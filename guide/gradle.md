
## Initialize gradle project

Note that this step is already done for this repository, and this section is purely informative. It is long series of manual steps required to build a project from scratch. For our code however we completely ignore this, and just use `SDL/android_project` from SDL repo.

(note to self)  
ADAPTED FROM  
https://developer.okta.com/blog/2018/08/10/basic-android-without-an-ide


Let's start by creating gradle project next to our dub project.

choose the defaults when prompted (basic project, groovy dsl, default name)
```sh
  gradle init
```

edit `settings.gradle` file and add this line
```groovy
  include ':app'
```

edit `build.gradle` and use the following content
```groovy
buildscript {

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:3.1.3'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
```

create `app` folder and `app/build.gradle` with following content
```groovy
def buildAsLibrary = project.hasProperty('BUILD_AS_LIBRARY')
def buildAsApplication = !buildAsLibrary
if (buildAsApplication) {
    apply plugin: 'com.android.application'
}
else {
    apply plugin: 'com.android.library'
}

android {
    compileSdkVersion 30
    defaultConfig {
        if (buildAsApplication) {
            applicationId "org.libsdl.app"
        }
        minSdkVersion 21
        targetSdkVersion 30
        versionCode 1
        versionName "1.0"

        // This is used in APK build process, use this to control what supported platforms
        ndk {
            // Specifies the ABI configurations of your native
            // libraries Gradle should build and package with your APK.
            abiFilters 'arm64-v8a' 
            // possible variants:
            //abiFilters 'arm64-v8a', 'x86', 'x86_64', 'armeabi', 'armeabi-v7a'
        }
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
        debug {
            debuggable true
            packagingOptions {
                doNotStrip '**/*.so'
            }
        }
    }
    if (!project.hasProperty('EXCLUDE_NATIVE_LIBS')) {
        // This will tell gradle to pack app/libs folder with our libraries
        sourceSets.main {
            jniLibs.srcDir 'libs'
        }
    }
    lintOptions {
        abortOnError false
    }
    
    if (buildAsLibrary) {
        libraryVariants.all { variant ->
            variant.outputs.each { output ->
                def outputFile = output.outputFile
                if (outputFile != null && outputFile.name.endsWith(".aar")) {
                    def fileName = "org.libsdl.app.aar"
                    output.outputFile = new File(outputFile.parent, fileName)
                }
            }
        }
    }
}

dependencies {
    implementation fileTree(include: ['*.jar'], dir: 'libs')
}

```

create `app/src/main/res/values/styles.xml` file with content
```xml
<resources>

    <!-- Base application theme. -->
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <!-- Customize your theme here. -->
    </style>

</resources>
```

create `app/src/main/AndroidManifest.xml` file with content
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">

    <application
        android:label="Demo App"
        android:theme="@style/AppTheme">

        <activity android:name="SDLActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```