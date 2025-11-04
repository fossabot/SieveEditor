#!/bin/bash
# SieveEditor build script
# Builds ManageSieveJ submodule dependency first, then builds SieveEditor

set -e

echo "Building ManageSieveJ dependency from submodule..."
mvn -f lib/ManageSieveJ/pom.xml clean install -DskipTests -Dmaven.javadoc.skip=true

echo ""
echo "Building SieveEditor..."
mvn clean package

echo ""
echo "Build complete!"
echo "Run with: ./sieveeditor.sh"
echo "Or: java -jar target/SieveEditor-jar-with-dependencies.jar"
