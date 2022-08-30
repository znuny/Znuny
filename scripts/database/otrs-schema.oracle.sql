-- ----------------------------------------------------------
--  driver: oracle
-- ----------------------------------------------------------
SET DEFINE OFF;
SET SQLBLANKLINES ON;
-- ----------------------------------------------------------
--  create table acl
-- ----------------------------------------------------------
CREATE TABLE acl (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    description VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    stop_after_match NUMBER (5, 0) NULL,
    config_match CLOB NULL,
    config_change CLOB NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT acl_name UNIQUE (name)
);
ALTER TABLE acl ADD CONSTRAINT PK_acl PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_acl';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_acl
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_acl_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_acl_t
BEFORE INSERT ON acl
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_acl.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table acl_sync
-- ----------------------------------------------------------
CREATE TABLE acl_sync (
    acl_id VARCHAR2 (200) NOT NULL,
    sync_state VARCHAR2 (30) NOT NULL,
    create_time DATE NOT NULL,
    change_time DATE NOT NULL
);
-- ----------------------------------------------------------
--  create table acl_ticket_attribute_relations
-- ----------------------------------------------------------
CREATE TABLE acl_ticket_attribute_relations (
    id NUMBER (20, 0) NOT NULL,
    filename VARCHAR2 (255) NOT NULL,
    attribute_1 VARCHAR2 (200) NOT NULL,
    attribute_2 VARCHAR2 (200) NOT NULL,
    acl_data CLOB NOT NULL,
    priority NUMBER (20, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT acl_tar_filename UNIQUE (filename)
);
ALTER TABLE acl_ticket_attribute_relations ADD CONSTRAINT PK_acl_ticket_attribute_relac5 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_acl_ticket_attribute_reab';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_acl_ticket_attribute_reab
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_acl_ticket_attribute_reab_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_acl_ticket_attribute_reab_t
BEFORE INSERT ON acl_ticket_attribute_relations
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_acl_ticket_attribute_reab.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table valid
-- ----------------------------------------------------------
CREATE TABLE valid (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT valid_name UNIQUE (name)
);
ALTER TABLE valid ADD CONSTRAINT PK_valid PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_valid';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_valid
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_valid_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_valid_t
BEFORE INSERT ON valid
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_valid.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table users
-- ----------------------------------------------------------
CREATE TABLE users (
    id NUMBER (12, 0) NOT NULL,
    login VARCHAR2 (200) NOT NULL,
    pw VARCHAR2 (128) NOT NULL,
    title VARCHAR2 (50) NULL,
    first_name VARCHAR2 (100) NOT NULL,
    last_name VARCHAR2 (100) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT users_login UNIQUE (login)
);
ALTER TABLE users ADD CONSTRAINT PK_users PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_users';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_users
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_users_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_users_t
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_users.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table user_preferences
-- ----------------------------------------------------------
CREATE TABLE user_preferences (
    user_id NUMBER (12, 0) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value CLOB NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX user_preferences_user_id ON user_preferences (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table permission_groups
-- ----------------------------------------------------------
CREATE TABLE permission_groups (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT groups_name UNIQUE (name)
);
ALTER TABLE permission_groups ADD CONSTRAINT PK_permission_groups PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_permission_groups';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_permission_groups
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_permission_groups_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_permission_groups_t
BEFORE INSERT ON permission_groups
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_permission_groups.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table group_user
-- ----------------------------------------------------------
CREATE TABLE group_user (
    user_id NUMBER (12, 0) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    permission_key VARCHAR2 (20) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_user_group_id ON group_user (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_user_user_id ON group_user (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table group_role
-- ----------------------------------------------------------
CREATE TABLE group_role (
    role_id NUMBER (12, 0) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    permission_key VARCHAR2 (20) NOT NULL,
    permission_value NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_role_group_id ON group_role (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_role_role_id ON group_role (role_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table group_customer_user
-- ----------------------------------------------------------
CREATE TABLE group_customer_user (
    user_id VARCHAR2 (100) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    permission_key VARCHAR2 (20) NOT NULL,
    permission_value NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_customer_user_group_id ON group_customer_user (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_customer_user_user_id ON group_customer_user (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table group_customer
-- ----------------------------------------------------------
CREATE TABLE group_customer (
    customer_id VARCHAR2 (150) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    permission_key VARCHAR2 (20) NOT NULL,
    permission_value NUMBER (5, 0) NOT NULL,
    permission_context VARCHAR2 (100) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_customer_customer_id ON group_customer (customer_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX group_customer_group_id ON group_customer (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table roles
-- ----------------------------------------------------------
CREATE TABLE roles (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT roles_name UNIQUE (name)
);
ALTER TABLE roles ADD CONSTRAINT PK_roles PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_roles';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_roles
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_roles_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_roles_t
BEFORE INSERT ON roles
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_roles.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table role_user
-- ----------------------------------------------------------
CREATE TABLE role_user (
    user_id NUMBER (12, 0) NOT NULL,
    role_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX role_user_role_id ON role_user (role_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX role_user_user_id ON role_user (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table personal_queues
-- ----------------------------------------------------------
CREATE TABLE personal_queues (
    user_id NUMBER (12, 0) NOT NULL,
    queue_id NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX personal_queues_queue_id ON personal_queues (queue_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX personal_queues_user_id ON personal_queues (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table personal_services
-- ----------------------------------------------------------
CREATE TABLE personal_services (
    user_id NUMBER (12, 0) NOT NULL,
    service_id NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX personal_services_service_id ON personal_services (service_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX personal_services_user_id ON personal_services (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table salutation
-- ----------------------------------------------------------
CREATE TABLE salutation (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    text VARCHAR2 (3000) NOT NULL,
    content_type VARCHAR2 (250) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT salutation_name UNIQUE (name)
);
ALTER TABLE salutation ADD CONSTRAINT PK_salutation PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_salutation';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_salutation
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_salutation_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_salutation_t
BEFORE INSERT ON salutation
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_salutation.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table signature
-- ----------------------------------------------------------
CREATE TABLE signature (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    text VARCHAR2 (3000) NOT NULL,
    content_type VARCHAR2 (250) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT signature_name UNIQUE (name)
);
ALTER TABLE signature ADD CONSTRAINT PK_signature PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_signature';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_signature
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_signature_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_signature_t
BEFORE INSERT ON signature
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_signature.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table system_address
-- ----------------------------------------------------------
CREATE TABLE system_address (
    id NUMBER (5, 0) NOT NULL,
    value0 VARCHAR2 (200) NOT NULL,
    value1 VARCHAR2 (200) NOT NULL,
    value2 VARCHAR2 (200) NULL,
    value3 VARCHAR2 (200) NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE system_address ADD CONSTRAINT PK_system_address PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_system_address';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_system_address
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_system_address_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_system_address_t
BEFORE INSERT ON system_address
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_system_address.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table system_maintenance
-- ----------------------------------------------------------
CREATE TABLE system_maintenance (
    id NUMBER (12, 0) NOT NULL,
    start_date NUMBER (12, 0) NOT NULL,
    stop_date NUMBER (12, 0) NOT NULL,
    comments VARCHAR2 (250) NOT NULL,
    login_message VARCHAR2 (250) NULL,
    show_login_message NUMBER (5, 0) NULL,
    notify_message VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE system_maintenance ADD CONSTRAINT PK_system_maintenance PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_system_maintenance';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_system_maintenance
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_system_maintenance_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_system_maintenance_t
BEFORE INSERT ON system_maintenance
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_system_maintenance.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table follow_up_possible
-- ----------------------------------------------------------
CREATE TABLE follow_up_possible (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT follow_up_possible_name UNIQUE (name)
);
ALTER TABLE follow_up_possible ADD CONSTRAINT PK_follow_up_possible PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_follow_up_possible';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_follow_up_possible
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_follow_up_possible_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_follow_up_possible_t
BEFORE INSERT ON follow_up_possible
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_follow_up_possible.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table queue
-- ----------------------------------------------------------
CREATE TABLE queue (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    unlock_timeout NUMBER (12, 0) NULL,
    first_response_time NUMBER (12, 0) NULL,
    first_response_notify NUMBER (5, 0) NULL,
    update_time NUMBER (12, 0) NULL,
    update_notify NUMBER (5, 0) NULL,
    solution_time NUMBER (12, 0) NULL,
    solution_notify NUMBER (5, 0) NULL,
    system_address_id NUMBER (5, 0) NOT NULL,
    calendar_name VARCHAR2 (100) NULL,
    default_sign_key VARCHAR2 (100) NULL,
    salutation_id NUMBER (5, 0) NOT NULL,
    signature_id NUMBER (5, 0) NOT NULL,
    follow_up_id NUMBER (5, 0) NOT NULL,
    follow_up_lock NUMBER (5, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT queue_name UNIQUE (name)
);
ALTER TABLE queue ADD CONSTRAINT PK_queue PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_queue';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_queue
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_queue_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_queue_t
BEFORE INSERT ON queue
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_queue.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX queue_group_id ON queue (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table queue_preferences
-- ----------------------------------------------------------
CREATE TABLE queue_preferences (
    queue_id NUMBER (12, 0) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value VARCHAR2 (250) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX queue_preferences_queue_id ON queue_preferences (queue_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_priority
-- ----------------------------------------------------------
CREATE TABLE ticket_priority (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_priority_name UNIQUE (name)
);
ALTER TABLE ticket_priority ADD CONSTRAINT PK_ticket_priority PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_priority';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_priority
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_priority_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_priority_t
BEFORE INSERT ON ticket_priority
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_priority.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_type
-- ----------------------------------------------------------
CREATE TABLE ticket_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_type_name UNIQUE (name)
);
ALTER TABLE ticket_type ADD CONSTRAINT PK_ticket_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_type_t
BEFORE INSERT ON ticket_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_lock_type
-- ----------------------------------------------------------
CREATE TABLE ticket_lock_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_lock_type_name UNIQUE (name)
);
ALTER TABLE ticket_lock_type ADD CONSTRAINT PK_ticket_lock_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_lock_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_lock_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_lock_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_lock_type_t
BEFORE INSERT ON ticket_lock_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_lock_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_state
-- ----------------------------------------------------------
CREATE TABLE ticket_state (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    type_id NUMBER (5, 0) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_state_name UNIQUE (name)
);
ALTER TABLE ticket_state ADD CONSTRAINT PK_ticket_state PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_state';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_state
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_state_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_state_t
BEFORE INSERT ON ticket_state
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_state.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_state_type
-- ----------------------------------------------------------
CREATE TABLE ticket_state_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_state_type_name UNIQUE (name)
);
ALTER TABLE ticket_state_type ADD CONSTRAINT PK_ticket_state_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_state_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_state_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_state_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_state_type_t
BEFORE INSERT ON ticket_state_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_state_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket
-- ----------------------------------------------------------
CREATE TABLE ticket (
    id NUMBER (20, 0) NOT NULL,
    tn VARCHAR2 (50) NOT NULL,
    title VARCHAR2 (255) NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    ticket_lock_id NUMBER (5, 0) NOT NULL,
    type_id NUMBER (5, 0) NULL,
    service_id NUMBER (12, 0) NULL,
    sla_id NUMBER (12, 0) NULL,
    user_id NUMBER (12, 0) NOT NULL,
    responsible_user_id NUMBER (12, 0) NOT NULL,
    ticket_priority_id NUMBER (5, 0) NOT NULL,
    ticket_state_id NUMBER (5, 0) NOT NULL,
    customer_id VARCHAR2 (150) NULL,
    customer_user_id VARCHAR2 (250) NULL,
    timeout NUMBER (12, 0) NOT NULL,
    until_time NUMBER (12, 0) NOT NULL,
    escalation_time NUMBER (12, 0) NOT NULL,
    escalation_update_time NUMBER (12, 0) NOT NULL,
    escalation_response_time NUMBER (12, 0) NOT NULL,
    escalation_solution_time NUMBER (12, 0) NOT NULL,
    archive_flag NUMBER (5, 0) DEFAULT 0 NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_tn UNIQUE (tn)
);
ALTER TABLE ticket ADD CONSTRAINT PK_ticket PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_t
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_archive_flag ON ticket (archive_flag)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_create_time ON ticket (create_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_customer_id ON ticket (customer_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_customer_user_id ON ticket (customer_user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_escalation_response_t29 ON ticket (escalation_response_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_escalation_solution_td9 ON ticket (escalation_solution_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_escalation_time ON ticket (escalation_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_escalation_update_time ON ticket (escalation_update_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_queue_id ON ticket (queue_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_queue_view ON ticket (ticket_state_id, ticket_lock_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_responsible_user_id ON ticket (responsible_user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_ticket_lock_id ON ticket (ticket_lock_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_ticket_priority_id ON ticket (ticket_priority_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_ticket_state_id ON ticket (ticket_state_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_timeout ON ticket (timeout)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_title ON ticket (title)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_type_id ON ticket (type_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_until_time ON ticket (until_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_user_id ON ticket (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_flag
-- ----------------------------------------------------------
CREATE TABLE ticket_flag (
    ticket_id NUMBER (20, 0) NOT NULL,
    ticket_key VARCHAR2 (50) NOT NULL,
    ticket_value VARCHAR2 (50) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_flag_per_user UNIQUE (ticket_id, ticket_key, create_by)
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_flag_ticket_id ON ticket_flag (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_flag_ticket_id_create7d ON ticket_flag (ticket_id, create_by)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_flag_ticket_id_ticketca ON ticket_flag (ticket_id, ticket_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_history
-- ----------------------------------------------------------
CREATE TABLE ticket_history (
    id NUMBER (20, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    history_type_id NUMBER (5, 0) NOT NULL,
    ticket_id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NULL,
    type_id NUMBER (5, 0) NOT NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    owner_id NUMBER (12, 0) NOT NULL,
    priority_id NUMBER (5, 0) NOT NULL,
    state_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE ticket_history ADD CONSTRAINT PK_ticket_history PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_history';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_history
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_history_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_history_t
BEFORE INSERT ON ticket_history
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_history.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_article_id ON ticket_history (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_create_time ON ticket_history (create_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_history_type_id ON ticket_history (history_type_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_owner_id ON ticket_history (owner_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_priority_id ON ticket_history (priority_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_queue_id ON ticket_history (queue_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_state_id ON ticket_history (state_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_ticket_id ON ticket_history (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_history_type_id ON ticket_history (type_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_history_type
-- ----------------------------------------------------------
CREATE TABLE ticket_history_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT ticket_history_type_name UNIQUE (name)
);
ALTER TABLE ticket_history_type ADD CONSTRAINT PK_ticket_history_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_history_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_history_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_history_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_history_type_t
BEFORE INSERT ON ticket_history_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_history_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_watcher
-- ----------------------------------------------------------
CREATE TABLE ticket_watcher (
    ticket_id NUMBER (20, 0) NOT NULL,
    user_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_watcher_ticket_id ON ticket_watcher (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_watcher_user_id ON ticket_watcher (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_index
-- ----------------------------------------------------------
CREATE TABLE ticket_index (
    ticket_id NUMBER (20, 0) NOT NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    queue VARCHAR2 (200) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    s_lock VARCHAR2 (200) NOT NULL,
    s_state VARCHAR2 (200) NOT NULL,
    create_time DATE NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_index_group_id ON ticket_index (group_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_index_queue_id ON ticket_index (queue_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_index_ticket_id ON ticket_index (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_lock_index
-- ----------------------------------------------------------
CREATE TABLE ticket_lock_index (
    ticket_id NUMBER (20, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_lock_index_ticket_id ON ticket_lock_index (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_loop_protection
-- ----------------------------------------------------------
CREATE TABLE ticket_loop_protection (
    sent_to VARCHAR2 (250) NOT NULL,
    sent_date VARCHAR2 (150) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_loop_protection_sent_37 ON ticket_loop_protection (sent_date)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_loop_protection_sent_to ON ticket_loop_protection (sent_to)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_sender_type
-- ----------------------------------------------------------
CREATE TABLE article_sender_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT article_sender_type_name UNIQUE (name)
);
ALTER TABLE article_sender_type ADD CONSTRAINT PK_article_sender_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_sender_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_sender_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_sender_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_sender_type_t
BEFORE INSERT ON article_sender_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_sender_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_flag
-- ----------------------------------------------------------
CREATE TABLE article_flag (
    article_id NUMBER (20, 0) NOT NULL,
    article_key VARCHAR2 (50) NOT NULL,
    article_value VARCHAR2 (50) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_flag_article_id ON article_flag (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_flag_article_id_crea15 ON article_flag (article_id, create_by)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table communication_channel
-- ----------------------------------------------------------
CREATE TABLE communication_channel (
    id NUMBER (20, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    module VARCHAR2 (200) NOT NULL,
    package_name VARCHAR2 (200) NOT NULL,
    channel_data CLOB NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT communication_channel_name UNIQUE (name)
);
ALTER TABLE communication_channel ADD CONSTRAINT PK_communication_channel PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_communication_channel';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_communication_channel
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_communication_channel_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_communication_channel_t
BEFORE INSERT ON communication_channel
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_communication_channel.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article
-- ----------------------------------------------------------
CREATE TABLE article (
    id NUMBER (20, 0) NOT NULL,
    ticket_id NUMBER (20, 0) NOT NULL,
    article_sender_type_id NUMBER (5, 0) NOT NULL,
    communication_channel_id NUMBER (20, 0) NOT NULL,
    is_visible_for_customer NUMBER (5, 0) NOT NULL,
    search_index_needs_rebuild NUMBER (5, 0) DEFAULT 1 NOT NULL,
    insert_fingerprint VARCHAR2 (64) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE article ADD CONSTRAINT PK_article PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_t
BEFORE INSERT ON article
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_article_sender_type_id ON article (article_sender_type_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_communication_channe74 ON article (communication_channel_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_search_index_needs_rf7 ON article (search_index_needs_rebuild)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_ticket_id ON article (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_data_mime
-- ----------------------------------------------------------
CREATE TABLE article_data_mime (
    id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    a_from CLOB NULL,
    a_reply_to CLOB NULL,
    a_to CLOB NULL,
    a_cc CLOB NULL,
    a_bcc CLOB NULL,
    a_subject VARCHAR2 (3800) NULL,
    a_message_id VARCHAR2 (3800) NULL,
    a_message_id_md5 VARCHAR2 (32) NULL,
    a_in_reply_to CLOB NULL,
    a_references CLOB NULL,
    a_content_type VARCHAR2 (250) NULL,
    a_body CLOB NULL,
    incoming_time NUMBER (12, 0) NOT NULL,
    content_path VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE article_data_mime ADD CONSTRAINT PK_article_data_mime PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_data_mime';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_data_mime
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_data_mime_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_data_mime_t
BEFORE INSERT ON article_data_mime
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_data_mime.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_article_id ON article_data_mime (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_message_idf3 ON article_data_mime (a_message_id_md5)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_search_index
-- ----------------------------------------------------------
CREATE TABLE article_search_index (
    id NUMBER (20, 0) NOT NULL,
    ticket_id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    article_key VARCHAR2 (200) NOT NULL,
    article_value CLOB NULL
);
ALTER TABLE article_search_index ADD CONSTRAINT PK_article_search_index PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_search_index';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_search_index
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_search_index_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_search_index_t
BEFORE INSERT ON article_search_index
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_search_index.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_search_index_article43 ON article_search_index (article_id, article_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_search_index_ticket_id ON article_search_index (ticket_id, article_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_data_mime_plain
-- ----------------------------------------------------------
CREATE TABLE article_data_mime_plain (
    id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    body CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE article_data_mime_plain ADD CONSTRAINT PK_article_data_mime_plain PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_data_mime_plain';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_data_mime_plain
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_data_mime_plain_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_data_mime_plain_t
BEFORE INSERT ON article_data_mime_plain
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_data_mime_plain.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_plain_artid4 ON article_data_mime_plain (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_data_mime_attachment
-- ----------------------------------------------------------
CREATE TABLE article_data_mime_attachment (
    id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    filename VARCHAR2 (250) NULL,
    content_size VARCHAR2 (30) NULL,
    content_type VARCHAR2 (450) NULL,
    content_id VARCHAR2 (250) NULL,
    content_alternative VARCHAR2 (50) NULL,
    disposition VARCHAR2 (15) NULL,
    content CLOB NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE article_data_mime_attachment ADD CONSTRAINT PK_article_data_mime_attachmbb PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_data_mime_attac4b';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_data_mime_attac4b
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_data_mime_attac4b_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_data_mime_attac4b_t
BEFORE INSERT ON article_data_mime_attachment
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_data_mime_attac4b.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_attachmentcb ON article_data_mime_attachment (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_data_mime_send_error
-- ----------------------------------------------------------
CREATE TABLE article_data_mime_send_error (
    id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    message_id VARCHAR2 (200) NULL,
    log_message CLOB NULL,
    create_time DATE NOT NULL
);
ALTER TABLE article_data_mime_send_error ADD CONSTRAINT PK_article_data_mime_send_erb5 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_data_mime_send_97';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_data_mime_send_97
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_data_mime_send_97_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_data_mime_send_97_t
BEFORE INSERT ON article_data_mime_send_error
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_data_mime_send_97.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_transmissi0b ON article_data_mime_send_error (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_mime_transmissi4d ON article_data_mime_send_error (message_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table article_data_otrs_chat
-- ----------------------------------------------------------
CREATE TABLE article_data_otrs_chat (
    id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NOT NULL,
    chat_participant_id VARCHAR2 (255) NOT NULL,
    chat_participant_name VARCHAR2 (255) NOT NULL,
    chat_participant_type VARCHAR2 (255) NOT NULL,
    message_text VARCHAR2 (3800) NULL,
    system_generated NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL
);
ALTER TABLE article_data_otrs_chat ADD CONSTRAINT PK_article_data_otrs_chat PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_article_data_otrs_chat';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_article_data_otrs_chat
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_article_data_otrs_chat_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_article_data_otrs_chat_t
BEFORE INSERT ON article_data_otrs_chat
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_article_data_otrs_chat.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX article_data_otrs_chat_artic16 ON article_data_otrs_chat (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table time_accounting
-- ----------------------------------------------------------
CREATE TABLE time_accounting (
    id NUMBER (20, 0) NOT NULL,
    ticket_id NUMBER (20, 0) NOT NULL,
    article_id NUMBER (20, 0) NULL,
    time_unit DECIMAL (10,2) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE time_accounting ADD CONSTRAINT PK_time_accounting PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_time_accounting';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_time_accounting
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_time_accounting_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_time_accounting_t
BEFORE INSERT ON time_accounting
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_time_accounting.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX time_accounting_article_id ON time_accounting (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX time_accounting_ticket_id ON time_accounting (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table standard_template
-- ----------------------------------------------------------
CREATE TABLE standard_template (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    text CLOB NULL,
    content_type VARCHAR2 (250) NULL,
    template_type VARCHAR2 (100) DEFAULT 'Answer' NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT standard_template_name UNIQUE (name)
);
ALTER TABLE standard_template ADD CONSTRAINT PK_standard_template PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_standard_template';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_standard_template
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_standard_template_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_standard_template_t
BEFORE INSERT ON standard_template
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_standard_template.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table queue_standard_template
-- ----------------------------------------------------------
CREATE TABLE queue_standard_template (
    queue_id NUMBER (12, 0) NOT NULL,
    standard_template_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
-- ----------------------------------------------------------
--  create table standard_attachment
-- ----------------------------------------------------------
CREATE TABLE standard_attachment (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    content_type VARCHAR2 (250) NOT NULL,
    content CLOB NOT NULL,
    filename VARCHAR2 (250) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT standard_attachment_name UNIQUE (name)
);
ALTER TABLE standard_attachment ADD CONSTRAINT PK_standard_attachment PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_standard_attachment';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_standard_attachment
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_standard_attachment_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_standard_attachment_t
BEFORE INSERT ON standard_attachment
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_standard_attachment.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table standard_template_attachment
-- ----------------------------------------------------------
CREATE TABLE standard_template_attachment (
    id NUMBER (12, 0) NOT NULL,
    standard_attachment_id NUMBER (12, 0) NOT NULL,
    standard_template_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE standard_template_attachment ADD CONSTRAINT PK_standard_template_attachmb7 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_standard_template_attacc3';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_standard_template_attacc3
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_standard_template_attacc3_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_standard_template_attacc3_t
BEFORE INSERT ON standard_template_attachment
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_standard_template_attacc3.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table auto_response_type
-- ----------------------------------------------------------
CREATE TABLE auto_response_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT auto_response_type_name UNIQUE (name)
);
ALTER TABLE auto_response_type ADD CONSTRAINT PK_auto_response_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_auto_response_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_auto_response_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_auto_response_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_auto_response_type_t
BEFORE INSERT ON auto_response_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_auto_response_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table auto_response
-- ----------------------------------------------------------
CREATE TABLE auto_response (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    text0 CLOB NULL,
    text1 CLOB NULL,
    type_id NUMBER (5, 0) NOT NULL,
    system_address_id NUMBER (5, 0) NOT NULL,
    content_type VARCHAR2 (250) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT auto_response_name UNIQUE (name)
);
ALTER TABLE auto_response ADD CONSTRAINT PK_auto_response PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_auto_response';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_auto_response
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_auto_response_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_auto_response_t
BEFORE INSERT ON auto_response
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_auto_response.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table queue_auto_response
-- ----------------------------------------------------------
CREATE TABLE queue_auto_response (
    id NUMBER (12, 0) NOT NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    auto_response_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE queue_auto_response ADD CONSTRAINT PK_queue_auto_response PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_queue_auto_response';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_queue_auto_response
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_queue_auto_response_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_queue_auto_response_t
BEFORE INSERT ON queue_auto_response
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_queue_auto_response.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table service
-- ----------------------------------------------------------
CREATE TABLE service (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT service_name UNIQUE (name)
);
ALTER TABLE service ADD CONSTRAINT PK_service PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_service';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_service
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_service_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_service_t
BEFORE INSERT ON service
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_service.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table service_preferences
-- ----------------------------------------------------------
CREATE TABLE service_preferences (
    service_id NUMBER (12, 0) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value VARCHAR2 (250) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX service_preferences_service_id ON service_preferences (service_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table service_customer_user
-- ----------------------------------------------------------
CREATE TABLE service_customer_user (
    customer_user_login VARCHAR2 (200) NOT NULL,
    service_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX service_customer_user_custom7e ON service_customer_user (customer_user_login)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX service_customer_user_servic99 ON service_customer_user (service_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sla
-- ----------------------------------------------------------
CREATE TABLE sla (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    calendar_name VARCHAR2 (100) NULL,
    first_response_time NUMBER (12, 0) NOT NULL,
    first_response_notify NUMBER (5, 0) NULL,
    update_time NUMBER (12, 0) NOT NULL,
    update_notify NUMBER (5, 0) NULL,
    solution_time NUMBER (12, 0) NOT NULL,
    solution_notify NUMBER (5, 0) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT sla_name UNIQUE (name)
);
ALTER TABLE sla ADD CONSTRAINT PK_sla PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sla';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sla
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sla_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sla_t
BEFORE INSERT ON sla
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sla.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sla_preferences
-- ----------------------------------------------------------
CREATE TABLE sla_preferences (
    sla_id NUMBER (12, 0) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value VARCHAR2 (250) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX sla_preferences_sla_id ON sla_preferences (sla_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table service_sla
-- ----------------------------------------------------------
CREATE TABLE service_sla (
    service_id NUMBER (12, 0) NOT NULL,
    sla_id NUMBER (12, 0) NOT NULL,
    CONSTRAINT service_sla_service_sla UNIQUE (service_id, sla_id)
);
-- ----------------------------------------------------------
--  create table sessions
-- ----------------------------------------------------------
CREATE TABLE sessions (
    id NUMBER (20, 0) NOT NULL,
    session_id VARCHAR2 (100) NOT NULL,
    data_key VARCHAR2 (100) NOT NULL,
    data_value CLOB NULL,
    serialized NUMBER (5, 0) NOT NULL
);
ALTER TABLE sessions ADD CONSTRAINT PK_sessions PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sessions';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sessions
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sessions_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sessions_t
BEFORE INSERT ON sessions
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sessions.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX sessions_data_key ON sessions (data_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX sessions_session_id_data_key ON sessions (session_id, data_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table customer_user
-- ----------------------------------------------------------
CREATE TABLE customer_user (
    id NUMBER (12, 0) NOT NULL,
    login VARCHAR2 (200) NOT NULL,
    email VARCHAR2 (150) NOT NULL,
    customer_id VARCHAR2 (150) NOT NULL,
    pw VARCHAR2 (128) NULL,
    title VARCHAR2 (50) NULL,
    first_name VARCHAR2 (100) NOT NULL,
    last_name VARCHAR2 (100) NOT NULL,
    phone VARCHAR2 (150) NULL,
    fax VARCHAR2 (150) NULL,
    mobile VARCHAR2 (150) NULL,
    street VARCHAR2 (150) NULL,
    zip VARCHAR2 (200) NULL,
    city VARCHAR2 (200) NULL,
    country VARCHAR2 (200) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT customer_user_login UNIQUE (login)
);
ALTER TABLE customer_user ADD CONSTRAINT PK_customer_user PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_customer_user';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_customer_user
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_customer_user_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_customer_user_t
BEFORE INSERT ON customer_user
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_customer_user.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table customer_preferences
-- ----------------------------------------------------------
CREATE TABLE customer_preferences (
    user_id VARCHAR2 (250) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value VARCHAR2 (250) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX customer_preferences_user_id ON customer_preferences (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table customer_company
-- ----------------------------------------------------------
CREATE TABLE customer_company (
    customer_id VARCHAR2 (150) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    street VARCHAR2 (200) NULL,
    zip VARCHAR2 (200) NULL,
    city VARCHAR2 (200) NULL,
    country VARCHAR2 (200) NULL,
    url VARCHAR2 (200) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT customer_company_name UNIQUE (name)
);
ALTER TABLE customer_company ADD CONSTRAINT PK_customer_company PRIMARY KEY (customer_id);
-- ----------------------------------------------------------
--  create table customer_user_customer
-- ----------------------------------------------------------
CREATE TABLE customer_user_customer (
    user_id VARCHAR2 (100) NOT NULL,
    customer_id VARCHAR2 (150) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX customer_user_customer_custo95 ON customer_user_customer (customer_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX customer_user_customer_user_id ON customer_user_customer (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table mail_account
-- ----------------------------------------------------------
CREATE TABLE mail_account (
    id NUMBER (12, 0) NOT NULL,
    login VARCHAR2 (200) NOT NULL,
    pw VARCHAR2 (200) NOT NULL,
    host VARCHAR2 (200) NOT NULL,
    account_type VARCHAR2 (20) NOT NULL,
    queue_id NUMBER (12, 0) NOT NULL,
    trusted NUMBER (5, 0) NOT NULL,
    imap_folder VARCHAR2 (250) NULL,
    authentication_type VARCHAR2 (100) DEFAULT 'password' NOT NULL,
    oauth2_token_config_id NUMBER (12, 0) NULL,
    comments VARCHAR2 (250) NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE mail_account ADD CONSTRAINT PK_mail_account PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_mail_account';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_mail_account
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_mail_account_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_mail_account_t
BEFORE INSERT ON mail_account
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_mail_account.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table postmaster_filter
-- ----------------------------------------------------------
CREATE TABLE postmaster_filter (
    f_name VARCHAR2 (200) NOT NULL,
    f_stop NUMBER (5, 0) NULL,
    f_type VARCHAR2 (20) NOT NULL,
    f_key VARCHAR2 (200) NOT NULL,
    f_value VARCHAR2 (200) NOT NULL,
    f_not NUMBER (5, 0) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX postmaster_filter_f_name ON postmaster_filter (f_name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table generic_agent_jobs
-- ----------------------------------------------------------
CREATE TABLE generic_agent_jobs (
    job_name VARCHAR2 (200) NOT NULL,
    job_key VARCHAR2 (200) NOT NULL,
    job_value VARCHAR2 (200) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX generic_agent_jobs_job_name ON generic_agent_jobs (job_name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table search_profile
-- ----------------------------------------------------------
CREATE TABLE search_profile (
    login VARCHAR2 (200) NOT NULL,
    profile_name VARCHAR2 (200) NOT NULL,
    profile_type VARCHAR2 (30) NOT NULL,
    profile_key VARCHAR2 (200) NOT NULL,
    profile_value VARCHAR2 (200) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX search_profile_login ON search_profile (login)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX search_profile_profile_name ON search_profile (profile_name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table process_id
-- ----------------------------------------------------------
CREATE TABLE process_id (
    process_name VARCHAR2 (200) NOT NULL,
    process_id VARCHAR2 (200) NOT NULL,
    process_host VARCHAR2 (200) NOT NULL,
    process_create NUMBER (12, 0) NOT NULL,
    process_change NUMBER (12, 0) NOT NULL
);
-- ----------------------------------------------------------
--  create table web_upload_cache
-- ----------------------------------------------------------
CREATE TABLE web_upload_cache (
    form_id VARCHAR2 (250) NULL,
    filename VARCHAR2 (250) NULL,
    content_id VARCHAR2 (250) NULL,
    content_size VARCHAR2 (30) NULL,
    content_type VARCHAR2 (250) NULL,
    disposition VARCHAR2 (15) NULL,
    content CLOB NOT NULL,
    create_time_unix NUMBER (20, 0) NOT NULL
);
-- ----------------------------------------------------------
--  create table notification_event
-- ----------------------------------------------------------
CREATE TABLE notification_event (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT notification_event_name UNIQUE (name)
);
ALTER TABLE notification_event ADD CONSTRAINT PK_notification_event PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_notification_event';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_notification_event
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_notification_event_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_notification_event_t
BEFORE INSERT ON notification_event
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_notification_event.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table notification_event_message
-- ----------------------------------------------------------
CREATE TABLE notification_event_message (
    id NUMBER (12, 0) NOT NULL,
    notification_id NUMBER (12, 0) NOT NULL,
    subject VARCHAR2 (200) NOT NULL,
    text VARCHAR2 (4000) NOT NULL,
    content_type VARCHAR2 (250) NOT NULL,
    language VARCHAR2 (60) NOT NULL,
    CONSTRAINT notification_event_message_nb4 UNIQUE (notification_id, language)
);
ALTER TABLE notification_event_message ADD CONSTRAINT PK_notification_event_message PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_notification_event_messe4';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_notification_event_messe4
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_notification_event_messe4_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_notification_event_messe4_t
BEFORE INSERT ON notification_event_message
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_notification_event_messe4.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX notification_event_message_lb8 ON notification_event_message (language)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX notification_event_message_n1c ON notification_event_message (notification_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table notification_event_item
-- ----------------------------------------------------------
CREATE TABLE notification_event_item (
    notification_id NUMBER (12, 0) NOT NULL,
    event_key VARCHAR2 (200) NOT NULL,
    event_value VARCHAR2 (200) NOT NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX notification_event_item_even64 ON notification_event_item (event_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX notification_event_item_evene4 ON notification_event_item (event_value)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX notification_event_item_notidc ON notification_event_item (notification_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table link_type
-- ----------------------------------------------------------
CREATE TABLE link_type (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (50) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT link_type_name UNIQUE (name)
);
ALTER TABLE link_type ADD CONSTRAINT PK_link_type PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_link_type';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_link_type
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_link_type_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_link_type_t
BEFORE INSERT ON link_type
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_link_type.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table link_state
-- ----------------------------------------------------------
CREATE TABLE link_state (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (50) NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT link_state_name UNIQUE (name)
);
ALTER TABLE link_state ADD CONSTRAINT PK_link_state PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_link_state';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_link_state
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_link_state_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_link_state_t
BEFORE INSERT ON link_state
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_link_state.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table link_object
-- ----------------------------------------------------------
CREATE TABLE link_object (
    id NUMBER (5, 0) NOT NULL,
    name VARCHAR2 (100) NOT NULL,
    CONSTRAINT link_object_name UNIQUE (name)
);
ALTER TABLE link_object ADD CONSTRAINT PK_link_object PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_link_object';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_link_object
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_link_object_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_link_object_t
BEFORE INSERT ON link_object
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_link_object.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table link_relation
-- ----------------------------------------------------------
CREATE TABLE link_relation (
    source_object_id NUMBER (5, 0) NOT NULL,
    source_key VARCHAR2 (50) NOT NULL,
    target_object_id NUMBER (5, 0) NOT NULL,
    target_key VARCHAR2 (50) NOT NULL,
    type_id NUMBER (5, 0) NOT NULL,
    state_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT link_relation_view UNIQUE (source_object_id, source_key, target_object_id, target_key, type_id)
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX link_relation_list_source ON link_relation (source_object_id, source_key, state_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX link_relation_list_target ON link_relation (target_object_id, target_key, state_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table system_data
-- ----------------------------------------------------------
CREATE TABLE system_data (
    data_key VARCHAR2 (160) NOT NULL,
    data_value CLOB NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE system_data ADD CONSTRAINT PK_system_data PRIMARY KEY (data_key);
-- ----------------------------------------------------------
--  create table xml_storage
-- ----------------------------------------------------------
CREATE TABLE xml_storage (
    xml_type VARCHAR2 (200) NOT NULL,
    xml_key VARCHAR2 (250) NOT NULL,
    xml_content_key VARCHAR2 (250) NOT NULL,
    xml_content_value CLOB NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX xml_storage_key_type ON xml_storage (xml_key, xml_type)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX xml_storage_xml_content_key ON xml_storage (xml_content_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table virtual_fs
-- ----------------------------------------------------------
CREATE TABLE virtual_fs (
    id NUMBER (20, 0) NOT NULL,
    filename VARCHAR2 (350) NOT NULL,
    backend VARCHAR2 (60) NOT NULL,
    backend_key VARCHAR2 (160) NOT NULL,
    create_time DATE NOT NULL
);
ALTER TABLE virtual_fs ADD CONSTRAINT PK_virtual_fs PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_virtual_fs';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_virtual_fs
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_virtual_fs_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_virtual_fs_t
BEFORE INSERT ON virtual_fs
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_virtual_fs.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX virtual_fs_backend ON virtual_fs (backend)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX virtual_fs_filename ON virtual_fs (filename)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table virtual_fs_preferences
-- ----------------------------------------------------------
CREATE TABLE virtual_fs_preferences (
    virtual_fs_id NUMBER (20, 0) NOT NULL,
    preferences_key VARCHAR2 (150) NOT NULL,
    preferences_value VARCHAR2 (350) NULL
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX virtual_fs_preferences_key_v7c ON virtual_fs_preferences (preferences_key, preferences_value)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX virtual_fs_preferences_virtuf6 ON virtual_fs_preferences (virtual_fs_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table virtual_fs_db
-- ----------------------------------------------------------
CREATE TABLE virtual_fs_db (
    id NUMBER (20, 0) NOT NULL,
    filename VARCHAR2 (350) NOT NULL,
    content CLOB NULL,
    create_time DATE NOT NULL
);
ALTER TABLE virtual_fs_db ADD CONSTRAINT PK_virtual_fs_db PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_virtual_fs_db';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_virtual_fs_db
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_virtual_fs_db_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_virtual_fs_db_t
BEFORE INSERT ON virtual_fs_db
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_virtual_fs_db.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX virtual_fs_db_filename ON virtual_fs_db (filename)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table package_repository
-- ----------------------------------------------------------
CREATE TABLE package_repository (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    version VARCHAR2 (250) NOT NULL,
    vendor VARCHAR2 (250) NOT NULL,
    install_status VARCHAR2 (250) NOT NULL,
    filename VARCHAR2 (250) NULL,
    content_type VARCHAR2 (250) NULL,
    content CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE package_repository ADD CONSTRAINT PK_package_repository PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_package_repository';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_package_repository
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_package_repository_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_package_repository_t
BEFORE INSERT ON package_repository
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_package_repository.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table gi_webservice_config
-- ----------------------------------------------------------
CREATE TABLE gi_webservice_config (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT gi_webservice_config_name UNIQUE (name)
);
ALTER TABLE gi_webservice_config ADD CONSTRAINT PK_gi_webservice_config PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_gi_webservice_config';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_gi_webservice_config
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_gi_webservice_config_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_gi_webservice_config_t
BEFORE INSERT ON gi_webservice_config
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_gi_webservice_config.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table gi_webservice_config_history
-- ----------------------------------------------------------
CREATE TABLE gi_webservice_config_history (
    id NUMBER (20, 0) NOT NULL,
    config_id NUMBER (12, 0) NOT NULL,
    config CLOB NOT NULL,
    config_md5 VARCHAR2 (32) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT gi_webservice_config_history8b UNIQUE (config_md5)
);
ALTER TABLE gi_webservice_config_history ADD CONSTRAINT PK_gi_webservice_config_hist06 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_gi_webservice_config_hi2f';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_gi_webservice_config_hi2f
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_gi_webservice_config_hi2f_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_gi_webservice_config_hi2f_t
BEFORE INSERT ON gi_webservice_config_history
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_gi_webservice_config_hi2f.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table gi_debugger_entry
-- ----------------------------------------------------------
CREATE TABLE gi_debugger_entry (
    id NUMBER (20, 0) NOT NULL,
    communication_id VARCHAR2 (32) NOT NULL,
    communication_type VARCHAR2 (50) NOT NULL,
    remote_ip VARCHAR2 (50) NULL,
    webservice_id NUMBER (12, 0) NOT NULL,
    create_time DATE NOT NULL,
    CONSTRAINT gi_debugger_entry_communicat94 UNIQUE (communication_id)
);
ALTER TABLE gi_debugger_entry ADD CONSTRAINT PK_gi_debugger_entry PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_gi_debugger_entry';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_gi_debugger_entry
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_gi_debugger_entry_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_gi_debugger_entry_t
BEFORE INSERT ON gi_debugger_entry
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_gi_debugger_entry.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX gi_debugger_entry_create_time ON gi_debugger_entry (create_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table gi_debugger_entry_content
-- ----------------------------------------------------------
CREATE TABLE gi_debugger_entry_content (
    id NUMBER (20, 0) NOT NULL,
    gi_debugger_entry_id NUMBER (20, 0) NOT NULL,
    debug_level VARCHAR2 (50) NOT NULL,
    subject VARCHAR2 (255) NOT NULL,
    content CLOB NULL,
    create_time DATE NOT NULL
);
ALTER TABLE gi_debugger_entry_content ADD CONSTRAINT PK_gi_debugger_entry_content PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_gi_debugger_entry_content';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_gi_debugger_entry_content
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_gi_debugger_entry_content_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_gi_debugger_entry_content_t
BEFORE INSERT ON gi_debugger_entry_content
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_gi_debugger_entry_content.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX gi_debugger_entry_content_cr4e ON gi_debugger_entry_content (create_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX gi_debugger_entry_content_dea1 ON gi_debugger_entry_content (debug_level)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table smime_signer_cert_relations
-- ----------------------------------------------------------
CREATE TABLE smime_signer_cert_relations (
    id NUMBER (12, 0) NOT NULL,
    cert_hash VARCHAR2 (8) NOT NULL,
    cert_fingerprint VARCHAR2 (59) NOT NULL,
    ca_hash VARCHAR2 (8) NOT NULL,
    ca_fingerprint VARCHAR2 (59) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE smime_signer_cert_relations ADD CONSTRAINT PK_smime_signer_cert_relations PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_smime_signer_cert_relatef';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_smime_signer_cert_relatef
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_smime_signer_cert_relatef_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_smime_signer_cert_relatef_t
BEFORE INSERT ON smime_signer_cert_relations
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_smime_signer_cert_relatef.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table dynamic_field_value
-- ----------------------------------------------------------
CREATE TABLE dynamic_field_value (
    id NUMBER (12, 0) NOT NULL,
    field_id NUMBER (12, 0) NOT NULL,
    object_id NUMBER (20, 0) NOT NULL,
    value_text VARCHAR2 (3800) NULL,
    value_date DATE NULL,
    value_int NUMBER (20, 0) NULL
);
ALTER TABLE dynamic_field_value ADD CONSTRAINT PK_dynamic_field_value PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_dynamic_field_value';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_dynamic_field_value
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_dynamic_field_value_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_dynamic_field_value_t
BEFORE INSERT ON dynamic_field_value
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_dynamic_field_value.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX dynamic_field_value_field_va6e ON dynamic_field_value (object_id, field_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX dynamic_field_value_search_db3 ON dynamic_field_value (field_id, value_date)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX dynamic_field_value_search_int ON dynamic_field_value (field_id, value_int)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX dynamic_field_value_search_tbc ON dynamic_field_value (field_id, value_text)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table dynamic_field
-- ----------------------------------------------------------
CREATE TABLE dynamic_field (
    id NUMBER (12, 0) NOT NULL,
    internal_field NUMBER (5, 0) DEFAULT 0 NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    label VARCHAR2 (200) NOT NULL,
    field_order NUMBER (12, 0) NOT NULL,
    field_type VARCHAR2 (200) NOT NULL,
    object_type VARCHAR2 (100) NOT NULL,
    config CLOB NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT dynamic_field_name UNIQUE (name)
);
ALTER TABLE dynamic_field ADD CONSTRAINT PK_dynamic_field PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_dynamic_field';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_dynamic_field
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_dynamic_field_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_dynamic_field_t
BEFORE INSERT ON dynamic_field
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_dynamic_field.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table dynamic_field_obj_id_name
-- ----------------------------------------------------------
CREATE TABLE dynamic_field_obj_id_name (
    object_id NUMBER (12, 0) NOT NULL,
    object_name VARCHAR2 (200) NOT NULL,
    object_type VARCHAR2 (100) NOT NULL,
    CONSTRAINT dynamic_field_object_name UNIQUE (object_name, object_type)
);
ALTER TABLE dynamic_field_obj_id_name ADD CONSTRAINT PK_dynamic_field_obj_id_name PRIMARY KEY (object_id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_dynamic_field_obj_id_name';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_dynamic_field_obj_id_name
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_dynamic_field_obj_id_name_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_dynamic_field_obj_id_name_t
BEFORE INSERT ON dynamic_field_obj_id_name
FOR EACH ROW
BEGIN
    IF :new.object_id IS NULL THEN
        SELECT SE_dynamic_field_obj_id_name.nextval
        INTO :new.object_id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_process
-- ----------------------------------------------------------
CREATE TABLE pm_process (
    id NUMBER (12, 0) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    state_entity_id VARCHAR2 (50) NOT NULL,
    layout CLOB NOT NULL,
    config CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT pm_process_entity_id UNIQUE (entity_id)
);
ALTER TABLE pm_process ADD CONSTRAINT PK_pm_process PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_pm_process';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_pm_process
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_pm_process_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_pm_process_t
BEFORE INSERT ON pm_process
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_pm_process.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_activity
-- ----------------------------------------------------------
CREATE TABLE pm_activity (
    id NUMBER (12, 0) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT pm_activity_entity_id UNIQUE (entity_id)
);
ALTER TABLE pm_activity ADD CONSTRAINT PK_pm_activity PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_pm_activity';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_pm_activity
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_pm_activity_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_pm_activity_t
BEFORE INSERT ON pm_activity
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_pm_activity.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_activity_dialog
-- ----------------------------------------------------------
CREATE TABLE pm_activity_dialog (
    id NUMBER (12, 0) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT pm_activity_dialog_entity_id UNIQUE (entity_id)
);
ALTER TABLE pm_activity_dialog ADD CONSTRAINT PK_pm_activity_dialog PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_pm_activity_dialog';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_pm_activity_dialog
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_pm_activity_dialog_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_pm_activity_dialog_t
BEFORE INSERT ON pm_activity_dialog
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_pm_activity_dialog.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_transition
-- ----------------------------------------------------------
CREATE TABLE pm_transition (
    id NUMBER (12, 0) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT pm_transition_entity_id UNIQUE (entity_id)
);
ALTER TABLE pm_transition ADD CONSTRAINT PK_pm_transition PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_pm_transition';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_pm_transition
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_pm_transition_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_pm_transition_t
BEFORE INSERT ON pm_transition
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_pm_transition.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_transition_action
-- ----------------------------------------------------------
CREATE TABLE pm_transition_action (
    id NUMBER (12, 0) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT pm_transition_action_entity_id UNIQUE (entity_id)
);
ALTER TABLE pm_transition_action ADD CONSTRAINT PK_pm_transition_action PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_pm_transition_action';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_pm_transition_action
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_pm_transition_action_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_pm_transition_action_t
BEFORE INSERT ON pm_transition_action
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_pm_transition_action.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table pm_entity_sync
-- ----------------------------------------------------------
CREATE TABLE pm_entity_sync (
    entity_type VARCHAR2 (30) NOT NULL,
    entity_id VARCHAR2 (50) NOT NULL,
    sync_state VARCHAR2 (30) NOT NULL,
    create_time DATE NOT NULL,
    change_time DATE NOT NULL,
    CONSTRAINT pm_entity_sync_list UNIQUE (entity_type, entity_id)
);
-- ----------------------------------------------------------
--  create table scheduler_task
-- ----------------------------------------------------------
CREATE TABLE scheduler_task (
    id NUMBER (20, 0) NOT NULL,
    ident NUMBER (20, 0) NOT NULL,
    name VARCHAR2 (150) NULL,
    task_type VARCHAR2 (150) NOT NULL,
    task_data CLOB NOT NULL,
    attempts NUMBER (5, 0) NOT NULL,
    lock_key NUMBER (20, 0) NOT NULL,
    lock_time DATE NULL,
    lock_update_time DATE NULL,
    create_time DATE NOT NULL,
    CONSTRAINT scheduler_task_ident UNIQUE (ident)
);
ALTER TABLE scheduler_task ADD CONSTRAINT PK_scheduler_task PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_scheduler_task';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_scheduler_task
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_scheduler_task_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_scheduler_task_t
BEFORE INSERT ON scheduler_task
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_scheduler_task.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_task_ident_id ON scheduler_task (ident, id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_task_lock_key_id ON scheduler_task (lock_key, id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table scheduler_future_task
-- ----------------------------------------------------------
CREATE TABLE scheduler_future_task (
    id NUMBER (20, 0) NOT NULL,
    ident NUMBER (20, 0) NOT NULL,
    execution_time DATE NOT NULL,
    name VARCHAR2 (150) NULL,
    task_type VARCHAR2 (150) NOT NULL,
    task_data CLOB NOT NULL,
    attempts NUMBER (5, 0) NOT NULL,
    lock_key NUMBER (20, 0) NOT NULL,
    lock_time DATE NULL,
    create_time DATE NOT NULL,
    CONSTRAINT scheduler_future_task_ident UNIQUE (ident)
);
ALTER TABLE scheduler_future_task ADD CONSTRAINT PK_scheduler_future_task PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_scheduler_future_task';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_scheduler_future_task
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_scheduler_future_task_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_scheduler_future_task_t
BEFORE INSERT ON scheduler_future_task
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_scheduler_future_task.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_future_task_ident_id ON scheduler_future_task (ident, id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_future_task_lock_kbd ON scheduler_future_task (lock_key, id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table scheduler_recurrent_task
-- ----------------------------------------------------------
CREATE TABLE scheduler_recurrent_task (
    id NUMBER (20, 0) NOT NULL,
    name VARCHAR2 (150) NOT NULL,
    task_type VARCHAR2 (150) NOT NULL,
    last_execution_time DATE NOT NULL,
    last_worker_task_id NUMBER (20, 0) NULL,
    last_worker_status NUMBER (5, 0) NULL,
    last_worker_running_time NUMBER (12, 0) NULL,
    lock_key NUMBER (20, 0) NOT NULL,
    lock_time DATE NULL,
    create_time DATE NOT NULL,
    change_time DATE NOT NULL,
    CONSTRAINT scheduler_recurrent_task_nam4e UNIQUE (name, task_type)
);
ALTER TABLE scheduler_recurrent_task ADD CONSTRAINT PK_scheduler_recurrent_task PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_scheduler_recurrent_task';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_scheduler_recurrent_task
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_scheduler_recurrent_task_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_scheduler_recurrent_task_t
BEFORE INSERT ON scheduler_recurrent_task
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_scheduler_recurrent_task.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_recurrent_task_locb6 ON scheduler_recurrent_task (lock_key, id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scheduler_recurrent_task_tas3a ON scheduler_recurrent_task (task_type, name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table cloud_service_config
-- ----------------------------------------------------------
CREATE TABLE cloud_service_config (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    config CLOB NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT cloud_service_config_name UNIQUE (name)
);
ALTER TABLE cloud_service_config ADD CONSTRAINT PK_cloud_service_config PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_cloud_service_config';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_cloud_service_config
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_cloud_service_config_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_cloud_service_config_t
BEFORE INSERT ON cloud_service_config
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_cloud_service_config.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_default
-- ----------------------------------------------------------
CREATE TABLE sysconfig_default (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (250) NOT NULL,
    description CLOB NOT NULL,
    navigation VARCHAR2 (200) NOT NULL,
    is_invisible NUMBER (5, 0) NOT NULL,
    is_readonly NUMBER (5, 0) NOT NULL,
    is_required NUMBER (5, 0) NOT NULL,
    is_valid NUMBER (5, 0) NOT NULL,
    has_configlevel NUMBER (5, 0) NOT NULL,
    user_modification_possible NUMBER (5, 0) NOT NULL,
    user_modification_active NUMBER (5, 0) NOT NULL,
    user_preferences_group VARCHAR2 (250) NULL,
    xml_content_raw CLOB NOT NULL,
    xml_content_parsed CLOB NOT NULL,
    xml_filename VARCHAR2 (250) NOT NULL,
    effective_value CLOB NOT NULL,
    is_dirty NUMBER (5, 0) NOT NULL,
    exclusive_lock_guid VARCHAR2 (32) NOT NULL,
    exclusive_lock_user_id NUMBER (12, 0) NULL,
    exclusive_lock_expiry_time DATE NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT sysconfig_default_name UNIQUE (name)
);
ALTER TABLE sysconfig_default ADD CONSTRAINT PK_sysconfig_default PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_default';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_default
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_default_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_default_t
BEFORE INSERT ON sysconfig_default
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_default.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_default_version
-- ----------------------------------------------------------
CREATE TABLE sysconfig_default_version (
    id NUMBER (12, 0) NOT NULL,
    sysconfig_default_id NUMBER (12, 0) NULL,
    name VARCHAR2 (250) NOT NULL,
    description CLOB NOT NULL,
    navigation VARCHAR2 (200) NOT NULL,
    is_invisible NUMBER (5, 0) NOT NULL,
    is_readonly NUMBER (5, 0) NOT NULL,
    is_required NUMBER (5, 0) NOT NULL,
    is_valid NUMBER (5, 0) NOT NULL,
    has_configlevel NUMBER (5, 0) NOT NULL,
    user_modification_possible NUMBER (5, 0) NOT NULL,
    user_modification_active NUMBER (5, 0) NOT NULL,
    user_preferences_group VARCHAR2 (250) NULL,
    xml_content_raw CLOB NOT NULL,
    xml_content_parsed CLOB NOT NULL,
    xml_filename VARCHAR2 (250) NOT NULL,
    effective_value CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE sysconfig_default_version ADD CONSTRAINT PK_sysconfig_default_version PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_default_version';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_default_version
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_default_version_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_default_version_t
BEFORE INSERT ON sysconfig_default_version
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_default_version.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX scfv_sysconfig_default_id_name ON sysconfig_default_version (sysconfig_default_id, name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_modified
-- ----------------------------------------------------------
CREATE TABLE sysconfig_modified (
    id NUMBER (12, 0) NOT NULL,
    sysconfig_default_id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (250) NOT NULL,
    user_id NUMBER (12, 0) NULL,
    is_valid NUMBER (5, 0) NOT NULL,
    user_modification_active NUMBER (5, 0) NOT NULL,
    effective_value CLOB NOT NULL,
    is_dirty NUMBER (5, 0) NOT NULL,
    reset_to_default NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT sysconfig_modified_per_user UNIQUE (sysconfig_default_id, user_id)
);
ALTER TABLE sysconfig_modified ADD CONSTRAINT PK_sysconfig_modified PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_modified';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_modified
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_modified_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_modified_t
BEFORE INSERT ON sysconfig_modified
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_modified.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_modified_version
-- ----------------------------------------------------------
CREATE TABLE sysconfig_modified_version (
    id NUMBER (12, 0) NOT NULL,
    sysconfig_default_version_id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (250) NOT NULL,
    user_id NUMBER (12, 0) NULL,
    is_valid NUMBER (5, 0) NOT NULL,
    user_modification_active NUMBER (5, 0) NOT NULL,
    effective_value CLOB NOT NULL,
    reset_to_default NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE sysconfig_modified_version ADD CONSTRAINT PK_sysconfig_modified_version PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_modified_versf7';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_modified_versf7
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_modified_versf7_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_modified_versf7_t
BEFORE INSERT ON sysconfig_modified_version
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_modified_versf7.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_deployment_lock
-- ----------------------------------------------------------
CREATE TABLE sysconfig_deployment_lock (
    id NUMBER (12, 0) NOT NULL,
    exclusive_lock_guid VARCHAR2 (32) NULL,
    exclusive_lock_user_id NUMBER (12, 0) NULL,
    exclusive_lock_expiry_time DATE NULL
);
ALTER TABLE sysconfig_deployment_lock ADD CONSTRAINT PK_sysconfig_deployment_lock PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_deployment_lock';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_deployment_lock
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_deployment_lock_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_deployment_lock_t
BEFORE INSERT ON sysconfig_deployment_lock
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_deployment_lock.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table sysconfig_deployment
-- ----------------------------------------------------------
CREATE TABLE sysconfig_deployment (
    id NUMBER (12, 0) NOT NULL,
    comments VARCHAR2 (250) NULL,
    user_id NUMBER (12, 0) NULL,
    effective_value CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE sysconfig_deployment ADD CONSTRAINT PK_sysconfig_deployment PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_sysconfig_deployment';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_sysconfig_deployment
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_sysconfig_deployment_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_sysconfig_deployment_t
BEFORE INSERT ON sysconfig_deployment
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_sysconfig_deployment.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table calendar
-- ----------------------------------------------------------
CREATE TABLE calendar (
    id NUMBER (20, 0) NOT NULL,
    group_id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (200) NOT NULL,
    salt_string VARCHAR2 (64) NOT NULL,
    color VARCHAR2 (7) NOT NULL,
    ticket_appointments CLOB NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT calendar_name UNIQUE (name)
);
ALTER TABLE calendar ADD CONSTRAINT PK_calendar PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_calendar';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_calendar
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_calendar_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_calendar_t
BEFORE INSERT ON calendar
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_calendar.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table calendar_appointment
-- ----------------------------------------------------------
CREATE TABLE calendar_appointment (
    id NUMBER (20, 0) NOT NULL,
    parent_id NUMBER (20, 0) NULL,
    calendar_id NUMBER (20, 0) NOT NULL,
    unique_id VARCHAR2 (255) NOT NULL,
    title VARCHAR2 (255) NOT NULL,
    description VARCHAR2 (3800) NULL,
    location VARCHAR2 (255) NULL,
    start_time DATE NOT NULL,
    end_time DATE NOT NULL,
    all_day NUMBER (5, 0) NULL,
    notify_time DATE NULL,
    notify_template VARCHAR2 (255) NULL,
    notify_custom VARCHAR2 (255) NULL,
    notify_custom_unit_count NUMBER (20, 0) NULL,
    notify_custom_unit VARCHAR2 (255) NULL,
    notify_custom_unit_point VARCHAR2 (255) NULL,
    notify_custom_date DATE NULL,
    team_id VARCHAR2 (3800) NULL,
    resource_id VARCHAR2 (3800) NULL,
    recurring NUMBER (5, 0) NULL,
    recur_type VARCHAR2 (20) NULL,
    recur_freq VARCHAR2 (255) NULL,
    recur_count NUMBER (12, 0) NULL,
    recur_interval NUMBER (12, 0) NULL,
    recur_until DATE NULL,
    recur_id DATE NULL,
    recur_exclude VARCHAR2 (3800) NULL,
    ticket_appointment_rule_id VARCHAR2 (32) NULL,
    create_time DATE NULL,
    create_by NUMBER (12, 0) NULL,
    change_time DATE NULL,
    change_by NUMBER (12, 0) NULL
);
ALTER TABLE calendar_appointment ADD CONSTRAINT PK_calendar_appointment PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_calendar_appointment';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_calendar_appointment
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_calendar_appointment_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_calendar_appointment_t
BEFORE INSERT ON calendar_appointment
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_calendar_appointment.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table calendar_appointment_plugin
-- ----------------------------------------------------------
CREATE TABLE calendar_appointment_plugin (
    id NUMBER (12, 0) NOT NULL,
    appointment_id NUMBER (5, 0) NOT NULL,
    plugin_key VARCHAR2 (1000) NOT NULL,
    config CLOB NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE calendar_appointment_plugin ADD CONSTRAINT PK_calendar_appointment_plugin PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_calendar_appointment_pl68';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_calendar_appointment_pl68
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_calendar_appointment_pl68_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_calendar_appointment_pl68_t
BEFORE INSERT ON calendar_appointment_plugin
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_calendar_appointment_pl68.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table calendar_appointment_ticket
-- ----------------------------------------------------------
CREATE TABLE calendar_appointment_ticket (
    calendar_id NUMBER (20, 0) NOT NULL,
    ticket_id NUMBER (20, 0) NOT NULL,
    rule_id VARCHAR2 (32) NOT NULL,
    appointment_id NUMBER (20, 0) NOT NULL,
    CONSTRAINT calendar_appointment_ticket_d2 UNIQUE (calendar_id, ticket_id, rule_id)
);
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX calendar_appointment_ticket_8c ON calendar_appointment_ticket (appointment_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX calendar_appointment_ticket_19 ON calendar_appointment_ticket (calendar_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX calendar_appointment_ticket_50 ON calendar_appointment_ticket (rule_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX calendar_appointment_ticket_e9 ON calendar_appointment_ticket (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table ticket_number_counter
-- ----------------------------------------------------------
CREATE TABLE ticket_number_counter (
    id NUMBER (20, 0) NOT NULL,
    counter NUMBER (20, 0) NOT NULL,
    counter_uid VARCHAR2 (32) NOT NULL,
    create_time DATE NULL,
    CONSTRAINT ticket_number_counter_uid UNIQUE (counter_uid)
);
ALTER TABLE ticket_number_counter ADD CONSTRAINT PK_ticket_number_counter PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_ticket_number_counter';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_ticket_number_counter
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_ticket_number_counter_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_ticket_number_counter_t
BEFORE INSERT ON ticket_number_counter
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_ticket_number_counter.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ticket_number_counter_create71 ON ticket_number_counter (create_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table mail_queue
-- ----------------------------------------------------------
CREATE TABLE mail_queue (
    id NUMBER (20, 0) NOT NULL,
    insert_fingerprint VARCHAR2 (64) NULL,
    article_id NUMBER (20, 0) NULL,
    attempts NUMBER (12, 0) NOT NULL,
    sender VARCHAR2 (200) NULL,
    recipient CLOB NOT NULL,
    raw_message CLOB NOT NULL,
    due_time DATE NULL,
    last_smtp_code NUMBER (12, 0) NULL,
    last_smtp_message CLOB NULL,
    create_time DATE NOT NULL,
    CONSTRAINT mail_queue_article_id UNIQUE (article_id),
    CONSTRAINT mail_queue_insert_fingerprint UNIQUE (insert_fingerprint)
);
ALTER TABLE mail_queue ADD CONSTRAINT PK_mail_queue PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_mail_queue';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_mail_queue
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_mail_queue_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_mail_queue_t
BEFORE INSERT ON mail_queue
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_mail_queue.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX mail_queue_attempts ON mail_queue (attempts)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table communication_log
-- ----------------------------------------------------------
CREATE TABLE communication_log (
    id NUMBER (20, 0) NOT NULL,
    insert_fingerprint VARCHAR2 (64) NULL,
    transport VARCHAR2 (200) NOT NULL,
    direction VARCHAR2 (200) NOT NULL,
    status VARCHAR2 (200) NOT NULL,
    account_type VARCHAR2 (200) NULL,
    account_id VARCHAR2 (200) NULL,
    start_time DATE NOT NULL,
    end_time DATE NULL
);
ALTER TABLE communication_log ADD CONSTRAINT PK_communication_log PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_communication_log';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_communication_log
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_communication_log_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_communication_log_t
BEFORE INSERT ON communication_log
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_communication_log.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_direction ON communication_log (direction)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_start_time ON communication_log (start_time)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_status ON communication_log (status)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_transport ON communication_log (transport)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table communication_log_object
-- ----------------------------------------------------------
CREATE TABLE communication_log_object (
    id NUMBER (20, 0) NOT NULL,
    insert_fingerprint VARCHAR2 (64) NULL,
    communication_id NUMBER (20, 0) NOT NULL,
    object_type VARCHAR2 (50) NOT NULL,
    status VARCHAR2 (200) NOT NULL,
    start_time DATE NOT NULL,
    end_time DATE NULL
);
ALTER TABLE communication_log_object ADD CONSTRAINT PK_communication_log_object PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_communication_log_object';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_communication_log_object
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_communication_log_object_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_communication_log_object_t
BEFORE INSERT ON communication_log_object
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_communication_log_object.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_log_object_obje4 ON communication_log_object (object_type)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_log_object_sta5a ON communication_log_object (status)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table communication_log_object_entry
-- ----------------------------------------------------------
CREATE TABLE communication_log_object_entry (
    id NUMBER (20, 0) NOT NULL,
    communication_log_object_id NUMBER (20, 0) NOT NULL,
    log_key VARCHAR2 (200) NOT NULL,
    log_value CLOB NOT NULL,
    priority VARCHAR2 (50) NOT NULL,
    create_time DATE NOT NULL
);
ALTER TABLE communication_log_object_entry ADD CONSTRAINT PK_communication_log_object_a3 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_communication_log_objecd3';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_communication_log_objecd3
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_communication_log_objecd3_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_communication_log_objecd3_t
BEFORE INSERT ON communication_log_object_entry
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_communication_log_objecd3.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_log_object_entec ON communication_log_object_entry (log_key)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table communication_log_obj_lookup
-- ----------------------------------------------------------
CREATE TABLE communication_log_obj_lookup (
    id NUMBER (20, 0) NOT NULL,
    communication_log_object_id NUMBER (20, 0) NOT NULL,
    object_type VARCHAR2 (200) NOT NULL,
    object_id NUMBER (20, 0) NOT NULL
);
ALTER TABLE communication_log_obj_lookup ADD CONSTRAINT PK_communication_log_obj_loo00 PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_communication_log_obj_le6';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_communication_log_obj_le6
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_communication_log_obj_le6_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_communication_log_obj_le6_t
BEFORE INSERT ON communication_log_obj_lookup
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_communication_log_obj_le6.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX communication_log_obj_lookup8d ON communication_log_obj_lookup (object_type, object_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table form_draft
-- ----------------------------------------------------------
CREATE TABLE form_draft (
    id NUMBER (12, 0) NOT NULL,
    object_type VARCHAR2 (100) NOT NULL,
    object_id NUMBER (12, 0) NOT NULL,
    action VARCHAR2 (200) NOT NULL,
    title VARCHAR2 (255) NULL,
    content CLOB NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL
);
ALTER TABLE form_draft ADD CONSTRAINT PK_form_draft PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_form_draft';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_form_draft
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_form_draft_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_form_draft_t
BEFORE INSERT ON form_draft
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_form_draft.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX form_draft_object_type_objecaf ON form_draft (object_type, object_id, action)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table smime_keys
-- ----------------------------------------------------------
CREATE TABLE smime_keys (
    id NUMBER (12, 0) NOT NULL,
    key_hash VARCHAR2 (8) NOT NULL,
    key_type VARCHAR2 (255) NOT NULL,
    file_name VARCHAR2 (255) NOT NULL,
    email_address VARCHAR2 (255) NULL,
    expiration_date DATE NULL,
    fingerprint VARCHAR2 (59) NULL,
    subject VARCHAR2 (255) NULL,
    create_time DATE NULL,
    change_time DATE NULL,
    create_by NUMBER (12, 0) NULL,
    change_by NUMBER (12, 0) NULL
);
ALTER TABLE smime_keys ADD CONSTRAINT PK_smime_keys PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_smime_keys';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_smime_keys
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_smime_keys_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_smime_keys_t
BEFORE INSERT ON smime_keys
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_smime_keys.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX smime_keys_file_name ON smime_keys (file_name)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX smime_keys_key_hash ON smime_keys (key_hash)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX smime_keys_key_type ON smime_keys (key_type)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
-- ----------------------------------------------------------
--  create table oauth2_token_config
-- ----------------------------------------------------------
CREATE TABLE oauth2_token_config (
    id NUMBER (12, 0) NOT NULL,
    name VARCHAR2 (250) NOT NULL,
    config CLOB NOT NULL,
    valid_id NUMBER (5, 0) NOT NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT oauth2_token_config_name UNIQUE (name)
);
ALTER TABLE oauth2_token_config ADD CONSTRAINT PK_oauth2_token_config PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_oauth2_token_config';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_oauth2_token_config
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_oauth2_token_config_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_oauth2_token_config_t
BEFORE INSERT ON oauth2_token_config
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_oauth2_token_config.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table oauth2_token
-- ----------------------------------------------------------
CREATE TABLE oauth2_token (
    id NUMBER (12, 0) NOT NULL,
    token_config_id NUMBER (12, 0) NOT NULL,
    authorization_code VARCHAR2 (2000) NULL,
    token VARCHAR2 (2000) NULL,
    token_expiration_date DATE NULL,
    refresh_token VARCHAR2 (2000) NULL,
    refresh_token_expiration_date DATE NULL,
    error_message VARCHAR2 (2000) NULL,
    error_description VARCHAR2 (2000) NULL,
    error_code VARCHAR2 (250) NULL,
    create_time DATE NOT NULL,
    create_by NUMBER (12, 0) NOT NULL,
    change_time DATE NOT NULL,
    change_by NUMBER (12, 0) NOT NULL,
    CONSTRAINT oauth2_token_config_id UNIQUE (token_config_id)
);
ALTER TABLE oauth2_token ADD CONSTRAINT PK_oauth2_token PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_oauth2_token';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_oauth2_token
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_oauth2_token_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_oauth2_token_t
BEFORE INSERT ON oauth2_token
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_oauth2_token.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
-- ----------------------------------------------------------
--  create table mention
-- ----------------------------------------------------------
CREATE TABLE mention (
    id NUMBER (12, 0) NOT NULL,
    user_id NUMBER (12, 0) NULL,
    ticket_id NUMBER (12, 0) NULL,
    article_id NUMBER (12, 0) NULL,
    create_time DATE NULL
);
ALTER TABLE mention ADD CONSTRAINT PK_mention PRIMARY KEY (id);
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SE_mention';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE SEQUENCE SE_mention
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE
CACHE 20
ORDER
;
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER SE_mention_t';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
--
;
CREATE OR REPLACE TRIGGER SE_mention_t
BEFORE INSERT ON mention
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        SELECT SE_mention.nextval
        INTO :new.id
        FROM DUAL;
    END IF;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX mention_article_id ON mention (article_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX mention_ticket_id ON mention (ticket_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX mention_user_id ON mention (user_id)';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
--
;
