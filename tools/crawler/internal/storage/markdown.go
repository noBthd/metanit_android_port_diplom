package storage

import "os"

func SaveMarkdown(path string, content string) error {

	return os.WriteFile(
		path,
		[]byte(content),
		0644,
	)
}