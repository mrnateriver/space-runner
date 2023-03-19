/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.objects {

    import starling.core.Starling;
    import starling.display.DisplayObjectContainer;
    import starling.events.Event;

    /**
     * The base class of some abstract game object.
     * Game object is any object added to the hierarchy of elements of the root scene.
     */
    public class GameObject extends DisplayObjectContainer {

        /**
         * An instance of the engine.
         */
        private var _engine: Starling;
        /**
         * Instance of the director of the gameplay.
         */
        private var _director: Director;

        /**
         * Constructor.
         */
        public function GameObject() {
            super();

            _engine = Starling.current;
            _director = _engine.root as Director;

            addEventListener(Event.ADDED_TO_STAGE, initSelf);
        }

        /**
         * Returns an instance of the gameplay director.
         */
        public function get director(): Director {
            return _director;
        }

        /**
         * Returns an instance of the engine.
         */
        public function get engine(): Starling {
            return _engine;
        }

        /**
         * Procedure for initializing an object. This method must be overridden by child classes.
         */
        protected function init(): void {
        }

        /**
         * Calls the object's initialization procedure. This method is required for a fixed initialization procedure
         * for child classes.
         *
         * @param event An instance of the add to object hierarchy event.
         */
        private function initSelf(event: Event): void {
            removeEventListener(Event.ADDED_TO_STAGE, initSelf);

            init();
        }
    }

}
