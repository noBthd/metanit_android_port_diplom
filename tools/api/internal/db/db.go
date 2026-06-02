package db

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
	"metanit_api/internal/models"
)

type DB struct {
	conn *sql.DB
}

func New(host, port, user, password, dbname string) (*DB, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	conn, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}
	if err := conn.Ping(); err != nil {
		return nil, err
	}
	return &DB{conn: conn}, nil
}

func (d *DB) InitSchema() error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		username VARCHAR(100) UNIQUE NOT NULL,
		display_name VARCHAR(200) NOT NULL DEFAULT '',
		password_hash VARCHAR(255) NOT NULL,
		token VARCHAR(255) UNIQUE,
		created_at TIMESTAMP DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS articles (
		id SERIAL PRIMARY KEY,
		title TEXT NOT NULL,
		link TEXT,
		file VARCHAR(50) UNIQUE NOT NULL,
		chapter INT NOT NULL,
		chapter_name VARCHAR(200),
		content TEXT,
		updated_at TIMESTAMP DEFAULT NOW()
	);

	CREATE TABLE IF NOT EXISTS favorites (
		id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(id) ON DELETE CASCADE,
		article_id INT REFERENCES articles(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT NOW(),
		UNIQUE(user_id, article_id)
	);

	-- Add display_name column if missing (for existing DBs)
	DO $$ BEGIN
		ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(200) NOT NULL DEFAULT '';
	EXCEPTION WHEN OTHERS THEN NULL;
	END $$;
	`
	_, err := d.conn.Exec(schema)
	return err
}

func generateToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// === Users ===

func (d *DB) Register(username, password, displayName string) (*models.AuthResponse, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	token := generateToken()
	var id int
	err = d.conn.QueryRow(
		"INSERT INTO users (username, password_hash, display_name, token) VALUES ($1, $2, $3, $4) RETURNING id",
		username, string(hash), displayName, token,
	).Scan(&id)
	if err != nil {
		return nil, fmt.Errorf("Пользователь с таким именем уже существует")
	}
	return &models.AuthResponse{Token: token, Username: username, DisplayName: displayName, UserID: id}, nil
}

func (d *DB) Login(username, password string) (*models.AuthResponse, error) {
	var id int
	var hash, displayName string
	err := d.conn.QueryRow(
		"SELECT id, password_hash, display_name FROM users WHERE username=$1", username,
	).Scan(&id, &hash, &displayName)
	if err != nil {
		return nil, fmt.Errorf("Неверный логин или пароль")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)); err != nil {
		return nil, fmt.Errorf("Неверный логин или пароль")
	}
	token := generateToken()
	d.conn.Exec("UPDATE users SET token=$1 WHERE id=$2", token, id)
	return &models.AuthResponse{Token: token, Username: username, DisplayName: displayName, UserID: id}, nil
}

func (d *DB) GetUserByToken(token string) (*models.User, error) {
	var u models.User
	err := d.conn.QueryRow(
		"SELECT id, username, display_name FROM users WHERE token=$1", token,
	).Scan(&u.ID, &u.Username, &u.DisplayName)
	if err != nil {
		return nil, fmt.Errorf("unauthorized")
	}
	return &u, nil
}

func (d *DB) UpdateProfile(userID int, displayName, oldPassword, newPassword string) error {
	if displayName != "" {
		d.conn.Exec("UPDATE users SET display_name=$1 WHERE id=$2", displayName, userID)
	}
	if newPassword != "" && oldPassword != "" {
		var hash string
		err := d.conn.QueryRow("SELECT password_hash FROM users WHERE id=$1", userID).Scan(&hash)
		if err != nil {
			return fmt.Errorf("Пользователь не найден")
		}
		if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(oldPassword)); err != nil {
			return fmt.Errorf("Неверный текущий пароль")
		}
		newHash, _ := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
		d.conn.Exec("UPDATE users SET password_hash=$1 WHERE id=$2", string(newHash), userID)
	}
	return nil
}

// === Articles ===

func (d *DB) UpsertArticle(a models.Article) error {
	_, err := d.conn.Exec(`
		INSERT INTO articles (title, link, file, chapter, chapter_name, content)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (file) DO UPDATE SET
			title=EXCLUDED.title, link=EXCLUDED.link,
			chapter=EXCLUDED.chapter, chapter_name=EXCLUDED.chapter_name,
			content=EXCLUDED.content, updated_at=NOW()`,
		a.Title, a.Link, a.File, a.Chapter, a.ChapterName, a.Content)
	return err
}

func (d *DB) GetArticles() ([]models.Article, error) {
	rows, err := d.conn.Query(
		"SELECT id, title, link, file, chapter, chapter_name FROM articles ORDER BY chapter, file")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var articles []models.Article
	for rows.Next() {
		var a models.Article
		rows.Scan(&a.ID, &a.Title, &a.Link, &a.File, &a.Chapter, &a.ChapterName)
		articles = append(articles, a)
	}
	return articles, nil
}

func (d *DB) GetArticleContent(file string) (string, error) {
	var content string
	err := d.conn.QueryRow("SELECT COALESCE(content,'') FROM articles WHERE file=$1", file).Scan(&content)
	return content, err
}

// === Favorites ===

func (d *DB) AddFavorite(userID, articleID int) error {
	_, err := d.conn.Exec(
		"INSERT INTO favorites (user_id, article_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
		userID, articleID)
	return err
}

func (d *DB) RemoveFavorite(userID, articleID int) error {
	_, err := d.conn.Exec(
		"DELETE FROM favorites WHERE user_id=$1 AND article_id=$2", userID, articleID)
	return err
}

func (d *DB) GetFavorites(userID int) ([]models.Article, error) {
	rows, err := d.conn.Query(`
		SELECT a.id, a.title, a.link, a.file, a.chapter, a.chapter_name
		FROM favorites f JOIN articles a ON f.article_id = a.id
		WHERE f.user_id=$1 ORDER BY f.created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var articles []models.Article
	for rows.Next() {
		var a models.Article
		rows.Scan(&a.ID, &a.Title, &a.Link, &a.File, &a.Chapter, &a.ChapterName)
		articles = append(articles, a)
	}
	return articles, nil
}
