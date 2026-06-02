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
}

type User struct {
	ID          int    `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Token       string `json:"token,omitempty"`
}

type Favorite struct {
	ID        int       `json:"id"`
	UserID    int       `json:"user_id"`
	ArticleID int       `json:"article_id"`
	CreatedAt time.Time `json:"created_at"`
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
