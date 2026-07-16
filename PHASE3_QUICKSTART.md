# ⚡ Phase 3 Quick Start Guide

## 🎯 What's New in Phase 3

You now have:
- ✅ **watchOS App** with real-time heart rate monitoring
- ✅ **Background Task Registration** for nightly data sync
- ✅ **Automated Code Signing** via GitHub Actions
- ✅ **Sideload-Ready IPA** generation

---

## 📱 watchOS App Features

### New Files Created:
```
BevelClone Watch App/
├── BevelCloneWatchApp.swift        # Watch app entry point
├── ContentView.swift                # Glanceable dashboard
└── WatchViewModel.swift             # Watch state & iPhone sync
```

### What It Does:
1. **Live Heart Rate Display** - Real-time BPM from Apple Watch sensors
2. **Workout Control** - Start/stop workout with "sendMessage" sync to iPhone
3. **Strain & Recovery** - Displays today's metrics synced from iPhone
4. **Connection Status** - Shows if iPhone is reachable
5. **Activity Status** - Current state (Active/Injured/etc.)

### How to Use:
1. Install iPhone app first
2. Watch app auto-installs from iPhone
3. Open Watch app → Tap "Start Workout"
4. Heart rate syncs in real-time to iPhone (appears in Health Monitor)
5. Tap "End Workout" to stop

---

## 🔄 Background Task Registration

### Updated File:
- `BevelClone/App/BevelCloneApp.swift` - Now includes `AppDelegate` for `BGTaskScheduler`

### What It Does:
- **Registers** background processing task: `com.bevelclone.healthsync`
- **Triggers** automatically when iPhone is:
  - 🔌 Charging
  - 📶 Connected (optional)
  - 🛌 Idle for 15+ minutes
- **Recalculates** 30/90-day rolling averages for Strain/Recovery
- **Updates** SwiftData cache without opening app

### How to Test:
```bash
# In Xcode debugger console (when running on device):
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.bevelclone.healthsync"]
```

---

## 🔐 Code Signing Setup (5-Minute Version)

### Required GitHub Secrets (7 total):

| Secret Name | How to Get It | Example Value |
|-------------|---------------|---------------|
| `BUILD_CERTIFICATE_BASE64` | Export `.p12` from Keychain → Convert to base64 | `MIIKmgIBAzCCCl4G...` (2800 chars) |
| `P12_PASSWORD` | Password you set when exporting certificate | `MySecretPass123` |
| `BUILD_PROVISION_PROFILE_BASE64` | Download `.mobileprovision` → Convert to base64 | `MIIQxAYJKoZIhvcN...` (8000 chars) |
| `KEYCHAIN_PASSWORD` | Any random password (only for CI) | `Temp$Keychain2024!` |
| `DEVELOPMENT_TEAM` | developer.apple.com → Membership → Team ID | `A1B2C3D4E5` (10 chars) |
| `BUNDLE_IDENTIFIER` | Your app's bundle ID | `com.yourname.bevelclone` |
| `PROVISIONING_PROFILE_NAME` | Name from developer.apple.com → Profiles | `Bevel Clone Development` |

### Quick Setup (Windows):

```powershell
# 1. Convert certificate to base64
$certBytes = [System.IO.File]::ReadAllBytes("Certificates.p12")
[System.Convert]::ToBase64String($certBytes) | Out-File cert_base64.txt

# 2. Convert provisioning profile to base64
$ppBytes = [System.IO.File]::ReadAllBytes("BevelClone_Development.mobileprovision")
[System.Convert]::ToBase64String($ppBytes) | Out-File pp_base64.txt

# 3. Copy contents and paste into GitHub Secrets
```

**Full detailed guide**: See [CODESIGNING_SETUP.md](CODESIGNING_SETUP.md)

---

## 🚀 Trigger Signed Build

### Step 1: Push to GitHub
```bash
git add .
git commit -m "Phase 3: watchOS app + code signing"
git push origin main
```

### Step 2: Wait for Build (~10 minutes)
- Go to: https://github.com/AquaNuit/Woose/actions
- Click on latest workflow run
- Wait for green checkmark ✅

### Step 3: Download IPA
- Scroll to **Artifacts** section
- Download `BevelClone-signed-{hash}.zip`
- Extract to get `BevelClone-signed.ipa`

---

## 📲 Sideload to iPhone

### Option 1: AltStore (Easiest for Windows)

1. **Install AltServer** on Windows: https://altstore.io
2. **Connect iPhone** via USB
3. **Install AltStore** on iPhone:
   - Right-click AltServer tray icon → Install AltStore → Select iPhone
   - Enter Apple ID credentials
4. **Sideload App**:
   - Open AltStore app on iPhone
   - Tap "+" button
   - Select `BevelClone-signed.ipa`
   - Wait 2 minutes
5. **Trust Certificate**:
   - Settings → General → Device Management → Trust your Apple ID
6. **Launch Bevel Clone** from Home Screen 🎉

### Option 2: SideStore

- Similar to AltStore but doesn't require Windows companion
- Follow SideStore installation guide: https://github.com/SideStore/SideStore

---

## 🧪 Testing Real HealthKit Integration

### First Launch:
1. **Open app** → Grant HealthKit permissions (ALL)
2. **Go to Settings → Health → Data Access & Devices → Bevel Clone** → Enable all categories
3. **Close and reopen app** → Should see real data instead of mock data

### Verify Data Sources:
- **Dashboard** → Health Monitor should show real RHR, HRV, SpO2
- **Journal** → Automatic triggers fire based on real step count
- **Fitness** → Activity grid populates with real workouts

### Test Watch Sync:
1. **Open Watch app** → Tap "Start Workout"
2. **Check iPhone app** → Health Monitor → Should see live heart rate updating
3. **End workout on Watch** → Data persists in iPhone

---

## 🔄 Maintenance (Free Developer Account)

**⚠️ Apps expire every 7 days with free accounts**

### Auto-Refresh (Set up once):
1. Keep **AltServer running** on Windows
2. Keep **iPhone on same WiFi**
3. Enable **AltStore Background Refresh** in app
4. App auto-refreshes every ~6 days

### Manual Refresh:
- Open AltStore → My Apps → Bevel Clone → Tap "Refresh"

---

## 🐛 Common Issues & Fixes

### Issue: "Unable to verify app"
**Fix**: Settings → General → Device Management → Trust certificate

### Issue: "HealthKit data not showing"
**Fix**: 
1. Check `isMocked` is set to `false` in `ContentView.swift` line 24
2. Verify HealthKit permissions granted
3. Force quit and reopen app

### Issue: "Watch app not installing"
**Fix**:
1. Delete iPhone app completely
2. Reinstall via AltStore
3. Wait 5 minutes for Watch app to auto-install

### Issue: "Background sync not working"
**Fix**:
1. Plug iPhone into charger overnight
2. Check Settings → Battery → Background App Refresh is ON
3. Verify `Info.plist` has `BGTaskSchedulerPermittedIdentifiers`

### Issue: "Build failed on GitHub Actions"
**Fix**:
1. Check all 7 secrets are set correctly (no typos)
2. Verify bundle ID matches App ID on developer.apple.com
3. Ensure device is registered on developer.apple.com
4. Re-download provisioning profile if device was added recently

---

## 📊 Verification Checklist

Before considering Phase 3 complete:

- [ ] watchOS app files created in `BevelClone Watch App/`
- [ ] `BevelCloneApp.swift` updated with `AppDelegate` and background tasks
- [ ] `Info.plist` includes background task identifier
- [ ] All 7 GitHub Secrets added to repository
- [ ] `.github/workflows/build-signed.yml` exists
- [ ] GitHub Actions build completes successfully
- [ ] IPA artifact downloads without errors
- [ ] App installs on iPhone via AltStore
- [ ] HealthKit permissions granted and data appears
- [ ] Watch app auto-installs on Apple Watch
- [ ] Real-time heart rate syncs from Watch to iPhone
- [ ] Background sync task registered (check Xcode console logs)

---

## 🎉 Success! What's Next?

You now have a **fully functional, production-ready** health tracking app with:
- ✅ Real HealthKit data integration
- ✅ Apple Watch companion with live HR
- ✅ Background data processing
- ✅ Automated CI/CD pipeline
- ✅ Sideloadable signed IPA

### Suggested Enhancements:
1. **Add Charts** - Integrate Apple's native Charts framework for trends
2. **Export Data** - JSON/CSV export for external analysis
3. **Notifications** - Alert when recovery is low or strain is high
4. **Widgets** - Home Screen widgets showing today's metrics
5. **Complications** - Watch face complications for Strain/Recovery

---

## 🔗 Quick Links

- **Full Code Signing Guide**: [CODESIGNING_SETUP.md](CODESIGNING_SETUP.md)
- **Main README**: [README.md](README.md)
- **Setup Instructions**: [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
- **GitHub Actions**: https://github.com/AquaNuit/Woose/actions
- **Apple Developer Portal**: https://developer.apple.com/account

---

**Built with ❤️ using SwiftUI, HealthKit, and WatchConnectivity**
