FROM node:20-alpine

WORKDIR /app

COPY backend/package.json ./
RUN npm install --legacy-peer-deps

COPY backend/ ./

RUN npm run build

RUN cp src/db/init.sql dist/db/init.sql

EXPOSE 3000

CMD ["node", "dist/index.js"]
