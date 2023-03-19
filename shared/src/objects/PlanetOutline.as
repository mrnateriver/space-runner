/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import flash.utils.setTimeout;

    import starling.animation.IAnimatable;
    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.events.Event;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;

    import support.objects.GameObject;

    /**
     * The class of the dotted outline of the planet.
     */
    public class PlanetOutline extends GameObject implements IAnimatable {

        /**
         * Distance from the planet's surface to the contour line.
         */
        public const GAP_SIZE: int = 10;
        /**
         * Maximum length of one dotted section.
         */
        public const MAX_SECTION_LENGTH: int = 30;
        /**
         * Minimum number of dotted sections.
         */
        public const MIN_SECTIONS_COUNT: int = 12;
        /**
         * Distance between dotted line sections.
         */
        public const SECTION_MARGIN: int = 10;

        /**
         * The planet around which the contour is displayed.
         */
        private var _planet: BasePlanet;
        /**
         * Outline color.
         */
        private var _color: uint;
        /**
         * Thickness of the contour line.
         */
        private var _thickness: uint;

        /**
         * Outline image.
         */
        private var _outlineImage: Image;

        /**
         * Animation controller for the appearance and concealment of the contour.
         */
        private var _juggler: Juggler = new Juggler();

        /**
         * Outline texture.
         */
        private var _outlineTexture: Texture;

        /**
         * Constructor.
         *
         * @param planet The planet around which the outline will be drawn.
         * @param color Outline color.
         * @param thickness The line thickness of the outline.
         */
        public function PlanetOutline(planet: BasePlanet, color: uint = 0xfcb570, thickness: uint = 5) {
            _planet = planet;
            _color = color;
            _thickness = thickness;
        }

        /**
         * @inheritDoc
         */
        override protected function init(): void {
            _outlineTexture = createTexture();

            _outlineImage = new Image(_outlineTexture);
            _outlineImage.visible = false;
            _outlineImage.alignPivot();

            addChild(_outlineImage);

            alignPivot();
        }

        /**
         * Displays this contour.
         */
        public function show(): void {
            _juggler.purge();
            _juggler.add(createAppearAnimation());
        }

        /**
         * Hides the current outline.
        */
        public function hide(): void {
            _juggler.purge();
            _juggler.add(createDisappearAnimation());
        }

        /**
         * Produces animation of all registered objects.
         *
         * @param time Time elapsed since the last frame.
         */
        public function advanceTime(time: Number): void {
            _juggler.advanceTime(time);
        }

        /**
         * Creates an animation of the appearance of the contour.
         *
         * @return The animation object.
         */
        protected function createAppearAnimation(): IAnimatable {
            const resultJuggler: Juggler = new Juggler();

            const scaleUp: Tween = new Tween(_outlineImage, 1, Transitions.EASE_OUT_ELASTIC);
            scaleUp.scaleTo(1.0);
            scaleUp.onStart = function(): void {
                _outlineImage.alpha = 0.0;
                _outlineImage.scale = 0.8;
                _outlineImage.visible = true;
            };
            resultJuggler.add(scaleUp);

            const appear: Tween = new Tween(_outlineImage, 0.2);
            appear.fadeTo(1.0);
            resultJuggler.add(appear);

            return resultJuggler;
        }

        /**
         * Creates an animation of the outline disappearing.
         *
         * @return The animation object.
         */
        protected function createDisappearAnimation(): IAnimatable {
            const resultJuggler: Juggler = new Juggler();

            const scaleDown: Tween = new Tween(_outlineImage, 0.1, Transitions.LINEAR);
            scaleDown.scaleTo(1.5);
            scaleDown.onComplete = function (): void {
                _outlineImage.visible = false;
            };
            resultJuggler.add(scaleDown);

            const disappear: Tween = new Tween(_outlineImage, 0.1);
            disappear.fadeTo(0.0);
            resultJuggler.add(disappear);

            return resultJuggler;
        }

        /**
         * Creates an instance of the texture used to render the path.
         */
        protected function createTexture(): Texture {
            const baseRadius: Number = _planet.radius + GAP_SIZE + _thickness;

            const texture: RenderTexture = new RenderTexture(baseRadius * 2, baseRadius * 2, false,
                                                                                             Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(_color);
                cv.drawCircle(baseRadius, baseRadius, baseRadius);
                cv.alignPivot();
                cv.x = cv.y = baseRadius;

                const centerEraser: Canvas = new Canvas();
                centerEraser.beginFill();
                centerEraser.drawCircle(baseRadius, baseRadius, baseRadius - _thickness);
                centerEraser.blendMode = BlendMode.ERASE;
                centerEraser.alignPivot();
                centerEraser.x = centerEraser.y = baseRadius;

                const circumference: Number = 2 * Math.PI * baseRadius;

                var erasersCount: Number;
                if (circumference / (MAX_SECTION_LENGTH + SECTION_MARGIN) >= MIN_SECTIONS_COUNT) {
                    // If the length of the circle can fit more pieces of the maximum length than the minimum
                    // quantity
                    erasersCount = Math.floor(circumference / (MAX_SECTION_LENGTH + SECTION_MARGIN));
                } else {
                    erasersCount = MIN_SECTIONS_COUNT;
                }

                const sectionAngle: Number = 2 * Math.PI / erasersCount;

                // Let's choose a random starting angle
                var angle: Number = Math.random() * (2 * Math.PI);
                var passedAngle: Number = 0;

                const erasers: Vector.<Canvas> = new Vector.<Canvas>(erasersCount);
                for (var i: int = 0; i < erasersCount; i++) {
                    const eraser: Canvas = new Canvas();
                    eraser.beginFill();
                    eraser.drawRectangle(0, 0, baseRadius, SECTION_MARGIN);
                    eraser.blendMode = BlendMode.ERASE;
                    eraser.rotation = angle;
                    eraser.x = eraser.y = baseRadius;
                    erasers[i] = eraser;

                    angle += sectionAngle;
                    passedAngle += sectionAngle;

                    if (passedAngle > 2 * Math.PI) {
                        break;
                    }
                }

                texture.drawBundled(function (): void {
                    texture.draw(cv);
                    texture.draw(centerEraser);

                    erasers.forEach(function (eraser: Canvas, index: int, vector: Vector.<Canvas>): void {
                        texture.draw(eraser);
                    });
                });

                cv.dispose();
                centerEraser.dispose();
                erasers.forEach(function (eraser: Canvas, index: int, vector: Vector.<Canvas>): void {
                    eraser.dispose();
                });
            };
            draw();

            texture.root.onRestore = function (): void {
                texture.clear();
                setTimeout(draw, 0);
            };

            return texture;
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);

            _outlineTexture.dispose();
            super.dispose();
        }

    }

}
