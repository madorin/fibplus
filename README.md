# <img src="Docs/images/fibplus-title.png" width="40" height="44" align="absmiddle" alt=""> FIBPlus Library

FIBPlus is a fast, easy-to-use component library for Delphi and C++Builder that works with Firebird and InterBase directly through the native client API, with no extra data access layers in between.

It is built for database application developers and has grown from their real-world needs: every component, method and property is designed to solve the tasks you face every day.

<p align="center">
  <a href="Docs/README.md"><picture>
    <source media="(prefers-color-scheme: dark)" srcset="Docs/images/palette-dark.png">
    <img src="Docs/images/palette-light.png" width="956" alt="FIBPlus component palette">
  </picture></a>
</p>


## 📚 Documentation

See the [documentation](Docs/README.md): a guide to features such as transactions and timeouts, and a reference of classes, properties, methods and events.


## 📦 Installation

The project groups are in the `Packages` folder:

| Delphi | Project group |
|--------|---------------|
| 10.4 Sydney and later | `FIB.groupproj` |
| 10.3 Rio | `FIB_D26.groupproj` |
| 10.2 Tokyo | `FIB_D25.groupproj` |
| 10.1 Berlin | `FIB_D24.groupproj` |
| 10 Seattle | `FIB_D23.groupproj` |

FIBPlus 8 supports Delphi 2009 and later; use 7.9.x for Delphi 6 to 2007. Packages before Delphi 10.4 are named after the [package version](https://docwiki.embarcadero.com/RADStudio/en/Compiler_Versions), from `FIB_D12` (Delphi 2009) to `FIB_D26` (10.3 Rio).

| Package | Type | Purpose |
|---------|------|---------|
| `FIB` (`FIB_Dxx` before 10.4) | runtime | Components, required by the other packages |
| `dclFIB` (`dclFIB_Dxx` before 10.4) | design time | Tool Palette registration, property and component editors, IDE login dialog |
| `dclFIBTools` | design time, optional | **Tools > FIBPlus** menu; closes the design-time connections before the program runs from the IDE |
| `FIBFMX` | runtime | FireMonkey login dialog (`FIB_FMX_DBLoginDlg`) |

`dclFIBTools` and `FIBFMX` exist for Delphi 10.4 and later, where each package is one `.dpk` for all versions and `{$LIBSUFFIX AUTO}` adds the version suffix to the BPL, e.g. `FIB370.bpl` for Delphi 13.

### 🛠️ Steps

1. Open the project group and select the **Win32** platform for all packages.
2. Right-click the project group and choose **Build All**.
3. Right-click `dclFIB` and choose **Install**; optionally install `dclFIBTools` too.
4. In **Tools > Options > Language > Delphi > Library**, add the `Source` folder to the **Library path** of every target platform you use.

**64-bit IDE** (Delphi 12.3 and later): select **Windows 64-bit** instead of Win32 and install the packages from `BplWin64`, which must be on the PATH of the 64-bit IDE. Win64x (Modern C++) is not what the 64-bit IDE loads.

### 📝 Notes

- Applications compile FIBPlus from `Source` for any target platform (Win32, Win64, ...). Build `FIB` and `FIBFMX` for a platform only if your application uses runtime packages.
- The DCU files go to `$(BDSCOMMONDIR)\Dcu\FIBPlus\$(Platform)\$(Config)`, separate for each Delphi version. Adding this folder to the library path, before `Source`, avoids recompiling FIBPlus in each project; `Source` stays needed for the form and resource files.
- **Language**: `Locales` has the error messages and the login dialog in English (`en`, the default), Czech (`cs`), German (`de`), Spanish (`es`), Polish (`pl`), Portuguese (Brazil) (`pt-BR`), Romanian (`ro`), Russian (`ru`) and Ukrainian (`uk`). Set the code in `Source\FIBLocale.inc`, for example `FIBLocale = 'ro';`, and rebuild the packages and your application (with **Build**, so FIBPlus is compiled again). See [Localization](Docs/guide/localization.md). This translates the errors raised by FIBPlus itself (`EFIBClientError`) and the login dialog; other FIBPlus exceptions and the server messages stay in English.


## ❤️ Support FIBPlus

Keeping FIBPlus alive takes real time: fixing bugs, reviewing patches and adapting the code to every new Delphi and Firebird release. If FIBPlus powers your apps, please consider [becoming a backer](Docs/SPONSORS.md) — monthly or one-time, every contribution helps.

[![Become a backer](https://img.shields.io/badge/Become_a_backer-❤-e25555?style=for-the-badge)](Docs/SPONSORS.md)


## ⚠️ Disclaimer

*This repository is an attempt to keep alive one of the best suite of components that seems to be abandoned by Devrace, without pretending to any copyrights. Initial source code was taken from public forums.*

*The goal of this project is to collect patches, fix bugs, adjust code to latest versions of Delphi, improve functionality by adding new features.*
