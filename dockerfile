FROM node:18-alpine

WORKDIR /app

# Copy and install backend
COPY backend/package*.json ./backend/
RUN cd backend && npm install

# Copy and install frontend
COPY frontend/package*.json ./frontend/
RUN cd frontend && npm install

# Copy all source code
COPY backend ./backend
COPY frontend ./frontend

# Build frontend for production
RUN cd frontend && npm run build

EXPOSE 5000 3000

CMD ["node", "backend/server.js"]