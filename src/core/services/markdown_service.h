#pragma once

#include <QObject>
#include <QVariantList>
#include <QHash>

/// Сервис загрузки и преобразования Markdown.
/// Поддерживает тёмную и светлую тему через параметр isDark.
class MarkdownService : public QObject
{
    Q_OBJECT

public:
    explicit MarkdownService(QObject *parent = nullptr);

    Q_INVOKABLE QString loadMarkdown(const QString &fileName);
    /// Разбивает markdown на блоки. isDark управляет цветами HTML.
    Q_INVOKABLE QVariantList parseBlocks(const QString &markdown, bool isDark = true);
    Q_INVOKABLE void cacheContent(const QString &fileName, const QString &content);

private:
    QString escapeHtml(const QString &text);
    QString processInline(const QString &text, bool isDark);
    QString renderTextBlockHtml(const QStringList &lines, bool isDark);

    QHash<QString, QString> m_contentCache;
};
