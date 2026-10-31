package com.github.alexmodguy.alexscaves.mixin;

import net.minecraft.world.level.saveddata.maps.MapDecoration;
import org.spongepowered.asm.mixin.Mixin;

// Custom map decoration type is now registered via data registry (map_decoration_type/underground_cabin.json)
// Custom rendering is handled via ClientEvents.renderMapDecorations
@Mixin(MapDecoration.class)
public abstract class MapDecorationMixin {
}
