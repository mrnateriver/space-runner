/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class Algorithms {

        /**
         * Returns the cosine of the angle between two vectors.
         *
         * @param a
         * @param b
         *
         * @return
         */
        public static function getAngleCosineBetweenVectors(a: Point, b: Point): Number {
            var dotProduct: Number = dot(a, b);
            var magnitude: Number = a.length * b.length;

            var angleCosine: Number = dotProduct / magnitude;

            return angleCosine;
        }

        /**
         * Returns the angle between two vectors.
         *
         * @param a
         * @param b
         *
         * @return
         */
        public static function getAngleBetweenVectors(a: Point, b: Point): Number {
            return Math.acos(getAngleCosineBetweenVectors(a, b));
        }

        /**
         * Calculates the intersection point of a ray starting at the center of the specified rectangle with the edges of the same
         * rectangle. If no {Point} instance is passed as the last argument to write the result, a
         * new instance will be created.
         *
         * @param rayEnd Coordinates of the end point of the ray that originates from the center of the rectangle.
         * @param rectangle An instance of a rectangle.
         * @param out The object to which the result will be written.
         *
         * @return
        */
        public static function getRectangleRayIntersectionPoint(rayEnd: Point,
                                                                rectangle: Rectangle,
                                                                out: Point = null): Point {
            if (out === null) {
                out = new Point();
            }

            // https://stackoverflow.com/a/1585620
            const hh: Number = rectangle.height / 2; // half the height of the rectangle
            const hw: Number = rectangle.width / 2; // half width

            const rX: Number = rectangle.x + hw; // X coordinate of the center of the rectangle
            const rY: Number = rectangle.x + hh; // Y coordinate of the center of the rectangle

            // y = kx + b - equation of a straight line
            const slope: Number = (rY - rayEnd.y) / (rX - rayEnd.x); // k from the usual notation

            const hsw: Number = slope * hw;
            const hsh: Number = hh / slope;

            if (-hh <= hsw && hsw <= hh) {
                // there is an intersection
                if (rX < rayEnd.x) {
                    // right edge
                    out.x = rX + hw;
                    out.y = rY + hsw;

                } else if (rX > rayEnd.x) {
                    // left edge
                    out.x = rX - hw;
                    out.y = rY - hsw;
                }
            }

            if (-hw <= hsh && hsh <= hw) {
                if (rY < rayEnd.y) {
                    // bottom edge
                    out.x = rX + hsh;
                    out.y = rY + hh;

                } else if (rY > rayEnd.y) {
                    // top edge
                    out.x = rX - hsh;
                    out.y = rY - hh;
                }
            }

            return out;
        }

        /**
         * Calculates a vector perpendicular to the specified one.
         *
         * @param vector The vector for which to find the perpendicular.
         * @param out The vector in which the result will be written.
         * @param clockwise Whether to measure the perpendicular vector clockwise.
         */
        public static function getPerpendicularVector(vector: Point,
                                                      out: Point = null,
                                                      clockwise: Boolean = true): Point {
            if (out === null) {
                out = new Point();
            }

            if (clockwise) {
                out.x = -vector.y;
                out.y = vector.x;
            } else {
                out.x = vector.y;
                out.y = -vector.x;
            }

            return out;
        }

        /**
         * Returns the dot product of two vectors.
         *
         * @param a
         * @param b
         *
         * @return
         */
        public static function dot(a: Point, b: Point): Number {
            return a.x * b.x + a.y * b.y;
        }

        /**
         * Returns whether a ray that starts at the given point and has the given direction intersects the circle with
         * with the specified radius and center at the specified point.
         *
         * @param rayOrigin Coordinates of the origin of the ray.
         * @param rayDirection Ray direction vector.
         * @param circleCenter Coordinates of the center of the circle.
         * @param circleRadius The radius of the circle.
         *
         * @return
         */
        public static function rayIntersectsCircle(rayOrigin: Point,
                                                   rayDirection: Point,
                                                   circleCenter: Point,
                                                   circleRadius: Number): Boolean {
            if (!rayDirection.length) {
                return false;
            }

            rayDirection.normalize(1);

            // https://math.stackexchange.com/a/2633290
            // https://www.openprocessing.org/sketch/45537
            const oc: Point = rayOrigin.subtract(circleCenter);

            const lf: Number = dot(rayDirection, oc);
            const s: Number = Math.pow(circleRadius, 2) - dot(oc, oc) + Math.pow(lf, 2);

            return !(s < 0 || (lf < s && (lf + s) < 0));
        }

        /**
         * Returns a specified number of random elements from an array.
         *
         * @param array An instance of a standard array or vector.
         * @param count The number of elements to return.
         *
         * @return
         */
        public static function getRandomArrayEntries(array: *, count: uint = 1): * {
            if (array is Array || array is Vector) {
                if (count === 1) {
                    return array[int(Math.random() * array.length)];

                } else if (count > 1) {
                    const copy: * = array;
                    const result: Array = [];

                    var selectedIndex: int;
                    var i: int = 0;
                    while (i < count && copy.length > 0) {
                        selectedIndex = int(Math.random() * copy.length);

                        result.push(copy[selectedIndex]);
                        copy.splice(selectedIndex, 1);
                    }

                    return result;
                }
            }

            return null;
        }

        /**
         * Returns the value of an object's random property.
         *
         * @param object
         *
         * @return
         */
        public static function getRandomObjectProperty(object: Object): * {
            var keys: Array = [];
            for (var key: String in object) {
                keys.push(key);
            }

            return object[keys[int(Math.random() * keys.length)]];
        }

    }

}
