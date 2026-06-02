#include "article_model.h"
#include <algorithm>

// === ArticleModel ===

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
    if (!index.isValid() || index.row() >= (int)m_articles.size())
        return {};

    const Article &article = m_articles[index.row()];

    switch (role) {
    case TitleRole:
        return article.title;
    case LinkRole:
        return article.link;
    case FileRole:
        return article.file;
    case ChapterRole:
        return article.chapter;
    case ChapterNameRole:
        return article.chapterName;
    default:
        return {};
    }
}

QHash<int, QByteArray> ArticleModel::roleNames() const
{
    return {
        {TitleRole, "title"},
        {LinkRole, "link"},
        {FileRole, "file"},
        {ChapterRole, "chapter"},
        {ChapterNameRole, "chapterName"}
    };
}

void ArticleModel::setArticles(const std::vector<Article>& articles)
{
    beginResetModel();
    m_articles = articles;
    endResetModel();
    m_revision++;
    emit revisionChanged();
}

QVariantList ArticleModel::getChapters() const
{
    QVariantList chapters;
    QList<int> seenOrder;  // сохраняем порядок появления

    for (const auto &a : m_articles) {
        if (!seenOrder.contains(a.chapter)) {
            seenOrder.append(a.chapter);
        }
    }

    std::sort(seenOrder.begin(), seenOrder.end());

    for (int ch : seenOrder) {
        QVariantMap chMap;
        chMap["chapter"] = ch;

        int count = 0;
        QString name;
        for (const auto &a : m_articles) {
            if (a.chapter == ch) {
                count++;
                if (name.isEmpty()) name = a.chapterName;
            }
        }
        chMap["name"] = name;
        chMap["count"] = count;
        chapters.append(chMap);
    }

    return chapters;
}

QVariantList ArticleModel::getArticlesForChapter(int chapter) const
{
    QVariantList result;
    for (const auto &a : m_articles) {
        if (a.chapter == chapter) {
            QVariantMap item;
            item["title"] = a.title;
            item["link"] = a.link;
            item["file"] = a.file;
            item["chapter"] = a.chapter;
            item["chapterName"] = a.chapterName;
            result.append(item);
        }
    }
    return result;
}

// === ArticleFilterModel ===

ArticleFilterModel::ArticleFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

QString ArticleFilterModel::filterText() const
{
    return m_filterText;
}

void ArticleFilterModel::setFilterText(const QString &text)
{
    if (m_filterText != text) {
        m_filterText = text;
        invalidateFilter();
        emit filterTextChanged();
    }
}

bool ArticleFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_filterText.isEmpty())
        return true;

    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    QString title = sourceModel()->data(index, ArticleModel::TitleRole).toString();
    return title.contains(m_filterText, Qt::CaseInsensitive);
}
