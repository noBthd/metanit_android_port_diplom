#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonArray>
#include <QJsonObject>
#include <QSettings>

/// Сетевой сервис — общение с Go API.
/// Управляет авторизацией, статьями, избранным, прогрессом, заметками, настройками UI.
class NetworkService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY authChanged)
    Q_PROPERTY(QString username READ username NOTIFY authChanged)
    Q_PROPERTY(QString displayName READ displayName NOTIFY authChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(int fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged)
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY themeChanged)

public:
    explicit NetworkService(QObject *parent = nullptr);

    bool isLoggedIn() const;
    QString username() const;
    QString displayName() const;
    bool isLoading() const;
    int fontSize() const;
    bool darkTheme() const;

    // Auth
    Q_INVOKABLE void login(const QString &user, const QString &pass);
    Q_INVOKABLE void registerUser(const QString &user, const QString &pass, const QString &name);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void updateProfile(const QString &name, const QString &oldPass, const QString &newPass);

    // Articles
    Q_INVOKABLE void fetchArticles();
    Q_INVOKABLE void fetchArticleContent(const QString &file);
    Q_INVOKABLE void searchArticles(const QString &query);

    // Favorites
    Q_INVOKABLE void toggleFavorite(const QString &file);
    Q_INVOKABLE void checkFavorite(const QString &file);
    Q_INVOKABLE void fetchFavorites();

    // Progress
    Q_INVOKABLE void markRead(const QString &file);
    Q_INVOKABLE void checkRead(const QString &file);
    Q_INVOKABLE void fetchProgress();

    // Notes
    Q_INVOKABLE void saveNote(const QString &file, const QString &text);
    Q_INVOKABLE void fetchNote(const QString &file);
    Q_INVOKABLE void fetchAllNotes();

    // UI
    Q_INVOKABLE void setFontSize(int size);
    Q_INVOKABLE void setDarkTheme(bool dark);
    Q_INVOKABLE void setBaseUrl(const QString &url);

signals:
    void authChanged();
    void authError(const QString &error);
    void profileUpdated();
    void profileError(const QString &error);
    void loadingChanged();
    void articlesLoaded(const QJsonArray &articles);
    void articleContentLoaded(const QString &file, const QString &content);
    void searchResults(const QJsonArray &articles);
    void favoriteToggled(const QString &file, bool isFavorite);
    void favoriteChecked(const QString &file, bool isFavorite);
    void favoritesLoaded(const QJsonArray &favorites);
    void readMarked(const QString &file);
    void readChecked(const QString &file, bool isRead);
    void progressLoaded(const QJsonObject &progress);
    void noteLoaded(const QString &file, const QString &text);
    void noteSaved();
    void allNotesLoaded(const QJsonArray &notes);
    void fontSizeChanged();
    void themeChanged();

private:
    QNetworkAccessManager *m_manager;
    QString m_baseUrl, m_token, m_username, m_displayName;
    bool m_loading = false;
    int m_fontSize = 16;
    bool m_darkTheme = true;

    void setLoading(bool v);
    QNetworkRequest makeRequest(const QString &path);
    void saveAuth();
    void loadAuth();
};
