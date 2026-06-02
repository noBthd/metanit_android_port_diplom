# Настройка PostgreSQL и API-сервера

## 1. Установка PostgreSQL

### macOS
```bash
brew install postgresql@16
brew services start postgresql@16
```

### Linux
```bash
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

## 2. Создание базы данных

```bash
# Зайти в psql
psql -U postgres

# Создать пользователя и базу
CREATE USER metanit WITH PASSWORD 'metanit';
CREATE DATABASE metanit OWNER metanit;
GRANT ALL PRIVILEGES ON DATABASE metanit TO metanit;
\q
```

Таблицы создаются автоматически при запуске API-сервера.

## 3. Структура таблиц (создаётся автоматически)

```sql
-- Пользователи
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    token VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Статьи
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    link TEXT,
    file VARCHAR(50) UNIQUE NOT NULL,
    chapter INT NOT NULL,
    chapter_name VARCHAR(200),
    content TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Избранное
CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    article_id INT REFERENCES articles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, article_id)
);
```

## 4. Запуск API-сервера

```bash
cd tools/api/cmd

# Установить зависимости (первый раз)
go mod tidy

# Запустить (по умолчанию localhost:8080)
go run main.go

# Или с кастомными параметрами:
DB_HOST=localhost DB_PORT=5432 DB_USER=metanit DB_PASS=metanit DB_NAME=metanit API_PORT=8080 go run main.go
```

При первом запуске сервер автоматически:
- Создаст таблицы в PostgreSQL
- Загрузит статьи из `data/articles.json` и markdown-контент из `data/articles/`

## 5. API Endpoints

| Метод  | URL                             | Описание                  | Auth |
|--------|---------------------------------|---------------------------|------|
| POST   | /api/register                   | Регистрация               | Нет  |
| POST   | /api/login                      | Вход                      | Нет  |
| GET    | /api/profile                    | Профиль пользователя      | Да   |
| GET    | /api/articles                   | Список статей             | Нет  |
| GET    | /api/articles/{file}/content    | Контент статьи            | Нет  |
| GET    | /api/favorites                  | Избранное пользователя    | Да   |
| POST   | /api/favorites                  | Добавить в избранное      | Да   |
| DELETE | /api/favorites/{article_id}     | Удалить из избранного     | Да   |

### Авторизация
Все защищённые эндпоинты требуют заголовок:
```
Authorization: Bearer <token>
```
Token возвращается при логине/регистрации.

## 6. Тестирование API

```bash
# Регистрация
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"1234"}'

# Вход
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"1234"}'

# Статьи
curl http://localhost:8080/api/articles

# Контент статьи
curl http://localhost:8080/api/articles/1.1.md/content
```

## 7. Настройка адреса сервера в приложении

По умолчанию приложение подключается к `http://localhost:8080`.
Для iOS-устройства в локальной сети замените на IP компьютера, например:
`http://192.168.1.100:8080`

Изменить можно в `network_service.cpp`:
```cpp
m_baseUrl("http://192.168.1.100:8080")
```
