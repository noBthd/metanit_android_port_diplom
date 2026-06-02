package db

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"strings"
	"unicode/utf8"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
	"metanit_api/internal/models"
)

type DB struct{ conn *sql.DB }

func New(host, port, user, password, dbname string) (*DB, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	conn, err := sql.Open("postgres", dsn)
	if err != nil { return nil, err }
	if err := conn.Ping(); err != nil { return nil, err }
	return &DB{conn: conn}, nil
}

func (d *DB) InitSchema() error {
	_, err := d.conn.Exec(`
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY, username VARCHAR(100) UNIQUE NOT NULL,
		display_name VARCHAR(200) NOT NULL DEFAULT '',
		password_hash VARCHAR(255) NOT NULL, token VARCHAR(255) UNIQUE,
		created_at TIMESTAMP DEFAULT NOW()
	);
	CREATE TABLE IF NOT EXISTS articles (
		id SERIAL PRIMARY KEY, title TEXT NOT NULL, link TEXT,
		file VARCHAR(50) UNIQUE NOT NULL, chapter INT NOT NULL,
		chapter_name VARCHAR(200), content TEXT, word_count INT DEFAULT 0,
		updated_at TIMESTAMP DEFAULT NOW()
	);
	CREATE TABLE IF NOT EXISTS favorites (
		id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(id) ON DELETE CASCADE,
		article_id INT REFERENCES articles(id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, article_id)
	);
	CREATE TABLE IF NOT EXISTS read_articles (
		id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(id) ON DELETE CASCADE,
		article_id INT REFERENCES articles(id) ON DELETE CASCADE,
		read_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, article_id)
	);
	CREATE TABLE IF NOT EXISTS notes (
		id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(id) ON DELETE CASCADE,
		file VARCHAR(50) NOT NULL,
		text TEXT NOT NULL DEFAULT '',
		created_at TIMESTAMP DEFAULT NOW(),
		updated_at TIMESTAMP DEFAULT NOW(),
		UNIQUE(user_id, file)
	);
	DO $$ BEGIN
		ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(200) NOT NULL DEFAULT '';
	EXCEPTION WHEN OTHERS THEN NULL; END $$;
	DO $$ BEGIN
		ALTER TABLE articles ADD COLUMN IF NOT EXISTS word_count INT DEFAULT 0;
	EXCEPTION WHEN OTHERS THEN NULL; END $$;
	`)
	return err
}

func generateToken() string {
	b := make([]byte, 32); rand.Read(b); return hex.EncodeToString(b)
}

// === Users ===

func (d *DB) Register(username, password, displayName string) (*models.AuthResponse, error) {
	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	token := generateToken()
	var id int
	err := d.conn.QueryRow(
		"INSERT INTO users (username, password_hash, display_name, token) VALUES ($1,$2,$3,$4) RETURNING id",
		username, string(hash), displayName, token).Scan(&id)
	if err != nil {
		if strings.Contains(err.Error(), "unique") || strings.Contains(err.Error(), "duplicate") {
			return nil, fmt.Errorf("Пользователь с таким именем уже существует")
		}
		return nil, fmt.Errorf("Ошибка регистрации: %v", err)
	}
	return &models.AuthResponse{Token: token, Username: username, DisplayName: displayName, UserID: id}, nil
}

func (d *DB) Login(username, password string) (*models.AuthResponse, error) {
	var id int; var hash, dn string
	err := d.conn.QueryRow("SELECT id, password_hash, display_name FROM users WHERE username=$1", username).Scan(&id, &hash, &dn)
	if err != nil { return nil, fmt.Errorf("Неверный логин или пароль") }
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)); err != nil {
		return nil, fmt.Errorf("Неверный логин или пароль")
	}
	token := generateToken()
	d.conn.Exec("UPDATE users SET token=$1 WHERE id=$2", token, id)
	return &models.AuthResponse{Token: token, Username: username, DisplayName: dn, UserID: id}, nil
}

func (d *DB) GetUserByToken(token string) (*models.User, error) {
	var u models.User
	err := d.conn.QueryRow("SELECT id, username, display_name FROM users WHERE token=$1", token).Scan(&u.ID, &u.Username, &u.DisplayName)
	if err != nil { return nil, fmt.Errorf("unauthorized") }
	return &u, nil
}

func (d *DB) UpdateProfile(userID int, displayName, oldPass, newPass string) error {
	if displayName != "" { d.conn.Exec("UPDATE users SET display_name=$1 WHERE id=$2", displayName, userID) }
	if newPass != "" && oldPass != "" {
		var hash string
		if err := d.conn.QueryRow("SELECT password_hash FROM users WHERE id=$1", userID).Scan(&hash); err != nil {
			return fmt.Errorf("Пользователь не найден")
		}
		if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(oldPass)); err != nil {
			return fmt.Errorf("Неверный текущий пароль")
		}
		h, _ := bcrypt.GenerateFromPassword([]byte(newPass), bcrypt.DefaultCost)
		d.conn.Exec("UPDATE users SET password_hash=$1 WHERE id=$2", string(h), userID)
	}
	return nil
}

// === Articles ===

func countWords(s string) int {
	return utf8.RuneCountInString(strings.TrimSpace(s)) / 5 // ~5 символов на слово для русского
}

func (d *DB) UpsertArticle(a models.Article) error {
	wc := countWords(a.Content)
	_, err := d.conn.Exec(`
		INSERT INTO articles (title, link, file, chapter, chapter_name, content, word_count)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT (file) DO UPDATE SET title=EXCLUDED.title, link=EXCLUDED.link,
			chapter=EXCLUDED.chapter, chapter_name=EXCLUDED.chapter_name,
			content=EXCLUDED.content, word_count=EXCLUDED.word_count, updated_at=NOW()`,
		a.Title, a.Link, a.File, a.Chapter, a.ChapterName, a.Content, wc)
	return err
}

func (d *DB) GetArticles() ([]models.Article, error) {
	rows, err := d.conn.Query(
		"SELECT id, title, link, file, chapter, chapter_name, COALESCE(word_count,0) FROM articles ORDER BY chapter, file")
	if err != nil { return nil, err }
	defer rows.Close()
	var arts []models.Article
	for rows.Next() {
		var a models.Article
		rows.Scan(&a.ID, &a.Title, &a.Link, &a.File, &a.Chapter, &a.ChapterName, &a.WordCount)
		a.ReadingTime = a.WordCount/200 + 1 // ~200 слов/мин
		arts = append(arts, a)
	}
	return arts, nil
}

func (d *DB) GetArticleContent(file string) (string, error) {
	var content string
	err := d.conn.QueryRow("SELECT COALESCE(content,'') FROM articles WHERE file=$1", file).Scan(&content)
	return content, err
}

// Полнотекстовый поиск
func (d *DB) SearchArticles(query string) ([]models.Article, error) {
	rows, err := d.conn.Query(`
		SELECT id, title, link, file, chapter, chapter_name, COALESCE(word_count,0)
		FROM articles
		WHERE title ILIKE '%' || $1 || '%' OR content ILIKE '%' || $1 || '%'
		ORDER BY chapter, file LIMIT 50`, query)
	if err != nil { return nil, err }
	defer rows.Close()
	var arts []models.Article
	for rows.Next() {
		var a models.Article
		rows.Scan(&a.ID, &a.Title, &a.Link, &a.File, &a.Chapter, &a.ChapterName, &a.WordCount)
		a.ReadingTime = a.WordCount/200 + 1
		arts = append(arts, a)
	}
	return arts, nil
}

// === Favorites ===

func (d *DB) ToggleFavoriteByFile(userID int, file string) (bool, error) {
	var articleID int
	if err := d.conn.QueryRow("SELECT id FROM articles WHERE file=$1", file).Scan(&articleID); err != nil {
		return false, fmt.Errorf("Статья не найдена")
	}
	var count int
	d.conn.QueryRow("SELECT COUNT(*) FROM favorites WHERE user_id=$1 AND article_id=$2", userID, articleID).Scan(&count)
	if count > 0 {
		d.conn.Exec("DELETE FROM favorites WHERE user_id=$1 AND article_id=$2", userID, articleID)
		return false, nil
	}
	d.conn.Exec("INSERT INTO favorites (user_id, article_id) VALUES ($1,$2) ON CONFLICT DO NOTHING", userID, articleID)
	return true, nil
}

func (d *DB) IsFavoriteByFile(userID int, file string) bool {
	var c int
	d.conn.QueryRow("SELECT COUNT(*) FROM favorites f JOIN articles a ON f.article_id=a.id WHERE f.user_id=$1 AND a.file=$2", userID, file).Scan(&c)
	return c > 0
}

func (d *DB) GetFavorites(userID int) ([]models.Article, error) {
	rows, err := d.conn.Query(`SELECT a.id, a.title, a.link, a.file, a.chapter, a.chapter_name
		FROM favorites f JOIN articles a ON f.article_id=a.id WHERE f.user_id=$1 ORDER BY f.created_at DESC`, userID)
	if err != nil { return nil, err }
	defer rows.Close()
	var arts []models.Article
	for rows.Next() {
		var a models.Article
		rows.Scan(&a.ID, &a.Title, &a.Link, &a.File, &a.Chapter, &a.ChapterName)
		arts = append(arts, a)
	}
	return arts, nil
}

// === Progress ===

func (d *DB) ToggleRead(userID int, file string) (bool, error) {
	var articleID int
	if err := d.conn.QueryRow("SELECT id FROM articles WHERE file=$1", file).Scan(&articleID); err != nil {
		return false, err
	}
	var count int
	d.conn.QueryRow("SELECT COUNT(*) FROM read_articles WHERE user_id=$1 AND article_id=$2", userID, articleID).Scan(&count)
	if count > 0 {
		d.conn.Exec("DELETE FROM read_articles WHERE user_id=$1 AND article_id=$2", userID, articleID)
		return false, nil
	}
	d.conn.Exec("INSERT INTO read_articles (user_id, article_id) VALUES ($1,$2) ON CONFLICT DO NOTHING", userID, articleID)
	return true, nil
}

func (d *DB) IsRead(userID int, file string) bool {
	var c int
	d.conn.QueryRow("SELECT COUNT(*) FROM read_articles r JOIN articles a ON r.article_id=a.id WHERE r.user_id=$1 AND a.file=$2", userID, file).Scan(&c)
	return c > 0
}

func (d *DB) GetProgress(userID int) (*models.UserProgress, error) {
	var total, read int
	d.conn.QueryRow("SELECT COUNT(*) FROM articles").Scan(&total)
	d.conn.QueryRow("SELECT COUNT(*) FROM read_articles WHERE user_id=$1", userID).Scan(&read)

	pct := 0
	if total > 0 { pct = read * 100 / total }

	// По главам
	rows, err := d.conn.Query(`
		SELECT a.chapter, a.chapter_name, COUNT(a.id) as total,
			COUNT(r.id) as read_count
		FROM articles a
		LEFT JOIN read_articles r ON a.id = r.article_id AND r.user_id = $1
		GROUP BY a.chapter, a.chapter_name
		ORDER BY a.chapter`, userID)
	if err != nil { return nil, err }
	defer rows.Close()

	var chapters []models.ChapterProgress
	for rows.Next() {
		var cp models.ChapterProgress
		rows.Scan(&cp.Chapter, &cp.ChapterName, &cp.Total, &cp.Read)
		if cp.Total > 0 { cp.Percent = cp.Read * 100 / cp.Total }
		chapters = append(chapters, cp)
	}

	return &models.UserProgress{TotalArticles: total, ReadArticles: read, Percent: pct, Chapters: chapters}, nil
}

// === Notes ===

func (d *DB) SaveNote(userID int, file, text string) error {
	_, err := d.conn.Exec(`
		INSERT INTO notes (user_id, file, text) VALUES ($1,$2,$3)
		ON CONFLICT (user_id, file) DO UPDATE SET text=EXCLUDED.text, updated_at=NOW()`,
		userID, file, text)
	return err
}

func (d *DB) GetNote(userID int, file string) string {
	var text string
	d.conn.QueryRow("SELECT COALESCE(text,'') FROM notes WHERE user_id=$1 AND file=$2", userID, file).Scan(&text)
	return text
}

func (d *DB) GetAllNotes(userID int) ([]models.Note, error) {
	rows, err := d.conn.Query("SELECT id, file, text, created_at, updated_at FROM notes WHERE user_id=$1 ORDER BY updated_at DESC", userID)
	if err != nil { return nil, err }
	defer rows.Close()
	var notes []models.Note
	for rows.Next() {
		var n models.Note
		rows.Scan(&n.ID, &n.File, &n.Text, &n.CreatedAt, &n.UpdatedAt)
		n.UserID = userID
		notes = append(notes, n)
	}
	return notes, nil
}

// === Stats ===

func (d *DB) GetStats() (*models.Stats, error) {
	var s models.Stats
	d.conn.QueryRow("SELECT COUNT(*) FROM users").Scan(&s.TotalUsers)
	d.conn.QueryRow("SELECT COUNT(*) FROM articles").Scan(&s.TotalArticles)
	d.conn.QueryRow("SELECT COUNT(*) FROM favorites").Scan(&s.TotalFavorites)
	d.conn.QueryRow("SELECT COUNT(*) FROM read_articles").Scan(&s.TotalReads)

	rows, err := d.conn.Query(`
		SELECT a.title, a.file,
			(SELECT COUNT(*) FROM read_articles r WHERE r.article_id=a.id) as reads,
			(SELECT COUNT(*) FROM favorites f WHERE f.article_id=a.id) as favs
		FROM articles a ORDER BY reads DESC LIMIT 10`)
	if err != nil { return &s, nil }
	defer rows.Close()
	for rows.Next() {
		var as models.ArticleStat
		rows.Scan(&as.Title, &as.File, &as.ReadCount, &as.FavCount)
		s.PopularArticles = append(s.PopularArticles, as)
	}
	return &s, nil
}
