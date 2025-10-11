shader_type canvas_item;

uniform float border_width : hint_range(0.0, 50.0) = 20.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 0.8, 1.0); // Gold color
uniform float sparkle_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float time_speed : hint_range(0.1, 10.0) = 3.0;
uniform float star_density : hint_range(0.1, 5.0) = 2.0;

void fragment() {
    // Get the size of the rect from UV coordinates
    vec2 rect_size = 1.0 / fwidth(UV);

    // Current position in pixels
    vec2 pos = UV * rect_size;

    // Calculate distance from edges
    float dist_left = UV.x;
    float dist_right = 1.0 - UV.x;
    float dist_top = UV.y;
    float dist_bottom = 1.0 - UV.y;

    // Find minimum distance to any edge
    float min_dist = min(min(dist_left, dist_right), min(dist_top, dist_bottom));
    float edge_factor = 1.0 - smoothstep(0.0, border_width / rect_size.x, min_dist);

    // Create star pattern
    vec2 star_pos = pos * star_density;
    vec2 star_grid = floor(star_pos);
    vec2 star_uv = fract(star_pos);

    // Random star positions within each grid cell
    float star_seed = star_grid.x * 7.0 + star_grid.y * 13.0;
    vec2 star_offset = vec2(
        fract(sin(star_seed) * 43758.5453),
        fract(cos(star_seed) * 43758.5453)
    );

    vec2 star_center = star_uv - star_offset;
    float star_dist = length(star_center);

    // Create star shape (cross pattern)
    float star_angle = atan(star_center.y, star_center.x);
    float star_shape = abs(sin(star_angle * 4.0)) + abs(cos(star_angle * 4.0));
    star_shape = 1.0 - smoothstep(0.3, 0.7, star_shape);

    // Star size and twinkle
    float star_size = 0.1 + 0.05 * sin(TIME * time_speed + star_seed);
    float star_brightness = 1.0 - smoothstep(0.0, star_size, star_dist);
    star_brightness *= star_shape;

    // Twinkle effect
    float twinkle = sin(TIME * time_speed * 2.0 + star_seed * 10.0) * 0.5 + 0.5;
    star_brightness *= twinkle;

    // Combine edge factor with star brightness
    float final_brightness = edge_factor * star_brightness * sparkle_intensity;

    // Create final color
    vec4 star_color = border_color * final_brightness;
    COLOR = star_color;
}