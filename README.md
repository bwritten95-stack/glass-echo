# Glass Echo

**Dash through a mirrored arena, leave fragile glass clones, and shatter them into shard storms — defeat the Mirror Warden before you break.**

Godot **4.7.2** · typed GDScript · procedural art/audio

## Play

Open the project in Godot 4.7+, or from a terminal:

```bash
godot --path .
```

### Controls
| Action | Input |
|--------|--------|
| Move | WASD / Arrows |
| Dash (leave echo) | Shift or Space |
| Shatter nearest echo | F or Left Click |
| Pause | Esc |

## Loop
**Menu → Arena waves (1–4) → Mirror Warden (wave 5) → Win/Lose → Menu**

Pause includes Master/SFX volume and fullscreen. Settings persist to `user://settings.cfg`.

## Export
Presets in `export_presets.cfg` (Linux, Windows, Web):

1. In Godot: **Editor → Manage Export Templates** → install **4.7.2** templates  
2. **Project → Export** → pick a preset → export into `export/`

## Project layout
```
autoload/     EventBus, SettingsStore, AudioService, RunState
scenes/       UI, arena, entities
scripts/      Typed GDScript mirrors of scenes
resources/    Shared resources (optional)
export/       Build output (gitignored binaries)
```

## Dev / CI helpers
```bash
godot --path . -- --autoplay
godot --path . -- --autoplay --boss-test --force-win
godot --path . -- --autoplay --force-lose
```

## License
Original game for Project Ambition. All rights reserved unless otherwise noted.
