package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"metanit_api/internal/db"
	"metanit_api/internal/handlers"
	"metanit_api/internal/models"

	"github.com/gorilla/mux"
)

func main() {
	// Config from env or defaults
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "metanit")
	dbPass := getEnv("DB_PASS", "metanit")
	dbName := getEnv("DB_NAME", "metanit")
	apiPort := getEnv("API_PORT", "8080")

	// Connect to PostgreSQL
	database, err := db.New(dbHost, dbPort, dbUser, dbPass, dbName)
	if err != nil {
		log.Fatal("DB connection failed:", err)
	}

	// Init schema
	if err := database.InitSchema(); err != nil {
		log.Fatal("Schema init failed:", err)
	}
	log.Println("Database connected, schema ready")

	// Seed articles from JSON if DB is empty
	articles, _ := database.GetArticles()
	if len(articles) == 0 {
		seedFromJSON(database)
	}

	h := &handlers.Handler{DB: database}

	r := mux.NewRouter()

	// Auth
	r.HandleFunc("/api/register", h.Register).Methods("POST")
	r.HandleFunc("/api/login", h.Login).Methods("POST")
	r.HandleFunc("/api/profile", h.Profile).Methods("GET")
	r.HandleFunc("/api/profile", h.UpdateProfile).Methods("PUT")

	// Articles
	r.HandleFunc("/api/articles", h.GetArticles).Methods("GET")
	r.HandleFunc("/api/articles/{file}/content", h.GetArticleContent).Methods("GET")
	r.HandleFunc("/api/search", h.Search).Methods("GET")

	// Favorites
	r.HandleFunc("/api/favorites", h.GetFavorites).Methods("GET")
	r.HandleFunc("/api/favorites/toggle", h.ToggleFavorite).Methods("POST")
	r.HandleFunc("/api/favorites/check/{file}", h.CheckFavorite).Methods("GET")

	// Progress
	r.HandleFunc("/api/progress", h.GetProgress).Methods("GET")
	r.HandleFunc("/api/progress/read", h.MarkRead).Methods("POST")
	r.HandleFunc("/api/progress/check/{file}", h.CheckRead).Methods("GET")

	// Notes
	r.HandleFunc("/api/notes", h.GetAllNotes).Methods("GET")
	r.HandleFunc("/api/notes", h.SaveNote).Methods("POST")
	r.HandleFunc("/api/notes/{file}", h.GetNote).Methods("GET")

	// Stats
	r.HandleFunc("/api/stats", h.GetStats).Methods("GET")

	// Sync
	r.HandleFunc("/api/sync", h.Sync).Methods("POST")

	// CORS middleware
	handler := corsMiddleware(r)

	log.Printf("API server starting on :%s", apiPort)
	log.Fatal(http.ListenAndServe(":"+apiPort, handler))
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(200)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func seedFromJSON(database *db.DB) {
	// Try to load articles.json
	paths := []string{
		"../../../data/articles.json",
		"../../data/articles.json",
		"data/articles.json",
	}

	var data []byte
	var err error
	for _, p := range paths {
		data, err = os.ReadFile(p)
		if err == nil {
			break
		}
	}
	if data == nil {
		log.Println("No articles.json found, skipping seed")
		return
	}

	var articles []models.Article
	if err := json.Unmarshal(data, &articles); err != nil {
		log.Println("Failed to parse articles.json:", err)
		return
	}

	// Also try to load markdown content for each article
	mdPaths := []string{"../../../data/articles/", "../../data/articles/", "data/articles/"}

	for _, a := range articles {
		// Try to read markdown content
		for _, mdDir := range mdPaths {
			content, err := os.ReadFile(mdDir + a.File)
			if err == nil {
				a.Content = string(content)
				break
			}
		}
		if err := database.UpsertArticle(a); err != nil {
			log.Printf("Failed to seed article %s: %v", a.File, err)
		}
	}
	fmt.Printf("Seeded %d articles into database\n", len(articles))
}
