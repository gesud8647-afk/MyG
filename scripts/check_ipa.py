import plistlib
import sys
import zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    assert archive.testzip() is None
    info = plistlib.loads(archive.read('Payload/ECO.app/Info.plist'))
    assert 'iPhoneOS' in info['CFBundleSupportedPlatforms']
    assert info['CFBundleIdentifier'].startswith('com.usino.eco')
    assert info['CFBundlePackageType'] == 'APPL'
    assert info['NSLocationWhenInUseUsageDescription']
    assert archive.read('Payload/ECO.app/' + info['CFBundleExecutable'])
    assert 'Payload/ECO.app/Assets.car' in archive.namelist()
print('PASS: struttura IPA per iPhone. Firma non verificata: IPA non firmato.')
