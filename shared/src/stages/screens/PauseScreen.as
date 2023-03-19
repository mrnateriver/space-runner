/*
 * Copyright (c) 2018 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package stages.screens {
    import objects.ui.Button;

    import starling.display.Image;
    import starling.display.Sprite;
    import starling.extensions.ColorArgb;
    import starling.filters.DropShadowFilter;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.textures.Texture;
    import starling.utils.Align;

    import support.Strings;

    import support.drawing.TextureGenerator;
    import support.objects.GameObject;

    public class PauseScreen extends GameObject {

        public static const EVENT_CONTINUE_CLICKED: String = "continue_button_clicked";
        public static const EVENT_MAIN_MENU_CLICKED: String = "main_menu_button_clicked";

        private var _shadeTexture: Texture;
        private var _starTexture: Texture;
        private var _score: Number;

        public function PauseScreen(score: Number) {
            super();
            _score = score;
        }

        override protected function init(): void {
            _shadeTexture = Texture.fromColor(2, 2, 0, 0.7);

            const shade: Image = new Image(_shadeTexture);
            shade.width = stage.stageWidth;
            shade.height = stage.stageHeight;
            addChild(shade);

            const uiContainer: Sprite = new Sprite();

            const strings: Object = Strings.getStrings();
            const font: String = Strings.getFont();

            const title: TextField = new TextField(stage.stageWidth - 40, 120, strings.PAUSE_TITLE);
            title.format.setTo(font, 90, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.CENTER);
            title.autoScale = true;
            title.batchable = true;
            title.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);
            title.alignPivot(Align.CENTER, Align.TOP);

            title.y = 0;
            title.x = stage.stageWidth / 2;
            uiContainer.addChild(title);

            //region Game points
            const scoreContainer: Sprite = new Sprite();

            _starTexture = TextureGenerator.createStarIcon(ColorArgb.fromArgb(0xffed9c2e), 70);
            const scoreIcon: Image = new Image(_starTexture);
            scoreIcon.alignPivot();
            scoreIcon.filter = new DropShadowFilter();

            scoreIcon.x = 0;
            scoreIcon.y = 53;
            scoreContainer.addChild(scoreIcon);

            const scoreText: TextField = new TextField(100, 90, _score.toString());
            scoreText.format.setTo(font, 90 * Strings.getFontSizeMultiplier(), 0xffffff, Align.LEFT, Align.TOP);
            scoreText.batchable = true;
            scoreText.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            scoreText.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            scoreText.x = 60;
            scoreText.y = 0;
            scoreContainer.addChild(scoreText);

            scoreContainer.x = stage.stageWidth / 2 - (60 + scoreText.textBounds.width) / 2;
            scoreContainer.y = title.height + 20;
            uiContainer.addChild(scoreContainer);
            //endregion

            //region Buttons
            const proceedLabel: TextField = new TextField(120, 60, strings.PAUSE_CONTINUE_BUTTON_LABEL);
            proceedLabel.format.setTo(font, 60, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            proceedLabel.autoScale = true;
            proceedLabel.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            proceedLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            const backToMenuLabel: TextField = new TextField(120, 60, strings.PAUSE_BACK_TO_MAIN_MENU_BUTTON_LABEL);
            backToMenuLabel.format.setTo(font, 60, Director.MAIN_BROWNISH_FONT_COLOR, Align.CENTER, Align.TOP);
            backToMenuLabel.batchable = true;
            backToMenuLabel.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
            backToMenuLabel.filter = new DropShadowFilter(4.0, 0.785, 0x0, 1);

            const buttonsContainer: Sprite = new Sprite();

            const proceedButton: Button = new Button(proceedLabel, Director.MAIN_BROWNISH_FONT_COLOR);
            proceedButton.alignPivot(Align.CENTER, Align.TOP);
            proceedButton.x = 0;
            proceedButton.y = 0;
            buttonsContainer.addChild(proceedButton);

            const that: PauseScreen = this;
            proceedButton.addEventListener(Button.EVENT_CLICKED, function (): void {
                director.hideBanner();
                that.dispatchEventWith(EVENT_CONTINUE_CLICKED);
            });

            const backToMenuButton: Button = new Button(backToMenuLabel, Director.MAIN_BROWNISH_FONT_COLOR);
            backToMenuButton.alignPivot(Align.CENTER, Align.TOP);
            backToMenuButton.x = 0;
            backToMenuButton.y = proceedButton.height + 10;
            buttonsContainer.addChild(backToMenuButton);

            backToMenuButton.addEventListener(Button.EVENT_CLICKED, function (): void {
                director.hideBanner();
                that.dispatchEventWith(EVENT_MAIN_MENU_CLICKED);
            });

            buttonsContainer.x = stage.stageWidth / 2;
            buttonsContainer.y = title.height + 10 + scoreContainer.height + 40;
            uiContainer.addChild(buttonsContainer);
            //endregion

            uiContainer.y = stage.stageHeight / 2 - uiContainer.height / 2 + 30 - 50;
            addChild(uiContainer);

            director.showBanner(function (): void {
            });
        }

        override public function dispose(): void {
            _shadeTexture.dispose();
            _starTexture.dispose();
            super.dispose();
        }

    }

}
