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
	user, err := h.DB.GetUserByToken(strings.TrimPrefix(auth, "Bearer "))
	if err != nil {
		return nil
	}
	return user
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Некорректный запрос", 400)
		return
	}
	if len(req.Username) < 3 {
		jsonError(w, "Логин должен быть не менее 3 символов", 400)
		return
	}
	if len(req.Password) < 4 {
		jsonError(w, "Пароль должен быть не менее 4 символов", 400)
		return
	}
	if req.DisplayName == "" {
		req.DisplayName = req.Username
	}
	resp, err := h.DB.Register(req.Username, req.Password, req.DisplayName)
	if err != nil {
		jsonError(w, err.Error(), 409)
		return
	}
	jsonOK(w, resp)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Некорректный запрос", 400)
		return
	}
	if req.Username == "" || req.Password == "" {
		jsonError(w, "Введите логин и пароль", 400)
		return
	}
	resp, err := h.DB.Login(req.Username, req.Password)
	if err != nil {
		jsonError(w, err.Error(), 401)
		return
	}
	jsonOK(w, resp)
}

func (h *Handler) Profile(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "Необходима авторизация", 401)
		return
	}
	jsonOK(w, user)
}

func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "Необходима авторизация", 401)
		return
	}
	var req models.UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Некорректный запрос", 400)
		return
	}
	if err := h.DB.UpdateProfile(user.ID, req.DisplayName, req.OldPassword, req.NewPassword); err != nil {
		jsonError(w, err.Error(), 400)
		return
	}
	jsonOK(w, map[string]string{"status": "ok"})
}

func (h *Handler) GetArticles(w http.ResponseWriter, r *http.Request) {
	articles, err := h.DB.GetArticles()
	if err != nil {
		jsonError(w, "Ошибка базы данных", 500)
		return
	}
	if articles == nil {
		articles = []models.Article{}
	}
	jsonOK(w, articles)
}

func (h *Handler) GetArticleContent(w http.ResponseWriter, r *http.Request) {
	file := strings.TrimPrefix(r.URL.Path, "/api/articles/")
	file = strings.TrimSuffix(file, "/content")
	content, err := h.DB.GetArticleContent(file)
	if err != nil {
		jsonError(w, "Статья не найдена", 404)
		return
	}
	jsonOK(w, map[string]string{"content": content})
}

func (h *Handler) AddFavorite(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "Необходима авторизация", 401)
		return
	}
	var req models.FavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "Некорректный запрос", 400)
		return
	}
	h.DB.AddFavorite(user.ID, req.ArticleID)
	jsonOK(w, map[string]string{"status": "ok"})
}

func (h *Handler) RemoveFavorite(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "Необходима авторизация", 401)
		return
	}
	idStr := strings.TrimPrefix(r.URL.Path, "/api/favorites/")
	articleID, _ := strconv.Atoi(idStr)
	h.DB.RemoveFavorite(user.ID, articleID)
	jsonOK(w, map[string]string{"status": "ok"})
}

func (h *Handler) GetFavorites(w http.ResponseWriter, r *http.Request) {
	user := h.getUserFromToken(r)
	if user == nil {
		jsonError(w, "Необходима авторизация", 401)
		return
	}
	favs, err := h.DB.GetFavorites(user.ID)
	if err != nil {
		jsonError(w, "Ошибка базы данных", 500)
		return
	}
	if favs == nil {
		favs = []models.Article{}
	}
	jsonOK(w, favs)
}


func (h *Handler) Sync(w http.ResponseWriter, r *http.Request) {

}
