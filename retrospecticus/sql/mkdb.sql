CREATE DATABASE PhotoTest;

use PhotoTest;

CREATE TABLE Site_User
( login_name      VARCHAR(20) NOT NULL,
  password        VARCHAR(60) NOT NULL,
  real_name       VARCHAR(40) NOT NULL,
  email           VARCHAR(40) NOT NULL,
  may_comment     TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  may_upload      TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  is_admin        TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY(login_name)
) TYPE = InnoDB;

CREATE TABLE Ownership
( login_name      VARCHAR(20) NOT NULL REFERENCES Site_User(login_name),
  directory       VARCHAR(255) NOT NULL,
  PRIMARY KEY(login_name, directory)
) TYPE = InnoDB;
