# ExistExtras

This is a simple app for manually uploading nutritional data onto [Exist](https://exist.io).

## Future Features

* Grab nutrition data from Google Fit & upload automatically

## Development

Needs a local redis server in the standard port. Otherwise, just `iex -S mix` to start the app locally.

## Deploying

This is hosted on an EC2 instance in AWS at `exist.jmnsf.com`. Deploying is through an Erlang release built with `distillery`. In production, the project runs on a Docker container.

### Pre-requisites

* RSA private key in `devops/exist-extras.pem` with access to the EC2 instance.

### Deploy Script

Running `devops/deploy.sh` will build a release using a local Docker container (to ensure the relase is built vs the right OS), upload it to the instance and restart the container with the updated app.
