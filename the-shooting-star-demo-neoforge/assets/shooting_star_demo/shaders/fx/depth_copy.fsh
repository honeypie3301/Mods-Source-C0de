// Copies the scene's depth into the effects' snapshot, value by value. A framebuffer blit would need the two depth
// formats to match exactly, and 1.20.1 makes its depth buffer with a format the driver picks and need not report
// (NVIDIA answers the generic DEPTH_COMPONENT): the blit failed there and every effect in the world lay hidden.
void main() {
    gl_FragDepth = texture(DepthSampler, texCoord).r;
    fragColor = vec4(0.0);
}
