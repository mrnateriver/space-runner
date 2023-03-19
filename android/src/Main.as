/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package {

    import flash.display.Screen;

    import support.ScreenSetup;

    [SWF(width="640", height="960", frameRate="60")]
    public class Main extends Entry {

        public function Main() {
            super(new ScreenSetup(stage.fullScreenWidth - Screen.mainScreen.visibleBounds.x,
                                  stage.fullScreenHeight - Screen.mainScreen.visibleBounds.y,
                                  [1, 2, 3]));
        }

    }

}
