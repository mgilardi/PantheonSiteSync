#!/bin/bash

git fetch origin -v
git fetch upstream -v
git merge upstream/master
