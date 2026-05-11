package parser

import (
	"strings"

	"github.com/PuerkitoBio/goquery"
)

func ExtractMarkdown(doc *goquery.Selection) string {

	var builder strings.Builder

	title := doc.Find("h2").First().Text()

	builder.WriteString("# " + title + "\n\n")

	doc.Find(".item.center.menC p").Each(func(i int, s *goquery.Selection) {

		text := strings.TrimSpace(s.Text())

		if text == "" {
			return
		}

		builder.WriteString(text)
		builder.WriteString("\n\n")
	})

	doc.Find(".item.center.menC pre").Each(func(i int, s *goquery.Selection) {

		code := strings.TrimSpace(s.Text())

		if code == "" {
			return
		}

		builder.WriteString("```cpp\n")
		builder.WriteString(code)
		builder.WriteString("\n```\n\n")
	})

	return builder.String()
}