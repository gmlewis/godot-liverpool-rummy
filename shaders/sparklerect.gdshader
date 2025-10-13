shader_type canvas_item;

uniform float border_width : hint_range(0.0, 50.0) = 20.0;
uniform vec4 sparkle_color : source_color = vec4(1.0, 0.85, 0.0, 1.0); // Golden
uniform float animation_speed : hint_range(0.5, 5.0) = 0.00005;
uniform float sparkle_count : hint_range(5.0, 30.0) = 30.0;
uniform float sparkle_intensity : hint_range(0.1, 10.0) = 0.8;

// Pseudo-random function
float random(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

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
		vec3 final_color = vec3(0.0);
		float final_alpha = 0.0;
		
		// Create multiple sparklers at random positions along the border
		for (int sparkler = 0; sparkler < 30; sparkler++) {
			if (float(sparkler) >= sparkle_count) break;
			
			float sparkler_id = float(sparkler);
			
			// Random position along the perimeter that changes over time
			float time_cycle = mod(TIME * animation_speed * 0.1, 1.0);
			float perim_rand = random(vec2(sparkler_id, 100.0 + time_cycle * 10.0));
			float perimeter = 2.0 * (rect_size.x + rect_size.y);
			float perim_offset = perim_rand * perimeter;
			
			vec2 sparkler_pos;
			
			// Distribute around border
			if (perim_offset < rect_size.x) {
				sparkler_pos = vec2(perim_offset, border_width * 0.5);
			} else if (perim_offset < rect_size.x + rect_size.y) {
				sparkler_pos = vec2(rect_size.x - border_width * 0.5, border_width * 0.5 + (perim_offset - rect_size.x));
			} else if (perim_offset < 2.0 * rect_size.x + rect_size.y) {
				sparkler_pos = vec2(rect_size.x - (perim_offset - rect_size.x - rect_size.y), rect_size.y - border_width * 0.5);
			} else {
				sparkler_pos = vec2(border_width * 0.5, rect_size.y - (perim_offset - 2.0 * rect_size.x - rect_size.y));
			}
			
			// Fire sparks from this sparkler
			for (int s = 0; s < 12; s++) {
				float spark_id = sparkler_id + float(s) * 0.1;
				float spark_direction = spark_id * 6.28 / 12.0;
				vec2 spark_dir = vec2(cos(spark_direction), sin(spark_direction));
				
				float spark_phase = random(vec2(spark_id, 20.0)) * 6.28;
				float spark_speed = random(vec2(spark_id, 21.0)) * 2.0 + 1.0;
				float time_phase = mod(TIME * animation_speed * spark_speed + spark_phase, 6.28);
				
				float pulse = sin(time_phase) * 0.5 + 0.5;
				pulse = pow(pulse, 2.0);
				
				if (pulse < 0.01) continue;
				
				// Sparks travel outward continuously
				float travel = mod(TIME * animation_speed * spark_speed * 50.0, border_width * 3.0);
				vec2 spark_pos = sparkler_pos + spark_dir * travel;
				float dist = length(pos - spark_pos);
				
				float brightness = pulse / (1.0 + dist * dist / 5.0);
				brightness *= sparkle_intensity;
				
				final_color += sparkle_color.rgb * brightness;
				final_alpha = max(final_alpha, brightness);
			}
		}
		
		final_alpha = max(final_alpha, 0.02);
		COLOR = vec4(final_color, final_alpha);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}