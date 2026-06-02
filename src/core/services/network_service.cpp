#include "network_service.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QSettings>
#include <QDebug>

NetworkService::NetworkService(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_baseUrl("http://localhost:8080")
{
    loadAuth();
}

void NetworkService::setBaseUrl(const QString &url) { m_baseUrl = url; }

bool NetworkService::isLoggedIn() const { return !m_token.isEmpty(); }
QString NetworkService::username() const { return m_username; }
bool NetworkService::isLoading() const { return m_loading; }

void NetworkService::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

QNetworkRequest NetworkService::makeRequest(const QString &path) {
    QNetworkRequest req(QUrl(m_baseUrl + path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty())
        req.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());
    return req;
}

void NetworkService::saveAuth() {
    QSettings s;
    s.setValue("auth/token", m_token);
    s.setValue("auth/username", m_username);
}

void NetworkService::loadAuth() {
    QSettings s;
    m_token = s.value("auth/token").toString();
    m_username = s.value("auth/username").toString();
}

void NetworkService::login(const QString &user, const QString &pass) {
    QJsonObject body;
    body["username"] = user;
    body["password"] = pass;

    auto *reply = m_manager->post(makeRequest("/api/login"),
                                   QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        auto doc = QJsonDocument::fromJson(reply->readAll());
        auto obj = doc.object();
        if (obj.contains("error")) {
            emit authError(obj["error"].toString());
        } else {
            m_token = obj["token"].toString();
            m_username = obj["username"].toString();
            saveAuth();
            emit authChanged();
        }
        reply->deleteLater();
    });
}

void NetworkService::registerUser(const QString &user, const QString &pass) {
    QJsonObject body;
    body["username"] = user;
    body["password"] = pass;

    auto *reply = m_manager->post(makeRequest("/api/register"),
                                   QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        auto doc = QJsonDocument::fromJson(reply->readAll());
        auto obj = doc.object();
        if (obj.contains("error")) {
            emit authError(obj["error"].toString());
        } else {
            m_token = obj["token"].toString();
            m_username = obj["username"].toString();
            saveAuth();
            emit authChanged();
        }
        reply->deleteLater();
    });
}

void NetworkService::logout() {
    m_token.clear();
    m_username.clear();
    saveAuth();
    emit authChanged();
}

void NetworkService::fetchArticles() {
    setLoading(true);
    auto *reply = m_manager->get(makeRequest("/api/articles"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        setLoading(false);
        if (reply->error() == QNetworkReply::NoError) {
            auto doc = QJsonDocument::fromJson(reply->readAll());
            emit articlesLoaded(doc.array());
        }
        reply->deleteLater();
    });
}

void NetworkService::fetchArticleContent(const QString &file) {
    auto *reply = m_manager->get(makeRequest("/api/articles/" + file + "/content"));
    connect(reply, &QNetworkReply::finished, this, [this, reply, file]() {
        if (reply->error() == QNetworkReply::NoError) {
            auto doc = QJsonDocument::fromJson(reply->readAll());
            emit articleContentLoaded(file, doc.object()["content"].toString());
        }
        reply->deleteLater();
    });
}

void NetworkService::addFavorite(int articleId) {
    QJsonObject body;
    body["article_id"] = articleId;
    auto *reply = m_manager->post(makeRequest("/api/favorites"),
                                   QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        emit favoriteToggled();
        reply->deleteLater();
    });
}

void NetworkService::removeFavorite(int articleId) {
    auto *reply = m_manager->deleteResource(makeRequest("/api/favorites/" + QString::number(articleId)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        emit favoriteToggled();
        reply->deleteLater();
    });
}

void NetworkService::fetchFavorites() {
    auto *reply = m_manager->get(makeRequest("/api/favorites"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            auto doc = QJsonDocument::fromJson(reply->readAll());
            emit favoritesLoaded(doc.array());
        }
        reply->deleteLater();
    });
}
