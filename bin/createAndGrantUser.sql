

CREATE USER 'vufind2'@'%' IDENTIFIED BY 'vufind2';
CREATE USER 'vufind2'@'localhost' IDENTIFIED BY 'vufind2';

GRANT ALL PRIVILEGES ON vfrd.* TO 'vufind2'@'localhost'  WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON vfrd.* TO 'vufind2'@'%'  WITH GRANT OPTION;
flush privileges;