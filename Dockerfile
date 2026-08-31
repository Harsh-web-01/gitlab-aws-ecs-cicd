FROM node:22-alpine
RUN npm install -g netlify-cli
RUN apk add curl