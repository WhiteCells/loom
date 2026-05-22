# Packaging Scripts

Run the packaging script on the target platform with Qt 6.5+ and CMake available.

```bash
script/package.sh
```

Platform-specific entry points:

```bash
script/package-linux.sh
script/linux/archlinux/build-package.sh
script/package-macos.sh
script/package-windows.ps1
script/package-windows.cmd
```

Useful options:

```bash
script/package-linux.sh --config Release --clean
script/linux/archlinux/build-package.sh --clean
script/package-macos.sh --qt-prefix /path/to/Qt/6.x/macos
```

On Windows:

```powershell
script\package-windows.ps1 -Config Release -Clean -QtPrefix C:\Qt\6.x\msvc2022_64
```

Packages are written under `dist/`. The generic platform scripts build through CMake, install into a staging directory, run Qt deployment from the CMake install rules, and then archive the staged app. The Arch Linux script runs `makepkg` and writes the pacman package under `dist/archlinux/`.
