/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {

    import flash.utils.setTimeout;

    import starling.animation.IAnimatable;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.events.Event;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;

    import support.objects.MassiveObject;

    /**
     * The base class of planets in the game. Child classes should only override the texture generation procedure.
     */
    public class BasePlanet extends MassiveObject implements IAnimatable {

        /**
         * The type of event when the planet begins to have the most gravitational influence on the specified object.
         */
        public static const EVENT_BECAME_MOST_ATTRACTING: String = "became_most_attracting";

        /**
         * Planet radius in DP.
         */
        private var _radius: Number;
        /**
         * Outline of the planet.
         */
        private var _outline: PlanetOutline;
        /**
         * Animation of planet contour rotation.
         */
        private var _outlineRotationTween: Tween;

        private var _baseTexture: Texture;

        /**
         * Constructor. Initializes the physical parameters of the object, and also saves the given radius of the planet for
         * further use.
         *
         * @param mass The mass of the planet in kilograms.
         * @param radius Planet radius in DP.
         */
        public function BasePlanet(mass: Number, radius: Number) {
            super(mass);

            _radius = radius;
        }

        /**
         * Sets whether the outline of the planet is displayed.
         *
         * @param value
         */
        public function set outline(value: Boolean): void {
            if (_outline) {
                if (value) {
                    _outline.show();
                } else {
                    _outline.hide();
                }
            }
        }

        /**
         * The procedure for initializing an object when added to the scene. Creates an object mapping, assigns handlers
         * events.
         */
        protected override function init(): void {
            _baseTexture = getTexture();

            var content: Image = new Image(_baseTexture);
            addChild(content);

            alignPivot();

            createOutline();
        }

        /**
         * Returns the texture of the planet. In the case of the given base class, only the circle of the given
         * random color radius.
         *
         *@return
         */
        protected function getTexture(): Texture {
            var texture: RenderTexture = new RenderTexture(_radius * 2, _radius * 2, false,
                                                                                     Starling.contentScaleFactor);

            const draw: Function = function (): void {
                var canvas: Canvas = new Canvas();
                canvas.beginFill(Math.random() * 0xbbbbbb /* 0xffffff - 0x444444 */ + 0x444444);
                canvas.drawCircle(_radius, _radius, _radius);

                texture.draw(canvas, null, 1.0, 16);

                canvas.dispose();
            };
            draw();

            texture.root.onRestore = function (): void {
                texture.clear();
                setTimeout(draw, 0);
            };

            return texture;
        }

        /**
         * Returns the radius of the given planet in DP.
         */
        public function get radius(): Number {
            return_radius;
        }

        /**
         * Advances planet outline animation.
         *
         * @param time
         */
        public function advanceTime(time: Number): void {
            if (_outline) {
                _outline.advanceTime(time);
                _outlineRotationTween.advanceTime(time);
            }
        }

        /**
         * Creates and initializes an instance of the planet outline.
         */
        protected function createOutline(): void {
            _outline = new PlanetOutline(this);
            _outline.x = _outline.y = radius;
            addChild(_outline);

            _outlineRotationTween = new Tween(_outline, 120);
            _outlineRotationTween.rotateTo(90, "deg");
            _outlineRotationTween.repeatCount = 0;

            addEventListener(EVENT_BECAME_MOST_ATTRACTING, onBecameMostAttractingPlanet);
        }

        /**
         * Handles the event when a given planet begins to act gravitationally on the planet the most
         * specified object.
         *
         * @param event
         */
        protected function onBecameMostAttractingPlanet(event: Event): void {
            trace("planet became most attracting");

            const previous: BasePlanet = event.data.previous as BasePlanet;
            if (previous) {
                previous.outline = false;
            }
            outline = true;
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);

            if (_baseTexture) {
                _baseTexture.dispose();
            }
            super.dispose();
        }

    }

}
