#!/usr/bin/env python3
"""Validate the app and both shipped extensions in a device archive."""
import plistlib
import sys
from pathlib import Path


def validate(archive: Path) -> None:
    app = archive / 'Products/Applications/Pulse.app'
    expected = {'Pulse.app': app, 'PulseShareExtension.appex': app / 'PlugIns/PulseShareExtension.appex',
                'PulseWidgetExtension.appex': app / 'PlugIns/PulseWidgetExtension.appex'}
    versions = set()
    identifiers = set()
    for name, bundle in expected.items():
        with (bundle / 'Info.plist').open('rb') as stream:
            info = plistlib.load(stream)
        executable = bundle / info['CFBundleExecutable']
        if not executable.is_file() or executable.stat().st_size == 0:
            raise ValueError(f'{name}: missing executable')
        if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError(f'{name}: not a device bundle')
        identifiers.add(info['CFBundleIdentifier'])
        versions.add((info['CFBundleShortVersionString'], info['CFBundleVersion']))
    if len(versions) != 1 or len(identifiers) != 3:
        raise ValueError('App/extension versions differ or bundle identifiers collide')
    print('Device archive contains the app and both extensions with matching versions.')


if __name__ == '__main__':
    validate(Path(sys.argv[1]))
