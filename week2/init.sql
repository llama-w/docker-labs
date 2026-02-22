CREATE TABLE IF NOT EXISTS users (
                                     id SERIAL PRIMARY KEY,
                                     name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
    );

INSERT INTO users (name) VALUES ('DevOps Student'), ('K8s Learner');