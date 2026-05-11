package storage

import (
	"encoding/json"
	"os"

	"metanit_crawler/internal/model"
)

func SaveArticles(path string, articles []model.Article) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	return encoder.Encode(articles)
}