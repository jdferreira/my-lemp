<?php

$hostname = 'db';
$database = getenv('MYSQL_DATABASE');
$username = getenv('MYSQL_USER');
$password = getenv('MYSQL_PASSWORD');

$pdo = new PDO("mysql:dbname=$database;host=$hostname", $username, $password);

$result = $pdo->query('SELECT 1');

if ($result->fetch(PDO::FETCH_COLUMN) == 1) {
    echo 'Success: database is accessible';
} else {
    echo 'Success: database is unreachable';
}
