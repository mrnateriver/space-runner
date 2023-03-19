/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package particles.stars {
    import flash.utils.setTimeout;

    import starling.core.Starling;
    import starling.display.Canvas;
    import starling.display.Stage;
    import starling.extensions.ColorArgb;
    import starling.extensions.Particle;
    import starling.extensions.ParticleSystem;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;

    /**
     * A particle system that generates a smoothly moving starry sky.
     */
    public class StarsBackground extends ParticleSystem {

        /**
         * Base apparent size of stars.
         */
        protected static const STAR_SIZE: int = 12;

        /**
         * Color generated stars.
         */
        private var _starColor: ColorArgb;
        /**
         * Number of generated stars.
         */
        private var _starCount: int;
        /**
         * The lifetime of each of the stars.
         */
        private var _starLifespan: Number;
        /**
         * An instance of the texture used to display the stars.
         */
        private var _particleTexture: Texture;

        /**
         * Constructor.
         *
         * @param starCount Number of stars to display at the same time.
         * @param starLifespan Lifespan of each individual star.
         * @param starColor The color of the generated stars, including the alpha channel.
         */
        public function StarsBackground(starCount: int = 70,
                                        starLifespan: Number = 220.0,
                                        starColor: uint = 0xffffffff) {
            _starCount = starCount;
            _starLifespan = starLifespan;
            _starColor = ColorArgb.fromArgb(starColor);

            _particleTexture = createTexture();

            super(_particleTexture);
            emissionRate = _starCount / _starLifespan;
            capacity = _starCount;

            populate(_starCount);
        }

        /**
         * Creates an instance of a particle representing a single star.
         *
         * @return The particle instance.
         */
        override protected function createParticle(): Particle {
            return new StarParticle();
        }

        /**
         * Sets the initial parameters of the particle at the time of its generation.
         *
         * @param _particle An instance of the newly created particle.
         */
        override protected function initParticle(_particle: Particle): void {
            var particle: StarParticle = _particle as StarParticle;
            var stage: Stage = Starling.current.stage;

            // Reset The Particle's Current Animation Time
            particle.currentTime = 0.0;
            // Randomize the total particle lifetime (creates a parallax effect): 30 + 30 * [-0.5, 0.5] = [15, 45]
            particle.totalTime = _starLifespan + _starLifespan * (Math.random() - 0.5);

            // Randomize the particle size, given that we created the texture in triple size: [0.3, 0.45]
            particle.scale = 0.2 + 0.3 * Math.random();
            // Put the star outside the scene
            particle.x = stage.stageWidth * Math.random();
            particle.y = -_particleTexture.height * 0.5 * particle.scale;

            // Calculate the speed of the particle. During the lifetime of a particle, it must move
            // opposite screen border
            particle.speed = ((stage.stageHeight + _particleTexture.height * particle.scale) - particle.y) / particle.totalTime;

            // Set the color of the particle
            particle.color = _starColor.toRgb();
        }

        /**
         * Changes particle parameters over time.
         *
         * @param _particle The particle instance.
         * @param passedTime The time elapsed since the last call to this function.
         */
        override protected function advanceParticle(_particle: Particle, passedTime: Number): void {
            var particle: StarParticle = _particle as StarParticle;
            particle.y += particle.speed * passedTime;
            particle.currentTime += passedTime;
        }

        /**
         * Returns the color of generated stars.
         */
        public function getstarColor(): ColorArgb {
            return _starColor;
        }

        /**
         * Returns the number of stars generated at the same time.
         */
        public function get starCount(): int {
            return _starCount;
        }

        /**
         * Returns the lifetime of each individual star.
         */
        public function get starLifespan(): Number {
            return _starLifespan;
        }

        /**
         * Creates an instance of the texture used to display the stars.
         *
         * @return The texture instance.
         */
        protected function createTexture(): Texture {
            const rt: RenderTexture = new RenderTexture(STAR_SIZE, STAR_SIZE, false, Starling.contentScaleFactor);

            const draw: Function = function (): void {
                const canvas: Canvas = new Canvas();
                canvas.beginFill(_starColor.toRgb(), _starColor.alpha);

                const radius: Number = STAR_SIZE / 2;
                canvas.drawCircle(radius, radius, radius);

                rt.draw(canvas, null, 1.0, 4);

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
         * @inheritDoc
         */
        override public function dispose(): void {
            _particleTexture.dispose();
            super.dispose();
        }

    }

}
