import os

files_map = {
    'pubspec.yaml': [('version: 0.2.16+27', 'version: 0.2.17+28')],
    'lib/features/dashboard/presentation/pages/dashboard_page.dart': [
        ('V 0.2.16', 'V 0.2.17'),
        ('V.0.2.16', 'V.0.2.17'),
    ],
    'lib/features/settings/presentation/pages/settings_page.dart': [
        ('V 0.2.16', 'V 0.2.17'),
        ('V.0.2.16', 'V.0.2.17'),
    ],
    'lib/core/services/smc_s_plus_scanner.dart': [
        ('V 0.2.16', 'V 0.2.17'),
    ],
    'android/app/src/main/kotlin/com/richard/micripto/micripto_sentinel/AlarmActivity.kt': [
        ('"V 0.2.16"', '"V 0.2.17"'),
    ],
    'android/app/src/main/kotlin/com/richard/micripto/micripto_sentinel/MainActivity.kt': [
        ('"V 0.2.16"', '"V 0.2.17"'),
    ],
    'android/app/src/main/kotlin/com/richard/micripto/micripto_sentinel/SentinelAlarmReceiver.kt': [
        ('"V 0.2.16"', '"V 0.2.17"'),
    ],
    'android/app/src/main/res/layout/activity_alarm.xml': [
        ('"V 0.2.16"', '"V 0.2.17"'),
    ],
}

for path, replacements in files_map.items():
    if not os.path.exists(path):
        print(f"Skipping missing file: {path}")
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    changed = False
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            changed = True
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {path}")
    else:
        print(f"No changes made to {path}")
