use image::DynamicImage;
use image::GrayImage;
use image::ImageReader;
use image::Luma;
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

    for config_entry in atlas_config.atlas.iter() {
        println!("\nProcessing texture atlas {}", config_entry.input);

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

                let tile_w: u32 = src_tile.width();
                let tile_h: u32 = src_tile.height();

                let mut alpha_img = GrayImage::new(tile_w, tile_h);
                for y in 0..tile_h {
                    for x in 0..tile_w {
                        let a: u8 = src_tile.get_pixel(x, y).0[3];
                        alpha_img.put_pixel(x, y, Luma([a]));
                    }
                }

                let blurred_alpha = gaussian_blur_f32(&alpha_img, config_entry.blur_sigma);

                let mut glow_tile = image::RgbaImage::new(tile_w, tile_h);
                for y in 0..tile_h {
                    for x in 0..tile_w {
                        let blurred_a = blurred_alpha.get_pixel(x, y).0[0] as f32;
                        let new_a = (blurred_a * config_entry.alpha_scale).clamp(0.0, 255.0) as u8;
                        glow_tile.put_pixel(x, y, image::Rgba([255, 255, 255, new_a]));
                    }
                }

                imageops::replace(&mut rgba_img, &glow_tile, x as i64, y_dest as i64);
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
