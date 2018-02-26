# kubrick

kubrick is a library written in swift that takes a protocol oriented approach to interfacing with media devices.

Currently it only supports AVFoundation without support for DAL inputs.

HAL devices do currently work on both macOS and iOS (I've tested with a Zoom H6 on an iPhone connected via a photo card input).

There is planned support for Video 4 Linux devices.

kubrick also provides a very basic generic Sink mechanism for building media processing pipelines.  A handful of sinks are included in the library to make it useful out of the box

For more information about protocol oriented programming, you can reference [this talk](https://developer.apple.com/videos/play/wwdc2015/408/).
