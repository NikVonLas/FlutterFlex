# 🐳 Docker Setup Guide für FlutterFlex Backend

Schnelle Anleitung zum Starten des Backends mit Docker.

---

## 1. Voraussetzungen

- Docker installiert: https://www.docker.com/products/docker-desktop
- Docker Compose ist bereits enthalten

---

## 2. MySQL Database mit Docker starten

### Mit docker-compose (Empfohlen)

```bash
# Im Backend Verzeichnis starten
cd Backend

# MySQL Container starten
docker-compose up -d
```

Datenbank Credentials:
- Host: `localhost`
- Port: `3307` (intern: 3306)
- User: `flutter_user`
- Password: `userpassword123`
- Database: `flutterflex_db`

### Container stoppen
```bash
docker-compose down
```

### Nur Datenbank stoppen (aber nicht löschen)
```bash
docker-compose stop
```

### Datenbank neustarten
```bash
docker-compose start
```

---

## 3. .env Datei für Docker konfigurieren

Erstelle eine `.env` Datei mit diesen Credentials (damit die App sich mit der Datenbank verbindet):

```env
DB_HOST=localhost
DB_USER=flutter_user
DB_PASSWORD=userpassword123
DB_NAME=flutterflex_db
PORT=3000
JWT_SECRET=your_super_secret_key
```

---

## 4. Backend mit Docker starten

### Option 1: Lokales Node.js
```bash
npm install
npm run dev
```

Server läuft auf: `http://localhost:3000`

### Option 2: Docker Container bauen
```bash
# Image bauen
docker build -t flutterflex-backend .

# Container starten
docker run -p 3000:3000 \
  --env-file .env \
  --network host \
  flutterflex-backend
```

---

## 5. Kompletter Docker Compose Stack

Um sowohl MySQL als auch die Node App zusammen zu starten, update die `docker-compose.yml`:

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: flutterflex_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword123
      MYSQL_DATABASE: flutterflex_db
      MYSQL_USER: flutter_user
      MYSQL_PASSWORD: userpassword123
    ports:
      - "3307:3306"
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - flutterflex-network

  backend:
    build: .
    container_name: flutterflex_backend
    restart: always
    environment:
      DB_HOST=db
      DB_USER=flutter_user
      DB_PASSWORD=userpassword123
      DB_NAME=flutterflex_db
      PORT=3000
      JWT_SECRET=your_super_secret_key
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - flutterflex-network

networks:
  flutterflex-network:
    driver: bridge

volumes:
  db_data:
```

Dann starten mit:
```bash
docker-compose up -d
```

---

## 6. Database mit Docker Befehlen prüfen

### In die MySQL Container gehen
```bash
docker exec -it flutterflex_mysql mysql -u flutter_user -p
```

Passwort eingeben: `userpassword123`

### Datenbanken anzeigen
```sql
SHOW DATABASES;
USE flutterflex_db;
SHOW TABLES;
SELECT COUNT(*) FROM users;
```

### Container anzeigen
```bash
# Laufende Container
docker ps

# Alle Container
docker ps -a

# Container Logs anschauen
docker logs flutterflex_mysql
docker logs flutterflex_backend
```

---

## 7. Docker Volumes verwalten

### Volume anzeigen
```bash
docker volume ls
docker volume inspect flutterflex_db_data
```

### Volume löschen (WARNING: Daten gehen verloren!)
```bash
docker volume rm flutterflex_db_data
```

---

## 8. Troubleshooting

### "Port 3307 already in use"
```bash
# Port in docker-compose.yml ändern
ports:
  - "3308:3306"  # Verwende einen anderen Host-Port
```

### "Connection refused"
```bash
# Überprüfe ob Container läuft
docker ps

# Logs anschauen
docker logs flutterflex_mysql

# Container neustarten
docker restart flutterflex_mysql
```

### "Database doesn't exist"
- Warte nach dem ersten Start 10-20 Sekunden, die DB braucht Zeit zum Initialisieren
- Logs überprüfen: `docker logs flutterflex_mysql`

### "Can't connect to MySQL server"
```bash
# Container Health überprüfen
docker inspect flutterflex_mysql

# Container neustarten
docker-compose restart

# Von vorne starten (Daten bleiben)
docker-compose down && docker-compose up -d
```

---

## 9. Datenbank Backup

### Datenbank exportieren
```bash
docker exec flutterflex_mysql mysqldump \
  -u flutter_user -puserpassword123 \
  flutterflex_db > backup.sql
```

### Datenbank importieren
```bash
docker exec -i flutterflex_mysql mysql \
  -u flutter_user -puserpassword123 \
  flutterflex_db < backup.sql
```

---

## 10. Production Deploy

### Mit Swarm oder Kubernetes
```bash
# Für Production solltest du:
1. Secrets managen (nicht hardcoded in docker-compose)
2. Resource limits setzen
3. Health checks implementieren
4. Environment-spezifische Configs nutzen
```

Beispiel mit Secrets:
```bash
echo "rootpassword123" | docker secret create mysql_root_password -
docker-compose -f docker-compose.prod.yml up -d
```

---

## Tipps & Tricks

1. **Auto-reload in Docker**
   - Nutze Volumes für Source Code
   - Mount: `- ./:/app`

2. **Environment Variablen**
   - Nutze `.env` Dateien
   - `--env-file .env` beim starten

3. **Networking**
   - Verwende `service_name:port` statt localhost
   - z.B. `db:3306` statt `localhost:3306`

4. **Logs überwachen**
   ```bash
   docker-compose logs -f backend
   ```

---

## Weitere Ressourcen

- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- MySQL Docker: https://hub.docker.com/_/mysql

---

Happy Containerizing! 🚀🐳

