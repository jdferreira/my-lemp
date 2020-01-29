# my-lemp

This is a dockerized solution to assist in developing PHP applications. It contains:
- a `db` container with the database (currently hard-coded as a MySQL database);
- a `php` container that runs the PHP requests
- an `nginx` container that orchestrates the HTTP(S) requests, receiving them
  and sending them to the PHP container
- a `workspace` container that contains the development tools: currently
  composer and node, as well as a functioning SSH server.

The containers mount a user-specified directory (which defaults to the current
directory) that is accessible to the `nginx`, `php-fpm` and `workspace`
containers.


