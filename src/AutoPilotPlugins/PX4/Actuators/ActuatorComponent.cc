/****************************************************************************
 *
 * (c) 2021 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ActuatorComponent.h"

#include "QGCApplication.h"

static bool imageProviderAdded{false};

ActuatorComponent::ActuatorComponent(Vehicle* vehicle, AutoPilotPlugin* autopilot, QObject* parent) :
    VehicleComponent(vehicle, autopilot, parent),
    _name(tr("Actuators")), _actuatorsController(vehicle)
{

    QString json_file = "";

    _actuatorsController.load(json_file);

    if (!imageProviderAdded) {
        qgcApp()->qmlAppEngine()->addImageProvider(QLatin1String("actuators"), GeometryImage::VehicleGeometryImageProvider::instance());
        imageProviderAdded = true;
    }

    connect(&_actuatorsController, &ActuatorsController::hasUnsetRequiredFunctionsChanged, this, [this]() { _triggerUpdated({}); });
}

QString ActuatorComponent::name(void) const
{
    return _name;
}

QString ActuatorComponent::description(void) const
{
    return "";
}

QString ActuatorComponent::iconResource(void) const
{
    return QStringLiteral("/qmlimages/MotorComponentIcon.svg");
}

bool ActuatorComponent::requiresSetup(void) const
{
    return true;
}

bool ActuatorComponent::setupComplete(void) const
{
    return !_actuatorsController.hasUnsetRequiredFunctions();
}

QStringList ActuatorComponent::setupCompleteChangedTriggerList(void) const
{
    return QStringList();
}

QUrl ActuatorComponent::setupSource(void) const
{
    return QUrl::fromUserInput(QStringLiteral("qrc:/qml/ActuatorComponent.qml"));
}

QUrl ActuatorComponent::summaryQmlSource(void) const
{
    return QUrl();
}
