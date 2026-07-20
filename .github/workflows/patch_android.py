import re

path = "android/app/build.gradle.kts"
with open(path) as f:
    content = f.read()

# Fixed NDK version (some plugins require newer than the default template)
if "ndkVersion" not in content:
    content = content.replace("android {", 'android {\n    ndkVersion = "27.0.12077973"', 1)

# Stable signing config so release builds always share the same key
# (avoids Android refusing updates with a new random debug key each CI run)
if 'signingConfigs {' not in content:
    signing_configs = '''    signingConfigs {
        create("release") {
            storeFile = file("xcapture-release.keystore")
            storePassword = "xcapture123"
            keyAlias = "xcapture"
            keyPassword = "xcapture123"
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
