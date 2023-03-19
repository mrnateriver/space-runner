/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package particles {

    import flash.geom.Point;

    import starling.animation.IAnimatable;
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Mesh;
    import starling.rendering.IndexData;
    import starling.rendering.VertexData;
    import starling.textures.Texture;

    public class RibbonTrail extends Mesh implements IAnimatable {
        private static var sMapTexCoords: Vector.<Number> = new <Number>[0.0, 0.0, 0.0, 0.0];

        protected var mVertexData: VertexData;
        protected var mIndexData: IndexData;
        protected var mTexture: Texture;

        protected var mRibbonSegments: Vector.<RibbonSegment>;
        protected var mNumRibbonSegments: int;

        protected var mFollowingEnable: Boolean = true;

        protected var mMovingRatio: Number = 0.5;
        protected var mAlphaRatio: Number = 0.95;

        protected var mRepeat: Boolean = false;

        protected var mIsPlaying: Boolean = false;

        protected var mFollowingRibbonSegmentLine: Vector.<RibbonSegment>;

        public function RibbonTrail(trailSegments: int = 10) {
            mVertexData = new VertexData();
            mVertexData.premultipliedAlpha = true;

            mIndexData = new IndexData();

            super(mVertexData, mIndexData);

            mRibbonSegments = new <RibbonSegment>[];

            raiseCapacity(trailSegments);

            updatevertexData();

            blendMode = BlendMode.NORMAL;
        }

        public function get followingEnable(): Boolean {
            return mFollowingEnable;
        }

        public function set followingEnable(value: Boolean): void {
            mFollowingEnable = value;
        }

        public function get isPlaying(): Boolean {
            return mIsPlaying;
        }

        public function set isPlaying(value: Boolean): void {
            mIsPlaying = value;
        }

        public function get movingRatio(): Number {
            return mMovingRatio;
        }

        public function set movingRatio(value: Number): void {
            if (mMovingRatio != value) {
                mMovingRatio = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
            }
        }

        public function get alphaRatio(): Number {
            return mAlphaRatio;
        }

        public function set alphaRatio(value: Number): void {
            if (mAlphaRatio != value) {
                mAlphaRatio = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
            }
        }

        public function get repeat(): Boolean {
            return mRepeat;
        }

        public function set repeat(value: Boolean): void {
            if (mRepeat != value) {
                mRepeat = value;

            }
        }

        //we don't need hitTest return.
        override public function hitTest(localPoint: Point): DisplayObject {
            return null;
        }

        override public function dispose(): void {
            super.dispose();

            mFollowingRibbonSegmentLine = null;

            mFollowingEnable = false;

            mTexture = null;
            mRibbonSegments = null;
            mIsPlaying = false;
            mNumRibbonSegments = 0;
        }

        public function getRibbonSegment(index: int): RibbonSegment {
            return mRibbonSegments[index];
        }

        public function followTrailSegmentsLine(followingRibbonSegmentLine: Vector.<RibbonSegment>): void {
            mFollowingRibbonSegmentLine = followingRibbonSegmentLine;
        }

        public function resetAllTo(x0: Number, y0: Number, x1: Number, y1: Number,
                                   alpha: Number = 1.0): void {
            if (mNumRibbonSegments > mRibbonSegments.length) {
                return;
            }

            var trailSegment: RibbonSegment;
            var trailSegmentIndex: int = 0;

            while (trailSegmentIndex < mNumRibbonSegments) {
                trailSegment = mRibbonSegments[trailSegmentIndex];
                trailSegment.setTo(x0, y0, x1, y1, alpha);

                trailSegmentIndex++;
            }
        }

        public function advanceTime(passedTime: Number): void {
            if (!mIsPlaying) {
                return;
            }

            var followingRibbonSegmentLineLength: int = mFollowingRibbonSegmentLine ?
                                                        mFollowingRibbonSegmentLine.length : 0;

            if (followingRibbonSegmentLineLength == 0) {
                return;
            }

            var vertexId: int = 0;
            var trailSegment: RibbonSegment;
            var followingSegment: RibbonSegment;
            var preTrailSegment: RibbonSegment;

            var trailSegmentIndex: int = 0;
            if (mRibbonSegments.length < mNumRibbonSegments) {
                return;
            }

            var colorized: Boolean = false;
            while (trailSegmentIndex < mNumRibbonSegments) {
                trailSegment = mRibbonSegments[trailSegmentIndex];
                followingSegment = trailSegmentIndex < followingRibbonSegmentLineLength ?
                                   mFollowingRibbonSegmentLine[trailSegmentIndex] : null;

                if (followingSegment) {
                    trailSegment.copyFrom(followingSegment);
                }
                else if (mFollowingEnable && preTrailSegment) {
                    trailSegment.tweenTo(preTrailSegment);

                    if (!colorized && trailSegment.color != preTrailSegment.color) {
                        trailSegment.color = preTrailSegment.color;
                        colorized = true;
                    }
                }

                preTrailSegment = trailSegment;

                vertexId = trailSegmentIndex * 2;

                setVertexPosition(vertexId, trailSegment.x0, trailSegment.y0);
                setVertexColor(vertexId, trailSegment.color);
                setVertexAlpha(vertexId, trailSegment.alpha);

                setVertexPosition(vertexId + 1, trailSegment.x1, trailSegment.y1);
                setVertexColor(vertexId + 1, trailSegment.color);
                setVertexAlpha(vertexId + 1, trailSegment.alpha);

                ++trailSegmentIndex;
            }
        }

        public function raiseCapacity(byAmount: int): void {
            var oldNumRibbonSegments: int = mNumRibbonSegments;
            mNumRibbonSegments = Math.min(8129, oldNumRibbonSegments + byAmount);

            mRibbonSegments.fixed = false;

            var trailSegment: RibbonSegment;

            for (var trailSegmentIndex: int = oldNumRibbonSegments; trailSegmentIndex < mNumRibbonSegments; trailSegmentIndex++) {
                trailSegment = createTrailSegment();
                trailSegment.ribbonTrail = this;
                mRibbonSegments[trailSegmentIndex] = trailSegment;

                if (trailSegmentIndex > 0) {
                    var quadIndex: int = trailSegmentIndex * 2 - 2;
                    indexData.addQuad(quadIndex, quadIndex + 2, quadIndex + 1, quadIndex + 3);
                }
            }

            mRibbonSegments.fixed = true;
        }

        protected function updatevertexData(): void {
            var shareRatio: Number = 1 / mNumRibbonSegments;
            var ratio: Number = 0;

            var vertexId: int = 0;
            var trailSegmentIndex: int = 0;

            while (trailSegmentIndex < mNumRibbonSegments) {
                vertexId = trailSegmentIndex * 2;

                ratio = trailSegmentIndex * shareRatio;

                //uv.
                if (mRepeat) {
                    sMapTexCoords[0] = trailSegmentIndex;
                    sMapTexCoords[1] = 0;
                    sMapTexCoords[2] = trailSegmentIndex;
                    sMapTexCoords[3] = 1;
                }
                else {
                    sMapTexCoords[0] = ratio;
                    sMapTexCoords[1] = 0;
                    sMapTexCoords[2] = ratio;
                    sMapTexCoords[3] = 1;
                }

                setTexCoords(vertexId, sMapTexCoords[0], sMapTexCoords[1]);
                setTexCoords(vertexId + 1, sMapTexCoords[2], sMapTexCoords[3]);

                trailSegmentIndex++;
            }
        }

        protected function createTrailSegment(): RibbonSegment {
            return new RibbonSegment();
        }
    }

}
