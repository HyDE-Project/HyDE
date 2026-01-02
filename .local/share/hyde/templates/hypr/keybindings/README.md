# HyDE Keyboard Layout Templates

This directory contains keyboard layout-specific keybinding configurations for HyDE.

## 📋 Available Layouts

- **`keybindings-abnt2.conf`** - Brazilian ABNT2 layout (Portuguese BR)

## 🚀 How to Use

### Option 1: Copy to Your Config

```bash
# Choose the appropriate keybindings file for your keyboard layout
cp keybindings-abnt2.conf ~/.config/hypr/keybindings.conf

# Reload Hyprland
# Method 1: Use keybinding (SUPER+SHIFT+R)
# Method 2: Restart your session
```

### Option 2: Symlink (Advanced)

```bash
# Create a symbolic link (changes will reflect automatically)
ln -sf ~/.local/share/hyde/templates/hypr/keybindings/keybindings-abnt2.conf \
       ~/.config/hypr/keybindings.conf
```

## 🌍 Contributing New Layouts

Want to add support for your keyboard layout? Here's how:

### 1. Understand the Issue

Most keyboard layout conflicts happen because:
- Special characters require SHIFT key (e.g., `@` = Shift+2 in ABNT2)
- Default keybindings may use these same combinations
- **However**: Hyprland captures key presses BEFORE layout conversion
- This means `SUPER+SHIFT+2` works correctly even on layouts where Shift+2 = @

### 2. Test Before Creating

Before creating a new layout template, **test if the default bindings actually conflict**:

```bash
# Try these tests:
1. Open a text editor
2. Type Shift+2 (should produce @ or your layout's symbol)
3. Press SUPER+SHIFT+2 (should move window to workspace 2)
4. If both work correctly, you may not need a custom layout!
```

### 3. When to Create a Custom Layout

Create a custom layout file only if:
- ✅ You confirmed actual conflicts with default keybindings
- ✅ You need to relocate bindings for better ergonomics
- ✅ Your physical keyboard layout differs significantly from US

### 4. How to Create Your Layout

```bash
# 1. Copy the base template
cp keybindings-abnt2.conf keybindings-YOUR_LAYOUT.conf

# 2. Add a descriptive header explaining:
#    - Your keyboard layout name and region
#    - What conflicts you're solving
#    - Which keybindings you changed and why
#    - Testing instructions

# 3. Modify only the conflicting keybindings

# 4. Test thoroughly before submitting
```

### 5. Header Template

Add this header to your new layout file:

```conf
# ============================================
# HyDE Keybindings - [LAYOUT NAME]
# ============================================
# 
# Author: [Your Name/Username]
# Created: [Date]
# Layout: [Full Layout Name] ([Region])
#
# Description:
# ------------
# [Explain what issues this layout solves]
#
# Main Changes from Default:
# ---------------------------
# 1. [List specific changes]
# 2. [And why you made them]
#
# Special Characters Reference:
# ------------------------------
# [Document how symbols are produced in your layout]
#
# Testing Your Configuration:
# ----------------------------
# [Provide test steps to verify it works]
#
# ============================================
```

### 6. Guidelines for Modifications

- ✅ **DO**: Change modifier keys (Shift → Alt, Ctrl, etc.) if needed
- ✅ **DO**: Relocate bindings to more ergonomic positions
- ✅ **DO**: Document every change clearly
- ✅ **DO**: Keep functionality consistent where possible
- ❌ **DON'T**: Remove essential keybindings
- ❌ **DON'T**: Change bindings just for personal preference
- ❌ **DON'T**: Make undocumented changes

### 7. Submit Your Contribution

```bash
# 1. Fork the HyDE repository
# 2. Create a branch: git checkout -b add-LAYOUT-keybindings
# 3. Add your file to: .local/share/hyde/templates/hypr/keybindings/
# 4. Update this README with your layout
# 5. Commit: git commit -m "feat: Add LAYOUT keyboard layout keybindings"
# 6. Push and create a Pull Request
```

## 📖 Layout-Specific Documentation

### ABNT2 (Brazilian Portuguese)

**Special Characters:**
- `@` → Shift+2
- `#` → Shift+3  
- `$` → Shift+4
- `%` → Shift+5
- `&` → Shift+7
- `*` → Shift+8
- `(` → Shift+9
- `)` → Shift+0

**Dead Keys:** `´` (acute), `` ` `` (grave), `^` (circumflex), `~` (tilde)

**Important Note:**
The default HyDE keybindings work correctly with ABNT2 because Hyprland captures key presses before the layout processes them. For example, `SUPER+SHIFT+2` will move a window to workspace 2 and will NOT produce the `@` symbol.

**Changes in this template:**
- None! The default keybindings are fully compatible
- This template includes comprehensive documentation for ABNT2 users
- Serves as a reference for understanding how keybindings work with this layout

---

## 🐛 Reporting Issues

If you encounter keyboard layout issues:

1. Test with the default keybindings first
2. Document exactly what keybinding conflicts with what symbol
3. Provide your keyboard layout details (setxkbmap -query)
4. Report at: https://github.com/HyDE-Project/HyDE/issues/1442

## 💡 Tips

- Physical key positions matter more than the symbol printed on them
- Most Hyprland keybindings use physical key codes, not layout-specific symbols
- Test thoroughly before assuming a conflict exists
- When in doubt, check with: `wev` (Wayland event viewer) to see actual key codes

## 📚 Additional Resources

- [Hyprland Keybinding Documentation](https://wiki.hyprland.org/Configuring/Binds/)
- [XKB Layout Documentation](https://www.x.org/wiki/XKB/)
- [Keyboard Layout List](https://en.wikipedia.org/wiki/Keyboard_layout)

---

**Contributors:** Add your name here when you submit a layout
- CapGuizera (ABNT2)
