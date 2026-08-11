FROM node:20-alpine
RUN npm install -g npm@latest
 
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
 
COPY src ./src
 
EXPOSE 3000
 
CMD ["node", "src/index.js"]