FROM node:5.12
RUN mkdir /usr/src/app
WORKDIR /usr/src/app
COPY ./package.json /usr/src/app/
RUN npm install && npm install -g nodemon && npm install -g webpack