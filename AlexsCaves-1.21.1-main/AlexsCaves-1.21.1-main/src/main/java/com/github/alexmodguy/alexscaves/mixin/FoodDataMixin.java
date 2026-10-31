package com.github.alexmodguy.alexscaves.mixin;

import net.minecraft.world.food.FoodData;
import org.spongepowered.asm.mixin.Mixin;

// Primordial Armor raw meat bonus is now handled in PlayerMixin via Player.eat() inject
@Mixin(FoodData.class)
public abstract class FoodDataMixin {
}
