shader_type canvas_item;

uniform float border_width : hint_range(0.0, 50.0) = 20.0;
uniform vec4 border_color : source_color = vec4(0.5, 0.5, 0.5, 0.5);

void fragment() {
    // Get the size of the rect from UV coordinates
    vec2 rect_size = 1.0 / fwidth(UV);

    // Current position in pixels
    vec2 pos = UV * rect_size;

    // Check distance from each edge
    bool near_left = pos.x < border_width;
    bool near_right = pos.x > (rect_size.x - border_width);
    bool near_top = pos.y < border_width;
    bool near_bottom = pos.y > (rect_size.y - border_width);

    if (near_left || near_right || near_top || near_bottom) {
        COLOR = border_color;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}