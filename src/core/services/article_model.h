#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <vector>
#include "models/article.h"

class ArticleModel : public QAbstractListModel
{
    Q_OBJECT

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

    Q_INVOKABLE QVariantList getChapters() const;
    Q_INVOKABLE QVariantList getArticlesForChapter(int chapter) const;

private:
    std::vector<Article> m_articles;
};

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
