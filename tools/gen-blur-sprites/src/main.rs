use image::DynamicImage;
use image::ImageReader;
use image::imageops;
use imageproc::filter::gaussian_blur_f32;
use serde::Deserialize;
use std::env;
use std::fs;
use std::path::Path;

#[derive(Debug, Deserialize)]
struct AtlasConfig {
    input: String,
    output: String,
    cell_width: u32,
    cell_height: u32,
    blur_sigma: f32,
    alpha_scale: f32,
}

#[derive(Debug, Deserialize)]
struct Config {
    atlas: Vec<AtlasConfig>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        eprintln!("Usage: {} <config.toml>", args[0]);
        std::process::exit(1);
    }

    let file_contents: String = fs::read_to_string(&args[1])?;
    let atlas_config: Config = toml::from_str(&file_contents)?;

    for (i, config_entry) in atlas_config.atlas.iter().enumerate() {
        println!("\nProcessing entry {}: {}", i, config_entry.input);

        let img: DynamicImage = ImageReader::open(&config_entry.input)?.decode()?;
        let mut rgba_img = img.to_rgba8();
        let (img_width, img_height) = (rgba_img.width(), rgba_img.height());

        let cols: u32 = img_width / config_entry.cell_width;
        let rows: u32 = img_height / config_entry.cell_height / 2;

        if cols == 0 || rows == 0 {
            eprintln!("Error: Image too small to contain any cells.");
            std::process::exit(1);
        }

        for row in 0..rows {
            for col in 0..cols {
                let x = col * config_entry.cell_width;
                let y_src = row * 2 * config_entry.cell_height;
                let y_dest = (row * 2 + 1) * config_entry.cell_height;

                let src_tile = imageops::crop_imm(
                    &rgba_img,
                    x,
                    y_src,
                    config_entry.cell_width,
                    config_entry.cell_height,
                )
                .to_image();

                let mut blurred_img = gaussian_blur_f32(&src_tile, config_entry.blur_sigma);

                for px in blurred_img.pixels_mut() {
                    let alpha: f32 = px.0[3] as f32 * config_entry.alpha_scale;
                    px.0[3] = alpha.clamp(0.0, 255.0) as u8;
                }

                imageops::replace(&mut rgba_img, &blurred_img, x as i64, y_dest as i64);
            }
        }

        if let Some(parent_path) = Path::new(&config_entry.output).parent() {
            fs::create_dir_all(parent_path)?;
        }

        rgba_img.save(&config_entry.output)?;
        println!("Saved {}", config_entry.output);
    }

    Ok(())
}
