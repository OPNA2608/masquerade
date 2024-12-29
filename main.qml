import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ApplicationWindow {
  id: main
  title: "Masquerade"
  minimumWidth: 400
  minimumHeight: minimumWidth
  visible: true

  property url selectedImage: ""
  property Component nextPage: coordsSelectionComponent

  DragTargets {}

  StackView {
    id: pageStack
    initialItem: imageSelectionComponent
    anchors.fill: parent

    onDepthChanged: {
      pageBackButton.enabled = depth != 1
      pageForwardButton.enabled = false
    }
  }

  Component {
    id: imageSelectionComponent

    Page {
      id: imageSelectionPage

      Image {
        id: imageSelectionDisplay
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: main.selectedImage

        Text {
          id: imagePlaceholder
          text: "Click to select an image"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          visible: true
        }

        onSourceChanged: {
          imagePlaceholder.visible = (source == "")
          pageForwardButton.enabled = (source != "")
        }

        onVisibleChanged: {
          if (visible) {
            imagePlaceholder.visible = (source == "")
            pageForwardButton.enabled = (source != "")
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: imageBrowser.open()
        }
      }

      FileDialog {
        id: imageBrowser
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        onAccepted: main.selectedImage = selectedFile
      }

      onVisibleChanged: {
        if (visible) {
          main.nextPage = coordsSelectionComponent
        }
      }
    }
  }

  Component {
    id: coordsSelectionComponent

    Page {
      id: coordsSelectionPage

      Item {
        anchors.fill: parent

        Item {
          id: coordsSelectionData
          property real selectionRectX: 0
          property real selectionRectY: 0
          property real selectionRectWidth: 200
          property real selectionRectHeight: 200
        }

        Image {
          id: coordsSelectionBackground
          anchors.fill: parent
          fillMode: Image.PreserveAspectFit
          source: main.selectedImage
          z: 5

          Binding {
            coordsSelectionData.selectionRectX: (coordsSelectionBackground.width - coordsSelectionBackground.paintedWidth) / 2
            coordsSelectionData.selectionRectY: (coordsSelectionBackground.height - coordsSelectionBackground.paintedHeight) / 2
          }

          Canvas {
            id: coordsSelectionCanvas
            anchors.fill: parent
            z: coordsSelectionBackground.z + 1

            onPaint: {
              var ctx = getContext("2d")

              ctx.clearRect(x, y, width, height)

              ctx.fillStyle = Qt.rgba(0, 0, 0, 0.3)
              ctx.fillRect(x, y, width, height)

              ctx.clearRect(
                coordsSelectionData.selectionRectX,
                coordsSelectionData.selectionRectY,
                coordsSelectionData.selectionRectWidth,
                coordsSelectionData.selectionRectHeight
              )

              ctx.stroke()
            }
          }

          onPaintedWidthChanged: coordsSelectionCanvas.requestPaint()
          onPaintedHeightChanged: coordsSelectionCanvas.requestPaint()

          MouseArea {
            anchors.fill: parent
            z: coordsSelectionCanvas.z + 1

            property int dragTarget: DragTargets.Target.None
            property real dragX: 0
            property real dragY: 0

            onPressed: function (mouse) {
              console.log("onPressed")

              if (mouse.button == Qt.LeftButton) {
                console.log("left-press detected")
                var mouseMargin = 10

                if (
                  (coordsSelectionData.selectionRectX - mouseMargin < mouse.x) &&
                  (coordsSelectionData.selectionRectX + mouseMargin > mouse.x) &&
                  (coordsSelectionData.selectionRectY - mouseMargin < mouse.y) &&
                  (coordsSelectionData.selectionRectY + mouseMargin > mouse.y)
                ) {
                  dragTarget = DragTargets.Target.TopLeft
                } else if (
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) - mouseMargin < mouse.x) &&
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) + mouseMargin > mouse.x) &&
                  (coordsSelectionData.selectionRectY - mouseMargin < mouse.y) &&
                  (coordsSelectionData.selectionRectY + mouseMargin > mouse.y)
                ) {
                  dragTarget = DragTargets.Target.TopRight
                } else if (
                  (coordsSelectionData.selectionRectX - mouseMargin < mouse.x) &&
                  (coordsSelectionData.selectionRectX + mouseMargin > mouse.x) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) - mouseMargin < mouse.y) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) + mouseMargin > mouse.y)
                ) {
                  dragTarget = DragTargets.Target.BottomLeft
                } else if (
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) - mouseMargin < mouse.x) &&
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) + mouseMargin > mouse.x) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) - mouseMargin < mouse.y) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) + mouseMargin > mouse.y)
                ) {
                  dragTarget = DragTargets.Target.BottomRight
                } else
                {
                  dragTarget = DragTargets.Target.Center
                }

                dragX = mouse.x
                dragY = mouse.y
                console.log(dragTarget + " target detected, dragging started")
              }
            }

            onPositionChanged: function (mouse) {
              console.info("onPositionChanged")

              if (dragTarget != DragTargets.Target.None) {
                console.info("in drag handling")

                const diffX = mouse.x - dragX
                const diffY = mouse.y - dragY

                if (dragTarget == DragTargets.Target.TopLeft) {
                  coordsSelectionData.selectionRectX += diffX
                  coordsSelectionData.selectionRectWidth -= diffX
                  coordsSelectionData.selectionRectY += diffY
                  coordsSelectionData.selectionRectHeight -= diffY
                } else if (dragTarget == DragTargets.Target.TopRight) {
                  coordsSelectionData.selectionRectWidth += diffX
                  coordsSelectionData.selectionRectY += diffY
                  coordsSelectionData.selectionRectHeight -= diffY
                } else if (dragTarget == DragTargets.Target.BottomLeft) {
                  coordsSelectionData.selectionRectX += diffX
                  coordsSelectionData.selectionRectWidth -= diffX
                  coordsSelectionData.selectionRectHeight += diffY
                } else if (dragTarget == DragTargets.Target.BottomRight) {
                  coordsSelectionData.selectionRectWidth += diffX
                  coordsSelectionData.selectionRectHeight += diffY
                } else {
                  coordsSelectionData.selectionRectX += diffX
                  coordsSelectionData.selectionRectY += diffY
                }

                dragX = mouse.x
                dragY = mouse.y
                coordsSelectionCanvas.requestPaint()
              }
            }

            onReleased: function (mouse) {
              console.log("onReleased")

              if (mouse.button == Qt.LeftButton) {
                dragTarget = DragTargets.Target.None
                dragX = 0
                dragY = 0
              }
            }
          }
        }
      }

      onVisibleChanged: {
        if (visible) {
          main.nextPage = null
        }
      }
    }
  }

  header: ToolBar {
    RowLayout {
      anchors.fill: parent

      Button {
        id: pageBackButton
        text: "<"
        enabled: false
        onClicked: pageStack.pop()
      }

      Item {
        id: toolbarButtonSpacer
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      Button {
        id: pageForwardButton
        text: ">"
        enabled: false
        onClicked: pageStack.pushItem(main.nextPage)
      }
    }
  }
}
