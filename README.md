# Elegy of Ascension

An open-source 2D game built with [Godot](https://godotengine.org/).

## Getting Started

### Prerequisites

- **Godot Engine 4.7** (standard build — the project does not use C#/.NET).
  Download it from the [official site](https://godotengine.org/download) or [GitHub releases](https://github.com/godotengine/godot/releases).
- **Git** to clone the repository.

> The project targets Godot **4.7** with the **Mobile** rendering backend (see `project.godot`). Using a different major/minor engine version may cause import errors.

### Clone

```bash
git clone git@github.com:HEX-nova/Elegy-of-Ascension.git
cd Elegy-of-Ascension
```

(or use the HTTPS URL: `https://github.com/HEX-nova/Elegy-of-Ascension.git`)

### Run from the editor

1. Launch Godot 4.7.
2. From the Project Manager, click **Import**.
3. Select the `project.godot` file in the cloned folder and click **Import & Edit**.
4. Once the project opens, press **F5** (or the ▶ **Play** button in the top-right) to run the game.

The first launch will reimport all assets, which may take a moment.

### Run from the command line

If the `godot` binary is on your `PATH`:

```bash
# From inside the project directory
godot

# Or point it at the project explicitly
godot --path /path/to/Elegy-of-Ascension
```

### Exporting a build

Export presets are already configured for **Windows Desktop** and **Android**
(`export_presets.cfg`). To export, install the matching **export templates** via
*Editor → Manage Export Templates…*, then use *Project → Export…*. Android exports
additionally require the Android SDK/JDK to be configured in the editor settings.

## Contributing

## License

Released under the [GNU General Public License v3.0](LICENSE).
