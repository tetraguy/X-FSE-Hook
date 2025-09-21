# X-FSE Hook
<img width="150" height="150" alt="X-FSE Hook" src="https://github.com/user-attachments/assets/740335f3-d68a-4dc8-a627-3554d3d70f6e" />

A tiny Windows helper that lets you **hook a launcher or game shell to start automatically at sign-in**, great for couch/handheld setups using the new **Xbox Full-Screen Experience (X-FSE)**. Pick Playnite Fullscreen, Steam, GOG, or any installed/UWP app with a click. Easily revert to the Windows default.

> ⚠️ Requires **Administrator** rights. The app makes a safe, reversible change to the **Winlogon ➜ `Userinit`** registry value.

---

## ✨ Features

* **Scan UWP apps** and **installed programs** and select the one you want to auto-start.
* **One-click presets:** Playnite Fullscreen, Steam, GOG, or **Default** (restore Windows behavior).
* **Manual hook:** Point to any executable if it’s not in the lists.
* **Backup + verify:** Creates a backup and confirms the registry change.
* **Simple UI:** Search, multi-select list, and clear status prompts.

---

## 🖼️ UI

<img width="543" height="539" alt="image" src="https://github.com/user-attachments/assets/e68e6939-fefc-4467-9258-41e510d2ef40" />

---

## 🛠️ How it works (in one line)

The app sets:

```
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit
```

to include:

```
C:\Windows\System32\userinit.exe,<your-selected-app>,
```

This preserves normal sign-in while launching your selected app immediately after login.

---

## 📦 Installation

1. Download the latest release `.msi`.
2. Install it.
3. **Right-click ➜ Run as administrator**.

> Built with PowerShell + WinForms. Works on Windows 10/11 (x64).

---

## 🚀 Usage

1. Launch **X-FSE Hook** as Administrator.
2. Click **Scan UWP Apps** and/or **Scan Installed Programs**.
3. Select an app in the list and press **Hook Selection**.

   * Or use a **Preset** (Playnite FS / Steam / GOG).
   * Or click **Hook Program Manually** to browse for an `.exe`.
4. You’ll get a success popup when the hook is set.

**Revert:** Click **Default** to restore the stock `Userinit` value.

---

## 🔐 Safety Notes

* Changes are limited to `HKLM\...\Winlogon\Userinit`.
* Always run the tool from a **64-bit, elevated** session.

---

## ❓ Troubleshooting

* **“Access denied / failed to update registry”**
  Run as Administrator (elevated PowerShell/EXE). Some EDR tools may require an allow-rule.

* **App not detected (e.g., Playnite)**
  Install it to the default path or use **Hook Program Manually**. The tool will show a warning if the default Playnite FS executable isn’t found.

* **Blank list after Scan**
  Click **Scan UWP Apps** and **Scan Installed Programs** again, or use the search box to filter.

---

## 🧩 Presets

* **Hook Playnite FS** → `Playnite.FullscreenApp.exe`
* **Hook Steam** → Steam client (Big Picture / BPM successor)
* **Hook GOG** → GOG Galaxy
* **Default** → Restore Windows default (`userinit.exe,` only)

---

## 🏗️ Build (devs)

* PowerShell 5.1+ (or PowerShell 7 with Windows-compatibility)
* .NET Framework WinForms assemblies available by default on Windows
* Run the script as admin to test registry writes

---

## 📜 License

MIT. See `LICENSE` for details.

---

## 🙌 Credits

* Community feedback and testing from PC-gaming/handheld users.
* Playnite, Steam, and GOG are trademarks of their respective owners. This project is unaffiliated.

---

### Disclaimer

Editing Winlogon settings can affect startup behavior. This tool keeps `userinit.exe` in place and appends your selection, which is the **safe** pattern. Use at your own risk and always keep a local admin account available.
