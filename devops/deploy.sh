docker-compose run release

scp -i devops/exist-extras.pem \
  _build/prod/rel/exist_extras/releases/0.1.0/exist_extras.tar.gz \
  ec2-user@35.166.205.77:exist_extras.tar.gz

scp -i devops/exist-extras.pem \
  Dockerfile ec2-user@35.166.205.77:Dockerfile

scp -i devops/exist-extras.pem \
  docker-compose.yml ec2-user@35.166.205.77:docker-compose.yml

ssh -i devops/exist-extras.pem ec2-user@35.166.205.77 'tar -xzf exist_extras.tar.gz'

ssh -i devops/exist-extras.pem ec2-user@35.166.205.77 \
  'docker-compose down && docker-compose up -d prod'
