fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

| Method                     | OS support                              | Description                                                                                                                           |
|----------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| [Homebrew](http://brew.sh) | macOS                                   | `brew cask install fastlane`                                                                                                          |
| Installer Script           | macOS                                   | [Download the zip file](https://download.fastlane.tools). Then double click on the `install` script (or run it in a terminal window). |
| RubyGems                   | macOS or Linux with Ruby 2.0.0 or above | `sudo gem install fastlane -NV`                                                                                                       |

# Available Actions
### travis
```
fastlane travis
```
Perform the build steps on travis CI
### macOS
```
fastlane macOS
```
Build Freddy for macOS
### iOS
```
fastlane iOS
```
Build Freddy for iOS
### tvOS
```
fastlane tvOS
```
Build Freddy for tvOS
### validate_cocoapods
```
fastlane validate_cocoapods
```
Validate cocoapods podspec file
### validate_carthage
```
fastlane validate_carthage
```
Validate carthage build
### create_docs
```
fastlane create_docs
```
Create docs

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
