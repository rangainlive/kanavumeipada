FROM node:20-alpine

WORKDIR /app

COPY backend/package.json ./
RUN npm install --legacy-peer-deps

COPY backend/ ./

RUN npm run build

EXPOSE 3000

CMD ["node", "dist/index.js"]
