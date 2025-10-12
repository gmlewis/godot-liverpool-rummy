shader_type canvas_item;

// Sparkler properties
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float spark_density : hint_range(0.1, 2.0) = 1.0;
//uniform float spark_size : hint_range(0.01, 0.2) = 0.05;
uniform float spark_brightness : hint_range(0.5, 3.0) = 1.5;
uniform float trail_length : hint_range(0.1, 2.0) = 0.8;

// Color properties
uniform vec4 spark_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float color_variation : hint_range(0.0, 1.0) = 0.3;

// Movement properties
uniform float gravity : hint_range(-0.5, 0.5) = 0.1;
uniform float wind_strength : hint_range(0.0, 0.3) = 0.05;
//uniform vec2 wind_direction = vec2(1.0, 0.0);

// Random number generator (hash function)
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Quintic interpolation
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;
    float aspect_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    uv.x *= aspect_ratio;
    
    // Center of the sparkler (middle bottom)
    vec2 center = vec2(0.5 * aspect_ratio, 0.1);
    vec2 to_center = center - uv;
    
    // Time with scale
    float t = TIME * time_scale;
    
    // Initialize color
    vec4 final_color = vec4(0.0);
    
    // Core glow
    float dist_to_center = length(to_center);
    float core_glow = max(0.0, 1.0 - dist_to_center * 8.0);
    final_color += core_color * core_glow * 0.5;
    
    // Spark particles
    float spark_sum = 0.0;
    const int NUM_OCTAVES = 8;
    
    for (int i = 0; i < NUM_OCTAVES; i++) {
        float fi = float(i);
        
        // Each octave has different properties
        float scale = pow(2.0, fi) * 0.5;
        float weight = 1.0 / pow(2.0, fi);
        float speed = 1.0 + fi * 0.3;
        
        // Animated position with gravity and wind
        vec2 animated_uv = uv * scale;
        animated_uv.y += t * speed * 2.0; // Spark movement upward
        animated_uv.y -= gravity * t * t * 0.5; // Gravity effect
        animated_uv.x += sin(t * 0.7 + fi) * wind_strength; // Wind effect
        
        // Add some randomness to position
        vec2 offset = vec2(sin(fi * 123.456), cos(fi * 456.789)) * 0.3;
        animated_uv += offset;
        
        // Sample noise
        float n = noise(animated_uv + vec2(t * speed, 0.0));
        
        // Spark shape (circular with some variation)
        float spark = smoothstep(0.7, 1.0, n) * weight;
        
        // Fade out based on distance from center and time
        float life_fade = 1.0 - fract(t * speed + fi);
        life_fade = pow(life_fade, trail_length * 4.0);
        
        // Distance fade from center
        float dist_fade = 1.0 - smoothstep(0.0, 0.4, dist_to_center);
        
        spark *= life_fade * dist_fade * spark_density;
        spark_sum += spark;
    }
    
    // Apply spark color with brightness and size
    float spark_intensity = spark_sum * spark_brightness;
    spark_intensity = min(spark_intensity, 1.0);
    
    // Color variation
    vec3 varied_color = spark_color.rgb;
    varied_color.r += (hash(uv + t) - 0.5) * color_variation;
    varied_color.g += (hash(uv + t + 1.0) - 0.5) * color_variation * 0.7;
    
    // Add sparks to final color
    final_color += vec4(varied_color * spark_intensity, spark_intensity);
    
    // Bright core at the center
    float core_intensity = max(0.0, 1.0 - dist_to_center * 20.0);
    final_color.rgb += core_color.rgb * core_intensity * 2.0;
    
    // Apply to output
    COLOR = final_color;
}