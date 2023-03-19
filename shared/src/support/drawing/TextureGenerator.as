/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.drawing {
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Canvas;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.extensions.ColorArgb;
    import starling.geom.Polygon;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;

    /**
     * Class for procedural generation of various textures.
     */
    public class TextureGenerator {

        /**
         * Creates an image of a regular multi-pointed star.
         *
         * @param color
         * @param size
         * @param count
         *
         * @return
         */
        public static function createStarIcon(color: ColorArgb, size: Number, count: uint = 5): Texture {
            const rt: RenderTexture = new RenderTexture(size, size, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const halfSize: Number = size / 2;

                const triangle: Polygon = new Polygon();
                triangle.addVertices(halfSize / 2, 0);
                triangle.addVertices(halfSize, halfSize);
                triangle.addVertices(0, halfSize);

                const canvas: Canvas = new Canvas();
                canvas.beginFill(color.toRgb(), color.alpha);
                canvas.drawPolygon(triangle);
                canvas.pivotY = halfSize;
                canvas.pivotX = halfSize / 2;
                canvas.x = halfSize;
                canvas.y = halfSize;

                rt.drawBundled(function (): void {
                    const delta: Number = 2 * Math.PI / count;
                    for (var i: uint = 0; i < count; i++) {
                        canvas.rotation = i * delta;
                        rt.draw(canvas);
                    }
                }, 4);

                canvas.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates a star-cross texture.
         *
         * @param color
         * @param size
         *
         * @return
         */
        public static function createCrossStar(color: ColorArgb, size: Number): Texture {
            const rt: RenderTexture = new RenderTexture(size, size, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const canvas: Canvas = new Canvas();
                canvas.beginFill(color.toRgb(), color.alpha);
                canvas.drawRectangle(0, 0, size, size);

                const radius: Number = size / 2;

                const circle: Canvas = new Canvas();
                circle.beginFill();
                circle.drawCircle(radius, radius, radius);
                circle.blendMode = BlendMode.ERASE;
                circle.alignPivot();

                rt.drawBundled(function (): void {
                    rt.draw(canvas);

                    circle.x = 0;
                    circle.y = 0;
                    rt.draw(circle);

                    circle.x = size;
                    circle.y = 0;
                    rt.draw(circle);

                    circle.x = size;
                    circle.y = size;
                    rt.draw(circle);

                    circle.x = 0;
                    circle.y = size;
                    rt.draw(circle);
                }, 4);

                circle.dispose();
                canvas.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates a shadow texture on the planet.
         */
        public static function createPlanetShadowTexture(radius: Number,
                                                         alpha: Number = 0.5,
                                                         shadowSize: Number = 30): Texture {
            const rt: RenderTexture = new RenderTexture(radius * 2, radius * 2, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const canvas: Canvas = new Canvas();
                canvas.beginFill(0);
                canvas.drawCircle(radius, radius, radius);
                canvas.alignPivot();
                canvas.x = canvas.y = radius;

                const eraser: Canvas = new Canvas();
                eraser.beginFill();
                eraser.drawCircle(radius + shadowSize / 3, radius + shadowSize / 3, radius + shadowSize / 3);
                eraser.alignPivot();
                eraser.blendMode = BlendMode.ERASE;
                eraser.x = eraser.y = radius - shadowSize;

                rt.drawBundled(function (): void {
                    rt.draw(canvas, null, alpha, 16);
                    rt.draw(eraser);
                });

                canvas.dispose();
                eraser.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates a texture for the "pause" icon.
         *
         * @param width
         * @param height
         * @param color
         *
         * @return
         */
        public static function createPauseIcon(width: Number, height: Number, color: uint): Texture {
            const rt: RenderTexture = new RenderTexture(width, height, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(color);

                cv.drawRectangle(0, 0, width / 3, height);
                cv.drawRectangle(2 * width / 3, 0, width / 3, height);

                rt.draw(cv, null, 1.0, 4);

                cv.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates an "ouroboros arrow" texture.
         *
         * @param radius
         * @param color
         * @param borderThickness
         *
         * @return
         */
        public static function createReloadIcon(radius: Number, color: uint, borderThickness: Number = 10): Texture {
            const finerRotationAngle: Number = Math.acos(2 / 3);

            const rt: RenderTexture = new RenderTexture(radius * 2, radius * 2, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(color);
                cv.drawCircle(radius, radius, radius - borderThickness);

                const eraser: Canvas = new Canvas();
                eraser.beginFill();
                eraser.blendMode = BlendMode.ERASE;

                eraser.drawRectangle(0, radius * 2 / 3, radius, radius / 3 * 2);
                eraser.drawCircle(radius, radius, radius - borderThickness * 2);

                const finer: Canvas = new Canvas();
                finer.beginFill();
                finer.blendMode = BlendMode.ERASE;

                const realRadius: Number = radius - borderThickness;

                // shift of 1 pixel is needed in order to remove the gap between the ring and the arrow that occurs due to
                // anti-aliasing
                finer.drawRectangle(0, 1, radius, borderThickness - 2);
                finer.x = radius - realRadius / 2;
                finer.y = radius;

                const arrowHeadWidth: Number = borderThickness * 2 * 1.1;

                const triangle: Polygon = new Polygon();
                triangle.addVertices(0, 0);
                triangle.addVertices(arrowHeadWidth, 0);
                triangle.addVertices(arrowHeadWidth / 2, arrowHeadWidth * 2 / 3);

                const arrowHeadOffset: Number = 1.5 * borderThickness - arrowHeadWidth / 2;

                const arrowHead: Canvas = new Canvas();
                arrowHead.beginFill(color);
                arrowHead.drawPolygon(triangle);
                arrowHead.pivotY = borderThickness;
                arrowHead.pivotX = realRadius / 2 + borderThickness / 2 + arrowHeadOffset;
                arrowHead.rotation = 0.5 * Math.PI - finerRotationAngle;
                arrowHead.x = arrowHead.pivotX;
                arrowHead.y = radius;

                rt.drawBundled(function (): void {
                    rt.draw(cv);
                    rt.draw(eraser);

                    finer.rotation = 1.5 * Math.PI - finerRotationAngle;
                    rt.draw(finer);

                    finer.pivotY = borderThickness;
                    finer.rotation = 0.5 * Math.PI + finerRotationAngle;
                    rt.draw(finer);

                    rt.draw(arrowHead);
                }, 4);

                cv.dispose();
                eraser.dispose();
                finer.dispose();
                arrowHead.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;

        }

        public static function createArrowTexture(height: Number,
                                                  width: Number,
                                                  borderColor: uint,
                                                  innerColor: uint): Texture {
            const headCoefficient: Number = 0.35;
            const borderSize: Number = height / 4 * 0.2;

            const rt: RenderTexture = new RenderTexture(width, height, false, Starling.contentScaleFactor);
            const draw: Function = function (): void {
                rt.drawBundled(function (): void {
                    const cv: Canvas = new Canvas();
                    cv.beginFill(borderColor);
                    cv.drawRectangle(width * headCoefficient, height / 2 - height / 8, width * 0.75, height / 4);

                    const triangle: Polygon = new Polygon();
                    triangle.addVertices(0, height / 2);
                    triangle.addVertices(width * headCoefficient, 0);
                    triangle.addVertices(width * headCoefficient, height);
                    cv.drawPolygon(triangle);

                    const inner: Canvas = new Canvas();
                    inner.beginFill(innerColor);
                    inner.drawRectangle(width * headCoefficient - borderSize * 1.1, height / 2 - height / 8 + borderSize, width - width * headCoefficient, height / 4 - borderSize * 2);

                    const innerTriangle: Polygon = new Polygon();
                    innerTriangle.addVertices(borderSize * 2, height / 2);
                    innerTriangle.addVertices(width * headCoefficient - borderSize * 1.1, borderSize * 2);
                    innerTriangle.addVertices(width * headCoefficient - borderSize * 1.1, height - borderSize * 2);
                    inner.drawPolygon(innerTriangle);

                    rt.draw(cv);
                    rt.draw(inner);

                    cv.dispose();
                    inner.dispose();
                }, 4);
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        public static function createSoundIcon(height: Number, color: uint): Texture {
            const rt: RenderTexture = new RenderTexture(height / 2, height, false, Starling.contentScaleFactor);
            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(color);
                cv.drawRectangle(0, height / 4, height / 2, height / 2);

                const triangle: Polygon = new Polygon();
                triangle.addVertices(0, 0);
                triangle.addVertices(height / 2, height / 2);
                triangle.addVertices(0, height);
                cv.drawPolygon(triangle);

                rt.draw(cv);
                cv.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        public static function createSoundWavesIcon(height: Number, color: uint): Texture {
            const thickness: Number = height * 0.05;

            const rt: RenderTexture = new RenderTexture(height / 2, height, false, Starling.contentScaleFactor);
            const draw: Function = function (): void {
                const cont: Sprite = new Sprite();

                for (var i: uint = 0; i < 3; i++) {
                    const radius: Number = height / 6 * (3 - i);

                    const cv: Canvas = new Canvas();
                    cv.beginFill(color);
                    cv.drawCircle(radius, radius, radius);
                    cv.alignPivot();
                    cv.x = cv.y = height / 2;

                    const eraser: Canvas = new Canvas();
                    eraser.blendMode = BlendMode.ERASE;
                    eraser.beginFill();
                    eraser.drawCircle(radius, radius, radius - thickness);
                    eraser.alignPivot();
                    eraser.drawRectangle(radius, 0, radius, radius * 2);
                    eraser.drawRectangle(0, radius, radius * 2, radius);
                    eraser.rotation -= Math.PI / 4;
                    eraser.x = eraser.y = height / 2;

                    cont.addChild(cv);
                    cont.addChild(eraser);
                }

                rt.drawBundled(function (): void {
                    rt.draw(cont);
                }, 4);

                cont.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        public static function createDashedLine(height: Number,
                                                width: Number,
                                                color: uint,
                                                alpha: Number = 1.0,
                                                dashWidth: Number = 10): Texture {
            const rt: RenderTexture = new RenderTexture(width, height, false, Starling.contentScaleFactor);
            const draw: Function = function (): void {
                const cv: Canvas = new Canvas();
                cv.beginFill(color, alpha);
                cv.drawRectangle(0, 0, dashWidth, height);

                const spacing: Number = dashWidth * 0.7;

                const total: Number = Math.ceil(width / (dashWidth + spacing));
                rt.drawBundled(function (): void {
                    for (var i: uint = 0; i < total; i++) {
                        cv.x = i * (dashWidth + spacing);
                        rt.draw(cv);
                    }
                }, 4);

                cv.dispose();
            };
            draw();

            rt.root.onRestore = function (): void {
                rt.clear();
                setTimeout(draw, 0);
            };

            return rt;
        }

        /**
         * Creates a planet texture of the specified color, lit from the top left side.
         *
         * @param radius
         * @param color
         *
         * @return
         */
        public static function createPlanetBaseTexture(radius: Number, color: uint): Texture {
            const rt: RenderTexture = new RenderTexture(radius * 2, radius * 2, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                rt.clear(color, 1);

                const topLeft: Quad = new Quad(radius, radius, color);
                topLeft.setVertexColor(0, 0xffffff);
                topLeft.x = topLeft.y = 0;

                const topRight: Quad = new Quad(radius, radius, color);
                topRight.setVertexColor(1, 0xffffff);
                topRight.x = radius;
                topRight.y = 0;

                const bottomRight: Quad = new Quad(radius, radius, color);
                bottomRight.setVertexColor(2, 0xffffff);
                bottomRight.x = 0;
                bottomRight.y = radius;

                const bottomLeft: Quad = new Quad(radius, radius, color);
                bottomLeft.setVertexColor(3, 0xffffff);
                bottomLeft.x = radius;
                bottomLeft.y = radius;

                rt.drawBundled(function (): void {
                    rt.draw(topLeft);
                    rt.draw(topRight);
                    rt.draw(bottomLeft);
                    rt.draw(bottomRight);
                });

                topLeft.dispose();
                topRight.dispose();
                bottomRight.dispose();
                bottomLeft.dispose();
            };

            rt.root.onRestore = function (): void {
                setTimeout(draw, 0);
            };

            return rt;
        }

    }
}
