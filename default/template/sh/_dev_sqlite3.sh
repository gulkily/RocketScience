#!/bin/sh

# opens index database from cache in sqlitebrowser

sqlite3 -echo -cmd ".headers on" -cmd ".timeout 500" -cmd ".mode column" -cmd ".tables" ./cache/*/index.sqlite3
