# Lucky Jump: Crash Run

Portrait arcade game for iOS 16 and later. The gameplay is implemented with SpriteKit; application screens use SwiftUI. All current art is generated from shapes and SF Symbols so final textures can be introduced without changing gameplay code.

## Run

1. Open `JumpCollectExplorer.xcodeproj` in Xcode.
2. Select the `JumpCollectExplorer` scheme.
3. Choose an iPhone simulator and run.

The generated project can be refreshed after changes to `project.yml` with:

```sh
xcodegen generate
```

## Implemented product flow

- animated loading screen and first-launch onboarding;
- home screen, world/level selection, missions, collection, shop, settings and statistics;
- 4 worlds with 20 sequentially unlocked levels each;
- 80 level definitions with individual targets, objective thresholds, jump spacing, hazard pacing and checkpoints;
- endless mode and daily reward;
- reproducible seeded daily challenge;
- automatic jumping with hold-left/hold-right steering;
- Doodle Jump-style horizontal wrap: leaving either side of the screen continues the same jump from the opposite side;
- normal, small, moving, rotten, fragile, spring, ice, sticky and vanishing islands;
- flying hazards with advance warnings and shield interactions;
- world-specific wind gusts and telegraphed lightning strikes;
- falling rocks, falling icicles, treasure chests, checkpoints and a dedicated finish island;
- Shield, Coin Magnet, Wings and Double Coins pickups with timed HUD indicators;
- Rocket and collectible Rescue Feather pickups;
- Perfect landings, combo multiplier, score, coins and edge saves;
- pause, restart, one-use rescue flow, game-over, completion and next-level flow;
- daily missions with persisted claim protection and a seven-day reward screen;
- pre-run objective and boost selection, persistent achievement rewards, and feather results;
- procedural world-specific background music and built-in sound feedback with working settings;
- premium dark glass UI system with layered gradients, material panels, accent lighting, metric chips and a native SwiftUI in-game HUD;
- unit tests for the level catalog, progression, feather rules and deterministic generation;
- local versioned player progress using Codable JSON;
- programmatic placeholder visuals prepared for later texture replacement.

## Texture replacement points

The SpriteKit nodes are currently created in `Game/GameScene.swift`. Final assets should use stable semantic names such as `character_turkey_default`, `platform_normal`, `platform_rotten`, `coin`, and `powerup_shield`. The screen layer does not depend on those textures.

## Production art prompts

`Assets/ASSET_PROMPTS.md` contains 64 self-contained generation prompts for the complete production art set. Every prompt follows the same premium 2.5D casual-game direction and specifies the target filename, canvas size, transparency/background requirements, composition, lighting and exclusions. The set covers branding, onboarding, world backgrounds, every platform type, the main character and skins, currency, pickups, hazards, navigation controls, world badges and VFX sheets.
