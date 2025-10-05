# Store System Documentation

## Overview

The Store System allows players to acquire bonus cards that provide various benefits (and sometimes penalties) during gameplay. The system consists of reusable card components and a store overlay that displays 3 random cards for the player to choose from.

## Components

### 1. Card Component (`Scenes/Card.tscn` and `Scenes/Card.gd`)

A reusable card UI component that displays:
- **Card Name**: Title of the card
- **Bonuses Section**: List of positive effects (displayed in green with ✓)
- **Penalties Section**: List of negative effects (displayed in red with ✗)
- **Select Button**: Button to acquire the card

#### Features:
- **3D Hover Effect**: Cards tilt and scale when hovered using 2D transformations
- **Smooth Animations**: Damped rotation and scaling for polished feel
- **Customizable Data**: Cards are data-driven via Dictionary structure

#### Card Data Structure:
```gdscript
{
	"name": "Card Name",
	"bonuses": ["Bonus 1", "Bonus 2"],  # Array of strings
	"maluses": ["Penalty 1"]             # Array of strings
}
```

#### Usage Example:
```gdscript
# Create a card instance
var card = CARD_SCENE.instantiate()
add_child(card)

# Set card data
card.set_card_data({
	"name": "Eagle Eye",
	"bonuses": ["Increased accuracy", "Larger hit radius"],
	"maluses": []
})

# Connect to selection signal
card.card_selected.connect(_on_card_selected)
```

### 2. Store Overlay (`Scenes/StoreOverlay.tscn` and `Scenes/StoreOverlay.gd`)

A full-screen overlay that displays 3 random cards for selection.

#### Features:
- **Semi-transparent dimmer**: Darkens the background (75% opacity)
- **Random card selection**: Picks 3 cards from the available pool
- **Entrance/exit animations**: Smooth fade-in and scale animations
- **Staggered card appearance**: Cards appear one after another for visual appeal

#### Signals:
- `card_selected(card_data: Dictionary)` - Emitted when a card is selected
- `store_closed()` - Emitted when the store overlay closes

#### Public Methods:
- `show_store()` - Display the store with 3 random cards
- `hide_store()` - Hide the store with exit animation

#### Usage Example:
```gdscript
# In your game scene
@onready var store_overlay = $StoreOverlay

func _ready():
	# Connect signals
	store_overlay.card_selected.connect(_on_card_selected)
	store_overlay.store_closed.connect(_on_store_closed)

func open_store():
	store_overlay.show_store()

func _on_card_selected(card_data: Dictionary):
	print("Player selected: ", card_data.name)
	# Apply card effects here
	GameState.acquire_card(card_data)
```

### 3. GameState Integration

The GameState singleton has been extended with card management functionality.

#### New Signals:
- `store_opened()` - Emitted when the store should be opened
- `card_acquired(card_data: Dictionary)` - Emitted when a card is acquired

#### New Variables:
- `acquired_cards: Array[Dictionary]` - List of all acquired cards

#### New Methods:
- `open_store()` - Emit signal to open the store
- `acquire_card(card_data: Dictionary)` - Add a card to acquired cards
- `has_card(card_name: String) -> bool` - Check if a specific card is acquired
- `get_acquired_cards() -> Array[Dictionary]` - Get all acquired cards

## Integration Guide

### Adding Store to Your Game Scene

1. **Add StoreOverlay to your scene**:
   - Open your main game scene (e.g., `Game.tscn`)
   - Instance `StoreOverlay.tscn` as a child node
   - The overlay will be hidden by default

2. **Connect to signals**:
```gdscript
extends Node2D

@onready var store_overlay = $StoreOverlay

func _ready():
	# Connect store signals
	store_overlay.card_selected.connect(_on_card_selected)
	
	# Connect GameState signals
	GameState.card_acquired.connect(_on_card_acquired)

func _on_card_selected(card_data: Dictionary):
	# Acquire the card through GameState
	GameState.acquire_card(card_data)

func _on_card_acquired(card_data: Dictionary):
	# Apply card effects
	_apply_card_effects(card_data)

func _apply_card_effects(card_data: Dictionary):
	# Implement your card effect logic here
	match card_data.name:
		"Extra Darts":
			GameState.remaining_darts += 3
		"Eagle Eye":
			# Increase accuracy logic
			pass
		# Add more card effects...
```

3. **Trigger the store**:
```gdscript
# Option 1: Direct call
store_overlay.show_store()

# Option 2: Via GameState signal
GameState.open_store()
# Then connect to GameState.store_opened signal to show the overlay
```

## Available Cards

The store comes with 10 pre-defined cards:

1. **Eagle Eye** - Increased accuracy, larger hit radius
2. **Extra Darts** - +3 darts, reduced accuracy
3. **Country Hint** - Reveals 3 random countries
4. **Time Freeze** - +30 seconds, -2 darts
5. **Lucky Shot** - Next dart always hits (one-time use)
6. **Dart Shower** - +5 darts, 50% accuracy penalty, -15 seconds
7. **Continental Bonus** - Collect entire continent, -5 darts
8. **Precision Master** - Perfect accuracy, -3 darts, slower throw
9. **Time Warp** - +60 seconds, -4 darts
10. **Dart Magnet** - Auto-aim, cannot choose target

### Adding Custom Cards

Edit `StoreOverlay.gd` and add to the `available_cards` array:

```gdscript
var available_cards: Array[Dictionary] = [
	{
		"name": "Your Card Name",
		"bonuses": ["Bonus 1", "Bonus 2"],
		"maluses": ["Penalty 1"]
	},
	# ... existing cards
]
```

## Example Scene

A complete example is provided in `Scenes/StoreOverlayExample.tscn`:
- Demonstrates how to integrate the store
- Shows signal connections
- Includes a button to open the store
- Displays acquired card count

To test:
1. Open `StoreOverlayExample.tscn` in Godot
2. Run the scene (F6)
3. Click "Open Store" button
4. Select a card
5. Observe the card count update

## Visual Customization

### Card Appearance

Edit `Scenes/Card.tscn` to customize:
- Card size: Modify `custom_minimum_size` on the root PanelContainer
- Colors: Edit the StyleBoxFlat resources
- Fonts: Override theme font sizes
- Border/shadow: Adjust StyleBoxFlat properties

### Store Background

Edit `Scenes/StoreOverlay.tscn`:
- Dimmer opacity: Change the `color` alpha value on the Dimmer ColorRect
- Card spacing: Modify `theme_override_constants/separation` on CardsContainer

### Hover Effect

Edit `Scenes/Card.gd` variables:
- `hover_tilt_strength`: Maximum tilt angle (default: 15 degrees)
- `hover_scale`: Scale multiplier when hovered (default: 1.05)
- `hover_damping`: Smoothing factor (default: 0.15)

## Animation Timing

### Store Entrance
- Dimmer fade: 0.3 seconds
- Cards appear: 0.4 seconds each
- Stagger delay: 0.1 seconds between cards

### Store Exit
- All elements fade: 0.2 seconds
- Cards scale down to 0.8

Edit `_animate_entrance()` and `_animate_exit()` in `StoreOverlay.gd` to customize.

## Best Practices

1. **Apply card effects immediately**: When a card is selected, apply its effects right away
2. **Store card data**: Keep acquired cards in GameState for persistence
3. **Validate effects**: Check if effects are still valid (e.g., can't add darts if at max)
4. **Visual feedback**: Show the player what changed after acquiring a card
5. **Balance**: Ensure cards have meaningful trade-offs (bonuses vs penalties)

## Troubleshooting

### Cards not appearing
- Check that `StoreOverlay.tscn` is properly instanced in your scene
- Verify `Card.tscn` path in `StoreOverlay.gd` CARD_SCENE constant

### Hover effect not working
- Ensure the Card's `mouse_filter` is set to "Stop" (not "Ignore")
- Check that the card is receiving mouse events

### Signals not firing
- Verify signal connections in `_ready()`
- Check that nodes are properly referenced with `@onready`

## Future Enhancements

Potential improvements:
- Card rarity system (common, rare, legendary)
- Card unlock progression
- Card preview before selection
- Sound effects for card selection
- Particle effects on card hover
- Card history/collection view
- Save/load acquired cards
- Card synergies (combos between cards)

