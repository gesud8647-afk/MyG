from pathlib import Path
import plistlib

r = Path(__file__).resolve().parent.parent
info = {'CFBundleDisplayName':'ECO','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.1','CFBundleVersion':'1','LSRequiresIPhoneOS':True,'NSLocationWhenInUseUsageDescription':'ECO usa la posizione solo quando lo chiedi per salvare un tuo luogo o verificare una vicinanza indicativa. Puoi giocare anche senza GPS.','UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait']}
(r/'ECO/Info.plist').write_bytes(plistlib.dumps(info))
objects=[]
def oid(i): return f'{i:024X}'
def obj(i,body): objects.append(f'{oid(i)} = {{ {body} }};')
def array(ids): return '('+', '.join(oid(i) for i in ids)+')'
files=[]; sources=[]; resources=[]
for n,p in enumerate(sorted((r/'ECO').glob('*.swift'))):
 fid,bid=100+n,200+n;files.append(fid);sources.append(bid)
 obj(fid,f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{p.name}"; sourceTree = "<group>";')
 obj(bid,f'isa = PBXBuildFile; fileRef = {oid(fid)};')
for n,(name,kind) in enumerate([('Info.plist','text.plist.xml'),('Assets.xcassets','folder.assetcatalog'),('PrivacyInfo.xcprivacy','text.xml')]):
 fid,bid=300+n,400+n;files.append(fid)
 obj(fid,f'isa = PBXFileReference; lastKnownFileType = {kind}; path = "{name}"; sourceTree = "<group>";')
 if n: resources.append(bid);obj(bid,f'isa = PBXBuildFile; fileRef = {oid(fid)};')
obj(1,f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1640; }}; buildConfigurationList = {oid(10)}; compatibilityVersion = "Xcode 14.0"; developmentRegion = it; hasScannedForEncodings = 0; knownRegions = (it,en,Base); mainGroup = {oid(2)}; productRefGroup = {oid(3)}; projectDirPath = ""; projectRoot = ""; targets = {array([4])};')
obj(2,f'isa = PBXGroup; children = {array([5,3])}; sourceTree = "<group>";')
obj(3,f'isa = PBXGroup; children = {array([6])}; name = Products; sourceTree = "<group>";')
obj(4,f'isa = PBXNativeTarget; buildConfigurationList = {oid(11)}; buildPhases = {array([7,8,9])}; buildRules = (); dependencies = (); name = ECO; productName = ECO; productReference = {oid(6)}; productType = "com.apple.product-type.application";')
obj(5,f'isa = PBXGroup; children = {array(files)}; path = ECO; sourceTree = "<group>";')
obj(6,'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ECO.app; sourceTree = BUILT_PRODUCTS_DIR;')
for num,kind,ids in [(7,'PBXSourcesBuildPhase',sources),(8,'PBXFrameworksBuildPhase',[]),(9,'PBXResourcesBuildPhase',resources)]:
 obj(num,f'isa = {kind}; buildActionMask = 2147483647; files = {array(ids)}; runOnlyForDeploymentPostprocessing = 0;')
for num,ids in [(10,[20,21]),(11,[22,23])]:
 obj(num,f'isa = XCConfigurationList; buildConfigurations = {array(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common='CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 16.0;'
target='CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = ECO/Info.plist; MARKETING_VERSION = 0.1; PRODUCT_BUNDLE_IDENTIFIER = com.usino.eco.primolegame; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;'
for num,name,settings in [(20,'Debug',common+' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;'),(21,'Release',common+' DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; SWIFT_COMPILATION_MODE = wholemodule;'),(22,'Debug',target),(23,'Release',target)]:
 obj(num,f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {name};')
(r/'ECO.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n'+'\n'.join(objects)+'\n};\nrootObject = '+oid(1)+';\n}\n')
scheme = r/'ECO.xcodeproj/xcshareddata/xcschemes/ECO.xcscheme'
scheme.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="ECO.app" BlueprintName="ECO" ReferencedContainer="container:ECO.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="ECO.app" BlueprintName="ECO" ReferencedContainer="container:ECO.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
(r/'ECO/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps({'NSPrivacyTracking':False,'NSPrivacyCollectedDataTypes':[],'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults','NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}))
print('Progetto ECO generato: iOS 16+, nessuna dipendenza esterna.')
