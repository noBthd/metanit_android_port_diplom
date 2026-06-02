#include "network_service.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QSettings>

NetworkService::NetworkService(QObject *parent)
    : QObject(parent), m_manager(new QNetworkAccessManager(this)), m_baseUrl("http://localhost:8080")
{
    loadAuth();
    QSettings s;
    m_fontSize = s.value("ui/fontSize", 16).toInt();
    m_darkTheme = s.value("ui/darkTheme", true).toBool();
}

void NetworkService::setBaseUrl(const QString &url) { m_baseUrl = url; }
bool NetworkService::isLoggedIn() const { return !m_token.isEmpty(); }
QString NetworkService::username() const { return m_username; }
QString NetworkService::displayName() const { return m_displayName; }
bool NetworkService::isLoading() const { return m_loading; }
int NetworkService::fontSize() const { return m_fontSize; }
bool NetworkService::darkTheme() const { return m_darkTheme; }

void NetworkService::setLoading(bool v) { if (m_loading != v) { m_loading = v; emit loadingChanged(); } }

void NetworkService::setFontSize(int size) {
    if (m_fontSize != size) {
        m_fontSize = size;
        QSettings s; s.setValue("ui/fontSize", size);
        emit fontSizeChanged();
    }
}

void NetworkService::setDarkTheme(bool dark) {
    if (m_darkTheme != dark) {
        m_darkTheme = dark;
        QSettings s; s.setValue("ui/darkTheme", dark);
        emit themeChanged();
    }
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
    s.setValue("auth/displayName", m_displayName);
}

void NetworkService::loadAuth() {
    QSettings s;
    m_token = s.value("auth/token").toString();
    m_username = s.value("auth/username").toString();
    m_displayName = s.value("auth/displayName").toString();
}

void NetworkService::login(const QString &user, const QString &pass) {
    QJsonObject body; body["username"] = user; body["password"] = pass;
    auto *reply = m_manager->post(makeRequest("/api/login"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        auto obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (obj.contains("error")) { emit authError(obj["error"].toString()); }
        else { m_token = obj["token"].toString(); m_username = obj["username"].toString();
               m_displayName = obj["display_name"].toString(); saveAuth(); emit authChanged(); }
        reply->deleteLater();
    });
}

void NetworkService::registerUser(const QString &user, const QString &pass, const QString &name) {
    QJsonObject body; body["username"] = user; body["password"] = pass; body["display_name"] = name;
    auto *reply = m_manager->post(makeRequest("/api/register"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        auto obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (obj.contains("error")) { emit authError(obj["error"].toString()); }
        else { m_token = obj["token"].toString(); m_username = obj["username"].toString();
               m_displayName = obj["display_name"].toString(); saveAuth(); emit authChanged(); }
        reply->deleteLater();
    });
}

void NetworkService::logout() {
    m_token.clear(); m_username.clear(); m_displayName.clear();
    saveAuth(); emit authChanged();
}

void NetworkService::updateProfile(const QString &name, const QString &oldPass, const QString &newPass) {
    QJsonObject body;
    if (!name.isEmpty()) body["display_name"] = name;
    if (!oldPass.isEmpty()) body["old_password"] = oldPass;
    if (!newPass.isEmpty()) body["new_password"] = newPass;
    auto *reply = m_manager->put(makeRequest("/api/profile"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, name]() {
        auto obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (obj.contains("error")) { emit profileError(obj["error"].toString()); }
        else { if (!name.isEmpty()) { m_displayName = name; saveAuth(); emit authChanged(); }
               emit profileUpdated(); }
        reply->deleteLater();
    });
}

void NetworkService::fetchArticles() {
    setLoading(true);
    auto *reply = m_manager->get(makeRequest("/api/articles"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        setLoading(false);
        if (reply->error() == QNetworkReply::NoError)
            emit articlesLoaded(QJsonDocument::fromJson(reply->readAll()).array());
        reply->deleteLater();
    });
}

void NetworkService::fetchArticleContent(const QString &file) {
    auto *reply = m_manager->get(makeRequest("/api/articles/" + file + "/content"));
    connect(reply, &QNetworkReply::finished, this, [this, reply, file]() {
        if (reply->error() == QNetworkReply::NoError)
            emit articleContentLoaded(file, QJsonDocument::fromJson(reply->readAll()).object()["content"].toString());
        reply->deleteLater();
    });
}

void NetworkService::addFavorite(int articleId) {
    QJsonObject body; body["article_id"] = articleId;
    auto *reply = m_manager->post(makeRequest("/api/favorites"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { emit favoriteToggled(); reply->deleteLater(); });
}

void NetworkService::removeFavorite(int articleId) {
    auto *reply = m_manager->deleteResource(makeRequest("/api/favorites/" + QString::number(articleId)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { emit favoriteToggled(); reply->deleteLater(); });
}

void NetworkService::fetchFavorites() {
    auto *reply = m_manager->get(makeRequest("/api/favorites"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError)
            emit favoritesLoaded(QJsonDocument::fromJson(reply->readAll()).array());
        reply->deleteLater();
    });
}
