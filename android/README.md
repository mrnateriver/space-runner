## Splash screen
To display the native splash screen before launching AIR, you need to make changes to the file `AIRSDK/lib/android/lib/resources/app_entry/res/values/styles.xml`:

```xml
<resources>
    <style name="Theme.NoShadow" parent="android:style/Theme.NoTitleBar">
        <!-- <item name="android:windowContentOverlay">@null</item> -->
        <item name="android:windowBackground">@drawable/splash_background</item>
    </style>
</resources>
``` 

Next, you need to copy the file from the project android/system/splash.png to the directory AIRSDK/lib/android/lib/resources/app_entry/res/drawable and create a file splash_background.xml next to it:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:src="@drawable/splash" />
    </item>
</layer-list>
```
