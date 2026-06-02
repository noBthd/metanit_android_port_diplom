#include "markdown_service.h"

#include <QFile>
#include <QTextStream>
#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QRegularExpression>
#include <QVariantMap>
#include <QSettings>

MarkdownService::MarkdownService(QObject *parent)
    : QObject(parent)
{
}

/// Загружает markdown: сначала из кэша, потом из локальных файлов.
/// На iOS файлов нет — используется только кэш (контент из API).
QString MarkdownService::loadMarkdown(const QString &fileName)
{
    // Проверяем in-memory кэш
    if (m_contentCache.contains(fileName)) {
        return m_contentCache[fileName];
    }

    // Проверяем persistent кэш (QSettings — сохраняется на диске)
    QSettings settings;
    QString key = "cache/article/" + fileName;
    if (settings.contains(key)) {
        QString content = settings.value(key).toString();
        m_contentCache[fileName] = content; // загружаем в in-memory
        return content;
    }

    // Пробуем локальные файлы (десктоп)
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
            QString content = in.readAll();
            m_contentCache[fileName] = content;
            return content;
        }
    }
    return "# Загрузка...\n\nСтатья загружается с сервера.";
}

/// Сохраняет контент в in-memory кэш И на диск (QSettings).
/// При следующем запуске без интернета — статья будет доступна.
void MarkdownService::cacheContent(const QString &fileName, const QString &content)
{
    m_contentCache[fileName] = content;
    // Persistent cache на диск
    QSettings settings;
    settings.setValue("cache/article/" + fileName, content);
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

QString MarkdownService::processInline(const QString &text, bool isDark)
{
    QString result = text;

    // Инлайн-код: `code` — цвета зависят от темы
    QString codeFg = isDark ? "#7ec8e3" : "#0550ae";
    QString codeBg = isDark ? "#262636" : "#e8edf3";

    QRegularExpression inlineCode("`([^`]+)`");
    result.replace(inlineCode,
        "<span style=\"font-family:'Menlo','Courier New',monospace;"
        "font-size:13px;color:" + codeFg + ";"
        "background-color:" + codeBg + ";\"> \\1 </span>");

    QRegularExpression bold("\\*\\*([^*]+)\\*\\*");
    result.replace(bold, "<b>\\1</b>");

    QRegularExpression italic("(?<!\\*)\\*([^*]+)\\*(?!\\*)");
    result.replace(italic, "<i>\\1</i>");

    return result;
}

// Рендерит блок текстовых строк (не-код) в HTML
QString MarkdownService::renderTextBlockHtml(const QStringList &lines, bool isDark)
{
    QString html;
    bool inList = false;
    QString listType;

    // Цвета заголовков — НЕ задаём в HTML, пусть QML Text.color управляет
    // Только размер и жирность задаём через стили

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
            html += "<p style=\"font-size:16px;font-weight:600;margin-top:16px;\">"
                    + processInline(escapeHtml(trimmed.mid(5)), isDark) + "</p>";
            continue;
        }
        if (trimmed.startsWith("### ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"font-size:18px;font-weight:600;margin-top:20px;\">"
                    + processInline(escapeHtml(trimmed.mid(4)), isDark) + "</p>";
            continue;
        }
        if (trimmed.startsWith("## ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"font-size:20px;font-weight:600;margin-top:24px;\">"
                    + processInline(escapeHtml(trimmed.mid(3)), isDark) + "</p>";
            continue;
        }
        if (trimmed.startsWith("# ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"font-size:24px;font-weight:700;\">"
                    + processInline(escapeHtml(trimmed.mid(2)), isDark) + "</p>";
            continue;
        }

        // Горизонтальная линия
        if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td bgcolor=\"#333\" style=\"height:1;\"></td></tr></table>";
            continue;
        }

        // Маркированный список
        if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
            if (!inList || listType != "ul") {
                if (inList) html += (listType == "ol") ? "</ol>" : "</ul>";
                html += "<ul>";
                inList = true; listType = "ul";
            }
            html += "<li>" + processInline(escapeHtml(trimmed.mid(2)), isDark) + "</li>";
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
            html += "<li>" + processInline(escapeHtml(olMatch.captured(2)), isDark) + "</li>";
            continue;
        }

        // Цитата
        if (trimmed.startsWith("> ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<p style=\"color:#8e8e93;font-style:italic;border-left:3px solid #0a84ff;"
                    "padding-left:10px;\">"
                    + processInline(escapeHtml(trimmed.mid(2)), isDark) + "</p>";
            continue;
        }

        // Таблица
        if (trimmed.startsWith("|")) {
            // Skip for now, handled as paragraph
        }

        // Обычный параграф
        if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
        html += "<p>" + processInline(escapeHtml(trimmed), isDark) + "</p>";
    }

    if (inList) {
        html += (listType == "ol") ? "</ol>" : "</ul>";
    }

    return html;
}

// Разбивает markdown на блоки: {type: "text", content: "html"} или {type: "code", content: "raw code"}
QVariantList MarkdownService::parseBlocks(const QString &markdown, bool isDark)
{
    QVariantList blocks;
    QStringList lines = markdown.split('\n');
    QStringList textBuffer;
    bool inCodeBlock = false;
    QString codeContent;

    auto flushText = [&]() {
        if (!textBuffer.isEmpty()) {
            QString html = renderTextBlockHtml(textBuffer, isDark);
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
