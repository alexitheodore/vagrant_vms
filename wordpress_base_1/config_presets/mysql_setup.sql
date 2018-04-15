CREATE DATABASE $site_url_safe CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY '$wp_sql_user_pass';
GRANT ALL PRIVILEGES ON $site_url_safe.* TO 'wp_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON $site_url_safe.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;