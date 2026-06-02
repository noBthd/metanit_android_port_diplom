#include "markdown_service.h"

#include <QFile>
#include <QTextStream>
#include <QCoreApplication>
#include <QDir>
#include <QDebug>

MarkdownService::MarkdownService(QObject *parent)
    : QObject(parent)
{
}

QString MarkdownService::loadMarkdown(const QString &fileName)
{
    QDir dir(QCoreApplication::applicationDirPath());

    dir.cdUp();
    dir.cdUp();
    dir.cdUp();

    QString path =
        dir.absoluteFilePath("data/articles/" + fileName);

    qDebug() << path;

    QFile file(path);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return "failed to load markdown file";
    }

    QTextStream in(&file);

    return in.readAll();
}