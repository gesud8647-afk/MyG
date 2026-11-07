from pathlib import Path
import plistlib

r = Path(__file__).resolve().parent.parent
info = {'CFBundleDisplayName':'USI Security','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.2','CFBundleVersion':'2','NSLocalNetworkUsageDescription':'Verifica le porte TCP del singolo dispositivo della tua rete locale che scegli e autorizzi.','LSRequiresIPhoneOS':True,'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait']}
(r/'PocketAI/Info.plist').write_bytes(plistlib.dumps(info))
objects=[]
def oid(i): return f'{i:024X}'
def obj(i,body): objects.append(f'{oid(i)} = {{ {body} }};')
def array(ids): return '('+', '.join(oid(i) for i in ids)+')'
files=[]; sources=[]; resources=[]
for n,p in enumerate(sorted(list((r/'PocketAI').glob('*.swift')) + list((r/'PocketAI').glob('*.cpp')))):
 fid,bid=100+n,200+n;files.append(fid);sources.append(bid)
 kind = 'sourcecode.cpp.cpp' if p.suffix == '.cpp' else 'sourcecode.swift'
 obj(fid,f'isa = PBXFileReference; lastKnownFileType = {kind}; path = "{p.name}"; sourceTree = "<group>";')
 obj(bid,f'isa = PBXBuildFile; fileRef = {oid(fid)};')
for n,(name,kind) in enumerate([('Info.plist','text.plist.xml'),('Assets.xcassets','folder.assetcatalog'),('PrivacyInfo.xcprivacy','text.xml'),('LLAMA_LICENSE.txt','text')]):
 fid,bid=300+n,400+n;files.append(fid)
 obj(fid,f'isa = PBXFileReference; lastKnownFileType = {kind}; path = "{name}"; sourceTree = "<group>";')
 if n: resources.append(bid);obj(bid,f'isa = PBXBuildFile; fileRef = {oid(fid)};')
obj(350, 'isa = PBXFileReference; lastKnownFileType = archive.ar; path = "Vendor/libpocket-llama.a"; sourceTree = "<group>";')
obj(450, f'isa = PBXBuildFile; fileRef = {oid(350)};')
files.append(351)
obj(351, 'isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = PocketBridge.h; sourceTree = "<group>";')
obj(1,f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1640; }}; buildConfigurationList = {oid(10)}; compatibilityVersion = "Xcode 14.0"; developmentRegion = it; hasScannedForEncodings = 0; knownRegions = (it,en,Base); mainGroup = {oid(2)}; productRefGroup = {oid(3)}; projectDirPath = ""; projectRoot = ""; targets = {array([4])};')
obj(2,f'isa = PBXGroup; children = {array([5,3,350])}; sourceTree = "<group>";')
obj(3,f'isa = PBXGroup; children = {array([6])}; name = Products; sourceTree = "<group>";')
obj(4,f'isa = PBXNativeTarget; buildConfigurationList = {oid(11)}; buildPhases = {array([7,8,9])}; buildRules = (); dependencies = (); name = PocketAI; productName = PocketAI; productReference = {oid(6)}; productType = "com.apple.product-type.application";')
obj(5,f'isa = PBXGroup; children = {array(files)}; path = PocketAI; sourceTree = "<group>";')
obj(6,'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PocketAI.app; sourceTree = BUILT_PRODUCTS_DIR;')
for num,kind,ids in [(7,'PBXSourcesBuildPhase',sources),(8,'PBXFrameworksBuildPhase',[450]),(9,'PBXResourcesBuildPhase',resources)]:
 obj(num,f'isa = {kind}; buildActionMask = 2147483647; files = {array(ids)}; runOnlyForDeploymentPostprocessing = 0;')
for num,ids in [(10,[20,21]),(11,[22,23])]:
 obj(num,f'isa = XCConfigurationList; buildConfigurations = {array(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common='CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 16.0;'
target='CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 2; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = PocketAI/Info.plist; MARKETING_VERSION = 0.2; PRODUCT_BUNDLE_IDENTIFIER = com.usino.pocketai; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; SWIFT_OBJC_BRIDGING_HEADER = PocketAI/PocketBridge.h; HEADER_SEARCH_PATHS = "$(SRCROOT)/Vendor/include"; LIBRARY_SEARCH_PATHS = ("$(inherited)", "$(SRCROOT)/Vendor"); CLANG_CXX_LANGUAGE_STANDARD = "c++17"; CLANG_CXX_LIBRARY = "libc++"; OTHER_LDFLAGS = "$(inherited) -lc++ -framework Accelerate -framework Foundation";'
for num,name,settings in [(20,'Debug',common+' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;'),(21,'Release',common+' DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; SWIFT_COMPILATION_MODE = wholemodule;'),(22,'Debug',target),(23,'Release',target)]:
 obj(num,f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {name};')
(r/'PocketAI.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n'+'\n'.join(objects)+'\n};\nrootObject = '+oid(1)+';\n}\n')
scheme = r/'PocketAI.xcodeproj/xcshareddata/xcschemes/PocketAI.xcscheme'
scheme.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="PocketAI.app" BlueprintName="PocketAI" ReferencedContainer="container:PocketAI.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'''+oid(4)+'''" BuildableName="PocketAI.app" BlueprintName="PocketAI" ReferencedContainer="container:PocketAI.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
(r/'PocketAI/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps({'NSPrivacyTracking':False,'NSPrivacyCollectedDataTypes':[],'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults','NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}))
print('Progetto PocketAI generato: iOS 16+, bridge C++ e libreria llama.cpp statica.')
