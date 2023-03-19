/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support.directing {
    import starling.display.DisplayObjectContainer;

    /**
     * The interface of the scene, providing a container with the player and the planet around which it rotates.
     */
    public interface IPlayerPlanetContainer {

        /**
         * Returns a container with player and planet objects.
         */
        function get playerPlanetSystem(): DisplayObjectContainer;

    }

}
