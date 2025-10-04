# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CountryCollector is a 2D dart-throwing game where players throw darts at a world map to collect countries. Players earn levels and unlock abilities that help them complete their collection. Built with Godot 4.5, targeting web platforms using GL Compatibility rendering.

## Running and Building

- **Run in editor**: Open project in Godot 4.5 and press F5
- **Export for web**: Use Godot's export menu (Project > Export) with the HTML5/Web preset

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

- **ClickableWorld node** (`Scenes/clickable_world.gd`): The map rendering and hit detection system
  - Loads SVG world map files and extracts the viewBox for coordinate mapping
  - Renders each country as an independent Sprite2D using `Image.load_svg_from_string()`
  - Parses SVG `<path>` elements and creates individual SVG sprites per country
  - Uses pixel-perfect collision detection via BitMap generated from sprite alpha channels
  - Emits `country_clicked(id: String)` signal when a dart hits a country

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

## Working with Maps

- Place SVG map files in `Assets/` directory
- Assign the SVG file to the `svg_path` export variable in the Inspector for ClickableWorld nodes
- SVG paths should have identifying attributes to identify clickable regions:
  - `name` attribute (preferred, e.g., `name="France"`)
  - `class` attribute (alternative, e.g., `class="France"`)
  - `id` attribute (fallback, e.g., `id="FR"`)
- Multi-part countries (e.g., island nations) with multiple `<path>` elements sharing the same identifier will be rendered as separate sprites
