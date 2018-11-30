-- CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS nextcloud;
-- GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON nextcloud.* TO 'username'@'localhost' IDENTIFIED BY 'password';
FLUSH privileges;