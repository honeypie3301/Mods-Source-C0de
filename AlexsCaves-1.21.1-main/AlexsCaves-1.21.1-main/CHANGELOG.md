# Changelog

## 2.0.10

### Fixes

- Restore Pewen and Thornwood sign/hanging sign support by implementing expandVanillaDefinitions for block entity types.
- Fix Primordial Armor raw meat nutrition bonus (ported from FoodDataMixin to PlayerMixin for 1.21 compatibility).
- Register underground cabin map decoration type via data registry for 1.21's registry-based MapDecorationType system.
- Implement enchanted book creative tab population for all weapon enchantments.
- Fix submarine jittering by restoring original 1.20.1 lSteps interpolation.
- Fix submarine console Z-fighting with POLYGON_OFFSET_LAYERING render type.
- Remove submarine floodlight block placement system that was breaking controls.
- Reduce cave biome generation frequency for better world balance.
- Prevent cave blocks/features from spawning on the surface.
- Fix access transformer to use mapped field name for BlockEntityType.validBlocks.

## 2.0.9

### Fixes

- Prevent Alex's Caves surface rules from leaking into non-Overworld dimensions.
- Guard biome decoration to avoid C2ME chunk feature index crashes.
- Ensure neodymium nodes drop raw neodymium without Silk Touch (with Fortune scaling).
- Ensure sulfur blocks/buds/clusters drop sulfur dust without Silk Touch (with Fortune scaling).
- Sync mod metadata version to 2.0.9.
- Various other fixes.
