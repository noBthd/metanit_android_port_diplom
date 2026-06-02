#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QDir>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>
#include <QSettings>

#include "services/article_service.h"
#include "services/article_model.h"
#include "services/markdown_service.h"
#include "services/network_service.h"

/// Парсит JSON-массив статей в вектор Article
static std::vector<Article> parseArticlesJson(const QJsonArray &arr) {
    std::vector<Article> result;
    for (const auto &val : arr) {
        auto obj = val.toObject();
        Article a;
        a.title = obj["title"].toString();
        a.link = obj["link"].toString();
        a.file = obj["file"].toString();
        a.chapter = obj["chapter"].toInt();
        a.chapterName = obj["chapterName"].toString();
        result.push_back(a);
    }
    return result;
}

/// Сохраняет список статей в QSettings (кэш на диск)
static void cacheArticlesList(const QJsonArray &arr) {
    QSettings s;
    s.setValue("cache/articlesList", QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

/// Загружает список статей из QSettings (оффлайн кэш)
static std::vector<Article> loadCachedArticles() {
    QSettings s;
    QByteArray data = s.value("cache/articlesList").toByteArray();
    if (data.isEmpty()) return {};
    QJsonArray arr = QJsonDocument::fromJson(data).array();
    return parseArticlesJson(arr);
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("MetanitPort");
    app.setApplicationName("Metanit C++");

    ArticleService service;
    ArticleModel model;
    ArticleFilterModel filterModel;
    MarkdownService markdownService;
    NetworkService networkService;

    // 1. Пробуем загрузить из локальных файлов (десктоп)
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

    // 2. Если локальных нет — загружаем из кэша (iOS оффлайн)
    if (articles.empty()) {
        articles = loadCachedArticles();
    }

    model.setArticles(articles);
    filterModel.setSourceModel(&model);

    // 3. При получении статей из API — обновляем модель И сохраняем в кэш
    QObject::connect(&networkService, &NetworkService::articlesLoaded,
        [&model](const QJsonArray &arr) {
            auto apiArticles = parseArticlesJson(arr);
            if (!apiArticles.empty()) {
                model.setArticles(apiArticles);
                cacheArticlesList(arr); // сохраняем на диск для оффлайна
            }
        });

    // 4. Запрашиваем свежие данные из API
    networkService.fetchArticles();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("articlesModel", &model);
    engine.rootContext()->setContextProperty("filterModel", &filterModel);
    engine.rootContext()->setContextProperty("markdownService", &markdownService);
    engine.rootContext()->setContextProperty("networkService", &networkService);
    engine.load(QUrl("qrc:/qml/main.qml"));

    return app.exec();
}
