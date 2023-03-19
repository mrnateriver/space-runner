/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package {
    import flash.desktop.NativeApplication;
    import flash.desktop.SystemIdleMode;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.Screen;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.SharedObject;
    import flash.system.Capabilities;
    import flash.system.System;
    import flash.utils.ByteArray;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.utils.AssetManager;
    import starling.utils.StringUtil;
    import starling.utils.SystemUtil;

    import support.ScreenSetup;

    /**
     * Application entry point.
     * Sets system event handlers, adjusts the scene size according to the screen, loads the necessary
     * resources, etc.
     */
    public class Entry extends Sprite {

        /**
         * An instance of the engine.
         */
        protected static var _starling: Starling;
        protected static var _logo: Loader;

        /**
         * Hides the loading screen.
         */
        public static function hideLoadingScreen(): void {
            if (_logo) {
                _starling.nativeOverlay.removeChild(_logo);
                _logo = null;
            }
        }

        /**
         * Starts downloading resources.
         *
         * @param scale The scaling factor for the resources to be loaded.
         * @param onComplete The function to call when the download is complete.
         */
        protected function loadAssets(scale: int, onComplete: Function): void {
            trace("Loading assets with scale: " + scale + "x");

            const appDir: File = File.applicationDirectory;

            const assets: AssetManager = new AssetManager(scale);
            assets.forcePotTextures = true;

            assets.verbose = Capabilities.isDebugger;
            assets.enqueue(
                    // appDir.resolvePath("audio"),
                    // appDir.resolvePath(StringUtil.format("fonts/{0}x", scale)),
                    appDir.resolvePath("textures")
            );

            assets.loadQueue(function (ratio: Number): void {
                // TODO _progressBar.ratio = ratio;
                if (ratio == 1) {
                    System.pauseForGCIfCollectionImminent(0);
                    System.gc();

                    onComplete(assets);
                }
            });
        }

        /**
         * Starts the game, passing the specified instance of the resource manager to the director. It is understood that the resources
         * in this manager have already been loaded by the time this method is called.
         *
         * @param assets Resource manager with loaded assets.
         */
        protected function startGame(assets: AssetManager): void {
            var root: Director = _starling.root as Director;
            root.start(assets);

            // Immediately after launch, hide the loading screen
            hideLoadingScreen();
        }

        /**
         * Displays the loading screen.
         */
        protected static function showLoadingScreen(): void {
            if (SystemUtil.isDesktop) {
                return;
            }

            const overlay: Sprite = _starling.nativeOverlay;
            const stageWidth: Number = _starling.stage.stageWidth;
            const stageHeight: Number = _starling.stage.stageHeight;

            var bgPath: String;
            if (SystemUtil.isIOS) {
                // TODO: detect whether iPad or iPhone or whatever
                bgPath = "Default-414w-736h@3x~iphone.png";
            } else if (SystemUtil.isAndroid) {
                // TODO: different screens for iOS and Android
                bgPath = "splash.png";
            }
            const bgFile: File = File.applicationDirectory.resolvePath(bgPath);

            const bytes: ByteArray = new ByteArray();
            const stream: FileStream = new FileStream();

            stream.open(bgFile, FileMode.READ);
            stream.readBytes(bytes, 0, stream.bytesAvailable);
            stream.close();

            _logo = new Loader();
            _logo.loadBytes(bytes);
            overlay.addChild(_logo);

            _logo.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,
                                                     function (e: Object): void {
                                                         (_logo.content as Bitmap).smoothing = true;

                                                         _logo.scaleX = stageWidth / _logo.width;
                                                         _logo.scaleY = stageHeight / _logo.height;

                                                         _logo.x = (stageWidth - _logo.width) / 2;
                                                         _logo.y = (stageHeight - _logo.height) / 2;
                                                     });
        }

        /**
          * The constructor of the class and the entire application in fact.
          *
          * @param screen Content display settings according to screen parameters.
          */
        public function Entry(screen: ScreenSetup) {
            trace(StringUtil.format("Application startup, stage: {0}x{1} at ({2},{3}), screen: {4}x{5}, bounds: {6}x{7} at ({8},{9})",
                                    stage.stageWidth,
                                    stage.stageHeight,
                                    stage.x,
                                    stage.y,
                                    stage.fullScreenWidth,
                                    stage.fullScreenHeight,
                                    Screen.mainScreen.visibleBounds.width,
                                    Screen.mainScreen.visibleBounds.height,
                                    Screen.mainScreen.visibleBounds.x,
                                    Screen.mainScreen.visibleBounds.y));

            SharedObject.preventBackup = true;

            stage.color = 0x0;

            // Create an instance of the engine, pass the class of the director, as well as screen parameters
            _starling = new Starling(Director, stage, screen.viewPort);
            _starling.stage.stageWidth = screen.stageWidth; // scene size in points
            _starling.stage.stageHeight = screen.stageHeight;
            _starling.skipUnchangedFrames = true;
            _starling.antiAliasing = 2;
            _starling.supportHighResolutions = true;

            // _starling.showStats = true; // TODO: remove!
            // _starling.showStatsAt(Align.LEFT, Align.CENTER, 0.8);

            // As soon as the director class is created, we start loading resources
            _starling.addEventListener(starling.events.Event.ROOT_CREATED, function (e: *): void {
                loadAssets(screen.assetScale, startGame /* start the game when finished */);
            });

            _starling.start();

            // Once all asynchronous processes are running (director initialization and resource loading), show
            // loading screen
            showLoadingScreen();

            if (!SystemUtil.isDesktop) {
                NativeApplication.nativeApplication.addEventListener(flash.events.Event.ACTIVATE,
                                                                     function (e: *): void {
                                                                         NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;

                                                                         _starling.start();
                                                                     });
                NativeApplication.nativeApplication.addEventListener(flash.events.Event.DEACTIVATE,
                                                                     function (e: *): void {
                                                                         const director: Director = _starling.root as Director;
                                                                         director.pauseGameplay();

                                                                         _starling.stop(true);
                                                                     });
            }
        }

    }
}
