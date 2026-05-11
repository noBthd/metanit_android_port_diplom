#pragma once

#include <vector>
#include "models/article.h"

class ArticleService {
public:
    std::vector<Article> loadArticles(const QString& path);
};