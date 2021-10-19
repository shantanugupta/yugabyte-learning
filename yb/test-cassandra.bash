ycqlsh 10.0.0.66

CREATE KEYSPACE IF NOT EXISTS app;

USE app;

DROP TABLE IF EXISTS user_actions;

CREATE TABLE user_actions (userid int, action_id int, payload text,
        PRIMARY KEY ((userid), action_id))
        WITH CLUSTERING ORDER BY (action_id DESC);

INSERT INTO user_actions (userid, action_id, payload) VALUES (1, 1, 'a');
INSERT INTO user_actions (userid, action_id, payload) VALUES (1, 2, 'b');
INSERT INTO user_actions (userid, action_id, payload) VALUES (1, 3, 'c');
INSERT INTO user_actions (userid, action_id, payload) VALUES (1, 4, 'd');
INSERT INTO user_actions (userid, action_id, payload) VALUES (2, 1, 'l');
INSERT INTO user_actions (userid, action_id, payload) VALUES (2, 2, 'm');
INSERT INTO user_actions (userid, action_id, payload) VALUES (2, 3, 'n');
INSERT INTO user_actions (userid, action_id, payload) VALUES (2, 4, 'o');
INSERT INTO user_actions (userid, action_id, payload) VALUES (2, 5, 'p');

SELECT * FROM user_actions WHERE userid=1 AND action_id > 2;
