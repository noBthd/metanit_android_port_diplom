#pragma once

#include <QObject>
#include <QVariantList>
#include <QHash>

/// Сервис загрузки и преобразования Markdown в блоки для QML.
/// Поддерживает загрузку из локальных файлов и кэш контента из API.
class MarkdownService : public QObject
{
    Q_OBJECT

public:
    explicit MarkdownService(QObject *parent = nullptr);

    /// Загружает markdown из файла или кэша. Возвращает сырой markdown-текст.
    Q_INVOKABLE QString loadMarkdown(const QString &fileName);

    /// Разбивает markdown на блоки {type: "text"/"code", content: "..."} для QML.
    Q_INVOKABLE QVariantList parseBlocks(const QString &markdown);

    /// Сохраняет контент статьи в кэш (вызывается из NetworkService).
    Q_INVOKABLE void cacheContent(const QString &fileName, const QString &content);

private:
    QString escapeHtml(const QString &text);
    QString processInline(const QString &text);
    QString renderTextBlockHtml(const QStringList &lines);

    /// Кэш контента статей, загруженных из API
    QHash<QString, QString> m_contentCache;
};
