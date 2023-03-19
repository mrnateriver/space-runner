/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.directing {

    import flash.utils.getQualifiedClassName;

    import starling.animation.IAnimatable;
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.ResizeEvent;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.styles.MeshStyle;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.Align;
    import starling.utils.StringUtil;

    import support.objects.GameObject;

    /**
     * The base class of any scene.
     */
    public class Scene extends GameObject implements IAnimatable {

        /**
         * Whether to show the scene size in debug mode.
         */
        protected var _showStageSize: Boolean = false;
        /**
         * Element with scene size text in debug mode.
         */
        private var _sceneSizeValue: TextField;

        /**
         * Returns the width of the scene in pixels.
         */
        public function get sceneWidth(): int {
            return stage.stageWidth;
        }

        /**
         * Returns the height of the scene in points.
         */
        public function get sceneHeight(): int {
            return stage.stageHeight;
        }

        /**
         * The procedure for initializing the scene as an abstract game object.
         * This method is needed to override the initialization logic for child scene classes.
         */
        override final protected function init(): void {
            initScene();

            if (engine.showStats && _showStageSize) {
                const fontName: String = BitmapFont.MINI;
                const fontSize: Number = BitmapFont.NATIVE_SIZE;
                const fontColor: uint = 0xffffff;
                const width: Number = 90;
                const height: Number = 10;

                var sceneSizeLabel: TextField = new TextField(width, height, "scene size:");
                sceneSizeLabel.format.setTo(fontName, fontSize, fontColor, Align.LEFT);
                sceneSizeLabel.batchable = true;
                sceneSizeLabel.x = 2;

                _sceneSizeValue = new TextField(width - 1, height);
                _sceneSizeValue.format.setTo(fontName, fontSize, fontColor, Align.RIGHT);
                _sceneSizeValue.batchable = true;
                _sceneSizeValue.text = StringUtil.format("{0}x{1}", sceneWidth, sceneHeight);

                var background: Quad = new Quad(width, height, 0x0);
                if (background.style.type != MeshStyle) {
                    background.style = new MeshStyle();
                }

                var sceneSizeSprite: Sprite = new Sprite();
                sceneSizeSprite.addChild(background);
                sceneSizeSprite.addChild(sceneSizeLabel);
                sceneSizeSprite.addChild(_sceneSizeValue);

                sceneSizeSprite.scale = 0.8;
                sceneSizeSprite.x = 0;
                sceneSizeSprite.y = sceneHeight / 2 + 12;

                addChild(sceneSizeSprite);

                stage.addEventListener(ResizeEvent.RESIZE, onResize);
            }
        }

        /**
         * Scene initialization procedure. This method must be overridden by child classes.
         */
        protected function initScene(): void {
        }

        /**
         * Scene resize event handler. Used to update the scene size in the debug window.
         *
         * @param event The event instance.
         */
        private function onResize(event: ResizeEvent): void {
            if (_sceneSizeValue) {
                _sceneSizeValue.text = StringUtil.format("{0}x{1}", sceneWidth, sceneHeight);
                _sceneSizeValue.format.color = 0xff0000;
            }
        }

        /**
         * Returns a function object to assign a touch handler to a specific object.
         *
         * @param target The object whose touch is to be handled.
         * @param callable An event handler whose only argument is a {Touch} instance.
         *
         * @return The generated closure function.
         */
        protected function getTapHandler(target: DisplayObject, callable: Function): Function {
            return function (event: TouchEvent): void {
                var touchLiftoff: Touch = event.getTouch(target, TouchPhase.BEGAN);
                if (touchLiftoff && !touchLiftoff.cancelled) {
                    callable(touchLiftoff);
                }
            };
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            trace(getQualifiedClassName(this) + ": scene disposed");

            dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
            super.dispose();
        }

        /**
         * @inheritDoc
         */
        public function advanceTime(time: Number): void {
        }

    }
}
