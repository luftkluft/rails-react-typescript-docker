#!/bin/bash

sudo mkdir -p backend
sudo mkdir -p database

# create Gemfile
touch Gemfile
echo "source 'https://rubygems.org'
gem 'rails', '6.0.1'
gem 'bootsnap'
gem 'listen'
gem 'pg'" > Gemfile
mv Gemfile ./backend/Gemfile

# create Gemfile.lock
touch Gemfile.lock
mv Gemfile.lock ./backend/Gemfile.lock

# create Dockerfile.backend
touch Dockerfile.backend
echo "FROM ruby:2.7.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /backend
WORKDIR /backend
COPY Gemfile /backend/Gemfile
COPY Gemfile.lock /backend/Gemfile.lock
RUN gem install bundler
RUN bundle install
COPY . /backend" > Dockerfile.backend
mv Dockerfile.backend ./backend/Dockerfile.backend

# create Dockerfile.database
touch Dockerfile.database
echo "FROM postgres:12.1
# RUN localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8
# ENV LANG ru_RU.utf8
ENV POSTGRES_PASSWORD password12345
ENV POSTGRES_DB: backend_development
EXPOSE 5555:5432" > Dockerfile.database
mv Dockerfile.database ./database/Dockerfile.database

# create docker-compose.yml
touch docker-compose.yml
echo "version: '2'
services:
  db:
    restart: always
    build:
      context: ./database
      dockerfile: Dockerfile.database
    volumes:
      - db_data:/var/lib/postgresql/data
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.backend
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - ./backend:/backend
    ports:
      - \"3000:3000\"
    depends_on:
      - db
volumes:
  db_data: {}" > docker-compose.yml

docker-compose run --rm backend rails new . --force --api --database=postgresql -T
sudo chown -R $USER:$USER .
docker-compose build

# config database.yml
echo "default: &default
  adapter: postgresql
  encoding: unicode
  host: db
  username: postgres
  password: password12345
  pool: <%= ENV.fetch(\"RAILS_MAX_THREADS\") { 5 } %>

development:
  <<: *default
  database: backend_development


test:
  <<: *default
  database: backend_test

# production:
#   <<: *default
#   database: backend_production
#   username: backend
#   password: <%= ENV['backend_DATABASE_PASSWORD'] %>" > ./backend/config/database.yml

docker-compose run --rm backend rake db:setup
docker-compose up