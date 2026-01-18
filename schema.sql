DROP TABLE IF EXISTS wallpapers;
CREATE TABLE IF NOT EXISTS wallpapers (
    date TEXT PRIMARY KEY,
    title TEXT,
    copyright TEXT,
    url TEXT,
    json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
