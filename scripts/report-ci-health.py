#!/usr/bin/env python3
"""Read-only rolling CI latency and recurring-flake report; never a merge gate."""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import tempfile
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from statistics import median


def gh_json(*args: str):
    return json.loads(subprocess.check_output(['gh', *args], text=True))


def latency_stats(runs: list[dict]) -> tuple[int, float | None, float | None]:
    durations = []
    for run in runs:
        if run.get('conclusion') != 'success':
            continue
        start, end = run.get('run_started_at'), run.get('updated_at')
        if not start or not end:
            continue
        minutes = (datetime.fromisoformat(end.replace('Z', '+00:00')) -
                   datetime.fromisoformat(start.replace('Z', '+00:00'))).total_seconds() / 60
        if minutes >= 0:
            durations.append(minutes)
    durations.sort()
    return (len(durations), median(durations), durations[math.ceil(len(durations) * .95) - 1]) if durations else (0, None, None)


def recurring_flakes(reports: dict[str, list[dict]], minimum: int) -> list[tuple[str, str, int]]:
    occurrences: Counter = Counter()
    for payloads in reports.values():
        # Duplicate assertions and retry iterations in one run count once.
        occurrences.update({(p['suite'], entry[0]) for p in payloads
                            if p.get('available', True) for entry in p.get('flaky', [])})
    return [(suite, case, count) for (suite, case), count in sorted(occurrences.items()) if count >= minimum]


def self_test():
    def run(minutes, conclusion='success'):
        return {'conclusion': conclusion, 'run_started_at': '2026-01-01T00:00:00Z',
                'updated_at': f'2026-01-01T00:{minutes:02d}:00Z'}
    assert latency_stats([run(10), run(20), run(50, 'failure')]) == (2, 15, 20)
    assert latency_stats([run(1, 'cancelled')]) == (0, None, None)
    fixture = {'suite': 'Unit', 'flaky': [['case', 'a'], ['case', 'b']]}
    assert recurring_flakes({'1': [fixture]}, 2) == []
    assert recurring_flakes({'1': [fixture], '2': [fixture]}, 2) == [('Unit', 'case', 2)]
    assert recurring_flakes({'1': [dict(fixture, available=False)]}, 1) == []
    print('self-test passed')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo')
    parser.add_argument('--output', default='ci-health.md')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if not args.repo:
        parser.error('--repo required')
    config = json.loads(Path('.github/ci-health-targets.json').read_text())
    cutoff = (datetime.now(timezone.utc) - timedelta(days=config['window_days'])).strftime('%Y-%m-%dT%H:%M:%SZ')
    lines = ['## CI health targets', '',
             f"Last {config['window_days']} days, capped at {config['max_runs_per_workflow']} runs per workflow. Advisory targets.", '',
             '| Workflow | Successful samples | Median / target | p95 / target | Failed / completed | Cancelled |',
             '|---|---:|---:|---:|---:|---:|']
    nightly_runs = []
    for workflow, target in config['workflows'].items():
        payload = gh_json('api', '--method', 'GET', f'repos/{args.repo}/actions/workflows/{workflow}/runs',
                          '-f', f"event={target['event']}", '-f', f'created=>={cutoff}',
                          '-f', f"per_page={config['max_runs_per_workflow']}")
        runs = [r for r in payload['workflow_runs'] if r['status'] == 'completed']
        if workflow == 'scheduled-tests.yml':
            nightly_runs = runs[:config['flake_nightlies']]
        n, med, p95 = latency_stats(runs)
        fmt = lambda value: f'{value:.1f}m' if value is not None else 'unavailable'
        failures = sum(r['conclusion'] in ('failure', 'timed_out', 'action_required') for r in runs)
        cancelled = sum(r['conclusion'] == 'cancelled' for r in runs)
        lines.append(f"| {target['name']} | {n} | {fmt(med)} / {target['median_minutes']}m | {fmt(p95)} / {target['p95_minutes']}m | {failures}/{len(runs)} | {cancelled} |")
        if n and (med > target['median_minutes'] or p95 > target['p95_minutes']):
            print(f"::warning::{target['name']} exceeds latency target")
    lines += ['', 'Latency measures successful workflow attempts from `run_started_at` to `updated_at`, including runner waits. '
              'Failures and cancellations are shown separately; small samples are descriptive, not a stable percentile estimate.', '',
              '### Recurring nightly flakes', '']
    reports = {}
    with tempfile.TemporaryDirectory(prefix='pulse-health-') as temporary:
        for run in nightly_runs:
            dest = Path(temporary) / str(run['id'])
            result = subprocess.run(['gh', 'run', 'download', str(run['id']), '--repo', args.repo,
                                     '--pattern', 'flaky-*', '--dir', str(dest)], capture_output=True, text=True)
            payloads = []
            if result.returncode == 0:
                for path in dest.rglob('flaky-*.json'):
                    try:
                        payload = json.loads(path.read_text())
                        if isinstance(payload.get('suite'), str) and isinstance(payload.get('flaky'), list):
                            payloads.append(payload)
                    except (OSError, ValueError, AttributeError):
                        print(f'::warning::Unreadable flake report for run {run["id"]}')
            reports[str(run['id'])] = payloads
            available = sum(p.get('available', True) for p in payloads)
            lines.append(f"- [Run {run['id']}]({run['html_url']}): {available}/5 suite reports available; missing reports are unknown, not clean.")
    repeated = recurring_flakes(reports, config['recurring_flake_runs'])
    lines += ['', f"Target: {config['recurring_flake_budget']} tests recurring in at least {config['recurring_flake_runs']} of the last {config['flake_nightlies']} nightlies.", '',
              '| Suite | Test | Runs with recovered failures |', '|---|---|---:|']
    for suite, case, count in repeated:
        case = case.replace('|', '\\|').replace('\n', ' ')
        lines.append(f'| {suite} | `{case}` | {count} |')
    if not repeated:
        lines.append('| No recurrence in available reports | | |')
    if len(repeated) > config['recurring_flake_budget']:
        print(f'::warning::{len(repeated)} recurring flaky tests exceed the advisory budget')
    Path(args.output).write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
