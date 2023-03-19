/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package {

    import support.ScreenSetup;

    [SWF(width="614", height="836", frameRate="60")]
    public class Main extends Entry {

        public function Main() {
            super(new ScreenSetup(stage.stageWidth, stage.stageHeight, [1, 2, 3]));
        }

    }

}
