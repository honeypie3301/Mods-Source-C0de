package com.github.alexmodguy.alexscaves.server.level.biome;

import com.github.alexmodguy.alexscaves.AlexsCaves;
import com.github.alexmodguy.alexscaves.server.config.BiomeGenerationConfig;
import com.github.alexmodguy.alexscaves.server.config.BiomeGenerationNoiseCondition;
import com.github.alexmodguy.alexscaves.server.misc.VoronoiGenerator;
import com.google.common.collect.ImmutableList;
import net.minecraft.resources.ResourceKey;
import net.minecraft.world.level.biome.Biome;
import net.minecraft.world.level.levelgen.XoroshiroRandomSource;
import net.minecraft.world.level.levelgen.synth.PerlinSimplexNoise;
import net.minecraft.world.phys.Vec3;

import javax.annotation.Nullable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ACBiomeRarity {
    private static long lastTestedSeed = 0;
    private static final List<Integer> BIOME_OCTAVES = ImmutableList.of(0);
    private static final PerlinSimplexNoise NOISE_X = new PerlinSimplexNoise(new XoroshiroRandomSource(1234L), BIOME_OCTAVES);
    private static final PerlinSimplexNoise NOISE_Z = new PerlinSimplexNoise(new XoroshiroRandomSource(4321L), BIOME_OCTAVES);
    private static final VoronoiGenerator VORONOI_GENERATOR = new VoronoiGenerator(42L);

    private static double biomeSize;
    private static double seperationDistance;
    private static volatile boolean initialized = false;
    
    private static final double BIOME_BOUNDARY_EXTENSION = 1.0D;

    // Per-thread cache to avoid contention. Each world gen thread works on nearby chunks,
    // so a thread-local cache has great spatial coherence.
    private static final int MAX_THREAD_CACHE_SIZE = 8192;
    private static final Object EMPTY_SENTINEL = new Object();
    private static final ThreadLocal<HashMap<Long, Object>> threadLocalCache =
            ThreadLocal.withInitial(() -> new HashMap<>(1024));

    public static void init() {
        VORONOI_GENERATOR.setOffsetAmount(AlexsCaves.COMMON_CONFIG.caveBiomeSpacingRandomness.get());
        biomeSize = AlexsCaves.COMMON_CONFIG.caveBiomeMeanWidth.get() * 0.25D;
        seperationDistance = biomeSize + AlexsCaves.COMMON_CONFIG.caveBiomeMeanSeparation.get() * 0.25D;
        initialized = true;
    }
    
    private static void ensureInitialized() {
        if (!initialized) {
            synchronized (VORONOI_GENERATOR) {
                if (!initialized) {
                    init();
                }
            }
        }
    }

    @Nullable
    public static VoronoiGenerator.VoronoiInfo getRareBiomeInfoForQuad(long worldSeed, int x, int z) {
        ensureInitialized();
        
        if (seperationDistance <= 0) {
            return null;
        }

        long cacheKey = worldSeed ^ (x * 73856093L) ^ (z * 19349669L);
        HashMap<Long, Object> cache = threadLocalCache.get();
        Object cached = cache.get(cacheKey);
        if (cached != null) {
            return cached == EMPTY_SENTINEL ? null : (VoronoiGenerator.VoronoiInfo) cached;
        }
        
        double sampleX = x / seperationDistance;
        double sampleZ = z / seperationDistance;
        double positionOffsetX = AlexsCaves.COMMON_CONFIG.caveBiomeWidthRandomness.get() * NOISE_X.getValue(sampleX, sampleZ, false);
        double positionOffsetZ = AlexsCaves.COMMON_CONFIG.caveBiomeWidthRandomness.get() * NOISE_Z.getValue(sampleX, sampleZ, false);
        VoronoiGenerator.VoronoiInfo info = VORONOI_GENERATOR.get2(sampleX + positionOffsetX, sampleZ + positionOffsetZ, worldSeed);
        
        VoronoiGenerator.VoronoiInfo result;
        if (info.distance() < (biomeSize / seperationDistance) * BIOME_BOUNDARY_EXTENSION) {
            result = info;
        } else {
            result = null;
        }

        if (cache.size() >= MAX_THREAD_CACHE_SIZE) {
            cache.clear();
        }
        cache.put(cacheKey, result != null ? result : EMPTY_SENTINEL);
        return result;
    }

    @Nullable
    public static Vec3 getRareBiomeCenter(VoronoiGenerator.VoronoiInfo voronoiInfo) {
        return voronoiInfo.cellPos().scale(seperationDistance);
    }

    @Nullable
    public static int getRareBiomeOffsetId(VoronoiGenerator.VoronoiInfo voronoiInfo) {
        double normalized = (voronoiInfo.hash() + 1D) * 0.5D; // 0.0 to 1.0
        int biomeCount = BiomeGenerationConfig.getBiomeCountFast();
        int offset = (int) (normalized * biomeCount);
        return Math.min(offset, biomeCount - 1);
    }

    public static boolean isQuartInRareBiome(long worldSeed, int x, int z) {
        return ACBiomeRarity.getRareBiomeInfoForQuad(worldSeed, x, z) != null;
    }

    @Nullable
    public static ResourceKey<Biome> getACBiomeForPosition(long worldSeed, int blockX, int blockZ) {
        ensureInitialized();
        
        int quartX = blockX >> 2;
        int quartZ = blockZ >> 2;
        
        VoronoiGenerator.VoronoiInfo voronoiInfo = getRareBiomeInfoForQuad(worldSeed, quartX, quartZ);
        if (voronoiInfo == null) {
            return null;
        }
        
        int rarityOffset = getRareBiomeOffsetId(voronoiInfo);
        
        Vec3 biomeCenter = getRareBiomeCenter(voronoiInfo);
        if (biomeCenter == null) {
            return null;
        }
        
        int centerBlockX = (int) biomeCenter.x * 4;
        int centerBlockZ = (int) biomeCenter.z * 4;
        
        for (Map.Entry<ResourceKey<Biome>, BiomeGenerationNoiseCondition> entry : BiomeGenerationConfig.getBiomesSnapshot().entrySet()) {
            if (entry.getValue().getRarityOffset() == rarityOffset) {
                // Check if biome center is far enough from spawn
                int distFromSpawn = entry.getValue().getDistanceFromSpawn();
                if (centerBlockX * centerBlockX + centerBlockZ * centerBlockZ < distFromSpawn * distFromSpawn) {
                    return null; // Too close to spawn
                }
                return entry.getKey();
            }
        }
        
        return null;
    }

    @Nullable
    public static Vec3 getACBiomeCenterForPosition(long worldSeed, int blockX, int blockZ) {
        ensureInitialized();
        
        int quartX = blockX >> 2;
        int quartZ = blockZ >> 2;
        
        VoronoiGenerator.VoronoiInfo voronoiInfo = getRareBiomeInfoForQuad(worldSeed, quartX, quartZ);
        if (voronoiInfo == null) {
            return null;
        }
        
        return getRareBiomeCenter(voronoiInfo);
    }
}