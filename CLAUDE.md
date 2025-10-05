# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CountryCollector is a 2D dart-throwing game where players throw darts at a world map to collect countries. Players earn levels and unlock abilities that help them complete their collection. Built with Godot 4.5, targeting web platforms using GL Compatibility rendering.

## Running and Building

- **Run in editor**: Open project in Godot 4.5 and press F5
- **Export for web**: Use Godot's export menu (Project > Export) with the HTML5/Web preset
- **Lint GDScript files**: After creating or modifying `.gd` files, run linting to check for errors:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --check-only --path . --script path/to/file.gd
  ```
  Example: `/Applications/Godot.app/Contents/MacOS/Godot --check-only --path . --script Scenes/clickable_world.gd`

## Game Design

### Core Mechanics

- **Dart throwing**: Players aim and throw darts at a world map
- **Country collection**: Successfully hitting a country adds it to the player's collection
- **Progression system**: Players earn levels as they collect countries
- **Abilities**: Unlock special abilities that help complete the collection (e.g., better aim, larger hit radius, hints)

### Target Platform

Web browser (HTML5 export), optimized for mouse/touch input

## Project Architecture

### Core Components

- **GameState singleton** (`GameState.gd`): Global autoload managing game state and events

  - **Properties**:
    - `all_countries: Array[String]` - List of all countries loaded from the map
    - `collected_countries: Array[String]` - List of countries the player has collected
  - **Signals**:
    - `countries_loaded()` - Emitted when all countries from the map have been loaded
    - `country_collected(country_id: String)` - Emitted when a player collects a country
  - **Key methods**:
    - `add_country(country_id)` - Adds a country to the all_countries list (called by ClickableWorld during map loading)
    - `collect_country(country_id)` - Marks a country as collected and emits the signal
    - `is_collected(country_id)` - Check if a country has been collected
  - All game events flow through this singleton for centralized state management

- **ClickableWorld node** (`Scenes/clickable_world.gd`): The map rendering and hit detection system

  - Loads SVG world map files and extracts the viewBox for coordinate mapping
  - Renders each country as an independent Sprite2D using `Image.load_svg_from_string()`
  - Parses SVG `<path>` elements and creates individual SVG sprites per country
  - Uses pixel-perfect collision detection via BitMap generated from sprite alpha channels
  - Registers each country with `GameState.add_country()` during sprite creation
  - Calls `GameState.collect_country()` when a country is clicked
  - Emits `country_clicked(id: String)` signal when a dart hits a country (legacy, prefer using GameState signals)

- **Game scene** (`Scenes/Game.tscn`): Root scene containing game logic, UI, and progression systems

### SVG Processing Pipeline

1. **Viewbox extraction**: Reads SVG `viewbox` attribute (lowercase) to determine original coordinate space
2. **Coordinate transformation**: Calculates scale and offset to fit the map to `fit_size` (default 1800x1200)
3. **Country identification**: Extracts all `<path>` elements and identifies countries by attribute priority:
   - `name` attribute (highest priority)
   - `class` attribute (medium priority)
   - `id` attribute (fallback)
4. **Individual SVG creation**: For each country path, creates a minimal SVG document containing only that path
5. **Sprite rendering**: Rasterizes each country's SVG into a Sprite2D texture using Godot's SVG renderer
6. **Collision generation**:
   - Creates `BitMap` from sprite's alpha channel (threshold: 0.1)
   - Converts bitmap to collision polygons using `opaque_to_polygons()` (epsilon: 2.0)
   - Generates multiple `CollisionPolygon2D` nodes per country if needed
   - Attaches `Area2D` to each sprite for click/hover detection

### Key Implementation Details

- Each country is a separate `Sprite2D` node with its own texture, positioned at `_offset`
- All sprites share the same viewbox, so they overlay correctly to form the complete map
- Pixel-perfect collision avoids false positives from overlapping sprite rectangles
- The SVG renderer handles all path complexity (curves, arcs, etc.) automatically
- Country metadata is stored in Area2D's `country_id` meta property for event handling

### Signal Flow and State Management

The game uses a centralized signal architecture through the GameState singleton:

1. **Map Loading**: ClickableWorld parses SVG → calls `GameState.add_country()` for each country → emits `GameState.countries_loaded` when complete
2. **Country Collection**: User clicks country → ClickableWorld calls `GameState.collect_country()` → emits `GameState.country_collected` signal
3. **UI Updates**: UI components connect to GameState signals and react to state changes

This pattern ensures:

- Single source of truth for game state
- Decoupled components that communicate through signals
- Easy debugging with centralized state tracking
- Consistent behavior across all game systems

## Working with Maps

- Place SVG map files in `Assets/` directory
- Assign the SVG file to the `svg_path` export variable in the Inspector for ClickableWorld nodes
- SVG paths should have identifying attributes to identify clickable regions:
  - `name` attribute (preferred, e.g., `name="France"`)
  - `class` attribute (alternative, e.g., `class="France"`)
  - `id` attribute (fallback, e.g., `id="FR"`)
- Multi-part countries (e.g., island nations) with multiple `<path>` elements sharing the same identifier will be rendered as separate sprites

# important-instruction-reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (\*.md) or README files. Only create documentation files if explicitly requested by the User.
ALWAYS run `/Applications/Godot.app/Contents/MacOS/Godot --check-only --path . --script <file.gd>` after creating or significantly modifying GDScript files to catch syntax errors and warnings.
