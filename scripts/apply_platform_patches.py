#!/usr/bin/env python3
"""Apply MechOS-specific Android/iOS permissions and application identity."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID_NS = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID_NS)


def android():
    manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
    if not manifest.exists():
        raise SystemExit('Android project missing; run flutter create first.')
    tree = ET.parse(manifest)
    root = tree.getroot()
    permissions = {p.get(f'{{{ANDROID_NS}}}name') for p in root.findall('uses-permission')}

    required = [
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.ACCESS_WIFI_STATE',
        'android.permission.CHANGE_WIFI_MULTICAST_STATE',
    ]
    for permission in required:
        if permission not in permissions:
            ET.SubElement(root, 'uses-permission', {f'{{{ANDROID_NS}}}name': permission})

    if 'android.permission.WRITE_EXTERNAL_STORAGE' not in permissions:
        ET.SubElement(root, 'uses-permission', {
            f'{{{ANDROID_NS}}}name': 'android.permission.WRITE_EXTERNAL_STORAGE',
            f'{{{ANDROID_NS}}}maxSdkVersion': '29',
        })

    app = root.find('application')
    if app is None:
        raise SystemExit('Android application element missing.')
    app.set(f'{{{ANDROID_NS}}}label', 'MechOS Companion')
    # Local pairing still uses authenticated LAN HTTP. Remote/relay routes should use HTTPS.
    app.set(f'{{{ANDROID_NS}}}usesCleartextTraffic', 'true')
    app.set(f'{{{ANDROID_NS}}}requestLegacyExternalStorage', 'true')
    tree.write(manifest, encoding='utf-8', xml_declaration=True)

    gradle = ROOT / 'android/app/build.gradle.kts'
    text = gradle.read_text()
    text = re.sub(r'namespace\s*=\s*"[^"]+"', 'namespace = "com.mechos.companion"', text)
    text = re.sub(r'applicationId\s*=\s*"[^"]+"', 'applicationId = "com.mechos.companion"', text)
    text = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36', text)
    gradle.write_text(text)


def ios():
    plist = ROOT / 'ios/Runner/Info.plist'
    if not plist.exists():
        raise SystemExit('iOS project missing; run flutter create first.')
    text = plist.read_text()
    additions = []
    values = {
        'NSLocalNetworkUsageDescription': 'MechOS Companion discovers and connects to your paired MechOS computer on your local network.',
        'NSPhotoLibraryAddUsageDescription': 'MechOS Companion saves optimization report images to your photo library.',
        'NSPhotoLibraryUsageDescription': 'MechOS Companion saves optimization report images to the MechOS Reports album.',
        'CFBundleDisplayName': 'MechOS Companion',
    }
    for key, value in values.items():
        if f'<key>{key}</key>' not in text:
            additions.append(f'\t<key>{key}</key>\n\t<string>{value}</string>\n')

    if '<key>NSBonjourServices</key>' not in text:
        additions.append(
            '\t<key>NSBonjourServices</key>\n'
            '\t<array>\n'
            '\t\t<string>_mechos-companion._tcp</string>\n'
            '\t</array>\n'
        )

    if '<key>NSAppTransportSecurity</key>' not in text:
        additions.append(
            '\t<key>NSAppTransportSecurity</key>\n'
            '\t<dict>\n'
            '\t\t<key>NSAllowsLocalNetworking</key>\n'
            '\t\t<true/>\n'
            '\t</dict>\n'
        )

    if additions:
        text = text.replace('</dict>\n</plist>', ''.join(additions) + '</dict>\n</plist>')
        plist.write_text(text)

    pbx = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    project = pbx.read_text()

    def bundle(match):
        current = match.group(1)
        suffix = '.RunnerTests' if 'RunnerTests' in current else ''
        return f'PRODUCT_BUNDLE_IDENTIFIER = com.mechos.companion{suffix};'

    project = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', bundle, project)
    pbx.write_text(project)


if __name__ == '__main__':
    android()
    ios()
    print('MechOS Android/iOS platform patches applied.')
