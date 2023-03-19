/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package particles {
    import objects.Player;

    import starling.animation.IAnimatable;
    import starling.display.DisplayObjectContainer;
    import starling.events.Event;

    import support.objects.GameObject;

    /**
     * A particle system that generates a "tail" behind a moving object.
     */
    public class ObjectTrail extends DisplayObjectContainer implements IAnimatable {

        public const TRAIL_COLOR_NORMAL: uint = 0xff8ecd3b;
        public const TRAIL_COLOR_DECELERATING: uint = 0xffbe0606;
        public const TRAIL_COLOR_ACCELERATING: uint = 0xffff8400;

        /**
         * The game object behind which the tail is drawn.
         */
        private var _source: GameObject;

        private var _currentColor: uint = TRAIL_COLOR_NORMAL;

        private var ribbonTrail: RibbonTrail;
        private var followingRibbonSegment: RibbonSegment = new RibbonSegment();
        private var followingRibbonSegmentLine: Vector.<RibbonSegment> = new <RibbonSegment>[followingRibbonSegment];

        /**
         * Constructor.
         *
         * @param source The GameObject to draw the tail behind.
         */
        public function ObjectTrail(source: GameObject) {
            super();

            _source = source;
            _source.addEventListener(Player.EVENT_PLAYER_CHANGED_MODE, onPlayerModeChanged);

            ribbonTrail = new RibbonTrail(50);
            ribbonTrail.isPlaying = true;
            ribbonTrail.movingRatio = 0.35;
            addChild(ribbonTrail);

            ribbonTrail.followTrailSegmentsLine(followingRibbonSegmentLine);
            resetRibbon();
        }

        /**
         * @inheritDoc
         */
        public function advanceTime(time: Number): void {
            followingRibbonSegment.setTo2(_source.x, _source.y, 2, _source.rotation, 1.0, _currentColor);
            ribbonTrail.advanceTime(time);
        }

        protected function resetRibbon(): void {
            ribbonTrail.resetAllTo(_source.x, _source.y, _source.x, _source.y);
        }

        /**
         * Handles the player state change event.
         *
         * @param event
         */
        protected function onPlayerModeChanged(event: Event): void {
            const mode: uint = event.data.mode;
            if (mode === Player.MODE_DECELERATING) {
                _currentColor = TRAIL_COLOR_DECELERATING;
            } else if (mode === Player.MODE_NORMAL) {
                _currentColor = TRAIL_COLOR_NORMAL;
            } else if (mode === Player.MODE_ACCELERATING) {
                _currentColor = TRAIL_COLOR_ACCELERATING;
            }
        }

    }

}
