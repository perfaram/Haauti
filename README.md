# Haauti

Haauti is a W.I.P macOS client for Jodel.

## Build

Run `pod install`, and fetch a copy to ./Libs/[PullRefreshableScrollView](https://github.com/perfaram/PullRefreshableScrollView). In the `./Libs` directory, you'll find a modified (made to support determinate progress levels), stripped down version of [ProgressKit](https://github.com/kaunteya/ProgressKit). You needn't change anything to it.

Then open the `.xcworkspace` in XCode and hit run. It *may* work.

## Features

Haauti currently displays the last Jodels in your area, allows you to set an artificial geographical position for Jodel or to just let it follow your actual position. It is mostly read-only (the only "write" action it performs is creating an account – not activating it, just creating it, for you to read the Jodels). It also displays the karma. More features are likely to come, the first one being actual error reporting.

## It doesn't work !
Likely some encryption key issues. I won't go over on how to fix these, as I don't think Jodel would like it. There are, however, more than enough resources here on Github about this. For reference, the Jodel keys are located in the `JodelAPISettings` class (in this project). 

## Why "_Haauti_" ?
It's how a link to [this](https://www.youtube.com/watch?v=vQhqikWnQCU) video is labeled in the (Android, at least) Jodel app : _Jodelhaaaaauuutiiii_. I stripped _Jodel_ and also some of the redundant letters.

## Great resources
https://github.com/AsamK/JodelJS
https://github.com/nborrmann/jodel_api

--------
###### Published in the hope that it will be useful