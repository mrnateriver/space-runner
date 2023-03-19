/*
 * Copyright (c) 2020 Evgenii Dobrovidov.
 * Working name of the project: "space-runner".
 * All rights reserved.
 */

package support {
    import flash.system.Capabilities;

    public class Strings {
        protected static const localized: Object = {
            en: {
                MAIN_MENU_TITLE: 'GRAVITY VOYAGE',
                MAIN_MENU_START_BUTTON_LABEL: 'START',
                BRIEFING_TITLE: 'BRIEFING',
                BRIEFING_LEFT_ADVICE_TEXT: '<font color=\"#88ff88\">Tap and hold</font> anywhere on the screen to accelerate the ship',
                BRIEFING_RIGHT_ADVICE_TITLE: 'You can\'t control its direction!',
                BRIEFING_RIGHT_ADVICE_TEXT: 'Travel from one orbit to another by accelerating at the right moment',
                BRIEFING_OK_BUTTON_LABEL: 'GOT IT!',
                PAUSE_TITLE: 'COSMOS PAUSED',
                PAUSE_CONTINUE_BUTTON_LABEL: 'CONTINUE',
                PAUSE_BACK_TO_MAIN_MENU_BUTTON_LABEL: 'MAIN MENU',
                GAMEPLAY_MENU_BUTTON_LABEL: 'MENU',
                GAMEPLAY_SPEED_LABEL: 'SPEED',
                GAMEPLAY_ABOUT_TO_LOSE_TITLE: 'Will be lost in space in:',
                GAMEOVER_TITLE: 'EXPLORATION ENDED',
                GAMEOVER_NEW_HIGHSCORE_TITLE: 'NEW HIGHSCORE!',
                GAMEOVER_OLD_HIGHSCORE_TITLE: 'HIGHSCORE:',
                GAMEOVER_BACK_TO_MENU_BUTTON_LABEL: 'MAIN MENU'
            },
            ru: {
                MAIN_MENU_TITLE: 'GRAVITY VOYAGE',
                MAIN_MENU_START_BUTTON_LABEL: 'ПОЕХАЛИ!',
                BRIEFING_TITLE: 'КУРС ПИЛОТА',
                BRIEFING_LEFT_ADVICE_TEXT: '<font color=\"#88ff88\">Нажмите и удерживайте</font> где угодно на экране для разгона корабля',
                BRIEFING_RIGHT_ADVICE_TITLE: 'Направлением движения управлять нельзя!',
                BRIEFING_RIGHT_ADVICE_TEXT: 'Переходите с орбиты на орбиту, вовремя ускоряя корабль',
                BRIEFING_OK_BUTTON_LABEL: 'ЯСНО!',
                PAUSE_TITLE: 'ПАУЗА',
                PAUSE_CONTINUE_BUTTON_LABEL: 'ПРОДОЛЖИТЬ',
                PAUSE_BACK_TO_MAIN_MENU_BUTTON_LABEL: 'НАЗАД В МЕНЮ',
                GAMEPLAY_MENU_BUTTON_LABEL: 'МЕНЮ',
                GAMEPLAY_SPEED_LABEL: 'СКОРОСТЬ',
                GAMEPLAY_ABOUT_TO_LOSE_TITLE: 'СВЯЗЬ БУДЕТ ПОТЕРЯНА ЧЕРЕЗ:',
                GAMEOVER_TITLE: 'СВЯЗЬ ПОТЕРЯНА',
                GAMEOVER_NEW_HIGHSCORE_TITLE: 'НОВЫЙ РЕКОРД!',
                GAMEOVER_OLD_HIGHSCORE_TITLE: 'РЕКОРД:',
                GAMEOVER_BACK_TO_MENU_BUTTON_LABEL: 'МЕНЮ'
            },
            zh: {
                // TODO: this is Google Translate'ed!
                MAIN_MENU_TITLE: '重力航行',
                MAIN_MENU_START_BUTTON_LABEL: '开始',
                BRIEFING_TITLE: '使用说明',
                BRIEFING_LEFT_ADVICE_TEXT: '<font color=\"#88ff88\">点击</font>并按住屏幕上的任意位置以加速飞船',
                BRIEFING_RIGHT_ADVICE_TITLE: '你无法控制它的方向!',
                BRIEFING_RIGHT_ADVICE_TEXT: '通过在适当的时刻加速来在行星之间旅行',
                BRIEFING_OK_BUTTON_LABEL: '我明白',
                PAUSE_TITLE: '停顿',
                PAUSE_CONTINUE_BUTTON_LABEL: '缵',
                PAUSE_BACK_TO_MAIN_MENU_BUTTON_LABEL: '走',
                GAMEPLAY_MENU_BUTTON_LABEL: '菜单',
                GAMEPLAY_SPEED_LABEL: '速',
                GAMEPLAY_ABOUT_TO_LOSE_TITLE: '会迷失在太空中:',
                GAMEOVER_TITLE: '勘探结束',
                GAMEOVER_NEW_HIGHSCORE_TITLE: '新高分!',
                GAMEOVER_OLD_HIGHSCORE_TITLE: '高分:',
                GAMEOVER_BACK_TO_MENU_BUTTON_LABEL: '走'
            }
        };

        protected static const fonts: Object = {
            en: 'LATIN_FONT',
            ru: 'CYRILLIC_FONT',
            zh: 'CHINESE_FONT'
        };

        public static function getLanguage(): String {
            const languages: Array = Capabilities.languages;
            if (languages.length < 1) {
                return 'en';
            }

            const lang: String = languages[0].split(/[^a-zA-Z]/)[0].toLowerCase();
            if (["en", "zh" /* chinese */, "ru"].indexOf(lang) >= 0) {
                return lang;
            } else {
                trace("System language '" + lang + "' not supported, returning EN");
                return "en";
            }
        }

        public static function getStrings(): Object {
            return Strings.localized[Strings.getLanguage()];
        }

        public static function getFont(): String {
            return Strings.fonts[Strings.getLanguage()];
        }

        public static function getFontSizeMultiplier(): Number {
            switch (Strings.getLanguage()) {
                case "ru":
                    return 0.64;
                default:
                    return 1;
            }
        }
    }
}
