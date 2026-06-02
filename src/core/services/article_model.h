#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <vector>
#include "models/article.h"

/// Модель статей для QML. Хранит список статей, предоставляет
/// данные для ListView и методы группировки по главам.
class ArticleModel : public QAbstractListModel
{
    Q_OBJECT
    /// Счётчик обновлений — меняется при setArticles, вызывает перерисовку в QML
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        LinkRole,
        FileRole,
        ChapterRole,
        ChapterNameRole
    };

    explicit ArticleModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setArticles(const std::vector<Article>& articles);

    int revision() const { return m_revision; }

    /// Возвращает список глав [{chapter, name, count}]
    Q_INVOKABLE QVariantList getChapters() const;
    /// Возвращает статьи для указанной главы
    Q_INVOKABLE QVariantList getArticlesForChapter(int chapter) const;

signals:
    void revisionChanged();

private:
    std::vector<Article> m_articles;
    int m_revision = 0;
};

/// Прокси-модель для фильтрации статей по поисковому запросу.
class ArticleFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)

public:
    explicit ArticleFilterModel(QObject *parent = nullptr);

    QString filterText() const;
    void setFilterText(const QString &text);

signals:
    void filterTextChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_filterText;
};
