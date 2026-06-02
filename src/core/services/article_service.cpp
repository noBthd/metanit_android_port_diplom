#include "article_service.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

std::vector<Article> ArticleService::loadArticles(const QString& path)
{
    std::vector<Article> result;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return result;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);

    QJsonArray arr = doc.array();

    for (auto item : arr) {
        QJsonObject obj = item.toObject();

        Article a;
        a.title = obj["title"].toString();
        a.link = obj["link"].toString();
        a.file = "../data/articles/" + obj["file"].toString();

        result.push_back(a);
    }

    return result;
}