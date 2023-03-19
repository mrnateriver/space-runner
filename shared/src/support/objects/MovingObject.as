/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.objects {
    import flash.geom.Point;

    import support.Algorithms;

    /**
     * The class of a game object moving in a specific direction at a given speed.
     */
    public class MovingObject extends MassiveObject {

        /**
         * Object speed in DP/sec, specified as a vector.
         */
        private var _velocity: Point;
        /**
         * Normalized object velocity vector.
         */
        private var _velocityDirection: Point;
        /**
         * A vector indicating the "front" of the object relative to the pivot point.
         */
        private var _faceDirection: Point;
        /**
         * Distance to the nearest massive object acting on this gravitationally.
         */
        private var _distanceToGravitator: Number = Number.MAX_VALUE;
        /**
         * The closest object acting on this gravitationally.
         */
        private var _closestGravitator: MassiveObject = null;

        /**
         * Constructor.
         *
         * @param mass The mass of the object in kilograms.
         * @param normalizedFaceDirection A normalized vector representing the "front" of the object relative to the point
         * rotation.
         */
        public function MovingObject(mass: Number, normalizedFaceDirection: Point = null) {
            super(mass);

            _velocity = new Point();
            _velocityDirection = new Point();

            _faceDirection = normalizedFaceDirection ? normalizedFaceDirection.clone() : new Point(1.0, 0);
            _faceDirection.normalize(1);
        }

        /**
         * Returns the object's velocity vector in DP/sec.
         */
        public function get velocity(): Point {
            return _velocity;
        }

        /**
         * Sets the object's velocity vector in DP/sec.
         *
         * @param velocity Velocity vector.
         */
        public function set velocity(velocity: Point): void {
            _velocity = velocity;

            updateVelocityDirection();
        }

        /**
         * Returns the normalized direction vector of the object's velocity.
         */
        public function get normalizedVelocity(): Point {
            return _velocityDirection;
        }

        /**
         * Returns the normalized "forward" direction vector of the object relative to the pivot point.
         */
        public function get faceDirection(): Point {
            return _faceDirection;
        }

        /**
         * Returns the angle in radians between the direction of the object's velocity and the "forward" of the object.
         */
        public function get velocityAngle(): Number {
            if (velocity.length > 0) {
                const angle: Number = Algorithms.getAngleBetweenVectors(_velocityDirection, _faceDirection);

                // if the velocity vector is directed upwards (the y-axis looks down), then the movement occurs in the left
                // semicircles - in this case, you need to subtract the result of the arc cosine from the full circle, because He
                // takes values from 0 to π
                if (_velocityDirection.y < 0) {
                    return 2 * Math.PI - angle;
                } else {
                    return angle;
                }

            } else {
                return rotation;
            }
        }

        /**
         * Adds the specified vector to the object's velocity vector.
         *
         * @param extra The vector to add.
         */
        public function addVelocity(extra: Point): void {
            _velocity.x += extra.x;
            _velocity.y += extra.y;

            updateVelocityDirection();
        }

        /**
         * Subtracts the specified vector from the object's velocity vector.
         *
         * @param sub Vector to subtract.
         */
        public function subtractVelocity(sub: Point): void {
            _velocity.x -= sub.x;
            _velocity.y -= sub.y;

            updateVelocityDirection();
        }

        /**
         * Accelerates the object by the specified value in the direction of its current movement.
         *
         * @param extraVelocity Velocity value to add.
         */
        public function accelerateForward(extraVelocity: Number): void {
            if (_velocityDirection.x == 0 && _velocityDirection.y == 0) {
                // if there is no direction of movement, then we use the "forward" pointer and the current rotation of the object
                const angle: Number = rotation;

                _velocityDirection.x = Math.cos(angle);
                _velocityDirection.y = Math.sin(angle);
            }

            _velocity.x += _velocityDirection.x * extraVelocity;
            _velocity.y += _velocityDirection.y * extraVelocity;

            updateVelocityDirection();
        }

        /**
         * Returns the distance to the nearest massive object acting on this gravitationally.
         */
        public function get distanceToClosestGravitator(): Number {
            return _distanceToGravitator;
        }

        /**
         * Sets the distance to the nearest massive object acting on this gravitationally.
         */
        public function set distanceToClosestGravitator(value: Number): void {
            _distanceToGravitator = value;
        }

        /**
         * Returns the nearest object acting on the given gravitationally.
         */
        public function get closestGravitator(): MassiveObject {
            return_closestGravitator;
        }

        /**
         * Specifies the nearest object acting on this gravitationally.
         */
        public function set closestGravitator(object: MassiveObject): void {
            _closestGravitator = object;
        }

        /**
         * Updates the normalized direction vector of the object's velocity.
         */
        protected function updateVelocityDirection(): void {
            _velocityDirection.x = _velocity.x;
            _velocityDirection.y = _velocity.y;
            _velocityDirection.normalize(1);
        }

    }

}
