package net.mcreator.thebackwoods.procedures;

import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.Level;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.Block;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.block.state.properties.Property;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.sounds.SoundSource;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;

import net.mcreator.thebackwoods.init.TheBackwoodsModBlocks;

import java.util.List;

public class LignumCaroSpreadOnTickUpdateProcedure {
	// ---------- CONFIGURABLE SPREAD & DEFENSE SETTINGS ----------
	// Spread/infection speed chance (0.0 to 1.0) on random ticks. Lower = slower spread.
	private static final double SPREAD_CHANCE = 0.35;

	// Spread delay in ticks for scheduled chain-reaction ticks. Lower = faster propagation.
	private static final int SPREAD_DELAY_TICKS = 7;

	// Minimum world age/time in game ticks (1200 ticks = 60 seconds = 1 minute) before infection begins.
	private static final long INFECTION_START_DELAY_TICKS = 1200L;

	// Sneeze range (radius in blocks) to detect Spore entities
	private static final double SNEEZE_RANGE = 4.0;

	// Sneeze activation chance per random tick (0.0 to 1.0)
	private static final double SNEEZE_CHANCE = 0.40;

	// Sneeze damage configuration
	private static final float SNEEZE_MIN_DAMAGE = 1.0F;
	private static final float SNEEZE_MAX_DAMAGE = 2.0F;

	// Cleansing chance: when uninfected block is next to an infected one, chance to cleanse it per tick
	private static final double CLEANSING_CHANCE = 0.25;
	// -------------------------------------------------------------

	public static void execute(LevelAccessor world, double x, double y, double z) {
		if (!(world instanceof Level level)) {
			return;
		}

		if (level.getGameTime() < INFECTION_START_DELAY_TICKS) {
			return;
		}

		BlockPos sourcePos = BlockPos.containing(x, y, z);
		BlockState sourceState = world.getBlockState(sourcePos);
		if (sourceState.isAir()) {
			return;
		}

		RandomSource random = world.getRandom();
		int sx = sourcePos.getX();
		int sy = sourcePos.getY();
		int sz = sourcePos.getZ();

		Block customBlock = TheBackwoodsModBlocks.LIGNUM_CARO.get();
		BlockState defaultSpreadState = customBlock.defaultBlockState();

		// Safely try to find and apply the "infected" state property if it's set up in MCreator
		Property<?> infectedProp = sourceState.getBlock().getStateDefinition().getProperty("infected");
		boolean isInfected = false;
		BooleanProperty boolProp = null;

		if (infectedProp instanceof BooleanProperty bProp) {
			boolProp = bProp;
			isInfected = sourceState.getValue(bProp);
		}

		if (isInfected) {
			// ==========================================
			// COMPROMISED / INFECTED SPREADING LOGIC
			// ==========================================
			BlockState infectedSpreadState = defaultSpreadState;
			if (boolProp != null) {
				infectedSpreadState = defaultSpreadState.setValue(boolProp, true);
			}

			// Scan adjacent blocks to spread the spore corruption
			for (int dx = -1; dx <= 1; dx++) {
				for (int dy = -1; dy <= 1; dy++) {
					for (int dz = -1; dz <= 1; dz++) {
						if (dx == 0 && dy == 0 && dz == 0) {
							continue;
						}

						BlockPos targetPos = new BlockPos(sx + dx, sy + dy, sz + dz);
						if (world.isOutsideBuildHeight(targetPos)) {
							continue;
						}

						BlockState targetState = world.getBlockState(targetPos);
						if (targetState.isAir()) {
							continue;
						}

						ResourceLocation reg = BuiltInRegistries.BLOCK.getKey(targetState.getBlock());
						if (reg != null && reg.getNamespace().equals("spore")) {
							// Apply configurable spread probability per neighbor block
							if (random.nextDouble() <= SPREAD_CHANCE) {
								world.setBlock(targetPos, infectedSpreadState, 3);
								world.scheduleTick(targetPos, customBlock, SPREAD_DELAY_TICKS);
							}
						}
					}
				}
			}
		} else {
			// ==========================================
			// PRISTINE WOOD / ACTIVE IMMUNE DEFENDER
			// ==========================================

			// 1. ENTITY DEFENSE: SNEEZE BURST against nearby Spore Entities
			if (random.nextDouble() <= SNEEZE_CHANCE) {
				double range = SNEEZE_RANGE;
				AABB scanArea = new AABB(
					x - range, y - range, z - range,
					x + range, y + range, z + range
				);
				List<LivingEntity> nearbySporeEntities = level.getEntitiesOfClass(LivingEntity.class, scanArea, entity -> {
					ResourceLocation rl = BuiltInRegistries.ENTITY_TYPE.getKey(entity.getType());
					return rl != null && rl.getNamespace().equals("spore");
				});

				if (!nearbySporeEntities.isEmpty()) {
					boolean sneezed = false;
					for (LivingEntity target : nearbySporeEntities) {
						if (target.isAlive()) {
							sneezed = true;
							// Apply rejection damage (random configurable range of magic damage)
							float damage = SNEEZE_MIN_DAMAGE + random.nextFloat() * (SNEEZE_MAX_DAMAGE - SNEEZE_MIN_DAMAGE);
							target.hurt(level.damageSources().magic(), damage);

							// Apply knockback (pushing away from the block center)
							Vec3 blockCenter = new Vec3(x + 0.5, y + 0.5, z + 0.5);
							Vec3 pushVec = target.position().subtract(blockCenter).normalize();
							target.setDeltaMovement(target.getDeltaMovement().add(pushVec.x * 0.4, 0.25, pushVec.z * 0.4));
							target.hurtMarked = true;

							// Inflict Poison status effect to the spore entities (6 seconds of Poison I)
							target.addEffect(new MobEffectInstance(MobEffects.POISON, 120, 0, false, false));

							// Spawn defensive sneeze particles blowing towards target
							if (level instanceof ServerLevel serverLevel) {
								serverLevel.sendParticles(ParticleTypes.SNEEZE, target.getX(), target.getY() + 1.0, target.getZ(), 8, 0.2, 0.2, 0.2, 0.05);
							}
						}
					}

					if (sneezed) {
						// Play an organic, wooden "sneeze" sound
						level.playSound(null, sourcePos, SoundEvents.LLAMA_SPIT, SoundSource.BLOCKS, 1.0F, 0.8F + random.nextFloat() * 0.4F);
						level.playSound(null, sourcePos, SoundEvents.BAMBOO_WOOD_BREAK, SoundSource.BLOCKS, 0.6F, 1.2F + random.nextFloat() * 0.4F);
						
						if (level instanceof ServerLevel serverLevel) {
							serverLevel.sendParticles(ParticleTypes.HAPPY_VILLAGER, x + 0.5, y + 1.0, z + 0.5, 12, 0.5, 0.5, 0.5, 0.1);
						}
					}
				}
			}

			// 2. BLOCK DEFENSE: STRUCTURAL RUPTURES & CLEANSING TUG-OF-WAR
			for (int dx = -1; dx <= 1; dx++) {
				for (int dy = -1; dy <= 1; dy++) {
					for (int dz = -1; dz <= 1; dz++) {
						if (dx == 0 && dy == 0 && dz == 0) {
							continue;
						}

						BlockPos targetPos = new BlockPos(sx + dx, sy + dy, sz + dz);
						if (world.isOutsideBuildHeight(targetPos)) {
							continue;
						}

						BlockState targetState = world.getBlockState(targetPos);
						if (targetState.isAir()) {
							continue;
						}

						// A: Convert adjacent Spore blocks into pristine Lignum Caro!
						ResourceLocation reg = BuiltInRegistries.BLOCK.getKey(targetState.getBlock());
						if (reg != null && reg.getNamespace().equals("spore")) {
							if (random.nextDouble() <= SPREAD_CHANCE) {
								BlockState pristineSpreadState = defaultSpreadState;
								if (boolProp != null) {
									pristineSpreadState = defaultSpreadState.setValue(boolProp, false);
								}
								world.setBlock(targetPos, pristineSpreadState, 3);
								world.scheduleTick(targetPos, customBlock, SPREAD_DELAY_TICKS);
								level.playSound(null, targetPos, SoundEvents.BAMBOO_WOOD_PLACE, SoundSource.BLOCKS, 0.8F, 1.0F + random.nextFloat() * 0.2F);
								
								if (level instanceof ServerLevel serverLevel) {
									serverLevel.sendParticles(ParticleTypes.HAPPY_VILLAGER, targetPos.getX() + 0.5, targetPos.getY() + 0.5, targetPos.getZ() + 0.5, 6, 0.2, 0.2, 0.2, 0.05);
								}
							}
						}
						// B: Reclaim / cleanse compromised Lignum Caro blocks
						else if (targetState.is(customBlock) && boolProp != null) {
							boolean targetInfected = targetState.getValue(boolProp);
							if (targetInfected && random.nextDouble() <= CLEANSING_CHANCE) {
								// Cleanse it back to pure wood
								BlockState cleansedState = defaultSpreadState.setValue(boolProp, false);
								world.setBlock(targetPos, cleansedState, 3);
								level.playSound(null, targetPos, SoundEvents.CHERRY_WOOD_BREAK, SoundSource.BLOCKS, 0.8F, 1.1F + random.nextFloat() * 0.2F);
								
								if (level instanceof ServerLevel serverLevel) {
									serverLevel.sendParticles(ParticleTypes.HAPPY_VILLAGER, targetPos.getX() + 0.5, targetPos.getY() + 0.5, targetPos.getZ() + 0.5, 5, 0.3, 0.3, 0.3, 0.02);
								}
							}
						}
					}
				}
			}
		}
	}
}