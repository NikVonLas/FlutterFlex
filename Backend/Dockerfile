# Backend Dockerfile

FROM node:18-alpine

# Workdir setzen
WORKDIR /app

# Package.json und package-lock.json kopieren
COPY package*.json ./

# Dependencies installieren
RUN npm ci --only=production

# Source Code kopieren
COPY . .

# Port exponieren
EXPOSE 3000

# Health Check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Server starten
CMD ["node", "server.js"]
