# Machine Ready TV

Custom CSS Loader themes designed to deliver a more console-like Steam Big Picture experience.

---

## 💾 Installation

> ⚠️ **Prerequisites:**  
> **Decky Loader** and the **CSS Loader** plugin are **required** to use these themes and profiles.  
> If you don't have them installed yet, please set up [Decky Loader](https://decky.xyz/) and install **CSS Loader** via the Decky Store in Gaming Mode before proceeding.

### 🚀 Option 1: Automatic Installation (Recommended)
The fastest and easiest way to install all themes and profiles. The installer verifies required dependencies (**Decky Loader** and **CSS Loader**), clones/updates the latest repository version, and gives you the option to install pre-configured profiles.

1. Switch your Steam Deck to **Desktop Mode** (`STEAM` button → `Power` → `Switch to Desktop`).
2. Open the **Konsole** app from your application menu.
3. Copy, paste, and run the following command:
```bash
curl -sSL [https://raw.githubusercontent.com/leoooorocha/Machine-Ready-TV/main/scripts/auto-install.sh](https://raw.githubusercontent.com/leoooorocha/Machine-Ready-TV/main/scripts/auto-install.sh) | bash
```
4. Follow the prompt in the terminal asking if you want to install pre-configured profiles.
5. Once completed, return to **Gaming Mode** using the desktop shortcut.

---

### 📦 Option 2: Manual Installation
If you prefer to set up everything by hand, follow these steps:

#### 1. Core Themes
1. Click **Code** → **Download ZIP** (or clone the repository).
2. Extract the archive and copy all theme folders.
3. Paste them into your Deck's theme directory:  
   `~/homebrew/themes`

#### 2. Optional Profiles
1. Copy the desired `.profile` folders from the **Profiles** directory.
2. Paste them alongside your themes inside `~/homebrew/themes`.

---

## ⚙️ Post-Installation Profile Setup

> 💡 **Machine Ready is fully compatible with the SteamGridDB plugin.**  
> *If you want square capsules and matching artwork, feel free to install it via the Decky Store.*

To complete the setup for your profiles:

1. Open the **CSS Loader Theme Store** and install these dependencies:
   * **Animated PSP Waves Background** *(only for **PSP OLED** profile)*
   * **Avatar Customization Suite**
   * **Better Blur**
   * **Centered Game Text**
   * **Clean Library Capsule**
   * **Focus Highlight Color**     
   * **Game Cover Shine Animation Color**
   * **Main Menu Hide Tabs** *(Hide the Store)*
   * **No Friend Playing Icon**
   * **No Hero Gradient**
   * **No Home Tabs**
   * **Proper Hero Scaling** *(only for **Back 2 Basic** profile)*
   * **QAM Hide Tabs**
   * **Top Bar Padding**
   * **Volume Tweaker**
2. Click the **Settings** ⚙️ button on the top-right of CSS Loader.
3. Navigate to **Settings** → **Enable Nav Patch**, and toggle it **On**.
   > 💡 *Some themes require Nav Patch to force Steam to ignore hidden elements.*
4. Go back to QAM CSS Loader, scroll to the bottom, and click **Refresh**.
5. Select and apply your preferred **Machine Ready** profile.

---

## 🛠️ About Custom Patches

These themes already exist in the Store, but I created custom patches to further improve their compatibility with Machine Ready.

* **Clean Game Launch**
  * Features an additional option to remove filters when launching a game.
  <img src="Clean Game Launch/Clean Game Launch - Patch.jpg" width="800" alt="Clean Game Launch">

* **Clean Gameview**
  * Features a fullscreen layout based on screen size and more options for the playbar.
  <img src="Clean Gameview/Clean Gameview - Patch.jpg" width="800" alt="Clean Gameview">

* **Colored Toggles**
  * Features advanced customization options, including an animated background for any custom gradient.
  <img src="Colored Toggles/Colored Toggles - Patch 3.jpg" width="800" alt="Colored Toggles">

* **Round**
  * Includes several patches with expanded options for the keyboard (with padding so roundness doesn't hide action buttons), all menus, and the settings page.
  <img src="Round/Round - Patch 1.jpg" width="800" alt="Round Patch">

> 💡 *Check each theme folder to see all available custom patches.*

---

## 🖼️ Profile Previews

### Clean Glass (Old Standard)
<img src="Profiles/MR - Clean Glass.profile/preview-1.jpg" width="800">

### PSP OLED
<img src="Profiles/MR - PSP OLED.profile/preview-1.jpg" width="800">

### Soft Play
<img src="Profiles/MR - Soft Play.profile/preview-1.jpg" width="800">

### Switch Grey
<img src="Profiles/MR - Switch Grey.profile/preview-1.jpg" width="800">

### Back 2 Basic
<img src="Profiles/MR - Back 2 Basic.profile/preview-1.jpg" width="800">

### 🎨 Color Palette
*Red, Orange, Yellow, Lime, Green, Mint, Cyan, Blue, Indigo, Purple, Magenta, Pink*

| | |
|---|---|
| <img src="Profiles/MR - Colors 01 - Red.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 02 - Orange.profile/preview-1.jpg" width="400"> |
| <img src="Profiles/MR - Colors 03 - Yellow.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 04 - Lime.profile/preview-1.jpg" width="400"> |
| <img src="Profiles/MR - Colors 05 - Green.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 06 - Mint.profile/preview-1.jpg" width="400"> |
| <img src="Profiles/MR - Colors 07 - Cyan.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 08 - Blue.profile/preview-1.jpg" width="400"> |
| <img src="Profiles/MR - Colors 09 - Indigo.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 10 - Purple.profile/preview-1.jpg" width="400"> |
| <img src="Profiles/MR - Colors 11 - Magenta.profile/preview-1.jpg" width="400"> | <img src="Profiles/MR - Colors 12 - Pink.profile/preview-1.jpg" width="400"> |

---

## 🤝 Credits & Acknowledgments

Full credit for the original themes featured in the custom patches goes to the amazing creators:
* **Niko**
* **SuchMeme**
* **EMERALD#0874**

Special thanks to:
* **Hannaway96** for writing and contributing the incredible bash automation installer.

*Thank you for making this project possible!*
