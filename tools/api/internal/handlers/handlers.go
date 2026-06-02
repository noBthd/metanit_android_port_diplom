package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"metanit_api/internal/db"
	"metanit_api/internal/models"
)

type Handler struct {
	DB *db.DB
}

func jsonError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func jsonOK(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) getUserFromToken(r *http.Request) *models.User {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return nil
	}
	token := strings.TrimPrefix(auth, "Bearer ")
	user, err := h.DB.GetUserByToken(token)
	if err != nil {
		return nil
	}
	return user
}

// POST /api/register
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", 400)
		return
	}
	if len(req.Username) < 3 || len(req.Password) < 4 {
		jsonError(w, "username min 3 chars, password min 4 chars", 400)
		return
	}
	resp, err := h.DB.Register(req.Username, req.Password)
	if err != nil {
		jsonError(w, err.Error(), 409)
		return
	}
	jsonOK(w, resp)
}

// POST /api/login
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", 400)
		return
	}
	resp, err := h.DB.Login(req.Username, req.Password)
	if err != nil {
		jsonError(w, err.Error(), 401)
		return
	}
	jsonOK(w, resp)
}

// GET /api/profile
func (h *Handler) Profile(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "unauthorized", 401)
		return
	}
	jsonOK(w, user)
}

// GET /api/articles
func (h *Handler) GetArticles(w http.ResponseWriter, r *http.Request) {
	articles, err := h.DB.GetArticles()
	if err != nil {
		jsonError(w, "db error", 500)
		return
	}
	if articles == nil {
		articles = []models.Article{}
	}
	jsonOK(w, articles)
}

// GET /api/articles/{file}/content
func (h *Handler) GetArticleContent(w http.ResponseWriter, r *http.Request) {
	file := strings.TrimPrefix(r.URL.Path, "/api/articles/")
	file = strings.TrimSuffix(file, "/content")

	content, err := h.DB.GetArticleContent(file)
	if err != nil {
		jsonError(w, "not found", 404)
		return
	}
	jsonOK(w, map[string]string{"content": content})
}

// POST /api/favorites
func (h *Handler) AddFavorite(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "unauthorized", 401)
		return
	}
	var req models.FavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", 400)
		return
	}
	h.DB.AddFavorite(user.ID, req.ArticleID)
	jsonOK(w, map[string]string{"status": "ok"})
}

// DELETE /api/favorites/{article_id}
func (h *Handler) RemoveFavorite(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "unauthorized", 401)
		return
	}
	idStr := strings.TrimPrefix(r.URL.Path, "/api/favorites/")
	articleID, _ := strconv.Atoi(idStr)
	h.DB.RemoveFavorite(user.ID, articleID)
	jsonOK(w, map[string]string{"status": "ok"})
}

// GET /api/favorites
func (h *Handler) GetFavorites(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "unauthorized", 401)
		return
	}
	favs, err := h.DB.GetFavorites(user.ID)
	if err != nil {
		jsonError(w, "db error", 500)
		return
	}
	if favs == nil {
		favs = []models.Article{}
	}
	jsonOK(w, favs)
}

// POST /api/sync — triggers crawler + parser and saves to DB
func (h *Handler) Sync(w http.ResponseWriter, r *http.Request) {
	jsonOK(w, map[string]string{"status": "sync not implemented via API, use CLI tools"})
}
