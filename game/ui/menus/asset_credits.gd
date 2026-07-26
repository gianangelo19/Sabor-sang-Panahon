extends RefCounted

## Centralized attribution catalog for free third-party art used by the project.
## Keep this list in sync when a downloaded asset is added or removed.

const SKETCHFAB_CREDITS := """
7-11 convenience store|Pasha|Sketchfab Standard|https://sketchfab.com/3d-models/7-11-convenience-store-797ab2c504d54979a217574efec34b45
Game ready building 5|ModelMaker|CC BY 4.0|https://sketchfab.com/3d-models/game-ready-building-5-73b1d5fc97ca46bab7f80b7c95001e79
Game Ready Mid Poly Building|ModelMaker|CC BY 4.0|https://sketchfab.com/3d-models/game-ready-mid-poly-building-dc4f6a49d8a7462b9349936b8dc7256e
Mesh Grill 03|romullus|CC BY-SA 4.0|https://sketchfab.com/3d-models/mesh-grill-03-b01080604d1b4552bcfd0faa4a6b00ee
NYC Bronx Buildings|99.Miles|CC BY 4.0|https://sketchfab.com/3d-models/nyc-bronx-buildings-9092600d1d9b46b7881746d44d8bfc58
old buildings|daftvid|CC BY 4.0|https://sketchfab.com/3d-models/old-buildings-f3775d0c3d9844fd8b1e95f430e3c890
Old Indonesian Simple House|sakit.jawa|CC BY 4.0|https://sketchfab.com/3d-models/old-indonesian-simple-house-ec295239d58d46cabedcce1607bf8135
Asian Buildings Set|golukumar|Sketchfab Standard|https://sketchfab.com/3d-models/asian-buildings-set-d3d7c14c576547e8912df310eb1f0476
Corrugated Metal Fence Material|Arsen Ismailov|CC BY 4.0|https://sketchfab.com/3d-models/corrugated-metal-fence-material-1328ca60d49b4b4884622b7a9884be62
Empty Mall|loafbrr|CC BY 4.0|https://sketchfab.com/3d-models/empty-mall-ac571db422444da4a2ec8ac1693e9148
Worned out traffic Light|Besk.art|CC BY 4.0|https://sketchfab.com/3d-models/worned-out-traffic-light-93f2afaf987d43f8ab1cf4b1e9f31fdf
boysen paint bucket|dinn|CC BY 4.0|https://sketchfab.com/3d-models/boysen-paint-bucket-58791242335a4627a3aa1fcbde945e9b
Classic Plastic Chairs|Francesco Coldesina|CC BY 4.0|https://sketchfab.com/3d-models/classic-plastic-chairs-6d139742099d48f195e6774514ccb7ef
Coca Cola Refrigerator|tonielpro520|CC BY 4.0|https://sketchfab.com/3d-models/coca-cola-refrigerator-eb505434e36c4416b8bdc3d87e9a6cc3
CocaCola Bottle|AverageMan|CC BY 4.0|https://sketchfab.com/3d-models/cocacola-bottle-af2601ae4d22455a829d4172fa18e83c
Commercial Front With Garage Door, Philippines|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/commercial-front-with-garage-door-philippines-a1ecd9e87c95444dbff19cfb82c4020b
Crates and boxes at the back of an Asian store|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/crates-and-boxes-at-the-back-of-an-asian-store-26f01d69ac8c49b2a4c34e21b68c656f
Electric Meters And Panels 1|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/electric-meters-and-panels-1-ec17e89b49a5436b8b329b5c05e905c4
Fan Blades|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/fan-blades-99032cbd6f91468a840f334b226c22bf
Fancy Shelf|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/fancy-shelf-39a8ac4cd178481897cb8a6bba627797
French Coke can|Robukan|CC BY-NC-ND 4.0|https://sketchfab.com/3d-models/french-coke-can-6a35d2c1bfe143e4b7e27a9e5324a905
Fridge Low Poly|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/fridge-low-poly-c97173e2b9cd4149bedf5a2572776e22
Garbage Disposal Bin - 3D scan|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/garbage-disposal-bin-3d-scan-a8751db2d94647ddac226d9d6886164c
Giant Filipino Banana (Polycam iPad Pro LIDAR)|JFN|CC BY 4.0|https://sketchfab.com/3d-models/giant-filipino-banana-polycam-ipad-pro-lidar-cc9f604aed304dd7b88d54f9ebea2396
Kitchen Oven and Sink Set Low Poly|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/kitchen-oven-and-sink-set-low-poly-4907f6a11e874b4daa90b8bef4fc83c0
Mechanical door garage door - 20MB|Mehdi Shahsavan|CC BY 4.0|https://sketchfab.com/3d-models/mechanical-door-garage-door-20mb-d46996c46d8f4ff9a516f4dbc835b6a5
Old table|EricKos|CC BY 4.0|https://sketchfab.com/3d-models/old-table-c1391f05e2a046ef9bd91945caf75fb8
Old table Fan|Chamod|CC BY 4.0|https://sketchfab.com/3d-models/old-table-fan-0815782d15ae4ecab62469100311956b
Petron Gas|Erin|CC BY 4.0|https://sketchfab.com/3d-models/petron-gas-a193c1f766b84bfbaa3ed492f694d87e
Plastic Chair|Jazavac|CC BY 4.0|https://sketchfab.com/3d-models/plastic-chair-be3d5131e634424e89ffd57ebb19804e
Single Sandbag|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/single-sandbag-77186bbcebce4c4a833d6153217e48d2
Small Wooden Cabinet Low Poly|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/small-wooden-cabinet-low-poly-bf4e6be63a4647d6a4b7b1158092dcde
Stylized Plastic Chair|Minh Nguyen|CC BY 4.0|https://sketchfab.com/3d-models/stylized-plastic-chair-90498283b9844372af0ff0c761a2612c
Table Fancy 1|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/table-fancy-1-142bc494bbea40ef8e2d3894c0a96431
Wooden Door and Frame|GameDevMoot|CC BY 4.0|https://sketchfab.com/3d-models/wooden-door-and-frame-4b2791977bbc4c23bcb7fb7c0cd61d54
Industrial Pipe|SLASH / RENDAR|CC BY 4.0|https://sketchfab.com/3d-models/industrial-pipe-08390acccfd84752bd8ec83b8ca07430
Mango Tree|stealth86|CC BY 4.0|https://sketchfab.com/3d-models/mango-tree-4b186052228d43d8b3fbb63213677de8
Realistic Tree|Daniel|CC BY 4.0|https://sketchfab.com/3d-models/realistic-tree-d989c0f801d847b9a74992ec4ddcfdfc
13 Forrunner 2.5 G (Textured)|sakit.jawa|CC BY 4.0|https://sketchfab.com/3d-models/13-forrunner-25-g-textured-82e30441125d4321ba1d661fe7c361a0
1984 Suzuki Kei Truck|Hubcap1235|CC BY 4.0|https://sketchfab.com/3d-models/1984-suzuki-kei-truck-c08fd6d5410b4a4099043033907616bd
2011 - 13 Toyota Kijang Innova 2.0 G (TGN40)|boiled fish|CC BY 4.0|https://sketchfab.com/3d-models/2011-13-toyota-kijang-innova-20-g-tgn40-3069bcbb3ee843a0bd2aa148c7a43130
Abandoned car / vehicle (Multicab) 3D Scan|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/abandoned-car-vehicle-multicab-3d-scan-5ed2b4a8b5564c6d98efa76ce62df505
Car Covered With Gray Cloth 2|Alben Tan|CC BY 4.0|https://sketchfab.com/3d-models/car-covered-with-gray-cloth-2-a6663b2e7d264f6898738706901914cc
Honda Supra x 125|Kucing Garage|CC BY 4.0|https://sketchfab.com/3d-models/honda-supra-x-125-6d61abb3aa3a4161bda31ef783111015
2005 - 2008 Innova V 2.7 (TGN41)|boiled fish|CC BY 4.0|https://sketchfab.com/3d-models/2005-2008-innova-v-27-tgn41-57ae7a0f70b14ee0a65e82ae754c5b4b
Lowpoly Traysikel / Tricycle|Joshua Rei|CC BY 4.0|https://sketchfab.com/3d-models/lowpoly-traysikeltricycle-08cb15a0c57748f793e0ead5e5095722
Poor Model 09 Aznava 1.5 S|sakit.jawa|CC BY 4.0|https://sketchfab.com/3d-models/poor-model-09-aznava-15-s-e592e92bc25c413db82597da46f9e947
Updated 2000 Toyota Kijang Krista|ORANG JAHAT 3D|CC BY 4.0|https://sketchfab.com/3d-models/updated-2000-toyota-kijang-krista-78ec7505556d4e0b82da4600d6220983
Low Poly Roof Tile Game Ready|Arthur.Zim|CC BY 4.0|https://sketchfab.com/3d-models/low-poly-roof-tile-game-ready-0c9486bb5bb84b379d431ebd45ec00d1
Lake Pinatubo, Philippines|riyabidaye|CC BY-NC-SA 4.0|https://sketchfab.com/3d-models/lake-pinatubo-philippines-0b0f1fe192764f68b0253a8d2b4c4e99
"""

const POLY_HAVEN_MODELS := [
	"Shelf 01",
	"Bananas",
	"Book Encyclopedia Set 01",
	"Cardboard Box 01",
	"Circuit Board",
	"Desk Lamp Arm 01",
	"Gamepad",
	"Lightbulb LED",
	"Metal Stool 02",
	"Modular Electricity Poles",
	"Office Notepads",
	"Plastic Container",
	"Plastic Monobloc Chair 01",
	"Plastic Thermos",
	"Power Box 01",
	"Pull Chain Light Socket",
	"Round Wooden Table 01",
	"Side Table 01",
	"Standing Picture Frame 02",
	"Stationery Supplies",
	"Steel Frame Shelves 02",
	"Sungka Board 02",
	"Wall Clock",
	"Wooden Cutting Board",
	"Wooden Table 02",
]

const POLY_HAVEN_MATERIALS := [
	"Asphalt 02",
	"Brown Floor Tiles",
	"Clean Asphalt",
	"Floor Tiles 02",
	"Ground Grey",
	"Herringbone Brick 03",
	"Interior Tiles",
	"Old Linoleum Flooring 01",
	"Painted Concrete 02",
	"Patio Tiles",
	"Polystyrene",
	"Rusty Metal Sheet",
	"Weathered Planks",
	"Wood Table Worn",
]

const POLY_HAVEN_HDRIS := [
	"Bambanani Sunset",
	"Citrus Orchard Road PureSky",
	"Plains Sunset",
]


static func build_bbcode() -> String:
	var credits := (
		"[color=#fff0cf][font_size=22][b]ASSET PACKS & TYPEFACE[/b][/font_size][/color]\n"
		+ "[url=https://kenney.nl/assets/animated-characters-1]Animated Characters 1[/url] — Kenney / Kay Lousberg — CC0\n"
		+ "[url=https://kenney.nl/assets/city-kit-suburban]City Kit (Suburban)[/url] — Kenney — CC0\n"
		+ "[url=https://kenney.nl/assets/retro-urban-kit]Retro Urban Kit[/url] — Kenney — CC0\n"
		+ "[url=https://kyle-fuji.itch.io/low-poly-bedroom-asset-pack]Low Poly Bedroom Asset Pack[/url] — Kyle Fuji — CC0\n"
		+ "[url=https://loafbrr.itch.io/toilets]Toilets[/url] — loafbrr — CC0\n"
		+ "[url=https://lukky-nl.itch.io/handpainted-texture-pack]Handpainted Texture Pack[/url] — Lukky — CC0\n"
		+ "[url=https://www.dafont.com/vcr-osd-mono.font]VCR OSD Mono[/url] — Riciery Leal — free for personal and commercial use\n\n"
		+ "[color=#fff0cf][font_size=22][b]POLY HAVEN — CC0[/b][/font_size][/color]\n"
		+ "Free 3D models, materials, and HDRIs from [url=https://polyhaven.com/]polyhaven.com[/url].\n\n"
		+ "[color=#ffd28a][b]3D MODELS[/b][/color]\n"
	)
	credits += _format_asset_list(POLY_HAVEN_MODELS)
	credits += "\n[color=#ffd28a][b]MATERIALS[/b][/color]\n"
	credits += _format_asset_list(POLY_HAVEN_MATERIALS)
	credits += "\n[color=#ffd28a][b]HDRIs[/b][/color]\n"
	credits += _format_asset_list(POLY_HAVEN_HDRIS)
	credits += (
		"\n[color=#fff0cf][font_size=22][b]SKETCHFAB MODELS[/b][/font_size][/color]\n"
		+ "Each title links to its original model page. Licenses are shown as supplied with each download.\n\n"
	)

	for line in SKETCHFAB_CREDITS.strip_edges().split("\n"):
		var fields := line.split("|")
		if fields.size() == 4:
			credits += (
				"- [url=%s]%s[/url] — %s — %s\n"
				% [fields[3], fields[0], fields[1], fields[2]]
			)

	credits += (
		"\n[color=#ffe2ad]Thank you to every creator who shared their work with the game-development community.[/color]"
	)
	return credits


static func sketchfab_credit_count() -> int:
	return SKETCHFAB_CREDITS.strip_edges().split("\n").size()


static func _format_asset_list(assets: Array) -> String:
	var formatted := ""
	for asset in assets:
		formatted += "- %s\n" % asset
	return formatted
