/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package {

    import flash.net.SharedObject;

    import particles.stars.CrossStarsBackground;
    import particles.stars.StarsBackground;

    import stages.GameOver;
    import stages.Gameplay;
    import stages.Menu;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.display.DisplayObjectContainer;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.ResizeEvent;
    import starling.utils.AssetManager;
    import starling.utils.StringUtil;

    import support.directing.IPlayerPlanetContainer;
    import support.directing.Scene;

    /**
     * Director of the entire game.
     * Processes events received from individual scenes, performs transitions between them and generally controls the entire
     * business logic.
     */
    public class Director extends Scene {

        [Embed(source="../assets/fonts/font.ttf", embedAsCFF="false", fontFamily="LATIN_FONT")]
        private static const LATIN_FONT: Class;
        [Embed(source="../assets/fonts/font4.ttf", embedAsCFF="false", fontFamily="CYRILLIC_FONT")]
        private static const CYRILLIC_FONT: Class;
        [Embed(source="../assets/fonts/font5.ttf", embedAsCFF="false", fontFamily="CHINESE_FONT")]
        private static const CHINESE_FONT: Class;

        public static const MAIN_BROWNISH_FONT_COLOR: uint = 0xe1c6ba;

        /**
         * Gameplay start event type.
         */
        public static const EVENT_GAME_STARTED: String = "game_started";
        public static const EVENT_GAME_RESTARTED: String = "game_restarted";
        /**
         * Game failure event type.
         */
        public static const EVENT_GAME_FAILED: String = "game_failed";
        /**
         * Event setting and unpausing the game.
         */
        public static const EVENT_GAME_PAUSE_STATE_CHANGED: String = "game_pause_changed";
        /**
         * Return to main menu event.
         */
        public static const EVENT_GAME_RETURN_TO_MENU: String = "return_to_menu";

        private static const DATA_SHARED_STORAGE_KEY: String = "sv_data_storage";

        /**
         * Game animation controller.
         */
        private var _gameJuggler: Juggler = new Juggler();

        /**
         * Resource manager.
         */
        private var _assetManager: AssetManager;
        /**
         * Current scene.
         */
        private var _activeScene: Scene;

        /**
         * Whether pause is enabled in the current scene. Needed to stop animation of background stars.
         */
        private var _paused: Boolean = false;

        private var _soundEnabled: Boolean = true;
        private var _showTutorial: Boolean = true;

        private var _localStorage: SharedObject;

        /**
         * Returns the resource manager.
         */
        public function get assets(): AssetManager {
            return _assetManager;
        }

        /**
         * Constructor.
         */
        public function Director() {
            super();

            _localStorage = SharedObject.getLocal(DATA_SHARED_STORAGE_KEY);
            _showStageSize = true;

            const savedEnabledSound: * = _localStorage.data.sound;
            if (savedEnabledSound !== null && typeof savedEnabledSound !== "undefined") {
                _soundEnabled = !!savedEnabledSound;
            }

            const showTutorial: * = _localStorage.data.tutorial;
            if (showTutorial !== null && typeof showTutorial !== "undefined") {
                _showTutorial = !!showTutorial;
            }
        }

        public function showInterstitial(callback: Function): void {
            // noop
        }

        public function showBanner(callback: Function): void {
            // noop
        }

        public function hideBanner(): void {
            // noop
        }

        /**
         * Stores the specified number of points in permanent storage.
         *
         * @paramscore
         */
        public function saveHighscore(score: Number): void {
            _localStorage.data.highscore = score;
            _localStorage.flush();
        }

        /**
         * Returns the previously scored maximum points from persistent storage.
         *
         * @return
         */
        public function getHighscore(): Number {
            return _localStorage.data.highscore;
        }

        public function get soundEnabled(): Boolean {
            return _soundEnabled;
        }

        public function set soundEnabled(value: Boolean): void {
            _soundEnabled = value;

            _localStorage.data.sound = value;
            _localStorage.flush();
        }

        public function get showTutorial(): Boolean {
            return _showTutorial;
        }

        public function set showTutorial(value: Boolean): void {
            _showTutorial = value;

            _localStorage.data.tutorial = value;
            _localStorage.flush();
        }

        /**
         * Returns whether the game is currently stopped.
         */
        public function get paused(): Boolean {
            return _paused;
        }

        /**
         * Specifies whether the game is currently paused.
         *
         * @param value
         */
        public function set paused(value: Boolean): void {
            _paused = value;
            dispatchEventWith(EVENT_GAME_PAUSE_STATE_CHANGED, false, { paused: value });
        }

        /**
         * Director initialization procedure. At the time of the call, the class instance is already attached to the root scene.
         */
        override final protected function initScene(): void {
            stage.addEventListener(Event.RESIZE, onResize);

            addEventListener(EVENT_GAME_STARTED, onStartGame);
            addEventListener(EVENT_GAME_RESTARTED, onRestartGame);
            addEventListener(EVENT_GAME_FAILED, onGameOver);
            addEventListener(EVENT_GAME_RETURN_TO_MENU, onReturnToMenu);

            const stars: StarsBackground = new StarsBackground();
            stars.start();

            const crossStars: CrossStarsBackground = new CrossStarsBackground();
            crossStars.start();

            _gameJuggler.add(stars);
            _gameJuggler.add(crossStars);

            addChild(stars);
            addChild(crossStars);

            addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrameHandler);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }

        /**
         * Handles the player's return to the main menu event.
         *
         * @param event
         */
        private function onReturnToMenu(event: Event): void {
            showScene(Menu);
        }

        /**
         * Jumps to the specified scene.
         *
         * @param scene Scene class.
         */
        private function showScene(scene: Class): void {
            if (_activeScene) {
                _activeScene.removeFromParent(true);
            }
            _activeScene = new scene() as Scene;

            if (_activeScene == null) {
                throw new ArgumentError("Invalid scene: " + scene);
            }

            addChild(_activeScene);
            _gameJuggler.add(_activeScene);
        }

        /**
         * Scene deletion event handler.
         *
         * @param event
         */
        private function onRemovedFromStage(event: Event): void {
            if (_gameJuggler) {
                _gameJuggler.purge();
            }
        }

        /**
         * Starts the game process.
         *
         * @param assets Resource manager with previously loaded resources.
         */
        public function start(assets: AssetManager): void {
            _assetManager = assets;

            showScene(Menu);
        }

        /**
         * Pauses gameplay and displays a pause screen if the current scene is gameplay.
         */
        public function pauseGameplay(): void {
            if (_activeScene && _activeScene is Gameplay) {
                (_activeScene as Gameplay).pauseGameplay();
            }
        }

        public function get isMainMenuActive(): Boolean {
            return _activeScene && _activeScene is Menu;
        }

        /**
         * Frame draw event handler. Used to animate the stars in the background.
         *
         * @param event
         */
        private function onEnterFrameHandler(event: EnterFrameEvent): void {
            if (_paused) {
                return;
            }

            _gameJuggler.advanceTime(event.passedTime);
        }

        /**
         * Handles the game fail event.
         *
         * @param event The event instance.
         */
        private function onGameOver(event: Event): void {
            const score: Number = event.data.score as Number;
            const highscore: Number = event.data.highscore as Number;

            const gameOverScene: GameOver = new GameOver(score, highscore);
            gameOverScene.alpha = 0;

            addChild(gameOverScene);

            const gameScene: Gameplay = _activeScene as Gameplay;
            if (!gameScene) {
                throw new Error("Game over event can only be issued from gameplay logic");
            }

            const appearanceTween: Tween = new Tween(gameOverScene, 0.6);
            appearanceTween.fadeTo(1.0);

            const transitionTween: Tween = new Tween(gameScene, 2, Transitions.EASE_IN_OUT_BACK);
            transitionTween.moveTo(0, stage.stageHeight * Gameplay.MAX_SCENE_DOWNSCALE + Gameplay.MAX_PLANET_RADIUS * 2
                                   /* in case the planet at the top of the scene has just been generated */);
            transitionTween.onComplete = function (): void {
                gameScene.removeFromParent(true);

                _gameJuggler.add(appearanceTween);
            };

            _gameJuggler.add(transitionTween);

            _activeScene = gameOverScene;
            _gameJuggler.add(_activeScene);
        }

        /**
         * Handles the resize event of the workspace (for example, an application window on a PC).
         *
         * @param event The event instance.
         */
        protected function onResize(event: ResizeEvent): void {
            var scale: Number = engine.contentScaleFactor;

            stage.stageWidth = event.width / scale;
            stage.stageHeight = event.height / scale;

            engine.viewPort.width = stage.stageWidth * scale;
            engine.viewPort.height = stage.stageHeight * scale;

            trace(StringUtil.format("Resize, stage: {0}x{1}, screen: {2}x{3}",
                                    stage.stageWidth,
                                    stage.stageHeight,
                                    engine.nativeStage.fullScreenWidth,
                                    engine.nativeStage.fullScreenHeight));
        }

        /**
         * Handles the game start event.
         *
         * @param event The event instance.
         */
        private function onStartGame(event: Event): void {
            showScene(Gameplay);

            const gameplayScene: Gameplay = _activeScene as Gameplay;
            gameplayScene.createPlayerPlanetSystem();
        }

        /**
         * Handles the game restart event after a failure.
         *
         * @param event The event instance.
         */
        private function onRestartGame(event: Event): void {
            const menuScene: IPlayerPlanetContainer = _activeScene as IPlayerPlanetContainer;
            if (!menuScene) {
                throw new TypeError("Scene that generated game start event does not provide player object accessor");
            }

            const playerSystem: DisplayObjectContainer = menuScene.playerPlanetSystem;
            playerSystem.removeFromParent();

            showScene(Gameplay);

            const gameplayScene: Gameplay = _activeScene as Gameplay;
            gameplayScene.injectPlayerPlanetSystem(playerSystem);
        }

    }
}
