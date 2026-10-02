import os
import sys
import base64
import re
import shutil

VERSION_CODE = 13
VERSION_NAME = "2.1.8"
PACKAGE_NAME = "com.studioxanywhere.nested"

def configure():
    print(f"[Signing] Starting release signing configuration for {PACKAGE_NAME} v{VERSION_NAME}+{VERSION_CODE}...")

    keystore_base64 = os.environ.get("KEYSTORE_BASE64", "").strip()
    keystore_pass = os.environ.get("KEYSTORE_PASSWORD", "").strip() or "NestedStrategy2026"
    key_alias = os.environ.get("KEY_ALIAS", "").strip() or "upload"
    key_pass = os.environ.get("KEY_PASSWORD", "").strip() or "NestedStrategy2026"

    os.makedirs("android/app", exist_ok=True)
    target_keystore = "android/app/upload-keystore.jks"
    root_keystore = "android/upload-keystore.jks"

    # Step 1: Ensure keystore exists in all expected paths
    if keystore_base64:
        print("[Signing] Decoding KEYSTORE_BASE64 from environment...")
        try:
            keystore_bytes = base64.b64decode(keystore_base64)
            with open(target_keystore, "wb") as f:
                f.write(keystore_bytes)
            with open(root_keystore, "wb") as f:
                f.write(keystore_bytes)
            with open("upload-keystore.jks", "wb") as f:
                f.write(keystore_bytes)
            print(f"[Signing] Wrote keystore to {target_keystore} and {root_keystore} ({len(keystore_bytes)} bytes).")
        except Exception as e:
            print(f"[Signing] ERROR decoding KEYSTORE_BASE64: {e}")
            sys.exit(1)
    elif os.path.exists("upload-keystore.jks"):
        print("[Signing] Copying root upload-keystore.jks to android/app/ and android/...")
        shutil.copy2("upload-keystore.jks", target_keystore)
        shutil.copy2("upload-keystore.jks", root_keystore)
        print(f"[Signing] Copied {target_keystore} and {root_keystore}.")
    elif os.path.exists(target_keystore):
        shutil.copy2(target_keystore, root_keystore)
        print(f"[Signing] Copied {target_keystore} to {root_keystore}.")
    else:
        print("[Signing] ERROR: No upload-keystore.jks found! Cannot sign release.")
        sys.exit(1)

    # Step 2: Write key.properties
    key_props = (
        f"storePassword={keystore_pass}\n"
        f"keyPassword={key_pass}\n"
        f"keyAlias={key_alias}\n"
        f"storeFile=upload-keystore.jks\n"
    )
    with open("android/key.properties", "w", encoding="utf-8") as f:
        f.write(key_props)
    with open("android/app/key.properties", "w", encoding="utf-8") as f:
        f.write(key_props)
    print("[Signing] Created android/key.properties successfully.")

    # Step 3: Ensure MainActivity.kt exists
    kt_path = "android/app/src/main/kotlin/com/studioxanywhere/nested/MainActivity.kt"
    if not os.path.exists(kt_path):
        os.makedirs(os.path.dirname(kt_path), exist_ok=True)
        with open(kt_path, "w", encoding="utf-8") as f:
            f.write("package com.studioxanywhere.nested\n\nimport io.flutter.embedding.android.FlutterActivity\n\nclass MainActivity: FlutterActivity() {\n}\n")
        print("[Signing] Ensured MainActivity.kt exists.")

    # Step 3.5: Ensure adaptive app launcher icons and colors exist from store_assets/android_res
    icons_src = "store_assets/android_res"
    res_dest = "android/app/src/main/res"
    if os.path.exists(icons_src):
        for root, dirs, files in os.walk(icons_src):
            rel_dir = os.path.relpath(root, icons_src)
            target_dir = os.path.join(res_dest, rel_dir) if rel_dir != "." else res_dest
            os.makedirs(target_dir, exist_ok=True)
            for file in files:
                shutil.copy2(os.path.join(root, file), os.path.join(target_dir, file))
        print(f"[Signing] Copied official app launcher icons and adaptive resources from {icons_src} to {res_dest}.")
    else:
        print("[Signing] WARNING: store_assets/android_res not found!")

    # Step 4: Ensure android/local.properties contains flutter.versionCode and flutter.versionName
    loc_props_path = "android/local.properties"
    existing_props = ""
    if os.path.exists(loc_props_path):
        with open(loc_props_path, "r", encoding="utf-8") as f:
            existing_props = f.read()

    if "flutter.versionCode=" in existing_props:
        existing_props = re.sub(r"^[ \t]*flutter\.versionCode=.*$", f"flutter.versionCode={VERSION_CODE}", existing_props, flags=re.MULTILINE)
    else:
        existing_props += f"\nflutter.versionCode={VERSION_CODE}\n"

    if "flutter.versionName=" in existing_props:
        existing_props = re.sub(r"^[ \t]*flutter\.versionName=.*$", f"flutter.versionName={VERSION_NAME}", existing_props, flags=re.MULTILINE)
    else:
        existing_props += f"flutter.versionName={VERSION_NAME}\n"

    with open(loc_props_path, "w", encoding="utf-8") as f:
        f.write(existing_props.strip() + "\n")
    print(f"[Signing] Ensured flutter.versionCode={VERSION_CODE} and flutter.versionName={VERSION_NAME} in android/local.properties.")

    # Step 5: Patch android/app/build.gradle (Groovy DSL)
    build_gradle = "android/app/build.gradle"
    if os.path.exists(build_gradle):
        with open(build_gradle, "r", encoding="utf-8") as f:
            c = f.read()

        signing_configs_code = f"""
    signingConfigs {{
        release {{
            keyAlias '{key_alias}'
            keyPassword '{key_pass}'
            storeFile file('upload-keystore.jks')
            storePassword '{keystore_pass}'
        }}
    }}
"""
        # Inject signingConfigs if not present
        if "signingConfigs {" in c:
            if "release {" not in c:
                c = c.replace("signingConfigs {", f"signingConfigs {{\n        release {{\n            keyAlias '{key_alias}'\n            keyPassword '{key_pass}'\n            storeFile file('upload-keystore.jks')\n            storePassword '{keystore_pass}'\n        }}\n")
        else:
            c = c.replace("buildTypes {", signing_configs_code + "\n    buildTypes {")

        # Replace signingConfig in release buildType
        c = re.sub(
            r"signingConfig\s*=?\s*signingConfigs\.\w+",
            "signingConfig signingConfigs.release",
            c
        )

        # Enforce exact package name, API 36, and version using line-anchored regexes (NEVER match across newlines)
        c = re.sub(r'^[ \t]*compileSdkVersion[ \t]+.*$', '    compileSdkVersion 36', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*compileSdk[ \t]*=.*$', '    compileSdk = 36', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*targetSdkVersion[ \t]+.*$', '        targetSdkVersion 36', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*targetSdk[ \t]*=.*$', '        targetSdk = 36', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*versionCode[ \t]*=.*$', f'        versionCode = {VERSION_CODE}', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*versionCode[ \t]+[0-9a-zA-Z._()]+.*$', f'        versionCode {VERSION_CODE}', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*versionName[ \t]*=.*$', f'        versionName = "{VERSION_NAME}"', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*versionName[ \t]+[0-9a-zA-Z._()"\']+', f'        versionName "{VERSION_NAME}"', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*applicationId[ \t]*=.*$', f'        applicationId = "{PACKAGE_NAME}"', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*applicationId[ \t]+["\'][^"\']+["\']', f'        applicationId "{PACKAGE_NAME}"', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*namespace[ \t]*=.*$', f'    namespace = "{PACKAGE_NAME}"', c, flags=re.MULTILINE)
        c = re.sub(r'^[ \t]*namespace[ \t]+["\'][^"\']+["\']', f'    namespace "{PACKAGE_NAME}"', c, flags=re.MULTILINE)

        # Fallback: if versionCode is missing from defaultConfig, explicitly inject it
        if "versionCode" not in c and "defaultConfig {" in c:
            c = c.replace("defaultConfig {", f"defaultConfig {{\n        versionCode {VERSION_CODE}\n        versionName \"{VERSION_NAME}\"")

        with open(build_gradle, "w", encoding="utf-8") as f:
            f.write(c)
        print(f"[Signing] Successfully patched android/app/build.gradle with API 36, {PACKAGE_NAME}, v{VERSION_NAME}+{VERSION_CODE}!")

    # Step 6: Patch android/app/build.gradle.kts (Kotlin DSL if present)
    build_gradle_kts = "android/app/build.gradle.kts"
    if os.path.exists(build_gradle_kts):
        with open(build_gradle_kts, "r", encoding="utf-8") as f:
            c_kts = f.read()

        signing_kts = f"""
    signingConfigs {{
        create("release") {{
            keyAlias = "{key_alias}"
            keyPassword = "{key_pass}"
            storeFile = file("upload-keystore.jks")
            storePassword = "{keystore_pass}"
        }}
    }}
"""
        if "create(\"release\")" not in c_kts:
            c_kts = c_kts.replace("buildTypes {", signing_kts + "\n    buildTypes {")
        c_kts = re.sub(
            r"signingConfig\s*=\s*signingConfigs.*",
            "signingConfig = signingConfigs.getByName(\"release\")",
            c_kts
        )
        c_kts = re.sub(r'^[ \t]*compileSdk(Version)?[ \t]*=.*$', '    compileSdk = 36', c_kts, flags=re.MULTILINE)
        c_kts = re.sub(r'^[ \t]*targetSdk(Version)?[ \t]*=.*$', '        targetSdk = 36', c_kts, flags=re.MULTILINE)
        c_kts = re.sub(r'^[ \t]*versionCode[ \t]*=.*$', f'        versionCode = {VERSION_CODE}', c_kts, flags=re.MULTILINE)
        c_kts = re.sub(r'^[ \t]*versionName[ \t]*=.*$', f'        versionName = "{VERSION_NAME}"', c_kts, flags=re.MULTILINE)
        c_kts = re.sub(r'^[ \t]*applicationId[ \t]*=.*$', f'        applicationId = "{PACKAGE_NAME}"', c_kts, flags=re.MULTILINE)
        c_kts = re.sub(r'^[ \t]*namespace[ \t]*=.*$', f'    namespace = "{PACKAGE_NAME}"', c_kts, flags=re.MULTILINE)

        if "versionCode" not in c_kts and "defaultConfig {" in c_kts:
            c_kts = c_kts.replace("defaultConfig {", f"defaultConfig {{\n        versionCode = {VERSION_CODE}\n        versionName = \"{VERSION_NAME}\"")

        with open(build_gradle_kts, "w", encoding="utf-8") as f:
            f.write(c_kts)
        print(f"[Signing] Successfully patched android/app/build.gradle.kts with API 36, {PACKAGE_NAME}, v{VERSION_NAME}+{VERSION_CODE}!")

    # Step 7: Ensure AndroidManifest.xml package and versionCode/versionName match
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            m = f.read()
        m = re.sub(r'package\s*=\s*["\'][^"\']+["\']', f'package="{PACKAGE_NAME}"', m)

        if 'android:versionCode=' in m:
            m = re.sub(r'android:versionCode\s*=\s*"[^"]*"', f'android:versionCode="{VERSION_CODE}"', m)
        else:
            m = re.sub(r'<manifest\b', f'<manifest android:versionCode="{VERSION_CODE}"', m, count=1)

        if 'android:versionName=' in m:
            m = re.sub(r'android:versionName\s*=\s*"[^"]*"', f'android:versionName="{VERSION_NAME}"', m)
        else:
            m = re.sub(r'<manifest\b', f'<manifest android:versionName="{VERSION_NAME}"', m, count=1)

        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(m)
        print(f"[Signing] Ensured package='{PACKAGE_NAME}', versionCode='{VERSION_CODE}', versionName='{VERSION_NAME}' in AndroidManifest.xml.")

    # Step 8: Verification of critical parameters
    verified = False
    for path in [build_gradle, build_gradle_kts]:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            if str(VERSION_CODE) in content and "36" in content and PACKAGE_NAME in content:
                print(f"[Signing] Verified {path} contains version {VERSION_CODE}, API 36, and package {PACKAGE_NAME}.")
                verified = True
    if not verified:
        print("[Signing] WARNING: Could not verify all parameters in build gradle files!")

    print(f"[Signing] Release signing configuration complete for {PACKAGE_NAME} v{VERSION_NAME}+{VERSION_CODE}. Ready to build!")

if __name__ == "__main__":
    configure()
