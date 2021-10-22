import QtQuick 2.12
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactControls  1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.ScreenTools   1.0

SetupPage {
    id:             actuatorPage
    pageComponent:  pageComponent
    showAdvanced:   true

    property var _actuatorsController:       globals.activeVehicle.actuatorsController

    property var _showAdvanced:              advanced
    readonly property real _margins:         ScreenTools.defaultFontPixelHeight

    Component {
        id: pageComponent

        Row {
            spacing:                        ScreenTools.defaultFontPixelWidth * 4
            property var _leftColumnWidth:  Math.max(actuatorTesting.implicitWidth, mixerUi.implicitWidth) + (_margins * 2)

            ColumnLayout {
                spacing:                    ScreenTools.defaultFontPixelHeight
                implicitWidth:              _leftColumnWidth

                // mixer ui
                QGCLabel {
                    text:                   qsTr("Geometry")
                    font.pointSize:         ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    implicitWidth:          _leftColumnWidth
                    implicitHeight:         mixerUi.height + (_margins * 2)
                    color:                  qgcPal.windowShade

                    Column {
                        id:                 mixerUi
                        spacing:            _margins
                        anchors {
                            left:           parent.left
                            leftMargin:     _margins
                            verticalCenter: parent.verticalCenter
                        }
                        enabled:            !safetySwitch.checked && !_actuatorsController.motorAssignmentActive
                        Repeater {
                            model:          _actuatorsController.mixerController.groups
                            ColumnLayout {
                                property var mixerGroup: object

                                RowLayout {
                                    QGCLabel {
                                        text:                    mixerGroup.label
                                        font.bold:               true
                                        rightPadding:            ScreenTools.defaultFontPixelWidth * 3
                                    }
                                    ActuatorFact {
                                        property var countParam: mixerGroup.countParam
                                        visible:                 countParam != null
                                        fact:                    countParam ? countParam.fact : null
                                    }
                                }

                                GridLayout {
                                    rows:       1 + mixerGroup.channels.count
                                    columns:    1 + mixerGroup.channelConfigs.count

                                    QGCLabel {
                                        text:   ""
                                    }

                                    // param config labels
                                    Repeater {
                                        model:              mixerGroup.channelConfigs
                                        QGCLabel {
                                            text:           object.label
                                            visible:        object.visible && (_showAdvanced || !object.advanced)
                                            Layout.row:     0
                                            Layout.column:  1 + index
                                        }
                                    }
                                    // param instances
                                    Repeater {
                                        model:              mixerGroup.channels
                                        QGCLabel {
                                            text:           object.label + ":"
                                            Layout.row:     1 + index
                                            Layout.column:  0
                                        }
                                    }
                                    Repeater {
                                        model:              mixerGroup.channels
                                        Repeater {
                                            property var channel: object
                                            property var channelIndex: index

                                            model: object.configInstances

                                            ActuatorFact {
                                                fact:           object.fact
                                                Layout.row:     1 + channelIndex
                                                Layout.column:  1 + index
                                                visible:        object.config.visible && (_showAdvanced || !object.config.advanced)
                                            }
                                        }
                                    }
                                }

                                // extra group config params
                                Repeater {
                                    model: mixerGroup.configParams

                                    RowLayout {
                                        spacing:     ScreenTools.defaultFontPixelWidth
                                        QGCLabel {
                                            text:    object.label + ":"
                                            visible: _showAdvanced || !object.advanced
                                        }
                                        ActuatorFact {
                                            fact: object.fact
                                            visible: _showAdvanced || !object.advanced
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // actuator image
                Image {
                    property var refreshFlag:         _actuatorsController.imageRefreshFlag
                    readonly property real imageSize: 9 * ScreenTools.defaultFontPixelHeight

                    id:                actuatorImage
                    source:            "image://actuators/geometry"+refreshFlag
                    sourceSize.width:  Math.max(parent.width, imageSize)
                    sourceSize.height: imageSize
                    visible:           _actuatorsController.isMultirotor
                    cache:             false
                    MouseArea {
                        anchors.fill:  parent
                        onClicked: {
                            if (mouse.button == Qt.LeftButton) {
                                _actuatorsController.imageClicked(mouse.x, mouse.y);
                            }
                        }
                    }
                }

                // actuator testing
                QGCLabel {
                    text:               qsTr("Actuator Testing")
                    font.pointSize:     ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    implicitWidth:            _leftColumnWidth
                    implicitHeight:           actuatorTesting.height + (_margins * 2)
                    color:                    qgcPal.windowShade

                    Column {
                        id:                   actuatorTesting
                        spacing:              _margins
                        anchors {
                            left:             parent.left
                            leftMargin:       _margins
                            verticalCenter:   parent.verticalCenter
                        }

                        QGCLabel {
                            text: qsTr("Configure some outputs in order to test them.")
                            visible: _actuatorsController.actuatorTestController.actuators.count == 0
                        }

                        Row {
                            spacing: ScreenTools.defaultFontPixelWidth
                            visible: _actuatorsController.actuatorTestController.actuators.count > 0

                            Switch {
                                id:      safetySwitch
                                enabled: !_actuatorsController.motorAssignmentActive &&  !_actuatorsController.actuatorTestController.hadFailure
                                Connections {
                                    target: _actuatorsController.actuatorTestController
                                    onHadFailureChanged: {
                                        if (_actuatorsController.actuatorTestController.hadFailure) {
                                            safetySwitch.checked = false;
                                            safetySwitch.switchUpdated();
                                        }
                                    }
                                }
                                onClicked: {
                                    switchUpdated();
                                }
                                function switchUpdated() {
                                    if (!checked) {
                                        for (var channelIdx=0; channelIdx<sliderRepeater.count; channelIdx++) {
                                            sliderRepeater.itemAt(channelIdx).stop();
                                        }
                                        if (allMotorsLoader.item != null)
                                            allMotorsLoader.item.stop();
                                    }
                                    _actuatorsController.actuatorTestController.setActive(checked);
                                }
                            }

                            QGCLabel {
                                color:  qgcPal.warningText
                                text: safetySwitch.checked ? qsTr("Careful: Actuator sliders are enabled") : qsTr("Propellers are removed - Enable sliders")
                            }
                        } // Row

                        Row {
                            spacing: ScreenTools.defaultFontPixelWidth * 2
                            enabled: safetySwitch.checked

                            // (optional) slider for all motors
                            Loader {
                                id:                allMotorsLoader
                                sourceComponent:   _actuatorsController.actuatorTestController.allMotorsActuator ?  allMotorsComponent : null
                                Layout.alignment:  Qt.AlignTop
                            }
                            Component {
                                id:                allMotorsComponent
                                ActuatorSlider {
                                    channel:       _actuatorsController.actuatorTestController.allMotorsActuator
                                    rightPadding:  ScreenTools.defaultFontPixelWidth * 3
                                    onActuatorValueChanged: {
                                        stopTimer();
                                        for (var channelIdx=0; channelIdx<sliderRepeater.count; channelIdx++) {
                                            var channelSlider = sliderRepeater.itemAt(channelIdx);
                                            if (channelSlider.channel.isMotor) {
                                                channelSlider.value = sliderValue;
                                            }
                                        }
                                    }
                                }
                            }

                            // all channels
                            Repeater {
                                id:         sliderRepeater
                                model:      _actuatorsController.actuatorTestController.actuators

                                ActuatorSlider {
                                    channel: object
                                    onActuatorValueChanged: {
                                        if (isNaN(value)) {
                                            _actuatorsController.actuatorTestController.stopControl(index);
                                            stop();
                                        } else {
                                            _actuatorsController.actuatorTestController.setChannelTo(index, value);
                                        }
                                    }
                                }
                            } // Repeater
                        } // Row
                    } // Column
                } // Rectangle
            }

            // Right column
            Column {
                QGCLabel {
                    text:               qsTr("Actuator Outputs")
                    font.pointSize:     ScreenTools.mediumFontPointSize
                    bottomPadding:      ScreenTools.defaultFontPixelHeight
                }
                QGCLabel {
                    text:          qsTr("One or more actuator still needs to be assigned to an output.")
                    visible:       _actuatorsController.hasUnsetRequiredFunctions
                    color:         qgcPal.warningText
                    bottomPadding: ScreenTools.defaultFontPixelHeight
                }


                // actuator output selection tabs
                QGCTabBar {
                    Repeater {
                        model: _actuatorsController.actuatorOutputs
                        QGCTabButton {
                            text:      '   ' + object.label + '   '
                            width:     implicitWidth
                        }
                    }
                    onCurrentIndexChanged: {
                        _actuatorsController.selectActuatorOutput(currentIndex)
                    }
                }

                // actuator outputs
                Rectangle {
                    id:                             selActuatorOutput
                    implicitWidth:                  actuatorGroupColumn.width + (_margins * 2)
                    implicitHeight:                 actuatorGroupColumn.height + (_margins * 2)
                    color:                          qgcPal.windowShade

                    property var actuatorOutput:    _actuatorsController.selectedActuatorOutput

                    Column {
                        id:               actuatorGroupColumn
                        spacing:          _margins
                        anchors.centerIn: parent

                        // Motor assignment
                        Row {
                            visible:           _actuatorsController.isMultirotor
                            enabled:           !safetySwitch.checked
                            anchors.right:     parent.right
                            spacing:           _margins
                            QGCButton {
                                text:          qsTr("Identify & Assign Motors")
                                visible:       !_actuatorsController.motorAssignmentActive
                                onClicked: {
                                    var success = _actuatorsController.initMotorAssignment()
                                    if (success) {
                                        motorAssignmentConfirmDialog.open()
                                    } else {
                                        motorAssignmentFailureDialog.open()
                                    }
                                }
                                MessageDialog {
                                    id:         motorAssignmentConfirmDialog
                                    visible:    false
                                    icon:       StandardIcon.Warning
                                    standardButtons: StandardButton.Yes | StandardButton.No
                                    title:      qsTr("Motor Order Identification and Assignment")
                                    text: _actuatorsController.motorAssignmentMessage
                                    onYes: {
                                        console.log(_actuatorsController.motorAssignmentActive)
                                        _actuatorsController.startMotorAssignment()
                                    }
                                }
                                MessageDialog {
                                    id:         motorAssignmentFailureDialog
                                    visible:    false
                                    icon:       StandardIcon.Critical
                                    standardButtons: StandardButton.Ok
                                    title:      qsTr("Error")
                                    text: _actuatorsController.motorAssignmentMessage
                                }
                            }
                            QGCButton {
                                text:          qsTr("Spin Motor Again")
                                visible:       _actuatorsController.motorAssignmentActive
                                onClicked: {
                                    _actuatorsController.spinCurrentMotor()
                                }
                            }
                            QGCButton {
                                text:          qsTr("Abort")
                                visible:       _actuatorsController.motorAssignmentActive
                                onClicked: {
                                    _actuatorsController.abortMotorAssignment()
                                }
                            }
                        }

                        Column {
                            enabled:          !safetySwitch.checked && !_actuatorsController.motorAssignmentActive
                            spacing:          _margins

                            RowLayout {
                                property var enableParam:     selActuatorOutput.actuatorOutput.enableParam
                                QGCLabel {
                                    visible:                  parent.enableParam != null
                                    text:                     parent.enableParam ? parent.enableParam.label + ":" : ""
                                }
                                ActuatorFact {
                                    visible:                  parent.enableParam != null
                                    fact:                     parent.enableParam ?  parent.enableParam.fact : null
                                }
                            }


                            Repeater {
                                model: selActuatorOutput.actuatorOutput.subgroups

                                ColumnLayout {
                                    property var subgroup: object
                                    visible:               selActuatorOutput.actuatorOutput.groupsVisible

                                    RowLayout {
                                        visible: subgroup.label != ""
                                        QGCLabel {
                                            text:                    subgroup.label
                                            font.bold:               true
                                            rightPadding:            ScreenTools.defaultFontPixelWidth * 3
                                        }
                                        ActuatorFact {
                                            property var primaryParam: subgroup.primaryParam
                                            visible:                   primaryParam != null
                                            fact:                      primaryParam ? primaryParam.fact : null
                                        }
                                    }

                                    GridLayout {
                                        rows:      1 + subgroup.channels.count
                                        columns:   1 + subgroup.channelConfigs.count

                                        QGCLabel {
                                            text: ""
                                        }

                                        // param config labels
                                        Repeater {
                                            model: subgroup.channelConfigs
                                            QGCLabel {
                                                text:           object.label
                                                visible:        object.visible && (_showAdvanced || !object.advanced)
                                                Layout.row:     0
                                                Layout.column:  1 + index
                                            }
                                        }
                                        // param instances
                                        Repeater {
                                            model: subgroup.channels
                                            QGCLabel {
                                                text:            object.label + ":"
                                                Layout.row:      1 + index
                                                Layout.column:   0
                                            }
                                        }
                                        Repeater {
                                            model: subgroup.channels
                                            Repeater {
                                                property var channel:      object
                                                property var channelIndex: index
                                                model:                     object.configInstances
                                                ActuatorFact {
                                                    fact:           object.fact
                                                    Layout.row:     1 + channelIndex
                                                    Layout.column:  1 + index
                                                    visible:        object.config.visible && (_showAdvanced || !object.config.advanced)
                                                }
                                            }
                                        }
                                    }

                                    // extra subgroup config params
                                    Repeater {
                                        model: subgroup.configParams

                                        RowLayout {
                                            QGCLabel {
                                                text: object.label + ":"
                                            }
                                            ActuatorFact {
                                                fact: object.fact
                                            }
                                        }
                                    }

                                }
                            } // subgroup Repeater

                            // extra actuator config params
                            Repeater {
                                model: selActuatorOutput.actuatorOutput.configParams

                                RowLayout {
                                    QGCLabel {
                                        text: object.label + ":"
                                    }
                                    ActuatorFact {
                                        fact: object.fact
                                    }
                                }
                            }

                            // notes
                            Repeater {
                                model: selActuatorOutput.actuatorOutput.notes
                                ColumnLayout {
                                    spacing: ScreenTools.defaultFontPixelHeight
                                    QGCLabel {
                                        text:       modelData
                                        color:      qgcPal.warningText
                                    }
                                }
                            }
                        }
                    }
                } // Rectangle
            } // Column
        } // Row

    }
}
