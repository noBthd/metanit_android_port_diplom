#include "markdown_service.h"

#include <QFile>
#include <QTextStream>
#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QRegularExpression>

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

    // Инлайн-код: `code` — без лишних пробелов, с закруглениями через unicode
    // Qt Rich Text не поддерживает border-radius, поэтому просто фон + цвет без пробелов
    QRegularExpression inlineCode("`([^`]+)`");
    result.replace(inlineCode,
        "<span style=\"font-family:'Menlo','Courier New',monospace;"
        "font-size:13px;color:#7ec8e3;"
        "background-color:#232336;\">&#8202;\\1&#8202;</span>");

    // Жирный: **text**
    QRegularExpression bold("\\*\\*([^*]+)\\*\\*");
    result.replace(bold, "<b>\\1</b>");

    // Курсив: *text*
    QRegularExpression italic("(?<!\\*)\\*([^*]+)\\*(?!\\*)");
    result.replace(italic, "<i>\\1</i>");

    return result;
}

QString MarkdownService::markdownToHtml(const QString &markdown)
{
    QStringList lines = markdown.split('\n');
    QString html;
    bool inCodeBlock = false;
    QString codeContent;
    bool inList = false;
    QString listType;

    for (int i = 0; i < lines.size(); i++) {
        const QString &line = lines[i];

        // === Блоки кода ===
        if (line.trimmed().startsWith("```")) {
            if (inCodeBlock) {
                // Закрываем блок кода — тёмный фон, гармоничный цвет
                html += "<table width=\"100%\" cellpadding=\"14\" cellspacing=\"0\" "
                        "bgcolor=\"#1c1c2e\">"
                        "<tr><td>"
                        "<pre style=\"font-family:'Menlo','Courier New',monospace;"
                        "font-size:13px;color:#d4d4d4;"
                        "white-space:pre-wrap;margin:0;\">"
                        + escapeHtml(codeContent.trimmed())
                        + "</pre>"
                        "</td></tr></table><br/>";
                codeContent.clear();
                inCodeBlock = false;
            } else {
                if (inList) {
                    html += (listType == "ol") ? "</ol>" : "</ul>";
                    inList = false;
                }
                inCodeBlock = true;
            }
            continue;
        }

        if (inCodeBlock) {
            codeContent += line + "\n";
            continue;
        }

        QString trimmed = line.trimmed();

        // Пустые строки
        if (trimmed.isEmpty()) {
            if (inList) {
                html += (listType == "ol") ? "</ol>" : "</ul>";
                inList = false;
            }
            continue;
        }

        // === Заголовки с разделительной линией сверху ===
        if (trimmed.startsWith("#### ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<br/><table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td style=\"border-top:1px solid #2a2a2e;padding-top:14px;\">"
                    "<p style=\"font-size:16px;font-weight:600;color:#e0e0e0;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(5)))
                    + "</p></td></tr></table><br/>";
            continue;
        }
        if (trimmed.startsWith("### ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<br/><table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td style=\"border-top:1px solid #2a2a2e;padding-top:16px;\">"
                    "<p style=\"font-size:18px;font-weight:600;color:#f0f0f0;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(4)))
                    + "</p></td></tr></table><br/>";
            continue;
        }
        if (trimmed.startsWith("## ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<br/><table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">"
                    "<tr><td style=\"border-top:1px solid #2a2a2e;padding-top:18px;\">"
                    "<p style=\"font-size:20px;font-weight:600;color:#ffffff;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(3)))
                    + "</p></td></tr></table><br/>";
            continue;
        }
        if (trimmed.startsWith("# ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            // Первый заголовок — без линии сверху
            html += "<p style=\"font-size:24px;font-weight:700;color:#ffffff;margin-bottom:8px;\">"
                    + processInline(escapeHtml(trimmed.mid(2)))
                    + "</p>";
            continue;
        }

        // === Горизонтальная линия ===
        if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<hr/>";
            continue;
        }

        // === Маркированный список ===
        if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
            if (!inList || listType != "ul") {
                if (inList) html += (listType == "ol") ? "</ol>" : "</ul>";
                html += "<ul>";
                inList = true;
                listType = "ul";
            }
            html += "<li>" + processInline(escapeHtml(trimmed.mid(2))) + "</li>";
            continue;
        }

        // === Нумерованный список ===
        QRegularExpression olRegex("^(\\d+)\\.\\s+(.*)$");
        QRegularExpressionMatch olMatch = olRegex.match(trimmed);
        if (olMatch.hasMatch()) {
            if (!inList || listType != "ol") {
                if (inList) html += (listType == "ol") ? "</ol>" : "</ul>";
                html += "<ol>";
                inList = true;
                listType = "ol";
            }
            html += "<li>" + processInline(escapeHtml(olMatch.captured(2))) + "</li>";
            continue;
        }

        // === Цитата ===
        if (trimmed.startsWith("> ")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"8\" cellspacing=\"0\" bgcolor=\"#1c1c2e\">"
                    "<tr><td style=\"border-left:3px solid #0a84ff;\">"
                    "<p style=\"color:#b0bec5;margin:0;\">"
                    + processInline(escapeHtml(trimmed.mid(2)))
                    + "</p></td></tr></table><br/>";
            continue;
        }

        // === Таблица ===
        if (trimmed.startsWith("|")) {
            if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
            html += "<table width=\"100%\" cellpadding=\"6\" cellspacing=\"0\" "
                    "border=\"1\" bordercolor=\"#333\">";
            int tableStart = i;
            bool headerDone = false;
            while (i < lines.size() && lines[i].trimmed().startsWith("|")) {
                QString tline = lines[i].trimmed();
                if (tline.contains("---")) {
                    headerDone = true;
                    i++;
                    continue;
                }
                QStringList cells = tline.split("|", Qt::SkipEmptyParts);
                if (i == tableStart && !headerDone) {
                    html += "<tr>";
                    for (const auto &cell : cells) {
                        html += "<td bgcolor=\"#1c1c2e\" style=\"color:#ffffff;\"><b>"
                                + processInline(escapeHtml(cell.trimmed()))
                                + "</b></td>";
                    }
                    html += "</tr>";
                } else {
                    html += "<tr>";
                    for (const auto &cell : cells) {
                        html += "<td style=\"color:#d0d0d0;\">"
                                + processInline(escapeHtml(cell.trimmed()))
                                + "</td>";
                    }
                    html += "</tr>";
                }
                i++;
            }
            html += "</table><br/>";
            i--;
            continue;
        }

        // === Обычный параграф ===
        if (inList) { html += (listType == "ol") ? "</ol>" : "</ul>"; inList = false; }
        html += "<p>" + processInline(escapeHtml(trimmed)) + "</p>";
    }

    // Закрываем незакрытые элементы
    if (inList) {
        html += (listType == "ol") ? "</ol>" : "</ul>";
    }
    if (inCodeBlock && !codeContent.isEmpty()) {
        html += "<table width=\"100%\" cellpadding=\"14\" cellspacing=\"0\" "
                "bgcolor=\"#1c1c2e\">"
                "<tr><td>"
                "<pre style=\"font-family:'Menlo','Courier New',monospace;"
                "font-size:13px;color:#d4d4d4;"
                "white-space:pre-wrap;margin:0;\">"
                + escapeHtml(codeContent.trimmed())
                + "</pre>"
                "</td></tr></table><br/>";
    }

    return html;
}
