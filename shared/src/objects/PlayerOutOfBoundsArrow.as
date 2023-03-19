/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.animation.IAnimatable;
    import starling.display.Image;
    import starling.textures.Texture;
    import starling.utils.Pool;

    import support.Algorithms;
    import support.drawing.TextureGenerator;
    import support.objects.GameObject;

    /**
     * Game object with an arrow that appears when the player leaves the screen and shows the direction from
     * the center of the scene to the location of the player.
     */
    public class PlayerOutOfBoundsArrow extends GameObject implements IAnimatable {

        /**
         * The type of event in which the player leaves the scene.
         */
        public static const PLAYER_LEFT_SCENE: String = "player_left_scene_bounds";
        /**
         * The type of event in which the player returns to the scene.
         */
        public static const PLAYER_ENTERED_SCENE: String = "player_entered_scene_bounds";

        /**
         * Arrow width. It is used only in test mode, the final texture is used.
         */
        private const ARROW_WIDTH: Number = 30;

        /**
         * The player object that is being tracked.
         */
        private var _player: Player;
        /**
         * The current position of the player.
         */
        private var _playerPosition: Point;

        /**
         * A rectangle that defines the boundaries of the scene, beyond which this object will be displayed.
         */
        private var _sceneRectangle: Rectangle;
        /**
         * Whether the object is currently visible.
         */
        private var _arrowVisible: Boolean = false;
        /**
         * Maximum scene zoom ratio.
         */
        private var _maxDownscale: Number;

        private var _minBounds: Point;
        private var _maxBounds: Point;

        /**
         * The texture of the arrow.
         */
        private var _arrowTexture: Texture;

        /**
         * Constructor. Accepts a player instance to track.
         *
         * @param player
         * @param maxDownscale
         */
        public function PlayerOutOfBoundsArrow(player: Player, maxDownscale: Number = 1) {
            _player = player;
            _maxDownscale = maxDownscale;

            _arrowTexture = getTexture();
        }

        /**
         * Procedure for initializing an object. Sets constants, determines the size of the scene, sets the texture and
         * assigns event handlers.
         */
        override protected function init(): void {
            const scaledWidth: Number = stage.stageWidth * _maxDownscale;
            const scaledHeight: Number = stage.stageHeight * _maxDownscale;

            _minBounds = new Point(-(scaledWidth - stage.stageWidth) / 2, -(scaledHeight - stage.stageHeight) / 2);
            _maxBounds = new Point(scaledWidth - (scaledWidth - stage.stageWidth) / 2, scaledHeight - (scaledHeight - stage.stageHeight) / 2);

            _sceneRectangle = new Rectangle(ARROW_WIDTH * 0.75,
                    ARROW_WIDTH * 0.75, stage.stageWidth - ARROW_WIDTH * 1.5, stage.stageHeight - ARROW_WIDTH * 1.5);

            _playerPosition = new Point(_player.x, _player.y);

            const image: Image = new Image(_arrowTexture);
            addChild(image);

            alignPivot();

            visible = false;
        }

        /**
         * Frame rendering event handler. Used to update the visibility state of a given object and
         * calculation of its position.
         *
         * @inheritDoc
         */
        public function advanceTime(time: Number): void {
            if (_arrowVisible) {
                if (_player.x < _maxBounds.x && _player.x > _minBounds.x &&
                    _player.y < _maxBounds.y && _player.y > _minBounds.y) {
                    visible = false;
                    _arrowVisible = false;

                    dispatchEventWith(PLAYER_ENTERED_SCENE);

                } else {
                    updateArrowPosition();
                }

            } else {
                if (_player.x > _maxBounds.x || _player.x < _minBounds.x ||
                    _player.y > _maxBounds.y || _player.y < _minBounds.y) {
                    // before making the arrow visible, we need to update its position to prevent blinking
                    updateArrowPosition();

                    visible = true;
                    _arrowVisible = true;

                    dispatchEventWith(PLAYER_LEFT_SCENE);
                }
            }
        }

        /**
         * Calculates and updates the position of a given object and orientation in space.
         */
        protected function updateArrowPosition(): void {
            _playerPosition.x = _player.x;
            _playerPosition.y = _player.y;

            const intersection: Point = Pool.getPoint();
            Algorithms.getRectangleRayIntersectionPoint(_playerPosition, _sceneRectangle, intersection);
            x = intersection.x;
            y = intersection.y;
            Pool.putPoint(intersection);

            const up: Point = Pool.getPoint(0, -1);
            const center: Point = Pool.getPoint(_sceneRectangle.x + _sceneRectangle.width / 2, _sceneRectangle.y + _sceneRectangle.height / 2);

            var angle: Number = Algorithms.getAngleBetweenVectors(_playerPosition.subtract(center), up);

            Pool.putPoint(up);
            Pool.putPoint(center);

            if (_player.x < stage.stageWidth / 2) {
                angle = 2 * Math.PI - angle;
            }
            angle += Math.PI / 2; // the default arrow points to the left, so we need to add 90 degrees to the rotation
            rotation = angle;
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            _arrowTexture.dispose();
            super.dispose();
        }

        /**
         * Returns an instance of the texture used for this object.
         *
         * @return
         */
        protected function getTexture(): Texture {
            return TextureGenerator.createArrowTexture(ARROW_WIDTH, ARROW_WIDTH * 1.5, 0x0, 0xed9c2e);
        }

    }

}
