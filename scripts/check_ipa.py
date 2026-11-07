import plistlib
import sys
import zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    p=plistlib.loads(z.read('Payload/PocketAI.app/Info.plist'))
    assert 'iPhoneOS' in p['CFBundleSupportedPlatforms']
    assert p['CFBundleIdentifier']=='com.usino.pocketai'
    assert p['CFBundlePackageType']=='APPL'
    assert z.read('Payload/PocketAI.app/'+p['CFBundleExecutable'])
    assert 'Payload/PocketAI.app/Assets.car' in z.namelist()
    assert not any(name.lower().endswith('.gguf') for name in z.namelist())
print('PASS: IPA iPhone, eseguibile e asset, modello separato. Firma da effettuare.')
