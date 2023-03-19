/*
 * Copyright (c) 2019 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package stages.screens {
    import objects.Player;
    import objects.RenderedPlanet;
    import objects.ui.Button;

    import stages.Gameplay;

    import starling.display.Image;
    import starling.display.Sprite;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.textures.Texture;
    import starling.utils.Align;

    import support.PlanetGenerator;
    import support.Strings;
    import support.drawing.TextureGenerator;
    import support.objects.GameObject;

    public class TutorialScreen extends GameObject {

        public static const EVENT_CONTINUE_CLICKED: String = "tutorial_continue_button_clicked";

        private var _shadeTexture: Texture;

        public function TutorialScreen() {
            super();
        }

        override protected function init(): void {
            const strings: Object = Strings.getStrings();

            _shadeTexture = Texture.fromColor(2, 2, 0, 0.7);

            const shade: Image = new Image(_shadeTexture);
            shade.width = stage.stageWidth;
            shade.height = stage.stageHeight;
            addChild(shade);

            const planetsContainer: Sprite = new Sprite();

            // bottom planet
            const bottomPlanet: RenderedPlanet = PlanetGenerator.generate(Gameplay.MIN_PLANET_MASS,
                                                                          Gameplay.MIN_PLANET_RADIUS + 15);
            bottomPlanet.x = stage.stageWidth / 4 + 30;
            bottomPlanet.y = stage.stageHeight - stage.stageHeight / 4 - 10;
            planetsContainer.addChild(bottomPlanet);

            // upper planet
            const upperPlanet: RenderedPlanet = PlanetGenerator.generate(Gameplay.MAX_PLANET_MASS,
                                                                         Gameplay.MAX_PLANET_RADIUS / 2);
            upperPlanet.x = stage.stageWidth - stage.stageWidth / 4 - 30;
            upperPlanet.y = stage.stageHeight / 4 + 10;
            planetsContainer.addChild(upperPlanet);
            upperPlanet.outline = true;
            // Starling.current.juggler.add(upperPlanet);

            // player with trail
            const player: Player = new Player(true);
            player.x = bottomPlanet.x - bottomPlanet.radius - 20;
            player.y = bottomPlanet.y - bottomPlanet.radius - 20;
            player.rotation = -Math.PI / 4 + 0.18;

            const dash: Texture = TextureGenerator.createDashedLine(4,
                                                                    stage.stageHeight,
                                                                    Director.MAIN_BROWNISH_FONT_COLOR,
                                                                    0.8);
            const line: Image = new Image(dash);
            line.pivotX = 0;
            line.pivotY = 2;
            line.x = player.x;
            line.y = player.y;
            line.rotation = player.rotation;

            planetsContainer.addChild(line);
            planetsContainer.addChild(player);

            addChild(planetsContainer);

            player.mode = Player.MODE_ACCELERATING;

            /*planetsContainer.pivotX = line.x + (upperPlanet.x - bottomPlanet.x) / 2;
             planetsContainer.pivotY = line.y - (bottomPlanet.y - upperPlanet.y) / 2;
             planetsContainer.x = stage.stageWidth / 2;
             planetsContainer.y = stage.stageHeight / 2;*/

            const uiContainer: Sprite = new Sprite();
            const that: TutorialScreen = this;

            // BRIEFING
            const thirdOfHeight: Number = stage.stageHeight / 3;

            const font: String = Strings.getFont();

            const upperHelpText: TextField = new TextField(stage.stageWidth / 2 - 30,
                                                           thirdOfHeight,
                                                           strings.BRIEFING_LEFT_ADVICE_TEXT);
            upperHelpText.format.setTo(font, 40, 0xffffff, Align.RIGHT, Align.BOTTOM);
            upperHelpText.isHtmlText = true;
            upperHelpText.autoScale = true;
            upperHelpText.wordWrap = true;
            upperHelpText.alignPivot(Align.RIGHT, Align.BOTTOM);
            upperHelpText.x = stage.stageWidth / 2 - 15;
            upperHelpText.y = stage.stageHeight / 2 - 15;
            uiContainer.addChild(upperHelpText);

            const bottomHelpText: TextField = new TextField(stage.stageWidth / 2 - 30, thirdOfHeight,
                                                            "<font color=\"#ff8888\">" + strings.BRIEFING_RIGHT_ADVICE_TITLE + "</font><font size=\"-10\">\n" + strings.BRIEFING_RIGHT_ADVICE_TEXT + "</font>");
            bottomHelpText.format.setTo(font, 40, 0xffffff, Align.LEFT, Align.TOP);
            bottomHelpText.isHtmlText = true;
            bottomHelpText.autoScale = true;
            bottomHelpText.wordWrap = true;
            bottomHelpText.alignPivot(Align.LEFT, Align.TOP);
            bottomHelpText.x = stage.stageWidth / 2 + 15;
            bottomHelpText.y = stage.stageHeight / 2 + 15;
            uiContainer.addChild(bottomHelpText);

            const titleHeight: Number = Math.min(upperHelpText.y - upperHelpText.textBounds.height,
                                                 upperPlanet.y - upperPlanet.radius);
            const screenTitle: TextField = new TextField(250, titleHeight, strings.BRIEFING_TITLE);
            screenTitle.format.setTo(font, 80, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.CENTER);
            screenTitle.autoScale = true;
            screenTitle.alignPivot(Align.CENTER, Align.TOP);
            screenTitle.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            screenTitle.x = stage.stageWidth / 2;
            screenTitle.y = 0;
            uiContainer.addChild(screenTitle);

            const proceedLabel: TextField = new TextField(120, 60, strings.BRIEFING_OK_BUTTON_LABEL);
            proceedLabel.format.setTo(font, 60, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            proceedLabel.autoScale = true;
            proceedLabel.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            proceedLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            const continueButton: Button = new Button(proceedLabel, Director.MAIN_BROWNISH_FONT_COLOR);
            continueButton.alignPivot();
            continueButton.x = stage.stageWidth / 2;
            continueButton.y = stage.stageHeight - 70;

            continueButton.addEventListener(Button.EVENT_CLICKED, function (): void {
                that.dispatchEventWith(EVENT_CONTINUE_CLICKED);
            });

            uiContainer.addChild(continueButton);

            addChild(uiContainer);
        }

        override public function dispose(): void {
            _shadeTexture.dispose();
            super.dispose();
        }

    }

}
