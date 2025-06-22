CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(24) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    image VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, username, email, password, image, created_at, updated_at) VALUES
('Alice Pereira', 'alicep', 'alicep@example.com', 'senha123', 'https://picsum.photos/200?1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Bruno Silva', 'brunos', 'bruno.silva@example.com', 'senha123', 'https://picsum.photos/200?2', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Carla Nunes', 'carlan', 'carla.nunes@example.com', 'senha123', 'https://picsum.photos/200?3', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Diego Torres', 'diegot', 'diego.torres@example.com', 'senha123', 'https://picsum.photos/200?4', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Eduarda Lima', 'eduardal', 'eduarda.lima@example.com', 'senha123', 'https://picsum.photos/200?5', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Felipe Souza', 'felipes', 'felipe.souza@example.com', 'senha123', 'https://picsum.photos/200?6', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Giovana Rocha', 'giovanar', 'giovana.rocha@example.com', 'senha123', 'https://picsum.photos/200?7', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Henrique Alves', 'henriquea', 'henrique.alves@example.com', 'senha123', 'https://picsum.photos/200?8', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Isabela Castro', 'isabelac', 'isabela.castro@example.com', 'senha123', 'https://picsum.photos/200?9', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('João Mendes', 'joaom', 'joao.mendes@example.com', 'senha123', 'https://picsum.photos/200?10', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Karina Duarte', 'karinad', 'karina.duarte@example.com', 'senha123', 'https://picsum.photos/200?11', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Lucas Ferreira', 'lucasf', 'lucas.ferreira@example.com', 'senha123', 'https://picsum.photos/200?12', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Marina Lopes', 'marinal', 'marina.lopes@example.com', 'senha123', 'https://picsum.photos/200?13', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Nicolas Pinto', 'nicolasp', 'nicolas.pinto@example.com', 'senha123', 'https://picsum.photos/200?14', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Olivia Matos', 'oliviam', 'olivia.matos@example.com', 'senha123', 'https://picsum.photos/200?15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Paulo Vieira', 'paulov', 'paulo.vieira@example.com', 'senha123', 'https://picsum.photos/200?16', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Quésia Ramos', 'quesiar', 'quesia.ramos@example.com', 'senha123', 'https://picsum.photos/200?17', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Rafael Costa', 'rafaelc', 'rafael.costa@example.com', 'senha123', 'https://picsum.photos/200?18', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Sabrina Azevedo', 'sabrinaa', 'sabrina.azevedo@example.com', 'senha123', 'https://picsum.photos/200?19', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Thiago Moreira', 'thiagom', 'thiago.moreira@example.com', 'senha123', 'https://picsum.photos/200?20', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Ursula Dantas', 'ursulad', 'ursula.dantas@example.com', 'senha123', 'https://picsum.photos/200?21', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Vinícius Reis', 'viniciusr', 'vinicius.reis@example.com', 'senha123', 'https://picsum.photos/200?22', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Wesley Oliveira', 'wesleyo', 'wesley.oliveira@example.com', 'senha123', 'https://picsum.photos/200?23', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Xuxa Martins', 'xuxam', 'xuxa.martins@example.com', 'senha123', 'https://picsum.photos/200?24', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Yasmin Teixeira', 'yasmint', 'yasmin.teixeira@example.com', 'senha123', 'https://picsum.photos/200?25', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO posts (title, content, user_id) VALUES
('Title 1', 'Content 1', 1),
('Title 2', 'Content 2', 2),
('Title 3', 'Content 3', 3),
('Title 4', 'Content 4', 4),
('Title 5', 'Content 5', 5);

CREATE TABLE IF NOT EXISTS likes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    post_id INTEGER NOT NULL REFERENCES posts(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, post_id)
);

INSERT INTO likes (user_id, post_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(id),
    post_id INTEGER NOT NULL REFERENCES posts(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO comments (content, user_id, post_id) VALUES
('Comment 1', 1, 1),
('Comment 2', 2, 2),
('Comment 3', 3, 3),
('Comment 4', 4, 4),
('Comment 5', 5, 5);