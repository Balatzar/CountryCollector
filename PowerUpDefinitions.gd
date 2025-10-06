extends Node

## PowerUpDefinitions
## Centralized definitions for all power-up bonuses and maluses
## Each power-up has a unique ID, display name, description, and tier (if applicable)

enum PowerUpType {
	BONUS,
	MALUS
}

# ===== BONUSES =====

const BONUS_SLOWER_MAP_T1 = {
	"id": "slower_map_t1",
	"type": PowerUpType.BONUS,
	"name": "Slower Map I",
	"description": "Map rotation speed reduced by 15%",
	"family": "slower_map",
	"tier": 1,
	"repeatable": false
}

const BONUS_SLOWER_MAP_T2 = {
	"id": "slower_map_t2",
	"type": PowerUpType.BONUS,
	"name": "Slower Map II",
	"description": "Map rotation speed reduced by 30%",
	"family": "slower_map",
	"tier": 2,
	"repeatable": false
}

const BONUS_SLOWER_MAP_T3 = {
	"id": "slower_map_t3",
	"type": PowerUpType.BONUS,
	"name": "Slower Map III",
	"description": "Map rotation speed reduced by 50%",
	"family": "slower_map",
	"tier": 3,
	"repeatable": false
}

const BONUS_SLOWER_MAP_T4 = {
	"id": "slower_map_t4",
	"type": PowerUpType.BONUS,
	"name": "Slower Map IV",
	"description": "Map rotation speed reduced by 65%",
	"family": "slower_map",
	"tier": 4,
	"repeatable": false
}

const BONUS_SLOWER_MAP_T5 = {
	"id": "slower_map_t5",
	"type": PowerUpType.BONUS,
	"name": "Slower Map V",
	"description": "Map rotation speed reduced by 80%",
	"family": "slower_map",
	"tier": 5,
	"repeatable": false
}

const BONUS_ZOOM_T1 = {
	"id": "zoom_t1",
	"type": PowerUpType.BONUS,
	"name": "Zoom I",
	"description": "Unlock map zoom capability (1.5x)",
	"family": "zoom",
	"tier": 1,
	"repeatable": false
}

const BONUS_ZOOM_T2 = {
	"id": "zoom_t2",
	"type": PowerUpType.BONUS,
	"name": "Zoom II",
	"description": "Improved map zoom (2.0x)",
	"family": "zoom",
	"tier": 2,
	"repeatable": false
}

const BONUS_ZOOM_T3 = {
	"id": "zoom_t3",
	"type": PowerUpType.BONUS,
	"name": "Zoom III",
	"description": "Map zoom (3.0x)",
	"family": "zoom",
	"tier": 3,
	"repeatable": false
}

const BONUS_ZOOM_T4 = {
	"id": "zoom_t4",
	"type": PowerUpType.BONUS,
	"name": "Zoom IV",
	"description": "Enhanced map zoom (4.0x)",
	"family": "zoom",
	"tier": 4,
	"repeatable": false
}

const BONUS_ZOOM_T5 = {
	"id": "zoom_t5",
	"type": PowerUpType.BONUS,
	"name": "Zoom V",
	"description": "Maximum map zoom (5.0x)",
	"family": "zoom",
	"tier": 5,
	"repeatable": false
}

const BONUS_EXTRA_XP_T1 = {
	"id": "extra_xp_t1",
	"type": PowerUpType.BONUS,
	"name": "Extra XP I",
	"description": "+5 XP per successful hit",
	"family": "extra_xp",
	"tier": 1,
	"repeatable": false
}

const BONUS_EXTRA_XP_T2 = {
	"id": "extra_xp_t2",
	"type": PowerUpType.BONUS,
	"name": "Extra XP II",
	"description": "+10 XP per successful hit",
	"family": "extra_xp",
	"tier": 2,
	"repeatable": false
}

const BONUS_EXTRA_XP_T3 = {
	"id": "extra_xp_t3",
	"type": PowerUpType.BONUS,
	"name": "Extra XP III",
	"description": "+15 XP per successful hit",
	"family": "extra_xp",
	"tier": 3,
	"repeatable": false
}

const BONUS_EXTRA_XP_T4 = {
	"id": "extra_xp_t4",
	"type": PowerUpType.BONUS,
	"name": "Extra XP IV",
	"description": "+20 XP per successful hit",
	"family": "extra_xp",
	"tier": 4,
	"repeatable": false
}

const BONUS_EXTRA_XP_T5 = {
	"id": "extra_xp_t5",
	"type": PowerUpType.BONUS,
	"name": "Extra XP V",
	"description": "+25 XP per successful hit",
	"family": "extra_xp",
	"tier": 5,
	"repeatable": false
}

# ===== MALUSES =====

const MALUS_FASTER_MAP_T1 = {
	"id": "faster_map_t1",
	"type": PowerUpType.MALUS,
	"name": "Faster Map I",
	"description": "Map rotation speed increased by 20%",
	"family": "faster_map",
	"tier": 1,
	"repeatable": false
}

const MALUS_FASTER_MAP_T2 = {
	"id": "faster_map_t2",
	"type": PowerUpType.MALUS,
	"name": "Faster Map II",
	"description": "Map rotation speed increased by 40%",
	"family": "faster_map",
	"tier": 2,
	"repeatable": false
}

const MALUS_FASTER_MAP_T3 = {
	"id": "faster_map_t3",
	"type": PowerUpType.MALUS,
	"name": "Faster Map III",
	"description": "Map rotation speed increased by 60%",
	"family": "faster_map",
	"tier": 3,
	"repeatable": false
}

const MALUS_FASTER_MAP_T4 = {
	"id": "faster_map_t4",
	"type": PowerUpType.MALUS,
	"name": "Faster Map IV",
	"description": "Map rotation speed increased by 80%",
	"family": "faster_map",
	"tier": 4,
	"repeatable": false
}

const MALUS_FASTER_MAP_T5 = {
	"id": "faster_map_t5",
	"type": PowerUpType.MALUS,
	"name": "Faster Map V",
	"description": "Map rotation speed increased by 100%",
	"family": "faster_map",
	"tier": 5,
	"repeatable": false
}

const MALUS_UNZOOM_T1 = {
	"id": "unzoom_t1",
	"type": PowerUpType.MALUS,
	"name": "Unzoom I",
	"description": "Map zoom reduced by 15%",
	"family": "zoom",
	"tier": 1,
	"repeatable": false
}

const MALUS_UNZOOM_T2 = {
	"id": "unzoom_t2",
	"type": PowerUpType.MALUS,
	"name": "Unzoom II",
	"description": "Map zoom reduced by 30%",
	"family": "zoom",
	"tier": 2,
	"repeatable": false
}

const MALUS_UNZOOM_T3 = {
	"id": "unzoom_t3",
	"type": PowerUpType.MALUS,
	"name": "Unzoom III",
	"description": "Map zoom reduced by 50%",
	"family": "zoom",
	"tier": 3,
	"repeatable": false
}

const MALUS_UNZOOM_T4 = {
	"id": "unzoom_t4",
	"type": PowerUpType.MALUS,
	"name": "Unzoom IV",
	"description": "Map zoom reduced by 65%",
	"family": "zoom",
	"tier": 4,
	"repeatable": false
}

const MALUS_UNZOOM_T5 = {
	"id": "unzoom_t5",
	"type": PowerUpType.MALUS,
	"name": "Unzoom V",
	"description": "Map zoom reduced by 80%",
	"family": "zoom",
	"tier": 5,
	"repeatable": false
}

const MALUS_VERTICAL_MOVEMENT_T1 = {
	"id": "vertical_movement_t1",
	"type": PowerUpType.MALUS,
	"name": "Vertical Drift I",
	"description": "Map slowly drifts up and down",
	"family": "vertical_movement",
	"tier": 1,
	"repeatable": false
}

const MALUS_VERTICAL_MOVEMENT_T2 = {
	"id": "vertical_movement_t2",
	"type": PowerUpType.MALUS,
	"name": "Vertical Drift II",
	"description": "Map drifts up and down",
	"family": "vertical_movement",
	"tier": 2,
	"repeatable": false
}

const MALUS_VERTICAL_MOVEMENT_T3 = {
	"id": "vertical_movement_t3",
	"type": PowerUpType.MALUS,
	"name": "Vertical Drift III",
	"description": "Map heavily drifts up and down",
	"family": "vertical_movement",
	"tier": 3,
	"repeatable": false
}

const MALUS_VERTICAL_MOVEMENT_T4 = {
	"id": "vertical_movement_t4",
	"type": PowerUpType.MALUS,
	"name": "Vertical Drift IV",
	"description": "Map drifts erratically up and down",
	"family": "vertical_movement",
	"tier": 4,
	"repeatable": false
}

const MALUS_VERTICAL_MOVEMENT_T5 = {
	"id": "vertical_movement_t5",
	"type": PowerUpType.MALUS,
	"name": "Vertical Drift V",
	"description": "Map drifts wildly up and down",
	"family": "vertical_movement",
	"tier": 5,
	"repeatable": false
}

# ===== POWER-UP POOLS =====

# All bonuses available for selection
const ALL_BONUSES = [
	BONUS_SLOWER_MAP_T1,
	BONUS_SLOWER_MAP_T2,
	BONUS_SLOWER_MAP_T3,
	BONUS_SLOWER_MAP_T4,
	BONUS_SLOWER_MAP_T5,
	BONUS_ZOOM_T1,
	BONUS_ZOOM_T2,
	BONUS_ZOOM_T3,
	BONUS_ZOOM_T4,
	BONUS_ZOOM_T5,
	BONUS_EXTRA_XP_T1,
	BONUS_EXTRA_XP_T2,
	BONUS_EXTRA_XP_T3,
	BONUS_EXTRA_XP_T4,
	BONUS_EXTRA_XP_T5
]

# All maluses available for selection
const ALL_MALUSES = [
	MALUS_FASTER_MAP_T1,
	MALUS_FASTER_MAP_T2,
	MALUS_FASTER_MAP_T3,
	MALUS_FASTER_MAP_T4,
	MALUS_FASTER_MAP_T5,
	MALUS_UNZOOM_T1,
	MALUS_UNZOOM_T2,
	MALUS_UNZOOM_T3,
	MALUS_UNZOOM_T4,
	MALUS_UNZOOM_T5,
	MALUS_VERTICAL_MOVEMENT_T1,
	MALUS_VERTICAL_MOVEMENT_T2,
	MALUS_VERTICAL_MOVEMENT_T3,
	MALUS_VERTICAL_MOVEMENT_T4,
	MALUS_VERTICAL_MOVEMENT_T5
]

# ===== HELPER FUNCTIONS =====

## Get a random bonus from the available pool
## Filters out power-ups already acquired (unless repeatable)
static func get_random_bonus(acquired_power_ups: Array[Dictionary] = []) -> Dictionary:
	var available_bonuses = _filter_available(ALL_BONUSES, acquired_power_ups)
	if available_bonuses.is_empty():
		return {}
	return available_bonuses[randi() % available_bonuses.size()]


## Get a random malus from the available pool
## Filters out power-ups already acquired (unless repeatable)
static func get_random_malus(acquired_power_ups: Array[Dictionary] = []) -> Dictionary:
	var available_maluses = _filter_available(ALL_MALUSES, acquired_power_ups)
	if available_maluses.is_empty():
		return {}
	return available_maluses[randi() % available_maluses.size()]


## Filter out power-ups that have already been acquired (unless repeatable)
## Also filters out tiered power-ups if the previous tier hasn't been acquired
static func _filter_available(pool: Array, acquired: Array[Dictionary]) -> Array:
	var available = []
	var acquired_ids = []

	# Build list of acquired IDs
	for power_up in acquired:
		if power_up.has("id"):
			acquired_ids.append(power_up["id"])

	# Filter pool
	for power_up in pool:
		var is_repeatable = power_up.get("repeatable", false)
		var is_acquired = power_up["id"] in acquired_ids

		# Skip if already acquired (unless repeatable)
		if is_acquired and not is_repeatable:
			continue

		# Check tier prerequisites
		var tier = power_up.get("tier", 0)
		if tier > 1:
			# Extract the base power-up ID (without tier suffix)
			var power_up_id: String = power_up["id"]
			var base_id = power_up_id.rsplit("_t", true, 1)[0]  # e.g., "slower_map_t2" -> "slower_map"
			var previous_tier_id = base_id + "_t" + str(tier - 1)  # e.g., "slower_map_t1"

			# Only include if previous tier is acquired
			if previous_tier_id not in acquired_ids:
				continue

		# Include this power-up
		available.append(power_up)

	return available


## Generate a card with one random bonus and one random malus
static func generate_card(acquired_power_ups: Array[Dictionary] = []) -> Dictionary:
	var bonus = get_random_bonus(acquired_power_ups)
	var malus = get_random_malus(acquired_power_ups)

	return {
		"bonus": bonus,
		"malus": malus
	}
