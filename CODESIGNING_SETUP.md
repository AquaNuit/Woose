# 🔐 Code Signing Setup for GitHub Actions Sideloading

This guide will help you extract certificates and provisioning profiles from your Apple Developer account to enable automatic signing in GitHub Actions.

---

## 📋 Prerequisites

- ✅ Apple ID with free developer account
- ✅ iPhone running iOS 18+
- ✅ Apple Watch SE (3rd gen) running watchOS 10+
- ✅ Windows computer with iTunes installed
- ✅ AltStore or SideStore installed on iPhone

---

## 🎯 Overview: What We're Building

We need to extract **4 GitHub Secrets** to enable automatic code signing in CI/CD:

1. **BUILD_CERTIFICATE_BASE64** - Your signing certificate (`.p12` file)
2. **P12_PASSWORD** - Password for the certificate
3. **BUILD_PROVISION_PROFILE_BASE64** - iOS app provisioning profile
4. **WATCH_PROVISION_PROFILE_BASE64** (Optional) - watchOS app provisioning profile

Plus **3 configuration secrets**:

5. **DEVELOPMENT_TEAM** - Your Team ID (10 characters)
6. **BUNDLE_IDENTIFIER** - Your app's bundle ID (e.g., `com.yourname.bevelclone`)
7. **PROVISIONING_PROFILE_NAME** - Name of your provisioning profile

---

## 🪟 Method 1: Extract from Windows (Recommended)

### Step 1: Create App ID on Apple Developer Portal

1. **Open browser and go to:** https://developer.apple.com/account
2. Log in with your Apple ID
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Identifiers** → **+** (Add new)
5. Select **App IDs** → **App**
6. Configure:
   - **Description**: `Bevel Clone`
   - **Bundle ID**: `com.yourname.bevelclone` (Explicit, replace `yourname`)
   - **Capabilities**: Check these boxes:
     - ✅ HealthKit
     - ✅ Background Modes
7. Click **Continue** → **Register**

### Step 2: Create Provisioning Profile

1. Still on developer.apple.com, go to **Profiles** → **+** (Add new)
2. Select **iOS App Development** → **Continue**
3. Choose **App ID**: Select `Bevel Clone` → **Continue**
4. **Select Certificate**: Check the box next to your certificate → **Continue**
5. **Select Devices**: Check your iPhone → **Continue**
6. **Profile Name**: `Bevel Clone Development` → **Generate**
7. **Download** the `.mobileprovision` file → Save as `BevelClone_Development.mobileprovision`

### Step 3: Download Certificate from Keychain Access (macOS Only)

**⚠️ If you don't have a Mac, skip to Step 4 for Windows alternative**

On macOS:
1. Open **Keychain Access** app
2. Find your **Apple Development** certificate in "login" keychain
3. Right-click → **Export "Apple Development: ..."**
4. Save as `Certificates.p12`
5. Enter a strong password → Remember it for later

### Step 4: Generate Certificate on Windows (Alternative)

**If you don't have a Mac, use Xcode on GitHub Actions to generate the certificate:**

1. Create a **Certificate Signing Request (CSR)** using OpenSSL on Windows:

```powershell
# Install OpenSSL via Chocolatey
choco install openssl

# Generate private key
openssl genrsa -out private.key 2048

# Generate CSR
openssl req -new -key private.key -out CertificateSigningRequest.certSigningRequest -subj "/emailAddress=your@email.com/CN=Your Name/C=US"
```

2. Go to **developer.apple.com** → **Certificates** → **+**
3. Select **Apple Development** → **Continue**
4. Upload `CertificateSigningRequest.certSigningRequest` → **Continue**
5. **Download** the certificate → Save as `development.cer`

6. Convert to `.p12` format:

```powershell
# Convert .cer to .pem
openssl x509 -in development.cer -inform DER -out development.pem -outform PEM

# Create .p12 with private key
openssl pkcs12 -export -out Certificates.p12 -inkey private.key -in development.pem -password pass:YourStrongPassword
```

**⚠️ Remember the password you used above!**

### Step 5: Convert to Base64 (Windows PowerShell)

Open PowerShell and run:

```powershell
# Convert certificate to base64
$certBytes = [System.IO.File]::ReadAllBytes("C:\Path\To\Certificates.p12")
$certBase64 = [System.Convert]::ToBase64String($certBytes)
$certBase64 | Out-File -FilePath cert_base64.txt

# Convert provisioning profile to base64
$ppBytes = [System.IO.File]::ReadAllBytes("C:\Path\To\BevelClone_Development.mobileprovision")
$ppBase64 = [System.Convert]::ToBase64String($ppBytes)
$ppBase64 | Out-File -FilePath pp_base64.txt

Write-Host "✅ Base64 files created:"
Write-Host "  - cert_base64.txt"
Write-Host "  - pp_base64.txt"
```

---

## 🍎 Method 2: Extract from macOS (Easier if Available)

### Step 1-2: Same as Method 1

Follow Steps 1-2 from Method 1 above to create App ID and Provisioning Profile.

### Step 3: Export Certificate from Keychain

1. Open **Keychain Access** app
2. Select **login** keychain → **My Certificates**
3. Find **Apple Development: your@email.com**
4. Right-click → **Export "Apple Development: ..."**
5. Save as `Certificates.p12`
6. Enter password → Remember it!

### Step 4: Convert to Base64 (macOS Terminal)

```bash
# Convert certificate to base64
base64 -i Certificates.p12 -o cert_base64.txt

# Convert provisioning profile to base64
base64 -i BevelClone_Development.mobileprovision -o pp_base64.txt

echo "✅ Base64 files created in current directory"
```

---

## 🔑 Step 6: Add Secrets to GitHub

1. **Go to your GitHub repository**: https://github.com/AquaNuit/Woose
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add these **7 secrets**:

### Secret 1: BUILD_CERTIFICATE_BASE64
- **Name**: `BUILD_CERTIFICATE_BASE64`
- **Value**: Copy entire content of `cert_base64.txt` (should be ~2800 characters)

### Secret 2: P12_PASSWORD
- **Name**: `P12_PASSWORD`
- **Value**: The password you used when creating the `.p12` file

### Secret 3: BUILD_PROVISION_PROFILE_BASE64
- **Name**: `BUILD_PROVISION_PROFILE_BASE64`
- **Value**: Copy entire content of `pp_base64.txt` (should be ~8000 characters)

### Secret 4: KEYCHAIN_PASSWORD
- **Name**: `KEYCHAIN_PASSWORD`
- **Value**: Any strong random password (e.g., `Temp$Keychain2024!`) - only used during CI build

### Secret 5: DEVELOPMENT_TEAM
- **Name**: `DEVELOPMENT_TEAM`
- **Value**: Your Team ID (10 characters, find it on developer.apple.com → Membership)
- Example: `A1B2C3D4E5`

### Secret 6: BUNDLE_IDENTIFIER
- **Name**: `BUNDLE_IDENTIFIER`
- **Value**: The bundle ID you created in Step 1
- Example: `com.yourname.bevelclone`

### Secret 7: PROVISIONING_PROFILE_NAME
- **Name**: `PROVISIONING_PROFILE_NAME`
- **Value**: The exact name from Step 2
- Example: `Bevel Clone Development`

---

## 📱 Step 7: Update Info.plist for Background Tasks

Add this to your `BevelClone/Info.plist` (or create it if it doesn't exist):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- HealthKit Usage Description -->
    <key>NSHealthShareUsageDescription</key>
    <string>Bevel Clone needs access to your health data to calculate Strain, Recovery, Sleep quality, and Biological Age metrics. Your data stays private on your device.</string>
    
    <key>NSHealthUpdateUsageDescription</key>
    <string>Bevel Clone may write workout data to HealthKit in future updates.</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>processing</string>
        <string>remote-notification</string>
    </array>
    
    <!-- Background Task Identifiers -->
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.bevelclone.healthsync</string>
    </array>
    
    <!-- Privacy - Location (if needed for workouts) -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Bevel Clone uses your location to track outdoor workout routes.</string>
</dict>
</plist>
```

---

## 🏗️ Step 8: Create Xcode Project Configuration

Since you're developing on Windows, you'll need to create the Xcode project structure first. Here's what needs to be set up:

### Option A: Use Xcode on a Mac (Temporary)

If you have access to a Mac temporarily:

1. **Create New Xcode Project**:
   - File → New → Project
   - iOS → App
   - Product Name: `BevelClone`
   - Team: Select your Apple ID
   - Organization Identifier: `com.yourname` (matching your bundle ID)
   - Interface: SwiftUI
   - Storage: SwiftData

2. **Add watchOS Target**:
   - File → New → Target
   - watchOS → Watch App
   - Product Name: `BevelClone Watch App`
   - Check "Include Notification Scene"

3. **Add Files to Project**:
   - Drag all `.swift` files from `BevelClone/` folder
   - Select "Copy items if needed"
   - Add to both iOS and watchOS targets as appropriate

4. **Configure Capabilities**:
   - Select BevelClone target → Signing & Capabilities
   - Add HealthKit
   - Add Background Modes → Check "Background processing"

5. **Commit Project Files**:
   ```bash
   git add BevelClone.xcodeproj/
   git commit -m "Add Xcode project files"
   git push origin main
   ```

### Option B: Let GitHub Actions Create Project (Advanced)

Modify `.github/workflows/build-signed.yml` to generate Xcode project:

```yaml
- name: Generate Xcode Project
  run: |
    # Use Swift Package Manager to generate Xcode project
    swift package init --type executable --name BevelClone
    # This is a workaround - you'll need actual .xcodeproj
```

**⚠️ Recommended: Use Option A with temporary Mac access**

---

## 🚀 Step 9: Trigger Build on GitHub Actions

1. Push all code to GitHub:
   ```bash
   git add .
   git commit -m "Add code signing configuration"
   git push origin main
   ```

2. Go to **Actions** tab on GitHub
3. You should see **"Build & Sign BevelClone IPA (Sideload Ready)"** running
4. Wait ~10-15 minutes for build to complete

5. If successful:
   - Click on the workflow run
   - Scroll to **Artifacts** section
   - Download `BevelClone-signed-{hash}.zip`
   - Extract to get `BevelClone-signed.ipa`

---

## 📲 Step 10: Sideload to iPhone

### Using AltStore (Recommended for Windows):

1. **Install AltServer on Windows**:
   - Download from: https://altstore.io
   - Install and run AltServer (should appear in system tray)

2. **Install AltStore on iPhone**:
   - Connect iPhone via USB
   - Right-click AltServer icon → Install AltStore → Select your iPhone
   - Enter Apple ID credentials when prompted
   - Go to Settings → General → Device Management → Trust your Apple ID

3. **Sideload BevelClone**:
   - Open AltStore app on iPhone
   - Tap "My Apps" tab
   - Tap "+" button
   - Select `BevelClone-signed.ipa` from your computer
   - Wait for installation (~2 minutes)

4. **Trust the App**:
   - Go to Settings → General → Device Management
   - Tap your Apple ID
   - Tap "Trust"

5. **Launch BevelClone** from Home Screen 🎉

---

## 🔄 Refresh Cycle (Free Developer Account)

**⚠️ Important**: Free Apple Developer accounts require re-signing every **7 days**.

### Automatic Refresh:

AltStore can auto-refresh when:
- iPhone is on same WiFi as Windows PC
- AltServer is running on Windows
- AltStore has background refresh enabled

### Manual Refresh:

If app stops working after 7 days:
1. Open AltStore on iPhone
2. Tap "My Apps"
3. Find Bevel Clone
4. Tap "Refresh"

---

## 🐛 Troubleshooting

### Error: "Certificate not found"

**Solution**: Make sure `BUILD_CERTIFICATE_BASE64` is the full base64 string (no line breaks).

```powershell
# Re-generate without line breaks
$certBytes = [System.IO.File]::ReadAllBytes("Certificates.p12")
[System.Convert]::ToBase64String($certBytes) -replace "`n|`r" | Out-File -FilePath cert_base64_clean.txt -NoNewline
```

### Error: "Provisioning profile doesn't match"

**Solution**: Ensure bundle ID in GitHub Secret matches App ID:
1. Check `BUNDLE_IDENTIFIER` secret
2. Check App ID on developer.apple.com
3. Check Xcode project → General → Bundle Identifier

### Error: "Failed to create IPA"

**Solution**: Check build logs for specific error. Common issues:
- Missing watchOS provisioning profile (optional, can disable Watch target)
- Wrong team ID
- Expired certificate (regenerate on developer.apple.com)

### Error: "Unable to install app"

**Solution**: 
- Make sure iPhone is registered as a device on developer.apple.com
- Re-download provisioning profile after adding device
- Update `BUILD_PROVISION_PROFILE_BASE64` secret

---

## 📊 Verification Checklist

Before pushing to GitHub Actions, verify:

- ✅ All 7 GitHub Secrets are set correctly
- ✅ Info.plist includes HealthKit usage descriptions
- ✅ Info.plist includes background task identifiers
- ✅ Xcode project exists with proper targets
- ✅ Bundle ID matches in all places (App ID, Provisioning Profile, Xcode)
- ✅ Device is registered on developer.apple.com
- ✅ AltStore is installed and working on iPhone

---

## 🎯 Success Indicators

After following this guide, you should see:

1. ✅ GitHub Actions workflow completes without errors
2. ✅ Artifact `BevelClone-signed-{hash}.zip` is downloadable
3. ✅ IPA file is ~15-30 MB in size
4. ✅ AltStore successfully installs the app
5. ✅ App launches on iPhone and requests HealthKit permissions
6. ✅ Watch app appears on Apple Watch after iPhone installation

---

## 🔗 Useful Resources

- **Apple Developer Portal**: https://developer.apple.com/account
- **AltStore Official Site**: https://altstore.io
- **SideStore GitHub**: https://github.com/SideStore/SideStore
- **OpenSSL for Windows**: https://slproweb.com/products/Win32OpenSSL.html
- **Base64 Encoding Reference**: https://www.base64encode.org

---

## 💡 Pro Tips

1. **Save your `.p12` file securely** - You'll need it if secrets are lost
2. **Document your password** - Store it in a password manager
3. **Set calendar reminder** - Refresh app every 6 days to avoid expiration
4. **Use paid Apple Developer account** - $99/year removes 7-day limit
5. **Keep device registered** - Don't remove from developer.apple.com

---

## 🎉 Next Steps

Once your signed IPA is installed:

1. **Grant HealthKit Permissions** - Open app and allow all health data access
2. **Test Background Sync** - Plug in iPhone overnight and check if data syncs
3. **Pair Apple Watch** - Install companion Watch app from iPhone
4. **Start Workout** - Test real-time heart rate sync from Watch to iPhone

Enjoy your fully functional Bevel Clone! 🚀
