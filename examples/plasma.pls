// Demoscene-style plasma effect
// Based on a tutorial by Lode Vandevenne
// https://lodev.org/cgtutor/plasma.html

let FRAME_WIDTH = 512;
let FRAME_HEIGHT = 512;

// Convert RGB/RGBA values in the range [0, 255] to a u32 encoding
fun rgb32(r, g, b)
{
    return 0xFF_00_00_00 | (r << 16) | (g << 8) | b;
}

// Convert a color from HSV format to RGB format
fun hsv_to_rgb(h, s, v)
{
    if (s < 0.01)
    {
        // simple gray conversion
        let c = (v * 255.0).floor();
        return rgb32(c, c, c);
    }

    // convert hue from [0, 360( to range [0,6)
    let var h = h / 60.0;
    if (h >= 6.0)
        h = h - 6.0;

    // break "h" down into integer and fractional parts.
    let i = h.floor();
    let f = h - i;

    // Compute the permuted RGB values
    let vi = (f * 255.0).floor();
    let p = ((v * (1.0 - s)) * 255.0).floor();
    let q = ((v * (1.0 - (s * f))) * 255.0).floor();
    let t = ((v * (1.0 - (s * (1.0 - f)))) * 255.0).floor();

    // map v, p, q, and t into red, green, and blue values
    if (i == 0)
        return rgb32(vi, t, p);
    if (i == 1)
        return rgb32(q, vi, p);
    if (i == 2)
        return rgb32(p, vi, t);
    if (i == 3)
        return rgb32(p, q, vi);
    if (i == 4)
        return rgb32(t, p, vi);

    return rgb32(vi, p, q);
}

let prog_start_time = $time_current_ms();

// Generate the palette
let palette = [];
for (let var i = 0; i < 256; ++i)
{
    // Vary the hue through the palette
    palette.push(hsv_to_rgb(360.0 / 256.0 * i, 1.0, 1.0));
}

// Generate the greyscale plasma values
let plasma = [];
for (let var y = 0; y < FRAME_HEIGHT; ++y)
{
    let row = [];
    for (let var x = 0; x < FRAME_WIDTH; ++x)
    {
        let dx1 = x - 128.0;
        let dy1 = y - 128.0;
        let d1 = (dx1*dx1 + dy1*dy1).sqrt() / 7.0;

        let dx2 = x - 300.0;
        let dy2 = y - 306.0;
        let d2 = (dx2*dx2 + dy2*dy2).sqrt() / 5.0;

        // Sum of multiple sine functions, divided by number of sines
        let value = (
              128.0 + (128.0 * (x / 12.0).sin())
            + 128.0 + (128.0 * (y / 35.0).sin())
            + 128.0 + (128.0 * d1.sin())
            + 128.0 + (128.0 * d2.sin())
        ) / 4;
        row.push(value.floor());
    }
    plasma.push(row);
}

let frame_buffer = ByteArray.with_size(FRAME_WIDTH * FRAME_HEIGHT * 4);
let window = $window_create(FRAME_WIDTH, FRAME_HEIGHT, "Demoscene Plasma Effect", 0);

loop
{
    let frame_start_time = $time_current_ms();
    let time_ms_i = frame_start_time - prog_start_time;
    let palette_offs = (time_ms_i / 20).floor();

    // Create a shifted palette for this frame
    let shifted_palette = [];
    for (let var i = 0; i < 256; ++i)
    {
        shifted_palette.push(palette[(i + palette_offs) % 256]);
    }

    // Draw the plasma with the shifted palette
    let var pixel_idx = 0;
    for (let var y = 0; y < FRAME_HEIGHT; ++y)
    {
        let row = plasma[y];
        for (let var x = 0; x < FRAME_WIDTH; ++x)
        {
            let color_idx = row[x];
            let color = shifted_palette[color_idx];
            frame_buffer.write_u32(pixel_idx, color);
            pixel_idx = pixel_idx + 4;
        }
    }

    $window_draw_frame(window, frame_buffer);

    let frame_end_time = $time_current_ms();
    $println(frame_end_time - frame_start_time);

    // Check for window events
    let msg = $actor_poll();

    if (msg == nil)
        continue;

    if (!(msg instanceof UIEvent))
        continue;

    if (msg.kind == 'CLOSE_WINDOW')
        break;

    if (msg.kind == 'KEY_DOWN' && (msg.key == 'ESCAPE' || msg.key == 'Q'))
        break;
}
