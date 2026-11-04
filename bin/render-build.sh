#!/usr/bin/env bash
set -o errexit

bundle install

bin/rails assets:precompile
bin/rails assets:clean

# Migração para plano gratuito
bin/rails db:migrate