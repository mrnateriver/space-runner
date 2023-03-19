/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import flash.geom.Point;

    import stages.Gameplay;

    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.filters.FragmentFilter;
    import starling.textures.Texture;
    import starling.utils.Pool;

    import support.drawing.TextureGenerator;

    /**
     * Planet class made up of layers, each pre-generated or loaded as
     * textures.
     */
    public class RenderedPlanet extends BasePlanet {

        /**
         * The minimum rotation speed of the layers of the planet for random generation.
         */
        public static const RANDOM_SPEED_MIN: Number = 2;
        /**
         * The maximum speed of rotation of the layers of the planet with random generation.
         */
        public static const RANDOM_SPEED_MAX: Number = 4;

        /**
         * Addition to the size of the textures of the animated layers of the planet.
         */
        protected static const TEXTURE_OVERSIZE_MARGIN: uint = 50;

        /**
         * The texture of the lighting of the planet.
         */
        private static var _overlayTexture: Texture = null;

        /**
         * Layers of the planet's surface for rendering.
         *
         * Items:
         * {
         *  texture: Texture
         *  textureWidth: Number
         *  image: Image
         *  direction: uint
         *  speed: uint
         * }
         */
        private var _layers: Vector.<Object> = new Vector.<Object>();

        /**
         * Planet layer animation controller.
         */
        private var _rotationJuggler: Juggler = new Juggler();

        /**
         * Planet shadow sprite.
         */
        private var _shadowImage: Image = null;

        /**
         * An array of textures to remove when deleting an object.
         */
        private var _disposableTextures: Vector.<Texture> = new Vector.<Texture>();

        /**
         * @inheritDoc
         */
        public function RenderedPlanet(mass: Number, radius: Number) {
            super(mass, radius);
        }

        /**
         * Shifts the texture coordinates of the specified image by the specified distance in UV coordinates.
         *
         * @param image
         * @param amount
         */
        protected static function shiftTexture(image: Image, amount: Number): void {
            var p: Point = Pool.getPoint();

            for (var i: uint = 0; i < 4; i++) {
                image.getTexCoords(i, p);
                p.x += amount;
                image.setTexCoords(i, p.x, p.y);
            }

            Pool.putPoint(p);
        }

        /**
         * Moves the planet layer image object itself (instead of its texture).
         *
         * @param image
         * @param amount
         */
        protected static function shiftImage(image: Image, amount: Number): void {
            image.x += amount;
        }

        /**
         * @inheritDoc
         */
        override protected function init(): void {
            // add a shadow cast by the planet
            if (RenderedPlanet._overlayTexture === null) {
                RenderedPlanet._overlayTexture = TextureGenerator.createPlanetShadowTexture(Gameplay.MAX_PLANET_RADIUS);
            }

            // compose the planet by layers
            const planetContainer: Sprite = new Sprite();

            const layersLength: int = _layers.length;
            for (var i: int = 0; i < layersLength; i++) {
                const layer: Object = _layers[i];

                const layerImage: Image = new Image(layer.texture);
                layerImage.alpha = layer.opacity;

                layerImage.x = layerImage.pivotX = 0;
                layerImage.y = layerImage.pivotY = radius;

                if (layer.speed > 0) {
                    // if the layer is animated, then we need to increase the texture size slightly to provide headroom for the shift
                    layerImage.readjustSize(radius * 2 + TEXTURE_OVERSIZE_MARGIN, radius * 2 + TEXTURE_OVERSIZE_MARGIN);
                    layerImage.y -= TEXTURE_OVERSIZE_MARGIN / 2;

                } else {
                    layerImage.readjustSize(radius * 2, radius * 2);
                }

                if (layer.filter is FragmentFilter) {
                    layerImage.filter = layer.filter;
                    layerImage.filter.cache();
                }

                if (layer.speed > 0) {
                    const rotationTween: Tween = new Tween(layerImage, TEXTURE_OVERSIZE_MARGIN / layer.speed);
                    rotationTween.animate("x", -TEXTURE_OVERSIZE_MARGIN);
                    rotationTween.repeatCount = 0;
                    rotationTween.reverse = true;

                    _rotationJuggler.add(rotationTween);

                    const container: Sprite = new Sprite();
                    container.pivotX = container.pivotY = radius;
                    container.x = container.y = radius;
                    container.rotation = Math.random() * 2 * Math.PI;

                    container.addChild(layerImage);
                    planetContainer.addChild(container);

                } else {
                    planetContainer.addChild(layerImage);
                }

                layer.image = layerImage;
            }

            // now we need to add a round mask
            const mask: Canvas = new Canvas();
            mask.drawCircle(radius, radius, radius);

            planetContainer.mask = mask;

            // random rotation for a change
            planetContainer.pivotX = planetContainer.pivotY = radius;
            planetContainer.x = planetContainer.y = radius;

            addChild(planetContainer);

            // all layers have been added to the scene - we need to add special effects and assign a frame rendering handler
            const overlayImage: Image = new Image(RenderedPlanet._overlayTexture);
            overlayImage.scale = radius * 2 / overlayImage.width;
            addChild(overlayImage);

            pivotY = pivotX = radius;

            // slight optimization
            touchable = false;

            // adding the planet's outline object
            createOutline();
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            for each (var texture: Texture in _disposableTextures) {
                texture.dispose();
            }
            super.dispose();
        }

        /**
         * Advances rotation animation of planet layers.
         *
         * @param time
         */
        public override function advanceTime(time: Number): void {
            _rotationJuggler.advanceTime(time);
            super.advanceTime(time);
        }

        /**
         * Adds a surface layer for the given planet with the specified parameters. This method must be called before
         * adding an object to the scene - after that it will have no effect.
         *
         * @param texture The texture of the layer.
         * @param filter The filter instance to additionally apply to the image when rendering.
         * @param rotationSpeed Rotation speed.
         * @param opacity
         *
         * @return object
         */
        public function addLayer(texture: Texture,
                                 filter: FragmentFilter = null,
                                 rotationSpeed: Number = NaN,
                                 opacity: Number = 1.0): Object {

            if (isNaN(rotationSpeed)) {
                rotationSpeed = RANDOM_SPEED_MIN + (RANDOM_SPEED_MAX - RANDOM_SPEED_MIN) * Math.random();
            }

            const newLayer: Object = {
                texture: texture,
                textureWidth: texture.frameWidth,
                filter: filter,
                image: null,
                speed: rotationSpeed,
                opacity: opacity
            };

            _layers.push(newLayer);
            _disposableTextures.push(texture);

            return newLayer;
        }

    }

}
