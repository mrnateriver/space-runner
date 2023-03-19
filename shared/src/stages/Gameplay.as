/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package stages {
    import flash.geom.Point;
    import flash.utils.Dictionary;

    import objects.BasePlanet;
    import objects.Player;
    import objects.PlayerModeIcon;
    import objects.PlayerOutOfBoundsArrow;
    import objects.PlayerOutOfBoundsLabel;
    import objects.RenderedPlanet;
    import objects.TextBubble;
    import objects.ui.Button;

    import particles.ObjectTrail;

    import stages.screens.PauseScreen;
    import stages.screens.TutorialScreen;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.extensions.ColorArgb;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.Align;
    import starling.utils.StringUtil;

    import support.PlanetGenerator;
    import support.Strings;
    import support.directing.GravitationScene;
    import support.drawing.TextureGenerator;

    /**
     * Gameplay scene.
     * In this scene, the main game logic occurs.
     */
    public class Gameplay extends GravitationScene {

        /**
         * The base number of game points awarded for a set of the second space velocity relative to the planet.
         */
        protected static const PLANET_ESCAPE_BASE_POINTS: Number = 100;

        /**
         * The mass of the very first planet. Set in a separate order to synchronize the transition from the main menu.
         */
        protected static const INITIAL_PLANET_MASS: Number = 1200;
        /**
         * Minimum mass of generated planets.
         */
        public static const MIN_PLANET_MASS: Number = 1200;
        /**
         * Maximum mass of generated planets.
         */
        public static const MAX_PLANET_MASS: Number = 4000;
        /**
         * Minimum radius of generated planets.
         */
        public static const MIN_PLANET_RADIUS: Number = 30;
        /**
         * The maximum radius of the generated planets.
         */
        public static const MAX_PLANET_RADIUS: Number = 120;
        /**
         * Acceleration of the player during acceleration in DP/sec^2.
         */
        protected static const PLAYER_ACCELERATION_RATE: Number = 85.35;
        /**
         * The maximum time allowed for a player to be outside the stage before the game fails.
         */
        protected static const PLAYER_OUT_OF_BOUNDS_TIMEOUT: Number = 20;
        /**
         * Offset from the edges of the scene, at the intersection of which the scene begins to scale with the movement
         * player.
         */
        protected static const SCENE_RESIZE_MARGIN: Number = 30;
        /**
         * Maximum scene zoom factor when moving the player.
         */
        public static const MAX_SCENE_DOWNSCALE: Number = 2;

        /**
         * General gameplay animator.
         */
        private var _gameJuggler: Juggler = new Juggler();
        /**
         * Interface animator.
         */
        private var _uiJuggler: Juggler = new Juggler();
        /**
         * Planet animation controller.
         */
        private var _planetJuggler: Juggler = new Juggler();
        /**
         * Controller for drawing the tail behind the player.
         */
        private var _trailJuggler: Juggler = new Juggler();
        /**
         * Animation controller for highlighting the current planet.
         */
        private var _planetOutlinesJuggler: Juggler = new Juggler();

        /**
         * Current game points.
         */
        private var _score: uint = 0;

        /**
         * A table for recording the generation of events for exit from orbit, necessary to avoid repeated triggering
         * events.
         */
        private var _planetsExitEvents: Dictionary = new Dictionary();

        /**
         * Container with all game objects. Required for scaling when the player exits the screen.
         */
        private var _contentContainer: DisplayObjectContainer;
        private var _planetsContainer: DisplayObjectContainer;

        /**
         * Container with interface objects.
         */
        private var _uiContainer: DisplayObjectContainer;

        /**
         * Player object.
         */
        private var _player: Player;
        /**
         * The object of the arrow indicating the position of the player when he is outside the scene.
         */
        private var _playerOutOfBoundsArrow: PlayerOutOfBoundsArrow;
        /**
         * The current planet the player is in orbit around.
         */
        private var _playerCurrentOrbitingPlanet: BasePlanet = null;

        /**
         * Whether the player is currently accelerating.
         */
        private var _acceleratingPlayer: Boolean = false;
        /**
         * Whether the player is currently slowing down.
         */
        private var _deceleratingPlayer: Boolean = false;
        /**
         * Current speed difference given by the player's acceleration.
         */
        private var _playerSpeedDelta: Number = 0;

        /**
         * Base speed of planets moving around the scene in DP/sec.
         */
        private var _planetMovingBaseSpeed: Number = 18;

        /**
         * ID of the timer used to crash the game when the player is behind the scenes.
         */
        private var _boundsGameOverTimer: uint;
        /**
         * Identifier of the timer used to count the remaining time the player is outside the scene.
         */
        private var _boundsCountdownTimer: uint;

        /**
         * Element displaying the current account.
         */
        private var _scoreText: TextField;
        /**
         * Star icon next to the number of points.
         */
        private var _scoreStar: Image;

        /**
         * The required scale of the scene.
         */
        private var _sceneScaleTarget: Number = 1.0;
        /**
         * Last generated planet.
         */
        private var _latestPlanet: RenderedPlanet = null;

        /**
         * Message about leaving the screen.
         */
        private var _playerOutOfBoundsLabel: PlayerOutOfBoundsLabel;

        /**
         * The object of the next generated planet.
         */
        private var _nextPlanet: RenderedPlanet;
        /**
         * The text of the countdown timer to the next planet.
         */
        private var _planetGenerationCountdownLabel: TextField;

        /**
         * Text of the player's current speed.
         */
        private var _playerSpeedLabel: TextField;
        /**
         * Player status icon.
         */
        private var _playerStatusIcon: PlayerModeIcon;

        /**
         * A queue of pop-up messages about the receipt of points.
         */
        private var _pointsBubblesQueue: Vector.<Array> = new Vector.<Array>();
        /**
         * Is it possible to generate a pop-up message about the receipt of points at the moment.
         */
        private var _pointsBubbleAvailable: Boolean = true;

        private var _planetsGenerated: uint = 0;

        private var _objectTrail: ObjectTrail;

        /**
         * Scene initialization procedure.
         */
        override protected function initScene(): void {
            _gameJuggler.add(_trailJuggler);
            _gameJuggler.add(_planetOutlinesJuggler);
            _gameJuggler.add(_planetJuggler);

            _contentContainer = new Sprite();
            _contentContainer.x = sceneWidth / 2;
            _contentContainer.y = sceneHeight / 2;
            _contentContainer.pivotX = _contentContainer.x;
            _contentContainer.pivotY = _contentContainer.y;

            _planetsContainer = new Sprite();
            _planetsContainer.x = sceneWidth / 2;
            _planetsContainer.y = sceneHeight / 2;
            _planetsContainer.pivotX = _planetsContainer.x;
            _planetsContainer.pivotY = _planetsContainer.y;

            addChild(_planetsContainer);
            addChild(_contentContainer);

            _uiContainer = new Sprite();
            addChild(_uiContainer);

            stage.addEventListener(TouchEvent.TOUCH, onTouch);

            trace("Highscore: " + director.getHighscore());
        }

        /**
         * @inheritDoc
         */
        override public function advanceTime(time: Number): void {

            const delta: Number = PLAYER_ACCELERATION_RATE * time;

            if (_acceleratingPlayer) {
                _player.accelerateForward(delta);
                _playerSpeedDelta += delta;

            } else if (_deceleratingPlayer) {
                _player.accelerateForward(-delta);
                _playerSpeedDelta -= delta;

                if (_playerSpeedDelta <= 0) {
                    _deceleratingPlayer = false;
                    _playerSpeedDelta = 0;

                    _player.mode = Player.MODE_NORMAL;

                    trace("stopped decelerating player");
                }
            }

            checkCurrentPlayerOrbit();

            // accelerate the movement of the planets
            _planetMovingBaseSpeed += 0.001;

            resizeContentWithPlayer();

            const scaleSpeed: Number = Number.round(0.5 * time * 10000) / 10000;
            const currentScale: Number = _contentContainer.scale;

            if (_sceneScaleTarget != currentScale) {
                const increase: Boolean = _sceneScaleTarget > currentScale;
                const newScale: Number = currentScale + (increase ? scaleSpeed : -scaleSpeed);

                if ((increase && newScale > _sceneScaleTarget) || (!increase && newScale < _sceneScaleTarget)) {
                    _contentContainer.scale = _planetsContainer.scale = _sceneScaleTarget;
                } else {
                    _contentContainer.scale = _planetsContainer.scale = newScale;
                }
            }

            if (_pointsBubblesQueue.length > 0 && _pointsBubbleAvailable) {
                const entry: Array = _pointsBubblesQueue.shift();
                showPointsBubble.apply(this, entry);
            }

            super.advanceTime(time);

            _uiJuggler.advanceTime(time);
            _gameJuggler.advanceTime(time);
        }

        /**
         * @inheritDoc
         */
        override public function dispose(): void {
            _uiJuggler.purge();

            if (_scoreStar) {
                _scoreStar.texture.dispose();
            }
            super.dispose();
        }

        public function createPlayerPlanetSystem(): void {
            _latestPlanet = PlanetGenerator.generate(INITIAL_PLANET_MASS, GameOver.RESTART_BUTTON_PLANET_RADIUS);
            _player = new Player();

            const playerSumHeight: Number = _player.height * 2 + GameOver.PLAYER_ORBIT_HEIGHT;

            _latestPlanet.x = GameOver.RESTART_BUTTON_PLANET_RADIUS + playerSumHeight + 120;
            _latestPlanet.y = sceneHeight - 2 * GameOver.RESTART_BUTTON_PLANET_RADIUS - playerSumHeight - y - 140;

            const multiplier: Number = (GameOver.RESTART_BUTTON_PLANET_RADIUS + GameOver.PLAYER_ORBIT_HEIGHT + _player.height);
            const angle: Number = Math.random() * Math.PI;

            _player.x = _latestPlanet.x + multiplier * Math.cos(angle);
            _player.y = _latestPlanet.y + multiplier * Math.sin(angle);

            _player.rotation = angle + Math.PI / 2;

            initGame();

            // _latestPlanet.shadow = true;
        }

        /**
         * Adds the player along with the starting planet to the stage. This method is necessary for the implementation of a smooth
         * transition from the main menu.
         *
         * @param container Container containing player and first planet objects.
         */
        public function injectPlayerPlanetSystem(container: DisplayObjectContainer): void {
            trace("injecting player system into gameplay scene");

            var lastMassiveObject: RenderedPlanet;

            const childrenCount: int = container.numChildren;
            for (var i: int = 0; i < childrenCount; i++) {
                var child: DisplayObject = container.getChildAt(i);
                if (child is Player) {
                    _player = child as Player;
                } else if (child is BasePlanet) {
                    lastMassiveObject = child as RenderedPlanet;
                }

                child.x += container.x - container.pivotX;
                child.y += container.y - container.pivotY;
            }

            if (_player && lastMassiveObject) {
                trace("Player injected: " + _player.x + ", " + _player.y);

                _latestPlanet = lastMassiveObject;

                initGame(true);
            }

            container.removeFromParent(true);
        }

        protected function initGame(skipTutorial: Boolean = false): void {
            if (director.showTutorial && !skipTutorial) {
                showTutorialScreen();
                director.showTutorial = false;
                return;
            }

            _latestPlanet.mass = INITIAL_PLANET_MASS;

            // player's trail
            _objectTrail = new ObjectTrail(_player);

            _trailJuggler.add(_objectTrail);

            _contentContainer.addChild(_objectTrail);
            _contentContainer.addChild(_player);

            _planetsContainer.addChild(_latestPlanet);

            _attractionTrackingObject = _player;

            _planetOutlinesJuggler.add(_latestPlanet);

            enableGravityForObject(_player);
            enableGravityForObject(_latestPlanet);

            setupInitialPlayerParameters(_latestPlanet);

            animatePlanet(_latestPlanet);

            // Turn on planet generation with a delay to eliminate the situation when the player crashes
            // to the initial planet on the first orbit
            _gameJuggler.delayCall(function (): void {
                startGenerationCycle(false);
            }, 3);

            _nextPlanet = createPlanet();
            _uiContainer.addChild(_nextPlanet);

            const tween: Tween = new Tween(_nextPlanet, 0.4, Transitions.EASE_OUT_BOUNCE);
            tween.animate("width", 50);
            tween.animate("height", 50);
            _gameJuggler.add(tween);

            _nextPlanet.y = sceneHeight - 25;
            _nextPlanet.x = 25;

            var timer: Number = 3;
            _gameJuggler.repeatCall(function (): void {
                _planetGenerationCountdownLabel.text = (--timer).toString();
            }, 1, 2);

            // Starting scoring
            _gameJuggler.repeatCall(addPoints, 3);

            setupUI();
        }

        /**
         * Creates and adds to the stage all the necessary user interface elements.
         */
        protected function setupUI(): void {
            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            _scoreText = new TextField(sceneWidth / 2, 50, "0");
            _scoreText.format.setTo(font, 50 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.RIGHT, Align.TOP);
            _scoreText.batchable = true;
            _scoreText.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            _scoreText.x = sceneWidth / 2 - 8;
            _scoreText.y = 8;

            _uiContainer.addChild(_scoreText);

            const starTexture: Texture = TextureGenerator.createStarIcon(ColorArgb.fromArgb(0xffed9c2e), 25);
            _scoreStar = new Image(starTexture);
            _scoreStar.alignPivot();
            _scoreStar.filter = new DropShadowFilter();

            _scoreStar.x = sceneWidth - _scoreText.textBounds.width - _scoreStar.width;
            _scoreStar.y = 8 + 30;

            _uiContainer.addChild(_scoreStar);

            _playerOutOfBoundsLabel = new PlayerOutOfBoundsLabel(PLAYER_OUT_OF_BOUNDS_TIMEOUT, sceneWidth - 40 /* 20dp paddings from both sides */);
            _playerOutOfBoundsLabel.x = sceneWidth / 2;
            _playerOutOfBoundsLabel.y = sceneHeight / 2;

            _uiContainer.addChild(_playerOutOfBoundsLabel);
            _gameJuggler.add(_playerOutOfBoundsLabel);

            _planetGenerationCountdownLabel = new TextField(sceneWidth / 2 - 50, 40, "3");
            _planetGenerationCountdownLabel.format.setTo(font,
                                                         40 * Strings.getFontSizeMultiplier(),
                                                         Director.MAIN_BROWNISH_FONT_COLOR,
                                                         Align.LEFT,
                                                         Align.CENTER);
            _planetGenerationCountdownLabel.autoScale = true;
            _planetGenerationCountdownLabel.batchable = true;
            _planetGenerationCountdownLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            _planetGenerationCountdownLabel.x = 50;
            _planetGenerationCountdownLabel.y = sceneHeight - 45;

            _uiContainer.addChild(_planetGenerationCountdownLabel);

            const speedLabelTitle: TextField = new TextField(50, 30, strings.GAMEPLAY_SPEED_LABEL);
            speedLabelTitle.format.setTo(font, 30 * Strings.getFontSizeMultiplier(), 0xffffff, Align.LEFT, Align.CENTER);
            speedLabelTitle.autoScale = true;
            speedLabelTitle.batchable = true;
            speedLabelTitle.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            speedLabelTitle.x = sceneWidth - (Strings.getLanguage() === 'en' ? 115 : 130);
            speedLabelTitle.y = sceneHeight - 39;

            _uiContainer.addChild(speedLabelTitle);

            _playerSpeedLabel = new TextField(50, 40, "");
            _playerSpeedLabel.format.setTo(font,
                                           40 * Strings.getFontSizeMultiplier(),
                                           Director.MAIN_BROWNISH_FONT_COLOR,
                                           Align.RIGHT,
                                           Align.CENTER);
            _playerSpeedLabel.autoScale = true;
            _playerSpeedLabel.batchable = true;
            _playerSpeedLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            _playerSpeedLabel.x = sceneWidth - 82;
            _playerSpeedLabel.y = sceneHeight - 45;

            _uiContainer.addChild(_playerSpeedLabel);

            const menuButtonIcon: Image = new Image(TextureGenerator.createPauseIcon(15,
                                                                                     15,
                                                                                     Director.MAIN_BROWNISH_FONT_COLOR));
            menuButtonIcon.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            menuButtonIcon.y = 12;

            const menuButtonLabel: TextField = new TextField(50, 40, strings.GAMEPLAY_MENU_BUTTON_LABEL);
            menuButtonLabel.format.setTo(font, 30 * Strings.getFontSizeMultiplier(), Director.MAIN_BROWNISH_FONT_COLOR, Align.LEFT, Align.CENTER);
            menuButtonLabel.autoScale = true;
            menuButtonLabel.batchable = true;
            menuButtonLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            menuButtonLabel.x = 25;

            const menuButton: Sprite = new Sprite();
            menuButton.addChild(menuButtonIcon);
            menuButton.addChild(menuButtonLabel);

            const menuButtonContainer: Button = new Button(menuButton, Director.MAIN_BROWNISH_FONT_COLOR);
            menuButtonContainer.x = 10;
            menuButtonContainer.y = 5;

            _uiContainer.addChild(menuButtonContainer);

            menuButtonContainer.addEventListener(Button.EVENT_CLICKED, function (): void {
                tapPause();
            });

            // Player's state
            _playerStatusIcon = new PlayerModeIcon(15, _player);
            _playerStatusIcon.x = sceneWidth - 17;
            _playerStatusIcon.y = sceneHeight - 25;
            _uiContainer.addChild(_playerStatusIcon);

            _gameJuggler.repeatCall(function (): void {
                _playerSpeedLabel.text = Number.round(_player.velocity.length).toString();
            }, 0.5);
            _playerSpeedLabel.text = Number.round(_player.velocity.length).toString();
        }

        /**
         * Starts the animation of the movement of the planet from its current position to the very bottom of the scene until it disappears from view.
         *
         * @param planet Planet object.
         *
         * @return
         */
        protected function animatePlanet(planet: BasePlanet): Tween {
            const animationDistance: Number = (sceneHeight * MAX_SCENE_DOWNSCALE - planet.y + planet.radius);

            // let's not slow down the planet to less than 70%
            var animationTime: Number = animationDistance / _planetMovingBaseSpeed;

            const animationTween: Tween = new Tween(planet, animationTime);
            animationTween.moveTo(planet.x, sceneHeight * MAX_SCENE_DOWNSCALE + planet.radius * 2);
            animationTween.onComplete = function (): void {
                disableGravityForObject(planet);
                planet.removeFromParent(true);
            };

            _planetJuggler.add(animationTween);

            return animationTween;
        }

        /**
         * Generates a planet instance.
         */
        protected function createPlanet(): RenderedPlanet {
            const radiusCoefficient: Number = Math.random();
            const radius: Number = MIN_PLANET_RADIUS + radiusCoefficient * (_planetsGenerated > 1
                                                                            ? (MAX_PLANET_RADIUS - MIN_PLANET_RADIUS)
                                                                            : (0.6 * MIN_PLANET_RADIUS));

            const massCoefficient: Number = radius / MAX_PLANET_RADIUS;
            const mass: Number = Number.max(massCoefficient * MAX_PLANET_MASS, MIN_PLANET_MASS);

            return PlanetGenerator.generate(mass, radius);
        }

        /**
         * Generates a random planet and adds it to the scene.
         */
        protected function generatePlanet(accountScale: Boolean = true): Tween {
            const planet: RenderedPlanet = _nextPlanet ? _nextPlanet : createPlanet();

            planet.scale = 1;
            planet.x = planet.radius + 20 + Math.random() * (sceneWidth - 40 - planet.radius * 2);
            planet.y = -planet.radius - (accountScale ? (sceneHeight * MAX_SCENE_DOWNSCALE - sceneHeight) / 2 : 0);

            _planetsContainer.addChild(planet);
            enableGravityForObject(planet);

            _planetOutlinesJuggler.add(planet);
            _latestPlanet = planet;

            // planet.shadow = true;

            _planetsGenerated++;

            return animatePlanet(planet);
        }

        protected function showTutorialScreen(): void {
            director.paused = true;

            const screen: TutorialScreen = new TutorialScreen();
            screen.addEventListener(TutorialScreen.EVENT_CONTINUE_CLICKED, function (): void {
                screen.removeFromParent(true);
                director.paused = false;

                initGame(true);
            });

            addChild(screen);
        }

        /**
         * Pauses gameplay and displays the pause screen.
         */
        public function pauseGameplay(): void {
            if (!director.paused) {
                director.paused = true;

                const screen: PauseScreen = new PauseScreen(_score);
                screen.addEventListener(PauseScreen.EVENT_CONTINUE_CLICKED, function (): void {
                    screen.removeFromParent(true);
                    director.paused = false;
                });
                screen.addEventListener(PauseScreen.EVENT_MAIN_MENU_CLICKED, function (): void {
                    director.paused = false;
                    director.dispatchEventWith(Director.EVENT_GAME_RETURN_TO_MENU);
                });

                addChild(screen);

                // Save highscore just in case
                const highscore: Number = director.getHighscore();
                if (isNaN(highscore) || _score > highscore) {
                    director.saveHighscore(_score);
                }
            }
        }

        /**
         * Handles the pause button click.
         */
        protected function tapPause(): void {
            pauseGameplay();
        }

        /**
         * Checks the current state of the player for de-orbiting planets.
         */
        protected function checkCurrentPlayerOrbit(): void {
            if (_player.closestGravitator is BasePlanet) {
                const planet: BasePlanet = _player.closestGravitator as BasePlanet;

                if (!_planetsExitEvents[planet]) {
                    if (planet !== _playerCurrentOrbitingPlanet) {
                        if (_playerCurrentOrbitingPlanet) {
                            _planetsExitEvents[_playerCurrentOrbitingPlanet] = true;
                        }
                        _playerCurrentOrbitingPlanet = planet;

                    } else {
                        const velocityMagnitude: Number = _player.velocity.length;
                        const planetEscapeVelocity: Number = planet.getEscapeVelocity(_player.distanceToClosestGravitator);

                        if (velocityMagnitude > planetEscapeVelocity) {
                            playerLeftOrbit(planet, velocityMagnitude, planetEscapeVelocity);

                            _planetsExitEvents[planet] = true;
                            _playerCurrentOrbitingPlanet = null;
                        }
                    }
                }
            }
        }

        /**
         * The procedure for handling the departure of the player from the orbit of the planet.
         *
         * @param planet
         * @param playerVelocity
         * @param escapeVelocity
         */
        protected function playerLeftOrbit(planet: BasePlanet,
                                           playerVelocity: Number,
                                           escapeVelocity: Number): void {

            trace("player left orbit, planet index: " + _planets.indexOf(planet));

            // to the base number of points we add the percent of the maximum possible mass of the planet, as well as a tenth of
            // differences with the second space velocity
            const points: Number = PLANET_ESCAPE_BASE_POINTS + Number.floor(planet.mass / MAX_PLANET_MASS * 100) + Number.floor((playerVelocity - escapeVelocity) / 10);
            addPoints(points);

            trace("Adding points for escape velocity: " + points.toString());
            _pointsBubblesQueue.push([points, planet]);
        }

        /**
         * Sets the initial starting parameters of the player and assigns event handlers associated with the object itself
         * player.
         *
         * @param planet Starting planet.
         */
        protected function setupInitialPlayerParameters(planet: BasePlanet): void {
            const pointA: Point = new Point(_player.x, _player.y);
            const pointB: Point = new Point(planet.x, planet.y);

            _player.accelerateForward(planet.getCircularOrbitVelocity(pointB.subtract(pointA).length));
            _playerCurrentOrbitingPlanet = planet;

            _player.addEventListener(Player.EVENT_PLAYER_COLLIDED, onPlayerCollided);

            _playerOutOfBoundsArrow = new PlayerOutOfBoundsArrow(_player, MAX_SCENE_DOWNSCALE);
            _uiContainer.addChild(_playerOutOfBoundsArrow);

            _gameJuggler.add(_playerOutOfBoundsArrow);

            _playerOutOfBoundsArrow.addEventListener(PlayerOutOfBoundsArrow.PLAYER_LEFT_SCENE, playerLeftSceneBounds);
            _playerOutOfBoundsArrow.addEventListener(PlayerOutOfBoundsArrow.PLAYER_ENTERED_SCENE,
                                                     playerEnteredSceneBounds);
        }

        /**
         * Adds the specified number of points to the player.
         *
         * @param points
         */
        protected function addPoints(points: uint = 0): void {
            if (points) {
                _score += points;

            } else {
                // if the exact number is not specified, then we consider that this is a periodic accrual
                // it depends on the current difficulty level
                const timePoints: Number = Number.floor(_planetMovingBaseSpeed);

                _score += timePoints;

                if (_player.closestGravitator is BasePlanet) {
                    trace("Adding points for time: " + timePoints.toString());
                    _pointsBubblesQueue.push([timePoints, _player.closestGravitator as BasePlanet]);
                }
            }

            _scoreText.text = _score.toString();
            _scoreStar.x = sceneWidth - _scoreText.textBounds.width - _scoreStar.texture.width;
        }

        /**
         * Starts the planet generation cycle.
         */
        protected function startGenerationCycle(accountScale: Boolean = true): void {
            const startingTween: Tween = generatePlanet(accountScale);

            _nextPlanet = createPlanet();
            _uiContainer.addChild(_nextPlanet);

            const tween: Tween = new Tween(_nextPlanet, 0.4, Transitions.EASE_OUT_BOUNCE);
            tween.animate("width", 50);
            tween.animate("height", 50);
            _gameJuggler.add(tween);

            _nextPlanet.y = sceneHeight - 25;
            _nextPlanet.x = 25;

            trace("next planet width: " + _nextPlanet.width + " scale: " + _nextPlanet.scale + " radius: " + _nextPlanet.radius);

            // planets are generated when the last planet has reached a third of the screen
            const nextTime: Number = Number.ceil(startingTween.totalTime / 3);
            trace("planet generated, next in " + nextTime);

            var timer: Number = nextTime;

            _planetGenerationCountdownLabel.text = timer.toString();
            _gameJuggler.repeatCall(function (): void {
                _planetGenerationCountdownLabel.text = (--timer).toString();
            }, 1, nextTime - 1);

            _gameJuggler.delayCall(startGenerationCycle, nextTime);
        }

        /**
         * Returns how far the specified object has moved out of the scene.
         *
         * @param x
         * @param y
         *
         * @return
         */
        protected function getObjectPositionDelta(x: Number, y: Number): Array {
            const width: Number = sceneWidth - SCENE_RESIZE_MARGIN;
            const height: Number = sceneHeight - SCENE_RESIZE_MARGIN;

            var horizontal: Number = 0;
            if (x < SCENE_RESIZE_MARGIN) {
                horizontal = SCENE_RESIZE_MARGIN - x;
            } else if (x > width) {
                horizontal = x - width;
            }

            var vertical: Number = 0;
            if (y < SCENE_RESIZE_MARGIN) {
                vertical = SCENE_RESIZE_MARGIN - y;
            } else if (y > height) {
                vertical = y - height;
            }

            return [horizontal, vertical];
        }

        /**
         * Changes the scale of the scene depending on the current position of the player.
         */
        protected function resizeContentWithPlayer(): void {
            const playerDelta: Array = getObjectPositionDelta(_player.x, _player.y);

            var horizontal: Number = playerDelta[0];
            var vertical: Number = playerDelta[1];

            const playerCoefficient: Number = Number.round(
                    Number.min(
                            sceneHeight / (vertical * 2 + sceneHeight),
                            sceneWidth / (horizontal * 2 + sceneWidth)
                    ) * 10000) / 10000;

            if (_latestPlanet) {
                const planetDelta: Array = getObjectPositionDelta(_latestPlanet.x, _latestPlanet.y - _latestPlanet.radius);

                var planetHorizontal: Number = planetDelta[0];
                var planetVertical: Number = planetDelta[1];

                const planetCoefficient: Number = Number.round(
                        Number.min(
                                sceneHeight / (planetVertical * 2 + sceneHeight),
                                sceneWidth / (planetHorizontal * 2 + sceneWidth)
                        ) * 10000) / 10000;

                if (planetCoefficient > 1 / MAX_SCENE_DOWNSCALE && planetCoefficient < playerCoefficient) {
                    _sceneScaleTarget = planetCoefficient;
                    return;
                }
            }

            if (playerCoefficient > 1 / MAX_SCENE_DOWNSCALE) {
                _sceneScaleTarget = playerCoefficient;
            }
        }

        /**
         * Displays a pop-up message about scoring for the specified planet.
         *
         * @param points
         * @param planet
         */
        protected function showPointsBubble(points: Number, planet: BasePlanet): void {
            const bubble: TextBubble = new TextBubble(points.toString(), planet.radius * 2);
            bubble.x = planet.x + 5;
            bubble.y = planet.y;

            _planetsContainer.addChild(bubble);
            _uiJuggler.add(bubble);

            bubble.show();

            _pointsBubbleAvailable = false;
            bubble.addEventListener(TextBubble.EVENT_ANIMATION_COMPLETED, function (): void {
                _pointsBubbleAvailable = true;
            });
        }

        /**
         * Game end event handler.
         *
         * @param bounds
         */
        protected function gameOver(bounds: Boolean = false): void {
            trace("game over, bounds: " + bounds);

            const loose: Function = function (): void {
                const highscore: Number = director.getHighscore();
                if (isNaN(highscore) || _score > highscore) {
                    trace("New highscore: " + _score);
                    director.saveHighscore(_score);
                }

                _playerOutOfBoundsLabel.hide();

                _gameJuggler.purge();

                disableGravityForAllObjects();

                _player.removeFromParent(true);
                _playerOutOfBoundsArrow.removeFromParent(true);

                _uiContainer.removeFromParent(true);

                const contentScaleTween: Tween = new Tween(_contentContainer, 0.5);
                contentScaleTween.scaleTo(1.0);
                const planetsScaleTween: Tween = new Tween(_planetsContainer, 0.5);
                planetsScaleTween.scaleTo(1.0);

                _gameJuggler.add(contentScaleTween);
                _gameJuggler.add(planetsScaleTween);

                director.dispatchEventWith(Director.EVENT_GAME_FAILED,
                                           true,
                                           { score: _score, highscore: isNaN(highscore) ? -1 : highscore });
            };


            if (!bounds) {
                _planetJuggler.purge();
                _trailJuggler.purge();

                const trailDisappear: Tween = new Tween(_objectTrail, 0.2);
                trailDisappear.fadeTo(0);
                _gameJuggler.add(trailDisappear);

                _player.crash();

                _gameJuggler.delayCall(loose, 0.4);

            } else {
                loose();
            }
        }

        /**
         * The event handler of the player's collision with the object and, accordingly, the failure of the game.
         *
         * @param event
         */
        protected function onPlayerCollided(event: Event): void {
            trace("player collided");

            gameOver(false);
        }

        /**
         * The event handler for the player leaving the scene.
         *
         * @param event
         */
        private function playerLeftSceneBounds(event: Event): void {
            trace("player left scene bounds, starting countdown");

            _boundsGameOverTimer = _gameJuggler.delayCall(gameOver, PLAYER_OUT_OF_BOUNDS_TIMEOUT, true);

            _playerOutOfBoundsLabel.time = PLAYER_OUT_OF_BOUNDS_TIMEOUT;
            _playerOutOfBoundsLabel.show();

            var timer: Number = PLAYER_OUT_OF_BOUNDS_TIMEOUT;
            _boundsCountdownTimer = _gameJuggler.repeatCall(function (): void {
                _playerOutOfBoundsLabel.time = --timer;
            }, 1, PLAYER_OUT_OF_BOUNDS_TIMEOUT);
        }

        /**
         * The event for the player to return to the scene.
         *
         * @param event
         */
        private function playerEnteredSceneBounds(event: Event): void {
            trace("player returned within scene bounds, stoping countdown");

            _gameJuggler.removeByID(_boundsGameOverTimer);
            _gameJuggler.removeByID(_boundsCountdownTimer);

            _boundsGameOverTimer = 0;
            _boundsCountdownTimer = 0;

            _playerOutOfBoundsLabel.hide();
        }

        /**
         * Scene touch event handler. Starts accelerating player.
         *
         * @param event
         */
        protected function onTouch(event: TouchEvent): void {
            if (director.paused) {
                return;
            }

            const touch: Touch = event.getTouch(stage);
            if (touch) {
                if (touch.phase === TouchPhase.BEGAN) {
                    _acceleratingPlayer = true;
                    _deceleratingPlayer = false;

                    _player.mode = Player.MODE_ACCELERATING;
                    _playerSpeedDelta = 0;

                    trace("accelerating player");

                } else if (touch.phase === TouchPhase.ENDED) {
                    _acceleratingPlayer = false;
                    _deceleratingPlayer = true;

                    _player.mode = Player.MODE_DECELERATING;

                    trace(StringUtil.format("decelerating player, current: {0}", _player.velocity.length));
                }
            }
        }

    }

}
