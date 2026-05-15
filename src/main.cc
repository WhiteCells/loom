#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "profilemanager.h"

#ifndef LOOM_QML_MODULE_URI
#define LOOM_QML_MODULE_URI "LoomQML"
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Loom"));
    QCoreApplication::setOrganizationName(QStringLiteral("Loom"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    ProfileManager profileManager;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("profileManager"), &profileManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral(LOOM_QML_MODULE_URI), QStringLiteral("Main"));

    return app.exec();
}
