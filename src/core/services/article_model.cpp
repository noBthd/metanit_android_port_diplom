#include "article_model.h"

ArticleModel::ArticleModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ArticleModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_articles.size();
}

QVariant ArticleModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const Article &article = m_articles[index.row()];

    switch (role) {
    case TitleRole:
        return article.title;
    case LinkRole:
        return article.link;
    case ContentRole:
        return article.content;
    default:
        return {};
    }
}

QHash<int, QByteArray> ArticleModel::roleNames() const
{
    return {
        {TitleRole, "title"},
        {LinkRole, "link"},
        {ContentRole, "content"}
    };
}

void ArticleModel::setArticles(const std::vector<Article>& articles)
{
    beginResetModel();
    m_articles = articles;
    endResetModel();
}