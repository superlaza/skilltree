FROM node:5.12
RUN mkdir /usr/src/app
WORKDIR /usr/src/app
COPY ./package.json /usr/src/app/package.json
COPY ./webpack.config.js /usr/src/app/webpack.config.js
RUN bash -c "cd /usr/src/app && npm install"