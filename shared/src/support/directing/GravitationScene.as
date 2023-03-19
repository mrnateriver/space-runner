/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.directing {
    import flash.geom.Point;
    import flash.utils.Dictionary;

    import objects.BasePlanet;

    import starling.core.Starling;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.events.Event;
    import starling.geom.Polygon;
    import starling.textures.RenderTexture;
    import starling.utils.Pool;

    import support.objects.MassiveObject;
    import support.objects.MovingObject;

    /**
     * The base class of the scene in which the gravitational interaction is simulated.
     */
    public class GravitationScene extends Scene {

        /**
         * Gravitational constant in DP^3 * kg^-1 * s^-2.
         */
        public static const G: Number = 5000;

        /**
         * The number of iterations when calculating gravitational interactions per frame.
         */
        protected static const SIMULATION_STEPS: int = 3;

        /**
         * Maximum difference in seconds between frames for which gravity simulation can be calculated.
         */
        protected static const SIMULATION_MAX_DELTA: Number = 0.5;

        /**
         * Distance limit in DP between objects at which objects are considered to have collided.
         */
        protected static const DISTANCE_COLLISION_THRESHOLD: Number = 1;

        /**
         * Time scaling factor when calculating gravitational interactions per frame.
         */
        public static const TIME_MULTIPLIER: Number = 0.75;
        /**
         * Coefficient of gravity when calculating gravitational interactions in one frame.
         */
        public static const FORCE_MULTIPLIER: Number = 1;

        /**
         * Debug mode.
         */
        protected static const DEBUG: Boolean = false;

        /**
         * An array of planets in the scene. Planet - an abstract object that attracts all other objects except others
         * planets.
         */
        protected var _planets: Vector.<BasePlanet> = new Vector.<BasePlanet>();
        /**
         * An array of objects affected by gravity.
         */
        protected var _objects: Vector.<MovingObject> = new Vector.<MovingObject>();
        /**
         * An array of dormant objects, i.e. those that participate in interactions, but for which are not called
         * events and position does not change.
         */
        protected var _sleepingObjects: Dictionary = new Dictionary();
        /**
         * A moving object, relative to which the maximum gravitational influence is calculated for generation
         * corresponding event for planets.
         */
        protected var _attractionTrackingObject: MovingObject = null;
        /**
         * The current object that has the strongest gravitational effect on the previously specified object.
         */
        protected var _mostAttractingMassiveObject: MassiveObject = null;

        protected var _debugForcesTexture: RenderTexture;
        protected var _debugForcesCanvas: Canvas;

        /**
         * Constructor. Required to assign a frame draw event handler to avoid forcing child
         * classes call the base method in the scene initialization method.
         */
        public function GravitationScene() {
            super();

            if (DEBUG) {
                _debugForcesTexture = new RenderTexture(Starling.current.stage.stageWidth,
                                                        Starling.current.stage.stageHeight);

                _debugForcesCanvas = new Canvas();
                _debugForcesCanvas.beginFill(0x00FF00);

                addEventListener(Event.ADDED_TO_STAGE, function (event: Event): void {
                    var trajectories: Image = new Image(_debugForcesTexture);
                    addChild(trajectories);
                });
            }
        }

        /**
         * Registers the specified massive object in the gravitational interaction simulation.
         *
         * @param object Massive object.
         */
        protected function enableGravityForObject(object: MassiveObject): void {
            if (object is MovingObject) {
                _objects.push(object);

            } else if (object is BasePlanet) {
                _planets.push(object);
            }
        }

        /**
         * Turns off the simulation of the gravitational interaction for the specified object.
         *
         * @param object An array object previously added to the simulation.
         */
        protected function disableGravityForObject(object: MassiveObject): void {
            var objectIndex: int;
            if (object is MovingObject) {
                objectIndex = _objects.indexOf(object as MovingObject);
                if (objectIndex > -1) {
                    _objects.removeAt(objectIndex);
                }

            } else if (object is BasePlanet) {
                objectIndex = _planets.indexOf(object as BasePlanet);
                if (objectIndex > -1) {
                    _planets.removeAt(objectIndex);
                }
            }
        }

        /**
         * Disables gravity simulation for all previously added objects.
         */
        protected function disableGravityForAllObjects(): void {
            _objects = new Vector.<MovingObject>();
            _planets = new Vector.<BasePlanet>();
        }

        /**
         * "Wakes up" the object after colliding with other objects, thus returning it to the gravity simulation.
         *
         * @param object
         */
        protected function wakeObject(object: MassiveObject): void {
            if (_sleepingObjects[object]) {
                delete _sleepingObjects[object];
            }
        }

        protected function createLinePolygon(from: Point, end: Point, thickness: Number): Polygon {
            var len: Number, fXOffset: Number, fYOffset: Number;

            fXOffset = end.x - from.x;
            fYOffset = end.y - from.y;

            len = Math.sqrt(fXOffset * fXOffset + fYOffset * fYOffset);
            fXOffset = fXOffset * thickness / (len * 2);
            fYOffset = fYOffset * thickness / (len * 2);

            return new Polygon([
                                   from.x + fYOffset, from.y - fXOffset,
                                   end.x + fYOffset, end.y - fXOffset,
                                   end.x - fYOffset, end.y + fXOffset,
                                   from.x - fYOffset, from.y + fXOffset
                               ]);
        }

        protected function drawDebugForceVector(pointA: Point, pointB: Point): void {
            if (DEBUG) {
                _debugForcesCanvas.drawPolygon(createLinePolygon(pointA, pointB, 2));
                _debugForcesTexture.draw(_debugForcesCanvas);
            }
        }

        protected function drawDebugObjectVelocity(object: MovingObject): void {
            if (DEBUG) {
                var clonedVelocity: Point = object.velocity.clone();
                clonedVelocity.normalize(30);

                drawDebugForceVector(Pool.getPoint(object.x, object.y),
                                     Pool.getPoint(object.x + clonedVelocity.x, object.y + clonedVelocity.y));
            }
        }

        /**
         * Calculates the speed of objects on the scene for a specified period of time.
         *
         * @param dt Time difference in seconds from the previous calculation.
         */
        protected function updateVelocities(dt: Number): void {
            // Processing only planet-to-object and object-to-object relationships
            var pointA: Point = Pool.getPoint();
            var pointB: Point = Pool.getPoint();

            var distance: Point;
            var distanceLength: Number;
            var distanceCollisionLength: Number;

            var minDistance: Number = Number.MAX_VALUE;
            var closestGravitator: MassiveObject = null;

            var forceMultiplier: Number;
            var force: Point = Pool.getPoint();

            var maxForceMultiplier: Number = Number.MIN_VALUE;
            var mostAttracting: MassiveObject = null;

            if (DEBUG) {
                _debugForcesTexture.clear();
                _debugForcesCanvas.clear();
            }

            const objectsLength: int = _objects.length;
            for (var i: int = 0; i < objectsLength; ++i) {
                const object: MovingObject = _objects[i];

                if (_sleepingObjects[object]) {
                    continue;
                }

                // we assume that the pivot point (pivot) is set correctly for all objects
                pointA.x = object.x;
                pointA.y = object.y;

                const planetsLength: int = _planets.length;
                for (var j: int = 0; j < planetsLength; j++) {
                    const planet: BasePlanet = _planets[j];

                    pointB.x = planet.x;
                    pointB.y = planet.y;

                    distance = pointB.subtract(pointA);

                    // TODO: for now, we assume that the objects are also round
                    distanceLength = distance.length;
                    distanceCollisionLength = distance.length - planet.radius; // TODO: so far, for simplicity, not at all
                                                                               // take into account the size of the object

                    if (distanceLength < minDistance) {
                        minDistance = distanceLength;
                        closestGravitator = planet;
                    }

                    // drawDebugForceVector(pointA, pointB);

                    if (distanceCollisionLength > DISTANCE_COLLISION_THRESHOLD) {
                        distance.normalize(1);

                        // we need acceleration (F=ma), so we immediately divide by the mass of the object and simply do not write it in
                        // formula
                        forceMultiplier = (G * planet.mass) / (distanceLength * distanceLength) * FORCE_MULTIPLIER;
                        if (forceMultiplier > maxForceMultiplier) {
                            maxForceMultiplier = forceMultiplier;
                            mostAttracting = planet;
                        }

                        force.x = distance.x * forceMultiplier * dt;
                        force.y = distance.y * forceMultiplier * dt;

                        object.addVelocity(force);

                        // drawDebugObjectVelocity(object);

                    } else {
                        object.velocity = new Point(); // stop the movement of the object after the collision

                        object.dispatchEventWith(MassiveObject.EVENT_COLLIDED, false, planet);
                        planet.dispatchEventWith(MassiveObject.EVENT_COLLIDED, false, object);

                        _sleepingObjects[object] = true;
                    }
                }

                if (_mostAttractingMassiveObject !== mostAttracting) {
                    mostAttracting.dispatchEventWith(BasePlanet.EVENT_BECAME_MOST_ATTRACTING,
                                                     false,
                                                     { previous: _mostAttractingMassiveObject });
                    _mostAttractingMassiveObject = mostAttracting;
                }

                /*for (j = 0; j < objectsLength; j++) {
                    if (i === j) {
                        continue;
                    }

                    const otherObject: MovingObject = _objects[j];

                    pointB.x = otherObject.x;
                    pointB.y = otherObject.y;

                    distance = pointB.subtract(pointA);

                    // TODO: for now we assume that all objects are round
                    distanceLength = distance.length;
                    distanceCollisionLength = distance.length - object.width / 2 - otherObject.width / 2;

                    if (distanceLength < minDistance) {
                        minDistance = distanceLength;
                        closestGravitator = planet;
                    }

                    // drawDebugForceVector(pointA, pointB);

                    if (distanceCollisionLength > DISTANCE_COLLISION_THRESHOLD) {
                        distance.normalize(1);

                        // we need acceleration (F=ma), so we immediately divide by the mass of the object and simply do not write it in
                        // formula
                        forceMultiplier = (G * otherObject.mass * object.mass) / (distanceLength * distanceLength) * FORCE_MULTIPLIER;

                        force.x = (distance.x * forceMultiplier * dt / object.mass);
                        force.y = (distance.y * forceMultiplier * dt / object.mass);

                        object.addVelocity(force);

                        force.x = (distance.x * forceMultiplier * dt / otherObject.mass);
                        force.y = (distance.y * forceMultiplier * dt / otherObject.mass);

                        otherObject.subtractVelocity(force);

                        // drawDebugObjectVelocity(object);
                        // drawDebugObjectVelocity(otherObject);

                    } else {
                        // stop the movement of an object with a smaller mass after a collision
                        if (otherObject.mass > object.mass) {
                            object.velocity = new Point();

                            object.dispatchEventWith(MassiveObject.EVENT_COLLIDED, false, otherObject);
                            _sleepingObjects[object] = true;

                        } else {
                            otherObject.velocity = new Point();

                            otherObject.dispatchEventWith(MassiveObject.EVENT_COLLIDED, false, object);
                            _sleepingObjects[otherObject] = true;
                        }
                    }
                 }*/

                object.distanceToClosestGravitator = minDistance;
                object.closestGravitator = closestGravitator;
            }

            Pool.putPoint(pointA);
            Pool.putPoint(pointB);
            Pool.putPoint(force);
        }

        /**
         * Updates the positions of moving objects on the scene for a specified period of time.
         *
         * @param dt Time difference in seconds from the previous calculation.
         */
        protected function updatePositions(dt: Number): void {
            const objectsLength: int = _objects.length;
            for (var i: int = 0; i < objectsLength; i++) {
                const object: MovingObject = _objects[i];
                const velocity: Point = object.velocity;

                object.x += velocity.x * dt;
                object.y += velocity.y * dt;

                if (!_sleepingObjects[object]) {
                    object.rotation = object.velocityAngle;
                }
            }
        }

        /**
         * @inheritDoc
         */
        override public function advanceTime(time: Number): void {
            if (time > SIMULATION_MAX_DELTA) {
                time = SIMULATION_MAX_DELTA;
            }

            time /= SIMULATION_STEPS;

            for (var s: int = 0; s < SIMULATION_STEPS; s++) {
                updateVelocities(time * TIME_MULTIPLIER);
                updatePositions(time * TIME_MULTIPLIER);
            }
        }

    }

}
