#include "markdown_service.h"

#include <QFile>
#include <QTextStream>
#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QRegularExpression>
#include <QVariantMap>

MarkdownService::MarkdownService(QObject *parent)
    : QObject(parent)
{
}

QString MarkdownService::loadMarkdown(const QString &fileName)
{
    QString appDir = QCoreApplication::applicationDirPath();
    QStringList paths = {
        QDir(appDir).filePath("../../data/articles/" + fileName),
        QDir(appDir).filePath("../data/articles/" + fileName),
        QDir(appDir).filePath("data/articles/" + fileName),
    };
    for (const auto &path : paths) {
        QFile file(path);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&file);
            return in.readAll();
        }
    }
    return "# Ошибка\n\nНе удалось загрузить файл: " + fileName;
}

QString MarkdownService::escapeHtml(const QString &text)
{
    QString result = text;
    result.replace("&", "&amp;");
    result.replace("<", "&lt;");
    result.replace(">", "&gt;");
    result.replace("\"", "&quot;");
    return result;
}

QString MarkdownService::processInline(const QString &text)
{
    QString result = text;

    // Инлайн-код: `code`
    QRegularExpression inlineCode("`([^`]+)`");
    result.replace(inlineCode,
        " <span style=\"font-family:'Menlo','Courier New',monospace;"
        "font-size:13px;color:#7ec8e3;"
        "background-color:#2a2a3a;\">&#8198;\\1&#8198;</span> ");

    // Жирный: **text**
    QRegularExpression bold("\\*\\*([^*]+)\\*\\*");
    result.replace(bold, "<b>\\1</b>");

    // Курсив: *text*
    QRegularExpression italic("(?<!\\*)\\*([^*]+)\\*(?!\\*)");
    result.replace(italic, "<i>\\1</i>");

    return result;
}

// Рендерит блок текстовых строк (не-код) в HTML
QString MarkdownService::renderTextBlockHtml(const QStringList &lines)
{
    QString html;
    bool inList = false;
    QString listType;

    for (const auto &rawLine : lines) {
        QString trimmed = rawLine.trimmed();

        if (trimmed.isEmpty()) {
            if (inList) {
                html += (listType == "ol") ? "</ol>" : "</ul>";
                inList = false;
            }
            continue;
        }

        // Заголовки
        if (trimmed.startsWith("#### ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td bgcolor=\"#2a2a2e\" style=\"height:1;\"></td></tr></table>"
                    "<br/>"
                    "<p style=\"font-size:16px;font-weight:600;color:#e0e0e0;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(5))) + "</p><br/>";
            continue;
        }
        if (trimmed.startsWith("### ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td bgcolor=\"#2a2a2e\" style=\"height:1;\"></td></tr></table>"
                    "<br/>"
                    "<p style=\"font-size:18px;font-weight:600;color:#f0f0f0;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(4))) + "</p><br/>";
            continue;
        }
        if (trimmed.startsWith("## ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td bgcolor=\"#2a2a2e\" style=\"height:1;\"></td></tr></table>"
                    "<br/>"
                    "<p style=\"font-size:20px;font-weight:600;color:#ffffff;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(3))) + "</p><br/>";
            continue;
        }
        if (trimmed.startsWith("# ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"font-size:24px;font-weight:700;color:#ffffff;\">"
                    + processInline(escapeHtml(trimmed.mid(2))) + "</p>";
            continue;
        }

        // Горизонтальная линия
        if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td bgcolor=\"#2a2a2e\" style=\"height:1;\"></td></tr></table><br/>";
            continue;
        }

        // Маркированный список
        if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
            if (!inList || listType != "ul") {
                if (inList) html += (listType == "ol") ? "</ol>" : "</ul>";
                html += "<ul>";
                inList = true; listType = "ul";
            }
            html += "<li>" + processInline(escapeHtml(trimmed.mid(2))) + "</li>";
            continue;
        }

        // Нумерованный список
        QRegularExpression olRegex("^(\\d+)\\.\\s+(.*)$");
        auto olMatch = olRegex.match(trimmed);
        if (olMatch.hasMatch()) {
            if (!inList || listType != "ol") {
                if (inList) html += (listType == "ol") ? "</ol>" : "</ul>";
                html += "<ol>";
                inList = true; listType = "ol";
            }
            html += "<li>" + processInline(escapeHtml(olMatch.captured(2))) + "</li>";
            continue;
        }

        // Цитата
        if (trimmed.startsWith("> ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"color:#8e8e93;font-style:italic;border-left:3px solid #0a84ff;"
                    "padding-left:10px;\">"
                    + processInline(escapeHtml(trimmed.mid(2))) + "</p>";
            continue;
        }

        // Таблица
        if (trimmed.startsWith("|")) {
            // Skip for now, handled as paragraph
        }

        // Обычный параграф
        if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
        html += "<p>" + processInline(escapeHtml(trimmed)) + "</p>";
    }

    if (inList) {
        html += (listType == "ol") ? "</ol>" : "</ul>";
    }

    return html;
}

// Разбивает markdown на блоки: {type: "text", content: "html"} или {type: "code", content: "raw code"}
QVariantList MarkdownService::parseBlocks(const QString &markdown)
{
    QVariantList blocks;
    QStringList lines = markdown.split('\n');
    QStringList textBuffer;
    bool inCodeBlock = false;
    QString codeContent;

    auto flushText = [&]() {
        if (!textBuffer.isEmpty()) {
            QString html = renderTextBlockHtml(textBuffer);
            if (!html.trimmed().isEmpty()) {
                QVariantMap block;
                block["type"] = "text";
                block["content"] = html;
                blocks.append(block);
            }
            textBuffer.clear();
        }
    };

    for (const auto &line : lines) {
        if (line.trimmed().startsWith("```")) {
            if (inCodeBlock) {
                // Закрываем блок кода
                flushText();
                QVariantMap block;
                block["type"] = "code";
                block["content"] = codeContent.trimmed();
                blocks.append(block);
                codeContent.clear();
                inCodeBlock = false;
            } else {
                // Сначала выводим накопленный текст
                flushText();
                inCodeBlock = true;
            }
            continue;
        }

        if (inCodeBlock) {
            codeContent += line + "\n";
        } else {
            textBuffer.append(line);
        }
    }

    // Добавляем оставшийся текст
    flushText();

    // Если код не закрыт
    if (inCodeBlock && !codeContent.isEmpty()) {
        QVariantMap block;
        block["type"] = "code";
        block["content"] = codeContent.trimmed();
        blocks.append(block);
    }

    return blocks;
}
