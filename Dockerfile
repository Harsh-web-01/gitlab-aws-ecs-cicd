FROM node:22-alpine
RUN npm install -g netlify-cli@18.0.0
RUN apk add curl
RUN apk add --no-cache bash