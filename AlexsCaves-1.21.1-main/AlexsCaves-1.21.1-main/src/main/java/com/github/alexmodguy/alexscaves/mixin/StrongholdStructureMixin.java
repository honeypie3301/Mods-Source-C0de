package com.github.alexmodguy.alexscaves.mixin;

import com.github.alexmodguy.alexscaves.server.level.biome.ACBiomeRarity;
import com.github.alexmodguy.alexscaves.server.level.biome.ACWorldSeedHolder;
import net.minecraft.world.level.levelgen.structure.Structure;
import net.minecraft.world.level.levelgen.structure.structures.StrongholdStructure;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import java.util.Optional;

@Mixin(StrongholdStructure.class)
public class StrongholdStructureMixin {

    @Inject(
            method = {"Lnet/minecraft/world/level/levelgen/structure/structures/StrongholdStructure;findGenerationPoint(Lnet/minecraft/world/level/levelgen/structure/Structure$GenerationContext;)Ljava/util/Optional;"},
            remap = true,
            cancellable = true,
            at = @At(value = "HEAD")
    )
    private void ac_findGenerationPoint(Structure.GenerationContext context, CallbackInfoReturnable<Optional<Structure.GenerationStub>> cir) {
        int i = context.chunkPos().getBlockX(9);
        int j = context.chunkPos().getBlockZ(9);

        // Use the voronoi system directly instead of the expensive getBiomesWithin() call.
        // getBiomesWithin(radius=80) queries ~1600 biome positions through the mixin pipeline,
        // causing watchdog timeouts when mods trigger bulk stronghold lookups (e.g. EndRemastered).
        long seed = context.seed();
        if (seed == 0 && ACWorldSeedHolder.isInitialized()) {
            seed = ACWorldSeedHolder.getSeed();
        }
        if (seed != 0) {
            int checkRadius = 80;
            int step = 32;
            for (int dx = -checkRadius; dx <= checkRadius; dx += step) {
                for (int dz = -checkRadius; dz <= checkRadius; dz += step) {
                    if (ACBiomeRarity.getACBiomeForPosition(seed, i + dx, j + dz) != null) {
                        cir.setReturnValue(Optional.empty());
                        return;
                    }
                }
            }
        }
    }
}
