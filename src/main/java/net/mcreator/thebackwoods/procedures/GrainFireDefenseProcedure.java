package net.mcreator.thebackwoods.procedures;
// 1.21.1 neoforge
import net.neoforged.neoforge.event.tick.PlayerTickEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.bus.api.SubscribeEvent;

import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.BaseFireBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.sounds.SoundSource;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.core.registries.Registries;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.StringTag;
import net.minecraft.nbt.Tag;

import java.util.Set;
import java.util.ArrayList;
import java.util.List;

@EventBusSubscriber
public class GrainFireDefenseProcedure {

    private static final int CHECK_INTERVAL_TICKS = 8;
    private static final int FIRE_SCAN_RADIUS_XZ = 128;
    private static final int FIRE_SCAN_RADIUS_Y = 48;
    private static final int BIG_FIRE_THRESHOLD = 40; 
    private static final int PURGE_COOLDOWN_TICKS = 20 * 6; // 6 sec

    private static final int THREAT_RADIUS_XZ = 48;
    private static final int THREAT_RADIUS_Y = 24;

    private static final String NBT_COOLDOWN_KEY = "grain_fire_purge_cd";

	private static final ResourceKey<Level> THE_GRAIN = ResourceKey.create(
            Registries.DIMENSION,
            ResourceLocation.parse("the_backwoods:the_grain")
    );

    private static final ResourceKey<Level> BACKWOODS = ResourceKey.create(
            Registries.DIMENSION,
            ResourceLocation.parse("the_backwoods:backwoods")
    );

    // 1. Declare the resource key for the sub strata dimension
    private static final ResourceKey<Level> THE_SUB_STRATA = ResourceKey.create(
            Registries.DIMENSION,
            ResourceLocation.parse("the_backwoods:the_sub_strata")
    );

    private static final ResourceKey<Level> THE_PETRIFIED_WEALD = ResourceKey.create(
            Registries.DIMENSION,
            ResourceLocation.parse("the_backwoods:the_petrified_weald")
    );

    // 2. Add it to the immutable Set of allowed dimensions
    private static final Set<ResourceKey<Level>> VALID_DIMENSIONS = Set.of(THE_GRAIN, BACKWOODS, THE_SUB_STRATA, THE_PETRIFIED_WEALD);
    
    @SubscribeEvent
    public static void onPlayerTick(PlayerTickEvent.Post event) {
        Player player = event.getEntity();
        if (player == null) return;

        Level level = player.level();
        if (level.isClientSide()) return;

        // Ensure we are in one of the approved dimensions
        if (!VALID_DIMENSIONS.contains(level.dimension())) return;

        // Process active domino purge queue every tick
        processDominoPurge(level, player);
        
        if (player.tickCount % CHECK_INTERVAL_TICKS != 0) return;

        BlockPos center = player.blockPosition();

        // 1. SILENT CLEANUP (Beyond close range, up to full SCAN_RADIUS_XZ)
        // Continuously and silently sweeps coordinates on a fast background slice to delete any fire, no blindness or sounds
        silentPurgeSliced(level, center, player.tickCount);

        // 2. ACTIVE THREAT RADIUS CHECK
        int cd = player.getPersistentData().getInt(NBT_COOLDOWN_KEY);
        if (cd > 0) {
            player.getPersistentData().putInt(NBT_COOLDOWN_KEY, Math.max(0, cd - CHECK_INTERVAL_TICKS));
            return;
        }

        int fireCount = countFireInThreatRadius(level, center);
        if (fireCount < BIG_FIRE_THRESHOLD) return;

        // Perform the domino threat purge
        startDominoPurge(level, player, center);

        // Set the cooldown
        player.getPersistentData().putInt(NBT_COOLDOWN_KEY, PURGE_COOLDOWN_TICKS);
    }

    private static void silentPurgeSliced(Level level, BlockPos center, int tickCount) {
        int totalSlices = 12;
        int currentSlice = (int) ((tickCount / CHECK_INTERVAL_TICKS) % totalSlices);

        int range = FIRE_SCAN_RADIUS_XZ;
        int sliceWidth = (range * 2 + 1 + totalSlices - 1) / totalSlices;
        int startDx = -range + currentSlice * sliceWidth;
        int endDx = Math.min(range, startDx + sliceWidth - 1);

        BlockPos.MutableBlockPos p = new BlockPos.MutableBlockPos();
        BlockPos.MutableBlockPos chunkCheckPos = new BlockPos.MutableBlockPos();
        int cx = center.getX();
        int cy = center.getY();
        int cz = center.getZ();

        for (int dx = startDx; dx <= endDx; dx++) {
            int absX = cx + dx;
            for (int dz = -FIRE_SCAN_RADIUS_XZ; dz <= FIRE_SCAN_RADIUS_XZ; dz++) {
                int absZ = cz + dz;
                chunkCheckPos.set(absX, cy, absZ);
                if (!level.hasChunkAt(chunkCheckPos)) continue;

                for (int dy = -FIRE_SCAN_RADIUS_Y; dy <= FIRE_SCAN_RADIUS_Y; dy++) {
                    // Do not silently delete nearby fires; let them build up and trigger the loud threat purge
                    if (Math.abs(dx) <= THREAT_RADIUS_XZ && Math.abs(dy) <= THREAT_RADIUS_Y && Math.abs(dz) <= THREAT_RADIUS_XZ) {
                        continue;
                    }
                    p.set(absX, cy + dy, absZ);
                    if (isFire(level.getBlockState(p))) {
                        level.setBlock(p, Blocks.AIR.defaultBlockState(), 3);
                    }
                }
            }
        }
    }

    private static int countFireInThreatRadius(Level level, BlockPos center) {
        int count = 0;
        BlockPos.MutableBlockPos p = new BlockPos.MutableBlockPos();
        int cx = center.getX();
        int cy = center.getY();
        int cz = center.getZ();
        for (int dx = -THREAT_RADIUS_XZ; dx <= THREAT_RADIUS_XZ; dx += 4) {
            for (int dz = -THREAT_RADIUS_XZ; dz <= THREAT_RADIUS_XZ; dz += 4) {
                for (int dy = -THREAT_RADIUS_Y; dy <= THREAT_RADIUS_Y; dy += 4) {
                    p.set(cx + dx, cy + dy, cz + dz);
                    if (isFire(level.getBlockState(p))) count += 64;
                }
            }
        }
        return count;
    }

    private static void purgeFireInThreatRadius(Level level, BlockPos center) {
        BlockPos.MutableBlockPos p = new BlockPos.MutableBlockPos();
        int cx = center.getX();
        int cy = center.getY();
        int cz = center.getZ();
        for (int dx = -THREAT_RADIUS_XZ; dx <= THREAT_RADIUS_XZ; dx += 2) {
            for (int dz = -THREAT_RADIUS_XZ; dz <= THREAT_RADIUS_XZ; dz += 2) {
                for (int dy = -THREAT_RADIUS_Y; dy <= THREAT_RADIUS_Y; dy += 2) {
                    for (int ox = 0; ox < 2; ox++) {
                        for (int oy = 0; oy < 2; oy++) {
                            for (int oz = 0; oz < 2; oz++) {
                                p.set(cx + dx + ox, cy + dy + oy, cz + dz + oz);
                                if (isFire(level.getBlockState(p))) {
                                    level.setBlock(p, Blocks.AIR.defaultBlockState(), 3);
                                    if (level instanceof net.minecraft.server.level.ServerLevel serverLevel && serverLevel.random.nextFloat() < 0.15f) {
                                        serverLevel.sendParticles(net.minecraft.core.particles.ParticleTypes.SMOKE, p.getX() + 0.5, p.getY() + 0.5, p.getZ() + 0.5, 1, 0.1, 0.1, 0.1, 0.05);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } // 1.21.1
    }

    private static void startDominoPurge(Level level, Player player, BlockPos center) {
        List<BlockPos> firePositions = new ArrayList<>();
        BlockPos.MutableBlockPos p = new BlockPos.MutableBlockPos();
        int cx = center.getX();
        int cy = center.getY();
        int cz = center.getZ();

        for (int dx = -THREAT_RADIUS_XZ; dx <= THREAT_RADIUS_XZ; dx += 2) {
            for (int dz = -THREAT_RADIUS_XZ; dz <= THREAT_RADIUS_XZ; dz += 2) {
                for (int dy = -THREAT_RADIUS_Y; dy <= THREAT_RADIUS_Y; dy += 2) {
                    for (int ox = 0; ox < 2; ox++) {
                        for (int oy = 0; oy < 2; oy++) {
                            for (int oz = 0; oz < 2; oz++) {
                                p.set(cx + dx + ox, cy + dy + oy, cz + dz + oz);
                                if (isFire(level.getBlockState(p))) {
                                    firePositions.add(p.immutable());
                                }
                            }
                        }
                    }
                }
            }
        }

        if (firePositions.isEmpty()) return;

        // Sort by distance to player ascending (closest first)
        firePositions.sort((p1, p2) -> Double.compare(p1.distSqr(center), p2.distSqr(center)));

        if (firePositions.size() > 1000) {
            firePositions = firePositions.subList(0, 1000);
        }

        ListTag list = new ListTag();
        for (BlockPos pos : firePositions) {
            list.add(StringTag.valueOf(pos.getX() + "," + pos.getY() + "," + pos.getZ()));
        }

        player.getPersistentData().put("grain_domino_queue", list);

        // Initial alert / extinguish sound
        BuiltInRegistries.SOUND_EVENT.getOptional(ResourceLocation.parse("block.fire.extinguish")).ifPresent(extinguish -> {
            level.playSound(null, center, extinguish, SoundSource.BLOCKS, 1.3f, 0.85f);
        });
    }

    private static void processDominoPurge(Level level, Player player) {
        CompoundTag data = player.getPersistentData();
        if (!data.contains("grain_domino_queue", Tag.TAG_LIST)) return;

        ListTag list = data.getList("grain_domino_queue", Tag.TAG_STRING);
        if (list.isEmpty()) {
            data.remove("grain_domino_queue");
            return;
        }

        int extinguishCount = Math.min(list.size(), 12);
        List<BlockPos> toExtinguish = new ArrayList<>();

        for (int i = 0; i < extinguishCount; i++) {
            String s = list.getString(0);
            list.remove(0);
            BlockPos p = parsePos(s);
            if (p != null) {
                toExtinguish.add(p);
            }
        }

        if (list.isEmpty()) {
            data.remove("grain_domino_queue");
        } else {
            data.put("grain_domino_queue", list);
        }

        if (level instanceof net.minecraft.server.level.ServerLevel serverLevel) {
            for (BlockPos pos : toExtinguish) {
                if (isFire(level.getBlockState(pos))) {
                    level.setBlock(pos, Blocks.AIR.defaultBlockState(), 3);

                    // Smoke particle
                    serverLevel.sendParticles(net.minecraft.core.particles.ParticleTypes.SMOKE, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, 2, 0.15, 0.15, 0.15, 0.05);

                    // Random subtle hiss sound at the block pos
                    if (serverLevel.random.nextFloat() < 0.2f) {
                        BuiltInRegistries.SOUND_EVENT.getOptional(ResourceLocation.parse("block.fire.extinguish")).ifPresent(extinguish -> {
                            level.playSound(null, pos, extinguish, SoundSource.BLOCKS, 0.25f, 1.2f + serverLevel.random.nextFloat() * 0.4f);
                        });
                    }
                }
            }
        }
    }

    private static BlockPos parsePos(String s) {
        if (s == null || s.isEmpty()) return null;
        try {
            String[] parts = s.split(",");
            if (parts.length == 3) {
                return new BlockPos(
                    Integer.parseInt(parts[0]),
                    Integer.parseInt(parts[1]),
                    Integer.parseInt(parts[2])
                );
            }
        } catch (Exception e) {}
        return null;
    }

    private static boolean isFire(BlockState state) {
        return state.getBlock() instanceof BaseFireBlock
                || state.is(Blocks.FIRE)
                || state.is(Blocks.SOUL_FIRE);
    }
}