/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import starling.animation.IAnimatable;
    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.events.Event;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.utils.Align;

    import support.Strings;

    import support.objects.GameObject;

    /**
     * Class for displaying a message about the loss when leaving the scene.
     */
    public class PlayerOutOfBoundsLabel extends GameObject implements IAnimatable {
        /**
         * Timer.
         */
        private var _timer: TextField;
        /**
         * Width of the component.
         */
        private var _width: Number;
        /**
         * The initial value of the timer.
         */
        private var _startingTime: Number;
        /**
         * The currently playing animation of the component appearing or hiding.
         */
        private var _animationJuggler: Juggler = new Juggler();

        /**
         * Constructor.
         *
         * @param startingTime
         * @param width
         */
        public function PlayerOutOfBoundsLabel(startingTime: Number, width: Number) {
            _width = width;
            _startingTime = startingTime;
        }

        /**
         * Sets the current timer value.
         *
         * @param value
         */
        public function set time(value: Number): void {
            _timer.text = value.toString();
            if (value < 10) {
                _timer.format.color = 0x831616;
            } else {
                _timer.format.color = Director.MAIN_BROWNISH_FONT_COLOR;
            }

            if (this.visible) {
                const tween: Tween = new Tween(_timer, 0.1, Transitions.LINEAR);
                tween.scaleTo(1.5);
                tween.onComplete = function (): void {
                    _timer.scale = 1.0;
                };
                _animationJuggler.add(tween);
            }
        }

        /**
         * @inheritDoc
         */
        protected override function init(): void {
            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            const _title: TextField = new TextField(_width, 80, strings.GAMEPLAY_ABOUT_TO_LOSE_TITLE);
            _title.format.setTo(font, 80, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            _title.autoScale = true;
            _title.batchable = true;
            _title.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            _title.alignPivot();

            _title.y = _title.height / 2;
            _title.x = _width / 2;

            trace("Label title x: " + _title.x + " y: " + _title.y + " width: " + _title.width + " height: " + _title.height + " specified width: " + _width);

            addChild(_title);

            _timer = new TextField(_width, 100, _startingTime.toString());
            _timer.format.setTo(font, 100 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            _timer.batchable = true;
            _timer.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            _timer.alignPivot();

            _timer.y = _title.textBounds.height + _timer.height / 2;
            _timer.x = _width / 2;

            addChild(_timer);

            alpha = 0;
            scale = 0.7;
            visible = false;

            alignPivot();
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);

            super.dispose();
        }

        /**
         * Displays the component.
         */
        public function show(): void {
            _animationJuggler.purge();

            visible = true;

            const tween: Tween = new Tween(this, 0.7, Transitions.EASE_OUT_ELASTIC);
            tween.fadeTo(1.0);
            tween.scaleTo(1.0);

            _animationJuggler.add(tween);
        }

        /**
         * Hides the component.
         */
        public function hide(): void {
            _animationJuggler.purge();

            const tween: Tween = new Tween(this, 0.2, Transitions.EASE_IN);
            tween.fadeTo(0.0);
            tween.scaleTo(0.7);

            tween.onComplete = function (): void {
                visible = false;
            };
            _animationJuggler.add(tween);
        }

        /**
         * @inheritDoc
         */
        public function advanceTime(time: Number): void {
            _animationJuggler.advanceTime(time);
        }

    }

}
