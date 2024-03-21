#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <include/FileReader/FileReader.h>

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    /* Регистрируем типы в метасистеме */
    qRegisterMetaType<QList<QVariantList>>("QList<QVariantList>");
    qRegisterMetaType<FileReader::FileReaderError>("FileReaderError");

    /* Регистрируем C++ классы в qml */
    qmlRegisterType<FileReader>("FileReader", 1, 0, "FileReader");
    initializeFileReaderErrors;

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](const QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
