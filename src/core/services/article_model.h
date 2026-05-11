#pragma once

#include <QAbstractListModel>
#include <vector>
#include "models/article.h"

class ArticleModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        LinkRole,
        ContentRole
    };

    explicit ArticleModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setArticles(const std::vector<Article>& articles);

private:
    std::vector<Article> m_articles;
};