# NEURAL RACER — Offline Adaptive AI Racing

**Developer: Adarsh Anand**

A self-contained portrait-mode, lane-based Android racing prototype made with **Godot 4.3**. It features touch steering, gas and brake controls, traffic, collision/lives, scoring, restart, and a simulated AI rival.

## Adaptive AI

The AI rival uses a **contextual multi-armed bandit**, with four traffic/speed contexts, three actions (left/stay/right), epsilon exploration and incremental reward updates. This is lightweight **online learning on device**, not a neural network or cloud API. Learning resets on game restart. The rival is a simulated competitor with a visible marker; this is an arcade racing prototype, not a realistic driving simulator.

## Controls

- Android: **LEFT / RIGHT**, **GAS**, **BRAKE**. Tap left/right side of the road to steer.
- Desktop: **A / D** or arrow keys to steer; **W / S** or up/down arrows to accelerate/brake.
- Dodge traffic. Three collisions end the race. Tap **RESTART** to retry.

## Build an APK on GitHub

1. Open **Actions → Build Android APK → Run workflow**, or push a commit to `main`.
2. Wait for the job to finish. If green, open the run and download **NeuralRacer-Android-APK** under **Artifacts**.
3. Extract the downloaded ZIP and install **NeuralRacer.apk** on your Android phone.

**Build status:** Source prototype. A successful APK is not guaranteed until the workflow passes. The workflow installs Godot 4.3, matching export templates, Android SDK, Java 17, creates a debug keystore and attempts a headless export. No signing credentials need to be committed. Debug builds are for testing, not Google Play release.

## Run in Godot

Open `project.godot` in Godot **4.3** and press **F5**. This is a lightweight 2D project with no external art assets.

## License

Copyright © 2026 Adarsh Anand. No redistribution license is granted until a license file is added by the owner.
