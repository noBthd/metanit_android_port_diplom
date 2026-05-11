package crawler

import (
	"fmt"
	"strings"

	"metanit_crawler/internal/model"

	"github.com/gocolly/colly"
)

type Crawler struct {
	StartURL string
}

func (c *Crawler) Run() []model.Article {

	collector := colly.NewCollector(
		colly.AllowedDomains("metanit.com"),
	)

	articles := []model.Article{}

	seen := make(map[string]bool)

	collector.OnHTML("a", func(e *colly.HTMLElement) {

		link := e.Attr("href")
		text := e.Text

		if link == "" || text == "" {
			return
		}

		if !isValid(link) {
			return
		}

		full := e.Request.AbsoluteURL(link)

		if seen[full] {
			return
		}
		seen[full] = true

		var linkStrs = strings.Split(full, "/")

		articles = append(articles, model.Article{
			Title: text,
			Link:  full,
			File: strings.ReplaceAll(linkStrs[len(linkStrs)-1], "php", "md"),
		})
	})

	collector.OnRequest(func(r *colly.Request) {
		fmt.Println("Visiting:", r.URL.String())
	})

	collector.Visit(c.StartURL)

	return articles
}

func isValid(link string) bool {

	if link == "" {
		return false
	}

	if link[0] == '#' || contains(link, "javascript:") {
		return false
	}

	if contains(link, "http") && !contains(link, "metanit.com") {
		return false
	}

	if contains(link, "tutorial") && contains(link, ".php") {
		return true
	}

	return false
}

func contains(s, sub string) bool {
	for i := 0; i <= len(s)-len(sub); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}