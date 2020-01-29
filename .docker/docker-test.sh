#!/bin/sh

DOCKER_COMPOSE_DIR="$(dirname $0)"
DOCKER_COMPOSE_FILE="$DOCKER_COMPOSE_DIR/docker-compose.yml"
DOCKER_COMPOSE="docker-compose -f $DOCKER_COMPOSE_FILE --project-directory $DOCKER_COMPOSE_DIR"

function container() {
    container="$1"

    echo -e "\nTesting container \e[1m$container\e[0m"
}

function assert() {
    if [ "$1" = true ]; then
        echo -e "\e[32;1mOK\e[0m"
    else
        echo -e "\e[31;1mERROR\e[0m"
    fi
}

function docker_exec() {
    $DOCKER_COMPOSE exec "$container" "$@"
}

function test_container_is_running() {
    local result="false"
    echo "$(docker ps --filter name="$container")" | grep -q "$container" && result="true"
    echo -n "  container is running? "
    assert $result
}

function test_host_docker_internal() {
    local result="false"
    docker_exec getent hosts "host.docker.internal" | grep -q "host.docker.internal" && result="true"
    echo -n "  can reach 'host.docker.internal'? "
    assert $result
}

function test_php_version() {
    expected="$1"
    local result="false"
    docker_exec php -v | grep -q "PHP $expected" && result="true"
    echo -n "  php version is '$expected'? "
    assert $result
}

function test_php_modules() {
    for module in "$@"; do
        test_php_module
    done
}

function test_php_module() {
    local result="false"
    docker_exec php -m | grep -q "$module" && result="true"
    echo -n "  has PHP module '$module'? "
    assert $result
}

function test_composer_is_installed() {
    local result="false"
    docker_exec composer --version > /dev/null 2> /dev/null && result="true"
    echo -n "  has composer installed? "
    assert $result
}

function test_node_is_installed() {
    local result="false"
    docker_exec bash --login -c 'node --version' > /dev/null 2> /dev/null && result="true"
    echo -n "  has node installed? "
    assert $result
}

function test_request_nginx() {
    local result="false"
    curl -s "$1" | grep -q "$2" && result="true"
    echo -n "  can receive HTTP requests? "
    assert $result
}

function test_database_is_working() {
    local result="false"
    docker_exec bash -c \
        'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1" > /dev/null 2> /dev/null' \
        && result="true"
    echo -n "  is running the database? "
    assert $result
}

function test_php_can_access_db() {
    local result="false"
    docker_exec curl -s "$1" | grep -q "$2" && result="true"
    echo -n "  can reach the database? "
    assert $result
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
