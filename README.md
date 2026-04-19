# Sign & Spell VR

## Overview
Sign Spell VR is an immersive virtual reality application designed to make learning Irish Sign Language (ISL) interactive and accessible for beginners and educators. Built using the Meta Quest 3 headset and the Godot 4 game engine, the project combines real-time hand tracking with gamified lessons to help users master the ISL alphabet, common words, phrases, and simple sentence construction in a 3D VR environment.​

##  Dependencies

###  Godot Engine 4.2+  
https://godotengine.org/download  

###  Godot XR Tools  
Already included in `/addons/GodotXRTools/`.

###  OpenXR Vendors Plugin  
Already included in `/addons/OpenXR-Vendors/`.

### Hand Pose Detector
Already included in `/addons/handposedetector/`.

###  Meta Quest Device  
Quest 3 recommended (supports full MR + hand tracking).

###  Android Build Support  
Required for deployment:  
- Android SDK  
- Android NDK (25.1.8937393 recommended)  
- JDK 17  

Configure in:  
`Editor → Editor Settings → Export → Android`

---

##  How to Run the Project (Godot Editor)

1. **Clone the repository**  
   ```bash
   git clone https://github.com/Kubzz00/Sign-and-Spell-VR.git
   cd final-year-project
2. **Open Godot 4.2+** and choose **Import Project**.

3. **Enable XR plugins**\
   Project → Project Settings → Plugins\
   Enable:
    - `GodotXRTools`
    - `OpenXR Vendors`

4. **Enable OpenXR**

5. **Press Play inside Godot**  

---

##  Running on Quest (Remote Deploy)

1. **Enable Developer Mode** on your Quest (using the Meta app).

2. **Connect the Quest via USB** to your PC.

3. **In Godot:**
   
Enable:
-  Deploy with Run Project  
  - Use USB  
  - Use OpenXR  

4. **Hit Display Remote (SHIFT + F5).**  
The app launches directly on the headset.

---

##  Building an APK (Full Export)

1. Install Godot's Android export templates:  
`Editor → Manage Export Templates`

2. Go to:  
`Project → Export → Android`

3. Set:
- Package name: `com.notespace.app`
- Minimum API Level: 29+
- Permissions (Camera Passthrough, Hand Tracking)

4. Export your APK.

5. Install using ADB:

```bash
adb install build.apk
