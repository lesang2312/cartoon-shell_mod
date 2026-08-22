## 🎯 Introduction

**Cartoon Shell** is a modern Wayland panel built entirely with **QuickShell** (QML) specifically for **Hyprland window manager**. The panel provides a smooth user experience with highly customizable interface, multi-language support, and multi-resolution display compatibility.

<div align="center">
  <video src="https://github.com/user-attachments/assets/7b68022d-6507-4404-b2a8-b68e6275a9ce" controls width="600" height="337.5"></video>
</div>

</p>
> [!NOTE]
> This is an updated and feature-extended version of the original "cartoon-shell" project created and owned by **Mai Duong Long** (mailong2401).

## 💻 System Requirements

### Operating System
- **Linux** (developed on Arch Linux)
- **Wayland** compositor (X11 not supported)
- **Hyprland(Lua)** window manager (required)

## 🔧 Installation

### Install dependencies (Arch Linux)

#### Full setup with dotfiles
```bash
cd ~
git clone https://github.com/lesang2312/dotfiles-hyprland
cd dotfiles-hyprland
chmod +x setup.sh
./setup.sh
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
```

## 🎛️ Custom Kitty Opacity Slider & New Updates

This version introduces a built-in visual slider inside the control panel, allowing you to dynamically adjust your Kitty terminal transparency on-the-fly without manual configuration editing.

### Kitty Opacity Feature:
- Real-time background opacity adjustments.
- Instant integration with the active Kitty instances.
- Smooth transition effects.

### Opacity Slider Preview
<div align="center">
  <img width="318" height="50" alt="image" src="https://github.com/user-attachments/assets/57ac4ea1-eb00-4a02-823a-2cda1e297e4c" />
  <img width="1334" height="702" alt="image" src="https://github.com/user-attachments/assets/29054dd0-327f-43cd-9903-0d4a941ebca8" />
</div>

### How to use the Opacity Slider:
* **Step 1**: Open the Cartoon Shell dashboard/control panel.
* **Step 2**: Locate the dedicated **Kitty Opacity Slider** component.
* **Step 3**: Drag the slider left to increase transparency, or right to make the window solid.
* **Step 4**: The transparency values are automatically managed and saved for your next terminal sessions.

### ✨ Other Key Updates in This Build:
Along with the opacity slider, this version brings numerous improvements and core enhancements to ensure a smoother desktop experience:
- **Performance Tweaks**: Optimized QML rendering inside Quickshell to reduce overall CPU and RAM usage.
- **UI & Layout Fixes**: Improved padding, alignment, and responsiveness across different monitor resolutions.
- **System Stability**: Fixed random panel crashes when switching system workspaces rapidly.
- **Smarter Caching**: Configuration files load faster upon launching the system panel.

## 🎨 Dashboard App Grid Customization

You can fully customize the applications, display names, and replace the default pixel-art icons inside the App Grid by modifying the configuration file.

### Configuration File Path:
```bash
~/.config/cartoon-shell/settings.json
```

### Grid Layout Preview
Here is how the 3x3 App Grid looks inside the dashboard panel with custom pixel-art icons applied:

<div align="center">
  <img width="155" height="157" alt="image" src="https://github.com/user-attachments/assets/24aee1bc-0234-4fe0-8782-7ef353423254" />
</div>


### How to Change Application Icons:

* **Step 1**: Prepare your custom icon files (ideally in `.png` format for transparency).
* **Step 2**: Copy your new icons directly into the project's icon directory:
  ```bash
  ~/.config/quickshell/cartoon-shell/icons/
  ```
* **Step 3**: Open your `settings.json` file using any text editor (e.g., VS Code, VSCodium, or Nano).
* **Step 4**: Locate the `"dashboard"` object and look for the `"appGrid"` array.
* **Step 5**: Update the `"name"` and `"icon"` values with your preferred app titles and full image file paths.

#### Configuration Example (`settings.json`):
```json
"dashboard": {
    "appGrid": [
        {
            "name": "Brave",
            "icon": "/home/linux-sieu-cap-pro-cua-le/.config/quickshell/cartoon-shell/icons/animal.png"
        },
        {
            "name": "Cốc Cốc",
            "icon": "/home/linux-sieu-cap-pro-cua-le/.config/quickshell/cartoon-shell/icons/anime.png"
        },
        {
            "name": "Terminal",
            "icon": "kitty"
        }
    ],
    "fullname": "Your fullname",
    "username": "Your username",
}
```
*Note: For built-in system applications, you can just input the native icon theme name (like `"kitty"`) instead of using an absolute file path.*

* **Step 6**: Save the file. **Cartoon Shell** will instantly refresh and apply your new application names and custom graphics.


## 📅 Customizing Calendar Reminder Sounds

You can fully customize your calendar reminder notification sounds by adding any audio file format (.mp3, .wav, .ogg, etc.) directly into the panel's calendar directory.

### Sound Assets Directory:
```bash
~/.config/quickshell/cartoon-shell/modules/panels/calendar/sounds/
```

### Grid Layout Preview & Sound Settings
Here is how the dashboard grid panel looks with custom configurations:

<div align="center">
  <img src="https://github.com/user-attachments/assets/c2393a7b-87bc-4e62-ac5c-0adaba4efe25" width="250px" alt="Preview 1" style="display:inline-block; vertical-align:middle; margin-right:10px;"/>
  <img src="https://github.com/user-attachments/assets/01ea9d37-2780-4f6c-80e3-7cee2d3bafc6" width="180px" alt="Preview 2" style="display:inline-block; vertical-align:middle; margin-right:10px;"/>
  <img src="https://github.com/user-attachments/assets/2756d067-7acd-4625-befa-dbb34719145f" width="170px" alt="Preview 3" style="display:inline-block; vertical-align:middle;"/>
</div>


### How to Change the Reminder Sound:

* **Step 1**: Prepare your preferred audio file (All popular formats like `.mp3`, `.wav`, or `.ogg` are supported).
* **Step 2**: Copy your audio file directly into the calendar sounds folder:
  ```bash
  ~/.config/quickshell/cartoon-shell/modules/panels/calendar/sounds/
  ```
* **Step 3**: Rename the audio file or update the calendar module configurations to reference your newly added file.
* **Step 4**: Restart the **Cartoon Shell** panel, and your custom audio track will now play whenever a scheduled calendar reminder triggers.
