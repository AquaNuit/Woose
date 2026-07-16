# 🏥 Bevel Clone - Premium Health Tracking for iOS

> A sophisticated, multi-layered health and fitness tracking application built with SwiftUI, SwiftData, and HealthKit. Features a strictly decoupled architecture supporting both real HealthKit data and mock data for development.

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

![Bevel Clone Hero](https://via.placeholder.com/1200x400/0a0a0f/ffffff?text=Bevel+Clone+-+Premium+Health+Tracking)

---

## ✨ Features

### 📊 The Big Three Metrics
- **Strain**: Cardiovascular load percentage with dynamic color-coded ring
- **Recovery**: Readiness score based on HRV, sleep, and RHR
- **Sleep**: Duration and efficiency tracking with stage breakdown

### 💓 Health Monitor
Real-time and cached metrics:
- Resting Heart Rate (RHR)
- Heart Rate Variability (HRV)
- Oxygen Saturation (SpO₂)
- Respiratory Rate
- Body Temperature
- Blood Glucose

### 📖 Journal (90-Day Habit Tracking)
- **Manual Habits**: Added Sugar, Alcohol, Caffeine, Hydration, Keto, Low Carbs, Device in Bed, Late Meal
- **Automatic HealthKit Triggers**: 10k+ Steps, 20+ Min Cardio, 20+ Min Strength, 20+ Min Daylight, 50+ dB Sleep Noise
- Visual calendar heatmap showing consistency
- Streak tracking and weekly summaries

### 🏋️ Fitness (30-Day Activity Grid)
- **Activity Heatmap**: 0/1/2/3+ workouts per day visualization
- **Strength Volume**: Per-muscle-group set tracking (Chest, Back, Arms, Core, Legs, Shoulders)
- **Cardio Load**: Accumulated cardiovascular training load
- **Heart Rate Recovery**: Post-workout HRR tracking

### 🧬 Biology (Biomarkers & Longevity)
- **Biological Age**: Calculated from VO₂ Max, HRV, RHR, and recovery metrics
- **Baseline Tracking**: Weight, Body Fat %, Lean Body Mass, VO₂ Max
- Visual arc display showing age deviation

---

## 🎨 Design Philosophy

### Glassmorphism Dark Mode
- Ultra-thin material backgrounds with gradient borders
- High-contrast white text on deep purple-black gradients
- Color-coded metrics (strain: red/orange, recovery: green, sleep: indigo)
- SF Symbols for iconography

### Strictly Decoupled Architecture
```
┌─────────────────────────────────────────────┐
│          SwiftUI Views (UI Layer)           │
│  DashboardView │ JournalView │ FitnessView  │
└────────────────┬────────────────────────────┘
                 │
        ┌────────▼────────┐
        │  AppViewModel   │  ◄─── isMocked: Bool
        │   @Observable   │
        └────┬────────┬───┘
             │        │
    ┌────────▼───┐  ┌▼──────────┐
    │ Real Data  │  │ Mock Data │
    │ Pipeline   │  │ Generator │
    └┬──────────┬┘  └───────────┘
     │          │
┌────▼────┐ ┌──▼─────────┐
│HealthKit│ │WatchConnect│
│ Manager │ │   Engine   │
└─────────┘ └────────────┘
```

**Why This Matters:**
- Allows UI development on iPad using Swift Playgrounds (HealthKit not available)
- Enables rapid iteration without needing physical iPhone
- Mock data provides reproducible 90-day narrative for demos

---

## 🚀 Quick Start

### Prerequisites
- macOS 14+ (for Xcode 16.2)
- Xcode 16.2 or later
- iOS 17.0+ deployment target
- Apple Developer account (for HealthKit entitlement)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/BevelClone.git
   cd BevelClone
   ```

2. **Open in Xcode**
   ```bash
   open BevelClone.xcodeproj
   ```

3. **Configure Info.plist**
   Add HealthKit usage description (see [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md))

4. **Enable Capabilities**
   - HealthKit
   - Background Modes (Background processing)

5. **Build and Run**
   - For **Simulator/Playgrounds**: Use `isMocked: true` in ContentView
   - For **Physical Device**: Use `isMocked: false` and grant HealthKit permissions

### Testing on iPad with Swift Playgrounds

```swift
// Copy Models.swift, AppViewModel.swift, and all UI files
// Create PlaygroundApp.swift:

import SwiftUI
import SwiftData

@main
struct PlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView() // Set isMocked: true inside
        }
        .modelContainer(for: [DailyMetrics.self, JournalEntry.self, FitnessVolume.self])
    }
}
```

**DO NOT copy HealthKitManager or WatchSyncEngine to Playgrounds** - they will crash due to missing entitlements.

---

## 🏗️ Architecture

### Backend (Phase 1)

#### Models.swift
SwiftData schemas with hybrid denormalized structure:
- `DailyMetrics`: Nested structs for heart, sleep, activity, vitals
- `JournalEntry`: 13 Boolean habit properties with trigger sources
- `FitnessVolume`: Daily aggregated muscle group volumes

#### HealthKitManager.swift
`@MainActor` singleton with comprehensive HealthKit integration:
- Authorization for 15+ quantity types, 2 category types, workouts
- Async/await query functions (`fetchDailyMetrics`, `fetchRealtimeHeartRate`)
- `HKObserverQuery` registration for background updates
- Automatic journal trigger detection (10k steps, 20min cardio, etc.)

#### WatchSyncEngine.swift
`WCSessionDelegate` implementation with priority-based messaging:
- **Real-time** (`sendMessage`): Live heart rate during active workouts
- **Background** (`updateApplicationContext`): Daily metric sync, persistent state
- Automatic fallback when Watch unreachable
- Serialization/deserialization for `DailyMetrics`

#### AppViewModel.swift
Central `@Observable` ViewModel with dual-mode operation:
- **Mock Mode**: Pre-scripted 90-day narrative with realistic correlations
- **Real Mode**: HealthKit queries with SwiftData caching
- Charts-ready data structures (`IdentifiableChartPoint`, grids)
- Biological age stub calculation (swappable architecture)

### Frontend (Phase 2)

#### DashboardView.swift
Home screen with "The Big Three":
- Circular progress rings for Strain/Recovery
- Sleep card with duration + efficiency
- Health Monitor grid (RHR, HRV, SpO₂, RR, Temp, Glucose)
- Stress/Energy percentage bars

#### JournalView.swift
90-day habit tracking:
- Calendar heatmap (13 weeks × 7 days)
- Streak counter and weekly totals
- Today's habits list with auto-trigger indicators

#### FitnessView.swift
30-day activity and volume:
- Activity grid heatmap (5 weeks × 7 days)
- Muscle group volume bars (7-day rolling)
- Cardio load progress indicator

#### BiologyView.swift
Longevity metrics:
- Biological age circular arc with gradient
- Chronological vs biological comparison
- Biomarker cards (Weight, Body Fat %, Lean Mass, VO₂ Max)

---

## 📊 Mock Data Generation

The 90-day narrative simulates a realistic training comeback:

### Phase 1: Injured (Days 1-14)
- Status: `.injured`
- Strain: 20-35% (low activity)
- Recovery: 40-55% (poor readiness)
- Sleep: 5.5-7 hrs, 70-82% efficiency
- Workouts: None
- Journal: Irregular habits

### Phase 2: Recovery (Days 15-30)
- Status: `.active`
- Strain: 35-50% on workout days
- Recovery: 55-70% (improving)
- Sleep: 6.5-7.8 hrs, 78-88% efficiency
- Workouts: 1-2 per day (light volume)
- Journal: Improving consistency

### Phase 3: Active Training (Days 31-90)
- Status: `.active`
- Strain: 65-80% on Mon/Wed/Fri
- Recovery: 75-85% (stable)
- Sleep: 7-8.5 hrs, 85-95% efficiency
- Workouts: 2-3 per day (Push/Pull/Legs split)
- Journal: Consistent habits, auto-triggers firing

**Correlations:**
- Poor sleep (< 6.5 hrs) → HRV -15 to -25ms next day
- High alcohol → Recovery -15%
- 10k+ steps → Automatic journal completion

---

## 🔧 Configuration

### Switch Between Mock and Real Data

```swift
// ContentView.swift, line 24
viewModel = AppViewModel(
    isMocked: true,  // Change to false for production
    modelContext: modelContext
)
```

### Customize Mock Data Seed

```swift
// AppViewModel.swift, line 199
var seededRandom = SeededRandomGenerator(seed: 42)  // Change seed value
```

### Adjust Biological Age Algorithm

```swift
// AppViewModel.swift, line 573
func calculateBiologicalAge() -> Double {
    // Modify weighted formula here
}
```

---

## 🤖 CI/CD Pipeline

### GitHub Actions Workflow

Located at `.github/workflows/build.yml`:

```yaml
name: Build BevelClone IPA
on: [push, pull_request, workflow_dispatch]
runs-on: macos-15
```

**Steps:**
1. Checkout code
2. Setup Xcode 16.2
3. Resolve Swift Package Dependencies
4. Build for iOS Simulator (smoke test)
5. Archive for iOS Device (unsigned)
6. Upload `.xcarchive` as artifact

**Download artifact and resign using:**
- AltStore (easiest for Windows developers)
- SideStore
- Xcode Devices window (macOS)

---

## 📁 Project Structure

```
BevelClone/
├── App/
│   └── BevelCloneApp.swift           # @main entry point
├── Backend/
│   ├── Models.swift                  # SwiftData schemas & enums
│   ├── HealthKitManager.swift        # HealthKit queries
│   └── WatchSyncEngine.swift         # WatchConnectivity
├── ViewModels/
│   └── AppViewModel.swift            # Central @Observable VM
└── UI/
    ├── ContentView.swift             # TabView container
    ├── DashboardView.swift           # Home tab
    ├── JournalView.swift             # Habit tracking
    ├── FitnessView.swift             # Activity grid
    └── BiologyView.swift             # Biomarkers

.github/
└── workflows/
    └── build.yml                     # macOS-15 build pipeline

SETUP_INSTRUCTIONS.md                 # Detailed setup guide
README.md                             # This file
```

---

## 🧪 Testing

### Unit Tests (Future)
```bash
xcodebuild test -project BevelClone.xcodeproj -scheme BevelClone -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Preview Testing (Xcode)
All views include `#Preview` macros with in-memory SwiftData:

```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyMetrics.self, configurations: config)
    let viewModel = AppViewModel(isMocked: true, modelContext: container.mainContext)
    return DashboardView(viewModel: viewModel)
}
```

---

## 🛠️ Development Constraints

### Windows + VS Code Workflow
- **No local macOS**: All code written in VS Code on Windows
- **Remote compilation**: GitHub Actions builds .ipa on macos-15 runner
- **Sideloading**: AltStore used to install unsigned .ipa on iPhone

### Swift Playgrounds Testing
- **Visual UI development on iPad**: Test SwiftUI layouts without Xcode
- **HealthKit exclusion**: HealthKitManager crashes Playgrounds (missing entitlements)
- **Mock-only mode**: `isMocked: true` bypasses all HealthKit/Watch code

---

## 🚧 Roadmap

### Phase 3: Advanced Visualization
- [ ] Native `Charts` framework integration
- [ ] 30-day Strain/Recovery line charts
- [ ] HRV trend visualization
- [ ] Sleep stage timeline

### Phase 4: Apple Watch App
- [ ] watchOS companion app target
- [ ] Live workout heart rate display
- [ ] Complication showing daily Strain
- [ ] Background sync optimizations

### Phase 5: Export & Sharing
- [ ] Export health data to JSON/CSV
- [ ] PDF report generation
- [ ] Share metrics via ActivityKit Live Activities

### Phase 6: Advanced Analytics
- [ ] CoreML biological age model
- [ ] Training load predictions
- [ ] Injury risk assessment
- [ ] Personalized recovery recommendations

---

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) (to be created) for guidelines.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Bevel App**: Inspiration for UI/UX design
- **Apple HealthKit**: Comprehensive health data APIs
- **SwiftUI & SwiftData**: Modern declarative frameworks
- **Claude 4.6 Opus**: Backend architecture assistance

---

## 📧 Contact

**Developer**: Aarav  
**Platform**: Windows (ASUS TUF Gaming A16) + VS Code  
**Target**: iOS 18+, iPadOS 18+, watchOS 10+

---

## 🎯 Quick Links

- [Setup Instructions](SETUP_INSTRUCTIONS.md) - Detailed Xcode configuration
- [AI System Context](AI_SYSTEM_CONTEXT.md) - LLM collaboration rules
- [GitHub Actions](https://github.com/YOUR_USERNAME/BevelClone/actions) - View build status
- [Issues](https://github.com/YOUR_USERNAME/BevelClone/issues) - Report bugs or request features

---

**Built with ❤️ using SwiftUI, SwiftData, and HealthKit**
