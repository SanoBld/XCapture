import re

path = "android/app/build.gradle.kts"
with open(path) as f:
    content = f.read()

# Set a fixed NDK version (some plugins require a newer one than the default template)
if "ndkVersion" not in content:
    content = content.replace("android {", 'android {\n    ndkVersion = "27.0.12077973"', 1)

# Load key.properties and sign release builds with our stable keystore,
# so installs update in place instead of requiring an uninstall each time.
signing_block = '''
    val keystoreProperties = java.util.Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }
'''
if "keystoreProperties" not in content:
    content = content.replace("android {", "android {\n" + signing_block, 1)

if "signingConfigs {" not in content:
    signing_configs = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
'''
    content = re.sub(r"(buildTypes \{)", signing_configs + r"\1", content, count=1)

content = content.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
)

with open(path, "w") as f:
    f.write(content)

print("Patched build.gradle.kts")
