#!/bin/sh

TAG="$1"

if [ -z "$TAG" ]; then
  printf "Usage: ./dune-release.sh <tag-name>\n"
  printf "Please make sure that dune-release is available.\n"
  exit 1
fi

step()
{
  printf "Continue? [Yn] "
  read action
  if [ "x$action" == "xn" ]; then exit 2; fi
  if [ "x$action" == "xN" ]; then exit 2; fi
}

dune-release tag "$TAG" --force
step
dune-release distrib -p logs-ppx -t "$TAG"
step
dune-release publish distrib -p logs-ppx -t "$TAG"
step
dune-release opam pkg -p logs-ppx -t "$TAG"
step
dune-release opam submit -p logs-ppx -t "$TAG"
