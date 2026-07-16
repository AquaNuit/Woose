# BevelClone Setup Instructions

## 📱 Phase 1 & 2 Complete - Ready for iPad Testing!

All backend and frontend files have been generated. Follow these steps to configure your Xcode project.

---

## 🗂️ File Structure

Your project should have this structure:

```
BevelClone/
├── App/
│   └── BevelCloneApp.swift                 ✅ Created
├── Backend/
│   ├── Models.swift                        ✅ Created
│   ├── HealthKitManager.swift              ✅ Created
│   └── WatchSyncEngine.swift               ✅ Created
├── ViewModels/
│   └── AppViewModel.swift                  ✅ Created
└── UI/
    ├── ContentView.swift                   ✅ Created
    ├── DashboardView.swift                 ✅ Created
    ├── JournalView.swift                   ✅ Created
    ├── FitnessView.swift                   ✅ Created
    └── BiologyView.swift                   ✅ Created

.github/
└── workflows/
    └── build.yml                           ✅ Created
```

---

## ⚙️ Xcode Project Configuration

### 1. Create New Xcode Project (If Not Already Created)

1. Open Xcode
2. File → New → Project
3. Choose **iOS → App**
4. Product Name: `BevelClone`
5. Interface: **SwiftUI**
6. Language: **Swift**
7. Storage: **SwiftData** ✅
8. Uncheck "Include Tests" (for now)

### 2. Add All Source Files to Xcode

1. In Xcode, right-click the `BevelClone` group
2. Select **Add Files to "BevelClone"...**
3. Navigate to your cloned repository folder
4. Select all `.swift` files
5. ✅ Check "Copy items if needed"
6. ✅ Check "Create groups"
7. Click **Add**

Organize files into groups matching the structure above for clarity.

### 3. Configure Info.plist

Add the following keys to your `Info.plist`:

**Method 1: Using Xcode UI**
1. Click your project in the navigator
2. Select the **BevelClone** target
3. Go to the **Info** tab
4. Click `+` to add new entries

**Method 2: Edit Info.plist as Source Code**

Right-click `Info.plist` → Open As → Source Code, then add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Bevel Clone needs access to your health data to calculate Strain, Recovery, Sleep quality, and Biological Age metrics. Your data stays private on your device.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Bevel Clone may write workout data to HealthKit in future updates.</string>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.bevelclone.healthsync</string>
</array>
```

### 4. Add Required Capabilities

1. Select your project → **BevelClone** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** and add:

   - ✅ **HealthKit**
   - ✅ **Background Modes** (check "Background processing")

### 5. Configure Build Settings

**Minimum Deployment Target:**
- iOS: **17.0** (for SwiftData @Observable support)
- watchOS: **10.0** (for Watch companion)

**Set Deployment Target:**
1. Select project → BevelClone target
2. General tab → Minimum Deployments
3. Set iOS to **17.0**

### 6. Update BevelCloneApp.swift Entry Point

The provided `BevelCloneApp.swift` should be set as your `@main` entry point. Verify it's marked with `@main` attribute.

---

## 🧪 Testing on iPad with Swift Playgrounds

### Option A: Test Full App with Mock Data (Recommended)

**For Swift Playgrounds (iPad):**

1. Copy ONLY these files to a new Playgrounds project:
   - ✅ `Models.swift`
   - ✅ `AppViewModel.swift`
   - ✅ `ContentView.swift`
   - ✅ `DashboardView.swift`
   - ✅ `JournalView.swift`
   - ✅ `FitnessView.swift`
   - ✅ `BiologyView.swift`

2. Create a new Swift file in Playgrounds called `PlaygroundApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            DailyMetrics.self,
            JournalEntry.self,
            FitnessVolume.self
        ])
    }
}
```

3. **DO NOT** copy these files (they will crash Playgrounds):
   - ❌ `HealthKitManager.swift`
   - ❌ `WatchSyncEngine.swift`

4. In `ContentView.swift`, verify line 24 is set to:
   ```swift
   viewModel = AppViewModel(isMocked: true, modelContext: modelContext)
   ```

### Option B: Test Individual Views (Quick Preview)

Create a new Playgrounds file and test single views:

```swift
import SwiftUI
import SwiftData

let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try! ModelContainer(
    for: DailyMetrics.self, JournalEntry.self, FitnessVolume.self,
    configurations: config
)
let context = container.mainContext
let viewModel = AppViewModel(isMocked: true, modelContext: context)

struct ContentView: View {
    var body: some View {
        DashboardView(viewModel: viewModel)
    }
}
```

---

## 🚀 Building IPA via GitHub Actions

### 1. Push Code to GitHub

```bash
git init
git add .
git commit -m "Initial commit: Phase 1 & 2 complete"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/BevelClone.git
git push -u origin main
```

### 2. GitHub Actions Will Automatically:

- ✅ Checkout your code
- ✅ Set up Xcode 16.2 on macOS 15
- ✅ Resolve Swift Package Dependencies
- ✅ Build for iOS Simulator (smoke test)
- ✅ Archive for iOS Device (unsigned)
- ✅ Upload `.xcarchive` as downloadable artifact

### 3. Download and Sideload

1. Go to **Actions** tab on GitHub
2. Click on the latest workflow run
3. Download `BevelClone-unsigned-{hash}` artifact
4. Extract the `.xcarchive.tar.gz` file
5. Resign using:
   - **AltStore** (easiest for Windows users)
   - **SideStore**
   - **Xcode → Window → Devices and Simulators** (if on Mac)

---

## 🎨 What You'll See on iPad

### Home Tab (Dashboard)
- ✅ **The Big Three**: Strain (circular ring), Recovery (circular ring), Sleep (horizontal card)
- ✅ **Activity Status**: Current state (Active/Sick/Injured/Break)
- ✅ **Health Monitor**: RHR, HRV, SpO2, Respiratory Rate, Body Temp, Glucose
- ✅ **Stress & Energy**: Percentage bars with glassmorphism design

### Journal Tab
- ✅ **90-Day Calendar Heatmap**: Visual grid showing habit completion
- ✅ **Streak Counter**: Days of consecutive habit logging
- ✅ **Today's Habits**: Checkboxes with automatic vs manual indicators

### Fitness Tab
- ✅ **30-Day Activity Grid**: Heatmap showing 0/1/2/3+ workouts per day
- ✅ **Strength Volume**: Bars for each muscle group (Chest, Back, Arms, etc.)
- ✅ **Cardio Load**: Weekly total with progress bar

### Biology Tab
- ✅ **Biological Age**: Large circular arc showing calculated age vs chronological
- ✅ **Biomarkers**: Weight, Body Fat %, Lean Mass, VO₂ Max cards

### Mock Data Features
- ✅ **90-Day Narrative**: Shows progression from "Injured" (Days 1-14) → "Recovery" (Days 15-30) → "Active" (Days 31-90)
- ✅ **Realistic Patterns**: Mon/Wed/Fri workouts, weekend alcohol consumption, poor sleep correlations
- ✅ **Reproducible**: Seeded random generator ensures same data on each launch

---

## 🔄 Switching Between Mock and Real Data

### For Swift Playgrounds Testing (Mock Only)
```swift
// In ContentView.swift line 24
viewModel = AppViewModel(isMocked: true, modelContext: modelContext)
```

### For Production iPhone Build (Real HealthKit)
```swift
// In ContentView.swift line 24
viewModel = AppViewModel(isMocked: false, modelContext: modelContext)
```

When `isMocked: false`, the app will:
1. Request HealthKit authorization on first launch
2. Query real health data from your Apple Health app
3. Activate WatchConnectivity for Apple Watch sync
4. Cache data in SwiftData for offline access

---

## 🐛 Troubleshooting

### "HealthKit is not available"
- HealthKit only works on **physical devices**, not simulators
- Use `isMocked: true` for simulator/Playgrounds testing

### "Cannot find type 'DailyMetrics' in scope"
- Ensure `Models.swift` is included in your Xcode target
- Check File Inspector → Target Membership → ✅ BevelClone

### "No such module 'SwiftData'"
- Minimum deployment target must be iOS 17.0+
- Check Project Settings → Deployment Info

### GitHub Actions Build Fails
- Check that `BevelClone.xcodeproj` exists in repository root
- Verify scheme name matches "BevelClone" exactly
- View workflow logs for detailed error messages

### Playgrounds Crashes on Launch
- Verify you did NOT copy `HealthKitManager.swift` or `WatchSyncEngine.swift`
- Ensure `isMocked: true` is set in ContentView

---

## 📊 Next Steps (Future Phases)

### Phase 3: Advanced Features
- [ ] Real-time Charts using Apple's Charts framework
- [ ] Export health data to JSON/CSV
- [ ] Custom workout builder
- [ ] Nutrition tracking integration

### Phase 4: Apple Watch Companion
- [ ] watchOS app target
- [ ] Live workout heart rate display
- [ ] Complication showing daily Strain
- [ ] Background sync improvements

### Phase 5: Cloud Sync (Optional)
- [ ] CloudKit integration for multi-device sync
- [ ] Backup/restore functionality
- [ ] Share health reports

---

## ✅ Verification Checklist

Before testing on iPad:

- [ ] All `.swift` files added to Xcode project
- [ ] `NSHealthShareUsageDescription` added to Info.plist
- [ ] HealthKit capability enabled
- [ ] Minimum deployment target set to iOS 17.0+
- [ ] ContentView has `isMocked: true` for Playgrounds
- [ ] Code pushed to GitHub for CI/CD

---

## 🎉 You're Ready!

Your Bevel Clone is now fully functional with:
- ✅ 90 days of realistic mock health data
- ✅ Beautiful dark-mode glassmorphism UI
- ✅ Four fully-implemented tabs
- ✅ Ready for iPad Swift Playgrounds testing
- ✅ Automated GitHub Actions build pipeline

**Copy the UI files to your iPad Playgrounds and see your health tracking app come to life!**
