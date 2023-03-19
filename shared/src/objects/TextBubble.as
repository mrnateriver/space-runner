/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package objects {
    import starling.animation.IAnimatable;
    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.display.Image;
    import starling.events.Event;
    import starling.extensions.ColorArgb;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.Align;

    import support.Strings;

    import support.drawing.TextureGenerator;
    import support.objects.GameObject;

    /**
     * Popup message with free text and an asterisk in front of it.
     */
    public class TextBubble extends GameObject implements IAnimatable {

        public static const EVENT_ANIMATION_COMPLETED: String = "animation_completed";

        /**
         * Text.
         */
        private var _text: String;
        /**
         * Block width. Required to align content to the center.
         */
        private var _width: Number;

        /**
         * The texture of the star icon.
         */
        private var _starTexture: Texture;

        /**
         * Animator for internal object animations.
         */
        private var _animationJuggler: Juggler = new Juggler();

        /**
         * Constructor.
         *
         * @param text
         * @param width
         */
        public function TextBubble(text: String, width: Number) {
            super();

            _text = text;
            _width = width;

            _starTexture = TextureGenerator.createStarIcon(ColorArgb.fromArgb(0xffed9c2e), 25);
        }

        /**
         * @inheritDoc
         */
        protected override function init(): void {
            const text: TextField = new TextField(_width, 50, _text);
            text.format.setTo(Strings.getFont(), 50 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.CENTER);
            text.batchable = true;
            text.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1, 1, 0.8);

            addChild(text);

            const star: Image = new Image(_starTexture);
            star.alignPivot();
            star.filter = new DropShadowFilter();

            star.x = _width / 2 - text.textBounds.width / 2;
            star.y = 30;

            // shift the text so that together with the star they are centered
            text.x = star.width / 2;

            addChild(star);

            this.alignPivot();

            this.alpha = 0;
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);

            _starTexture.dispose();
            super.dispose();
        }

        /**
         * Displays this pop-up message with an animation of appearing and disappearing, after which it immediately deletes
         * object from the scene.
         */
        public function show(): void {
            const that: TextBubble = this;

            const appear: Tween = new Tween(this, 0.7);
            appear.fadeTo(1.0);

            const disappear: Tween = new Tween(this, 0.3);
            disappear.fadeTo(0.0);

            const move: Tween = new Tween(this, 1);
            move.moveTo(this.x, this.y - 30);

            appear.nextTween = disappear;

            move.onComplete = function (): void {
                that.dispatchEventWith(EVENT_ANIMATION_COMPLETED);
                that.removeFromParent(true);

                dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
            };

            _animationJuggler.add(appear);
            _animationJuggler.add(move);
        }

        /**
         * @inheritDoc
         */
        public function advanceTime(time: Number): void {
            _animationJuggler.advanceTime(time);
        }

    }

}
