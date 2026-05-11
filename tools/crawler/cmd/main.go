package main

import (
	"fmt"

	"metanit_crawler/internal/crawler"
	"metanit_crawler/internal/storage"
)

func main() {

	c := crawler.Crawler{
		StartURL: "https://metanit.com/cpp/tutorial/",
	}

	articles := c.Run()

	err := storage.SaveArticles("../../../data/articles.json", articles)
	if err != nil {
		panic(err)
	}

	fmt.Println("Done! Articles:", len(articles))
}