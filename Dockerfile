FROM node:alpine

COPY . /app

WORKDIR /app

RUN npm i

RUN npm run build

CMD ["npm", "run", "start"]


