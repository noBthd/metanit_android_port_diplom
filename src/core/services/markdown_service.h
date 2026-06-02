#pragma once

#include <QObject>

class MarkdownService : public QObject
{
    Q_OBJECT

public:
    explicit MarkdownService(QObject *parent = nullptr);

    Q_INVOKABLE QString loadMarkdown(const QString &fileName);
    Q_INVOKABLE QString markdownToHtml(const QString &markdown);

private:
    QString escapeHtml(const QString &text);
    QString processInline(const QString &text);
};
