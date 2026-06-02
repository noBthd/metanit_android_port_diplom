#include "network_service.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QSettings>

NetworkService::NetworkService(QObject *parent)
    : QObject(parent), m_manager(new QNetworkAccessManager(this)),
      m_baseUrl("http://172.20.10.11:8080")
{
    loadAuth();
    QSettings s;
    m_fontSize = s.value("ui/fontSize", 16).toInt();
    m_darkTheme = s.value("ui/darkTheme", true).toBool();
    QString savedUrl = s.value("server/url").toString();
    if (!savedUrl.isEmpty()) m_baseUrl = savedUrl;
}

void NetworkService::setBaseUrl(const QString &url) {
    m_baseUrl = url; QSettings s; s.setValue("server/url", url);
}
bool NetworkService::isLoggedIn() const { return !m_token.isEmpty(); }
QString NetworkService::username() const { return m_username; }
QString NetworkService::displayName() const { return m_displayName; }
bool NetworkService::isLoading() const { return m_loading; }
int NetworkService::fontSize() const { return m_fontSize; }
bool NetworkService::darkTheme() const { return m_darkTheme; }
void NetworkService::setLoading(bool v) { if (m_loading!=v) { m_loading=v; emit loadingChanged(); } }

void NetworkService::setFontSize(int size) {
    if (m_fontSize!=size) { m_fontSize=size; QSettings().setValue("ui/fontSize",size); emit fontSizeChanged(); }
}
void NetworkService::setDarkTheme(bool dark) {
    if (m_darkTheme!=dark) { m_darkTheme=dark; QSettings().setValue("ui/darkTheme",dark); emit themeChanged(); }
}

QNetworkRequest NetworkService::makeRequest(const QString &path) {
    QNetworkRequest req(QUrl(m_baseUrl + path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty()) req.setRawHeader("Authorization", ("Bearer "+m_token).toUtf8());
    return req;
}
void NetworkService::saveAuth() {
    QSettings s; s.setValue("auth/token",m_token); s.setValue("auth/username",m_username); s.setValue("auth/displayName",m_displayName);
}
void NetworkService::loadAuth() {
    QSettings s; m_token=s.value("auth/token").toString(); m_username=s.value("auth/username").toString(); m_displayName=s.value("auth/displayName").toString();
}

// === Auth ===
void NetworkService::login(const QString &user, const QString &pass) {
    QJsonObject b; b["username"]=user; b["password"]=pass;
    auto *r = m_manager->post(makeRequest("/api/login"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r](){
        auto o=QJsonDocument::fromJson(r->readAll()).object();
        if(o.contains("error")){emit authError(o["error"].toString());}
        else{m_token=o["token"].toString();m_username=o["username"].toString();m_displayName=o["display_name"].toString();saveAuth();emit authChanged();}
        r->deleteLater();
    });
}

void NetworkService::registerUser(const QString &user, const QString &pass, const QString &name) {
    QJsonObject b; b["username"]=user; b["password"]=pass; b["display_name"]=name;
    auto *r = m_manager->post(makeRequest("/api/register"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r](){
        auto o=QJsonDocument::fromJson(r->readAll()).object();
        if(o.contains("error")){emit authError(o["error"].toString());}
        else{m_token=o["token"].toString();m_username=o["username"].toString();m_displayName=o["display_name"].toString();saveAuth();emit authChanged();}
        r->deleteLater();
    });
}

void NetworkService::logout() { m_token.clear();m_username.clear();m_displayName.clear();saveAuth();emit authChanged(); }

void NetworkService::updateProfile(const QString &name, const QString &oldPass, const QString &newPass) {
    QJsonObject b; if(!name.isEmpty())b["display_name"]=name; if(!oldPass.isEmpty())b["old_password"]=oldPass; if(!newPass.isEmpty())b["new_password"]=newPass;
    auto *r = m_manager->put(makeRequest("/api/profile"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r,name](){
        auto o=QJsonDocument::fromJson(r->readAll()).object();
        if(o.contains("error")){emit profileError(o["error"].toString());}
        else{if(!name.isEmpty()){m_displayName=name;saveAuth();emit authChanged();}emit profileUpdated();}
        r->deleteLater();
    });
}

// === Articles ===
void NetworkService::fetchArticles() {
    setLoading(true);
    auto *r = m_manager->get(makeRequest("/api/articles"));
    connect(r, &QNetworkReply::finished, this, [this,r](){
        setLoading(false);
        if(r->error()==QNetworkReply::NoError) emit articlesLoaded(QJsonDocument::fromJson(r->readAll()).array());
        r->deleteLater();
    });
}

void NetworkService::fetchArticleContent(const QString &file) {
    auto *r = m_manager->get(makeRequest("/api/articles/"+file+"/content"));
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError)
            emit articleContentLoaded(file, QJsonDocument::fromJson(r->readAll()).object()["content"].toString());
        r->deleteLater();
    });
}

void NetworkService::searchArticles(const QString &query) {
    auto *r = m_manager->get(makeRequest("/api/search?q="+query));
    connect(r, &QNetworkReply::finished, this, [this,r](){
        if(r->error()==QNetworkReply::NoError) emit searchResults(QJsonDocument::fromJson(r->readAll()).array());
        r->deleteLater();
    });
}

// === Favorites ===
void NetworkService::toggleFavorite(const QString &file) {
    QJsonObject b; b["file"]=file;
    auto *r = m_manager->post(makeRequest("/api/favorites/toggle"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError){auto o=QJsonDocument::fromJson(r->readAll()).object();emit favoriteToggled(file,o["is_favorite"].toBool());}
        r->deleteLater();
    });
}

void NetworkService::checkFavorite(const QString &file) {
    auto *r = m_manager->get(makeRequest("/api/favorites/check/"+file));
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError){auto o=QJsonDocument::fromJson(r->readAll()).object();emit favoriteChecked(file,o["is_favorite"].toBool());}
        r->deleteLater();
    });
}

void NetworkService::fetchFavorites() {
    auto *r = m_manager->get(makeRequest("/api/favorites"));
    connect(r, &QNetworkReply::finished, this, [this,r](){
        if(r->error()==QNetworkReply::NoError) emit favoritesLoaded(QJsonDocument::fromJson(r->readAll()).array());
        r->deleteLater();
    });
}

// === Progress ===
void NetworkService::markRead(const QString &file) {
    QJsonObject b; b["file"]=file;
    auto *r = m_manager->post(makeRequest("/api/progress/read"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError) {
            auto o=QJsonDocument::fromJson(r->readAll()).object();
            emit readChecked(file, o["is_read"].toBool());
        }
        r->deleteLater();
    });
}

void NetworkService::checkRead(const QString &file) {
    auto *r = m_manager->get(makeRequest("/api/progress/check/"+file));
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError){auto o=QJsonDocument::fromJson(r->readAll()).object();emit readChecked(file,o["is_read"].toBool());}
        r->deleteLater();
    });
}

void NetworkService::fetchProgress() {
    auto *r = m_manager->get(makeRequest("/api/progress"));
    connect(r, &QNetworkReply::finished, this, [this,r](){
        if(r->error()==QNetworkReply::NoError) emit progressLoaded(QJsonDocument::fromJson(r->readAll()).object());
        r->deleteLater();
    });
}

// === Notes ===
void NetworkService::saveNote(const QString &file, const QString &text) {
    QJsonObject b; b["file"]=file; b["text"]=text;
    auto *r = m_manager->post(makeRequest("/api/notes"), QJsonDocument(b).toJson());
    connect(r, &QNetworkReply::finished, this, [this,r](){ emit noteSaved(); r->deleteLater(); });
}

void NetworkService::fetchNote(const QString &file) {
    auto *r = m_manager->get(makeRequest("/api/notes/"+file));
    connect(r, &QNetworkReply::finished, this, [this,r,file](){
        if(r->error()==QNetworkReply::NoError){auto o=QJsonDocument::fromJson(r->readAll()).object();emit noteLoaded(file,o["text"].toString());}
        r->deleteLater();
    });
}

void NetworkService::fetchAllNotes() {
    auto *r = m_manager->get(makeRequest("/api/notes"));
    connect(r, &QNetworkReply::finished, this, [this,r](){
        if(r->error()==QNetworkReply::NoError) emit allNotesLoaded(QJsonDocument::fromJson(r->readAll()).array());
        r->deleteLater();
    });
}
