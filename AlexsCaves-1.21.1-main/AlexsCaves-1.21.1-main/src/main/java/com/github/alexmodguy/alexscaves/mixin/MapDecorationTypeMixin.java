package com.github.alexmodguy.alexscaves.mixin;

import org.spongepowered.asm.mixin.Mixin;

// MapDecorationType is now registry-based in 1.21
// Custom type registered via data/alexscaves/map_decoration_type/underground_cabin.json
@Mixin(targets = "net.minecraft.world.level.saveddata.maps.MapDecorationType")
public class MapDecorationTypeMixin {
}
