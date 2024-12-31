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
  property Canvas selectedArea: Canvas {
    width: 200
    height: 200

    property real imageOffsetX: 0
    property real imageOffsetY: 0
    property real imageWidth: 1
    property real imageHeight: 1
  }

  property list<Component> pages: [
    imageSelectionComponent,
    coordsSelectionComponent,
    canvasDisplayComponent
  ]

  function printDebug (str) {
    //console.debug (str)
  }

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

        property string lastImage: ""

        Text {
          id: imagePlaceholder
          text: defaultText
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          visible: true

          property string defaultText: "Click to select an image"
          property string errorText: "Selected file was invalid, please try again"
        }

        onVisibleChanged: {
          if (visible) {
            imagePlaceholder.visible = (source == "")
            pageForwardButton.enabled = (source != "")
          }
        }

        onStatusChanged: {
          imagePlaceholder.visible = (status != Image.Ready)
          imagePlaceholder.text = (status == Image.Error) ? imagePlaceholder.errorText : imagePlaceholder.defaultText
          pageForwardButton.enabled = (status == Image.Ready)

          if (status == Image.Loading || (
            (status == Image.Ready) && (imageSelectionDisplay.source != lastImage) && (lastImage != "")
          )) {
            selectedArea.unloadImage (lastImage)
          }

          if (status == Image.Ready) {
            lastImage = imageSelectionDisplay.source
            selectedArea.loadImage (imageSelectionDisplay.source)
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: imageBrowser.open()
        }
      }

      FileDialog {
        id: imageBrowser
        fileMode: FileDialog.OpenFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        onAccepted: main.selectedImage = selectedFile
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
          property real selectionRectWidth: selectedArea.width
          property real selectionRectHeight: selectedArea.height

          property int dragTarget: DragTargets.Target.None
          property real dragStartX: 0
          property real dragStartY: 0

          property real dragPlusX: 0
          property real dragPlusY: 0
          property real dragPlusWidth: 0
          property real dragPlusHeight: 0
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
                coordsSelectionData.selectionRectX + coordsSelectionData.dragPlusX,
                coordsSelectionData.selectionRectY + coordsSelectionData.dragPlusY,
                coordsSelectionData.selectionRectWidth + coordsSelectionData.dragPlusWidth,
                coordsSelectionData.selectionRectHeight + coordsSelectionData.dragPlusHeight
              )

              ctx.stroke()
            }

            onPainted: {
              pageForwardButton.enabled = true
            }
          }

          onPaintedWidthChanged: coordsSelectionCanvas.requestPaint()
          onPaintedHeightChanged: coordsSelectionCanvas.requestPaint()

          MouseArea {
            anchors.fill: parent
            z: coordsSelectionCanvas.z + 1


            onPressed: function (mouse) {
              printDebug ("onPressed")

              if (mouse.button == Qt.LeftButton) {
                printDebug ("left-press detected")
                var mouseMargin = 10

                if (
                  (coordsSelectionData.selectionRectX - mouseMargin < mouse.x) &&
                  (coordsSelectionData.selectionRectX + mouseMargin > mouse.x) &&
                  (coordsSelectionData.selectionRectY - mouseMargin < mouse.y) &&
                  (coordsSelectionData.selectionRectY + mouseMargin > mouse.y)
                ) {
                  coordsSelectionData.dragTarget = DragTargets.Target.TopLeft
                } else if (
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) - mouseMargin < mouse.x) &&
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) + mouseMargin > mouse.x) &&
                  (coordsSelectionData.selectionRectY - mouseMargin < mouse.y) &&
                  (coordsSelectionData.selectionRectY + mouseMargin > mouse.y)
                ) {
                  coordsSelectionData.dragTarget = DragTargets.Target.TopRight
                } else if (
                  (coordsSelectionData.selectionRectX - mouseMargin < mouse.x) &&
                  (coordsSelectionData.selectionRectX + mouseMargin > mouse.x) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) - mouseMargin < mouse.y) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) + mouseMargin > mouse.y)
                ) {
                  coordsSelectionData.dragTarget = DragTargets.Target.BottomLeft
                } else if (
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) - mouseMargin < mouse.x) &&
                  ((coordsSelectionData.selectionRectX + coordsSelectionData.selectionRectWidth) + mouseMargin > mouse.x) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) - mouseMargin < mouse.y) &&
                  ((coordsSelectionData.selectionRectY + coordsSelectionData.selectionRectHeight) + mouseMargin > mouse.y)
                ) {
                  coordsSelectionData.dragTarget = DragTargets.Target.BottomRight
                } else
                {
                  coordsSelectionData.dragTarget = DragTargets.Target.Center
                }

                coordsSelectionData.dragStartX = mouse.x
                coordsSelectionData.dragStartY = mouse.y

                coordsSelectionData.dragPlusX = 0
                coordsSelectionData.dragPlusY = 0
                coordsSelectionData.dragPlusWidth = 0
                coordsSelectionData.dragPlusHeight = 0

                printDebug(coordsSelectionData.dragTarget + " target detected, dragging started")
              }
            }

            onPositionChanged: function (mouse) {
              printDebug ("onPositionChanged")

              if (coordsSelectionData.dragTarget != DragTargets.Target.None) {
                printDebug ("in drag handling")

                const diffX = mouse.x - coordsSelectionData.dragStartX
                const diffY = mouse.y - coordsSelectionData.dragStartY

                if (coordsSelectionData.dragTarget == DragTargets.Target.Center) {
                  coordsSelectionData.dragPlusX = diffX
                  coordsSelectionData.dragPlusY = diffY
                  coordsSelectionData.dragPlusWidth = 0
                  coordsSelectionData.dragPlusHeight = 0
                } else {
                  const absX = Math.abs(diffX)
                  const absY = Math.abs(diffY)
                  const xIsMax = absX > absY
                  const max = xIsMax ? absX : absY

                  var dirX = diffX >= 0 ? 1 : -1
                  var dirY = diffY >= 0 ? 1 : -1

                  const dirsUseSameSign =
                    coordsSelectionData.dragTarget == DragTargets.Target.TopLeft ||
                    coordsSelectionData.dragTarget == DragTargets.Target.BottomRight

                  if (xIsMax) {
                    dirY = dirsUseSameSign ? dirX : -dirX
                  } else {
                    dirX = dirsUseSameSign ? dirY : -dirY
                  }

                  const normalX = max * dirX
                  const normalY = max * dirY

                  if (coordsSelectionData.dragTarget == DragTargets.Target.TopLeft) {
                    coordsSelectionData.dragPlusX = normalX
                    coordsSelectionData.dragPlusWidth = -normalX
                    coordsSelectionData.dragPlusY = normalY
                    coordsSelectionData.dragPlusHeight = -normalY
                  } else if (coordsSelectionData.dragTarget == DragTargets.Target.TopRight) {
                    coordsSelectionData.dragPlusWidth = normalX
                    coordsSelectionData.dragPlusY = normalY
                    coordsSelectionData.dragPlusHeight = -normalY
                  } else if (coordsSelectionData.dragTarget == DragTargets.Target.BottomLeft) {
                    coordsSelectionData.dragPlusX = normalX
                    coordsSelectionData.dragPlusWidth = -normalX
                    coordsSelectionData.dragPlusHeight = normalY
                  } else if (coordsSelectionData.dragTarget == DragTargets.Target.BottomRight) {
                    coordsSelectionData.dragPlusWidth = normalX
                    coordsSelectionData.dragPlusHeight = normalY
                  } else {
                    console.error ("Somehow, we got this far into edge-only dragging calculation without being a valid edge?")
                  }
                }

                coordsSelectionCanvas.requestPaint()
              }
            }

            onReleased: function (mouse) {
              printDebug ("onReleased")

              if (mouse.button == Qt.LeftButton) {
                coordsSelectionData.selectionRectX += coordsSelectionData.dragPlusX
                coordsSelectionData.selectionRectY += coordsSelectionData.dragPlusY
                coordsSelectionData.selectionRectWidth += coordsSelectionData.dragPlusWidth
                coordsSelectionData.selectionRectHeight += coordsSelectionData.dragPlusHeight

                coordsSelectionData.dragTarget = DragTargets.Target.None
                coordsSelectionData.dragStartX = 0
                coordsSelectionData.dragStartY = 0

                coordsSelectionData.dragPlusX = 0
                coordsSelectionData.dragPlusY = 0
                coordsSelectionData.dragPlusWidth = 0
                coordsSelectionData.dragPlusHeight = 0

                selectedArea.width = coordsSelectionData.selectionRectWidth
                selectedArea.height = coordsSelectionData.selectionRectHeight
                selectedArea.imageOffsetX = coordsSelectionData.selectionRectX
                selectedArea.imageOffsetY = coordsSelectionData.selectionRectY
                selectedArea.imageWidth = coordsSelectionBackground.paintedWidth
                selectedArea.imageHeight = coordsSelectionBackground.paintedHeight
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: canvasDisplayComponent

    Page {
      id: canvasDisplayPage

      Canvas {
        id: displayCanvas
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: selectedArea.width
        height: selectedArea.height

        onPaint: {
          var ctx = getContext("2d");

          printDebug (width + "/" + height)

          if (selectedArea.isImageLoaded (main.selectedImage)) {
            ctx.drawImage (
              main.selectedImage,
              -selectedArea.imageOffsetX,
              -selectedArea.imageOffsetY,
              selectedArea.imageWidth,
              selectedArea.imageHeight
            )
            ctx.stroke()
          }
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
        onClicked: pageStack.pushItem(pages[pageStack.depth])
      }
    }
  }
}
