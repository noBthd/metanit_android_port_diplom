package models

import "time"

type Article struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	Link        string `json:"link"`
	File        string `json:"file"`
	Chapter     int    `json:"chapter"`
	ChapterName string `json:"chapterName"`
	Content     string `json:"content,omitempty"`
	ReadingTime int    `json:"reading_time"` // минуты на чтение
	WordCount   int    `json:"word_count"`
}

type User struct {
	ID          int    `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Token       string `json:"token,omitempty"`
}

type RegisterRequest struct {
	Username    string `json:"username"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token       string `json:"token"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	UserID      int    `json:"user_id"`
}

type UpdateProfileRequest struct {
	DisplayName string `json:"display_name,omitempty"`
	NewPassword string `json:"new_password,omitempty"`
	OldPassword string `json:"old_password,omitempty"`
}

type FavoriteRequest struct {
	ArticleID int `json:"article_id"`
}

// Прогресс чтения
type ReadProgress struct {
	UserID    int       `json:"user_id"`
	ArticleID int       `json:"article_id"`
	File      string    `json:"file"`
	ReadAt    time.Time `json:"read_at"`
}

// Заметка к статье
type Note struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	File      string    `json:"file"`
	Text      string    `json:"text"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type NoteRequest struct {
	File string `json:"file"`
	Text string `json:"text"`
}

// Статистика
type Stats struct {
	TotalUsers      int            `json:"total_users"`
	TotalArticles   int            `json:"total_articles"`
	TotalFavorites  int            `json:"total_favorites"`
	TotalReads      int            `json:"total_reads"`
	PopularArticles []ArticleStat  `json:"popular_articles"`
}

type ArticleStat struct {
	Title     string `json:"title"`
	File      string `json:"file"`
	ReadCount int    `json:"read_count"`
	FavCount  int    `json:"fav_count"`
}

// Прогресс пользователя
type UserProgress struct {
	TotalArticles int              `json:"total_articles"`
	ReadArticles  int              `json:"read_articles"`
	Percent       int              `json:"percent"`
	Chapters      []ChapterProgress `json:"chapters"`
}

type ChapterProgress struct {
	Chapter     int    `json:"chapter"`
	ChapterName string `json:"chapter_name"`
	Total       int    `json:"total"`
	Read        int    `json:"read"`
	Percent     int    `json:"percent"`
}
