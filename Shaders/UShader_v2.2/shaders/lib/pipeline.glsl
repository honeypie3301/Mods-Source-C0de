/*
const int colortex0Format   = RGBA16F;
const int colortex1Format   = RGBA16;
const int colortex2Format   = RGBA16;
const int colortex3Format   = RGBA16;
const int colortex4Format   = RGBA16F;
const int colortex5Format   = RGBA16F;
const int colortex6Format   = RGBA16F;
const int colortex7Format   = RGBA16F;
const int colortex8Format   = RGBA16F;
const int colortex9Format   = RGBA16;
const int colortex10Format  = R16F;
const int colortex11Format  = RGBA16F;
const int colortex12Format  = R16;
const int colortex13Format  = RGBA16;
const int colortex14Format  = R8;

const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

const bool colortex6Clear   = false;
const bool colortex7Clear   = false;
const bool colortex8Clear   = false;
const bool colortex9Clear   = false;
const bool colortex10Clear  = false;
const bool colortex13Clear  = false;

const int noiseTextureResolution = 256;

C0: SceneColor
    3x16 Scene Color        (full)

C1: GData01
    2x16 Scene Normals      (gbuffer -> composite)
    1x16 Lightmaps          (gbuffer -> composite)
    2x8  Wetness + POM Shadow   (gbuffer -> composite)

C2: GData02
    2x16 Specular Texture   (gbuffer -> composite)
    1x16 MatID              (gbuffer -> composite)
    2x8  AO Data            (gbuffer -> deferred)

C3:
    4x16 Direct Light + Albedo (deferred -> composite)

C4:
    3x16 Skybox Captures    (prepare -> composite)

C5:
    4x16 Cloud Image        (deferred -> deferred),
         Translucency Color (water -> composite),
    3x16 Fog Scattering     (composite -> composite)

C6:
    3x16 Temporal AA        (full)
    1x16 Temporal Exposure  (full)

C7:
    4x16 Indirect History

C8:
    4x16 Cloud Reconstruct  (full)

C9:
    3x16 Fog Transmittance Reconstruction (full)
    2x8 Checkerboard Data   (full)

C10: A
    3x16 Fog Scattering Reconstruction (full)
    1x16 Previous Distance  (full)

C11: B
    3x16 Fog Transmittance  (composite -> composite)
*/