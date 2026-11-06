"""Check layout and device platform. Does not verify signing/installability."""
import plistlib
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    if archive.testzip() is not None:
        raise SystemExit('Archivio corrotto')
    info = plistlib.loads(archive.read('Payload/MyG.app/Info.plist'))
    assert info['CFBundlePackageType'] == 'APPL'
    assert 'iPhoneOS' in info['CFBundleSupportedPlatforms']
    assert info.get('NSBluetoothAlwaysUsageDescription')
    executable = 'Payload/MyG.app/' + info['CFBundleExecutable']
    assert len(archive.read(executable)) > 0
print('Struttura IPA e piattaforma iPhoneOS verificate; firma non verificata.')
