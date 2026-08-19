# ⚠️ Project Status: Deprecated / Archived
*This project is no longer under active development. I have transitioned my focus to C++ and Unreal Engine development. I am leaving this repository public as a portfolio piece to demonstrate my early experience with client-server architecture, system design, and Luau.*

---

# 🌟 Luceria: Spellbound
A physics-driven magic exploration game built in Roblox Studio using Luau, Rojo, and custom Blender rigs.

---

## 🛠️ Core Systems Engineered
* **Dynamic Physics Simulation:** Integrated and packed custom SmartBone engine architecture (written by someone else) to simulate real-time ribbon and fabric physics via parallel computing loops.
* **Component-Driven Architecture:** Managed game states utilizing modular Luau script lifecycles across client/server boundaries via Rojo mapping profiles.

---

## 🛠️ Transferable Engineering Concepts Demonstrated
While built in Roblox (Luau), this project implements core architectural patterns used across the games industry:
* **Client-Server Networking:** Implemented secure RemoteEvents and RemoteFunctions to handle spell replication and combat data, minimizing latency and preventing exploit vulnerabilities.
* **Component-Based Movement:** Designed a modular movement system emphasizing predictable physics and state management.
* **Object-Oriented Programming (OOP):** Utilized Luau's metatables to build a reusable, extensible architecture for the spell/ability system.
* **Asset Pipelines:** Integrated 3D assets (like the custom staff model) into a functional gameplay framework.