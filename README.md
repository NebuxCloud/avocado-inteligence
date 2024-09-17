# AvocadoIntelligence

<div align="center">
    <img src="avocadointeligence.swiftui/Assets.xcassets/AppIcon.appiconset/appstore.png" alt="App Logo" width="150"/>
</div>

**AvocadoIntelligence** is a SwiftUI application created by [NebuxCloud](https://nebux.cloud), a company specializing in AI and SRE solutions. This application aims to bring intelligent functionalities to iOS users. This guide will help you compile the project using Xcode.

## Features

AvocadoIntelligence offers a range of advanced features designed to enhance the user experience with intelligent text generation. These features have been tested on devices starting from the iPhone 13 Pro and work across any iOS version in any region, supporting both English and Spanish languages. While testing has primarily been conducted on iPhone 13 Pro and newer devices, it may also work on earlier versions of iPhone.

- **Summarize URLs in Spanish:** Generate concise summaries from web links in Spanish. [Watch demo](https://youtube.com/shorts/zxvDh6J-6qM)
- **Summarize URLs in English:** Extract key points from web links in English. [Watch demo](https://youtube.com/shorts/Szu7mtuekFY)
- **Romanticize Spanish text:** Add a romantic flair to your Spanish writings. [Watch demo](https://youtube.com/shorts/b8nXXE6m7rE)
- **Romanticize English text:** Transform English text with a romantic style. [Watch demo](https://youtube.com/shorts/4jMdMYGzus4)
- **Professionalize Spanish text:** Elevate your Spanish content to a professional tone. [Watch demo](https://youtube.com/shorts/4wj_EEkfBVs)
- **Professionalize English text:** Improve English text by giving it a more formal, professional voice. [Watch demo](https://youtube.com/shorts/Y2nkhM59aj0?feature=share)

Each feature works seamlessly on devices running iOS in any region (not restricted to the USA) and offers multilingual support (English and Spanish).

### Model

- Gemma 2b IT

## How to Compile AvocadoIntelligence in Xcode

### 1. Open Xcode

Launch Xcode on your Mac and navigate to the **AvocadoIntelligence** project folder. You can do this by either double-clicking the `.xcodeproj` or `.xcworkspace` file or opening it directly from within Xcode using the "Open" option.

### 2. Set the Signing & Capabilities

- Go to the **Signing & Capabilities** tab in the project settings.
- Select the target **AvocadoIntelligence** in the project navigator.
- Ensure you have a valid Apple Developer Account set up in Xcode. You can add this by navigating to **Xcode > Preferences > Accounts**.
- Choose a **team** from the drop-down list under **Signing**. This is required for running the app on a physical device or distributing it.

### 3. Set the Deployment Target

Ensure the **Deployment Target** is set correctly for your desired iOS version. This can be found under the **General** tab in the project settings. Make sure it matches the minimum iOS version required by your app.

### 4. Build the App

Click the **Build** button or press `Cmd + B` to compile the project. Xcode will begin the build process, resolving dependencies, and compiling the code.

### 5. Run on a Simulator or Device

- To run the app on a simulator, select the target device in the toolbar and press `Cmd + R` to run the app.
- To run the app on a physical device, connect your device, select it from the target device list, and click the **Run** button.

### 6. Debug and Test

Once the app is running, you can use the Xcode debugging tools to inspect the app's performance and behavior. Set breakpoints or use logging to troubleshoot any issues.

### 7. Archive and Distribute (Optional)

If you're ready to distribute your app, you can archive it by going to **Product > Archive**. This will create an archive of your app, which can then be uploaded to the App Store or shared with others for testing through TestFlight.

---

Enjoy developing with **AvocadoIntelligence**! If you encounter any issues, feel free to open a new issue in this repository.
