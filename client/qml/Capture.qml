import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import QtMultimedia 5.0
import Sailfish.Media 1.0
import Sailfish.Gallery 1.0
import com.jolla.camera 1.0
import org.nemomobile.time 1.0
import org.nemomobile.thumbnailer 1.0

Dialog {
    id: page
    objectName: "capture"
    allowedOrientations: Orientation.Portrait | Orientation.Landscape
    canNavigateForward: canAccept
    canAccept: false

    property string imagePath: ""

    property bool broadcastMode: true

    property alias cameraState: camera.cameraState

    property int _recordingDuration: ((clock.enabled ? clock.time : page._endTime) - page._startTime) / 1000
    property var _startTime: new Date()
    property var _endTime: _startTime

    function _captureHandler() {
        console.log("Capture saved to", imagePath)
        page.canAccept = true
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            if (camera.cameraState != Camera.UnloadedState) {
                console.log("deactivating camera")
                camera.cameraState = Camera.UnloadedState
            }
        }
        else if (status == PageStatus.Active && !canAccept) {
            console.log("activating camera")
            camera.cameraState = Camera.ActiveState
        }
    }

    onRejected: {
        console.log("capture rejected")
        Mitakuuluu.rejectMediaCapture(imagePath)
    }

    Component.onDestruction: {
        if (camera.cameraState != Camera.UnloadedState) {
            console.log("camera destruction")
            camera.cameraState = Camera.UnloadedState
        }
    }

    Rectangle {
        anchors.fill: header
        z: 1
        color: Theme.rgba(Theme.highlightColor, 0.2)
    }

    DialogHeader {
        id: header
        z: 1
        title: page.canAccept ? qsTr("Send", "Capture page send title")
                              : qsTr("Camera", "Capture page default title")
    }

    GStreamerVideoOutput {
        id:mPreview
        x:0
        y:0
        anchors.fill: parent
        orientation: page.orientation == Orientation.Portrait ? 0 : 90
        visible: !page.canAccept

        source: camera
    }

    Camera {
        id: camera

        // Set this to Camera.ActiveState to load, and Camera.UnloadedState to unload.
        //cameraState: Camera.ActiveState

        // Options are Camera.CaptureStillImage or Camera.CaptureVideo
        captureMode: Camera.CaptureStillImage

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }
        flash.mode: Camera.FlashAuto

        imageCapture {
            resolution: extensions.viewfinderResolution

            onImageCaptured:{
            }

            // Called when the image is saved.
            onImageSaved: {
                camera.cameraState = Camera.UnloadedState
                imagePath = path
                _captureHandler()
            }

            // Called when a capture fails for some reason.
            onCaptureFailed: {
                console.log("Capture failed")
            }
        }

        videoRecorder{
            resolution: extensions.viewfinderResolution
            frameRate: 30
            audioChannels: 2
            audioSampleRate: 48000
            audioCodec: "audio/mpeg, mpegversion=(int)4"
            videoCodec: "video/mpeg, mpegversion=(int)4"
            mediaContainer: "video/quicktime, variant=(string)iso"
        }

        // This will tell us when focus lock is gained.
        onLockStatusChanged: {
            if (lockStatus == Camera.Locked) {
                console.log("locked")
                if (shutter.autoMode)
                    camera.imageCapture.capture()
            }
        }

        function _finishRecording() {
            console.log("recording state: " + videoRecorder.recorderState)
            if (videoRecorder.recorderState == CameraRecorder.StoppedState) {
                console.log("finish recordig")
                videoRecorder.recorderStateChanged.disconnect(_finishRecording)
                camera.cameraState = Camera.UnloadedState
                imagePath = videoRecorder.outputLocation
                _captureHandler()
            }
        }

    }

    CameraExtensions {
        id: extensions
        camera: camera

        device: "primary"
        viewfinderResolution: "1280x720"

        onViewfinderResolutionChanged: reloadTimer.unload()
        onDeviceChanged: reloadTimer.unload()

        manufacturer: "Jolla"
        model: "Jolla"

        rotation: {
            switch (page.orientation) {
            case Orientation.Portrait:
                return 0
            case Orientation.Landscape:
                return 90
            case Orientation.PortraitInverted:
                return 180
            case Orientation.LandscapeInverted:
                return 270
            }
        }
    }

    Loader {
        id: previewLoader
        anchors.fill: parent
        active: page.canAccept
        sourceComponent: camera.captureMode == Camera.CaptureStillImage ? imagePreviewComponent : videoPreviewComponent
    }

    Component {
        id: imagePreviewComponent
        ImageViewer {
            id: prev
            source: imagePath
            visible: page.canAccept
        }
    }

    Component {
        id: videoPreviewComponent
        Thumbnail {
            fillMode: Image.PreserveAspectFit
            source: imagePath
            sourceSize.width: width
            sourceSize.height: height
            clip: true
            smooth: true
            mimeType: "video/quicktime"
        }
    }

    /*Rectangle {
        id: cameraModeButton
        width: Theme.itemSizeMedium
        height: width
        radius: width / 2
        color: cameraModeArea.pressed ? Theme.highlightColor : Theme.secondaryHighlightColor
        anchors.left: parent.left
        anchors.top: header.bottom
        anchors.margins: Theme.paddingSmall
        visible: !page.canAccept

        Image {
            id: cameraModeSource
            source: camera.captureMode == Camera.CaptureStillImage ? "image://theme/icon-camera-camera-mode"
                                                                   : "image://theme/icon-camera-video"
            anchors.centerIn: parent
            property bool flash: true
        }

        MouseArea {
            id: cameraModeArea
            anchors.fill: parent
            onClicked: {
                if (camera.captureMode == Camera.CaptureStillImage) {
                    camera.captureMode = Camera.CaptureVideo
                    extensions.viewfinderResolution = "640x480"
                }
                else {
                    camera.captureMode = Camera.CaptureStillImage
                    extensions.viewfinderResolution = "1280x720"
                }
            }
        }
    }*/

    Rectangle {
        id: cameraSourceButton
        width: Theme.itemSizeMedium
        height: width
        radius: width / 2
        color: cameraSourceArea.pressed ? Theme.highlightColor : Theme.secondaryHighlightColor
        anchors.right: parent.right
        anchors.bottom: flashButton.top
        anchors.margins: Theme.paddingSmall
        visible: !page.canAccept

        Image {
            id: cameraSource
            source: "image://theme/icon-camera-front-camera"
            anchors.centerIn: parent
            property bool flash: true
        }

        MouseArea {
            id: cameraSourceArea
            anchors.fill: parent
            onClicked: {
                if (extensions.device == "primary") {
                    extensions.device = "secondary"
                }
                else {
                    extensions.device = "primary"
                }
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 10
        function unload() {
            camera.cameraState = Camera.UnloadedState
            start()
        }
        onTriggered: camera.cameraState = Camera.ActiveState
    }

    Item {
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: Theme.paddingSmall
        width: timerLabel.implicitWidth + (2 * Theme.paddingMedium)
        height: timerLabel.implicitHeight + (2 * Theme.paddingSmall)
        opacity: camera.captureMode == Camera.CaptureVideo ? 1 : 0
        Behavior on opacity { FadeAnimation {} }

        Rectangle {
            radius: Theme.paddingSmall / 2

            anchors.fill: parent
            color: Theme.highlightBackgroundColor
            opacity: 0.6
        }
        Label {
            id: timerLabel

            anchors.centerIn: parent

            text: Format.formatDuration(
                      page._recordingDuration,
                      page._recordingDuration >= 3600 ? Formatter.DurationLong : Formatter.DurationShort)
            font.pixelSize: Theme.fontSizeMedium

        }

        WallClock {
            id: clock
            updateFrequency: WallClock.Second
            enabled: camera.videoRecorder.recorderState == CameraRecorder.RecordingState
            onEnabledChanged: {
                if (enabled) {
                    page._startTime = clock.time
                    page._endTime = page._startTime
                } else {
                    page._endTime = page._startTime
                }
            }
        }
    }

    Rectangle {
        id: flashButton
        width: Theme.itemSizeMedium
        height: width
        radius: width / 2
        color: flashModeArea.pressed ? Theme.highlightColor : Theme.secondaryHighlightColor
        anchors.right: parent.right
        anchors.bottom: captureButton.top
        anchors.margins: Theme.paddingSmall
        visible: !page.canAccept

        Image {
            id: flashMode
            source: flashModeIcon(camera.flash.mode)
            anchors.centerIn: parent
            property bool flash: true

            function flashModeIcon(mode) {
                switch (mode) {
                case Camera.FlashAuto:
                    return "image://theme/icon-camera-flash-automatic"
                case Camera.FlashOff:
                    return "image://theme/icon-camera-flash-off"
                default:
                    return "image://theme/icon-camera-flash-on"
                }
            }

            function nextFlashMode(mode) {
                switch (mode) {
                case Camera.FlashAuto:
                    return Camera.FlashOff
                case Camera.FlashOff:
                    return Camera.FlashOn
                case Camera.FlashOn:
                    return Camera.FlashAuto
                default:
                    return Camera.FlashOff
                }
            }
        }

        MouseArea {
            id: flashModeArea
            anchors.fill: parent
            onClicked: camera.flash.mode = flashMode.nextFlashMode(camera.flash.mode)
        }
    }

    Rectangle {
        id: captureButton
        width: Theme.itemSizeMedium
        height: width
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.paddingSmall
        radius: width / 2
        color: shutterArea.pressed ? Theme.highlightColor : Theme.secondaryHighlightColor
        visible: !page.canAccept

        Image {
            id: shutter
            source: camera.captureMode == Camera.CaptureStillImage ? "image://theme/icon-camera-shutter-release"
                                                                   : (camera.videoRecorder.recorderState == CameraRecorder.StoppedState ? "image://theme/icon-camera-record"
                                                                                                                                        : "image://theme/icon-camera-stop")
            anchors.centerIn: parent
            property bool autoMode: false
        }

        MouseArea {
            id: shutterArea
            anchors.fill: parent
            onPressed: {
                if (camera.captureMode == Camera.CaptureStillImage) {
                    console.log("shutter pressed")
                    shutter.autoMode = false
                    if (camera.captureMode == Camera.CaptureStillImage
                            && camera.lockStatus == Camera.Unlocked) {
                        camera.searchAndLock()
                    }
                }
            }
            onReleased: {
                if (camera.captureMode == Camera.CaptureStillImage) {
                    console.log("shutter released")
                    shutter.autoMode = false
                    if (camera.lockStatus == Camera.Locked) {
                        extensions.captureTime = new Date()
                        camera.imageCapture.capture()
                    }
                }
            }
            onClicked: {
                if (camera.videoRecorder.recorderState == CameraRecorder.RecordingState) {
                    camera.videoRecorder.stop()
                } else if (camera.captureMode == Camera.CaptureStillImage) {

                    console.log("shutter clicked")
                    shutter.autoMode = true

                    extensions.captureTime = new Date()

                    camera.imageCapture.capture()
                } else {
                    extensions.captureTime = new Date()
                    camera.videoRecorder.record()
                    if (camera.videoRecorder.recorderState == CameraRecorder.RecordingState) {
                        camera.videoRecorder.recorderStateChanged.connect(camera._finishRecording)
                    }
                }
            }
        }
    }
}
