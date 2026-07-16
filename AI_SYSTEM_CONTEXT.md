# 🤖 AI SYSTEM CONTEXT & RULES FOR "BEVEL CLONE" PROJECT

**ATTENTION ALL LLMs:** Read this document entirely before generating any code for this project. This file establishes the absolute constraints, hardware limitations, and architectural rules for this iOS/watchOS codebase. 

## 1. Developer Context & Hardware Constraints
* **Lead Developer:** Aarav
* **Local Hardware:** ASUS TUF Gaming A16 running Windows.
* **IDE:** Visual Studio Code (No local Xcode, no macOS environment, no local simulators).
* **Target Devices:** iPhone (iOS 26), iPad (iPadOS 26), Apple Watch (watchOS 10+).
* **Compilation:** All builds are executed entirely remotely via GitHub Actions `macos-latest` runners. The resulting `.ipa` is downloaded and sideloaded.

**CRITICAL RULE:** Because Aarav is coding on Windows, **NEVER** instruct him to "Open Xcode," "Use the Xcode Simulator," or "Check the Interface Builder." Provide all solutions as raw Swift code or VS Code/terminal commands.

## 2. The Decoupled UI Workflow (The "Playgrounds" Rule)
Because there is no local macOS simulator, Aarav relies on **Swift Playgrounds on his iPad** to get a live preview of the SwiftUI UI code. 

* Swift Playgrounds on iPad **will crash** if it attempts to compile code containing `import HealthKit`, `import WatchConnectivity`, or `NSHealthShareUsageDescription` entitlements.
* **The Solution:** The architecture MUST be strictly decoupled. 
* Every SwiftUI view must be powered by a central `AppViewModel`. 
* The `AppViewModel` must have a strict `isMocked` Boolean flag. 
* When `isMocked = true`, the app must generate rich, realistic dummy data (e.g., Strain: 64%, RR: 14 br/min, Sleep: 7h) and completely bypass any calls to HealthKit or WatchConnectivity managers.
* This allows Aarav to copy *only* the UI files and the Mocked ViewModel to his iPad for visual tweaking, while leaving the backend logic in VS Code.

## 3. App Features & Blueprint
This is a high-performance replica of the "Bevel" health tracking app. It requires a dark-mode, glassmorphism UI.
* **Metrics:** Strain (cardio load), Recovery (readiness), Sleep (efficiency/duration), and Biological Age.
* **Health Monitor:** Tracks RR, RHR, HRV, SpO2, and Body Temperature.
* **Journaling:** Boolean/Integer daily habit logging (e.g., Added sugar, Caffeine, Alcohol, Device in bed).
* **Data Storage:** Uses `SwiftData` for local caching and offline journaling.
* **Data Ingestion:** Uses `HealthKit` for passive background metric aggregation.

## 4. AI Delegation Roles
You are part of a coordinated LLM team. Adhere to your specific role and do not overwrite the architecture established by the others:
* **Claude 4.6 Opus:** You are the **Backend Architect**. Your job is to write `HealthKitManager.swift`, `WatchSyncEngine.swift`, and the `SwiftData` models.
* **Gemini 3.1 Pro:** You are the **UI/UX Engineer**. Your job is to write the high-fidelity `SwiftUI` views, complex multi-layered charts, circular progress rings, and bind them to the `AppViewModel`. You write the "Mock Data" layouts.
* **DeepSeek v4 Flash:** You are the **DevOps & Debugging Lead**. Your job is to optimize the GitHub Actions YAML, handle the `.ipa` compilation pipeline, fix provisioning profile errors, and squash compilation bugs.

## 5. Output Formatting Rules
* Always provide complete, copy-pasteable Swift files. Do not use "..." to skip logic unless explicitly asked.
* Use `async/await` concurrency for all data fetching.
* Ensure all SwiftUI views look excellent in `.dark` color schemes. 
* Acknowledge these constraints by briefly summarizing your assigned role before generating code.