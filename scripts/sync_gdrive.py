import os
import sys
import shutil
from pathlib import Path

APP_NAME = "Nested App"
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Target Google Drive directories
USER_HOME = Path(os.environ.get("USERPROFILE", r"C:\Users\choud"))
GDRIVE_ROOT = USER_HOME / "Google Drive"
TARGET_GDRIVE_DIR = GDRIVE_ROOT / APP_NAME
LOCAL_GDRIVE_DIR = PROJECT_ROOT / "gdrive" / APP_NAME

# Secondary Google Drive (e.g. G: drive if exists)
G_DRIVE_ALT = Path(r"G:\My Drive") / APP_NAME

print("=" * 60)
print(f"  SYNCING {APP_NAME.upper()} TO GOOGLE DRIVE")
print("=" * 60)

# Artifact sources to sync
artifacts = [
    {
        "source": PROJECT_ROOT / "Nested-TaskStrategy-v2.1.8-review.apk",
        "dest_name": "Nested-v2.1.8-Build13.apk",
        "description": "Release APK (v2.1.8+13 Build 13)"
    },
    {
        "source": PROJECT_ROOT / "Nested-TaskStrategy-v2.1.8-review.apk",
        "dest_name": "Nested-v2.1.8.apk",
        "description": "Latest Release APK (v2.1.8+13)"
    },
    {
        "source": PROJECT_ROOT / "release-v2.1.8" / "app-release-v2.1.8.apk",
        "dest_name": "Nested-v2.1.8-Build12.apk",
        "description": "Previous Build APK (v2.1.8+12 Build 12)"
    },
    {
        "source": PROJECT_ROOT / "release-v2.1.7" / "app-release-updated.apk",
        "dest_name": "Nested-v2.1.7.apk",
        "description": "Previous Release APK (v2.1.7+10 Build 10)"
    },
    {
        "source": PROJECT_ROOT / "release-v2.1.7" / "native-debug-symbols.zip",
        "dest_name": "native-debug-symbols-v2.1.7.zip",
        "description": "Native Debug Symbols (v2.1.7)"
    },
]

# Ensure target directories exist
TARGET_GDRIVE_DIR.mkdir(parents=True, exist_ok=True)
LOCAL_GDRIVE_DIR.mkdir(parents=True, exist_ok=True)

sync_targets = [TARGET_GDRIVE_DIR, LOCAL_GDRIVE_DIR]
if G_DRIVE_ALT.parent.exists():
    try:
        G_DRIVE_ALT.mkdir(parents=True, exist_ok=True)
        sync_targets.append(G_DRIVE_ALT)
    except Exception as e:
        print(f"[!] Could not create G: drive alt directory: {e}")

synced_count = 0
for art in artifacts:
    src = art["source"]
    dest_name = art["dest_name"]
    desc = art["description"]
    
    if not src.exists():
        print(f"[-] Source file not found: {src}")
        continue

    size_mb = src.stat().st_size / (1024 * 1024)
    print(f"\n[+] Processing: {desc} ({dest_name}, {size_mb:.2f} MB)")
    
    for target_dir in sync_targets:
        dest_file = target_dir / dest_name
        try:
            shutil.copy2(src, dest_file)
            print(f"    --> Synced to: {dest_file}")
            synced_count += 1
        except Exception as e:
            print(f"    [!] Error copying to {dest_file}: {e}")

print("\n" + "=" * 60)
print(f"  SYNC COMPLETED! {synced_count} file copies created/updated.")
print(f"  Google Drive Path: {TARGET_GDRIVE_DIR}")
print(f"  Local gdrive Path: {LOCAL_GDRIVE_DIR}")
print("=" * 60)
