#!/bin/bash

DOCKER_COMPOSE_DIR="$(dirname $0)"
DOCKER_COMPOSE_FILE="$DOCKER_COMPOSE_DIR/docker-compose.yml"
DOCKER_COMPOSE="docker-compose -f $DOCKER_COMPOSE_FILE --project-directory $DOCKER_COMPOSE_DIR"

function ok() {
    echo -e "\e[32;1m${1:-OK}\e[0m"
}

function error() {
    echo -e "\e[31;1m${1:-ERROR}\e[0m"
}

function assert() {
    if [ "$?" = 0 ]; then
        ok
    else
        error
    fi
}

function container() {
    container="$1"

    echo -e "\nTesting container \e[1m$container\e[0m"
}

function docker_exec() {
    extra=""

    while [[ $1 =~ ^- ]]; do
        extra="$extra $1"
        shift
    done

    $DOCKER_COMPOSE exec $extra "$container" "$@"
}

function test_container_is_running() {
    local result="false"

    echo -n "  container is running? "

    echo "$(docker ps --filter name="$container")" | grep -q "$container"
    assert
}

function test_host_docker_internal() {
    local result="false"

    echo -n "  can reach 'host.docker.internal'? "

    docker_exec getent hosts "host.docker.internal" | grep -q "host.docker.internal"
    assert
}

function test_php_version() {
    expected="$1"
    local result="false"

    echo -n "  php version is '$expected'? "

    docker_exec php -v | grep -q "PHP $expected"
    assert
}

function test_php_modules() {
    for module in "$@"; do
        test_php_module
    done
}

function test_php_module() {
    local result="false"

    echo -n "  has PHP module '$module'? "

    docker_exec php -m | grep -q "$module"
    assert
}

function test_composer_is_installed() {
    local result="false"

    echo -n "  has composer installed? "

    docker_exec composer --version >/dev/null 2>/dev/null
    assert
}

function test_node_is_installed() {
    local result="false"

    echo -n "  has node installed? "

    docker_exec --user=www-data bash --login -c 'node --version' >/dev/null 2>/dev/null
    assert
}

function test_request_nginx() {
    local result="false"

    echo -n "  can receive HTTP requests? "

    curl -s "$1" | grep -q "$2"
    assert
}

function test_database_is_working() {
    local result="false"

    echo -n "  is running the database? "

    docker_exec bash -c \
        'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1" > /dev/null 2> /dev/null'
    assert
}

function test_php_can_access_db() {
    local result="false"

    echo -n "  can reach the database? "

    docker_exec curl -s "$1" | grep -q "$2"
    assert
}

container "db"
test_container_is_running
test_database_is_working

container "php-fpm"
test_container_is_running
test_host_docker_internal
test_php_version 7.3
test_php_modules xdebug "Zend OPcache"

container "nginx"
test_container_is_running
test_request_nginx localhost/test.php "Hello world!"
test_php_can_access_db localhost/test-db.php "Success: database is accessible"

container "workspace"
test_container_is_running
test_host_docker_internal
test_php_version 7.3
test_php_modules xdebug "Zend OPcache"
test_composer_is_installed
test_node_is_installed
