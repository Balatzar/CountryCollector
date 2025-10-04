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
  - Renders the SVG as a rasterized background using `Image.load_svg_from_string()`
  - Parses SVG `<path>` elements to create collision polygons for hit detection
  - Emits `country_clicked(id: String)` signal when a dart hits a country
  - Provides hover effects for visual feedback

- **Game scene** (`Scenes/Game.tscn`): Root scene containing game logic, UI, and progression systems

### SVG Processing Pipeline

1. **Viewbox extraction**: Reads SVG viewBox attribute to determine original coordinate space
2. **Coordinate transformation**: Calculates scale and offset to fit the map to `fit_size` (default 1400x800)
3. **Background rendering**: Rasterizes the entire SVG at calculated scale for visual display
4. **Path parsing**: Custom SVG path parser (`_flatten_svg_path`) that supports:
   - Movement: M/m
   - Lines: L/l, H/h, V/v
   - Bezier curves: C/c, S/s, Q/q, T/t
   - Arcs: A/a (approximated as straight lines)
   - Close path: Z/z
5. **Collision generation**:
   - Creates `Area2D` nodes with `CollisionPolygon2D` for each valid path
   - Automatically simplifies polygons with >100 points using Ramer-Douglas-Peucker algorithm
   - Validates polygons (minimum area, distinct points)
   - Stores country ID in node metadata for click detection

### Key Implementation Details

- SVG coordinates are transformed to screen space: `world_pos = svg_pos * _scale + _offset`
- Complex polygons are simplified to prevent collision system issues (tolerance: 2.0 pixels)
- Hover effects are implemented via mouse_entered/mouse_exited signals on Area2D nodes
- Bezier curves are sampled into line segments (adaptive step count based on distance)
- The visible Polygon2D and collision Area2D are separate nodes to allow independent control

## Working with Maps

- Place SVG map files in `Assets/` directory
- Assign the SVG file to the `svg_path` export variable in the Inspector for ClickableWorld nodes
- SVG paths must have `id` attributes to identify clickable regions (e.g., `id="france"`)
- The parser handles multi-part regions (e.g., island nations) by creating multiple Area2D nodes per ID
