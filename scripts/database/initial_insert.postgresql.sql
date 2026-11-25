-- ----------------------------------------------------------
--  driver: postgresql
-- ----------------------------------------------------------
SET standard_conforming_strings TO ON;
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('valid', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('invalid', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table valid
-- ----------------------------------------------------------
INSERT INTO valid (name, create_by, create_time, change_by, change_time)
    VALUES
    ('invalid-temporarily', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table users
-- ----------------------------------------------------------
INSERT INTO users (first_name, last_name, login, pw, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Admin', 'Znuny', 'root@localhost', 'roK20XGbWEsSM', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table permission_groups
-- ----------------------------------------------------------
INSERT INTO permission_groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('users', 'Group for default access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table permission_groups
-- ----------------------------------------------------------
INSERT INTO permission_groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('admin', 'Group of all administrators.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table permission_groups
-- ----------------------------------------------------------
INSERT INTO permission_groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('stats', 'Group for statistics access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table permission_groups
-- ----------------------------------------------------------
INSERT INTO permission_groups (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('timeaccounting_webservice', 'Group for time accounting web service access.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 2, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table group_user
-- ----------------------------------------------------------
INSERT INTO group_user (user_id, group_id, permission_key, create_by, create_time, change_by, change_time)
    VALUES
    (1, 3, 'rw', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_type
-- ----------------------------------------------------------
INSERT INTO link_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Normal', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_type
-- ----------------------------------------------------------
INSERT INTO link_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ParentChild', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_state
-- ----------------------------------------------------------
INSERT INTO link_state (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Valid', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table link_state
-- ----------------------------------------------------------
INSERT INTO link_state (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Temporary', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('new', 'All new state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('open', 'All open state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('closed', 'All closed state types (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('pending reminder', 'All ''pending reminder'' state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto', 'All ''pending auto *'' state types (default: viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('removed', 'All ''removed'' state types (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state_type
-- ----------------------------------------------------------
INSERT INTO ticket_state_type (name, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('merged', 'State type for merged tickets (default: not viewable).', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('new', 'New ticket created by customer.', 1, 1, '#50B5FFFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('closed successful', 'Ticket is closed successful.', 3, 1, '#3DD598FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('closed unsuccessful', 'Ticket is closed unsuccessful.', 3, 1, '#FC5A5AFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('open', 'Open tickets.', 2, 1, '#FFC542FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('removed', 'Customer removed ticket.', 6, 1, '#8D8D9BFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('pending reminder', 'Ticket is pending for agent reminder.', 4, 1, '#FF8A25FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto close+', 'Ticket is pending for automatic close.', 5, 1, '#FF8A25FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('pending auto close-', 'Ticket is pending for automatic close.', 5, 1, '#FF8A25FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_state
-- ----------------------------------------------------------
INSERT INTO ticket_state (name, comments, type_id, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('merged', 'State for merged tickets.', 7, 1, '#FF8A25FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table salutation
-- ----------------------------------------------------------
INSERT INTO salutation (name, text, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system standard salutation (en)', 'Dear <ZNUNY_CUSTOMER_REALNAME>,

Thank you for your request.

', 'text/plain; charset=utf-8', 'Standard Salutation.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table signature
-- ----------------------------------------------------------
INSERT INTO signature (name, text, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system standard signature (en)', '
Your Ticket-Team

 <ZNUNY_Agent_UserFirstname> <ZNUNY_Agent_UserLastname>

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--', 'text/plain; charset=utf-8', 'Standard Signature.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table system_address
-- ----------------------------------------------------------
INSERT INTO system_address (value0, value1, comments, valid_id, queue_id, create_by, create_time, change_by, change_time)
    VALUES
    ('znuny@localhost', 'Znuny System', 'Standard Address.', 1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('possible', 'Follow-ups for closed tickets are possible. Ticket will be reopened.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('reject', 'Follow-ups for closed tickets are not possible. No new ticket will be created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table follow_up_possible
-- ----------------------------------------------------------
INSERT INTO follow_up_possible (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('new ticket', 'Follow-ups for closed tickets are not possible. A new ticket will be created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Postmaster', 1, 1, 1, 1, 1, 0, 0, 'Postmaster queue.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Raw', 1, 1, 1, 1, 1, 0, 0, 'All default incoming tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Junk', 1, 1, 1, 1, 1, 0, 0, 'All junk tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue
-- ----------------------------------------------------------
INSERT INTO queue (name, group_id, system_address_id, salutation_id, signature_id, follow_up_id, follow_up_lock, unlock_timeout, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Misc', 1, 1, 1, 1, 1, 0, 0, 'All misc tickets.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table standard_template
-- ----------------------------------------------------------
INSERT INTO standard_template (name, text, content_type, template_type, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('empty answer', '', 'text/plain; charset=utf-8', 'Answer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table standard_template
-- ----------------------------------------------------------
INSERT INTO standard_template (name, text, content_type, template_type, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('test answer', 'Some test answer to show how a standard template can be used.', 'text/plain; charset=utf-8', 'Answer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (2, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table queue_standard_template
-- ----------------------------------------------------------
INSERT INTO queue_standard_template (queue_id, standard_template_id, create_by, create_time, change_by, change_time)
    VALUES
    (4, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reply', 'Automatic reply which will be sent out after a new ticket has been created.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reject', 'Automatic reject which will be sent out after a follow-up has been rejected (in case queue follow-up option is "reject").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto follow up', 'Automatic confirmation which is sent out after a follow-up has been received for a ticket (in case queue follow-up option is "possible").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto reply/new ticket', 'Automatic response which will be sent out after a follow-up has been rejected and a new ticket has been created (in case queue follow-up option is "new ticket").', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response_type
-- ----------------------------------------------------------
INSERT INTO auto_response_type (name, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('auto remove', 'Auto remove will be sent out after a customer removed the request.', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 'default reply (after new ticket has been created)', 'This is a demo text which is send to every inquiry.
It could contain something like:

Thanks for your email. A new ticket has been created.

You wrote:
<ZNUNY_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP

Have fun with Znuny! :-)

Your Znuny Team
', 'RE: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (2, 1, 'default reject (after follow-up and rejected of a closed ticket)', 'Your previous ticket is closed.

-- Your follow-up has been rejected. --

Please create a new ticket.

Your Znuny Team
', 'Your email has been rejected! (RE: <ZNUNY_CUSTOMER_SUBJECT[24]>)', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (3, 1, 'default follow-up (after a ticket follow-up has been added)', 'Thanks for your follow-up email

You wrote:
<ZNUNY_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP.

Have fun with Znuny!

Your Znuny Team
', 'RE: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table auto_response
-- ----------------------------------------------------------
INSERT INTO auto_response (type_id, system_address_id, name, text0, text1, content_type, comments, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (4, 1, 'default reject/new ticket created (after closed follow-up with new ticket creation)', 'Your previous ticket is closed.

-- A new ticket has been created for you. --

You wrote:
<ZNUNY_CUSTOMER_EMAIL[6]>

Your email will be answered by a human ASAP.

Have fun with Znuny!

Your Znuny Team
', 'New ticket has been created! (RE: <ZNUNY_CUSTOMER_SUBJECT[24]>)', 'text/plain', '', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_type
-- ----------------------------------------------------------
INSERT INTO ticket_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unclassified', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('1 very low', 1, '#03c4f0ff', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('2 low', 1, '#83bfc8ff', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('3 normal', 1, '#cdcdcdff', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('4 high', 1, '#ffaaaaff', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_priority
-- ----------------------------------------------------------
INSERT INTO ticket_priority (name, valid_id, color, create_by, create_time, change_by, change_time)
    VALUES
    ('5 very high', 1, '#ff505eff', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('unlock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_lock_type
-- ----------------------------------------------------------
INSERT INTO ticket_lock_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('tmp_lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('NewTicket', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('FollowUp', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoReject', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoReply', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAutoFollowUp', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Forward', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Bounce', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAnswer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendAgentNotification', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SendCustomerNotification', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailAgent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PhoneCallAgent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PhoneCallCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('AddNote', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Move', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Lock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unlock', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Remove', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TimeAccounting', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('CustomerUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('PriorityUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('OwnerUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('LoopProtection', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Misc', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SetPendingTime', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('StateUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketDynamicFieldUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('WebRequestCustomer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketLinkAdd', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TicketLinkDelete', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SystemRequest', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Merged', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ResponsibleUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Subscribe', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Unsubscribe', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TypeUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ServiceUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('SLAUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('ArchiveFlagUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeStart', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationSolutionTimeNotifyBefore', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationResponseTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EscalationUpdateTimeStop', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('TitleUpdate', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('EmailResend', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history_type
-- ----------------------------------------------------------
INSERT INTO ticket_history_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Bulk', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('agent', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('system', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_sender_type
-- ----------------------------------------------------------
INSERT INTO article_sender_type (name, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('customer', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Chat::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Chat::VisibleForCustomer', '#D1E8D1FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Email::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Email::VisibleForCustomer', '#D1E8D1FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Internal::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Internal::VisibleForCustomer', '#CCCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Phone::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Phone::VisibleForCustomer', '#D1E8D1FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Web::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('agent::Web::VisibleForCustomer', '#D1E8D1FF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Chat::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Chat::VisibleForCustomer', '#FFF7BEFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Email::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Email::VisibleForCustomer', '#FFF7BEFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Internal::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Internal::VisibleForCustomer', '#FFF7BEFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Phone::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Phone::VisibleForCustomer', '#FFF7BEFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Web::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('system::Web::VisibleForCustomer', '#FFF7BEFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Chat::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Chat::VisibleForCustomer', '#D4DEFCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Email::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Email::VisibleForCustomer', '#D4DEFCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Internal::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Internal::VisibleForCustomer', '#D4DEFCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Phone::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Phone::VisibleForCustomer', '#D4DEFCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Web::NotVisibleForCustomer', '#FFCCCCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_color
-- ----------------------------------------------------------
INSERT INTO article_color (name, color, create_by, create_time, change_by, change_time)
    VALUES
    ('customer::Web::VisibleForCustomer', '#D4DEFCFF', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket
-- ----------------------------------------------------------
INSERT INTO ticket (tn, queue_id, ticket_lock_id, user_id, responsible_user_id, ticket_priority_id, ticket_state_id, title, timeout, until_time, escalation_time, escalation_response_time, escalation_update_time, escalation_solution_time, create_by, create_time, change_by, change_time)
    VALUES
    ('2021012710123456', 2, 1, 1, 1, 3, 1, 'Znuny says hi!', 0, 0, 0, 0, 0, 0, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Email', 'Kernel::System::CommunicationChannel::Email', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Phone', 'Kernel::System::CommunicationChannel::Phone', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Internal', 'Kernel::System::CommunicationChannel::Internal', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Chat', 'Kernel::System::CommunicationChannel::Chat', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_otrs_chat
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table communication_channel
-- ----------------------------------------------------------
INSERT INTO communication_channel (name, module, package_name, channel_data, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    ('Web', 'Kernel::System::CommunicationChannel::Web', 'Framework', '---
ArticleDataArticleIDField: article_id
ArticleDataTables:
- article_data_mime
- article_data_mime_plain
- article_data_mime_attachment
- article_data_mime_send_error
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article
-- ----------------------------------------------------------
INSERT INTO article (ticket_id, communication_channel_id, article_sender_type_id, is_visible_for_customer, create_by, create_time, change_by, change_time)
    VALUES
    (1, 1, 3, 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_data_mime
-- ----------------------------------------------------------
INSERT INTO article_data_mime (article_id, a_from, a_to, a_subject, a_body, a_message_id, incoming_time, content_path, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'Znuny <hello@znuny.org>', 'Your Znuny service desk <znuny@localhost>', 'Znuny says hi!', 'We welcome you to Znuny, our ticketing solution based on the well-known OTRS ((Community Edition)) which we forked to make things different.

We are focused on delivering a stable and community influenced software. So if you have something to contribute, whether bug reports, solutions or enhancements, let us know. We will be happy about your participation.

You can get additional information here:

Community forum: https://community.znuny.org/

Documentation: https://doc.znuny.org/

GitHub: https://github.com/znuny/Znuny

Have fun and enjoy it.

Your Znuny Team
', '<007@localhost>', 1611745200, '2021/01/27', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table article_data_mime_plain
-- ----------------------------------------------------------
INSERT INTO article_data_mime_plain (article_id, body, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'From: Znuny <hello@znuny.org>
To: Your Znuny service desk <znuny@localhost>
Subject: Znuny says hi!
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

We welcome you to Znuny, our ticketing solution based on the well-known OTRS ((Community Edition)) which we forked to make things different.

We are focused on delivering a stable and community influenced software. So if you have something to contribute, whether bug reports, solutions or enhancements, let us know. We will be happy about your participation.

You can get additional information here:

Community forum: https://community.znuny.org/

Documentation: https://doc.znuny.org/

GitHub: https://github.com/znuny/Znuny

Have fun and enjoy it.

Your Znuny Team
', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table ticket_history
-- ----------------------------------------------------------
INSERT INTO ticket_history (name, history_type_id, ticket_id, type_id, article_id, priority_id, owner_id, state_id, queue_id, create_by, create_time, change_by, change_time)
    VALUES
    ('New Ticket [2021012710123456] created.', 1, 1, 1, 1, 3, 1, 1, 2, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket create notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'VisibleForAgentTooltip', 'You will receive a notification each time a new ticket is created in one of your "My Queues" or "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Events', 'NotificationNewTicket');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (1, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket follow-up notification (unlocked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'VisibleForAgentTooltip', 'You will receive a notification if a customer sends a follow-up to an unlocked ticket which is in your "My Queues" or "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Events', 'NotificationFollowUp');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'LockID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (2, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket follow-up notification (locked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'VisibleForAgentTooltip', 'You will receive a notification if a customer sends a follow-up to a locked ticket of which you are the ticket owner or responsible.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Events', 'NotificationFollowUp');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'LockID', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'LockID', '3');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (3, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket lock timeout notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'VisibleForAgentTooltip', 'You will receive a notification as soon as a ticket owned by you is automatically unlocked.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Events', 'NotificationLockTimeout');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (4, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket owner update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Events', 'NotificationOwnerUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (5, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket responsible update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Events', 'NotificationResponsibleUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (6, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket new note notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Events', 'NotificationAddNote');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Recipients', 'AgentWatcher');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (7, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket queue update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'VisibleForAgentTooltip', 'You will receive a notification if a ticket is moved into one of your "My Queues".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Events', 'NotificationMove');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (8, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket pending reminder notification (locked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Events', 'NotificationPendingReminder');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'LockID', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'LockID', '3');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (9, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket pending reminder notification (unlocked)', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Events', 'NotificationPendingReminder');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'LockID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (10, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket escalation notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Events', 'NotificationEscalation');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Recipients', 'AgentWritePermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (11, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket escalation warning notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Events', 'NotificationEscalationNotifyBefore');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Recipients', 'AgentMyQueues');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Recipients', 'AgentWritePermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'OncePerDay', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (12, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket service update notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'VisibleForAgentTooltip', 'You will receive a notification if a ticket''s service is changed to one of your "My Services".');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Events', 'NotificationServiceUpdate');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Recipients', 'AgentMyServices');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (13, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Appointment reminder notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'VisibleForAgentTooltip', 'You will receive a notification each time a reminder time is reached for one of your appointments.');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Events', 'AppointmentNotification');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Recipients', 'AppointmentAgentReadPermissions');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'SendOnOutOfOffice', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (14, 'NotificationType', 'Appointment');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Ticket email delivery failure notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'ArticleAttachmentInclude', '0');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'ArticleCommunicationChannelID', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Events', 'ArticleEmailSendingError');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'LanguageID', 'en');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'RecipientGroups', '2');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Recipients', 'AgentResponsible');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Recipients', 'AgentOwner');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (15, 'VisibleForAgent', '0');
-- ----------------------------------------------------------
--  insert into table notification_event
-- ----------------------------------------------------------
INSERT INTO notification_event (name, valid_id, comments, create_by, create_time, change_by, change_time)
    VALUES
    ('Mention notification', 1, '', 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'AgentEnabledByDefault', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'ArticleAttachmentInclude', '0');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'Events', 'UserMention');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'LanguageID', 'en');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'Transports', 'Email');
-- ----------------------------------------------------------
--  insert into table notification_event_item
-- ----------------------------------------------------------
INSERT INTO notification_event_item (notification_id, event_key, event_value)
    VALUES
    (16, 'VisibleForAgent', '1');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'en', 'Ticket Created: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been created in queue <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> wrote:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'en', 'Unlocked Ticket Follow-Up: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the unlocked ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] received a follow-up.

<ZNUNY_CUSTOMER_REALNAME> wrote:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'en', 'Locked Ticket Follow-Up: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the locked ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] received a follow-up.

<ZNUNY_CUSTOMER_REALNAME> wrote:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'en', 'Ticket Lock Timeout: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has reached its lock timeout period and is now unlocked.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'en', 'Ticket Owner Update to <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the owner of ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been updated to <ZNUNY_TICKET_OWNER_UserFullname> by <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'en', 'Ticket Responsible Update to <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the responsible agent of ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been updated to <ZNUNY_TICKET_RESPONSIBLE_UserFullname> by <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'en', 'Ticket Note: <ZNUNY_AGENT_SUBJECT[24]>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> wrote:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'en', 'Ticket Queue Update to <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been updated to queue <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'en', 'Locked Ticket Pending Reminder Time Reached: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the pending reminder time of the locked ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been reached.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'en', 'Unlocked Ticket Pending Reminder Time Reached: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the pending reminder time of the unlocked ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been reached.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'en', 'Ticket Escalation! <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] is escalated!

Escalated at: <ZNUNY_TICKET_EscalationDestinationDate>
Escalated since: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'en', 'Ticket Escalation Warning! <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] will escalate!

Escalation at: <ZNUNY_TICKET_EscalationDestinationDate>
Escalation in: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'en', 'Ticket Service Update to <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

the service of ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has been updated to <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'en', 'Reminder: <ZNUNY_APPOINTMENT_TITLE>', '<p>Hi &lt;ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname&gt;,</p>
<p></p>
<p>appointment &quot;&lt;ZNUNY_APPOINTMENT_TITLE&gt;&quot; has reached its notification time.</p>
<p></p>
<p>Description: &lt;ZNUNY_APPOINTMENT_DESCRIPTION&gt;</p>
<p>Location: &lt;ZNUNY_APPOINTMENT_LOCATION&gt;</p>
<p>Calendar: <span style="color: &lt;ZNUNY_CALENDAR_COLOR&gt;;">■</span> &lt;ZNUNY_CALENDAR_CALENDARNAME&gt;</p>
<p>Start date: &lt;ZNUNY_APPOINTMENT_STARTTIME&gt;</p>
<p>End date: &lt;ZNUNY_APPOINTMENT_ENDTIME&gt;</p>
<p>All-day: &lt;ZNUNY_APPOINTMENT_ALLDAY&gt;</p>
<p>Repeat: &lt;ZNUNY_APPOINTMENT_RECURRING&gt;</p>
<p></p>
<p><a href="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;" title="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;">&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;</a></p>
<p></p>
<p>-- &lt;ZNUNY_CONFIG_NotificationSenderName&gt;</p>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (15, 'text/plain', 'en', 'Email Delivery Failure', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

Please note, that the delivery of an email article of [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] has failed. Please check the email address of your recipient for mistakes and try again. You can manually resend the article from the ticket if required.

Error Message:
<ZNUNY_AGENT_TransmissionStatusMessage>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>;ArticleID=<ZNUNY_TICKET_LAST_ARTICLE_ID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (16, 'text/plain', 'en', 'Mention in ticket: <ZNUNY_TICKET_Title>', 'Hi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

you have been mentioned in ticket <ZNUNY_TICKET_NUMBER>.
<ZNUNY_AGENT_BODY[5]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'de', 'Ticket erstellt: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde in der Queue <ZNUNY_TICKET_Queue> erstellt.

<ZNUNY_CUSTOMER_REALNAME> schrieb:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'de', 'Nachfrage zum freigegebenen Ticket: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

zum freigegebenen Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] gibt es eine Nachfrage.

<ZNUNY_CUSTOMER_REALNAME> schrieb:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'de', 'Nachfrage zum gesperrten Ticket: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

zum gesperrten Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] gibt es eine Nachfrage.

<ZNUNY_CUSTOMER_REALNAME> schrieb:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'de', 'Ticketsperre aufgehoben: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

die Sperrzeit des Tickets [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] ist abgelaufen. Es ist jetzt freigegeben.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'de', 'Änderung des Ticket-Besitzers auf <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

der Besitzer des Tickets [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde von <ZNUNY_CURRENT_UserFullname> geändert auf <ZNUNY_TICKET_OWNER_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'de', 'Änderung des Ticket-Verantwortlichen auf <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

der Verantwortliche für das Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde von <ZNUNY_CURRENT_UserFullname> geändert auf <ZNUNY_TICKET_RESPONSIBLE_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'de', 'Ticket-Notiz: <ZNUNY_AGENT_SUBJECT[24]>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

<ZNUNY_CURRENT_UserFullname> schrieb:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'de', 'Ticket-Queue geändert zu <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde in die Queue <ZNUNY_TICKET_Queue> verschoben.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'de', 'Erinnerungszeit des gesperrten Tickets erreicht: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

die Erinnerungszeit für das gesperrte Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde erreicht.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'de', 'Erinnerungszeit des freigegebenen Tickets erreicht: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

die Erinnerungszeit für das freigegebene Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde erreicht.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'de', 'Ticket-Eskalation! <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] ist eskaliert!

Eskaliert am: <ZNUNY_TICKET_EscalationDestinationDate>
Eskaliert seit: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'de', 'Ticket-Eskalations-Warnung! <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

das Ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wird bald eskalieren!

Eskalation um: <ZNUNY_TICKET_EscalationDestinationDate>
Eskalation in: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'de', 'Ticket-Service aktualisiert zu <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

der Service des Tickets [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] wurde geändert zu <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'de', 'Erinnerung: <ZNUNY_APPOINTMENT_TITLE>', '<p>Hallo &lt;ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname&gt;,</p>
<p></p>
<p>Termin &quot;&lt;ZNUNY_APPOINTMENT_TITLE&gt;&quot; hat seine Benachrichtigungszeit erreicht.</p>
<p></p>
<p>Beschreibung: &lt;ZNUNY_APPOINTMENT_DESCRIPTION&gt;</p>
<p>Standort: &lt;ZNUNY_APPOINTMENT_LOCATION&gt;</p>
<p>Kalender: <span style="color: &lt;ZNUNY_CALENDAR_COLOR&gt;;">■</span> &lt;ZNUNY_CALENDAR_CALENDARNAME&gt;</p>
<p>Startzeitpunkt: &lt;ZNUNY_APPOINTMENT_STARTTIME&gt;</p>
<p>Endzeitpunkt: &lt;ZNUNY_APPOINTMENT_ENDTIME&gt;</p>
<p>Ganztägig: &lt;ZNUNY_APPOINTMENT_ALLDAY&gt;</p>
<p>Wiederholung: &lt;ZNUNY_APPOINTMENT_RECURRING&gt;</p>
<p></p>
<p><a href="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;" title="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;">&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;</a></p>
<p></p>
<p>-- &lt;ZNUNY_CONFIG_NotificationSenderName&gt;<p>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (15, 'text/plain', 'de', 'Fehler beim Versand einer E-Mail', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

bitte beachten Sie, dass der Versand eines E-Mail-Artikels für [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] fehlgeschlagen ist. Bitte überprüfen Sie die E-Mail-Adresse des Empfängers auf Fehler und versuchen Sie es erneut. Sie können den Artikel bei Bedarf manuell aus dem Ticket erneut senden.

Fehlermeldung:
<ZNUNY_AGENT_TransmissionStatusMessage>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>;ArticleID=<ZNUNY_TICKET_LAST_ARTICLE_ID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (16, 'text/plain', 'de', 'Erwähnung in Ticket: <ZNUNY_TICKET_Title>', 'Hallo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname> <ZNUNY_NOTIFICATION_RECIPIENT_UserLastname>,

Sie wurden erwähnt in Ticket <ZNUNY_TICKET_NUMBER>.
<ZNUNY_AGENT_BODY[5]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'es_MX', 'Se ha creado un ticket: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha creado en la fila <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> escribió:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'es_MX', 'Seguimiento a ticket desbloqueado: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket desbloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] recibió un seguimiento.

<ZNUNY_CUSTOMER_REALNAME> escribió:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'es_MX', 'Seguimiento a ticket bloqueado: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket bloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] recibió un seguimiento.

<ZNUNY_CUSTOMER_REALNAME> escribió:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'es_MX', 'Terminó tiempo de bloqueo: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>]  ha alcanzado su tiempo de espera como bloqueado y ahora se encuentra desbloqueado.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'es_MX', 'Actualización del propietario de ticket a <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el propietario del ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha modificado  a <ZNUNY_TICKET_OWNER_UserFullname> por <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'es_MX', 'Actualización del responsable de ticket a <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el agente responsable del ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha modificado a <ZNUNY_TICKET_RESPONSIBLE_UserFullname> por <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'es_MX', 'Nota de ticket: <ZNUNY_AGENT_SUBJECT[24]>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> escribió:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'es_MX', 'La fila del ticket ha cambiado a <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] ha cambiado de fila a <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'es_MX', 'Recordatorio pendiente en ticket bloqueado se ha alcanzado: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el tiempo del recordatorio pendiente para el ticket bloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha alcanzado.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'es_MX', 'Recordatorio pendiente en ticket desbloqueado se ha alcanzado: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el tiempo del recordatorio pendiente para el ticket desbloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha alcanzado.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'es_MX', '¡Escalación de ticket! <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha escalado!

Escaló: <ZNUNY_TICKET_EscalationDestinationDate>
Escalado desde: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'es_MX', 'Aviso de escalación de ticket! <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se encuentra proximo a escalar!

Escalará: <ZNUNY_TICKET_EscalationDestinationDate>
Escalará en: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'es_MX', 'El servicio del ticket ha cambiado a <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Hola <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

el servicio del ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] se ha cambiado a <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'zh_CN', '票据编制 工单已创建：<ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已在等待队列 已在队列<ZNUNY_TICKET_Queue> 中被编制完成。中被创建完成

<ZNUNY_CUSTOMER_REALNAME> 写道：
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'zh_CN', '解锁票据的后续作业解锁工单的后续： <ZNUNY_CUSTOMER_SUBJECT[24]>', '您好<ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

解锁票据解锁工单[<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已获得一项后续作业。

<ZNUNY_CUSTOMER_REALNAME> 写道:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'zh_CN', '加锁票据的后续作业 锁定工单后续：<ZNUNY_CUSTOMER_SUBJECT[24]>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

加锁票据锁定工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已获得一项后续作业。

<ZNUNY_CUSTOMER_REALNAME> 写道：
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'zh_CN', '票据加锁超时工单锁定超时：<ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已达到其锁定时限，现在解锁。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'zh_CN', '票据的拥有人升级为工单所有者更新为 <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据的所有人工单的所有者 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已被该信为 <ZNUNY_TICKET_OWNER_UserFullname> 的 <ZNUNY_CURRENT_UserFullname>。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'zh_CN', '票据的负责人 工单负责人更新为<ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

工单的负责人 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已被升级为 已被更新为 <ZNUNY_TICKET_RESPONSIBLE_UserFullname> 的 <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'zh_CN', '票据备注工单备注：<ZNUNY_AGENT_SUBJECT[24]>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> 写道：
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'zh_CN', '票据序列已升级为工单队列更新为<ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已被升级为序列已被更新为队列 <ZNUNY_TICKET_Queue>。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'zh_CN', '已达到锁定票据即将到期的提醒时间已到达锁定工单挂起提醒时间：<ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

锁定票据即将到期的提醒时间锁定工单挂起提醒时间 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已到达。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'zh_CN', '未锁定票据即将到期的提醒时间已到已到未锁定工单的挂起提醒时间：<ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

未锁定票据即将到期的提醒时间未锁定工单的挂起提醒时间 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已到已到达。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'zh_CN', '票据升级！工单升级！<ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已被升级！

升级地点升级开始时间：<ZNUNY_TICKET_EscalationDestinationDate>
升级开始时间升级在：<ZNUNY_TICKET_EscalationDestinationIn>内

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'zh_CN', '工单升级警告Ticket Escalation Warning! <ZNUNY_TICKET_Title>', '您好  <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据工单 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 将升级！

升级地点升级开始时间：<ZNUNY_TICKET_EscalationDestinationDate>
升级开始时间升级在：<ZNUNY_TICKET_EscalationDestinationIn>内

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'zh_CN', '票据服务升级为工单服务更新为<ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', '您好 <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

票据服务工单服务 [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] 已被升级为已被更新为 <ZNUNY_TICKET_Service>。

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'pt_BR', 'Ticket criado: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi criado na fila <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> escreveu:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'pt_BR', 'Acompanhamento do ticket desbloqueado: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket desbloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] recebeu uma resposta.

<ZNUNY_CUSTOMER_REALNAME> escreveu:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'pt_BR', 'Acompanhamento do ticket bloqueado: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket bloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] recebeu uma resposta.

<ZNUNY_CUSTOMER_REALNAME> escreveu:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'pt_BR', 'Tempo limite de bloqueio do ticket: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] atingiu o seu período de tempo limite de bloqueio e agora está desbloqueado.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'pt_BR', 'Atualização de proprietário de ticket para <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o proprietário do ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atualizado para <ZNUNY_TICKET_OWNER_UserFullname> por <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'pt_BR', 'Atualização de responsável de ticket para <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o agente responsável do ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atualizado para <ZNUNY_TICKET_RESPONSIBLE_UserFullname> por <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'pt_BR', 'Observação sobre o ticket: <ZNUNY_AGENT_SUBJECT[24]>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> escreveu:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'pt_BR', 'Atualização da fila do ticket para <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atualizado na fila <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'pt_BR', 'Tempo de Lembrete de Pendência do Ticket Bloqueado Atingido: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o tempo de lembrete pendente do ticket bloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atingido.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'pt_BR', 'Tempo de Lembrete Pendente do Ticket Desbloqueado Atingido: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o tempo de lembrete pendente do ticket desbloqueado [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atingido.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'pt_BR', 'Escalonamento do ticket! <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi escalonado!

Escalonado em: <ZNUNY_TICKET_EscalationDestinationDate>
Escalonado desde: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'pt_BR', 'Aviso de escalonamento do ticket! <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] será escalonado!

Escalonamento em: <ZNUNY_TICKET_EscalationDestinationDate>
Escalonamento em: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'pt_BR', 'Atualização do serviço do ticket para <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Oi <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

o serviço do ticket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] foi atualizado para <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'hu', 'Jegy létrehozva: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy létrejött a következő várólistában: <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> ezt írta:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'hu', 'Feloldott jegy követése: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A feloldott [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy egy követő üzenetet kapott.

<ZNUNY_CUSTOMER_REALNAME> ezt írta:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'hu', 'Zárolt jegy követése: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A zárolt [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy egy követő üzenetet kapott.

<ZNUNY_CUSTOMER_REALNAME> ezt írta:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'hu', 'Jegyzár időkorlát: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy elérte a zárolás időkorlátjának időtartamát, és most feloldásra került.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'hu', 'Jegytulajdonos frissítés <ZNUNY_OWNER_UserLastname> <ZNUNY_OWNER_UserFirstname> ügyintézőre: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy tulajdonosát <ZNUNY_CURRENT_UserLastname> <ZNUNY_CURRENT_UserFirstname> frissítette <ZNUNY_OWNER_UserLastname> <ZNUNY_OWNER_UserFirstname> ügyintézőre.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'hu', 'Jegyfelelős frissítés <ZNUNY_RESPONSIBLE_UserLastname> <ZNUNY_RESPONSIBLE_UserFirstname> ügyintézőre: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy felelős ügyintézőjét <ZNUNY_CURRENT_UserLastname> <ZNUNY_CURRENT_UserFirstname> frissítette <ZNUNY_RESPONSIBLE_UserLastname> <ZNUNY_RESPONSIBLE_UserFirstname> ügyintézőre.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'hu', 'Új jegyzet: <ZNUNY_AGENT_SUBJECT[24]>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

<ZNUNY_CURRENT_UserLastname> <ZNUNY_CURRENT_UserFirstname> ezt írta:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'hu', 'Jegy várólista frissítés <ZNUNY_TICKET_Queue> várólistára: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegyet áthelyezték a következő várólistába: <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'hu', 'Zárolt jegy „emlékeztető függőben” ideje elérve: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A zárolt [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy elérte az „emlékeztető függőben” idejét.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'hu', 'Feloldott jegy „emlékeztető függőben” ideje elérve: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A feloldott [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy elérte az „emlékeztető függőben” idejét.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'hu', 'Jegyeszkaláció! <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy eszkalálódott!

Eszkaláció időpontja: <ZNUNY_TICKET_EscalationDestinationDate>
Eszkaláció óta eltelt idő: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'hu', 'Jegyeszkaláció figyelmeztetés! <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy eszkalálódni fog!

Eszkaláció időpontja: <ZNUNY_TICKET_EscalationDestinationDate>
Eszkalációig fennmaradó idő: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'hu', 'Jegyszolgáltatás frissítve <ZNUNY_TICKET_Service> szolgáltatásra: <ZNUNY_TICKET_Title>', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

A(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy szolgáltatása frissítve lett a következőre: <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'hu', 'Emlékeztető: <ZNUNY_APPOINTMENT_TITLE>', '<p>Kedves &lt;ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname&gt;!</p>
<p></p>
<p>A következő esemény elérte az értesítési idejét: &lt;ZNUNY_APPOINTMENT_TITLE&gt;</p>
<p></p>
<p>Leírás: &lt;ZNUNY_APPOINTMENT_DESCRIPTION&gt;</p>
<p>Hely: &lt;ZNUNY_APPOINTMENT_LOCATION&gt;</p>
<p>Naptár: <span style="color: &lt;ZNUNY_CALENDAR_COLOR&gt;;">■</span> &lt;ZNUNY_CALENDAR_CALENDARNAME&gt;</p>
<p>Kezdési dátum: &lt;ZNUNY_APPOINTMENT_STARTTIME&gt;</p>
<p>Befejezési dátum: &lt;ZNUNY_APPOINTMENT_ENDTIME&gt;</p>
<p>Egész napos: &lt;ZNUNY_APPOINTMENT_ALLDAY&gt;</p>
<p>Ismétlődés: &lt;ZNUNY_APPOINTMENT_RECURRING&gt;</p>
<p></p>
<p><a href="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;" title="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;">&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;</a></p>
<p></p>
<p>-- &lt;ZNUNY_CONFIG_NotificationSenderName&gt;</p>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (15, 'text/plain', 'hu', 'E-mail kézbesítési hiba', 'Kedves <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>!

Felhívjuk a figyelmét, hogy a(z) [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] jegy e-mail bejegyzésének kézbesítése nem sikerült. Ellenőrizze, hogy nincs-e a címzett e-mail címében hiba, és próbálja meg újra. Kézileg is újraküldheti a bejegyzést a jegyből, ha szükséges.

Hibaüzenet:
<ZNUNY_AGENT_TransmissionStatusMessage>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>;ArticleID=<ZNUNY_TICKET_LAST_ARTICLE_ID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'sr_Cyrl', 'Oтворен тикет: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је отворен у реду <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> је написао/ла:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'sr_Cyrl', 'Наставак откључаног тикета: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

откључани тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је примио наставак.

<ZNUNY_CUSTOMER_REALNAME> је написао/ла:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'sr_Cyrl', 'Наставак закључаног тикета: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

закључани тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је примио наставак.

<ZNUNY_CUSTOMER_REALNAME> је написао/ла:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'sr_Cyrl', 'Истек закључаног тикета: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је достигао време откључавања.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'sr_Cyrl', 'Промена власника тикета на <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

власник тикета [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је промењен на <ZNUNY_TICKET_OWNER_UserFullname> од стране <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'sr_Cyrl', 'Промена одговорног за тикет на <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

одговорни оператер тикета [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је промењен на <ZNUNY_TICKET_RESPONSIBLE_UserFullname> од стране <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'sr_Cyrl', 'Напомена тикета: <ZNUNY_AGENT_SUBJECT[24]>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> је написао/ла:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'sr_Cyrl', 'Промена реда тикета у <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

тикету [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је промењен ред у <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'sr_Cyrl', 'Истек закључаног тикета на чекању: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

време закључаног тикета на чекању [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је достигнуто.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'sr_Cyrl', 'Истек откључаног тикета на чекању: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

време откључаног тикета на чекању [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је достигнуто.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'sr_Cyrl', 'Ескалација тикета! <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је ескалирао!

Време ескалације: <ZNUNY_TICKET_EscalationDestinationDate>
Ескалиран од: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'sr_Cyrl', 'Упозорење на ескалацију тикета! <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

тикет [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] ће ескалирати!

Време ескалације: <ZNUNY_TICKET_EscalationDestinationDate>
Ескалира за: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'sr_Cyrl', 'Промена сервиса тикета на <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Здраво <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

сервис тикета [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] је промењен на <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'sr_Cyrl', 'Подсетник: <ZNUNY_APPOINTMENT_TITLE>', '<p>Здраво &lt;ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname&gt;,</p>
<p></p>
<p>време је за обавештење у вези термина &quot;&lt;ZNUNY_APPOINTMENT_TITLE&gt;&quot;.</p>
<p></p>
<p>Опис: &lt;ZNUNY_APPOINTMENT_DESCRIPTION&gt;</p>
<p>Локација: &lt;ZNUNY_APPOINTMENT_LOCATION&gt;</p>
<p>Календар: <span style="color: &lt;ZNUNY_CALENDAR_COLOR&gt;;">■</span> &lt;ZNUNY_CALENDAR_CALENDARNAME&gt;</p>
<p>Датум почетка: &lt;ZNUNY_APPOINTMENT_STARTTIME&gt;</p>
<p>Датум краја: &lt;ZNUNY_APPOINTMENT_ENDTIME&gt;</p>
<p>Целодневно: &lt;ZNUNY_APPOINTMENT_ALLDAY&gt;</p>
<p>Понављање: &lt;ZNUNY_APPOINTMENT_RECURRING&gt;</p>
<p></p>
<p><a href="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;" title="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;">&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;</a></p>
<p></p>
<p>-- &lt;ZNUNY_CONFIG_NotificationSenderName&gt;</p>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (1, 'text/plain', 'sr_Latn', 'Otvoren tiket: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je otvoren u redu <ZNUNY_TICKET_Queue>.

<ZNUNY_CUSTOMER_REALNAME> je napisao/la:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (2, 'text/plain', 'sr_Latn', 'Nastavak otključanog tiketa: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

otključani tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je primio nastavak.

<ZNUNY_CUSTOMER_REALNAME> je napisao/la:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (3, 'text/plain', 'sr_Latn', 'Nastavak zaključanog tiketa: <ZNUNY_CUSTOMER_SUBJECT[24]>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

zaključani tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je primio nastavak.

<ZNUNY_CUSTOMER_REALNAME> je napisao/la:
<ZNUNY_CUSTOMER_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (4, 'text/plain', 'sr_Latn', 'Istek zaključanog tiketa: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je dostigao vreme otključavanja.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (5, 'text/plain', 'sr_Latn', 'Promena vlasnika tiketa na <ZNUNY_OWNER_UserFullname>: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

vlasnik tiketa [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je promenjen na <ZNUNY_TICKET_OWNER_UserFullname> by <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (6, 'text/plain', 'sr_Latn', 'Promena odgovornog za tiket na <ZNUNY_RESPONSIBLE_UserFullname>: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

odgovorni operater tiketa [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je promenjen na <ZNUNY_TICKET_RESPONSIBLE_UserFullname> by <ZNUNY_CURRENT_UserFullname>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (7, 'text/plain', 'sr_Latn', 'Napomena tiketa: <ZNUNY_AGENT_SUBJECT[24]>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

<ZNUNY_CURRENT_UserFullname> je napisao/la:
<ZNUNY_AGENT_BODY[30]>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (8, 'text/plain', 'sr_Latn', 'Promena reda tiketa u <ZNUNY_TICKET_Queue>: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

tiketu [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je promenjen red u <ZNUNY_TICKET_Queue>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (9, 'text/plain', 'sr_Latn', 'Istek zaključanog tiketa na čekanju: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

vreme zaključanog tiketa na čekanju [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je dostignuto.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (10, 'text/plain', 'sr_Latn', 'Istek otključanog tiketa na čekanju: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

vreme otključanog tiketa na čekanju [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je dostignuto.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (11, 'text/plain', 'sr_Latn', 'Eskalacija tiketa! <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je eskalirao!

Vreme eskalacije: <ZNUNY_TICKET_EscalationDestinationDate>
Eskaliran od: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (12, 'text/plain', 'sr_Latn', 'Upozorenje na eskalaciju tiketa! <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

tiket [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] će eskalirati!

Vreme eskalacije: <ZNUNY_TICKET_EscalationDestinationDate>
Eskalira za: <ZNUNY_TICKET_EscalationDestinationIn>

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>


-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (13, 'text/plain', 'sr_Latn', 'Promena servisa tiketa na <ZNUNY_TICKET_Service>: <ZNUNY_TICKET_Title>', 'Zdravo <ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname>,

servis tiketa [<ZNUNY_CONFIG_Ticket::Hook><ZNUNY_CONFIG_Ticket::HookDivider><ZNUNY_TICKET_TicketNumber>] je promenjen na <ZNUNY_TICKET_Service>.

<ZNUNY_CONFIG_HttpType>://<ZNUNY_CONFIG_FQDN>/<ZNUNY_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<ZNUNY_TICKET_TicketID>

-- <ZNUNY_CONFIG_NotificationSenderName>');
-- ----------------------------------------------------------
--  insert into table notification_event_message
-- ----------------------------------------------------------
INSERT INTO notification_event_message (notification_id, content_type, language, subject, text)
    VALUES
    (14, 'text/html', 'sr_Latn', 'Podsetnik: <ZNUNY_APPOINTMENT_TITLE>', '<p>Zdravo &lt;ZNUNY_NOTIFICATION_RECIPIENT_UserFirstname&gt;,</p>
<p></p>
<p>vreme je za obaveštenje u vezi termina &quot;&lt;ZNUNY_APPOINTMENT_TITLE&gt;&quot;.</p>
<p></p>
<p>Opis: &lt;ZNUNY_APPOINTMENT_DESCRIPTION&gt;</p>
<p>Lokacije: &lt;ZNUNY_APPOINTMENT_LOCATION&gt;</p>
<p>Kalendar: <span style="color: &lt;ZNUNY_CALENDAR_COLOR&gt;;">■</span> &lt;ZNUNY_CALENDAR_CALENDARNAME&gt;</p>
<p>Datum početka: &lt;ZNUNY_APPOINTMENT_STARTTIME&gt;</p>
<p>Datum kraja: &lt;ZNUNY_APPOINTMENT_ENDTIME&gt;</p>
<p>Celodnevno: &lt;ZNUNY_APPOINTMENT_ALLDAY&gt;</p>
<p>Ponavljanje: &lt;ZNUNY_APPOINTMENT_RECURRING&gt;</p>
<p></p>
<p><a href="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;" title="&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;">&lt;ZNUNY_CONFIG_HttpType&gt;://&lt;ZNUNY_CONFIG_FQDN&gt;/&lt;ZNUNY_CONFIG_ScriptAlias&gt;index.pl?Action=AgentAppointmentCalendarOverview;AppointmentID=&lt;ZNUNY_APPOINTMENT_APPOINTMENTID&gt;</a></p>
<p></p>
<p>-- &lt;ZNUNY_CONFIG_NotificationSenderName&gt;</p>');
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'ProcessManagementProcessID', 'Process', 1, 'ProcessID', 'Ticket', '---
DefaultValue: ''''
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'ProcessManagementActivityID', 'Activity', 1, 'ActivityID', 'Ticket', '---
DefaultValue: ''''
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (1, 'ProcessManagementAttachment', 'Attachment', 1, 'TextArea', 'Ticket', '---
DefaultValue: ''''
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (0, 'TicketCalendarStartTime', 'Ticket Calendar StartTime', 1, 'DateTime', 'Ticket', '---
DefaultValue: 0,
YearsInFuture: 0,
YearsInPast: 0,
YearsPeriod: 0,
', 1, 1, current_timestamp, 1, current_timestamp);
-- ----------------------------------------------------------
--  insert into table dynamic_field
-- ----------------------------------------------------------
INSERT INTO dynamic_field (internal_field, name, label, field_order, field_type, object_type, config, valid_id, create_by, create_time, change_by, change_time)
    VALUES
    (0, 'TicketCalendarEndTime', 'Ticket Calendar EndTime', 1, 'DateTime', 'Ticket', '---
DefaultValue: 0,
YearsInFuture: 0,
YearsInPast: 0,
YearsPeriod: 0,
', 1, 1, current_timestamp, 1, current_timestamp);
SET standard_conforming_strings TO ON;
