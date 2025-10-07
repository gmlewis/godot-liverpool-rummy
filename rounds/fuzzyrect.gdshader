shader_type canvas_item;

uniform float border_width : hint_range(0.0, 50.0) = 40.0;
uniform vec4 border_color : source_color = vec4(0.5, 0.5, 0.5, 0.5);

void fragment() {
    vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 uv = UV * size;

    // Check if we're within the border area
    bool in_border = (uv.x < border_width || uv.x > size.x - border_width ||
                      uv.y < border_width || uv.y > size.y - border_width);

    if (in_border) {
        COLOR = border_color;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Fully transparent
    }
}