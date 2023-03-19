/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support {

    /**
     * Class that stores the color palette used for generating planet textures.
     */
    public class PlanetPalette {

        /**
         * An array of colors that can be used for generating planet textures.
         */
        public static const COLORS: Object = {
            WHITE: 0xffffff, // white
            BROWNISH_WHITE: 0xf5dcbd, // brownish white
            BLUEISH_WHITE: 0xc8d3d9, // bluish white
            MAGENTA_GRAY: 0xe7e0f0, // gray with a touch of purple
            ORANGE: 0xe86908, // orange
            DARK_ORANGE: 0x864124, // dark orange
            DARK_RED_ORANGE: 0xa9472e, // dark, almost red orange
            LIGHT_BROWN: 0xecb485, // ochre
            BROWN: 0xc38959, // darkened ochre
            BLUE: 0x6c82b3, // blue
            YELLOW: 0xf8cc49, // yellow
            BLUE_GRAY: 0x8495c1, // blue-gray
            DARK_BLUE: 0x314465, // dark blue
            DIRTY_ORANGE: 0xc9621f, // dirty orange
            DARK_DIRTY_ORANGE: 0xba5c29, // dark dirty orange
            GRASS_GREEN: 0x92cf36, // grassy green
            MYSTERY_GREEN: 0x44ad82, // mysterious green
            MOLD_GREEN: 0x197856, // moldy green
            GRAY: 0xadaabd // gray
        };

        /**
         * Groups of colors based on their compatibility in a single object.
         */
        public static const COLORS_GROUPS: Object = {
            // in all groups, the first color is the one that can fill the "base" of the planets - the basic color
            // the second one is the contrasting color that can fill the layer of the planet's details
            ORANGE: [
                COLORS.ORANGE,
                COLORS.DARK_ORANGE,
                COLORS.DARK_RED_ORANGE,
                COLORS.DIRTY_ORANGE,
                COLORS.DARK_DIRTY_ORANGE,
                COLORS.YELLOW
            ],
            LIGHT_BROWN: [
                COLORS.LIGHT_BROWN,
                COLORS.BROWN,
                COLORS.BROWNISH_WHITE
            ],
            BLUE: [
                COLORS.BLUE,
                COLORS.DARK_BLUE,
                COLORS.BLUE_GRAY,
                COLORS.BLUEISH_WHITE
            ],
            GREEN: [
                COLORS.MYSTERY_GREEN,
                COLORS.MOLD_GREEN,
                COLORS.GRASS_GREEN
            ],
            GRAY: [
                COLORS.WHITE,
                COLORS.GRAY,
                COLORS.BROWNISH_WHITE,
                COLORS.BLUEISH_WHITE,
                COLORS.MAGENTA_GRAY
            ]
        };

        /**
         * Returns a random color from the palette.
         *
         * @return
         */
        public static function getRandomColor(): int {
            var keys: Array = [];
            for (var key: String in COLORS) {
                keys.push(key);
            }

            return COLORS[keys[int(Math.random() * keys.length)]];
        }

    }

}
