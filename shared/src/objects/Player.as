/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.geom.Point;

    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.filters.DisplacementMapFilter;
    import starling.textures.Texture;

    import support.objects.MassiveObject;
    import support.objects.MovingObject;

    /**
     * A game object representing the player.
     */
    public class Player extends MovingObject {

        public static const PLAYER_SPRITE_WIDTH: Number = 40;

        public static const MODE_NORMAL: uint = 0;
        public static const MODE_ACCELERATING: uint = 1;
        public static const MODE_DECELERATING: uint = 2;

        /**
         * Event type of the player's collision with another object.
         */
        public static const EVENT_PLAYER_COLLIDED: String = "player_collided";

        /**
         * Type of event for changing the current state of the player.
         */
        public static const EVENT_PLAYER_CHANGED_MODE: String = "player_changed_mode";

        /**
         * Weight of the player in kilograms.
         */
        protected static const PLAYER_MASS: Number = 1;

        private var _playerAccelerationFlame: Image;
        private var _playerSprite: Image;
        private var _mode: uint;

        private var _playerFlameTexture: Texture;
        private var _playerTexture: Texture;

        private var _explosion: Image;
        private var _explosionScale: Number;

        private var _dontAddDistortionToFlame: Boolean = false;

        /**
         * Constructor. Initializes the physical parameters of the player.
         */
        public function Player(dontAddDistortionToFlame: Boolean = false) {
            super(PLAYER_MASS, newPoint(1, 0));

            _playerTexture = director.assets.getTexture("player");
            _playerFlameTexture = director.assets.getTexture("player_flame");

            _explosion = new Image(director.assets.getTexture("explosion"));

            _dontAddDistortionToFlame = dontAddDistortionToFlame;
        }

        /**
         * Sets the current display mode of the player object.
         *
         * @param newMode
         */
        public function set mode(newMode: uint): void {
            if (_mode !== newMode) {
                dispatchEventWith(EVENT_PLAYER_CHANGED_MODE, false, { mode: newMode });
            }

            _mode = newMode;
            _playerAccelerationFlame.visible = newMode === MODE_ACCELERATING;
        }

        /**
         * Returns the current display mode of the player object.
         */
        public function get mode(): uint {
            return _mode;
        }

        /**
         * Initialization procedure when adding to the scene. Creates a player display, assigns event handlers.
         */
        override protected function init(): void {
            _playerAccelerationFlame = new Image(_playerFlameTexture);
            _playerSprite = new Image(_playerTexture);

            _playerSprite.scale = _playerAccelerationFlame.scale = PLAYER_SPRITE_WIDTH / _playerSprite.width;

            if (!_dontAddDistortionToFlame) {
                addDistortionTo(_playerAccelerationFlame);
            }

            mode = MODE_NORMAL;

            addChild(_playerAccelerationFlame);
            addChild(_playerSprite);

            alignPivot();

            addEventListener(MassiveObject.EVENT_COLLIDED, onCollidedWithObject);

            _explosion.alignPivot();
            _explosion.x = _playerSprite.width / 2;
            _explosion.y = _playerSprite.height / 2;
            addChild(_explosion);

            _explosionScale = (PLAYER_SPRITE_WIDTH * 1.5) / _explosion.width;
            _explosion.scale = 0.01;
            // _explosion.alpha = 0;
            _explosion.visible = false;
        }

        /**
         * Adds a distortion filter to the specified object.
         *
         * @param target
         */
        private function addDistortionTo(target: DisplayObject): void {
            var offset: Number = 0;
            var scale: Number = Starling.contentScaleFactor;
            var width: int = target.width;
            var height: int = target.height;

            var perlinData: BitmapData = new BitmapData(width * scale, height * scale, false);
            perlinData.perlinNoise(70 * scale, 10 * scale, 2, 5, true, true, 0, true);

            var dispMap: BitmapData = new BitmapData(perlinData.width, perlinData.height * 2, false);
            dispMap.copyPixels(perlinData, perlinData.rect, new Point(0, 0));
            dispMap.copyPixels(perlinData, perlinData.rect, new Point(0, perlinData.height));

            var texture: Texture = Texture.fromBitmapData(dispMap, false, false, scale);
            var filter: DisplacementMapFilter = new DisplacementMapFilter(texture,
                                                                          BitmapDataChannel.RED,
                                                                          BitmapDataChannel.RED,
                                                                          10,
                                                                          5);

            target.filter = filter;
            target.addEventListener("enterFrame", function (event: EnterFrameEvent): void {
                if (offset > height) {
                    offset -= height;
                } else {
                    offset += event.passedTime * 40;
                }

                filter.mapY = offset - height;
            });
        }

        public function crash(): void {
            _playerSprite.visible = false;
            _explosion.visible = true;

            const inc: Tween = new Tween(_explosion, 0.1);
            inc.scaleTo(_explosionScale);
            const dec: Tween = new Tween(_explosion, 0.1);
            dec.scaleTo(0.01);
            dec.onComplete = function (): void {
                _explosion.visible = false;
            };
            inc.nextTween = dec;

            Starling.juggler.add(inc);
            // Starling.juggler.add(scale);
        }

        /**
         * Player collision handler with another object. Generates more specific events depending on
         * what type of object the collision occurred with.
         *
         * @param event The event instance.
         */
        protected function onCollidedWithObject(event: Event): void {
            trace("player collided with object", event.data);

            if (event.data is BasePlanet) {
                dispatchEventWith(EVENT_PLAYER_COLLIDED, true, event.data);
            }
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            _playerFlameTexture.dispose();
            _playerTexture.dispose();
            super.dispose();
        }

    }

}
