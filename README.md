# FibPlus Library

FibPlus is a fast, easy-to-use component library for Delphi and C++Builder that works with Firebird and InterBase directly through the native client API, with no extra data access layers in between.

It is built for database application developers and has grown from their real-world needs: every component, method and property is designed to solve the tasks you face every day.


## 📚 Documentation

See the [documentation](Docs/README.md): a guide to features such as transactions and timeouts, and a reference of classes, properties, methods and events.


## 📦 Installation

The `Packages` folder contains a project group `FibPlus_Dxx.groupproj` for each supported Delphi version, where `xx` is the product version:

| Delphi | Suffix |
|--------|--------|
| 13 Florence | D37 |
| 12 Athens | D29 |
| 11 Alexandria | D28 |
| 10.4 Sydney | D27 |
| 10.3 Rio | D26 |
| 10.2 Tokyo | D25 |
| 10.1 Berlin | D24 |
| 10 Seattle | D23 |

Each group contains these packages:

| Package | Type | Purpose |
|---------|------|---------|
| `FIBPlus_Dxx` | runtime | Components, required by the other packages |
| `DclFIBPlus_Dxx` | design time | Registers the components in the Tool Palette |
| `FIBPlusEditors_Dxx` | design time | Property and component editors, VCL login dialog for the IDE |
| `FIBPlusFMX` | runtime | FireMonkey login dialog (`FIB_FMX_DBLoginDlg`), Delphi 13 and later |

### 🛠️ Steps

1. Open `Packages\FibPlus_Dxx.groupproj` for your Delphi version.
2. In Project Manager, select the **Win32** platform (**Win64x** for the 64-bit IDE) for all packages.
3. Right-click `FIBPlus_Dxx` and choose **Build**. It is a never-build package (`{$IMPLICITBUILD OFF}`), so it must be built explicitly before the design packages. Skipping this step causes *E2225 Never-build package 'FibPlus_Dxx' must be recompiled*.
4. Right-click `DclFIBPlus_Dxx`, choose **Build**, then **Install**.
5. Right-click `FIBPlusEditors_Dxx`, choose **Build**, then **Install**.
6. In **Tools > Options > Language > Delphi > Library**, add the `Source` folder to the **Library path** for every target platform you use (Win32, Win64, ...).

The runtime package itself does not need to be installed. The design packages exist only for the IDE platform (Win32, or Win64x for the 64-bit IDE), as the IDE loads them; for Win64 applications it is enough to set the library path, as in step 6. Build `FIBPlus_Dxx` for Win64 only if your application is built with runtime packages. `FIBPlusFMX` is needed only by FireMonkey applications built with runtime packages; otherwise add `FIB_FMX_DBLoginDlg` to the uses clause.

The packages write their DCU files to `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`, e.g. `C:\Users\Public\Documents\Embarcadero\Studio\37.0\Dcu\FIBPlus\Win32\Release`. This folder is separate for each Delphi version, so several versions installed on the same machine don't overwrite each other's DCU files. Adding this folder to the library path, before `Source`, is optional and only avoids recompiling FibPlus in each project; `Source` stays needed for the form and resource files.


## ❤️ Support FibPlus

Keeping FibPlus alive takes real time: fixing bugs, reviewing patches and adapting the code to every new Delphi and Firebird release. If FibPlus powers your apps, please consider [becoming a backer](Docs/SPONSORS.md) — monthly or one-time, every contribution helps.

[![Become a backer](https://img.shields.io/badge/Become_a_backer-❤-e25555?style=for-the-badge)](Docs/SPONSORS.md)


## ⚠️ Disclaimer

*This repository is an attempt to keep alive one of the best suite of components that seems to be abandoned by Devrace, without pretending to any copyrights. Initial source code was taken from public forums.*

*The goal of this project is to collect patches, fix bugs, adjust code to latest versions of Delphi, improve functionality by adding new features.*
