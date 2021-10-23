/****************************************************************************
 *
 * (c) 2021 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ActuatorActions.h"

#include "QGCApplication.h"

using namespace ActuatorActions;

QString Config::typeToLabel() const
{
    switch (type) {
        case Type::setSpinNormal: return QCoreApplication::translate("ActuatorAction", "Set Spin Direction: normal");
        case Type::setSpinReversed: return QCoreApplication::translate("ActuatorAction", "Set Spin Direction: reversed");
    }
    return "";
}

Action::Action(QObject *parent, const Config &action, const QString &label, int outputFunction,
        Vehicle *vehicle)
    : _label(label), _outputFunction(outputFunction), _type(action.type), _vehicle(vehicle)
{
}

void Action::trigger()
{
    if (_commandInProgress) {
        return;
    }
    sendMavlinkRequest();
}

void Action::ackHandlerEntry(void* resultHandlerData, int compId, MAV_RESULT commandResult,
        Vehicle::MavCmdResultFailureCode_t failureCode)
{
    Action* controller = (Action*)resultHandlerData;
    controller->ackHandler(commandResult, failureCode);
}

void Action::ackHandler(MAV_RESULT commandResult, Vehicle::MavCmdResultFailureCode_t failureCode)
{
    _commandInProgress = false;
    if (failureCode != Vehicle::MavCmdResultFailureNoResponseToCommand && commandResult != MAV_RESULT_ACCEPTED) {
        qgcApp()->showAppMessage(tr("Actuator action command failed"));
    }
}

void Action::sendMavlinkRequest()
{
    qCDebug(ActuatorsConfigLog) << "Sending actuator action, function:" << _outputFunction << "type:" << (int)_type;

    _vehicle->sendMavCommandWithHandler(
            ackHandlerEntry,                  // Ack callback
            this,                             // Ack callback data
            MAV_COMP_ID_AUTOPILOT1,           // the ID of the autopilot
            MAV_CMD_DO_ACTUATOR_ACTION,       // the mavlink command
            (int)_type,                       // action type
            0,                                // unused parameter
            0,                                // unused parameter
            0,                                // unused parameter
            1000+_outputFunction,             // function
            0,                                // unused parameter
            0);
    _commandInProgress = true;
}

ActionGroup::ActionGroup(QObject *parent, const QString &label, Config::Type type)
    : _label(label), _type(type)
{
}
