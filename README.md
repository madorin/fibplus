# FibPlus Library

Fast, flexible and high-performance component library for Delphi, C++ Builder and Kylix intended for work with InterBase and Firebird using Direct InterBase API.

FIBPlus is a flexible and easy-to-use library of Delphi, C++ Builder, Kylix components and Ada objects for direct work with InterBase and Firebird (Yaffil). It has been made for developers of database applications. From the very outset we were developing it in accordance with our customers wishes and requests. Every component, method and property is intended to solve the most common daily tasks.


## Installation

The `Packages` folder contains a project group `FibPlus_Dxx.groupproj` for each supported Delphi version, where `xx` is the product version:

| Delphi | Suffix |
|--------|--------|
| 10 Seattle | D23 |
| 10.1 Berlin | D24 |
| 10.2 Tokyo | D25 |
| 10.3 Rio | D26 |
| 10.4 Sydney | D27 |
| 11 Alexandria | D28 |
| 12 Athens | D29 |
| 13 Florence | D37 |

Each group contains three packages:

| Package | Type | Purpose |
|---------|------|---------|
| `FIBPlus_Dxx` | runtime | Components, required by the other two |
| `DclFIBPlus_Dxx` | design time | Registers the components in the Tool Palette |
| `FIBPlusEditors_Dxx` | design time | Property and component editors |

### Steps

1. Open `Packages\FibPlus_Dxx.groupproj` for your Delphi version.
2. In Project Manager, select the **Win32** platform (**Win64x** for the 64-bit IDE) for all three packages.
3. Right-click `FIBPlus_Dxx` and choose **Build**. It is a never-build package (`{$IMPLICITBUILD OFF}`), so it must be built explicitly before the design packages. Skipping this step causes *E2225 Never-build package 'FibPlus_Dxx' must be recompiled*.
4. Right-click `DclFIBPlus_Dxx`, choose **Build**, then **Install**.
5. Right-click `FIBPlusEditors_Dxx`, choose **Build**, then **Install**.
6. In **Tools > Options > Language > Delphi > Library**, add the `Source` folder to the **Library path** for every target platform you use (Win32, Win64, ...).

The runtime package itself does not need to be installed. The design packages exist only for the IDE platform (Win32, or Win64x for the 64-bit IDE), as the IDE loads them; for Win64 applications it is enough to set the library path, as in step 6. Build `FIBPlus_Dxx` for Win64 only if your application is built with runtime packages.


## ❤️ Support FibPlus

Keeping FibPlus alive takes real time: fixing bugs, reviewing patches and adapting the code to every new Delphi and Firebird release. If FibPlus powers your apps, please consider [becoming a backer](Docs/SPONSORS.md) — monthly or one-time, every contribution helps.

[![Become a backer](https://img.shields.io/badge/Become_a_backer-❤-e25555)](Docs/SPONSORS.md)


## Disclaimer

*This repository is an attempt to keep alive one of the best suite of components that seems to be abandoned by Devrace, without pretending to any copyrights. Initial source code was taken from public forums.*

*The goal of this project is to collect patches, fix bugs, adjust code to latest versions of Delphi, improve functionality by adding new features.*
