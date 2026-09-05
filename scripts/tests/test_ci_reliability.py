"""Regression coverage for the CI's own pass/fail decisions."""
import importlib.util
import json
import os
import plistlib
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))


def load(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), SCRIPTS / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


runner = load('run-ios-test-suite')
archive = load('check-release-archive')
flakes = load('detect-flaky-tests')


class ExecutionTests(unittest.TestCase):
    def test_structured_result_from_swift_testing(self):
        output = {'passedTests': 30, 'failedTests': 0, 'expectedFailures': 0, 'skippedTests': 0}
        with patch.object(runner.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, json.dumps(output))):
            count = runner.result_execution_count(Path('test.xcresult'))
        self.assertEqual(runner.validate_execution(0, count, ['Executed 0 tests']), (0, 30))

    def test_tool_failure_falls_back_to_both_frameworks(self):
        with patch.object(runner.subprocess, 'run', side_effect=subprocess.TimeoutExpired('xcrun', 30)):
            count = runner.result_execution_count(Path('test.xcresult'))
        for lines in [['Executed 4 tests'], ['Executed 0 tests', '✔ Test run with 30 tests in 8 suites passed']]:
            self.assertEqual(runner.validate_execution(0, count, lines)[0], 0)

    def test_malformed_result_does_not_invent_count(self):
        for output in ['not json', '[]', '{}', '{"totalTestCount": 20}']:
            with patch.object(runner.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, output)):
                self.assertIsNone(runner.result_execution_count(Path('test.xcresult')))

    def test_missing_and_all_skipped_fail(self):
        self.assertEqual(runner.validate_execution(0, None, [])[0], 1)
        count = runner.structured_execution_count({'passedTests': 0, 'failedTests': 0, 'expectedFailures': 0, 'skippedTests': 30})
        self.assertEqual(runner.validate_execution(0, count, [])[0], 1)

    def test_original_failure_and_timeout_are_preserved(self):
        for status in [65, 124]:
            self.assertEqual(runner.validate_execution(status, None, [])[0], status)

    def test_missing_flake_data_is_unknown(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / 'flaky.json'
            flakes.write_outputs('Unit', [], output, '/dev/null', available=False)
            self.assertFalse(json.loads(output.read_text())['available'])


class AnalysisGateTests(unittest.TestCase):
    def test_workflow_gates_accept_only_expected_completion(self):
        for name in ['codeql', 'docs']:
            workflow = (SCRIPTS.parent / f'.github/workflows/{name}.yml').read_text()
            block = workflow.split('      - name: Verify planned analysis completed\n', 1)[1]
            command = textwrap.dedent(block.split('        run: |\n', 1)[1])
            cases = [('success', 'true', 'success', 0), ('success', 'false', 'skipped', 0),
                     ('success', 'true', 'skipped', 1), ('success', 'true', 'failure', 1),
                     ('success', 'true', 'cancelled', 1), ('failure', 'false', 'skipped', 1),
                     ('cancelled', 'true', 'skipped', 1), ('success', '', 'skipped', 1)]
            for detection, planned, result, expected in cases:
                with self.subTest(workflow=name, detection=detection, planned=planned, result=result):
                    env = dict(os.environ, DETECTION=detection, PLANNED=planned, RESULT=result,
                               GITHUB_STEP_SUMMARY=os.devnull)
                    completed = subprocess.run(['bash', '-e', '-c', command], env=env, capture_output=True)
                    self.assertEqual(completed.returncode, expected)


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        app = self.root / 'Products/Applications/Pulse.app'
        self.bundles = [app, app / 'PlugIns/PulseShareExtension.appex', app / 'PlugIns/PulseWidgetExtension.appex']
        for index, bundle in enumerate(self.bundles):
            bundle.mkdir(parents=True)
            (bundle / 'binary').write_bytes(b'not-empty')
            with (bundle / 'Info.plist').open('wb') as stream:
                plistlib.dump({'CFBundleExecutable': 'binary', 'CFBundleIdentifier': f'com.example.target{index}',
                              'CFBundleSupportedPlatforms': ['iPhoneOS'], 'CFBundleShortVersionString': '1.0.0',
                              'CFBundleVersion': '1'}, stream)

    def change(self, key, value):
        path = self.bundles[-1] / 'Info.plist'
        data = plistlib.loads(path.read_bytes())
        data[key] = value
        path.write_bytes(plistlib.dumps(data))

    def test_valid_archive(self):
        archive.validate(self.root)

    def test_missing_extension_binary(self):
        (self.bundles[-1] / 'binary').unlink()
        with self.assertRaises(ValueError):
            archive.validate(self.root)

    def test_simulator_archive_rejected(self):
        self.change('CFBundleSupportedPlatforms', ['iPhoneSimulator'])
        with self.assertRaises(ValueError):
            archive.validate(self.root)

    def test_mismatched_version_rejected(self):
        self.change('CFBundleVersion', '2')
        with self.assertRaises(ValueError):
            archive.validate(self.root)

    def test_duplicate_bundle_id_rejected(self):
        self.change('CFBundleIdentifier', 'com.example.target0')
        with self.assertRaises(ValueError):
            archive.validate(self.root)


if __name__ == '__main__':
    unittest.main()
