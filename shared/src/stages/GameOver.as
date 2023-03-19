/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package stages {
    import flash.geom.Point;
    import flash.utils.setTimeout;

    import objects.Player;
    import objects.RenderedPlanet;
    import objects.ui.Button;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.ColorArgb;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;
    import starling.utils.Align;
    import starling.utils.StringUtil;

    import support.PlanetGenerator;
    import support.Strings;
    import support.directing.IPlayerPlanetContainer;
    import support.directing.Scene;
    import support.drawing.TextureGenerator;

    public class GameOver extends Scene implements IPlayerPlanetContainer {
        private static var FAIL_COUNT: Number = 0;

        /**
         * The height of the player's orbit around the planet.
         */
        public static const PLAYER_ORBIT_HEIGHT: Number = 40;
        /**
         * The speed of the player around the planets in rad/s.
         */
        public static const PLAYER_ROTATION_SPEED: Number = 2 * Math.PI / 2.6; // whole circumference in 2.3 seconds

        public static const RESTART_BUTTON_PLANET_RADIUS: Number = 45;

        private var _animationJuggler: Juggler = new Juggler();

        private var _score: Number;
        private var _highscore: Number;

        private var _uiContainer: DisplayObjectContainer;

        private var _player: Player;
        private var _planet: RenderedPlanet;
        private var _playerPlanetSystem: DisplayObjectContainer;
        private var _gameRestartIcon: Image;
        private var _staticTexture: Texture;

        /**
         * The calculated height of the player.
         */
        private var _playerHeight: Number = 0;
        /**
         * The current center of the player's orbit.
         */
        private var _playerRotationCenter: Point;
        /**
         * The current radius of the player's orbit.
         */
        private var _playerRotationRadius: Number;
        /**
         * The current angle of rotation of the player in orbit relative to the vertical in a clockwise direction.
         */
        private var _playerRotationAngle: Number = 0;

        public function GameOver(score: Number, highscore: Number) {
            _score = score;
            _highscore = highscore;
        }

        public function get playerPlanetSystem(): DisplayObjectContainer {
            return _playerPlanetSystem;
        }

        override protected function initScene(): void {
            setupObjects();

            _planet.touchable = true;
            _planet.addEventListener(TouchEvent.TOUCH, function (event: TouchEvent): void {
                var touchLiftoff: Touch = event.getTouch(_planet, TouchPhase.ENDED);
                if (touchLiftoff && !touchLiftoff.cancelled) {
                    const touchLocation: Point = new Point(0, 0);
                    touchLiftoff.getLocation(_planet, touchLocation);

                    if (touchLocation.x > 0 && touchLocation.x < _planet.radius * 2 &&
                        touchLocation.y < _planet.radius * 2 && touchLocation.y > 0) {

                        onPlanetTouch(touchLiftoff);
                    }
                }
            });

            FAIL_COUNT++;
        }

        override public function dispose(): void {
            if (_gameRestartIcon) {
                _gameRestartIcon.texture.dispose();
            }
            _staticTexture.dispose();
            super.dispose();
        }

        protected function onPlanetTouch(touch: Touch): void {
            _planet.removeEventListeners(TouchEvent.TOUCH);
            animateTitleDisappearance();

            gameRestart();

            /*if (FAIL_COUNT > 2) {
                FAIL_COUNT = 0;
                director.showInterstitial(gameRestart);

            } else {
                gameRestart();
            }*/
        }

        protected function gameRestart(): void {
            trace("game restarted");
            animateTransitionToGameplay();
        }

        protected function getStaticTexture(): Texture {
            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            const rt: RenderTexture = new RenderTexture(sceneWidth, 30 + 120 + 20 + 50 + 20 + 120,
                                                        false,
                                                        Starling.contentScaleFactor);
            const draw: Function = function (): void {
                const container: Sprite = new Sprite();

                const title: TextField = new TextField(sceneWidth - 80, 120, strings.GAMEOVER_TITLE);
                title.format.setTo(font, 90, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.CENTER);
                title.autoScale = true;
                title.batchable = true;
                title.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
                title.alignPivot(Align.CENTER, Align.TOP);

                title.y = 30;
                title.x = sceneWidth / 2;
                container.addChild(title);

                var scoreTitle: String;
                if (_score > _highscore) {
                    scoreTitle = strings.GAMEOVER_NEW_HIGHSCORE_TITLE;
                } else {
                    scoreTitle = strings.GAMEOVER_OLD_HIGHSCORE_TITLE + " " + _highscore;
                }

                const highscoreText: TextField = new TextField(sceneWidth - 40, 50, scoreTitle);
                highscoreText.format.setTo(font, 50, 0xffffff, Align.LEFT, Align.TOP);
                highscoreText.batchable = true;
                highscoreText.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
                highscoreText.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
                highscoreText.alignPivot(Align.CENTER, Align.TOP);
                highscoreText.y = title.y + title.height + 20;
                highscoreText.x = sceneWidth / 2;
                container.addChild(highscoreText);

                const starTexture: Texture = TextureGenerator.createStarIcon(ColorArgb.fromArgb(0xffed9c2e), 70);

                const scoreIcon: Image = new Image(starTexture);
                scoreIcon.alignPivot();
                scoreIcon.filter = new DropShadowFilter();
                scoreIcon.y = title.y + title.height + 20 + highscoreText.height + 20 + 53;
                container.addChild(scoreIcon);

                const scoreText: TextField = new TextField(100, 90, _score.toString());
                scoreText.format.setTo(font, 90 * Strings.getFontSizeMultiplier(), 0xffffff, Align.LEFT, Align.TOP);
                scoreText.batchable = true;
                scoreText.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
                scoreText.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
                scoreText.y = title.y + title.height + 20 + highscoreText.height + 20;
                container.addChild(scoreText);

                scoreIcon.x = sceneWidth / 2 - (scoreText.width + scoreIcon.width - 40) / 2;
                scoreText.x = scoreIcon.x + 60;

                rt.draw(container);

                container.dispose();
                starTexture.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        protected function setupObjects(): void {
            _uiContainer = new Sprite();

            _staticTexture = getStaticTexture();

            const staticUi: Image = new Image(_staticTexture);
            _uiContainer.addChild(staticUi);

            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            const backToMenuLabel: TextField = new TextField(120, 60, strings.GAMEOVER_BACK_TO_MENU_BUTTON_LABEL);
            backToMenuLabel.format.setTo(font, 60, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            backToMenuLabel.batchable = true;
            backToMenuLabel.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            backToMenuLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            const backToMenuButton: Button = new Button(backToMenuLabel, Director.MAIN_BROWNISH_FONT_COLOR);
            backToMenuButton.addEventListener(Button.EVENT_CLICKED, function (): void {
                director.dispatchEventWith(Director.EVENT_GAME_RETURN_TO_MENU);
            });

            _uiContainer.addChild(backToMenuButton);
            backToMenuButton.alignPivot();
            backToMenuButton.x = sceneWidth / 2;
            backToMenuButton.y = sceneHeight - 70;

            _player = new Player();
            _planet = PlanetGenerator.generate(Gameplay.MIN_PLANET_MASS, RESTART_BUTTON_PLANET_RADIUS);
            _animationJuggler.add(_planet);
            _playerRotationCenter = new Point(0, 0);
            _playerRotationRadius = RESTART_BUTTON_PLANET_RADIUS;

            _playerPlanetSystem = new Sprite();

            _playerPlanetSystem.addChild(_player);
            _playerPlanetSystem.addChild(_planet);

            _playerHeight = _player.height;
            _playerPlanetSystem.alignPivot();
            _playerPlanetSystem.x = sceneWidth / 2;
            _playerPlanetSystem.y = staticUi.height + Math.abs(backToMenuButton.y - backToMenuButton.height / 2 - staticUi.height) / 2;

            addChild(_playerPlanetSystem);

            _gameRestartIcon = new Image(TextureGenerator.createReloadIcon(RESTART_BUTTON_PLANET_RADIUS * 0.9, 0xffffff));
            _gameRestartIcon.filter = new DropShadowFilter(0, 0.785, 0x0, 1, 2.0, 1);
            _gameRestartIcon.touchable = false;
            _gameRestartIcon.alignPivot();
            _gameRestartIcon.x = _playerPlanetSystem.x;
            _gameRestartIcon.y = _playerPlanetSystem.y;

            addChild(_gameRestartIcon);

            addChild(_uiContainer);
        }

        override public function advanceTime(time: Number): void {
            _playerRotationAngle += PLAYER_ROTATION_SPEED * time;
            updatePlayerPosition();

            _animationJuggler.advanceTime(time);
        }

        private function animateTitleDisappearance(): void {
            const containerTween: Tween = new Tween(_uiContainer, 0.6);
            containerTween.fadeTo(0);
            const fadeTween: Tween = new Tween(_gameRestartIcon, 0.3);
            fadeTween.fadeTo(0);

            _animationJuggler.add(containerTween);
            _animationJuggler.add(fadeTween);
        }

        /**
         * Updates the position of the player object according to the calculated deflection angle in the current orbit.
         */
        private function updatePlayerPosition(): void {
            const multiplier: Number = (_playerRotationRadius + PLAYER_ORBIT_HEIGHT + _playerHeight);

            _player.x = _playerRotationCenter.x + multiplier * Math.cos(_playerRotationAngle);
            _player.y = _playerRotationCenter.y + multiplier * Math.sin(_playerRotationAngle);

            _player.rotation = _playerRotationAngle + Math.PI / 2;
        }

        /**
         * Triggers the transition animation to the gameplay scene.
         */
        private function animateTransitionToGameplay(): void {
            const playerSumHeight: Number = _playerHeight * 2 + PLAYER_ORBIT_HEIGHT;
            const endPoint: Point = new Point(RESTART_BUTTON_PLANET_RADIUS + playerSumHeight + 120, sceneHeight - 2 * RESTART_BUTTON_PLANET_RADIUS - playerSumHeight - y - 140);

            trace(StringUtil.format("moving player system from [{0}, {1}] to [{2}, {3}]",
                                    _playerPlanetSystem.x,
                                    _playerPlanetSystem.y,
                                    endPoint.x,
                                    endPoint.y));

            const playerMovement: Tween = new Tween(_playerPlanetSystem, 2.5, Transitions.EASE_IN_OUT_BACK);
            playerMovement.moveTo(endPoint.x, endPoint.y);

            playerMovement.onComplete = function (): void {
                director.dispatchEventWith(Director.EVENT_GAME_RESTARTED);
            };

            _animationJuggler.add(playerMovement);
        }

    }

}
