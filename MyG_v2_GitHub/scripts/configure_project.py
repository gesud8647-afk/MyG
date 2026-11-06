"""Generate a deterministic Xcode project. No Google key means no Google dependency."""
from pathlib import Path
import os
import plistlib

root = Path(__file__).resolve().parent.parent
key = os.environ.get('GOOGLE_MAPS_API_KEY', '').strip()
google = os.environ.get('ENABLE_GOOGLE_MAPS', 'false').lower() == 'true'
if google and not key:
    raise SystemExit('Google Maps richiesto ma secret GOOGLE_MAPS_API_KEY mancante.')

info = {
    'CFBundleDisplayName': 'My G', 'CFBundleExecutable': '$(EXECUTABLE_NAME)',
    'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleInfoDictionaryVersion': '6.0',
    'CFBundleName': '$(PRODUCT_NAME)', 'CFBundlePackageType': 'APPL',
    'CFBundleShortVersionString': '2.0', 'CFBundleVersion': '2', 'LSRequiresIPhoneOS': True,
    'NSBluetoothAlwaysUsageDescription': 'My G rileva segnali BLE vicini e si collega solo agli accessori che scegli.',
    'NSLocationWhenInUseUsageDescription': 'Mostra il tuo iPhone e un cerchio di distanza Bluetooth indicativa sulla mappa. Non ricava la posizione di altri dispositivi.',
    'UIApplicationSceneManifest': {'UIApplicationSupportsMultipleScenes': False},
    'UILaunchScreen': {}, 'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait'],
}
if google:
    (root/'MyG/GoogleMapsConfig.plist').write_bytes(plistlib.dumps({'GoogleMapsAPIKey': key}))
else:
    (root/'MyG/GoogleMapsConfig.plist').unlink(missing_ok=True)
# The API key is in an ignored resource, never in the checked-in Info.plist.
(root/'MyG/Info.plist').write_bytes(plistlib.dumps(info))

objects = []
def oid(n): return f'{n:024X}'
def obj(n, body): objects.append(f'{oid(n)} = {{ {body} }};')
q = lambda s: '"' + s.replace('\\','\\\\').replace('"','\\"') + '"'
arr = lambda values: '(' + ', '.join(oid(v) for v in values) + ')'
source_names = sorted(p.name for p in (root/'MyG').glob('*.swift'))
file_ids, source_builds, resource_builds = [], [], []
for index, name in enumerate(source_names):
    fid, bid = 100+index, 200+index
    file_ids.append(fid); source_builds.append(bid)
    obj(fid, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(name)}; sourceTree = "<group>";')
    obj(bid, f'isa = PBXBuildFile; fileRef = {oid(fid)};')
for index, (name, kind) in enumerate([('Info.plist','text.plist.xml'),('Assets.xcassets','folder.assetcatalog'),('PrivacyInfo.xcprivacy','text.xml')]):
    fid, bid = 300+index, 400+index
    file_ids.append(fid)
    obj(fid, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(name)}; sourceTree = "<group>";')
    if index:
        resource_builds.append(bid); obj(bid, f'isa = PBXBuildFile; fileRef = {oid(fid)};')
if google:
    file_ids.append(303); resource_builds.append(403)
    obj(303, 'isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = GoogleMapsConfig.plist; sourceTree = "<group>";')
    obj(403, f'isa = PBXBuildFile; fileRef = {oid(303)};')
    obj(500, 'isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/googlemaps/ios-maps-sdk"; requirement = { kind = exactVersion; version = 9.4.0; };')
    obj(501, f'isa = XCSwiftPackageProductDependency; package = {oid(500)}; productName = GoogleMaps;')
    obj(502, f'isa = PBXBuildFile; productRef = {oid(501)};')
obj(1, f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1640; }}; buildConfigurationList = {oid(10)}; compatibilityVersion = "Xcode 14.0"; developmentRegion = it; hasScannedForEncodings = 0; knownRegions = (it, en, Base); mainGroup = {oid(2)}; productRefGroup = {oid(3)}; projectDirPath = ""; projectRoot = ""; targets = {arr([4])}; packageReferences = {arr([500] if google else [])};')
obj(2, f'isa = PBXGroup; children = {arr([5,3])}; sourceTree = "<group>";')
obj(3, f'isa = PBXGroup; children = {arr([6])}; name = Products; sourceTree = "<group>";')
obj(4, f'isa = PBXNativeTarget; buildConfigurationList = {oid(11)}; buildPhases = {arr([7,8,9])}; buildRules = (); dependencies = (); name = MyG; productName = MyG; productReference = {oid(6)}; productType = "com.apple.product-type.application"; packageProductDependencies = {arr([501] if google else [])};')
obj(5, f'isa = PBXGroup; children = {arr(file_ids)}; path = MyG; sourceTree = "<group>";')
obj(6, 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MyG.app; sourceTree = BUILT_PRODUCTS_DIR;')
for num, kind, ids in [(7,'PBXSourcesBuildPhase',source_builds),(8,'PBXFrameworksBuildPhase',[502] if google else []),(9,'PBXResourcesBuildPhase',resource_builds)]:
    obj(num, f'isa = {kind}; buildActionMask = 2147483647; files = {arr(ids)}; runOnlyForDeploymentPostprocessing = 0;')
for num, ids in [(10,[20,21]),(11,[22,23])]:
    obj(num, f'isa = XCConfigurationList; buildConfigurations = {arr(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common = 'CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 16.0;'
target = 'CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 2; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = MyG/Info.plist; MARKETING_VERSION = 2.0; PRODUCT_BUNDLE_IDENTIFIER = com.myg.nearby; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; OTHER_LDFLAGS = "$(inherited) -ObjC";'
for num, name, settings in [(20,'Debug',common+' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;'),(21,'Release',common+' DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; SWIFT_COMPILATION_MODE = wholemodule;'),(22,'Debug',target),(23,'Release',target)]:
    obj(num, f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {name};')
(root/'MyG.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n'+'\n'.join(objects)+'\n};\nrootObject = '+oid(1)+';\n}\n')
scheme = root/'MyG.xcodeproj/xcshareddata/xcschemes/MyG.xcscheme'
scheme.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="MyG.app" BlueprintName="MyG" ReferencedContainer="container:MyG.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="MyG.app" BlueprintName="MyG" ReferencedContainer="container:MyG.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Progetto configurato: Google Maps abilitato.' if google else 'Progetto configurato: MapKit, nessuna chiave o dipendenza Google.')
