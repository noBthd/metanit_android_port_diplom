package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"metanit_link_to_md/internal/model"
	"metanit_link_to_md/internal/parser"
	"metanit_link_to_md/internal/storage"

	"github.com/gocolly/colly"
)

func main() {

    file, err := os.ReadFile("../../../data/articles.json")
    if err != nil {
        panic(err)
    }

    var articles []model.Article

    err = json.Unmarshal(file, &articles)
    if err != nil {
        panic(err)
    }

    collector := colly.NewCollector(
        colly.AllowedDomains("metanit.com"),
    )

    collector.OnRequest(func(r *colly.Request) {
        fmt.Println("Visiting:", r.URL.String())
    })

    collector.OnHTML("html", func(e *colly.HTMLElement) {

        article := e.Request.Ctx.GetAny("article").(model.Article)

        markdown := parser.ExtractMarkdown(e.DOM)

        outputPath := filepath.Join(
            "../../../data/articles",
            article.File,
        )

        err := storage.SaveMarkdown(
            outputPath,
            markdown,
        )

        if err != nil {
            fmt.Println("Save error:", err)
            return
        }

        fmt.Println("Saved:", article.File)
    })

    for _, article := range articles {

        ctx := colly.NewContext()
        ctx.Put("article", article)

        err := collector.Request(
            "GET",
            article.Link,
            nil,
            ctx,
            nil,
        )

        if err != nil {
            fmt.Println("Request error:", err)
        }
    }

    fmt.Println("Done")
}