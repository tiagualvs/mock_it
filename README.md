# Mock It

# Serviço de Mock API com Suporte a SQLite

Um serviço em Dart que gera endpoints de API mockados a partir de arquivos SQL, facilitando testes e desenvolvimento.

## Funcionalidades

- Geração automática de endpoints REST (GET, POST, PUT, DELETE)
- Suporte a relacionamentos entre tabelas
- Documentação automática com Swagger/OpenAPI
- Simulação de dados baseada em estrutura SQL
- Interface simples e intuitiva

## Instalação

1. Certifique-se de ter o Dart instalado em sua máquina ou baixe o executável em https://github.com/tiagualvs/mock_it/releases
```bash
dart pub global activate -sgit https://github.com/tiagualvs/mock_it.git
```

## Uso Básico

1. Prepare seu arquivo SQL com a estrutura do banco de dados
2. Execute o serviço:
```bash
mock_it -i path/to/your/schema.sql
```

Ou para persistir os dados em um arquivo local:

```bash
mock_it -i path/to/your/schema.sql -d path/to/your/database.db
```

## Estrutura do Arquivo SQL

O serviço suporta arquivos SQLite com:
- Criação de tabelas (CREATE TABLE)
- Relacionamentos (FOREIGN KEY)
- Tipos de dados comuns (VARCHAR, INTEGER, DATE, etc.)

## Endpoints Gerados

Para cada tabela no seu arquivo SQL, o serviço gerará automaticamente os seguintes endpoints:

- `GET /tabela` - Lista os registros de forma paginada
- `GET /tabela/{id}` - Obtém um registro específico
- `POST /tabela` - Cria um novo registro
- `PUT /tabela/{id}` - Atualiza um registro existente (Caso a tabela não tenha um campo de updated_at este endpoint não será gerado)
- `DELETE /tabela/{id}` - Remove um registro 

## Documentação Swagger

A documentação Swagger é gerada automaticamente e pode ser acessada em:
```
http://localhost:8080/docs
```

## Exemplo de Uso

Suponha que você tenha o seguinte arquivo SQL:
```sql
CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    titulo VARCHAR(100),
    conteudo TEXT,
    usuario_id INTEGER,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);
```

O serviço gerará automaticamente:
- Endpoints para gerenciar usuários (`/usuarios`)
- Endpoints para gerenciar os posts de um usuário (`/usuarios/{id}/posts`)
- Endpoint para gerenciar um post de um usuário (`/usuarios/{id}/posts/{post_id}`)
- Endpoints para gerenciar posts (`/posts`)
- Relacionamento entre usuários e posts
- Documentação Swagger completa

## Configuração

O serviço pode ser configurado através de variáveis de ambiente:

- `MOCK_IT_PORT` - Porta do servidor (padrão: 8080)
- `MOCK_IT_BASE_PATH` - Caminho base das rotas (padrão: /api)

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Consulte o arquivo LICENSE para mais detalhes.