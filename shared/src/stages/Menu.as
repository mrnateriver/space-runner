/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package stages {

    import flash.utils.setTimeout;

    import objects.RenderedPlanet;
    import objects.ui.Button;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Canvas;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.extensions.ColorArgb;
    import starling.filters.DropShadowFilter;
    import starling.filters.GlowFilter;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;
    import starling.utils.Align;
    import starling.utils.deg2rad;

    import support.Algorithms;
    import support.PlanetGenerator;
    import support.Strings;
    import support.directing.Scene;
    import support.drawing.TextureGenerator;

    /**
     * Main menu scene.
     * This scene starts the game.
     */
    public class Menu extends Scene {

        protected static var SHIFTED_UI: Boolean = false;

        protected static const PLANET_ROTATION_SPEED: Number = deg2rad(3);

        protected static var planetTexture: RenderTexture;

        /**
         * Animator.
         */
        private var _animationJuggler: Juggler = new Juggler();

        private var _planet: DisplayObject;
        private var _moon: DisplayObject;

        private var _disposeTextures: Vector.<Texture> = new Vector.<Texture>();

        private var _highscore: Number;

        private var _soundWaves: Image;

        private var _uiContainer: DisplayObjectContainer;

        private var _startButton: Button;

        /**
         * Scene title object.
         */
        private var _title: TextField;

        /**
         * Scene initialization. In this procedure, objects are placed on the stage, their positions are set,
         * event handlers, and the trajectory of the flight from the central to the first planet is calculated in advance.
         */
        override protected function initScene(): void {
            _highscore = director.getHighscore();

            setupObjects();
            setupUI();

            director.showBanner(moveStartButtonUp);
        }

        protected function setupUI(): void {
            _uiContainer = new Sprite();

            const topContainer: Sprite = new Sprite();
            _uiContainer.addChild(topContainer);

            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            const title: TextField = new TextField(sceneWidth - 40, 120, strings.MAIN_MENU_TITLE);
            title.format.setTo(font, 90 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.CENTER);
            title.autoScale = true;
            title.batchable = true;
            title.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            title.alignPivot(Align.CENTER, Align.TOP);

            title.y = 60;
            title.x = sceneWidth / 2;
            topContainer.addChild(title);

            if (!isNaN(_highscore)) {
                const scoreContainer: Sprite = new Sprite();

                const starTexture: Texture = TextureGenerator.createStarIcon(ColorArgb.fromArgb(0xffed9c2e), 40);
                _disposeTextures.push(starTexture);

                const scoreIcon: Image = new Image(starTexture);
                scoreIcon.alignPivot();
                scoreIcon.filter = new DropShadowFilter();
                scoreIcon.x = 0;
                scoreIcon.y = 38;
                scoreContainer.addChild(scoreIcon);

                const scoreText: TextField = new TextField(100, 60, _highscore.toString());
                scoreText.format.setTo(font, 60 * Strings.getFontSizeMultiplier(), 0xffffff, Align.LEFT, Align.TOP);
                scoreText.batchable = true;
                scoreText.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
                scoreText.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
                scoreText.x = 30;
                scoreText.y = 0;
                scoreContainer.addChild(scoreText);

                scoreContainer.alignPivot(Align.CENTER, Align.TOP);
                scoreContainer.x = sceneWidth / 2;
                scoreContainer.y = title.y + title.height + 20;
                topContainer.addChild(scoreContainer);
            }

            topContainer.y = -topContainer.height;
            const appear: Tween = new Tween(topContainer, 2, Transitions.EASE_OUT_BACK);
            appear.moveTo(0, 0);
            Starling.juggler.add(appear);

            const bottomContainer: Sprite = new Sprite();
            _uiContainer.addChild(bottomContainer);

            const startLabel: TextField = new TextField(120, 90, strings.MAIN_MENU_START_BUTTON_LABEL);
            startLabel.format.setTo(font, 90 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            startLabel.batchable = true;
            startLabel.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            startLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            _startButton = new Button(startLabel, Director.MAIN_BROWNISH_FONT_COLOR);
            _startButton.addEventListener(Button.EVENT_CLICKED, newGameTapped);

            bottomContainer.addChild(_startButton);
            _startButton.alignPivot();
            _startButton.x = sceneWidth / 2;
            _startButton.y = sceneHeight - 90;
            if (SHIFTED_UI) {
                _startButton.y -= 25;
            }

            // const soundSpeaker: Texture = TextureGenerator.createSoundIcon(30, Director.MAIN_BROWNISH_FONT_COLOR);
            // const soundWaves: Texture = TextureGenerator.createSoundWavesIcon(50, Director.MAIN_BROWNISH_FONT_COLOR);

            // _disposeTextures.push(soundSpeaker);
            // _disposeTextures.push(soundWaves);

            // _soundWaves = new Image(soundWaves);
            // _soundWaves.filter = new DropShadowFilter();

            // const speaker: Image = new Image(soundSpeaker);
            // speaker.filter = new DropShadowFilter();
            // speaker.x = _soundWaves.width + 5;
            // speaker.y = 10;

            // const soundButtonContainer: Sprite = new Sprite();
            // soundButtonContainer.addChild(_soundWaves);
            // soundButtonContainer.addChild(speaker);

            // soundButtonContainer.pivotY = 50;
            // soundButtonContainer.pivotX = 55;
            // soundButtonContainer.x = sceneWidth - 10;
            // soundButtonContainer.y = sceneHeight - 10;

            // soundButtonContainer.addEventListener(TouchEvent.TOUCH,
            //                                       getTapHandler(soundButtonContainer, soundOffTapped));

            // bottomContainer.addChild(soundButtonContainer);
            // _soundWaves.visible = director.soundEnabled;

            bottomContainer.y = bottomContainer.height;
            const appearBottom: Tween = new Tween(bottomContainer, 2, Transitions.EASE_OUT_BACK);
            appearBottom.moveTo(0, 0);
            Starling.juggler.add(appearBottom);

            addChild(_uiContainer);

            Entry.hideLoadingScreen();
        }

        /**
         * Frame rendering event handler. Calculates the current angle of the player in orbit, and also initiates the flight
         * the player to the first planet if necessary.
         */
        override public function advanceTime(time: Number): void {
            _animationJuggler.advanceTime(time);

            if (_planet) {
                _planet.rotation += PLANET_ROTATION_SPEED * time;
            }
            if (_moon) {
                _moon.rotation += PLANET_ROTATION_SPEED * 3 * time;
            }
        }

        private function moveStartButtonUp(): void {
            if (!SHIFTED_UI) {
                _startButton.y -= 25;
                SHIFTED_UI = true;
            }
        }

        override public function dispose(): void {
            for each (var tex: Texture in _disposeTextures) {
                tex.dispose();
            }
            super.dispose();
        }

        /**
         * Creates all objects and adds them to the scene.
         */
        protected function setupObjects(): void {
            if (!planetTexture) {
                planetTexture = new RenderTexture(sceneWidth, sceneHeight / 2,
                                                  false,
                                                  Starling.contentScaleFactor);

                const scw: int = sceneWidth;
                const sch: int = sceneHeight;

                const draw: Function = function (): void {
                    const planetCanvas: Canvas = new Canvas();
                    planetCanvas.beginFill(0x6c2424);
                    planetCanvas.drawCircle(sch, sch, sch);

                    planetCanvas.alignPivot();
                    planetCanvas.x = scw / 2;
                    planetCanvas.y = 1.5 * sch - 180;
                    planetCanvas.filter = new GlowFilter(0xa4dbf8, 0.8, 13);
                    planetCanvas.blendMode = BlendMode.NORMAL;

                    const innerShadowCanvas: Canvas = new Canvas();
                    innerShadowCanvas.beginFill(0x0);
                    innerShadowCanvas.drawCircle(sch / 2, sch / 2, sch / 2);

                    innerShadowCanvas.alignPivot();
                    innerShadowCanvas.x = scw / 2;
                    innerShadowCanvas.y = sch;
                    innerShadowCanvas.filter = new GlowFilter(0x0, 1.0, 30);
                    innerShadowCanvas.blendMode = BlendMode.NORMAL;

                    planetTexture.drawBundled(function (): void {
                        planetTexture.draw(planetCanvas);
                        planetTexture.draw(innerShadowCanvas);
                    }, 4);

                    planetCanvas.dispose();
                    innerShadowCanvas.dispose();
                };
                draw();

                planetTexture.root.onRestore = function (): void {
                    planetTexture.clear();

                    if (director && director.isMainMenuActive) {
                        setTimeout(draw, 0);
                    } else {
                        planetTexture.dispose();
                        planetTexture = null;
                    }
                };
            }

            const planetContainer: Sprite = new Sprite();
            addChild(planetContainer);

            const planet: Image = new Image(planetTexture);
            planet.x = 0;
            planet.y = sceneHeight / 2;
            planetContainer.addChild(planet);

            const cratersContainer: Sprite = new Sprite();
            cratersContainer.pivotX = cratersContainer.pivotY = sceneHeight;
            cratersContainer.x = sceneWidth / 2;
            cratersContainer.y = 2 * sceneHeight - 180;
            planetContainer.addChild(cratersContainer);

            const crater1: Texture = director.assets.getTexture("menu_planet_crater1");
            const crater2: Texture = director.assets.getTexture("menu_planet_crater2");

            _disposeTextures.push(crater1);
            _disposeTextures.push(crater2);

            for (var i: uint = 0; i < 8; i++) {
                const container: Sprite = new Sprite();
                container.pivotX = container.pivotY = container.x = container.y = sceneHeight;
                container.rotation = Math.PI / 4 * i;

                const firstCrater: Image = new Image(crater2);
                firstCrater.scale = 120 / firstCrater.width;
                firstCrater.x = container.pivotX - sceneWidth / 4 - firstCrater.width / 2;
                firstCrater.y = 30;
                container.addChild(firstCrater);

                const secondCrater: Image = new Image(crater1);
                secondCrater.scale = 189 / secondCrater.width;
                secondCrater.x = container.pivotX + secondCrater.width / 3;
                secondCrater.y = 50;
                secondCrater.rotation = deg2rad(5);
                container.addChild(secondCrater);

                cratersContainer.addChild(container);
            }
            _planet = cratersContainer;

            const moonContainer: Sprite = new Sprite();
            moonContainer.pivotX = moonContainer.pivotY = sceneHeight;
            moonContainer.x = sceneWidth / 2;
            moonContainer.y = 1.5 * sceneHeight + 100;

            const index: Number = Algorithms.getRandomArrayEntries([6, 7, 13, 14, 19, 20]);
            trace("Generated menu moon index: " + index);

            const moon: RenderedPlanet = PlanetGenerator.generateWithConfiguration(PlanetGenerator.ROCK_PLANETS_CONFIGURATIONS[index],
                                                                                   1200,
                                                                                   30);
            moon.x = moonContainer.pivotX;
            moon.y = 0;
            moonContainer.addChild(moon);

            _animationJuggler.add(moon);

            const shadowTexture: RenderTexture = new RenderTexture(120, 120, false, Starling.contentScaleFactor);

            const drawShadow: Function = function (): void {
                const moonShadowCanvas: Canvas = new Canvas();
                moonShadowCanvas.beginFill(0x0, 0.3);
                moonShadowCanvas.drawCircle(60, 60, 30);
                moonShadowCanvas.filter = new GlowFilter(0, 1, 1.0);

                shadowTexture.draw(moonShadowCanvas);

                moonShadowCanvas.dispose();
            };
            drawShadow();

            shadowTexture.root.onRestore = function (): void {
                shadowTexture.clear();
                setTimeout(drawShadow, 0);
            };

            _disposeTextures.push(shadowTexture);

            const shadow: Image = new Image(shadowTexture);
            shadow.height /= 2;
            shadow.alignPivot();
            shadow.x = moonContainer.pivotX;
            shadow.y = 200;
            moonContainer.addChild(shadow);

            moonContainer.rotation -= Math.PI / 4;

            _moon = moonContainer;
            planetContainer.addChild(_moon);

            planetContainer.y = 200;
            const appear: Tween = new Tween(planetContainer, 4, Transitions.EASE_OUT);
            appear.moveTo(0, 0);

            Starling.juggler.add(appear);
        }

        /**
         * The event of touching the second planet, i.e. mute.
         *
         * @param touch
         */
        private function soundOffTapped(touch: Touch): void {
            trace("sound disabled");

            _soundWaves.visible = !_soundWaves.visible;
            director.soundEnabled = _soundWaves.visible;
        }

        private function newGameTapped(): void {
            director.hideBanner();

            trace("new game started");

            director.dispatchEventWith(Director.EVENT_GAME_STARTED);
        }

    }
}
