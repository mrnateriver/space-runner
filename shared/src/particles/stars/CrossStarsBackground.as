/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package particles.stars {
    import starling.textures.Texture;

    import support.drawing.TextureGenerator;

    /**
     * A particle system that generates a smoothly moving starry sky with stars with diffraction peaks.
     */
    public class CrossStarsBackground extends StarsBackground {

        /**
         * Base apparent size of stars.
         */
        protected static const STAR_SIZE: int = 38;

        /**
         * Constructor.
         *
         * @param starCount Number of stars to display at the same time.
         * @param starLifespan Lifespan of each individual star.
         * @param starColor The color of the generated stars, including the alpha channel.
         */
        public function CrossStarsBackground(starCount: int = 6,
                                            starLifespan: Number = 300.0,
                                            starColor: uint = 0xffffffcc) {
            super(starCount, starLifespan, starColor);
        }

        /**
         * Creates a single star texture instance.
         *
         * @return The texture instance.
         */
        override protected function createTexture(): Texture {
            return TextureGenerator.createCrossStar(starColor, STAR_SIZE);
        }

    }

}
