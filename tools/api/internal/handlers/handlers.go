package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"metanit_api/internal/db"
	"metanit_api/internal/models"
)

type Handler struct{ DB *db.DB }

func j(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
func je(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json"); w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func (h *Handler) user(r *http.Request) *models.User {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") { return nil }
	u, err := h.DB.GetUserByToken(strings.TrimPrefix(auth, "Bearer "))
	if err != nil { return nil }
	return u
}

// Auth
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Некорректный запрос", 400); return }
	if len(req.Username) < 3 { je(w, "Логин от 3 символов", 400); return }
	if len(req.Password) < 4 { je(w, "Пароль от 4 символов", 400); return }
	if req.DisplayName == "" { req.DisplayName = req.Username }
	resp, err := h.DB.Register(req.Username, req.Password, req.DisplayName)
	if err != nil { je(w, err.Error(), 409); return }
	j(w, resp)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Некорректный запрос", 400); return }
	if req.Username == "" || req.Password == "" { je(w, "Введите логин и пароль", 400); return }
	resp, err := h.DB.Login(req.Username, req.Password)
	if err != nil { je(w, err.Error(), 401); return }
	j(w, resp)
}

func (h *Handler) Profile(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	j(w, u)
}

func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	var req models.UpdateProfileRequest
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Некорректный запрос", 400); return }
	if err := h.DB.UpdateProfile(u.ID, req.DisplayName, req.OldPassword, req.NewPassword); err != nil {
		je(w, err.Error(), 400); return
	}
	j(w, map[string]string{"status": "ok"})
}

// Articles
func (h *Handler) GetArticles(w http.ResponseWriter, r *http.Request) {
	arts, err := h.DB.GetArticles()
	if err != nil { je(w, "Ошибка БД", 500); return }
	if arts == nil { arts = []models.Article{} }
	j(w, arts)
}

func (h *Handler) GetArticleContent(w http.ResponseWriter, r *http.Request) {
	file := strings.TrimPrefix(r.URL.Path, "/api/articles/")
	file = strings.TrimSuffix(file, "/content")
	content, err := h.DB.GetArticleContent(file)
	if err != nil { je(w, "Не найдена", 404); return }
	j(w, map[string]string{"content": content})
}

// Search — полнотекстовый поиск
func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" { je(w, "Пустой запрос", 400); return }
	arts, err := h.DB.SearchArticles(q)
	if err != nil { je(w, "Ошибка поиска", 500); return }
	if arts == nil { arts = []models.Article{} }
	j(w, arts)
}

// Favorites
func (h *Handler) ToggleFavorite(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	var req struct{ File string `json:"file"` }
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Ошибка", 400); return }
	isFav, err := h.DB.ToggleFavoriteByFile(u.ID, req.File)
	if err != nil { je(w, err.Error(), 400); return }
	j(w, map[string]interface{}{"is_favorite": isFav})
}

func (h *Handler) CheckFavorite(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	file := strings.TrimPrefix(r.URL.Path, "/api/favorites/check/")
	j(w, map[string]bool{"is_favorite": h.DB.IsFavoriteByFile(u.ID, file)})
}

func (h *Handler) GetFavorites(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	favs, _ := h.DB.GetFavorites(u.ID)
	if favs == nil { favs = []models.Article{} }
	j(w, favs)
}

// Progress — прогресс чтения
func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	var req struct{ File string `json:"file"` }
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Ошибка", 400); return }
	isRead, _ := h.DB.ToggleRead(u.ID, req.File)
	j(w, map[string]interface{}{"is_read": isRead})
}

func (h *Handler) CheckRead(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	file := strings.TrimPrefix(r.URL.Path, "/api/progress/check/")
	j(w, map[string]bool{"is_read": h.DB.IsRead(u.ID, file)})
}

func (h *Handler) GetProgress(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	p, err := h.DB.GetProgress(u.ID)
	if err != nil { je(w, "Ошибка", 500); return }
	j(w, p)
}

// Notes — заметки
func (h *Handler) SaveNote(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	var req models.NoteRequest
	if json.NewDecoder(r.Body).Decode(&req) != nil { je(w, "Ошибка", 400); return }
	h.DB.SaveNote(u.ID, req.File, req.Text)
	j(w, map[string]string{"status": "ok"})
}

func (h *Handler) GetNote(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	file := strings.TrimPrefix(r.URL.Path, "/api/notes/")
	j(w, map[string]string{"text": h.DB.GetNote(u.ID, file)})
}

func (h *Handler) GetAllNotes(w http.ResponseWriter, r *http.Request) {
	u := h.user(r); if u == nil { je(w, "Авторизуйтесь", 401); return }
	notes, _ := h.DB.GetAllNotes(u.ID)
	if notes == nil { notes = []models.Note{} }
	j(w, notes)
}

// Stats — статистика
func (h *Handler) GetStats(w http.ResponseWriter, r *http.Request) {
	s, _ := h.DB.GetStats()
	j(w, s)
}

func (h *Handler) Sync(w http.ResponseWriter, r *http.Request) {
	j(w, map[string]string{"status": "ok"})
}
