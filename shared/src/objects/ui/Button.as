/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects.ui {
    import flash.geom.Point;
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Canvas;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;
    import starling.utils.Align;

    import support.objects.GameObject;

    /**
     * UI Button.
     */
    public class Button extends GameObject {
        /**
         * Identifier of the button click event.
         */
        public static const EVENT_CLICKED: String = "button_clicked";

        /**
         * Frame width.
         */
        public static const BORDER_WIDTH: Number = 2.0;
        /**
         * The radius of the rounding of the corners of the frame.
         */
        public static const BORDER_RADIUS: Number = 10.0;

        /**
         * Sprite image frame button.
         */
        private var _borderImage: Image;
        /**
         * Flag indicating whether the button will be pressed when the mouse/finger button is released from the screen.
         */
        private var _canClick: Boolean = false;
        /**
         * A pool of cursor coordinates to optimize the check in the event of its movement.
         */
        private var _clickHoverPointPool: Point = new Point();

        /**
         * Constructor.
         *
         * @param content
         * @param borderColor
         */
        public function Button(content: DisplayObject, borderColor: uint) {
            super();

            _borderImage = new Image(createBorderTexture(content.width + 20, content.height + 10, borderColor));
            _borderImage.scale = 0.333;
            _borderImage.alpha = 0;
            addChild(_borderImage);

            content.alignPivot(Align.LEFT, Align.TOP);
            content.x = 10;
            content.y = 5;
            addChild(content);

            const that: Button = this;
            addEventListener(TouchEvent.TOUCH, function (event: TouchEvent): void {
                var touchBegin: Touch = event.getTouch(that, TouchPhase.BEGAN);
                var touchEnd: Touch = event.getTouch(that, TouchPhase.ENDED);
                var touchHover: Touch = event.getTouch(that, TouchPhase.MOVED);

                if (touchBegin && !touchBegin.cancelled) {
                    _canClick = true;
                    _borderImage.alpha = 1.0;

                } else if (touchEnd && !touchEnd.cancelled && _canClick) {
                    _canClick = false;
                    _borderImage.alpha = 0;

                    that.dispatchEventWith(EVENT_CLICKED);

                } else if (touchHover && !touchHover.cancelled && _canClick) {
                    touchHover.getLocation(that, _clickHoverPointPool);
                    if (_clickHoverPointPool.x < 0 || _clickHoverPointPool.x > that.width ||
                        _clickHoverPointPool.y > that.height || _clickHoverPointPool.y < 0) {
                        _canClick = false;
                        _borderImage.alpha = 0;
                    }
                }

                event.stopPropagation();
            });
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            _borderImage.texture.dispose();

            super.dispose();
        }

        /**
         * Returns the frame texture of the specified dimensions with rounded edges.
         *
         * @param width
         * @param height
         * @param color
         *
         * @return
         */
        protected function createBorderTexture(width: Number, height: Number, color: uint): Texture {
            const radius: Number = BORDER_RADIUS * 3;
            const borderWidth: Number = BORDER_WIDTH * 3;
            const virtualWidth: Number = width * 3;
            const virtualHeight: Number = height * 3;

            const rt: RenderTexture = new RenderTexture(virtualWidth,
                                                        virtualHeight,
                                                        false,
                                                        Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(color);

                cv.drawRectangle(radius, 0, virtualWidth - radius * 2, borderWidth); // top
                cv.drawRectangle(radius, virtualHeight - borderWidth, virtualWidth - radius * 2, borderWidth); // bottom
                cv.drawRectangle(0, radius, borderWidth, virtualHeight - radius * 2); // left
                cv.drawRectangle(virtualWidth - borderWidth, radius, borderWidth, virtualHeight - radius * 2); // right

                cv.drawCircle(radius, radius, radius); // top-left
                cv.drawCircle(virtualWidth - radius, radius, radius); // top-right
                cv.drawCircle(radius, virtualHeight - radius, radius); // bottom-left
                cv.drawCircle(virtualWidth - radius, virtualHeight - radius, radius); // bottom-right

                const eraser: Canvas = new Canvas();
                eraser.beginFill();
                eraser.blendMode = BlendMode.ERASE;

                eraser.drawRectangle(borderWidth, radius, virtualWidth - borderWidth * 2, virtualHeight - radius * 2);
                eraser.drawRectangle(radius, borderWidth, virtualWidth - radius * 2, virtualHeight - borderWidth * 2);

                const shift: Number = borderWidth / Math.sqrt(2) + 1.5;

                eraser.drawCircle(radius + shift, radius + shift, radius);
                eraser.drawCircle(virtualWidth - radius - shift, radius + shift, radius);
                eraser.drawCircle(radius + shift, virtualHeight - radius - shift, radius);
                eraser.drawCircle(virtualWidth - radius - shift, virtualHeight - radius - shift, radius);

                rt.drawBundled(function (): void {
                    rt.draw(cv);
                    rt.draw(eraser);
                }, 16);

                cv.dispose();
                eraser.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }
    }

}
