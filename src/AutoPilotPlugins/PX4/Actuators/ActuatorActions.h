/****************************************************************************
 *
 * (c) 2021 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QString>

#include "Common.h"

#include <QmlObjectListModel.h>

namespace ActuatorActions {

struct Config {
    enum class Type {
        setSpinReversed = 0, ///< motors: set reversed spin direction (needs to match the definition in mavlink)
        setSpinNormal = 1,   ///< motors: set normal spin direction
    };
    QString typeToLabel() const;

    Type type;
    Condition condition;
    QSet<QString> actuatorTypes;
};

class Action : public QObject
{
    Q_OBJECT
public:
    Action(QObject* parent, const Config& action, const QString& label,
            int outputFunction, Vehicle* vehicle);

    Q_PROPERTY(QString label                     READ label              CONSTANT)

    const QString& label() const { return _label; }

    Q_INVOKABLE void trigger();

private:
    static void ackHandlerEntry(void* resultHandlerData, int compId, MAV_RESULT commandResult,
            Vehicle::MavCmdResultFailureCode_t failureCode);
    void ackHandler(MAV_RESULT commandResult, Vehicle::MavCmdResultFailureCode_t failureCode);
    void sendMavlinkRequest();

    const QString _label;
    const int _outputFunction;
    const Config::Type _type;
    Vehicle* _vehicle{nullptr};

    bool _commandInProgress{false};
};

class ActionGroup : public QObject
{
    Q_OBJECT
public:
    ActionGroup(QObject* parent, const QString& label, Config::Type type);

    Q_PROPERTY(QString label                     READ label              CONSTANT)
    Q_PROPERTY(QmlObjectListModel* actions       READ actions            CONSTANT)

    QmlObjectListModel* actions() { return _actions; }
    const QString& label() const { return _label; }

    void addAction(Action* action) { _actions->append(action); }

    Config::Type type() const { return _type; }

private:
    const QString _label;
    QmlObjectListModel* _actions = new QmlObjectListModel(this); ///< list of Action*
    const Config::Type _type;
};

} // namespace ActuatorActions
