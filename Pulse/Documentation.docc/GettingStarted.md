# Getting Started

Set up your development environment and understand the Pulse architecture.

## Overview

This guide walks you through setting up the Pulse iOS project and understanding
its Unidirectional Data Flow (UDF) architecture.

## Prerequisites

- Xcode 26.2 or later
- iOS 26.2 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Setup

1. Clone the repository
2. Run the setup command:

```bash
make setup
```

This installs XcodeGen and generates the Xcode project.

3. Open the project:

```bash
make xcode
```

## Project Structure

```
Pulse/
├── Home/                   # Home feed feature
│   ├── API/                # Service protocols + implementations
│   ├── Domain/             # Interactor, State, Action, Reducer
│   ├── ViewModel/          # HomeViewModel
│   ├── View/               # SwiftUI views
│   └── Router/             # Navigation router
├── ForYou/                 # Personalized feed (Premium)
├── Feed/                   # AI Daily Digest (Premium)
├── Search/                 # Search feature
├── Bookmarks/              # Offline reading
├── Settings/               # User preferences
└── Configs/                # Shared infrastructure
```

## Adding a New Feature

1. Create the feature folder with standard subfolders:
   - `API/` - Service protocol and implementations
   - `Domain/` - Interactor, State, Action, EventActionMap, ViewStateReducer
   - `ViewModel/` - ViewModel implementation
   - `View/` - SwiftUI views
   - `Router/` - Navigation router

2. Register services in `PulseSceneDelegate.setupServices()`

3. Add the feature's tab to `Coordinator` if needed

## Running Tests

```bash
make test          # All tests
make test-unit     # Unit tests only
make test-ui       # UI tests only
make test-snapshot # Snapshot tests only
```

## Code Quality

```bash
make lint    # Check code style
make format  # Auto-fix formatting
```
