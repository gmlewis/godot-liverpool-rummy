shader_type canvas_item;

uniform float border_width : hint_range(0.0, 50.0) = 10.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 0.8, 1.0); // Gold color
uniform float sparkle_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float time_speed : hint_range(0.1, 10.0) = 5.0;

void fragment() {
    // Use a gold base color for satisfied melds
    vec4 base_color = vec4(0.8, 0.7, 0.2, 1.0); // Gold color fully opaque

    // Get the size of the rect from UV coordinates
    vec2 rect_size = 1.0 / fwidth(UV);

    // Current position in pixels
    vec2 pos = UV * rect_size;

    // Add sparkle effect using noise-like function
    float sparkle = sin(pos.x * 0.1 + TIME * time_speed) * cos(pos.y * 0.1 + TIME * time_speed * 0.7);
    sparkle = (sparkle + 1.0) * 0.5; // Normalize to 0-1
    sparkle = smoothstep(0.3, 0.7, sparkle); // Threshold for sparkle
    vec4 sparkle_color = border_color * (1.0 + sparkle * sparkle_intensity);
    COLOR = mix(base_color, sparkle_color, sparkle);
}