#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>
#include <QJsonArray>
#include <QJsonObject>

#include "services/article_service.h"
#include "services/article_model.h"
#include "services/markdown_service.h"
#include "services/network_service.h"

/// Точка входа приложения.
/// Инициализирует сервисы, загружает данные и запускает QML-интерфейс.
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("MetanitPort");
    app.setApplicationName("Metanit C++");

    // Сервисы
    ArticleService service;
    ArticleModel model;
    ArticleFilterModel filterModel;
    MarkdownService markdownService;
    NetworkService networkService;

    // Загрузка локальных данных (fallback если нет API)
    QString appDir = QCoreApplication::applicationDirPath();
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

    // Подключение загрузки статей из API
    // Когда API ответит — модель обновится автоматически
    QObject::connect(&networkService, &NetworkService::articlesLoaded,
        [&model, &filterModel](const QJsonArray &arr) {
            std::vector<Article> apiArticles;
            for (const auto &val : arr) {
                auto obj = val.toObject();
                Article a;
                a.title = obj["title"].toString();
                a.link = obj["link"].toString();
                a.file = obj["file"].toString();
                a.chapter = obj["chapter"].toInt();
                a.chapterName = obj["chapterName"].toString();
                apiArticles.push_back(a);
            }
            if (!apiArticles.empty()) {
                model.setArticles(apiArticles);
            }
        });

    // Загружаем статьи из API при старте
    networkService.fetchArticles();

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("articlesModel", &model);
    engine.rootContext()->setContextProperty("filterModel", &filterModel);
    engine.rootContext()->setContextProperty("markdownService", &markdownService);
    engine.rootContext()->setContextProperty("networkService", &networkService);

    engine.load(QUrl("qrc:/qml/main.qml"));

    return app.exec();
}
