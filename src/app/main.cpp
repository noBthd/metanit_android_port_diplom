#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>

#include "services/article_service.h"
#include "services/article_model.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    ArticleService service;
    ArticleModel model;

    QString appDir = QCoreApplication::applicationDirPath();
    QString dataPath = QDir(appDir).filePath("../data/articles.json");
    auto articles = service.loadArticles(dataPath);
    model.setArticles(articles);

    QQmlApplicationEngine engine;
    
    engine.rootContext()->setContextProperty("articlesModel", &model);
    
    engine.load(QUrl("qrc:/qml/main.qml"));

    return app.exec();
}