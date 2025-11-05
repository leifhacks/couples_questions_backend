### Init

rails new couples_questions_backend --api -d mysql
cd couples_questions_backend
mkdir -p shared/sockets
git init
git add .
git commit -m "initial commit"
git branch -M master
git remote add origin git@github.com:leifhacks/couples_questions_backend
git push -u origin master

bundle install
bundle exec wheneverize .
# rm -rf config/credentials.yml.enc
# EDITOR="nano" rails credentials:edit
rails db:create
rails db:migrate

ApiKey.create
whenever --update-crontab --set environment=$RAILS_ENV wheneverCrontab
