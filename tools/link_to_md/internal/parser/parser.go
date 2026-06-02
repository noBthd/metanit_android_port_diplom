package parser

import (
	"strings"

	"github.com/PuerkitoBio/goquery"
)

// навигационные строки, которые нужно удалить
var skipTexts = []string{
	"Назад",
	"Вперед",
	"Содержание",
	"НазадСодержаниеВперед",
	"НазадВперед",
	"НазадСодержание",
	"СодержаниеВперед",
}

func shouldSkip(text string) bool {
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return true
	}

	for _, skip := range skipTexts {
		if trimmed == skip {
			return true
		}
	}

	// Пропускаем текст навигации вроде "Назад Содержание Вперед"
	cleaned := strings.ReplaceAll(trimmed, " ", "")
	for _, skip := range skipTexts {
		if cleaned == skip {
			return true
		}
	}

	return false
}

func isNavElement(s *goquery.Selection) bool {
	// Проверяем, не является ли это навигационной ссылкой
	href, exists := s.Attr("href")
	if exists {
		text := strings.TrimSpace(s.Text())
		if (text == "Назад" || text == "Вперед" || text == "Содержание") && strings.Contains(href, ".php") {
			return true
		}
	}
	return false
}

func ExtractMarkdown(doc *goquery.Selection) string {
	var builder strings.Builder

	// Получаем заголовок статьи из h2
	title := strings.TrimSpace(doc.Find("h2").First().Text())
	if title != "" {
		builder.WriteString("# " + title + "\n\n")
	}

	// Находим основной контейнер контента
	content := doc.Find(".item.center.menC")
	if content.Length() == 0 {
		// Если не найден, пробуем альтернативные селекторы
		content = doc.Find(".content")
	}

	// Обходим дочерние элементы ПОСЛЕДОВАТЕЛЬНО для сохранения порядка
	content.Children().Each(func(i int, s *goquery.Selection) {
		processElement(&builder, s)
	})

	result := builder.String()

	// Финальная очистка: убираем оставшуюся навигацию
	lines := strings.Split(result, "\n")
	var cleaned []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if shouldSkip(trimmed) {
			continue
		}
		// Пропускаем строки, содержащие только "Назад", "Содержание", "Вперед"
		if isNavLine(trimmed) {
			continue
		}
		cleaned = append(cleaned, line)
	}

	return strings.Join(cleaned, "\n")
}

func isNavLine(line string) bool {
	stripped := strings.ReplaceAll(line, " ", "")
	stripped = strings.ReplaceAll(stripped, "\t", "")

	navWords := []string{"Назад", "Содержание", "Вперед"}

	temp := stripped
	for _, word := range navWords {
		temp = strings.ReplaceAll(temp, word, "")
	}
	// Если после удаления всех навигационных слов ничего не осталось — это навигация
	if len(stripped) > 0 && temp == "" {
		return true
	}
	return false
}

func processElement(builder *strings.Builder, s *goquery.Selection) {
	tag := goquery.NodeName(s)

	switch tag {
	case "h1":
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString("# " + text + "\n\n")
		}

	case "h2":
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString("## " + text + "\n\n")
		}

	case "h3":
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString("### " + text + "\n\n")
		}

	case "h4":
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString("#### " + text + "\n\n")
		}

	case "p":
		text := extractInlineContent(s)
		if shouldSkip(text) {
			return
		}
		builder.WriteString(text + "\n\n")

	case "pre":
		code := strings.TrimSpace(s.Text())
		if code == "" {
			return
		}
		builder.WriteString("```cpp\n")
		builder.WriteString(code)
		builder.WriteString("\n```\n\n")

	case "ul":
		s.Find("li").Each(func(i int, li *goquery.Selection) {
			text := strings.TrimSpace(li.Text())
			if text != "" && !shouldSkip(text) {
				builder.WriteString("- " + text + "\n")
			}
		})
		builder.WriteString("\n")

	case "ol":
		s.Find("li").Each(func(i int, li *goquery.Selection) {
			text := strings.TrimSpace(li.Text())
			if text != "" && !shouldSkip(text) {
				builder.WriteString(strings.Repeat(" ", 0))
				builder.WriteString(string(rune('1'+i)) + ". " + text + "\n")
			}
		})
		builder.WriteString("\n")

	case "table":
		processTable(builder, s)

	case "div":
		// Проверяем, что это не навигация или реклама
		class, _ := s.Attr("class")

		// Пропускаем навигационные и служебные блоки
		if strings.Contains(class, "nav") ||
			strings.Contains(class, "socBlock") ||
			strings.Contains(class, "comments") ||
			strings.Contains(class, "subscribe") {
			return
		}

		// Рекурсивно обрабатываем дочерние элементы div
		s.Children().Each(func(i int, child *goquery.Selection) {
			processElement(builder, child)
		})

	case "blockquote":
		text := strings.TrimSpace(s.Text())
		if text != "" {
			lines := strings.Split(text, "\n")
			for _, line := range lines {
				builder.WriteString("> " + strings.TrimSpace(line) + "\n")
			}
			builder.WriteString("\n")
		}

	case "hr":
		builder.WriteString("---\n\n")

	case "img":
		// Пропускаем изображения (они не будут отображаться в приложении)

	case "a":
		// Пропускаем навигационные ссылки
		if isNavElement(s) {
			return
		}
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString(text)
		}

	case "span":
		text := strings.TrimSpace(s.Text())
		if text != "" && !shouldSkip(text) {
			builder.WriteString(text)
		}

	case "br":
		builder.WriteString("\n")
	}
}

func extractInlineContent(s *goquery.Selection) string {
	var result strings.Builder

	s.Contents().Each(func(i int, child *goquery.Selection) {
		tag := goquery.NodeName(child)

		switch tag {
		case "#text":
			result.WriteString(child.Text())

		case "code", "kbd":
			code := strings.TrimSpace(child.Text())
			if code != "" {
				result.WriteString("`" + code + "`")
			}

		case "strong", "b":
			text := strings.TrimSpace(child.Text())
			if text != "" {
				result.WriteString("**" + text + "**")
			}

		case "em", "i":
			text := strings.TrimSpace(child.Text())
			if text != "" {
				result.WriteString("*" + text + "*")
			}

		case "a":
			text := strings.TrimSpace(child.Text())
			if text != "" && !shouldSkip(text) {
				result.WriteString(text)
			}

		case "br":
			result.WriteString("\n")

		case "span":
			text := strings.TrimSpace(child.Text())
			if text != "" {
				result.WriteString(text)
			}

		default:
			text := strings.TrimSpace(child.Text())
			if text != "" {
				result.WriteString(text)
			}
		}
	})

	return strings.TrimSpace(result.String())
}

func processTable(builder *strings.Builder, s *goquery.Selection) {
	// Извлекаем таблицу в markdown-формат
	var headers []string
	var rows [][]string

	s.Find("thead tr th, thead tr td").Each(func(i int, th *goquery.Selection) {
		headers = append(headers, strings.TrimSpace(th.Text()))
	})

	// Если нет thead, берём первую строку как заголовок
	if len(headers) == 0 {
		first := s.Find("tr").First()
		first.Find("th, td").Each(func(i int, td *goquery.Selection) {
			headers = append(headers, strings.TrimSpace(td.Text()))
		})
	}

	s.Find("tbody tr, tr").Each(func(i int, tr *goquery.Selection) {
		var row []string
		tr.Find("td").Each(func(j int, td *goquery.Selection) {
			row = append(row, strings.TrimSpace(td.Text()))
		})
		if len(row) > 0 {
			rows = append(rows, row)
		}
	})

	if len(headers) > 0 {
		builder.WriteString("| " + strings.Join(headers, " | ") + " |\n")
		sep := make([]string, len(headers))
		for i := range sep {
			sep[i] = "---"
		}
		builder.WriteString("| " + strings.Join(sep, " | ") + " |\n")
	}

	for _, row := range rows {
		builder.WriteString("| " + strings.Join(row, " | ") + " |\n")
	}
	builder.WriteString("\n")
}
