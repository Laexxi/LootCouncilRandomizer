# LootCouncilRandomizer

**Version:** 1.6.0
**Author:** Laexxi-Antonidas

LootCouncilRandomizer helps guilds to randomly select loot council members from predefined groups. This addon allows guild leaders to import guild members, assign them to custom groups, and ensure fair and unbiased loot distribution by preventing re-selection within a configurable timeframe.

## Features

- **Import Guild Members:** Easily import guild members and assign them to custom groups.
- **Random Selection:** Randomly select loot council members based on group configurations.
- **User Interface:** Intuitive UI with a minimap button and organized guild overview.
- **Statistics Tracking:** Track and display selection statistics to monitor fairness.
- **Re-selection Prevention:** Prevent re-selection of members within a configurable timeframe.

## Installation

1. Download the latest version of LootCouncilRandomizer from [CurseForge](https://www.curseforge.com).
2. Extract the downloaded zip file to your World of Warcraft `Interface/AddOns` directory.
3. Launch World of Warcraft and enable the addon from the AddOns menu.

## Usage

### Commands

- **Open the main window:**

```lua
/lcr open
```

- **Randomize the council:**

```lua
/lcr roll
```

### Configuration

1. **Group Creation and Assignment:**

- Import guild members and assign them to custom groups.
- Set the number of groups and members per group.

2. **Re-selection Prevention:**

- Configure the re-selection prevention settings per group to avoid selecting the same members within a specific timeframe.

(Not implemented yet) 3. **Localization:**

- The addon supports multiple languages. It will default to the client's language, with a fallback to English.

## Upcoming Features

- **Localization**
- **Sync for settings and statistics.**

## Support

For bug reports, feature suggestions, and general support, please visit our [GitHub repository](https://github.com/Laexxi/LootCouncilRandomizer).

## License

This project is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file for details.
