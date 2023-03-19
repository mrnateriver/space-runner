/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.objects {
    import support.directing.GravitationScene;

    /**
     * The class of a game object that has mass and, as a result, is affected by gravity.
     */
    public class MassiveObject extends GameObject {

        /**
         * Event type when two massive objects collide.
         */
        public static const EVENT_COLLIDED: String = "massive_object_collided";

        /**
         * The mass of the object in kilograms.
         */
        private var _mass: Number;

        /**
         * Constructor.
         *
         * @param mass The mass of the object in kilograms.
         */
        public function MassiveObject(mass: Number) {
            super();

            _mass = mass;
        }

        /**
         * Returns the mass of the object in kilograms.
         */
        public function get mass(): Number {
            return _mass;
        }

        /**
         * Specifies the mass of the object in kilograms.
         *
         * @param value
         */
        public function set mass(value: Number): void {
            _mass = value;
        }

        /**
         * Returns the first escape velocity for the given object for an orbit with the given altitude.
         *
         * @param orbitHeight Height of required orbit.
         *
         * @return
         */
        public function getCircularOrbitVelocity(orbitHeight: Number): Number {
            return Math.sqrt(GravitationScene.G * mass / orbitHeight * GravitationScene.FORCE_MULTIPLIER);
        }

        /**
         * Returns the second escape velocity for the given object at the specified distance from it.
         *
         * @param distance The distance from the given object at which the second escape velocity should be calculated.
         *
         * @return
         */
        public function getEscapeVelocity(distance: Number): Number {
            return Math.sqrt(2 * GravitationScene.G * mass / distance * GravitationScene.FORCE_MULTIPLIER);
        }

    }

}
