/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.events.Event;
    import starling.geom.Polygon;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;

    /**
     * Class for displaying an icon that symbolizes the current status of the player.
     */
    public class PlayerModeIcon extends Image {

        /**
         * Texture for displaying arrows.
         */
        private var _triangle: Texture;
        /**
         * Texture to display kruglishochka.
         */
        private var _circle: Texture;

        /**
         * Constructor.
         *
         * @param width
         * @param player
         */
        public function PlayerModeIcon(width: Number, player: Player) {
            _triangle = createTriangleTexture(width * 3);
            _circle = createCircleTexture(width * 3);

            super(_circle);

            pivotX = pivotY = width * 1.5;
            scale = 0.33;

            player.addEventListener(Player.EVENT_PLAYER_CHANGED_MODE, function (event: Event): void {
                setMode(event.data.mode);
            });
            setMode(player.mode);
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            _triangle.dispose();
            _circle.dispose();

            super.dispose();
        }

        /**
         * Creates a circle texture.
         *
         * @param width
         *
         * @return
         */
        protected function createCircleTexture(width: Number): Texture {
            const rt: RenderTexture = new RenderTexture(width, width, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const canvas: Canvas = new Canvas();
                canvas.beginFill();
                canvas.drawCircle(width / 2, width / 2, width / 3);
                canvas.x = canvas.y = 0;

                rt.draw(canvas, null, 1.0, 4);

                canvas.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates a triangle texture.
         *
         * @param width
         *
         * @return
         */
        protected function createTriangleTexture(width: Number): Texture {
            const rt: RenderTexture = new RenderTexture(width, width, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const triangle: Polygon = new Polygon();
                triangle.addVertices(width / 2, 0);
                triangle.addVertices(width, width);
                triangle.addVertices(0, width);

                const canvas: Canvas = new Canvas();
                canvas.beginFill();
                canvas.drawPolygon(triangle);
                canvas.x = canvas.y = 0;

                rt.draw(canvas, null, 1.0, 4);

                canvas.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Sets the current icon display mode.
         *
         * @param mode
         */
        private function setMode(mode: uint): void {
            switch (mode) {
                case Player.MODE_ACCELERATING:
                    texture = _triangle;
                    color = 0x31a082;
                    rotation = 0;
                    break;

                case Player.MODE_DECELERATING:
                    texture = _triangle;
                    color = 0xd92b00;
                    rotation = Math.PI;
                    break;

                default:
                    texture = _circle;
                    color = Director.MAIN_BROWNISH_FONT_COLOR;
                    rotation = 0;
                    break;
            }
        }


    }
}
