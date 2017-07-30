docker-compose run release

scp -i devops/exist-extras.pem \
  _build/prod/rel/exist_extras/releases/0.1.0/exist_extras.tar.gz \
  ec2-user@exist.jmnsf.com:exist_extras.tar.gz

scp -i devops/exist-extras.pem \
  Dockerfile ec2-user@exist.jmnsf.com:Dockerfile

scp -i devops/exist-extras.pem \
  docker-compose.yml ec2-user@exist.jmnsf.com:docker-compose.yml

ssh -i devops/exist-extras.pem ec2-user@exist.jmnsf.com 'tar -xzvf exist_extras.tar.gz'

ssh -i devops/exist-extras.pem ec2-user@exist.jmnsf.com \
  'docker-compose down prod && docker-compose up -d prod'
