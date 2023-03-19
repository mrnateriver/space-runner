/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support {

    import flash.geom.Rectangle;
    import flash.system.Capabilities;

    /**
     * Class for defining screen parameters and content scaling.
     */
    public class ScreenSetup {
        /**
         * Recommended scene width in points, calculated for the specified application window size.
         */
        private var _stageWidth: Number;
        /**
         * Recommended scene height in points, calculated for the specified application window size.
         */
        private var _stageHeight: Number;
        /**
         * Calculated scene size in pixels.
         */
        private var _viewPort: Rectangle;
        /**
         * Scaling factor for the screen with the specified parameters.
         */
        private var _scale: Number;
        /**
         * Graphic scaling factor.
         */
        private var _assetScale: Number;

        /**
         * Constructor.
         *
         * @param {uint} applicationWidth Application window width in pixels.
         * @param {uint} applicationHeight Application window height in pixels.
         * @param {uint[]} assetScales Array of possible graphic scale modifiers.
         * @param {Number} screenDPI Screen pixel density.
         */
        public function ScreenSetup(applicationWidth: uint, applicationHeight: uint,
                                    assetScales: Array = null, screenDPI: Number = -1) {

            if (screenDPI <= 0) {
                screenDPI = Capabilities.screenDPI;
            }
            if (assetScales == null || assetScales.length == 0) {
                assetScales = [1];
            }

            var iPad: Boolean = Capabilities.os.indexOf("iPad") != -1;
            var baseDPI: Number = iPad ? 130 : 160;
            var exactScale: Number = screenDPI / baseDPI;

            if (exactScale < 1.0) {
                _scale = 1.0;
            } else {
                _scale = Math.round(exactScale);
            }

            _stageWidth = int(applicationWidth / _scale);
            _stageHeight = int(applicationHeight / _scale);

            assetScales.sort(Array.NUMERIC | Array.DESCENDING);
            _assetScale = assetScales[0];

            for (var i: int = 0; i < assetScales.length; ++i) {
                if (assetScales[i] >= _scale) {
                    _assetScale = assetScales[i];
                }
            }

            _viewPort = new Rectangle(0, 0, _stageWidth * _scale, _stageHeight * _scale);
        }

        /**
         * Returns the recommended scene width in points.
         */
        public function get stageWidth(): Number {
            return _stageWidth;
        }

        /**
         * Returns the recommended scene height in points.
         */
        public function get stageHeight(): Number {
            return _stageHeight;
        }

        /**
         * Returns the recommended scene size in pixels.
         */
        public function get viewPort(): Rectangle {
            return _viewPort;
        }

        /**
         * Returns the screen scaling factor.
         */
        public function get scale(): Number {
            return _scale;
        }

        /**
         * Returns the graphic scaling factor.
         */
        public function get assetScale(): Number {
            return _assetScale;
        }
    }
}
