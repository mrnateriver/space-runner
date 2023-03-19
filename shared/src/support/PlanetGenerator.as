/*
  * Copyright (c) 2018 Evgenii Dobrovidov.
  * Working name of the project: "space-runner".
  *All rights reserved.
  */

package support {
     import objects.RenderedPlanet;

     import starling.core.Starling;
     import starling.display.Image;
     import starling.events.Event;
     import starling.filters.ColorMatrixFilter;
     import starling.filters.DropShadowFilter;
     import starling.filters.FilterChain;
     import starling.filters.FragmentFilter;
     import starling.textures.RenderTexture;
     import starling.textures.Texture;

     /**
      * Class for random generation of planets.
      */
     public class PlanetGenerator {

         /**
          * The radius above which the planet is considered gas.
          */
         public static const GAS_PLANET_MIN_RADIUS: Number = 50;

         /**
          * Prepared texture combinations for generating small stone planets.
          */
         public static const ROCK_PLANETS_CONFIGURATIONS: Array = [
             /*
              [
              "base level" || fill color,
              "surface detail"
              surface color,
              [possible cloud textures] || false (if clouds are disabled),
              whether to make the clouds white
              ]
              */
             [0xffffff, "details1", PlanetPalette.COLORS.BLUEISH_WHITE, false, false],
             [0xe45901, "details1", null, [1, 2, 3, 4, 5, 6], true],
             [0xeca96f, "details1", PlanetPalette.COLORS.BROWN, [1, 2, 3, 4, 5, 6], true],
             [0x5a6da2, "details1", PlanetPalette.COLORS.DARK_BLUE, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details1", PlanetPalette.COLORS.MOLD_GREEN, [1, 2, 3, 4, 5, 6], true],
             // [0x259782, "details1", PlanetPalette.COLORS.MOLD_GREEN, [7], false],

             [0xffffff, "details2", PlanetPalette.COLORS.BLUEISH_WHITE, false, false],
             [0xeca96f, "details2", null, [1, 2, 3, 4, 5, 6], true],
             [0xe45901, "details2", PlanetPalette.COLORS.DARK_ORANGE, [1, 2, 3, 4, 5, 6], true],
             [0x5a6da2, "details2", PlanetPalette.COLORS.DARK_BLUE, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details2", PlanetPalette.COLORS.MOLD_GREEN, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details2", PlanetPalette.COLORS.MOLD_GREEN, [7], false],

             [0x475b93, "details3", null, [1, 2, 3, 4, 5, 6, 7], true],

             [0xffffff, "details4", null, false, false],
             [0xe45901, "details4", PlanetPalette.COLORS.DARK_ORANGE, [1, 2, 3, 4, 5, 6], true],
             [0xeca96f, "details4", PlanetPalette.COLORS.BROWN, [1, 2, 3, 4, 5, 6], true],
             [0x5a6da2, "details4", PlanetPalette.COLORS.DARK_BLUE, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details4", PlanetPalette.COLORS.MOLD_GREEN, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details4", PlanetPalette.COLORS.MOLD_GREEN, [7], false],

             [0xffffff, "details5", PlanetPalette.COLORS.BLUEISH_WHITE, false, false],
             [0xe45901, "details5", PlanetPalette.COLORS.DARK_ORANGE, [1, 2, 3, 4, 5, 6], true],
             [0xeca96f, "details5", PlanetPalette.COLORS.BROWN, [1, 2, 3, 4, 5, 6], true],
             [0x5a6da2, "details5", PlanetPalette.COLORS.DARK_BLUE, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details5", null, [1, 2, 3, 4, 5, 6], true],
             [0x259782, "details5", null, [7], false]
         ];

         /**
          * Prepared combinations of textures for generating large gas planets.
          */
         public static const GAS_PLANETS_CONFIGURATIONS: Array = [
             [0xda5300, "details6", null, false, false],
             [0xda5300, "details7", PlanetPalette.COLORS.ORANGE, false, false],
             [0xda5300, "details9", PlanetPalette.COLORS.ORANGE, false, false],
             [0xda5300, "details10", PlanetPalette.COLORS.ORANGE, false, false],

             [0x5a6da2, "details7", null, false, false],
             [0x5a6da2, "details6", PlanetPalette.COLORS.BLUE, false, false],
             [0x5a6da2, "details9", PlanetPalette.COLORS.BLUE, false, false],
             [0x5a6da2, "details10", PlanetPalette.COLORS.BLUE, false, false],

             [0xde7e45, "details8", null, false, false],

             [0x475b93, "details9", null, false, false]

             // [0xb5b1c3, "details10", null, false, false],
             // [0xb5b1c3, "details6", PlanetPalette.COLORS.MAGENTA_GRAY, false, false],
             // [0xb5b1c3, "details7", PlanetPalette.COLORS.MAGENTA_GRAY, false, false],
             // [0xb5b1c3, "details8", PlanetPalette.COLORS.MAGENTA_GRAY, false, false],
             // [0xb5b1c3, "details9", PlanetPalette.COLORS.MAGENTA_GRAY, false, false]
         ];

         /**
          * Generates a planet with the given configuration.
          *
          * @param configuration
          * @param mass
          * @param radius
          *
          * @return
          */
         public static function generateWithConfiguration(configuration: Array,mass:Number,
                                                          radius: Number): RenderedPlanet {
             const director: Director = Starling.current.root as Director;

             const planet: RenderedPlanet = new RenderedPlanet(mass, radius);

             // base layer
             const baseLayer: RenderTexture = new RenderTexture(radius * 2, radius * 2, false,
                                                                                        Starling.contentScaleFactor);
             const draw: Function = function (): void {
                 var baseTexture: Texture;
                 if (typeof configuration[0] === "string") {
                     baseTexture = director.assets.getTexture(configuration[0]);
                 } else {
                     baseTexture = Texture.fromColor(radius * 2, radius * 2, configuration[0]);
                 }

                 const glowTexture: Texture = director.assets.getTexture("glow");
                 const detailsTexture: Texture = director.assets.getTexture(configuration[1]);

                 const base: Image = new Image(baseTexture);
                 const glow: Image = new Image(glowTexture);
                 glow.alpha = 0.3;

                 const details: Image = new Image(detailsTexture);
                 details.width = details.height = radius * 2;

                 if (configuration[2] !== null) {
                     const detailsTint: ColorMatrixFilter = new ColorMatrixFilter();
                     detailsTint.tint(configuration[2]);
                     details.filter = detailsTint;
                 }

                 baseLayer.drawBundled(function (): void {
                     baseLayer.draw(base);
                     baseLayer.draw(glow);
                     baseLayer.draw(details);
                 }, 4.0);

                 base.dispose();
                 glow.dispose();
                 details.dispose();

                 baseTexture.dispose();
                 glowTexture.dispose();
                 detailsTexture.dispose();
             };
             draw();

             var assetsRestore: Function = function (): void {
                 draw();
                 director.assets.removeEventListener(Event.TEXTURES_RESTORED, assetsRestore);
             };

             baseLayer.root.onRestore = function (): void {
                 baseLayer.clear();
                 director.assets.addEventListener(Event.TEXTURES_RESTORED, assetsRestore);
             };

             planet.addLayer(baseLayer, null, 0);

             // clouds with 20% chance
             if (configuration[3] !== false && Math.random() > 0.8) {
                 const cloudsTextureIndex: Number = Algorithms.getRandomArrayEntries(configuration[3]);
                 const cloudsTexture: Texture = director.assets.getTexture("clouds" + cloudsTextureIndex);
                 if (cloudsTexture) {
                     var cloudsTintConfiguration: * = configuration[4];
                     planet.addLayer(
                             rasterizeTexture(cloudsTexture, function (): FragmentFilter {
                                 var cloudsTint: ColorMatrixFilter = null;
                                 if (cloudsTintConfiguration) {
                                     cloudsTint = new ColorMatrixFilter();
                                     cloudsTint.adjustBrightness(1);
                                 }

                                 const shadow: DropShadowFilter = new DropShadowFilter(4.0, 0.785, 0x0, 0.6, 0.5, 0.8);

                                 return cloudsTint ? new FilterChain(cloudsTint, shadow) : shadow;
                             }),
                             null,
                             RenderedPlanet.RANDOM_SPEED_MIN + (RenderedPlanet.RANDOM_SPEED_MAX - RenderedPlanet.RANDOM_SPEED_MIN) * Math.random() + Math.random() * 5,
                             0.8
                     );

                 } else {
                     trace("Failed to load clouds texture with index: " + cloudsTextureIndex);
                 }
             }

             return planet;
         }

         /**
          * Rasterizes the specified texture with the filter.
          *
          * @param texture
          * @param filterGenerator
          *
          * @return
          */
         public static function rasterizeTexture(texture: Texture, filterGenerator: Function): Texture {
             const director: Director = Starling.current.root as Director;

             const rt: RenderTexture = new RenderTexture(texture.width, texture.height, false, texture.scale);
             const draw: Function = function (): void {
                 const sprite: Image = new Image(texture);
                 sprite.filter = filterGenerator();
                 rt.draw(sprite);

                 sprite.dispose();
             };
             draw();

             var assetsRestore: Function = function (): void {
                 draw();
                 director.assets.removeEventListener(Event.TEXTURES_RESTORED, assetsRestore);
             };

             rt.root.onRestore = function (): void {
                 rt.clear();
                 director.assets.addEventListener(Event.TEXTURES_RESTORED, assetsRestore);
             };

             return rt;
         }

         /**
          * Generates a planet randomly.
          *
          * @param mass
          * @param radius
          *
          * @return
          */
         public static function generate(mass: Number, radius: Number): RenderedPlanet {
             var configurationSelection: Array;
             if (radius > GAS_PLANET_MIN_RADIUS) {
                 configurationSelection = GAS_PLANETS_CONFIGURATIONS;
             } else {
                 configurationSelection = ROCK_PLANETS_CONFIGURATIONS;
             }

             const configuration: Array = Algorithms.getRandomArrayEntries(configurationSelection);

             return generateWithConfiguration(configuration, mass, radius);
         }

     }

}
