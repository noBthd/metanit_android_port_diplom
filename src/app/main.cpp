#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>

#include "services/article_service.h"
#include "services/article_model.h"
#include "services/markdown_service.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("MetanitPort");
    app.setApplicationName("Metanit C++");

    ArticleService service;
    ArticleModel model;
    ArticleFilterModel filterModel;
    MarkdownService markdownService;

    // Load data
    QString appDir = QCoreApplication::applicationDirPath();
    
    // Try multiple paths for data
    QStringList dataPaths = {
        QDir(appDir).filePath("../../data/articles.json"),
        QDir(appDir).filePath("../data/articles.json"),
        QDir(appDir).filePath("data/articles.json"),
    };

    std::vector<Article> articles;
    for (const auto &path : dataPaths) {
        articles = service.loadArticles(path);
        if (!articles.empty()) break;
    }

    model.setArticles(articles);
    filterModel.setSourceModel(&model);

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("articlesModel", &model);
    engine.rootContext()->setContextProperty("filterModel", &filterModel);
    engine.rootContext()->setContextProperty("markdownService", &markdownService);

    engine.load(QUrl("qrc:/qml/main.qml"));

    return app.exec();
}
