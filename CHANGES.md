# 6.0.43 2022-05-04
 - Fixed migration module RemoveGenericAgentSystemCommandCalls.

# 6.0.42 2022-04-28
 - 2022-04-27 Deactivated Perl code execution for Template::Toolkit. Thanks to Sven Oesterling (OTOBO).

# 6.0.41 2022-04-20
 - 2022-04-13 Fixed refresh in overviews if fulltext search in toolbar is not enabled. [#237](https://github.com/znuny/Znuny/issues/237)
 - 2022-03-31 Fixed check of UntilTime in Kernel::System::Ticket::Event::TicketPendingTimeReset. [#221)(https://github.com/znuny/Znuny/issues/221)
 - 2022-03-24 Fixed XSS vulnerability in package manager GUI (CVE-2022-0475).
 - 2022-03-24 Deactivated support for execution of configurable system commands from Sendmail and PostMaster pre-filter configurations (CVE-2021-36100).
 - 2022-03-24 The system command in SysConfig option "MIME-Viewer" now is only configurable via Kernel/Config.pm (CVE-2021-36100).
 - 2022-03-23 Removed dashboard widget support for execution of system commands (CVE-2021-36100).
 - 2022-03-23 Removed configurable system commands from generic agents (CVE-2021-36100).
 - 2022-03-22 Added missing CKEditor codemirror plugin.
 - 2022-03-14 Fixed sending notifications to invalid customer users.

# 6.0.40 2022-03-09
 - 2022-03-07 Original owners of tickets will now be set again when cancelling a ticket bulk action.
 - 2022-03-02 Sector Nord AG: Fixed AgentAppointmentCalendarOverview AppointmentTooltip (#216). Thanks to Sector Nord AG (@jsinagowitz). [#216](https://github.com/znuny/Znuny/pull/216)
 - 2022-02-25 Fixed Bug - Since version 6.0.31 the size of embedded images within the RTE cannot be changed via click & drag anymore [#98](https://github.com/znuny/Znuny/issues/98).
 - 2022-02-25 Fixed Bug - Fixed subject regex for rfc822 attachments on email parsing operation. No error will be thrown anymore if subject is missing/empty.
 - 2022-02-18 Updated CKEditor from version 4.16.0 to 4.17.1.
 - 2022-02-11 Fixed Bug - Show menu items when showing the error screen. (https://github.com/znuny/Znuny/issues/210)
 - 2022-02-03 Fixed Bug - Dashboard-TicketQueueOverview refresh (https://github.com/znuny/Znuny/issues/156).
 - 2022-02-03 Updated jQuery UI from 1.12.1 to 1.13.1.
 - 2022-02-03 Fixed link detection matches trailing dot.
 - 2022-01-11 Fixed Bug - Email overwritten when editing an agent.
 - 2022-01-06 Fixed Bug - The page refresh stops the fulltext search via toolbar. [#182](https://github.com/znuny/Znuny/issues/182)

# 6.0.39 2021-12-15
 - 2021-12-14 Added ProcessListTreeView in AgentTicketProcess and CustomerTicketProcess.
 - 2021-12-14 Added missing translation for process and activity in CustomerTicketZoom.tt.
 - 2021-12-14 Removed translation for process in AdminProcessManagement.
 - 2021-12-14 Fixed bug, too long process / activity names are not translated.
 - 2021-12-03 Deactivated business solution daemon tasks.
 - 2021-12-03 Fixed - Links in dynamic fields are shortened so that the link no longer works (CustomerTicketZoom).
 - 2021-12-01 Fixed Bug - Avoidable error message / entry in logfiles (#123). [#123](https://github.com/znuny/Znuny/issues/123)
 - 2021-11-26 Fixed error "Parameter 'Config' must be a hash ref with data!" (#173). Thanks to @meisterheister. [#173](https://github.com/znuny/Znuny/issues/173)
 - 2021-11-25 Removed error log if !IsHashRefWithData( Config ) in `SanitizeConfig`. This is to strict and not needed.
 - 2021-11-25 Sector Nord AG: Replaced hardcoded attributes with a dynamic Sysconfig in Kernel/System/Ticket/Event/NotificationEvent.pm (#171). Thanks to @LuBroering (Lukas Bröring SectorNord AG). [#171](https://github.com/znuny/Znuny/issues/171)
 - 2021-11-25 Add option '--no-tablespaces' to scripts/backup.pl (#136). Thanks to @meisterheister. [#136](https://github.com/znuny/Znuny/issues/136)
 - 2021-11-25 Prevents error message "no TicketID" on sending an answer if no TicketID exists (#133). Thanks to Renée Bäcker (@reneeb). [#133](https://github.com/znuny/Znuny/issues/133)
 - 2021-11-25 Fixed - "No TicketID is given!" on each outgoing reply (#170). Thanks to Renée Bäcker (@reneeb). [#170](https://github.com/znuny/Znuny/issues/170)
 - 2021-11-25 Fixed - Bug - Regression Error Message in Log (#126). Thanks to Renée Bäcker (@reneeb). [#126](https://github.com/znuny/Znuny/issues/126)
 - 2021-11-15 Fixed CPANUpdate console command to also work on FreeBSD. Thanks to @papeng. [#162](https://github.com/znuny/Znuny/issues/162)

# 6.0.38 2021-10-27
 - 2021-10-21 Fixed error log message for missing days in Kernel::System::SysConfig::ValueType::WorkingHours::ModifiedValueGet(). [#122](https://github.com/znuny/Znuny/issues/122)
 - 2021-10-21 Fixed "Need Ticket ID" error when switching templates in AgentTicketCommon modules. [#127](https://github.com/znuny/Znuny/issues/127)
 - 2021-10-15 Fixed "Need ticket ID" error in Kernel::Modules::AgentTicketEmailOutbound. [#130](https://github.com/znuny/Znuny/issues/130)
 - 2021-10-12 Fixed translation bug in Kernel::Output::HTML::Layout::_BuildSelectionDataRefCreate.
 - 2021-10-11 Updated CPAN package Mozilla/CA.
 - 2021-10-01 Disabled connection to external RSS during unit testing. Thanks to Paweł Bogusławski (@pboguslawski). [#45](https://github.com/znuny/Znuny/pull/45)
 - 2021-10-01 Fixed error "Can't sign: unable to write 'random state'" if sending emails signed with S/MIME (OTRS bug #14522). Thanks to Kai Herlemann (@KaiHerlemann). [#72](https://github.com/znuny/Znuny/pull/72)

# 6.0.37 2021-09-29
 - 2021-09-28 Removed MySQL performance check module from support data collector. It only tests for the now deprecated MySQL setting 'query_cache_size'. Thanks for the hint to GitHub user arndkeyz.
 - 2021-09-27 Fixed problem with daylight saving time switch for recurrent appointments and date/time in general.
 - 2021-09-27 JavaScript in the error message of regular expression checks for dynamic field values now will be removed instead of being executed when showing the error message. Thanks to Stefan Härter (OTOBO) for reporting the issue.
 - 2021-09-23 Customer users with too many failed login attempts will now be set to "invalid-temporarily" and cannot log in anymore.
 - 2021-09-09 Fixed handling of database query results in Kernel::System::Ticket::_TicketGetClosed.
 - 2021-08-31 Fixed UI hang on admin group name change (#121). Thanks to Paweł Bogusławski (@pboguslawski). [#121](https://github.com/znuny/Znuny/pull/121)
 - 2021-08-31 Fixed storage switch only executable from main directory (#116). Thanks to maxence (@tipue-dev). [#116](https://github.com/znuny/Znuny/pull/116)
 - 2021-08-23 Added default value for CurrentComment in ACLUpdate.
 - 2021-08-20 Fixed double encoding for dynamic field filters in ticket overviews (#51). Thanks to maxence (@tipue-dev). [#51](https://github.com/znuny/Znuny/pull/51)
 - 2021-08-20 Fixed #107 - AgentTicketEmailOutbound "Empty subject" notification is not translated (#111.) Thanks to Tronsy (@Tronsy). [#111](https://github.com/znuny/Znuny/pull/111)
 - 2021-08-18 Fixed layout bug in BuildSelectionDataRefCreate

# 6.0.36 2021-08-05
 - 2021-07-28 Improved JavaScript recognition in function Kernel::System::HTMLUtils::Safety. Thanks for hints to Tim Püttmanns, maxence.
 - 2021-07-27 Files in configured directories of SysConfig options SMIME::PrivatePath and SMIME::CertPath will now not be included in a support bundle anymore if they are within the Znuny directory (CVE-2021-21440). Thanks for hints to Centuran Consulting.
 - 2021-07-27 Added safety checks for form/URL parameters to AdminAppointmentCalendarManage, AgentAppointmentEdit and AgentAppointmentList. Thanks for hints to Centuran Consulting.
 - 2021-07-26 Added permission check to ticket recipient list (CVE-2021-21443). Thanks for hints to Centuran Consulting.
 - 2021-07-26 Added permission check to appointment list (CVE-2021-36091). Thanks for hints to Centuran Consulting.
 - 2021-06-25 Linebreak now does not break fulltext search anymore (#49). Thanks to Johannes Nickel (@hanneshal). [#49](https://github.com/znuny/Znuny/pull/49)
 - 2021-06-25 Incorrect empty hash initializations fixed (#96). Thanks to Paweł Bogusławski (@pboguslawski). [#96](https://github.com/znuny/Znuny/pull/96)
 - 2021-06-25 Changed breadcrumb for the main action entry to a link. (#91). Thanks to maxence (@tipue-dev). [#91](https://github.com/znuny/Znuny/pull/91)
 - 2021-06-17 Fixed not needed error message in TicketList.pm (#94). Thanks to Paweł Bogusławski (@pboguslawski). [#94](https://github.com/znuny/Znuny/pull/94)
 - 2021-06-15 Do not warn agents about empty article subjects by default (#88). Thanks to Renée Bäcker (@reneeb). [#88]
 - 2021-06-15 Column list validation before saving agent preferences (#84). Thanks to Paweł Bogusławski (@pboguslawski). [#84](https://github.com/znuny/Znuny/pull/84)

# 6.0.35 2021-06-02
 - 2021-05-28 Improved StorageSwitch command to be more flexible (#27). Thanks to Renée Bäcker (@reneeb). [#27](https://github.com/znuny/Znuny/pull/27)
 - 2021-05-26 Changed autocomplete to 'new-password' (#64). Thanks to maxence (@tipue-dev) and Thijs Kinkhorst (@thijskh) [#64](https://github.com/znuny/Znuny/pull/64)
 - 2021-05-26 Fixed typo in variable "$SumRow"/"$SumCol" (#65). Thanks to paulfolkers (@paulfolkers) [#65](https://github.com/znuny/Znuny/pull/65)
 - 2021-05-26 Fixed ACL item from selection not changeable (#71). Thanks to maxence (@tipue-dev) [#71](https://github.com/znuny/Znuny/pull/71)
 - 2021-05-19 Fixed performance issue with regular expression that looks for PGP keys in the content of articles.
 - 2021-05-03 Changed behaviour of `NotificationEvent::Transport::Base->_ReplaceTicketAttributes()` function if multiselect fields are used.

# 6.0.34 2021-04-21
 - 2021-04-16 Fixed uninitialized value in pattern match warning for the TicketUpdate operation (#57). Thanks to maxence (@tipue-dev) [#57](https://github.com/znuny/Znuny/pull/57)
 - 2021-04-16 Fixed webservice console commands only use valid webservices to check if the name is already used (#56). Thanks to maxence (@tipue-dev) [#56](https://github.com/znuny/Znuny/pull/56)
 - 2021-04-16 Fixed uninitialized value in pattern match warning for the TicketCreate operation (#55). Thanks to maxence (@tipue-dev) [#55](https://github.com/znuny/Znuny/pull/55)
 - 2021-04-16 Changed CommunicationChannel to optional (#54). Thanks to maxence (@tipue-dev) [#54](https://github.com/znuny/Znuny/pull/54)
 - 2021-04-16 Fixed webservice creation only uses valid webservices to check if the name is already used (#53). Thanks to maxence (@tipue-dev) [#53](https://github.com/znuny/Znuny/pull/53)
 - 2021-04-16 Improved POD in Priority.pm (#46). Thanks to maxence (@tipue-dev) [#46](https://github.com/znuny/Znuny/pull/46)
 - 2021-04-14 Updated jquery-validate from version 1.16.0 to 1.19.3 (CVE-2021-21252).
 - 2021-04-13 Fixed product URL in HTTP Headers. Thanks to Renée Bäcker (@reneeb) [#42](https://github.com/znuny/Znuny/pull/42)
 - 2021-04-13 Updated CPAN module Sisimai. Thanks to Renée Bäcker (@reneeb) [#37](https://github.com/znuny/Znuny/pull/37)
 - 2021-04-13 Updated libwww-perl (LWP::UserAgent et al). Thanks to Renée Bäcker (@reneeb) [#40](https://github.com/znuny/Znuny/pull/40)
 - 2021-04-13 Updated cpan-lib LWP::Protocol::https. Thanks to Renée Bäcker (@reneeb) [#39](https://github.com/znuny/Znuny/pull/39)
 - 2021-04-13 Fixed missing spacing when adding new values to dynamic field dropdowns in configuration. Thanks to maxence (@tipue-dev) [#52](https://github.com/znuny/Znuny/pull/52)
 - 2021-03-18 Added HTML filter to output of localized date/time data which does not explicitly contain date/time values.
 - 2021-03-18 Limited evaluation of ticket column data as date/time to specific date/time string format in Kernel/Output/HTML/TicketOverview/Small.pm.
 - 2021-03-16 Removed duplicated code. Thanks to Renée Bäcker (@reneeb). [#33](https://github.com/znuny/Znuny/pull/33)
 - 2021-03-16 Fixed minor syntax issues: replaced ',' with ';'. Thanks to Renée Bäcker (@reneeb). [#32](https://github.com/znuny/Znuny/pull/32)
 - 2021-03-16 Fixed bug#[14622](https://bugs.otrs.org/show_bug.cgi?id=14622) - Wrong navigation group for Frontend::Module###AdminAppointmentImport and Frontend::NavBarModule###2-AdminFavourites admin modules
 - 2021-03-15 Created missing symlink for deployment. [#30](https://github.com/znuny/Znuny/issues/30) [#31](https://github.com/znuny/Znuny/pull/31)
 - 2021-03-15 Fixed link to admin manual (shown in admin area). Thanks to Renée Bäcker (@reneeb). [#18](https://github.com/znuny/Znuny/pull/18)

# 6.0.33 2021-03-10
 - 2021-03-02 Limited match for subdomain to 255 characters in Kernel::Output::HTML::FilterText::URL because of runtime issues.
 - 2021-02-24 Moved 'AdminSupportDataCollector' to 'Administration' in Admin.
 - 2021-02-22 Fixed article limit in generic interface operation TicketGet. Thanks to Renée Bäcker (@reneeb). [#16](https://github.com/znuny/Znuny/issues/16) [#17](https://github.com/znuny/Znuny/pull/17)
 - 2021-02-15 Leading and trailing white space in names of uploaded files will now be removed. This prevents non-working attachment download links.
 - 2021-02-12 Fixed output of customer (user) dynamic field labels and values in PDF.
 - 2021-02-11 Removed unused SysConfig options Ticket::Frontend::AgentTicketStatusView###ViewableTicketsPage and Ticket::Frontend::AgentTicketEscalationView###ViewableTicketsPage. Thanks to Bernhard Schmalhofer (@bschmalhofer).
 - 2021-02-11 Updated to JavaScript::Minifier 1.15. Enabled automatic utilization of JavaScript::Minifier::XS if available. Thanks to Fedor A. Fetisov (@faf), @zoffixznet and Yuri Myasoedov (@ymyasoedov). [#6](https://github.com/znuny/Znuny/issues/6)
 - 2020-02-11 Enabled automatic utilization of CSS::Minifier::XS if available.
 - 2020-02-11 Fixed return value format of user search. Thanks to Nicola Cordioli (@niccord).
 - 2020-02-10 Fixed bug in `_UserCacheClear` in Kernel::System::User. Thanks to Yuri Myasoedov (@ymyasoedov). [#1](https://github.com/znuny/Znuny/pull/1)

# 6.0.32 2021-01-29
 - 2021-01-29 Updated CKEditor to version 4.16.0.

# 6.0.31 2021-01-27
 - 2021-01-27 Updated CKEditor to version 4.15.1.
 - 2021-01-27 Switched to Znuny branding.

# 6.0.30 2020-10-12
 - 2020-09-22 Updated translations, thanks to all translators.
 - 2020-09-15 Fixed bug#[15246](https://bugs.otrs.org/show_bug.cgi?id=15246) - Default encryption setting on queue is ignored.
  If there are more than one S/MIME keys available, the newest one is selected in AgentTicketEmail and not the one selected for this queue. Also the setting in the queue about the certification to use is ignored by the ticket notifications.
 - 2020-09-09 Updated third party libraries: jquery to 3.5.1, fullcalendar to 3.10.2, fullcalendar-scheduler to 1.10.1 and spectrum to 1.8.1.
 - 2020-07-27 Fixed bug#[15263](https://bugs.otrs.org/show_bug.cgi?id=15263) - Maint::Email::MailQueue adds error log entry because of using uninitialized value.
 - 2020-07-03 Fixed bug#[15180](https://bugs.otrs.org/show_bug.cgi?id=15180) - Plain text article printing does not work well with citation.

# 6.0.29 2020-07-20
 - 2020-07-05 Fixed bug#[15227](https://bugs.otrs.org/show_bug.cgi?id=15227) - Daemon outputs subroutine redefined in logs and provoking false task failures.
 - 2020-07-01 Updated translations, thanks to all translators.
 - 2020-06-30 Updated Mozilla's CA certificate bundle.
 - 2020-06-29 Improved session handling.
 - 2020-05-28 Changed shebang command line of Perl scripts from `/usr/bin/perl` (which hardcodes the system Perl) to `/usr/bin/env perl` (which uses the first found Perl from the $PATH). This should not cause any changes on systems where there is only one Perl installed, but more predictable behavior on systems which have an additional "custom" Perl installed.
 - 2020-05-26 Fixed bug#[15143](https://bugs.otrs.org/show_bug.cgi?id=15143) - SysConfig broken for editing array of hashes.
 - 2020-05-18 Fixed bug#[13924](https://bugs.otrs.org/show_bug.cgi?id=13924) - `Error creating DateTime object` appears in the log during daylight saving time switch.
 - 2020-05-13 Fixed bug#[15016](https://bugs.otrs.org/show_bug.cgi?id=15016) - Processing of sequence flows throws error for tickets assigned to unknown or invalid processes.
 - 2020-05-13 Fixed bug#[15075](https://bugs.otrs.org/show_bug.cgi?id=15075) - Wrong S/MIME certificate is selected in AgentTicketCompose.
 - 2020-05-08 Improved random number generator.
 - 2020-04-27 Fixed bug#[14997](https://bugs.otrs.org/show_bug.cgi?id=14997) - RichText editor is taking focus if required validation fails.
  After updating jQuery library, it's not possible to leave it empty.
 - 2020-04-13 Fixed bug#[15035](https://bugs.otrs.org/show_bug.cgi?id=15035) - Missing Perl dependency in CheckModules script (Moo).

# 6.0.28 2020-04-20
 - 2020-04-08 Updated translations, thanks to all translators.
 - 2020-04-07 Added more debugging information in the error log when system fails to create DateTime object.
 - 2020-03-24 Fixed bug#[14958](https://bugs.otrs.org/show_bug.cgi?id=14958) - Can't reply to an article create using Internal communication channel.
 - 2020-03-19 Fixed bug#[15031](https://bugs.otrs.org/show_bug.cgi?id=15031) - Inconsistent behavior in sending AddNote notification to "involved agent" who has no permissions on ticket queue.
 - 2020-03-18 Fixed bug#[14965](https://bugs.otrs.org/show_bug.cgi?id=14965) - Untranslated string in database charset check.
 - 2020-03-17 Fixed bug#[14948](https://bugs.otrs.org/show_bug.cgi?id=14948) - Line breaks in tag 'OTRS_APPOINTMENT_DESCRIPTION' are not replaced.
 - 2020-03-13 Fixed bug#[15017](https://bugs.otrs.org/show_bug.cgi?id=15017) - Untranslated strings in PGP status information.
 - 2020-03-12 Improved download of the private and public keys and certificates (S/MIME and PGP).
 - 2020-03-11 Fixed bug#[14956](https://bugs.otrs.org/show_bug.cgi?id=14956) - Add new key/value pair to the Hash element doesn't render proper element in SysConfig.
 - 2020-03-10 Fixed bug#[13657](https://bugs.otrs.org/show_bug.cgi?id=13657) - There are "Duplicate entry" error messages for the ticket seen flag in the log.
 - 2020-03-06 Fixed bug#[13761](https://bugs.otrs.org/show_bug.cgi?id=13761) - Line breaks are not working in the long description fields in the Process management.
 - 2020-03-02 Fixed bug#[15005](https://bugs.otrs.org/show_bug.cgi?id=15005) - The service view does not work well with more than 10000 tickets.
  With the fix there is a limit of 20000 tickets.
 - 2020-03-02 Fixed bug#[14975](https://bugs.otrs.org/show_bug.cgi?id=14975) - Setting Event Type Filter in the ticket timeline view is applied only to the current ticket.
  Instead, it should be applied to all tickets.
 - 2020-03-02 Fixed bug#[14930](https://bugs.otrs.org/show_bug.cgi?id=14930) - Matching 'Frontend' setting in the ACLs causes problem when changing Type, Queue, Service or SLA.
  The issue occurs in combination with PossibleAdd parameter - the forbidden fields are still there (i.e. Free fields), but changes are not saved.

# 6.0.27 2020-03-27
 - 2020-03-23 Mask user credentials in the SupportBundle.
 - 2020-03-12 Updated translations, thanks to all translators.
 - 2020-03-03 Improved random number generator.
  We added new CPAN dependencies, which should already be present on all systems:
    Crypt::Random::Source
    Exporter::Tiny
    Math::Random::ISAAC
    Math::Random::Secure
    Module::Find
    Moo
    Types::TypeTiny
    namespace::clean

 - 2020-03-03 Improved token handling in the LostPassword requests.
 - 2020-02-28 Fixed bug#[14752](https://bugs.otrs.org/show_bug.cgi?id=14752) - In the ticket create screen, system always preselects first valid certificate for signature/encryption.
  In this case, system should preselect default certificate, or the one with the newest/longest valid certificate.
 - 2020-02-28 Fixed bug#[14949](https://bugs.otrs.org/show_bug.cgi?id=14949) - PostMaster X-OTRS-AttachmentExists filter is activated on email with embedded images.
 - 2020-02-28 Fixed bug#[13103](https://bugs.otrs.org/show_bug.cgi?id=13103) - Items in admin favorites are sorted by id instead of alphabetically.
 - 2020-02-28 Fixed bug#[14953](https://bugs.otrs.org/show_bug.cgi?id=14953) - System logs an error when email contains utf-8 characters while trying to create a gravatar link.
 - 2020-02-28 Fixed bug#[14952](https://bugs.otrs.org/show_bug.cgi?id=14952) - From field is not consistent if article is created by note compared to the bulk note add (in agent interface).
 - 2020-02-27 Fixed bug#[14988](https://bugs.otrs.org/show_bug.cgi?id=14988) - The edit button in 'Assigned Transition Actions' table doesn't work (in Transition Actions).
 - 2020-02-27 Fixed bug#[14987](https://bugs.otrs.org/show_bug.cgi?id=14987) - InvalidUserCleanup generates tons of useless entries in the ticket history.
 - 2020-02-27 Fixed bug#[14982](https://bugs.otrs.org/show_bug.cgi?id=14982) - Filter for CustomerIDs with special characters break the page.
 - 2020-02-26 Fixed bug#[14774](https://bugs.otrs.org/show_bug.cgi?id=14774) - AdminGenericAgent matches first ticket close time instead of last.
  The issue occurs when the ticket is reopened and then closed again - system matches first close time.
 - 2020-02-25 Fixed bug#[14944](https://bugs.otrs.org/show_bug.cgi?id=14944) - Changing Ticket Number Generator causes ExternalTicketNumberRecognition to fail.
  Therefore system creates a new ticket instead of appending the article to the existing one.
 - 2020-02-19 Fixed bug#[14974](https://bugs.otrs.org/show_bug.cgi?id=14974) - Untranslated string in appointment calendar.
 - 2020-02-14 Fixed bug#[14963](https://bugs.otrs.org/show_bug.cgi?id=14963) - Mails are not signed in compose screens.
  If an S/MIME certificate is set for signing and encrypting outgoing mails, it is not used for signing in Compose answers. For new Email tickets, E-Mail Outbound and Forward the emails are signed correctly. Furthermore, if "sign and encrypt" is chosen, the mail will only be encrypted, but not signed.
 - 2020-02-14 Fixed bug#[14926](https://bugs.otrs.org/show_bug.cgi?id=14926) - OTRS tag <OTRS_EMAIL_DATE[]> in Templates does not work correctly.
 - 2020-02-14 Fixed bug#[14932](https://bugs.otrs.org/show_bug.cgi?id=14932) - OTRS tag is not replaced in a Generic Agent job if the ticket has no CustomerID.
 - 2020-02-12 Fixed bug#[14960](https://bugs.otrs.org/show_bug.cgi?id=14960) - Incorrect language file loading.
 OTRS loads wrong language files if the user uses a top-level language file like 'es' or 'fr' where also country variants exist (e. g. "es_MX") and the user has packages with translation files installed.
 - 2020-02-11 Added a new SysConfig setting 'DisableLoginAutocomplete' - when enabled, it disables autocomplete in the login forms.
   System adds autocomplete="off" attribute to the login input fields. Note that some browsers ignore it by default (usually it can be changed in the browser configuration).
 - 2020-02-10 Fixed bug#[14773](https://bugs.otrs.org/show_bug.cgi?id=14773) - Invalid characters in Perl Modules section on AdminSupportDataCollector screen.
 - 2020-02-07 Fixed bug#[14968](https://bugs.otrs.org/show_bug.cgi?id=14968) - Values of the queue field are translated in the bulk view.
 - 2020-02-07 Fixed bug#[14967](https://bugs.otrs.org/show_bug.cgi?id=14967) - The accounted time is missing in the generic interface TicketGet documentation of API.
 - 2020-02-06 Fixed bug#[14833](https://bugs.otrs.org/show_bug.cgi?id=14833) - Citation conversion to plain text is broken.
 - 2020-02-05 Improved From field handling in the Email action screens.
 - 2020-02-05 Fixed bug#[14858](https://bugs.otrs.org/show_bug.cgi?id=14858) - It's not possible to transfer value "0" via web service to dynamic field.
 - 2020-02-05 Fixed bug#[14203](https://bugs.otrs.org/show_bug.cgi?id=14203) - GET method processes entity-body message from request.
 - 2020-02-05 Follow-up fix for bug#[10825](https://bugs.otrs.org/show_bug.cgi?id=10825) - <OTRS_CUSTOMER_Body> in Reply-Template.
  Re-added tags which were marked as not supported in previous fix.

# 6.0.26 2020-02-07
 - 2020-01-23 Updated translations, thanks to all translators.
 - 2020-01-22 Update jquery to 3.4.1.
 - 2020-01-16 Fixed bug#[14917](https://bugs.otrs.org/show_bug.cgi?id=14917) - Permission problem with Notification and Group rights (NOTE/RO).
  When user sends a note to the 'InvolvedAgent', target user doesn't receive notification if he doesn't have the 'RO' permission (even if he has other permissions, like NOTE).
 - 2020-01-15 Fixed bug#[14908](https://bugs.otrs.org/show_bug.cgi?id=14908) - Line brakes are ignored in the long descriptions (Activity Dialog).
 - 2020-01-08 Fixed bug#[14367](https://bugs.otrs.org/show_bug.cgi?id=14367) - Generic agent edit screen is slow when there are many dynamic fields.
 - 2020-01-08 Fixed bug#[13159](https://bugs.otrs.org/show_bug.cgi?id=13159) - Generic agent deletes the content of dropdown dynamic field if empty value is added.
  It only happens when 'Add empty value' is set.
 - 2019-12-27 Fixed bug#[14882](https://bugs.otrs.org/show_bug.cgi?id=14882) - Number of tickets is wrong in the customer information center if dynamic fields are used.
  If dynamic fields are used as attributes in Frontend::CustomerUser::Item###15-OpenTickets the number of tickets for the link in the customer information center is not displayed correctly.
 - 2019-12-25 Fixed bug#[14722](https://bugs.otrs.org/show_bug.cgi?id=14722) - Debug messages are shown as Daemon errors.
 - 2019-12-25 Fixed bug#[14900](https://bugs.otrs.org/show_bug.cgi?id=14900) - Transition action / Sequence flow DynamicFieldSet can't handle multiselect field value set.
 - 2019-12-25 Fixed bug#[14288](https://bugs.otrs.org/show_bug.cgi?id=14288) - CustomerUser is not set when ticket is created via Web Service.
  CustomerUser parameter expects customer user login, so when email is provided it didn't worked out.
 - 2019-12-20 Fixed bug#[14912](https://bugs.otrs.org/show_bug.cgi?id=14912) - Installer refers to non-existing documentation.
 - 2019-12-18 Fixed bug#[14896](https://bugs.otrs.org/show_bug.cgi?id=14896) - Process print action in process overview screen does not open in pop-up window.
 - 2019-12-16 Fixed bug#[14895](https://bugs.otrs.org/show_bug.cgi?id=14895) - Caching issues with dropdown and multiselect dynamic fields when they are filled by 'DynamicFieldFromCustomerUser::Mapping' (Agent interface).
 - 2019-12-16 Fixed bug#[14910](https://bugs.otrs.org/show_bug.cgi?id=14910) - Missing ZZZAAuto.pm prevents deployment of overridden invalid entity type database settings.
  If system has invalid setting stored in the SysConfig database which is overridden via ZZZ*pm files, rebuild fails and therefore machines can't be deployed when upgrading the system.
 - 2019-12-10 Fixed bug#[14903](https://bugs.otrs.org/show_bug.cgi?id=14903) - There is a space after some time values in statistics.

# 6.0.25 2020-01-10
 - 2019-12-12 Updated translations, thanks to all translators.
 - 2019-12-11 Improved handling of the uploaded inline images.
 - 2019-12-06 Fixed bug#[14886](https://bugs.otrs.org/show_bug.cgi?id=14886) - When config ExternalFrontend::TicketCreate###Queue is disabled, customer user can create a ticket in default queue without sufficient permission.
 - 2019-12-05 Fixed bug#[14233](https://bugs.otrs.org/show_bug.cgi?id=14233) - It's not possible to disable ticket type via ACL in the AgentTicketSearch.
 - 2019-12-05 Improved the draft feature in the agent frontend.
 - 2019-12-04 Fixed bug#[14791](https://bugs.otrs.org/show_bug.cgi?id=14791) - ICS files with carriage return character can not be imported to calendar.
 - 2019-12-03 Fixed bug#[14883](https://bugs.otrs.org/show_bug.cgi?id=14883) - Confusing message 'This message has been queued for sending' is shown in the TicketZoom screen.
 - 2019-12-02 Fixed bug#[14881](https://bugs.otrs.org/show_bug.cgi?id=14881) - Signature and Salutation text fields are not marked as mandatory in add and edit screens in admin interface.
 - 2019-11-29 Improved article sending via email communication channel.
 - 2019-11-29 Fixed bug#[14869](https://bugs.otrs.org/show_bug.cgi?id=14869) - The value of config Ticket::IncludeUnknownTicketCustomers is ignored in the statistic.
 - 2019-11-29 Fixed bug#[14861](https://bugs.otrs.org/show_bug.cgi?id=14861) - Foreign Customer Company DB validation is wrong.
 - 2019-11-28 Fixed bug#[14834](https://bugs.otrs.org/show_bug.cgi?id=14834) - Packages with long description (comment) can not be deployed in the system configuration.
 - 2019-11-28 Follow-up fix for bug#[14761](https://bugs.otrs.org/show_bug.cgi?id=14761) - It's not possible to create article with attachment named '0'.
 - 2019-11-20 Fixed bug#[14659](https://bugs.otrs.org/show_bug.cgi?id=14659) - Composing a new mail message with a blank subject causes no warning to appear.
 - 2019-11-15 Fixed bug#[14852](https://bugs.otrs.org/show_bug.cgi?id=14852) - Customer company filter is reset after going to the other page.
 - 2019-11-07 Improved config 'Ticket::ViewableStateType' description.
 - 2019-11-07 Fixed bug#[14826](https://bugs.otrs.org/show_bug.cgi?id=14826) - Ticket history shows incomplete record for the Type entry.
 - 2019-11-07 Fixed bug#[14864](https://bugs.otrs.org/show_bug.cgi?id=14864) - When generic agent changes a ticket's CustomerID, CustomerUserID is cleared and is empty.
 - 2019-11-05 Fixed bug#[14851](https://bugs.otrs.org/show_bug.cgi?id=14851) - Predefined values for dynamic fields are missing in the system configuration for TicketSearch screens.
 - 2019-11-05 Fixed bug#[14747](https://bugs.otrs.org/show_bug.cgi?id=14747) - PerformanceLog file increases despite max size is reached.
 - 2019-11-05 Fixed bug#[14845](https://bugs.otrs.org/show_bug.cgi?id=14845) - It's not possible to save system configuration settings with Date type on Internet Explorer.
 - 2019-11-05 Removed unneeded dependency Crypt::SSLeay.
 - 2019-11-04 Fixed bug#[14842](https://bugs.otrs.org/show_bug.cgi?id=14842) - Downgrade to ((OTRS)) Community Edition is possible for every agent whether or not the agent is member of the admin group.

# 6.0.24 2019-11-15
 - 2019-10-31 Updated translations, thanks to all translators.
 - 2019-10-25 Fixed bug#[13651](https://bugs.otrs.org/show_bug.cgi?id=13651) - User is logged out after deploying system configuration changes.
  There is missing SessionID parameter in the link for setting deployment when SessionUserCookie is disabled.
 - 2019-10-24 Updated welcome ticket text.
 - 2019-10-24 Fixed bug#[14763](https://bugs.otrs.org/show_bug.cgi?id=14763) - Invisible SysConfig settings are not removed on package deinstallation.
 - 2019-10-23 Follow-up fix for bug#[14542](https://bugs.otrs.org/show_bug.cgi?id=14542) - Date values for escalation times are not localized in ticket small overview.
 - 2019-10-22 Fixed bug#[14810](https://bugs.otrs.org/show_bug.cgi?id=14810) - Attributes are not replaced with OTRS_CURRENT_ tags in Transition Action modules in the process management.
 - 2019-10-21 Fixed bug#[14742](https://bugs.otrs.org/show_bug.cgi?id=14742) - Short and long dynamic field descriptions are not translated in the process management.
 Translation short/long description in a process.
 - 2019-10-21 Fixed bug#[14742](https://bugs.otrs.org/show_bug.cgi?id=14742) - Translation short/long description in a process.
 - 2019-10-18 Fixed bug#[14824](https://bugs.otrs.org/show_bug.cgi?id=14824) - Ticket action sub-menu items suddenly disappear in the AgentTicketZoom.
 - 2019-10-15 Follow-up fix for bug#[14693](https://bugs.otrs.org/show_bug.cgi?id=14693) - Console command Maint::Ticket::InvalidUserCleanup reports error about ArticleFlagDelete().
 - 2019-10-11 Fixed bug#[14800](https://bugs.otrs.org/show_bug.cgi?id=14800) - Signature check and decryption of PGP and S/MIME mails causes needless write operations.
 - 2019-10-10 Follow-up fix for bug#[14716](https://bugs.otrs.org/show_bug.cgi?id=14716) - Mails with attached mails (e.g. forwarded) containing period followed by long string in the subject may get stuck.
 - 2019-10-08 Fixed bug#[14798](https://bugs.otrs.org/show_bug.cgi?id=14798) - Dev::Tools::TranslationsUpdate includes the header of PO file into the language file for empty string.
 - 2019-10-08 Fixed bug#[14775](https://bugs.otrs.org/show_bug.cgi?id=14775) - ACL does not match process activity (ActivityEntityID).
 - 2019-10-07 Fixed bug#[14785](https://bugs.otrs.org/show_bug.cgi?id=14785) - Wrong grammar in the CustomerAccept link in the customer interface.
 - 2019-10-04 Fixed bug#[13469](https://bugs.otrs.org/show_bug.cgi?id=13469) - Missing Signing and Encryption information in the Ticket zoom screen.
 - 2019-10-01 Fixed bug#[14615](https://bugs.otrs.org/show_bug.cgi?id=14615) - Outdated default Gravatar image URL.
  Gravatar image mm (mystery-man) is renamed to mp (mystery-person).
 - 2019-09-19 Fixed bug#[14751](https://bugs.otrs.org/show_bug.cgi?id=14751) - Wrong favicon URL for US-CERT NVD in OutputFilterTextAutoLink###CVE system configuration item.
 - 2019-09-19 Fixed bug#[12726](https://bugs.otrs.org/show_bug.cgi?id=12726) - Automatic links to CVE numbers don't work in TicketViewZoom.
 - 2019-09-18 Fixed bug#[14743](https://bugs.otrs.org/show_bug.cgi?id=14743) - Missing filter state in the queue view for queues with sub-queues.

# 6.0.23 2019-10-04
 - 2019-09-18 Updated translations, thanks to all translators.
 - 2019-09-13 Fixed bug#[14768](https://bugs.otrs.org/show_bug.cgi?id=14768) - Advanced setting options are not reachable in System Configuration if the setting value contains too much text.
 - 2019-09-12 Fixed bug#[13886](https://bugs.otrs.org/show_bug.cgi?id=13886) - Access to settings with higher ConfigLevel is possible even if system wide ConfigLevel is not matched.
 - 2019-09-11 Fixed bug#[14761](https://bugs.otrs.org/show_bug.cgi?id=14761) - It's not possible to create article with attachment named '0'.
 Instead, error message is shown.
 - 2019-09-10 Fixed bug#[14760](https://bugs.otrs.org/show_bug.cgi?id=14760) - Customer user has no customer relation information in search result screen.
 - 2019-09-06 Fixed LibreSSL version detection.
 - 2019-09-04 Fixed bug#[14497](https://bugs.otrs.org/show_bug.cgi?id=14497) - Filtering doesn't work when special characters (like & and ;) are used in ColumnFilterDynamicField.
  In this case there is encoding problem.
 - 2019-09-04 Fixed bug#[14748](https://bugs.otrs.org/show_bug.cgi?id=14748) - TicketOverviewSmall screen has a much lower performance than Medium and Large screens.
 - 2019-09-04 Fixed bug#[14708](https://bugs.otrs.org/show_bug.cgi?id=14708) - Dev::Tools::TranslationsUpdate command generates wrong filename if the module name contains a number.
 - 2019-09-04 Fixed bug#[14764](https://bugs.otrs.org/show_bug.cgi?id=14764) - Wrong calendar highlighting in the Month timeline.
 - 2019-09-04 Fixed bug#[14678](https://bugs.otrs.org/show_bug.cgi?id=14678) - NotificationOwnerUpdate event can cause wrong <OTRS_CUSTOMER_BODY> tag replacing.
  Systems sets content to 'No body' instead of last customer article body.
 - 2019-09-03 Fixed bug#[14610](https://bugs.otrs.org/show_bug.cgi?id=14610) - There is no autocomplete option for AgentTicketBulk action in ACL configuration.
   `ACLKeysLevel3::Actions###100-Default` is updated. AgentTicketBulk is added as a possible action.
 - 2019-08-27 Fixed bug#[14728](https://bugs.otrs.org/show_bug.cgi?id=14728) - Dynamic field values are replaced by "xxx" in notifications and emails when using <OTRS>-tags in notifications.
  It's fixed by adding a check if the tag is referring to the Dynamic field and in this case system skips value replacement.
 - 2019-08-26 Fixed bug#[14724](https://bugs.otrs.org/show_bug.cgi?id=14724) - It's not possible to search for a dynamic field with the name 'Name' in the activity dialog.
 - 2019-08-21 Fixed bug#[14737](https://bugs.otrs.org/show_bug.cgi?id=14737) - "Switch to customer" feature is not working in AgentCustomerInformationCenter.
 - 2019-08-13 Fixed bug#[14720](https://bugs.otrs.org/show_bug.cgi?id=14720) - In the process management, TicketStateSet script task fails if target state equals current state.
   When TicketStateSet fails, it causes a scheduler error e-mail to be sent.
 - 2019-08-12 Fixed bug#[14677](https://bugs.otrs.org/show_bug.cgi?id=14677) - Undefined field in title of activity dialog edit window.
 - 2019-08-08 Fixed bug#[14665](https://bugs.otrs.org/show_bug.cgi?id=14665) - Config option 'AutoResponseForWebTicket' is not honored in follow-up articles.
   When 'AutoResponseForWebTickets' is set to 'No', follow-up articles generate auto-response.
 - 2019-08-07 Fixed bug#[14716](https://bugs.otrs.org/show_bug.cgi?id=14716) - E-mails with attached e-mails (e.g. forwarded) containing period followed by long string in the subject may get stuck.
   Put such e-mail into OTRS PostMaster and mail processing will run until the process is killed manually.

# 6.0.22 2019-08-30
 - 2019-08-26 Fixed bug#[14758](https://bugs.otrs.org/show_bug.cgi?id=14758) - If activity dialog contains 'Article' field after 'CustomerID', users are not able to create process ticket (Need TicketID error).

# 6.0.21 2019-08-23
 - 2019-08-08 Updated translations, thanks to all translators.
 - 2019-08-08 Fixed bug#[14694](https://bugs.otrs.org/show_bug.cgi?id=14694) - Multiple emails are sent out by one action.
   A regression was introduced in a previous bugfix in OTRS 6.0.7, that resulted in an errant submit handler which would result in multiple instances of the same article in case the recipient field was entered manually.
 - 2019-08-05 Fixed bug#[14693](https://bugs.otrs.org/show_bug.cgi?id=14693) - Console command Maint::Ticket::InvalidUserCleanup reports error about ArticleFlagDelete().
 - 2019-08-05 Fixed bug#[14713](https://bugs.otrs.org/show_bug.cgi?id=14713) - Untranslated strings in GenericInterface screens.
 - 2019-08-05 Fixed bug#[14644](https://bugs.otrs.org/show_bug.cgi?id=14644) - Client side validation does not show tooltips in the Appointment calendar.
 - 2019-08-05 Fixed bug#[14572](https://bugs.otrs.org/show_bug.cgi?id=14572) - Package installation via Console upgrade command bypasses OTRS verification.
 - 2019-08-05 Fixed bug#[14672](https://bugs.otrs.org/show_bug.cgi?id=14672) - Values from multi-select Dynamic Fields do not work as recipient in Ticket Notifications.
 - 2019-08-02 Added colorization of weekends in calendars.
 - 2019-08-02 Fixed bug#[14655](https://bugs.otrs.org/show_bug.cgi?id=14655) - In the process management OTRS_CURRENT tags are not correctly interpreted when used in the TicketOwnerSet and TicketResponsibleSet transition action.
 - 2019-07-29 Fixed bug#[14357](https://bugs.otrs.org/show_bug.cgi?id=14357) - Email sending doesn't work fine with specific module versions.
   Recently additional option for otrs.CheckModules.pl has been introduced to show recommended version of modules which should be used. Modules 'IO::Socket::SSL' and 'Net::SMTP' have increased recommended versions.
 - 2019-07-29 Fixed bug#[14605](https://bugs.otrs.org/show_bug.cgi?id=14605) - Password field is not mandatory on S/MIME screen.
 - 2019-07-29 Fixed bug#[14629](https://bugs.otrs.org/show_bug.cgi?id=14629) - In the Calendar Overview screen, last selected Timeline overview is not saved.
 - 2019-07-25 Fixed bug#[14670](https://bugs.otrs.org/show_bug.cgi?id=14670) - Ticket notification migration from 5 to 6 fails if notification content is missing.
 - 2019-07-25 Follow-up fix for bug#[14557](https://bugs.otrs.org/show_bug.cgi?id=14557) - Webservice debug log does not honor selected agent timezone.
 - 2019-07-24 Fixed bug#[12956](https://bugs.otrs.org/show_bug.cgi?id=12956) - After splitting the ticket Customer Information are wrong.
 - 2019-07-23 Fixed bug#[14358](https://bugs.otrs.org/show_bug.cgi?id=14358) - Ticket Title is hidden in the ticket zoom screen using Mobile Mode in Agent interface.
 - 2019-07-23 Fixed bug#[14503](https://bugs.otrs.org/show_bug.cgi?id=14503) - Filter label is not visible if High contrast skin is used.
 - 2019-07-23 Fixed bug#[14662](https://bugs.otrs.org/show_bug.cgi?id=14662) - Syncing LDAP fields causes error when value is undefined.
 - 2019-07-22 Fixed bug#[14563](https://bugs.otrs.org/show_bug.cgi?id=14563) - Responsible agent is not shown in the 'To' Field of the Article in the Ticket zoom screen.
 - 2019-07-22 Fixed bug#[14666](https://bugs.otrs.org/show_bug.cgi?id=14666) - OTRS console command Dev::Code::CPANAudit scans OTRS home folder and decreases performance.
   System scans all folders for perl modules, which is not needed.
 - 2019-07-19 Fixed bug#[14646](https://bugs.otrs.org/show_bug.cgi?id=14646) - OTRS_CUSTOMER_DATA tags not correctly interpreted in DynamicFieldSet transition action.
 - 2019-07-19 Additional recipient email addresses in notification events are correctly separated on send to prevent information leakage.
 - 2019-07-18 Fixed bug#[14651](https://bugs.otrs.org/show_bug.cgi?id=14651) - System configuration descriptions refers to non-existing parameters (e.g. AccessibleTickets).
 - 2019-07-10 Fixed bug#[14593](https://bugs.otrs.org/show_bug.cgi?id=14593) - Article seen flag shows wrong state when there are more then 1500 articles for one ticket.
 - 2019-07-10 Fixed bug#[14618](https://bugs.otrs.org/show_bug.cgi?id=14618) - Information about usage of 'URI' or 'URL' filters is missing at some dynamic field types.
 - 2019-07-09 Fixed bug#[14612](https://bugs.otrs.org/show_bug.cgi?id=14612) - Explanation for 'Kernel::System::Email::Test' is missing from SendmailModule System configuration description.
 - 2019-07-04 Fixed bug#[14597](https://bugs.otrs.org/show_bug.cgi?id=14597) - Missing hint on how to separate 'Additional Email Recipients' in notifications.
 - 2019-07-03 Added improvements for user module regarding the LDAP auth synchronization.
 - 2019-07-01 Fixed bug#[14575](https://bugs.otrs.org/show_bug.cgi?id=14575) - Input field in the FrontendNavigation type in SysConfig has incorrect value when single quotes are used.
 - 2019-06-29 Fixed bug#[14601](https://bugs.otrs.org/show_bug.cgi?id=14601) - Entitlement check message is different in GUI and log.
 - 2019-06-25 Fixed bug#[14606](https://bugs.otrs.org/show_bug.cgi?id=14606) - Values of Activity status and Customer visibility drop-downs are not translated in the Ticket notification screen.

# 6.0.20 2019-07-12
 - 2019-07-01 Improved value masking in tag replacement method.
 - 2019-06-27 Updated translations, thanks to all translators.
 - 2019-06-21 Fixed bug#[14540](https://bugs.otrs.org/show_bug.cgi?id=14540) - Agent interface is broken after update from OTRS 6.0.17 and OTRS 7.0.7.
   In the OTRS 6.0.18 and OTRS 7.0.7, third-party library jquery.jstree.js was updated to 3.3.7. Therefore, default value of the setting Loader::Agent::CommonJS###000-Framework was changed. If adminstrator changed this setting manually, system uses that value instead of the new default. Since this value refers to the wrong path (most likely to the 3.3.4), JavaScript is not loaded properly in the Agent (and Admin) interface.
 - 2019-06-21 Fixed bug#[14578](https://bugs.otrs.org/show_bug.cgi?id=14578) - Login area is out of screen in responsive mode.
 - 2019-06-21 Fixed bug#[14594](https://bugs.otrs.org/show_bug.cgi?id=14594) - New notification screen has English text block although EN is not active and it can not be removed.
 - 2019-06-20 Fixed bug#[14592](https://bugs.otrs.org/show_bug.cgi?id=14592) - Wrong HTML handling of agent names in autocomplete field.
   When some special characters are used (like quotes), autocomplete results might be wrong.
 - 2019-06-19 Fixed bug#[14534](https://bugs.otrs.org/show_bug.cgi?id=14534) - S/MIME certificate relations don't get removed in both directions.
   If we have relation between private key and certificate and then we delete private key, relation is deleted as well. If we delete certificate, relation is not deleted (but this is not visible in the GUI). Afterwards, errors occur when signing emails.
 - 2019-06-19 Fixed bug#[14588](https://bugs.otrs.org/show_bug.cgi?id=14588) - Server side validation breaks process management administration screens.
  There was a problem with JavaScript reinitialisation on screens after server error.
 - 2019-06-18 Fixed bug#[12334](https://bugs.otrs.org/show_bug.cgi?id=12334) - Net::SSLGlue issues warnings on modern systems.
  System will use Net::SSLGlue::SMTP only on systems with older Net::SMTP modules that cannot handle SMTPS.
 - 2019-06-18 Fixed bug#[13727](https://bugs.otrs.org/show_bug.cgi?id=13727) - Admin::Config::Update lacks possibilities to reset / invalidate settings.
   Extended console command Admin::Config::Update, it accepts additional parameters (--reset and --valid).
 - 2019-06-17 Fixed bug#[14585](https://bugs.otrs.org/show_bug.cgi?id=14585) - ArticleLimit parameter causes wrong response of TicketGet web service operation.
   If ArticleLimit is set to 10 for example and we have ticket with 3 articles, web service returns 10 articles (3 regular and 7 empty).
 - 2019-06-17 Fixed bug#[14586](https://bugs.otrs.org/show_bug.cgi?id=14586) - Wrong number of tickets in TicketQueueOverview screen.
 - 2019-06-17 Fixed bug#[14583](https://bugs.otrs.org/show_bug.cgi?id=14583) - The statistics can not be downloaded from the agent dashboard.
 - 2019-06-17 Fixed bug#[14557](https://bugs.otrs.org/show_bug.cgi?id=14557) - Webservice debug log does not honor selected agent timezone.
 - 2019-06-11 Reply-To overwrites name from customer backend, thanks to Georgeto (PR#[1974](https://github.com/OTRS/otrs/pull/1974)).
 - 2019-06-03 Improved session ID handling in templates.
 - 2019-06-03 Fixed bug#[14542](https://bugs.otrs.org/show_bug.cgi?id=14542) - Date values for escalation times are not localized in ticket small overview.
 - 2019-05-31 Added new console command Dev::Code::CPANAudit. It scans the system for installed CPAN modules with known vulnerabilities. This will also be done as part of the update script and in the support data collector. In both cases, possible findings will be shown as warnings, not errors.
 - 2019-05-29 Fixed bug#[14554](https://bugs.otrs.org/show_bug.cgi?id=14554) - Link preview for dynamic fields does not work for date fields in the agent interface.
 - 2019-05-29 Fixed bug#[14419](https://bugs.otrs.org/show_bug.cgi?id=14419) - Resize issue with dashboard stats sidebar widget.
   When dashboard widget is shrinked, graphs are scaling as intended. After extending the widget, graph doesn't extend, it remains shrinked.
 - 2019-05-27 Fixed bug#[14556](https://bugs.otrs.org/show_bug.cgi?id=14556) - CustomerTicketSearch screen adds error log entry when calculating pagination parameters.
 - 2019-05-27 Fixed bug#[14555](https://bugs.otrs.org/show_bug.cgi?id=14555) - Ticket view screens add error log entry (uninitialized value in concatenation).
 - 2019-05-27 Fixed bug#[14478](https://bugs.otrs.org/show_bug.cgi?id=14478) - Wrong console command 'Maint::Ticket::FulltextIndex' description.
   It's not possible to use both parameters at the same time (--status --rebuild) - description was updated.
 - 2019-05-14 Fixed bug#[14488](https://bugs.otrs.org/show_bug.cgi?id=14488) - New note notification is not sent if agent does not have both ro AND note permission on the queue.
   With this fix in place, inform agent selection contains only agents with ro permission.

# 6.0.19 2019-05-31
 - 2019-05-16 Updated translations, thanks to all translators.
 - 2019-05-14 Added Macedonian and Romanian translations.
 - 2019-05-11 Fixed bug#[14491](https://bugs.otrs.org/show_bug.cgi?id=14491) - Ticket::DefineEmailFrom not used for external notes.
   Added new system configuration options `Ticket::Frontend::CustomerTicketZoom###DisplayNoteFrom` and `Ticket::Frontend::CustomerTicketZoom###DefaultAgentName` to define if agent name should be shown in external notes in the customer interface or should use a default generic name instead.
 - 2019-05-10 Fixed bug#[13867](https://bugs.otrs.org/show_bug.cgi?id=13867) - In the process management within TransitionAction,characters < and > are replaced by HTML escape sequences.
 - 2019-05-10 Fixed bug#[14512](https://bugs.otrs.org/show_bug.cgi?id=14512) - If the customer name has some special characters, the name is shown wrong on the answer article.
 - 2019-05-09 Fixed bug#[14398](https://bugs.otrs.org/show_bug.cgi?id=14398) - External images are automatically loaded in forward screen.
   New config named `Ticket::Frontend::BlockLoadingRemoteContent` has been added. It controls if loading of external resources will be blocked, by default it is disabled.
 - 2019-05-09 Fixed bug#[14500](https://bugs.otrs.org/show_bug.cgi?id=14500) - The behaviour of the webservices are not compliant to RFC 4648. After 76 characters we built in a linefeed (/n) which is not RFC compliant.
 - 2019-05-08 Fixed bug#[14532](https://bugs.otrs.org/show_bug.cgi?id=14532) - Wrong comment / documentation for Daemon::SchedulerCronTaskManager::Task###GenericInterfaceDebugLogCleanup in Docs and SystemConfiguration.
 - 2019-05-08 Fixed bug#[14455](https://bugs.otrs.org/show_bug.cgi?id=14455) - OTRS tags '<OTRS_CUSTOMER_DATA_*>' don't work in templates of the type 'Create'.
 - 2019-05-08 Fixed bug#[14514](https://bugs.otrs.org/show_bug.cgi?id=14514) - In the appointment calendar long entries in the team and agent list can be hidden behind the appointment overview window.
 - 2019-05-08 Fixed bug#[14400](https://bugs.otrs.org/show_bug.cgi?id=14400) - Reply adds the same email address for every connected customer user backend.
 - 2019-04-23 Fixed bug#[14509](https://bugs.otrs.org/show_bug.cgi?id=14509) - The agent's notification bar has a wrong URL.
   It was only indicated by IE, since other browsers automatically redirected to the same page.
 - 2019-04-18 Fixed bug#[14504](https://bugs.otrs.org/show_bug.cgi?id=14504) - Queue based ACL does not work for AgentTicketActionCommon based screens.
 - 2019-04-18 Fixed bug#[14482](https://bugs.otrs.org/show_bug.cgi?id=14482) - File upload help text is wrapped and overflows on small resolutions.
 - 2019-04-17 Fixed bug#[14511](https://bugs.otrs.org/show_bug.cgi?id=14511) - Statistic does not work during daylight saving time.
   Fatal error was fixed during generation of statistics based on an unexisting hour, which is lost during the time switch.
 - 2019-04-16 Fixed bug#[14412](https://bugs.otrs.org/show_bug.cgi?id=14412) - CustomerID cannot be changed in ticket action for changing customer.
   Config option `Ticket::Frontend::AgentTicketCustomer::CustomerIDReadOnly` was not honored.
 - 2019-04-16 Fixed bug#[14494](https://bugs.otrs.org/show_bug.cgi?id=14494) - Wrong service selection in ticket search dialog.
   Tree view selection field has been improved to also work in modal dialogs.
 - 2019-04-12 Updated CPAN module Mozilla::CA.
 - 2019-04-04 Fixed bug#[14408](https://bugs.otrs.org/show_bug.cgi?id=14408) - Short description of CustomerID fields is not shown in the process views.

# 6.0.18 2019-04-26
 - 2019-04-02 Updated translations, thanks to all translators.
 - 2019-04-02 Fixed bug#[14055](https://bugs.otrs.org/show_bug.cgi?id=14055) - Translation of "copy" to german in AdminNotificationEvent wrong.
 - 2019-04-01 Made article header expansion state configurable. For this, there is is a new setting `Ticket::Frontend::ArticleHeadVisibleDefault`, which is inactive by default and can be activated to show the article header area expanded by default.
 - 2019-04-01 Fixed bug#[14442](https://bugs.otrs.org/show_bug.cgi?id=14442) - Legacy references to customer interface and public interface.
 - 2019-04-01 Fixed bug#[14345](https://bugs.otrs.org/show_bug.cgi?id=14345) - The timestamp information in the action AdminLog is wrong.
 - 2019-04-01 Fixed bug#[14243](https://bugs.otrs.org/show_bug.cgi?id=14243) - It is possible set system address to invalid even though there is auto response with this address.
 - 2019-03-29 Fixed bug#[14474](https://bugs.otrs.org/show_bug.cgi?id=14474) - Some strings are not translated in Support Data Collector.
 - 2019-03-29 Fixed bug#[14436](https://bugs.otrs.org/show_bug.cgi?id=14436) - Merged cells are not fit to agenda overview table.
 - 2019-03-29 Fixed bug#[14476](https://bugs.otrs.org/show_bug.cgi?id=14476) - Command invalid in 66.1Ticket::SearchIndex::Attribute.
 - 2019-03-29 Fixed bug#[14473](https://bugs.otrs.org/show_bug.cgi?id=14473) - Config Ticket::Frontend::Overview::PreviewArticleSenderTypes does not work.
 - 2019-03-28 Fixed bug#[14461](https://bugs.otrs.org/show_bug.cgi?id=14461) - Can't deactivate TicketMove via ACL in Bulk-Action.
 - 2019-03-28 Fixed bug#[14414](https://bugs.otrs.org/show_bug.cgi?id=14414) - The customer information widget is not update in the view of new ticket on split.
 - 2019-03-26 Fixed bug#[14447](https://bugs.otrs.org/show_bug.cgi?id=14447) - Unnecessary error screen in Bulk action of Queue View.
 - 2019-03-19 Fixed bug#[14462](https://bugs.otrs.org/show_bug.cgi?id=14462) - Missing breadcrumbs in reports and statistics screens.
 - 2019-03-18 Fixed bug#[13540](https://bugs.otrs.org/show_bug.cgi?id=13540) - Not needed time zone output in the ticket list for the configured otrs system time zone.
 - 2019-03-15 Follow-up fix for bug#[14129](https://bugs.otrs.org/show_bug.cgi?id=14129) - Incorrect handling of RootNavigation in AdminSystemConfiguration.
 - 2019-03-04 Fixed bug#[14432](https://bugs.otrs.org/show_bug.cgi?id=14432) - If session is in URL upload of attachments doesn't work.
 - 2019-03-04 Fixed bug#[14242](https://bugs.otrs.org/show_bug.cgi?id=14242) - Appointment Notification Filter 'Calendar' greyed out.
 - 2019-03-01 Fixed bug#[14405](https://bugs.otrs.org/show_bug.cgi?id=14405) - Customers can't login if DER encoded S/MIME certs are fetched.
 - 2019-02-28 Fixed bug#[14245](https://bugs.otrs.org/show_bug.cgi?id=14245) - Expired PGP and S/MIME keys are not shown.
 - 2019-02-26 Fixed bug#[14337](https://bugs.otrs.org/show_bug.cgi?id=14337) - Registration - Can not register system Need Data OSVersion.
 - 2019-02-25 Fixed bug#[14393](https://bugs.otrs.org/show_bug.cgi?id=14393) - TicketUpdate.pm not setting original "To" value.
 - 2019-02-25 Fixed bug#[14424](https://bugs.otrs.org/show_bug.cgi?id=14424) - Wrong invoker sorting when there are more than 9 conditions.
 - 2019-02-25 Fixed bug#[14335](https://bugs.otrs.org/show_bug.cgi?id=14335) - Appointment notification event 'AppointmentDelete' does not contain data of deleted Appointment.

# 6.0.17 2019-03-08
 - 2019-02-21 Fixed bug#[14396](https://bugs.otrs.org/show_bug.cgi?id=14396) - Names are not consistent (mixed singular and plural forms).
 - 2019-02-21 Fixed bug#[14287](https://bugs.otrs.org/show_bug.cgi?id=14287) - Show context setting dialog in ticket overview screens does not support columns with brackets.
 - 2019-02-21 Fixed bug#[11932](https://bugs.otrs.org/show_bug.cgi?id=11932) - OTRS does not handle more than 10 S/MIME certificates per user.
 - 2019-02-21 Fixed bug#[14417](https://bugs.otrs.org/show_bug.cgi?id=14417) - Use of uninitialized value in concatenation.
 - 2019-02-19 Improved console commands Admin::Config::FixInvalid (load setting values from YAML file) and Admin::Config::ListInvalid (export invalid settings to the YAML file).
 - 2019-02-16 Fixed bug#[14411](https://bugs.otrs.org/show_bug.cgi?id=14411) - ACL description Bug causes error.
 - 2019-02-14 Improved SysConfig performance.
 - 2019-02-14 Improved performance of the following console commands:
      Admin::Package::Install
      Admin::Package::Reinstall
      Admin::Package::ReinstallAll
      Admin::Package::Uninstall
      Admin::Package::Upgrade
      Admin::Package::UpgradeAll
      Admin::Package::UpgradeAll
 - 2019-02-13 Updated translations, thanks to all translators.
 - 2019-02-11 Fixed bug#[14391](https://bugs.otrs.org/show_bug.cgi?id=14391) - Log spam when autoreply is sent to unknown customer.
 - 2019-02-11 Fixed bug#[14282](https://bugs.otrs.org/show_bug.cgi?id=14282) - After upgrading from OTRS 5 to 6 some the values of some renamed package settings are not preserved.
 - 2019-02-11 Fixed bug#[14309](https://bugs.otrs.org/show_bug.cgi?id=14309) - ArticleSearchIndexRebuildWorker is not working correctly.
 - 2019-02-08 Fixed bug#[14346](https://bugs.otrs.org/show_bug.cgi?id=14346) - A blank space in the first column of text is either duplicated or removed.
 - 2019-02-04 Fixed bug#[14379](https://bugs.otrs.org/show_bug.cgi?id=14379) - Communication Log - Time Range.
 - 2019-02-01 Fixed bug#[14373](https://bugs.otrs.org/show_bug.cgi?id=14373) - Ticket lock is set even there is no owner set in activity dialog.
 - 2019-01-31 Follow-up fix for bug#[10825](https://bugs.otrs.org/show_bug.cgi?id=10825) - <OTRS_CUSTOMER_Body>  in  Reply-Template.
 - 2019-01-30 Fixed bug#[14329](https://bugs.otrs.org/show_bug.cgi?id=14329) - AppointmentNotification partial title filter.
 - 2019-01-28 Fixed bug#[14370](https://bugs.otrs.org/show_bug.cgi?id=14370) - Article Overview not readable (white text on white ground) with High Contrast Skin.
 - 2019-01-23 Fixed bug#[14363](https://bugs.otrs.org/show_bug.cgi?id=14363) - The regex in ExternalTicketnumberRecognitaion does not match.
 - 2019-01-18 Fixed bug#[14145](https://bugs.otrs.org/show_bug.cgi?id=14145) - s/mime shows first line of encoded message and cert information in <OTRS_CUSTOMER_EMAIL>.
 - 2019-01-17 Further improved handling of JSData in templates.

# 6.0.16 2019-01-18
 - 2019-01-08 Updated translations, thanks to all translators.
 - 2019-01-08 Fixed bug#[14270](https://bugs.otrs.org/show_bug.cgi?id=14270) - Escalation Notification is shown wrong.
 - 2019-01-08 Fixed bug#[14229](https://bugs.otrs.org/show_bug.cgi?id=14229) - Transition Action fails to transfer line breaks of content in dynamic field textarea.
 - 2019-01-07 Add total count of links to "complex" link table, thanks to Frennkie (PR#[1893](https://github.com/OTRS/otrs/pull/1893)).
 - 2019-01-02 Improved performance of the FileStorable cache module by 30%, thanks to Yuri Myasoedov (PR#[1961](https://github.com/OTRS/otrs/pull/1961)).
 - 2018-12-26 Fixed bug#[13930](https://bugs.otrs.org/show_bug.cgi?id=13930) - NotificationOwnerUpdate and TicketOwnerUpdate will not be triggered when a Owner is set in a new process ticket.
 - 2018-12-25 Fixed bug#[14322](https://bugs.otrs.org/show_bug.cgi?id=14322) - Old session is not deleted on SwitchToUser.
 - 2018-12-24 Fixed bug#[14286](https://bugs.otrs.org/show_bug.cgi?id=14286) - Months are missing below the charts in reports.
 - 2018-12-21 Fixed bug#[14245](https://bugs.otrs.org/show_bug.cgi?id=14245) - Expired PGP Keys are not shown.
 - 2018-12-20 Fixed bug#[14311](https://bugs.otrs.org/show_bug.cgi?id=14311) - Appointment widget has wrong colspan if no appointment present.
 - 2018-12-19 Fixed bug#[14157](https://bugs.otrs.org/show_bug.cgi?id=14157) - Edit ACL Screen, Syntax error unrecognised expression '#'.
 - 2018-12-16 Fixed bug#[14305](https://bugs.otrs.org/show_bug.cgi?id=14305) - Incorrect handling of content-type in PictureUpload.
 - 2018-12-14 Set NotificationRecipientEmail setting as non-required, thanks to Yuri Myasoedov (PR#1960).
 - 2018-12-14 Added button which generates shared secret key for two factor authentication (agent interface).
 - 2018-12-14 Fixed bug#[13444](https://bugs.otrs.org/show_bug.cgi?id=13444) - DynamicField Dropdown values are not verified if submitted via web service.
 - 2018-12-12 Fixed bug#[14216](https://bugs.otrs.org/show_bug.cgi?id=14216) - Update Script to OTRS 6 is not cleaning OTRSPostMasterKeepState.
 - 2018-12-12 Fixed bug#[13865](https://bugs.otrs.org/show_bug.cgi?id=13865) - Timezone not respected in Generic Agent, Reports and Autoreply.
 - 2018-12-12 Fixed bug#[14105](http://bugs.otrs.org/show_bug.cgi?id=14105) - SMIME signed messages cause a lot of database errors on customer ticket zoom, thanks to Renee Bäcker.
 - 2018-12-11 Fixed bug#[14259](https://bugs.otrs.org/show_bug.cgi?id=14259) - Config Rebuild locking issue on cluster nodes.
 - 2018-12-10 Fixed bug#[14221](https://bugs.otrs.org/show_bug.cgi?id=14221) - Ticket notification with ArticleSend event leads into deep recursion.
 - 2018-12-10 Fixed bug#[14262](https://bugs.otrs.org/show_bug.cgi?id=14262) - Untranslated string and wrong charset in package manager notification.
 - 2018-12-06 Fixed bug#[14282](https://bugs.otrs.org/show_bug.cgi?id=14282) - After upgrading from OTRS 5 to 6 some the values of some renamed package settings are not preserved.
 - 2018-12-06 Fixed bug#[14165](https://bugs.otrs.org/show_bug.cgi?id=14165) - Article's style of plain text is wrong in AgentTicketZoom.

# 6.0.15 2018-12-14
 - 2018-12-06 Updated translations, thanks to all translators.
 - 2018-12-05 Added possibility to display links in footer section of customer and public interface.
 - 2018-12-05 Fixed bug#[14106](https://bugs.otrs.org/show_bug.cgi?id=14106) - XSLT Editor breaks.
 - 2018-11-27 Use scale in transforamtion for Notification item on hover, thanks to Andrew Bone (PR#1958).
 - 2018-11-27 Fixed bug#[13829](https://bugs.otrs.org/show_bug.cgi?id=13829) - Internal server error when Z time is used in RSS-Feed.
 - 2018-11-22 Fixed bug#[14227](https://bugs.otrs.org/show_bug.cgi?id=14227) - Passing an empty arrayref in 'TicketID' to ticket-search, results in invalid SQL statement.
 - 2018-11-21 Improved SysConfig caching, rebuilding SysConfig is up to 50% faster.
 - 2018-11-21 Follow-up fix for bug#[14154](https://bugs.otrs.org/show_bug.cgi?id=14154) - After migration, configuration deployment does not work due to the invalid setting value.
 - 2018-11-21 Fixed bug#[14229](https://bugs.otrs.org/show_bug.cgi?id=14229) - Transition Action  fails to transfer line breaks of content in dynamic field textarea.
 - 2018-11-20 Fixed bug#[14237](https://bugs.otrs.org/show_bug.cgi?id=14237) - Sorting of state menu entries is different then order in state overview screen.
 - 2018-11-19 Fixed bug#[14148](https://bugs.otrs.org/show_bug.cgi?id=14148) - Superfluous filter boxes and "Add Group" form in Group Management screen.
 - 2018-11-19 Fixed bug#[14197](https://bugs.otrs.org/show_bug.cgi?id=14197) - Missing confirmation dialog when deleting a generic agent job.
 - 2018-11-15 Fixed bug#[14209](https://bugs.otrs.org/show_bug.cgi?id=14209) - System maintenance 'Kill all Sessions, except for your own' button is too big and aligned right.
 - 2018-11-15 Fixed bug#[14226](https://bugs.otrs.org/show_bug.cgi?id=14226) - It is not possible to deselect queue in AgentTicketBulk after AJAX update.
 - 2018-11-15 Fixed bug#[14195](https://bugs.otrs.org/show_bug.cgi?id=14195) - False positive in Bounce Detection if eml attachment present.
 - 2018-11-08 Follow-up fix for bug#[14154](https://bugs.otrs.org/show_bug.cgi?id=14154) - After migration, configuration deployment does not work due to the invalid setting value.
 - 2018-11-05 Fixed bug#[14201](https://bugs.otrs.org/show_bug.cgi?id=14201) - backup.pl - dump errors are not detected.
 - 2018-11-05 Fixed bug#[14063](https://bugs.otrs.org/show_bug.cgi?id=14063) - CustomerUserNameFields not used.

# 6.0.14 2018-11-14
 - 2018-11-13 Follow-up fix for bug#[13978](https://bugs.otrs.org/show_bug.cgi?id=13978) - User and customer preferences may override user data.

# 6.0.13 2018-11-09
 - 2018-11-01 Updated translations, thanks to all translators.
 - 2018-11-01 Fixed: TicketSolutionResponseTime stats leads to internal server error (bug#14167).
 - 2018-11-01 Fixed bug#[14140](https://bugs.otrs.org/show_bug.cgi?id=14140) - Missing confirmation dialog when deleting a PGP key.
 - 2018-10-31 Added option to hide deployment info to Admin::Package::ReinstallAll console command.
 - 2018-10-31 Fixed bug#[14154](https://bugs.otrs.org/show_bug.cgi?id=14154) - After migration, configuration deployment does not work due to the invalid setting value.
 - 2018-10-29 Follow-up fix for bug#[13978](https://bugs.otrs.org/show_bug.cgi?id=13978) - User and customer preferences may override user data.
 - 2018-10-26 Follow-up fix for bug#[14132](https://bugs.otrs.org/show_bug.cgi?id=14132) - After select a sub-queue the queue's field is break in the bulk window.
 - 2018-10-26 Fixed bug#[14132](https://bugs.otrs.org/show_bug.cgi?id=14132) - After select a sub-queue the queue's field is break in the bulk window.
 - 2018-10-26 Fixed bug#[14131](https://bugs.otrs.org/show_bug.cgi?id=14131) - Missing Default Sign key field description in AdminQueue.
 - 2018-10-26 Fixed bug#[14112](https://bugs.otrs.org/show_bug.cgi?id=14112) - Inconsistent layouts for Attachments-Templates and Auto Responses-Queues screens.
 - 2018-10-26 Fixed bug#[14119](https://bugs.otrs.org/show_bug.cgi?id=14119) - WSDL File is incorrect.
 - 2018-10-25 Fixed bug#[13967](https://bugs.otrs.org/show_bug.cgi?id=13967) - Translation not working in AgentTicketMerge.
 - 2018-10-25 Follow-up fix for bug#[13968](https://bugs.otrs.org/show_bug.cgi?id=13968) - Attachments with spaces in file name does not work properly.
 - 2018-10-23 Fixed bug#[11107](https://bugs.otrs.org/show_bug.cgi?id=11107) - ACL does not work properly in AgentTicketMove screen.
 - 2018-10-23 Fixed bug#[13847](https://bugs.otrs.org/show_bug.cgi?id=13847) - Reset setting in AdminSystemConfiguration does not work correctly.
 - 2018-10-23 Fixed missing content during package installation with disabled cloud services.
 - 2018-10-22 Fixed bug#[14054](https://bugs.otrs.org/show_bug.cgi?id=14054) - Setting AppointmentCalendar::CalendarLimitOverview not working correctly.
 - 2018-10-22 Fixed bug#[14137](https://bugs.otrs.org/show_bug.cgi?id=14137) - Error occurs when item is removed from the frontend configuration.
 - 2018-10-11 Fixed bug#[14129](https://bugs.otrs.org/show_bug.cgi?id=14129) - Incorrect handling of RootNavigation in AdminSystemConfiguration.
 - 2018-10-16 Fixed bug#[14079](https://bugs.otrs.org/show_bug.cgi?id=14079) - Cancel and Close button are not visible.
 - 2018-10-09 Follow-up fix for bug#[13928](https://bugs.otrs.org/show_bug.cgi?id=13928) - Assigning customer group to chat modules results in constant connection error messages.
 - 2018-10-09 Improved upload cache module.
 - 2018-10-03 Fixed bug#[14107](https://bugs.otrs.org/show_bug.cgi?id=14107) - IfNotPackage property in <Database\*> tag is not honored during Package Install for Installed packages.

# 6.0.12 2018-10-05
 - 2018-09-27 Updated translations, thanks to all translators.
 - 2018-09-27 Added Korean language, thanks to 신홍열.
 - 2018-09-27 Fixed bug#[13623](https://bugs.otrs.org/show_bug.cgi?id=13623) - Long running DBUpgrade from OTRS 5 to OTRS 6 due to inefficient SQL queries.
 - 2018-09-25 Fixed bug#[13754](https://bugs.otrs.org/show_bug.cgi?id=13754) - Overridden module configuration lost after update.
 - 2018-09-25 Fixed bug#[14022](https://bugs.otrs.org/show_bug.cgi?id=14022) - Parsing Error System Configuration.
 - 2018-09-24 Fixed bug#[14077](https://bugs.otrs.org/show_bug.cgi?id=14077) - Logged-in Users Dashlet missing css.
 - 2018-09-19 Fixed bug#[14072](https://bugs.otrs.org/show_bug.cgi?id=14072) - Type activation warning disappears after new type is added.
 - 2018-09-18 Improved handling of JSData in Templates.

# 6.0.11 2018-09-21
 - 2018-09-13 Updated translations, thanks to all translators.
 - 2018-09-11 Fixed bug#[13990](https://bugs.otrs.org/show_bug.cgi?id=13990) - Process Management issue when splitting tickets to Process tickets.
 - 2018-09-11 Fixed bug#[14023](https://bugs.otrs.org/show_bug.cgi?id=14023) - Timeline View is broken when a body string contains closing script tag.
 - 2018-09-10 Fixed bug#[14057](https://bugs.otrs.org/show_bug.cgi?id=14057) - UserInitialsGet ignores FirstnameLastnameOrder.
 - 2018-09-07 Fixed bug#[14052](https://bugs.otrs.org/show_bug.cgi?id=14052) - Reason param in LogoutURL sys config items makes error.
 - 2018-09-05 Follow-up fix for bug#[13968](https://bugs.otrs.org/show_bug.cgi?id=13968) - Attachments with spaces in file name does not work properly.
 - 2018-09-04 Fixed bug#[14044](https://bugs.otrs.org/show_bug.cgi?id=14044) - DefaultOverviewColumns and DefaultColumns configurations are inconsistent.
 - 2018-08-30 Fixed bug#[14030](https://bugs.otrs.org/show_bug.cgi?id=14030) - Values of the type field are translated in the bulk view.
 - 2018-08-29 Fixed bug#[13903](https://bugs.otrs.org/show_bug.cgi?id=13903) - Setting an invalid sender-type will crash mail processing.
 - 2018-08-29 Fixed bug#[14045](https://bugs.otrs.org/show_bug.cgi?id=14045) - Error creating DateTime object for pending time in Process ticket.
 - 2018-08-28 Fixed bug#[14039](https://bugs.otrs.org/show_bug.cgi?id=14039) - Filter in admin panel ignores category titles.
 - 2018-08-27 Fixed bug#[14025](https://bugs.otrs.org/show_bug.cgi?id=14025) - backup.pl may delete a backup it just created.
 - 2018-08-27 Fixed bug#[13767](https://bugs.otrs.org/show_bug.cgi?id=13767) - Search result wrong displayed when there is only one result in IE 11.
 - 2018-08-17 Fixed bug#[13987](https://bugs.otrs.org/show_bug.cgi?id=13987) - The value typed in e.g. customer user is deleted frequently, if already one customer user is selected.
 - 2018-08-17 Fixed bug#[13957](https://bugs.otrs.org/show_bug.cgi?id=13957) - POP3 fetching mails in wrong order.
 - 2018-08-15 Fixed bug#[13614](https://bugs.otrs.org/show_bug.cgi?id=13614) - Title is shown based on the first article in customer ticket overview even if the first article is marked as not visible for customer.
 - 2018-08-15 Fixed bug#[14011](https://bugs.otrs.org/show_bug.cgi?id=14011) - 'Backspace' key returns to previous page in modernize field selection.
 - 2018-08-15 Fixed bug#[14014](https://bugs.otrs.org/show_bug.cgi?id=14014) - Missing attachments created in process ticket articles.
 - 2018-08-10 Fixed bug#[14006](https://bugs.otrs.org/show_bug.cgi?id=14006) - TicketOverview does not show last visible for customer article for process ticket.
 - 2018-08-09 Fixed bug#[14004](https://bugs.otrs.org/show_bug.cgi?id=14004) - Packages are only accessible via HTTP instead of HTTPS.
 - 2018-08-08 Fixed bug#[14003](https://bugs.otrs.org/show_bug.cgi?id=14003) - Not possible to add more conditions on process transition edit which has more then 10 conditions.
 - 2018-08-08 Fixed bug#[14009](https://bugs.otrs.org/show_bug.cgi?id=14009) - Wrong description for RedirectAfterCloseDisabled configuration.
 - 2018-08-07 Fixed bug#[14008](https://bugs.otrs.org/show_bug.cgi?id=14008) - Kernel::System::VariableCheck::DataIsDifferent() does not work if one data element is undefined.
 - 2018-08-07 Fixed bug#[13968](https://bugs.otrs.org/show_bug.cgi?id=13968) - Attachments with spaces in file name does not work properly.
 - 2018-08-07 Follow-up fix for bug#[13597](https://bugs.otrs.org/show_bug.cgi?id=13597) - In case of OTRS 6 Upgrade "Email Delivery Failure" notification message is incorrectly displayed.
 - 2018-09-04 Added improvements to HTML filter.
 - 2018-09-03 Added improvements to SupportDataCollector Admin screen.
 - 2018-08-02 Fixed bug#[13997](https://bugs.otrs.org/show_bug.cgi?id=13997) - Error in pattern matching for DiskSpacePartitions.
 - 2018-08-02 Fixed bug#[13995](https://bugs.otrs.org/show_bug.cgi?id=13995) - Ticket attributes are not working in ResponseFormat.
 - 2018-08-02 Fixed bug#[13993](https://bugs.otrs.org/show_bug.cgi?id=13993) - Misleading breadcrumb path in AgentPreferences screen.
 - 2018-08-01 Follow-up fix for bug#[13805](https://bugs.otrs.org/show_bug.cgi?id=13805) - Distribution OpenBSD is not recognized by support data collector.
 - 2018-08-01 Follow-up fix for bug#[13643](https://bugs.otrs.org/show_bug.cgi?id=13643) - After CustomerCompanySupport is disabled the customer-user cannot be defined at several places.
 - 2018-08-01 Fixed bug#[13983](https://bugs.otrs.org/show_bug.cgi?id=13983) - Default process ticket title time stamp does not show appropriate time zone value.
 - 2018-08-01 Fixed bug#[13988](https://bugs.otrs.org/show_bug.cgi?id=13988) - The Hungarian subsidiary is missing form the first page of the installer.
 - 2018-08-01 Fixed bug#[13986](https://bugs.otrs.org/show_bug.cgi?id=13986) - UserSearch function does not work for login with upper-case letters on case sensitive databases.
 - 2018-08-01 Fixed bug#[13981](https://bugs.otrs.org/show_bug.cgi?id=13981) - CustomerID change popup window can not be shown in AgentTicketProcess screen.
 - 2018-07-25 Fixed bug#[13972](https://bugs.otrs.org/show_bug.cgi?id=13972) - API documentation: missing default permission types 'note' and 'owner'.

# 6.0.10 2018-07-31
 - 2018-07-24 Updated translations, thanks to all translators.
 - 2018-07-24 Add explicit information for robots.
 - 2018-07-23 Fixed bug#[13978](https://bugs.otrs.org/show_bug.cgi?id=13978) - User and customer preferences may override user data.
 - 2018-07-23 Pay attention to accounted time when splitting an article into a ticket (PR#1938).
 - 2018-07-19 Fixed bug#[13662](https://bugs.otrs.org/show_bug.cgi?id=13662) - Missing white space between article details and transmission processing message.
 - 2018-07-19 Fixed bug#[13971](https://bugs.otrs.org/show_bug.cgi?id=13971) - DBUpdate fails on galera cluster.
 - 2018-07-17 Fixed bug#[13722](https://bugs.otrs.org/show_bug.cgi?id=13722) - Translation of ticket notification header uses the system language instead of recipients preferences.

# 6.0.9 2018-07-24
 - 2018-07-16 Updated translations, thanks to all translators.
 - 2018-07-16 Fixed bug#[13961](https://bugs.otrs.org/show_bug.cgi?id=13961) - ExternalTicketNumberRecognition not working correctly with spaces.
 - 2018-07-16 Fixed bug#[13964](https://bugs.otrs.org/show_bug.cgi?id=13964) - System configuration value validation error displayed for disabled settings.
 - 2018-07-16 Fixed bug#[13965](https://bugs.otrs.org/show_bug.cgi?id=13965) - Overridden SysConfig settings can be shown as disabled in the frontend.
 - 2018-07-11 Fixed bug#[13952](https://bugs.otrs.org/show_bug.cgi?id=13952) - Internal server error in AdminSystemConfiguration if you remove frontend registration and navigation modules.
 - 2018-07-10 Fixed bug#[13947](https://bugs.otrs.org/show_bug.cgi?id=13947) - Split selection dialog does not honor ACL restrictions.
 - 2018-07-06 Fixed bug#[13928](https://bugs.otrs.org/show_bug.cgi?id=13928) - Assigning customer group to chat modules results in constant connection error messages.
 - 2018-07-06 Fixed bug#[13948](https://bugs.otrs.org/show_bug.cgi?id=13948) - Some labels are not translated in ticket search screen.
 - 2018-07-06 Fixed bug#[13940](https://bugs.otrs.org/show_bug.cgi?id=13940) - Index missing on table article_data_mime.
 - 2018-07-06 Fixed bug#[13936](https://bugs.otrs.org/show_bug.cgi?id=13936) - Notification looses text for 'Additional recipient email addresses' when sizelimit 200 characters is exceeded.
 - 2018-07-05 Fixed bug#[13837](https://bugs.otrs.org/show_bug.cgi?id=13837) - Open and new tickets always at the end of the list when sorting by pending time since OTRS 6.
 - 2018-07-05 Fixed bug#[13943](https://bugs.otrs.org/show_bug.cgi?id=13943) - Untranslated word "last-search" in ticket search result screen.
 - 2018-07-05 Fixed bug#[13945](https://bugs.otrs.org/show_bug.cgi?id=13945) - Archived tickets won't be moved with StorageSwitch command.
 - 2018-07-04 Fixed bug#[13938](https://bugs.otrs.org/show_bug.cgi?id=13938) - Statistic: Internal Server Error when invalid date is set for x axis.
 - 2018-07-04 Fixed bug#[13937](https://bugs.otrs.org/show_bug.cgi?id=13937) - Default value for title is not displayed as default in Process Activity Dialog if field is shown.
 - 2018-07-02 Fixed bug#[13942](https://bugs.otrs.org/show_bug.cgi?id=13942) - Wrong title in browser window in statistics screens.
 - 2018-07-02 Fixed bug#[13901](https://bugs.otrs.org/show_bug.cgi?id=13901) - Error messages during RPM upgrade.
 - 2018-07-02 Fixed bug#[13790](https://bugs.otrs.org/show_bug.cgi?id=13790) - Toolbar Fulltext Search will not care for archiving settings.
 - 2018-06-27 Fixed bug#[13927](https://bugs.otrs.org/show_bug.cgi?id=13927) - Ticket Merge: "No merge state found! Please add a valid merge state" - Articles are invisible till next action.
 - 2018-06-27 Fixed bug#[13922](https://bugs.otrs.org/show_bug.cgi?id=13922) - SearchIndexModule misleading config description.
 - 2018-06-27 Fixed bug#[13700](https://bugs.otrs.org/show_bug.cgi?id=13700) - Layout issue with ticket split.
 - 2018-06-27 Fixed bug#[13839](https://bugs.otrs.org/show_bug.cgi?id=13839) - When doing a search from change management the results window does not expand.
 - 2018-06-27 Fixed bug#[13672](https://bugs.otrs.org/show_bug.cgi?id=13672) - Auto response names are not translated in Auto Responses screen of the Admin interface.
 - 2018-06-25 Fixed bug#[13919](https://bugs.otrs.org/show_bug.cgi?id=13919) - Adding a new favorite setting overwrites the existing favorite settings.
 - 2018-06-25 Fixed bug#[13923](https://bugs.otrs.org/show_bug.cgi?id=13923) - Sender name in article created by queue move "window" only shows FirstName.
 - 2018-06-20 Follow-up fix for bug#[13734](https://bugs.otrs.org/show_bug.cgi?id=13734) - Set the last valid Status Merge to invalid is allowed.
 - 2018-06-19 Fixed bug#[13408](https://bugs.otrs.org/show_bug.cgi?id=13408) - Setting for showing default fields in the search mask not working partially.
 - 2018-06-19 Fixed bug#[13906](https://bugs.otrs.org/show_bug.cgi?id=13906) - Validation for Pending date is active for non pending states.
 - 2018-06-18 Fixed bug#[13778](https://bugs.otrs.org/show_bug.cgi?id=13778) - otrs.Console.pl Admin::Package::UpgradeAll fails at installed ITSM package.
 - 2018-06-18 Fixed bug#[13894](https://bugs.otrs.org/show_bug.cgi?id=13894) - System log does not present timezone information.
 - 2018-06-18 Fixed bug#[13752](https://bugs.otrs.org/show_bug.cgi?id=13752) - Missing direction arrow for AgentTicketEmailOutbound.
 - 2018-06-15 Fixed bug#[13912](https://bugs.otrs.org/show_bug.cgi?id=13912) - Generic Agents looses text for notes when sizelimit 200 characters is exceeded.
 - 2018-06-15 Fixed bug#[13775](https://bugs.otrs.org/show_bug.cgi?id=13775) - ArticleLimit is not integrated for GenericInterface TicketGet.
 - 2018-06-15 Fixed bug#[13910](https://bugs.otrs.org/show_bug.cgi?id=13910) - LinkObject events are not working in web services due to missing LinkObject::EventModulePost configuration.
 - 2018-06-14 Fixed bug#[13913](https://bugs.otrs.org/show_bug.cgi?id=13913)(PR#1936) - Searchable Article Fields not translated in AgentTicketSearch. Thanks to Robin.
 - 2018-06-14 Fixed bug#[13838](https://bugs.otrs.org/show_bug.cgi?id=13838) - WarnOnStopWordUsage not working for subject, body, from, to, cc.
 - 2018-06-14 Fixed bug#[13893](https://bugs.otrs.org/show_bug.cgi?id=13893) - Wrong descriptions for some system configurations.
 - 2018-06-14 Fixed bug#[12479](https://bugs.otrs.org/show_bug.cgi?id=12479) - Reply to a ticket locks the ticket and cancel unlocks it but does not reset owner.
 - 2018-06-12 Fixed bug#[13902](https://bugs.otrs.org/show_bug.cgi?id=13902) - Dialog submit is not possible for an appointment created by rule based on pending time.
 - 2018-06-12 Fixed bug#[13888](https://bugs.otrs.org/show_bug.cgi?id=13888) - Wrong charset in output while upgrading packages.
 - 2018-06-07 Enhanced package manager:
   - Not verified packages can't be installed by default (via GUI + OTRS console).
   - Added sysconfig setting 'Package::AllowNotVerifiedPackages' to allow installation of not verified packages (disabled by default).
   - Display a notification if setting 'Package::AllowNotVerifiedPackages' is active.
 - 2018-06-07 Fixed bug#[13842](https://bugs.otrs.org/show_bug.cgi?id=13842) - When splitting a ticket, the picture embedded in the letter body is not displayed in the child ticket.
 - 2018-06-07 Added improvements to the support data collector plugins.
 - 2018-06-06 Fixed bug#[13873](https://bugs.otrs.org/show_bug.cgi?id=13873) - Wrong descripton for TicketNumberCounterCleanup setting in System Configuration.
 - 2018-06-05 Fixed bug#[13900](https://bugs.otrs.org/show_bug.cgi?id=13900) - Password authentication issue in Fedora 28 operating system.

# 6.0.8 2018-06-12
 - 2018-06-04 Updated translations, thanks to all translators.
 - 2018-06-02 Fixed bug#[13728](https://bugs.otrs.org/show_bug.cgi?id=13728) - Processes need to be deployed after update to Version 6.
 - 2018-06-01 Fixed bug#[13824](https://bugs.otrs.org/show_bug.cgi?id=13824) - Search conditions in AdminProcessManagement are resetted.
 - 2018-06-01 Fixed bug#[13880](https://bugs.otrs.org/show_bug.cgi?id=13880) - "Customer user" field is cleared once the focus is lost in AgentTicketCustomer.
 - 2018-06-01 Fixed bug#[13889](https://bugs.otrs.org/show_bug.cgi?id=13889) - Postmaster filter value limit is 100 characters in frontend.
 - 2018-06-01 Renamed 'OTRS Free' to '((OTRS)) Community Edition'.
 - 2018-05-30 Fixed bug#[13868](https://bugs.otrs.org/show_bug.cgi?id=13868) - Customer User Title is not translated.
 - 2018-05-29 Fixed bug#[13879](https://bugs.otrs.org/show_bug.cgi?id=13879) - IFRAME in customer ticket zoom loading the content outside of itself.
 - 2018-05-28 Fixed bug#[13870](https://bugs.otrs.org/show_bug.cgi?id=13870) - Content of Title and Subject columns are the same in Excel/CSV output of search.
 - 2018-05-28 Fixed bug#[13819](https://bugs.otrs.org/show_bug.cgi?id=13819) - ACL's CompareMatchWithData floods the log when service is not in relation with customer user.
 - 2018-05-25 Fixed bug#[13883](https://bugs.otrs.org/show_bug.cgi?id=13883) - Several display issues in Admin Screen "Ticket Notification Management".
 - 2018-05-25 Fixed bug#[13826](https://bugs.otrs.org/show_bug.cgi?id=13142) - Error The given param 'QueueIDs' is invalid or an empty array reference.
 - 2018-05-23 Fixed bug#[13826](https://bugs.otrs.org/show_bug.cgi?id=13826) - Queue Names are translated (but should not).
 - 2018-05-18 Fixed bug#[13869](https://bugs.otrs.org/show_bug.cgi?id=13869) - Unexpected shadow in long Sysconfig entry.
 - 2018-05-16 Fixed bug#[13820](https://bugs.otrs.org/show_bug.cgi?id=13820) - Wrong UserID argument in AdminAppointmentNotificationEvent.
 - 2018-05-14 Fixed bug#[13827](https://bugs.otrs.org/show_bug.cgi?id=13827) - GenericInterface EventTrigger does not consider Asynchronous parameter during creation.
 - 2018-05-11 Fixed bug#[13732](https://bugs.otrs.org/show_bug.cgi?id=13732) - For mails with inline images and little text, the display area remains very small.
 - 2018-05-11 Fixed bug#[13821](https://bugs.otrs.org/show_bug.cgi?id=13821) - CustomerUserListFields: search result create a wrong entry.
 - 2018-05-10 Fixed bug#[13846](https://bugs.otrs.org/show_bug.cgi?id=13846) - Ticket invoker base module does not use modernized fields.
 - 2018-05-10 Fixed bug#[13795](https://bugs.otrs.org/show_bug.cgi?id=13795) - Transition Action 'TicketTitleSet': Tag of a dyn. field type 'date' display the time, too.
 - 2018-05-10 Fixed bug#[13850](https://bugs.otrs.org/show_bug.cgi?id=13850) - Problems with overridden SysConfig settings.
 - 2018-05-10 Follow-up fix for bug#[7988](https://bugs.otrs.org/show_bug.cgi?id=7988) - Search attributes not consistent.
 - 2018-05-10 Fixed bug#[12864](https://bugs.otrs.org/show_bug.cgi?id=12864) - Hang in my_readline.
 - 2018-05-10 Fixed bug#[13855](https://bugs.otrs.org/show_bug.cgi?id=13855) - Some migration modules will be executed with every DBUpdate-to-6.pl run.
 - 2018-05-08 Fixed bug#[12686](https://bugs.otrs.org/show_bug.cgi?id=12686) - Wrong sorting order in the admin screen.
 - 2018-05-08 Fixed bug#[13836](https://bugs.otrs.org/show_bug.cgi?id=13836) - Filter in timeline view not being applied.
 - 2018-05-08 Fixed bug#[12994](https://bugs.otrs.org/show_bug.cgi?id=12994) - Merge Tickets with same linked objects causes error.
 - 2018-05-07 Fixed bug#[13818](https://bugs.otrs.org/show_bug.cgi?id=13818) - Dynamic field values of tickets are not displayed in customer ticket search result.
 - 2018-04-30 Changed default gravatar image for articles to 'mm' (mystery man).
 - 2018-04-25 Fixed bug#[13764](https://bugs.otrs.org/show_bug.cgi?id=13764) - Mixed up plain and rich text body in process management when article is created.
 - 2018-04-25 Fixed bug#[13815](https://bugs.otrs.org/show_bug.cgi?id=13815) - The little arrow is cut off for articles.
 - 2018-04-24 Fixed bug#[13805](https://bugs.otrs.org/show_bug.cgi?id=13805) - Distribution OpenBSD is not recognized by support data collector.
 - 2018-04-18 Fixed bug#[11132](https://bugs.otrs.org/show_bug.cgi?id=11132) - Loss of attached files with long Cyrillic names.

# 6.0.7 2018-05-04
 - 2018-04-23 Updated translations, thanks to all translators.
 - 2018-04-23 Fixed bug#[13784](https://bugs.otrs.org/show_bug.cgi?id=13784) - Duplicated entry dialog button is not clickable for the same recipient.
 - 2018-04-18 Fixed bug#[13797](https://bugs.otrs.org/show_bug.cgi?id=13797) - Wrong URL for SecureMode in AdminSecureMode.tt.
 - 2018-04-18 Fixed bug#[13554](https://bugs.otrs.org/show_bug.cgi?id=13554) - Non-allowed characters in attachment file names.
 - 2018-04-18 Follow-up fix for bug#[13676](https://bugs.otrs.org/show_bug.cgi?id=13676) - Column headers and tooltips are not translated.
 - 2018-04-17 Fixed bug#[13765](https://bugs.otrs.org/show_bug.cgi?id=13765) - Line numbers given in tags like <OTRS_AGENT_Body[50]> are not working.
 - 2018-04-17 Fixed bug#[13785](https://bugs.otrs.org/show_bug.cgi?id=13785) - When an article contains a longer subject the creation date is cut off in all article view.
 - 2018-04-17 Re-added plugin to open links in CKEditor.
 - 2018-04-17 Fixed bug#[13794](https://bugs.otrs.org/show_bug.cgi?id=13794) - Missleading label that customer can be recipient of notifications as group recipient.
 - 2018-04-13 Fixed bug#[13801](https://bugs.otrs.org/show_bug.cgi?id=13801) - Preview of internal article is shown to customer in ticket overview screen.
 - 2018-04-11 Fixed bug#[13782](https://bugs.otrs.org/show_bug.cgi?id=13782) - Set of customer dynamic field not possible while adding a customer user if AutoLoginCreation is active.
 - 2018-04-05 Fixed bug#[13126](https://bugs.otrs.org/show_bug.cgi?id=13126) - Process first activity cannot be changed to other activity.
 - 2018-04-04 Fixed bug#[13735](https://bugs.otrs.org/show_bug.cgi?id=13735) - Custom Logo is not supported for High Contrast skin.
 - 2018-04-04 Fixed bug#[13683](https://bugs.otrs.org/show_bug.cgi?id=13683) - Generic Agent Mail Filtering.
 - 2018-04-03 Follow-up fix for bug#[13292](https://bugs.otrs.org/show_bug.cgi?id=13292) - Internal Server Error in ticket screens with missing articles in the file system.
 - 2018-04-02 Fixed bug#[13780](https://bugs.otrs.org/show_bug.cgi?id=13780) - Daemon does not recognize ACL or ProcessManagement changes.
 - 2018-03-29 Fixed bug#[13759](https://bugs.otrs.org/show_bug.cgi?id=13759) - Split Ticket - OTRS wants to close browser tab in IE11.
 - 2018-03-29 Fixed bug#[13750](https://bugs.otrs.org/show_bug.cgi?id=13750) - Process Widget Group not Translatable.
 - 2018-03-29 Fixed bug#[13737](https://bugs.otrs.org/show_bug.cgi?id=13737) - Not possible to add valid services to invalid parents when KeepChildren config is enabled.
 - 2018-03-29 Fixed bug#[13739](https://bugs.otrs.org/show_bug.cgi?id=13739) - Wrong Sysconfig descriptions for public interface.
 - 2018-03-29 Fixed bug#[13734](https://bugs.otrs.org/show_bug.cgi?id=13734) - Set the last valid Status Merge to invalid is allowed.
 - 2018-03-27 Fixed bug#[13462](https://bugs.otrs.org/show_bug.cgi?id=13462) - OTRS creates empty Kernel/Config/Files/User/\*.pm files.
 - 2018-03-27 Fixed bug#[13717](https://bugs.otrs.org/show_bug.cgi?id=13717) - AgentTicketService can slow down a system, when having many services and many agents working on there.
 - 2018-03-26 Fixed bug#[10709](https://bugs.otrs.org/show_bug.cgi?id=10709) - ACL for Action AgentTicketBulk are inconsistent.
 - 2018-03-19 Fixed bug#[5562](https://bugs.otrs.org/show_bug.cgi?id=5562) - Options configured in Sysconfig aren't used untill a restart of OTRS when deployed on FastCGI.
 - 2018-03-19 Fixed bug#[13711](https://bugs.otrs.org/show_bug.cgi?id=13711) - Multiple GenericInterface default Invoker and Operation frontend issues.
 - 2018-03-16 Follow-up fix for bug#[13164](https://bugs.otrs.org/show_bug.cgi?id=13164) - Certain AJAX Error Types are still unprocessed.
 - 2018-03-13 Fixed bug#[13710](https://bugs.otrs.org/show_bug.cgi?id=13710) - Maint::WebUploadCache::Cleanup fails if files are in folder upload_cache.
 - 2018-03-12 Fixed bug#[13537](https://bugs.otrs.org/show_bug.cgi?id=13537) - Changing customer user doesn't update the Customer Information box.
 - 2018-03-09 Fixed bug#[13723](https://bugs.otrs.org/show_bug.cgi?id=13723) - Wrong navigation group for Ticket::Frontend::CustomerTicketProcess###StateType.
 - 2018-03-09 Fixed bug#[13718](https://bugs.otrs.org/show_bug.cgi?id=13718) - CacheTTLLocal setting for the TicketQueueOverview Dashboard Widget is not used.
 - 2018-03-09 Fixed bug#[13702](https://bugs.otrs.org/show_bug.cgi?id=13702) - Complex LinkObject Table configuration is broken when more than one kind if object is linked.
 - 2018-03-09 Fixed bug#[13578](https://bugs.otrs.org/show_bug.cgi?id=13578) - Untranslated words in Support Data Collector.
 - 2018-03-08 Fixed bug#[13673](https://bugs.otrs.org/show_bug.cgi?id=13673)(PR#1899) - Mandatory fields are not marked as mandatory. Thanks to Balazs Ur.
 - 2018-03-08 Fixed bug#[7988](https://bugs.otrs.org/show_bug.cgi?id=7988) - Search attributes not consistent.
 - 2018-03-07 Fixed bug#[13693](https://bugs.otrs.org/show_bug.cgi?id=13693) - Email causes deadlock in Maint::Postmaster::Read.

# 6.0.6 2018-03-13
 - 2018-03-05 Updated translations, thanks to all translators.
 - 2018-03-05 Fixed bug#[13713](https://bugs.otrs.org/show_bug.cgi?id=13713) - Dashboard widget 'Appointments' ignores user specific time zone on output.
 - 2018-03-05 Fixed bug#[13709](https://bugs.otrs.org/show_bug.cgi?id=13709) - SupportDataCollector causes Internal Server Error.
 - 2018-03-05 Fixed bug#[13708](https://bugs.otrs.org/show_bug.cgi?id=13708) - GenericInterface article EventFilter does not work with ticket data.
 - 2018-03-05 Fixed Allow array as top-level-XML-Element on REST Response from remote site, thanks to Andreas Hergert (PR#1905).
 - 2018-03-05 Fixed bug#[13549](https://bugs.otrs.org/show_bug.cgi?id=13549) - Scrolling not possible for some articles on iOS Safari.
 - 2018-03-02 Added improvements for the time zone migration script in non interactive mode.
 - 2018-03-01 Reduced warnings thrown by Layout object when BuildSelection is used with TreeView option.
 - 2018-03-01 Fixed bug#[13703](https://bugs.otrs.org/show_bug.cgi?id=13703) - Complex LinkObject Table broken after successful configuration.
 - 2018-03-01 Fixed bug#[13687](https://bugs.otrs.org/show_bug.cgi?id=13687) - CustomerIDRaw parameter is empty in Customer View.
 - 2018-02-28 Fixed bug#[13560](https://bugs.otrs.org/show_bug.cgi?id=13560) - SysConfig added columns for dashboard widgets can't be removed.
 - 2018-02-28 Fixed bug#[13692](https://bugs.otrs.org/show_bug.cgi?id=13692) - Support Data Collector shows wrong information in OTRS -> Database Records -> Months Between First And Last Ticket / Tickets Per Month (avg).
 - 2018-02-28 Fixed bug#[13670](https://bugs.otrs.org/show_bug.cgi?id=13670) - FilterLink has to be LinkFilter in ViewModules.
 - 2018-02-28 Fixed bug#[13643](https://bugs.otrs.org/show_bug.cgi?id=13643) - After CustomerCompanySupport is disabled the customer-user cannot be defined at several places.
 - 2018-02-28 Follow-up fix for bug#[13596](https://bugs.otrs.org/show_bug.cgi?id=13596) - "S" view in mobile browser cannot be rolled horizontally.
 - 2018-02-28 Fixed bug#[13706](https://bugs.otrs.org/show_bug.cgi?id=13706) - Empty user configuration files cause internal server error.
 - 2018-02-28 Fixed bug#[13701](https://bugs.otrs.org/show_bug.cgi?id=13701) - Error Message if attachment is 0.
 - 2018-02-28 Fixed bug#[13642](https://bugs.otrs.org/show_bug.cgi?id=13642) - Deletion of tickets not possible if automatically created appointments exist for it.
 - 2018-02-28 Follow-up fix for bug#[12822](https://bugs.otrs.org/show_bug.cgi?id=12822) - SysConfig should make better use of white space.
 - 2018-02-27 Fixed bug#[13698](https://bugs.otrs.org/show_bug.cgi?id=13698)(PR#1909) - AJAX-Update missing parameter in Customer User Information Center. Thanks to Andreas Hergert.
 - 2018-02-26 Fixed bug#[13697](https://bugs.otrs.org/show_bug.cgi?id=13697) - Config ‘SystemMaintenance::TimeNotifyUpcomingMaintenance’ does not work correctly.
 - 2018-02-26 Fixed bug#[13463](https://bugs.otrs.org/show_bug.cgi?id=13463) - Updating agent data as an admin will delete user preferences.
 - 2018-02-26 Fixed bug#[13690](https://bugs.otrs.org/show_bug.cgi?id=13690) - Frontend::Module###AgentTicketEmail not hiding split target "Email ticket".
 - 2018-02-23 Fixed bug#[13686](https://bugs.otrs.org/show_bug.cgi?id=13686) - Autocomplete JS config format is wrong in Customer interface.
 - 2018-02-23 Fixed bug#[13669](https://bugs.otrs.org/show_bug.cgi?id=13669) - Agent login interface login button problem.
 - 2018-02-23 Fixed bug#[13610](https://bugs.otrs.org/show_bug.cgi?id=13610) - AgentTicketEmail take wrong Database Credentials.
 - 2018-02-21 Fixed bug#[13680](https://bugs.otrs.org/show_bug.cgi?id=13680) - SLA edit screen is not fully modern.
 - 2018-02-21 Fixed bug#[13676](https://bugs.otrs.org/show_bug.cgi?id=13676) - Column headers and tooltips are not translated, thanks to Balazs Ur - (PR#1904).
 - 2018-02-21 Fixed bug#[13681](https://bugs.otrs.org/show_bug.cgi?id=13681) - Legacy description for NotificationEvent sysconfig.
 - 2018-02-20 Fixed bug#[13674](https://bugs.otrs.org/show_bug.cgi?id=13674) - Wording issue in Session Management screen of Admin interface, thanks to Balazs Ur - (PR#1900).
 - 2018-02-20 Fixed bug#[13675](https://bugs.otrs.org/show_bug.cgi?id=13675) - Notification transport name and label are not marked for translation , thanks to Balazs Ur - (PR#1903).
 - 2018-02-16 Improved console output documentation for options that can be specified multiple times.
 - 2018-02-15 Fixed bug#[13644](https://bugs.otrs.org/show_bug.cgi?id=13644) - Attachment and text missing on some mails.
 - 2018-02-14 Fixed bug#[13638](https://bugs.otrs.org/show_bug.cgi?id=13638) - Subject Field in customer search not aligned correctly when field label above is split in 2 lines.
 - 2018-02-14 Fixed bug#[13593](https://bugs.otrs.org/show_bug.cgi?id=13593) - Current pagination number is not highlighted on the dashboard widget.
 - 2018-02-14 Fixed bug#[13547](https://bugs.otrs.org/show_bug.cgi?id=13547) - Wrong link in notification to enable cloud services.
 - 2018-02-14 Fixed bug#[13653](https://bugs.otrs.org/show_bug.cgi?id=13653) - Untranslated word "All" in system configuration search.
 - 2018-02-14 Fixed bug#[13635](https://bugs.otrs.org/show_bug.cgi?id=13635) - Broken workflow in system configuration history module.
 - 2018-02-14 Fixed bug#[13569](https://bugs.otrs.org/show_bug.cgi?id=13569) - Dynamic Fields per Template not working anymore since OTRS 6.
 - 2018-02-13 Fixed bug#[13585](https://bugs.otrs.org/show_bug.cgi?id=13585) - Follow-up: coloring issues in Ivory slim skin.
 - 2018-02-09 Fixed bug#[13603](https://bugs.otrs.org/show_bug.cgi?id=13603) - Text in Ticketheader overlaps itself when printing via browser.
 - 2018-02-09 Fixed bug#[13631](https://bugs.otrs.org/show_bug.cgi?id=13631) - Design bug in "Message of Today" text display.
 - 2018-02-09 Fixed bug#[13649](https://bugs.otrs.org/show_bug.cgi?id=13649) - Dropdown for ticket link is hidden behind appointment mask in appointment calendar.
 - 2018-02-09 Fixed bug#[13597](https://bugs.otrs.org/show_bug.cgi?id=13597) - In case of OTRS 6 Upgrade "Email Delivery Failure" notification message is incorrectly displayed.
 - 2018-02-09 Fixed bug#[13583](https://bugs.otrs.org/show_bug.cgi?id=13583) - Activation of by-default disabled Frontend::Module leads into error.
 - 2018-02-09 Fixed bug#[13646](https://bugs.otrs.org/show_bug.cgi?id=13646) - Unintuitive SysConfig setting CloudServices::Disabled.
 - 2018-02-09 Fixed bug#[13628](https://bugs.otrs.org/show_bug.cgi?id=13628) - Error message from Dev::Tools::TranslationsUpdate if certain directory does not exist.
 - 2018-02-09 Fixed bug#[13585](https://bugs.otrs.org/show_bug.cgi?id=13585) - Coloring issues in Ivory skin.
 - 2018-02-09 Fixed bug#[13587](https://bugs.otrs.org/show_bug.cgi?id=13587) - Error message when customer user does not have a first name.
 - 2018-02-07 Fixed bug#[13633](https://bugs.otrs.org/show_bug.cgi?id=13633) - "Escalated since" is always displayed as "0m" in notification of escalated tickets.
 - 2018-02-07 Fixed bug#[13550](https://bugs.otrs.org/show_bug.cgi?id=13550) - In ticket notifications to the agent, certain lines are duplicated.
 - 2018-02-07 Fixed bug#[13578](https://bugs.otrs.org/show_bug.cgi?id=13578) - Untranslated words in Support Data Collector.
 - 2018-02-07 Fixed bug#[13641](https://bugs.otrs.org/show_bug.cgi?id=13641) - Impossible to set PostmasterFilter Headers X-OTRS-IsVisibleForCustomer or X-OTRS-FollowUp-IsVisibleForCustomer to 0.
 - 2018-02-07 Fixed bug#[13609](https://bugs.otrs.org/show_bug.cgi?id=13609) - "Need TwoFactorToken!" generates error in system log.
 - 2018-02-06 Fixed translation mechanism in AdminCommunicationLog, thanks to Balazs Ur (PR#1901).
 - 2018-02-06 Fixed column spans in communication log screens, thanks to Balazs Ur (PR#1902).

# 6.0.5 2018-02-13
 - 2018-02-05 Updated translations, thanks to all translators.
 - 2018-02-05 Fixed bug#[13590](https://bugs.otrs.org/show_bug.cgi?id=13590) - Notification triggers not correct if a dynamic field with key value 0 is chosen in ticket selection and Additional recipient is set.
 - 2018-02-05 Fixed bug#[13594](https://bugs.otrs.org/show_bug.cgi?id=13594) - Menu point of article setting window is hardly available on mobile view.
 - 2018-02-03 Fixed bug#[13624](https://bugs.otrs.org/show_bug.cgi?id=13624) - Uninitialized value error in generic interface event handler.
 - 2018-02-01 Implemented database integrity check and added automatic repair option for certain situations.
 - 2018-01-31 Fixed bug#[13555](https://bugs.otrs.org/show_bug.cgi?id=13555) - Setting ZoomExpand in AgentTicketZoom also affects customer frontend.
 - 2018-01-31 Fixed bug#[13452](https://bugs.otrs.org/show_bug.cgi?id=13452) - Security options does not preselect Signing, honoring Queue default signature.
 - 2018-01-31 Fixed bug#[13595](https://bugs.otrs.org/show_bug.cgi?id=13595) - Setting of ticket number is old-style on the ticket overview screen.
 - 2018-01-31 Fixed bug#[13596](https://bugs.otrs.org/show_bug.cgi?id=13596) - "S" view in mobile browser cannot be rolled horizontally.
 - 2018-01-31 Fixed bug#[13557](https://bugs.otrs.org/show_bug.cgi?id=13557) - Incoming mails are not being processed.
 - 2018-01-31 Fixed bug#[13561](https://bugs.otrs.org/show_bug.cgi?id=13561) - Empty strings not handled correctly in HTMLUtils::Safety(). Thanks to Paweł Bogusławski.
 - 2018-01-31 Fixed bug#[13589](https://bugs.otrs.org/show_bug.cgi?id=13589) - Dynamic field choices missing for Customer User Information Center settings.
 - 2018-01-31 Fixed bug#[13570](https://bugs.otrs.org/show_bug.cgi?id=13570) - Queue view display incorrect if you move a queue to be a sub-queue.
 - 2018-01-31 Fixed bug#[13598](https://bugs.otrs.org/show_bug.cgi?id=13598) - Hiding AgentTicketMove menu with ACL makes draft function unusable.
 - 2018-01-31 Fixed bug#[13562](https://bugs.otrs.org/show_bug.cgi?id=13562) - Drag and drop of a BMP image into the editor causes an error message.
 - 2018-01-31 Fixed bug#[13284](https://bugs.otrs.org/show_bug.cgi?id=13284) - Ticket title is not included in fulltext search.
 - 2018-01-31 Fixed bug#[13500](https://bugs.otrs.org/show_bug.cgi?id=13500) - Sticky footer overlaps with elements on the login screen.
 - 2018-01-31 Fixed bug#[13399](https://bugs.otrs.org/show_bug.cgi?id=13399) - Agent preferences granular permission support not working correctly.
 - 2018-01-31 Fixed bug#[13548](https://bugs.otrs.org/show_bug.cgi?id=13548) - Package::UpgradeAll does not warn about already updated but not correctly deployed packages.
 - 2018-01-31 Fixed bug#[13604](https://bugs.otrs.org/show_bug.cgi?id=13604) - Dynamic Field Contact with Data is displayed doubled in AgentTicketZoom views.
 - 2018-01-31 Fixed bug#[13519](https://bugs.otrs.org/show_bug.cgi?id=13519) - Multi file upload dialog not usable with keyboard navigation.
 - 2018-01-30 Fixed bug#[13556](https://bugs.otrs.org/show_bug.cgi?id=13556) - Save draft without a title, opens window with JSON error on submit.
 - 2018-01-30 Fixed bug#[13592](https://bugs.otrs.org/show_bug.cgi?id=13592) - ACL with invalid-temporarily status is not included in export file when exporting ACL.
 - 2018-01-30 Fixed bug#[13468](https://bugs.otrs.org/show_bug.cgi?id=13468) - Generic interface works not with a interface which use the http status code '204'.
 - 2018-01-29 Fixed bug#[13586](https://bugs.otrs.org/show_bug.cgi?id=13586) - Wrong tooltip text in customer interface (ID of the field instead of human readable text).
 - 2018-01-25 Fixed bug#[13584](https://bugs.otrs.org/show_bug.cgi?id=13584)(PR#1894) - Emails sent via AgentTicketEmailOutbound are always visible for customer. Thanks to Robert Ullrich.
 - 2018-01-25 Fixed bug#[13558](https://bugs.otrs.org/show_bug.cgi?id=13558) - ACL PossibleAdd ignores AgentTicketCompose and AgentTicketForward.
 - 2018-01-24 Fixed bug#[13515](https://bugs.otrs.org/show_bug.cgi?id=13515) - On Login page it is impossible to insert a picture from a website (AgentLoginLogo).
 - 2018-01-24 Fixed bug#[13567](https://bugs.otrs.org/show_bug.cgi?id=13567) - $GetParam{StateID} used for ACLCompatGetParam but $GetParam{NewStateID} given.
 - 2018-01-24 Fixed bug#[13530](https://bugs.otrs.org/show_bug.cgi?id=13530) - Internal server error in AgentTicketForward if no article ID is provided.
 - 2018-01-24 Fixed bug#[13472](https://bugs.otrs.org/show_bug.cgi?id=13472) - Conversion of Dates not accepting valid format.
 - 2018-01-23 Fixed bug#[2289](https://bugs.otrs.org/show_bug.cgi?id=2289) - backup.pl - compress with bzip2 dont works.
 - 2018-01-22 Fixed bug#[13235](https://bugs.otrs.org/show_bug.cgi?id=13235) - Race condition when fetching mails.
 - 2018-01-22 Fixed bug#[13405](https://bugs.otrs.org/show_bug.cgi?id=13405) - CIC overlay display error.
 - 2018-01-21 Updated translations, thanks to all translators.
 - 2018-01-18 Fixed bug#[13552](https://bugs.otrs.org/show_bug.cgi?id=13552) - Wrong documentation in POD of TicketSearch.
 - 2018-01-13 Fixed bug#[13534](https://bugs.otrs.org/show_bug.cgi?id=13534) - Comments in the Config XML files are not ignored.
 - 2018-01-13 Fixed bug#[13339](https://bugs.otrs.org/show_bug.cgi?id=13339) - If deployment fails because of wrong settings, this wrong settings wouldn't be displayed.
 - 2018-01-12 Fixed bug#[13543](https://bugs.otrs.org/show_bug.cgi?id=13543) - Wrong Month Name in OTRS Appoinment Calender.
 - 2018-01-12 Fixed bug#[13521](https://bugs.otrs.org/show_bug.cgi?id=13521) - Article sender field contains user's OoO information.
 - 2018-01-12 Fixed bug#[13498](https://bugs.otrs.org/show_bug.cgi?id=13498) - Multi-upload form is showing inline attachments after new uploads.
 - 2018-01-11 Fixed bug#[13542](https://bugs.otrs.org/show_bug.cgi?id=13542) - Deep recursion error in package manager install/upgrade in a very special constellation.
 - 2018-01-11 Fixed bug#[13536](https://bugs.otrs.org/show_bug.cgi?id=13536) - System maintenance does not show formatted timestamps and messages.
 - 2018-01-10 Fixed bug#[13523](https://bugs.otrs.org/show_bug.cgi?id=13523) - Loading an invalid communication ID causes all to be shown.
 - 2018-01-09 Follow-up fix for bug#[13325](https://bugs.otrs.org/show_bug.cgi?id=13325) - OTRS_CUSTOMER_BODY not working for most notification events.

# 6.0.4 2018-01-16
 - 2018-01-12 Fixed bug#[13527](https://bugs.otrs.org/show_bug.cgi?id=13527) - Reset locally not working as expected.
 - 2018-01-12 Fixed bug#[13546](https://bugs.otrs.org/show_bug.cgi?id=13546) - Dashboard sort order changes itself after autorefresh cyclically.
 - 2018-01-11 Fixed bug#[13541](https://bugs.otrs.org/show_bug.cgi?id=13541) - Running migration script during patch level updates cleans up all modified settings from packages.
 - 2018-01-08 Updated translations, thanks to all translators.
 - 2018-01-08 Fixed bug#[13460](https://bugs.otrs.org/show_bug.cgi?id=13460) - upgrade packages result in a output with strange characters.
 - 2018-01-06 Fixed bug#[13478](https://bugs.otrs.org/show_bug.cgi?id=13478) - Maint::Config::Rebuild does not show error if old-style configuration file is found.
 - 2018-01-05 Fixed bug#[13428](https://bugs.otrs.org/show_bug.cgi?id=13428) - Timeline view dynamic field values.
 - 2018-01-05 Fixed bug#[13516](https://bugs.otrs.org/show_bug.cgi?id=13516) - In the setting window of linked widgets dynamic field labels are not displayed.
 - 2018-01-05 Fixed bug#[13503](https://bugs.otrs.org/show_bug.cgi?id=13503) - Delete button of filter is not unified.
 - 2018-01-05 Fixed bug#[13338](https://bugs.otrs.org/show_bug.cgi?id=13338) - DBUpdate-script isn't checking ZZZAuto.pm for wrong Sysconfig settings.
 - 2018-01-05 Fixed bug#[13502](https://bugs.otrs.org/show_bug.cgi?id=13502) - communication log delete is slow.
 - 2018-01-05 Fixed bug#[13353](https://bugs.otrs.org/show_bug.cgi?id=13353) - inline picture not shown in AgentTicketZoom.
 - 2018-01-05 Fixed bug#[13437](https://bugs.otrs.org/show_bug.cgi?id=13437) - Upgrade script repeatedly asks for time zone configuration.
 - 2018-01-05 Fixed bug#[13326](https://bugs.otrs.org/show_bug.cgi?id=13326) - System was unable to lock Default Settings - after DBsetup/Step 2.
 - 2018-01-04 Fixed bug#[13267](https://bugs.otrs.org/show_bug.cgi?id=13267) - User specific settings which are overwritten in user files are not shown correctly in agent preferences screen (OTRS Business Solution™).
 - 2018-01-04 Fixed bug#[13518](https://bugs.otrs.org/show_bug.cgi?id=13518) - Invisible settings still available in SysConfig autocomplete search.
 - 2018-01-04 Fixed bug#[13294](https://bugs.otrs.org/show_bug.cgi?id=13294) - Safari autofill broken when two factor authentication is enabled.
 - 2018-01-04 Fixed bug#[13260](https://bugs.otrs.org/show_bug.cgi?id=13260) - Endless loop for recurrent daemon task with the same task name.
 - 2018-01-03 Fixed bug#[13510](https://bugs.otrs.org/show_bug.cgi?id=13510) - Article fields like Signed and Crypted are missing from the article header.
 - 2018-01-02 Fixed bug#[13444](https://bugs.otrs.org/show_bug.cgi?id=13444) - DynamicField Dropdown values are not verified if submitted via web service.
 - 2018-01-02 Follow-up fix for bug#[12569](https://bugs.otrs.org/show_bug.cgi?id=12569) - Missing explanation users (with visual impairments) in the 'Preferences' page.
 - 2017-12-29 Fixed bug#[13509](https://bugs.otrs.org/show_bug.cgi?id=13509) - Ordering in ticket overview screens is not consistent with dashboard tables.
 - 2017-12-29 Fixed bug#[13511](https://bugs.otrs.org/show_bug.cgi?id=13511) - Need UserFirstname floods system log.
 - 2017-12-27 Fixed bug#[13489](https://bugs.otrs.org/show_bug.cgi?id=13489) - Allowing users to change settings has no affect in advanced settings.
 - 2017-12-27 Fixed bug#[13488](https://bugs.otrs.org/show_bug.cgi?id=13488) - User Specific Settings not reflecting the correct number.
 - 2017-12-26 Fixed bug#[13485](https://bugs.otrs.org/show_bug.cgi?id=13485) - Text editor is incorrectly displayed in Bulk menu window.
 - 2017-12-26 Fixed bug#[13486](https://bugs.otrs.org/show_bug.cgi?id=13486) - On the agent's login interface the system maintenance notification is too wide (width is not limited).
 - 2017-12-26 Fixed bug#[13426](https://bugs.otrs.org/show_bug.cgi?id=13426) - Making changes on dashboard stats widgets are not being remembered.
 - 2017-12-26 Follow-up fix for bug#[13424](https://bugs.otrs.org/show_bug.cgi?id=13424) - The CustomerID is missing after the ticket split.
 - 2017-12-26 Follow-up fix for bug#[11422](https://bugs.otrs.org/show_bug.cgi?id=11422) - List in the Dashboard: standard priority is ignored if you use a filter.
 - 2017-12-26 Fixed bug#[13414](https://bugs.otrs.org/show_bug.cgi?id=13414) - Wrong behavior of open ticket links in customer screens.
 - 2017-12-26 Fixed bug#[13475](https://bugs.otrs.org/show_bug.cgi?id=13475) - Escalation notifications are not triggered.
 - 2017-12-26 Fixed bug#[13397](https://bugs.otrs.org/show_bug.cgi?id=13397) - Autoreply shows HTML Tags when adding HTML formatted articles via Generic Interface. Thanks to Christoph Delbrück.
 - 2017-12-26 Fixed bug#[13429](https://bugs.otrs.org/show_bug.cgi?id=13429) - Wrong number of logged in agents/customers.
 - 2017-12-26 Fixed bug#[13430](https://bugs.otrs.org/show_bug.cgi?id=13430) - Ticket title overlaps with actions.
 - 2017-12-25 Fixed bug#[13499](https://bugs.otrs.org/show_bug.cgi?id=13499) - Target \_blank value is not working for TicketMenu in AgentTicketZoom.
 - 2017-12-25 Fixed bug#[13289](https://bugs.otrs.org/show_bug.cgi?id=13289) - Certain input fields in don't accept accentuated letters.
 - 2017-12-22 Fixed bug#[13461](https://bugs.otrs.org/show_bug.cgi?id=13461) - Safari will not update Ticket notification settings in the Agent preferences screen.
 - 2017-12-21 Fixed bug#[13458](https://bugs.otrs.org/show_bug.cgi?id=13458) - Sorting is wrong for zero.
 - 2017-12-21 Fixed bug#[13403](https://bugs.otrs.org/show_bug.cgi?id=13403) - When importing sys config the disabled modules don't become enabled.
 - 2017-12-20 Fixed bug#[13465](https://bugs.otrs.org/show_bug.cgi?id=13465) - outgoing mail stuck in queue.
 - 2017-12-20 Fixed bug#[13476](https://bugs.otrs.org/show_bug.cgi?id=13476) - Email security options in AgentTicketCompose leads into an error.
 - 2017-12-20 Fixed bug#[13231](https://bugs.otrs.org/show_bug.cgi?id=13231) - AJAX Error when ACL triggers in queue move (restrict move from one queue to another based on Properties).
 - 2017-12-20 Fixed bug#[13431](https://bugs.otrs.org/show_bug.cgi?id=13431) - Notification article is visible for the customer although it shouldn't be.
 - 2017-12-19 Fixed bug#[13464](https://bugs.otrs.org/show_bug.cgi?id=13464) - Dropdown selection not visible in ticket search.
 - 2017-12-18 Fixed bug#[13450](https://bugs.otrs.org/show_bug.cgi?id=13450) - Changing TicketType doesn't change Ticket::Frontend::CustomerTicketMessage###TicketTypeDefault.
 - 2017-12-18 Fixed bug#[13371](https://bugs.otrs.org/show_bug.cgi?id=13371) - Deleting a sysconfig entry in AgentPreferencesGroups breaks the config when saving.
 - 2017-12-14 Fixed bug#[13411](https://bugs.otrs.org/show_bug.cgi?id=13411) - Names of search templates cut off.
 - 2017-12-13 Updated translations, thanks to all translators.
 - 2017-12-13 Fixed bug#[13351](https://bugs.otrs.org/show_bug.cgi?id=13351) - Templates of type "Create" don't get automatically loaded on AgentTicketPhone or AgentTicketEmail
 - 2017-12-13 Fixed bug#[13196](https://bugs.otrs.org/show_bug.cgi?id=13196) - Search in CustomerUser Information Center returns a search blank screen.
 - 2017-12-13 Fixed bug#[13419](https://bugs.otrs.org/show_bug.cgi?id=13419) - Queue View Large shows the same date and timestamp for every article.
 - 2017-12-13 Fixed bug#[13453](https://bugs.otrs.org/show_bug.cgi?id=13453) - During automatic update of dashboard widget the arrangement changes.
 - 2017-12-13 Fixed bug#[13448](https://bugs.otrs.org/show_bug.cgi?id=13448) - XML::LibXML is now mandatory, but shown optional in CheckModules.
 - 2017-12-12 Fixed bug#[13405](https://bugs.otrs.org/show_bug.cgi?id=13405) - CIC overlay display error.
 - 2017-12-12 Fixed bug#[13407](https://bugs.otrs.org/show_bug.cgi?id=13407) - PasswordMaxLoginFailed destroys the user's password after too many incorrect logins.
 - 2017-12-12 Fixed bug#[13445](https://bugs.otrs.org/show_bug.cgi?id=13445) - System should use TimeZone ValueType in the Framework.xml instead of Select.

# 6.0.3 2017-12-19
 - 2017-12-14 Fixed bug#[13451](https://bugs.otrs.org/show_bug.cgi?id=13451) - Can't create Meta Article after update from 5 to 6.
 - 2017-12-13 Fixed bug#[13432](https://bugs.otrs.org/show_bug.cgi?id=13432)(PR#1881) - Inline images are not shown in customer frontend.
 - 2017-12-11 Updated translations, thanks to all translators.
 - 2017-12-11 Fixed bug#[13410](https://bugs.otrs.org/show_bug.cgi?id=13410) - Package::UpdagreAll can't upgrade from ITSM 5 to 6.
 - 2017-12-08 Hot-fix for bug#[13353](https://bugs.otrs.org/show_bug.cgi?id=13353) - Inline picture not shown in AgentTicketZoom.
 - 2017-12-08 Follow-up fix for bug#13367.
 - 2017-12-08 Fixed bug#[13438](https://bugs.otrs.org/show_bug.cgi?id=13438) - Once per day option in notifications is not honored.
 - 2017-12-07 Improved parameter appending.
 - 2017-12-07 Fixed bug#[13434](https://bugs.otrs.org/show_bug.cgi?id=13434) - ArticleCheck/PGP.pm still contains unported code.
 - 2017-12-07 Fixed bug#[13422](https://bugs.otrs.org/show_bug.cgi?id=13422) - Recipient agents of notes no longer visible.
 - 2017-12-06 Fixed bug#[13394](https://bugs.otrs.org/show_bug.cgi?id=13394) - Changes in CustomerUserListFields are not applied.
 - 2017-12-06 Fixed bug#[13424](https://bugs.otrs.org/show_bug.cgi?id=13424) - The CustomerID is missing after the ticket split.
 - 2017-12-04 Fixed bug#[13412](https://bugs.otrs.org/show_bug.cgi?id=13412) - Statistics with date or date time dynamic fields are no longer working.
 - 2017-12-04 Fixed bug#[13392](https://bugs.otrs.org/show_bug.cgi?id=13392) - Unable to create a multiselection Articlefilter in AgentTicketZoom.
 - 2017-12-04 Follow-up fix for bug#[13262](https://bugs.otrs.org/show_bug.cgi?id=13262) - Dynamic Fields Management breadcrumb is not translatable.
 - 2017-12-04 Fixed bug#[13097](https://bugs.otrs.org/show_bug.cgi?id=13097) - Button "Add Customer" in Customer Information Center is missing.
 - 2017-12-04 Fixed bug#[13404](https://bugs.otrs.org/show_bug.cgi?id=13404) - Native Browser Spellchecker doesn't work.
 - 2017-12-01 Fixed bug#[13225](https://bugs.otrs.org/show_bug.cgi?id=13225) - Too many DB calls when rebuilding system configuration.
 - 2017-12-01 Fixed bug#[13251](https://bugs.otrs.org/show_bug.cgi?id=13251) - SysConfig Date settings with complex names are broken.
 - 2017-12-01 Fixed bug#[13363](https://bugs.otrs.org/show_bug.cgi?id=13363) - Missing code migration in TicketUpdate operation.
 - 2017-12-01 Fixed bug#[13335](https://bugs.otrs.org/show_bug.cgi?id=13335) - Changes in Network Transport of Web Services are not saved.
 - 2017-12-01 Fixed bug#[13312](https://bugs.otrs.org/show_bug.cgi?id=13312) - ACLs not working as expected in AgentTicketFreeText.
 - 2017-12-01 Fixed bug#[13170](https://bugs.otrs.org/show_bug.cgi?id=13170) - Frontend::RichTextWidth setting is not honored.
 - 2017-12-01 Fixed bug#[13350](https://bugs.otrs.org/show_bug.cgi?id=13350) - CheckMXRecord should not act when setting email address to invalid.
 - 2017-11-30 Fixed bug#[13299](https://bugs.otrs.org/show_bug.cgi?id=13299) - Dashboard widgets can't be rearranged in Chrome and Internet Explorer on touchscreen devices.
 - 2017-11-30 Fixed bug#[13379](https://bugs.otrs.org/show_bug.cgi?id=13379) - PendingTimeDiff is not updated, if no state update was done in a transition action.
 - 2017-11-29 Fixed bug#[13395](https://bugs.otrs.org/show_bug.cgi?id=13395) - ConfigImportAllowed: configuration option missing.

# 6.0.2 2017-12-05
 - 2017-11-30 Fixed bug#[13362](https://bugs.otrs.org/show_bug.cgi?id=13362) - Issue with dynamic fields in ticket information widget in ticket zoom.
 - 2017-11-30 Fixed bug#[13398](https://bugs.otrs.org/show_bug.cgi?id=13398) - ActivityDialog communication-channel not in config.
 - 2017-11-29 Fixed bug#[13391](https://bugs.otrs.org/show_bug.cgi?id=13391) - Ticket history mapping reference missing in TicketSearch.
 - 2017-11-27 Updated translations, thanks to all translators.
 - 2017-11-27 Fixed bug#[13262](https://bugs.otrs.org/show_bug.cgi?id=13262) - Dynamic Fields Management breadcrumb is not translatable.
 - 2017-11-27 Fixed bug#[13366](https://bugs.otrs.org/show_bug.cgi?id=13366) - Maintenance Message cannot exceed 250 characters, that is not reflected in the GUI.
 - 2017-11-27 Fixed bug#[13325](https://bugs.otrs.org/show_bug.cgi?id=13325) - OTRS_CUSTOMER_BODY not working for most notification events.
 - 2017-11-27 Fixed bug#[13385](https://bugs.otrs.org/show_bug.cgi?id=13385) - Customer web request results in a phone article.
 - 2017-11-27 Fixed bug#[13342](https://bugs.otrs.org/show_bug.cgi?id=13342) - Package installation results in an error until web server is restarted.
 - 2017-11-27 Fixed bug#[13370](https://bugs.otrs.org/show_bug.cgi?id=13370) - Cloning DateTime object returns bad object(wrong unix timestamp).
 - 2017-11-24 Fixed bug#[13266](https://bugs.otrs.org/show_bug.cgi?id=13266) - Article field not mandatory if time units are added.
 - 2017-11-24 Fixed bug#[13323](https://bugs.otrs.org/show_bug.cgi?id=13323) - Visibility issues in SysConfig settings with large number of list items.
 - 2017-11-24 Fixed bug#[13382](https://bugs.otrs.org/show_bug.cgi?id=13382) - Stats dashboard generate fails because of missing parameters in Stats.pm.
 - 2017-11-23 Fixed bug#[13381](https://bugs.otrs.org/show_bug.cgi?id=13381) - Categories in Navigation (AgentPreferences screen) are not working for non-admin users.
 - 2017-11-23 Fixed bug#[13374](https://bugs.otrs.org/show_bug.cgi?id=13374) - DBUpdate script deletes user time zone information on patch level updates.
 - 2017-11-23 Fixed bug#[13376](https://bugs.otrs.org/show_bug.cgi?id=13376) - Standard values in System Configuration displayed as modified and contained in config.pm and locked.
 - 2017-11-22 Fixed bug#[13365](https://bugs.otrs.org/show_bug.cgi?id=13365) - Incorrect accentuated characters in the draft name.
 - 2017-11-22 Fixed bug#[13286](https://bugs.otrs.org/show_bug.cgi?id=13286) - SysConfig frontends allows changing seemingly read-only values.
 - 2017-11-22 Fixed bug#[13288](https://bugs.otrs.org/show_bug.cgi?id=13288) - In several places of the OTRS 6 sys config it's not possible to add new entry.
 - 2017-11-22 Fixed bug#[13373](https://bugs.otrs.org/show_bug.cgi?id=13373) - Console command to generate the dashboard stats stops working, if a user had a time zone selected in OTRS 5.
 - 2017-11-22 Fixed bug#[13372](https://bugs.otrs.org/show_bug.cgi?id=13372) - Editing for agent dashboard statistics with a absolute time period on the x axes doesn't work and statitic can not be generated.
 - 2017-11-22 Fixed bug#[13367](https://bugs.otrs.org/show_bug.cgi?id=13367) - Wrong output for article email content in agent ticket zoom.
 - 2017-11-21 Fixed bug#[13357](https://bugs.otrs.org/show_bug.cgi?id=13357) - Improve handling of PGP parameters.
 - 2017-11-20 Fixed bug#[13293](https://bugs.otrs.org/show_bug.cgi?id=13293) - Uninitialized value notice in AgentTicketZoom with enabled 'Ticket::NewArticleIgnoreSystemSender'.
 - 2017-11-20 Fixed bug#[13361](https://bugs.otrs.org/show_bug.cgi?id=13361)(PR#1873) - Postmaster Filter matching is not correct, thanks to Pawel Boguslawski.
 - 2017-11-20 Fixed bug#[13360](https://bugs.otrs.org/show_bug.cgi?id=13360) - Configuration Deployment Failure does not restore old values set for reset.
 - 2017-11-20 Fixed bug#[13340](https://bugs.otrs.org/show_bug.cgi?id=13340) - UpgradeAll feature does not state it works only if OTRS Daemon is running.
 - 2017-11-20 Fixed bug#[13316](https://bugs.otrs.org/show_bug.cgi?id=13316) - Obsolete directive in CSP.
 - 2017-11-20 Fixed bug#[13250](https://bugs.otrs.org/show_bug.cgi?id=13250) - Disabled wrong value settings does not let to specify the correct value.
 - 2017-11-20 Fixed bug#[13291](https://bugs.otrs.org/show_bug.cgi?id=13291) - Moving setting from one XML file to another doesn't update xml_filename in the sysconfig_default table.
 - 2017-11-17 Fixed bug#[13145](https://bugs.otrs.org/show_bug.cgi?id=13145) - Editing a transistion action results in error without logfile entry.
 - 2017-11-16 Fixed bug#[13331](https://bugs.otrs.org/show_bug.cgi?id=13331) - Ticket Age is shown not updated on customer interface.
 - 2017-11-17 Fixed bug#[13347](https://bugs.otrs.org/show_bug.cgi?id=13347) - Internal article information disclosed by the customer search.
 - 2017-11-17 Fixed bug#[13343](https://bugs.otrs.org/show_bug.cgi?id=13343) - LDAP customer user backends should be implicitly read only.
 - 2017-11-17 Fixed bug#[13348](https://bugs.otrs.org/show_bug.cgi?id=13348) - User specific settings do not reset when set to the default value.
 - 2017-11-16 Fixed bug#[13333](https://bugs.otrs.org/show_bug.cgi?id=13333) - Customer filter filter is too narrow on customer interface.
 - 2017-11-14 Fixed bug#[13310](https://bugs.otrs.org/show_bug.cgi?id=13310) - Only 15 tickets in ticket lists if overview medium/preview disabled for new agents.
 - 2017-11-14 Fixed bug#[13314](https://bugs.otrs.org/show_bug.cgi?id=13314) - Multiple submit possible for bulk action.

# 6.0.1 2017-11-21
 - 2017-11-17 Fixed bug#[13344](https://bugs.otrs.org/show_bug.cgi?id=13344) - DBUpgrade-6.pl break UTF-8 letters in config.
 - 2017-11-15 Fixed bug#[13328](https://bugs.otrs.org/show_bug.cgi?id=13328) - Postmaster filter migration for 'X-OTRS-ArticleType' and 'X-OTRS-FollowUp-ArticleType' are not working for sysconfig settings.
 - 2017-11-13 Fixed bug#[13108](https://bugs.otrs.org/show_bug.cgi?id=13108) - Debugger only shows information if HTTP response was 20x.
 - 2017-11-13 Updated translations, thanks to all translators.
 - 2017-11-13 Fixed bug#[13330](https://bugs.otrs.org/show_bug.cgi?id=13330) - Postmaster filter from sysconfig are not working and stops working.
 - 2017-11-13 Fixed bug#[13317](https://bugs.otrs.org/show_bug.cgi?id=13317) - Wrong avatar offset in user preferences.
 - 2017-11-13 Fixed bug#[13318](https://bugs.otrs.org/show_bug.cgi?id=13318) - It is no longer possible to add a new navbar entry with the sysconfig frontend and the migration for own entries doesn't work.
 - 2017-11-10 Fixed bug#[13281](https://bugs.otrs.org/show_bug.cgi?id=13281) - Not possible to add more than 4000 character in ticket notification texts.
 - 2017-11-10 Fixed bug#[13320](https://bugs.otrs.org/show_bug.cgi?id=13320) - Internal Server Error in agent ticket move with Ticket::Frontend::MoveType type 'form' and with add article.
 - 2017-11-09 Fixed bug#[13315](https://bugs.otrs.org/show_bug.cgi?id=13315) - Problem with sending ticket notifications after the migration, because of existing 'NotificationArticleTypeID'.
 - 2017-11-08 Fixed bug#[13300](https://bugs.otrs.org/show_bug.cgi?id=13300) - Problem with the StatsCleanUp functionality during the package upgrade.
 - 2017-11-08 Fixed bug#[13292](https://bugs.otrs.org/show_bug.cgi?id=13292) - Internal Server Error in ticket screens with missing articles in the file system.
 - 2017-10-25 Fixed bug#[12392](https://bugs.otrs.org/show_bug.cgi?id=12392) - [thirdparty] gnupg 2.1 not working.

# 6.0.0.rc1 2017-11-14
 - 2017-11-06 Updated translations, thanks to all translators.
 - 2017-11-06 Fixed bug#[13282](https://bugs.otrs.org/show_bug.cgi?id=13282) - Try to bounce a ticket, Apache error about ObjectLog and an undefined value.
 - 2017-11-06 Fixed bug#[13239](https://bugs.otrs.org/show_bug.cgi?id=13239) - Legacy descriptions in SysConfig.
 - 2017-11-06 Fixed bug#[13290](https://bugs.otrs.org/show_bug.cgi?id=13290) - If Group and GroupRo and defined and both have any group set, system grants access for any user to this screen.
 - 2017-11-06 Fixed bug#[13206](https://bugs.otrs.org/show_bug.cgi?id=13206) - Dashboard does not detect expired sessions.
 - 2017-11-03 Fixed bug#[13279](https://bugs.otrs.org/show_bug.cgi?id=13279) - Problem with rebuilding config after migration.
 - 2017-11-03 Submit with Ctrl/CMD + Enter in textareas, thanks to Perleone.
 - 2017-11-03 Fixed bug#[13261](https://bugs.otrs.org/show_bug.cgi?id=13261) - Limit hit when installing ITSM package on MySQL.
 - 2017-11-03 Fixed bug#[13271](https://bugs.otrs.org/show_bug.cgi?id=13271) - Breadcrumb for a specific SysConfig setting name garbles its encoding.
 - 2017-11-03 Fixed bug#[13280](https://bugs.otrs.org/show_bug.cgi?id=13280) - Rebuild config fails for seemingly valid XML file.
 - 2017-11-02 Fixed Need ObjectID! error on AgentTicketMove with article dynamic field, thanks to Pawel Boguslawski.
 - 2017-11-02 Fixed bug#[13278](https://bugs.otrs.org/show_bug.cgi?id=13278) - Considering invalid 'navbar' items in sysconfig migration while upgrading a package from otrs5.
 - 2017-10-27 Fixed bug#[12886](https://bugs.otrs.org/show_bug.cgi?id=12886) - AccessKeys not working.
 - 2017-10-27 Fixed bug#[13254](https://bugs.otrs.org/show_bug.cgi?id=13254) - Delete icon of Attachment is not displayed on mobile view.
 - 2017-10-27 Fixed bug#[13061](https://bugs.otrs.org/show_bug.cgi?id=13061) - PGP Agent Notification with expired certificate results in unencrypted message.
 - 2017-10-27 Fixed bug#[13259](https://bugs.otrs.org/show_bug.cgi?id=13259) - Problem when enabling all setting.
 - 2017-10-27 Fixed bug#[10946](https://bugs.otrs.org/show_bug.cgi?id=10946) - Stats Restrictions : 'Created in Queue' together with ' Close Time' doesn' work.
 - 2017-10-27 Fixed links to SysConfig items in AdminCustomerUserGroup and AdminCustomerGroup screen, thanks to urbalazs.
 - 2017-10-27 Fixed bug#[13264](https://bugs.otrs.org/show_bug.cgi?id=13264) - Hash of select items are not working properly in SysConfig.
 - 2017-10-26 Fixed bug#[13263](https://bugs.otrs.org/show_bug.cgi?id=13263) - Fatal error after click on breadcrumb in agent preferences.
 - 2017-10-25 Fixed bug#[13265](https://bugs.otrs.org/show_bug.cgi?id=13265) - Disabled sysconfig settings are active after migration (if the setting is active as default).
 - 2017-10-25 Fixed bug#[13143](https://bugs.otrs.org/show_bug.cgi?id=13143) - Toolbar Search for Customer User should open new Customer User Information Center.

# 6.0.0.beta5 2017-11-01
 - 2017-10-23 Updated translations, thanks to all translators.
 - 2017-10-23 Fixed bug#[13248](https://bugs.otrs.org/show_bug.cgi?id=13248) - Wrong use of DateTime Object in Stats.
 - 2017-10-23 Fixed bug#[12822](https://bugs.otrs.org/show_bug.cgi?id=12822) - SysConfig should make better use of white space.
 - 2017-10-20 Fixed bug#[13213](https://bugs.otrs.org/show_bug.cgi?id=13213) - Disabled Customer information widget is broken in agent ticket zoom.
 - 2017-10-20 Fixed bug#[13226](https://bugs.otrs.org/show_bug.cgi?id=13226) - TicketAcceleratorRebuild has mismatch in number of fields vs parameters.
 - 2017-10-20 Fixed bug#[13079](https://bugs.otrs.org/show_bug.cgi?id=13079) - Upgrade fails on foreign key constraints.
 - 2017-10-20 Fixed bug#[13193](https://bugs.otrs.org/show_bug.cgi?id=13193) - Ticket::SearchIndex::FilterStopWords should be optimized.
 - 2017-10-18 Fixed bug#[13221](https://bugs.otrs.org/show_bug.cgi?id=13221) - Update errors when updating to OTRS 6.
 - 2017-10-18 Fixed bug#[13236](https://bugs.otrs.org/show_bug.cgi?id=13236) - Cannot invoke otrs.SetPermissions.pl without arguments.
 - 2017-10-18 Fixed bug#[13227](https://bugs.otrs.org/show_bug.cgi?id=13227) - Some notifications are untranslatable.
 - 2017-10-17 Fixed bug#[13201](https://bugs.otrs.org/show_bug.cgi?id=13201) - Sanitize output of all translations in templates.
 - 2017-10-17 Fixed bug#[13044](https://bugs.otrs.org/show_bug.cgi?id=13044) - Fatal errors in the frontend if Modules are disabled in System Configuration.
 - 2017-10-16 Fixed bug#[13177](https://bugs.otrs.org/show_bug.cgi?id=13177) - Changing the TimeZone in the AgentPreferences shows an error in the log.
 - 2017-10-16 Fixed bug#[13223](https://bugs.otrs.org/show_bug.cgi?id=13223) - Package dialogs need additional CSS.
 - 2017-10-16 Fixed bug#[12823](https://bugs.otrs.org/show_bug.cgi?id=12823) - SysConfig slow.
 - 2017-10-13 Fixed bug#[13154](https://bugs.otrs.org/show_bug.cgi?id=13154) - The New Dynamic Field for CustomerUsers does not support links.
 - 2017-10-13 Fixed bug#[13146](https://bugs.otrs.org/show_bug.cgi?id=13146) - DynamicField Database does not work in process dialogue.
 - 2017-10-13 Fixed bug#[13156](https://bugs.otrs.org/show_bug.cgi?id=13156) - TicketHistory hides mandatory column Ticket Actions.
 - 2017-10-13 Fixed bug#[13218](https://bugs.otrs.org/show_bug.cgi?id=13218) - Link binding works only for the last asychronous widget in the agent ticket zoom.
 - 2017-10-12 Fixed bug#[13095](https://bugs.otrs.org/show_bug.cgi?id=13095) - Ambiguous message when uploading large files.
 - 2017-10-12 Fixed bug#[13178](https://bugs.otrs.org/show_bug.cgi?id=13178) - Freely selectable feature package list does not honor user language.
 - 2017-10-12 Fixed bug#[13099](https://bugs.otrs.org/show_bug.cgi?id=13099) - AgentTicketPhone does not honor KeepChildren SysConfig setting for service list.
 - 2017-10-12 Fixed bug#[13059](https://bugs.otrs.org/show_bug.cgi?id=13059) - Translation is not applied in AgentAppointmentList.
 - 2017-10-12 Fixed bug#[13114](https://bugs.otrs.org/show_bug.cgi?id=13114) - Data key RegEx filters are removed if XSLT mapping contains an error.
 - 2017-10-10 Fixed bug#[13208](https://bugs.otrs.org/show_bug.cgi?id=13208) - HumanReadableDataSize in the layout object returns only integer portion.

# 6.0.0.beta4 2017-10-17
 - 2017-10-09 Updated translations, thanks to all translators.
 - 2017-10-09 Fixed bug#[13199](https://bugs.otrs.org/show_bug.cgi?id=13199) - Table dynamic_field_obj_id_name was not created during installation.
 - 2017-10-05 Updated translations, thanks to all translators.
 - 2017-10-03 Fixed bug#[13189](https://bugs.otrs.org/show_bug.cgi?id=13189) - User specific settings incorrectly marked as coming from Kernel/Config.pm.
 - 2017-10-01 Fixed bug#[13023](https://bugs.otrs.org/show_bug.cgi?id=13023) - Base classes displayed as options in SysConfig.
 - 2017-10-01 Fixed bug#[13149](https://bugs.otrs.org/show_bug.cgi?id=13149) - Translations are not applied from \*.tmpl files.

# 6.0.0.beta3 2017-10-03
 - 2017-09-25 Updated translations, thanks to all translators.
 - 2017-09-25 Fixed bug#[13160](https://bugs.otrs.org/show_bug.cgi?id=13160) - Customer User Address Book visibility issues.
 - 2017-09-25 Fixed bug#[13010](https://bugs.otrs.org/show_bug.cgi?id=13010) - ACL does not trigger on a change of a dynamic field checkbox.
 - 2017-09-25 Fixed bug#[13155](https://bugs.otrs.org/show_bug.cgi?id=13155) - Ticket::UseArticleColors shows all articles white, all internal notes are red.
 - 2017-09-25 Fixed bug#[13027](https://bugs.otrs.org/show_bug.cgi?id=13027) - Content of an invalid setting can be changed.
 - 2017-09-25 Fixed bug#[13176](https://bugs.otrs.org/show_bug.cgi?id=13176) - Error message "Size must be integer" in some screens.
 - 2017-09-24 Updated translations, thanks to all translators.
 - 2017-09-22 Fixed bug#[12915](https://bugs.otrs.org/show_bug.cgi?id=12915) - OTRS 6 uses modifiers for sysconfig values.
 - 2017-09-21 Fixed bug#[13105](https://bugs.otrs.org/show_bug.cgi?id=13105) - Dropdown fields in GenericAgent not modernized.
 - 2017-09-21 Fixed bug#[13106](https://bugs.otrs.org/show_bug.cgi?id=13106) - Upgrading to 6.0.0.beta1 missing system configuration settings.
 - 2017-09-21 Fixed bug#[9716](https://bugs.otrs.org/show_bug.cgi?id=9716) - Report on solution times gives very large negative times.
 - 2017-09-21 Fixed bug#[13051](https://bugs.otrs.org/show_bug.cgi?id=13051) - Postmaster Filter named captures.
 - 2017-09-20 Fixed translatable strings, thanks to Balazs Ur (PR#1833, PR#1834).
 - 2017-09-20 Fixed bug#[13173](https://bugs.otrs.org/show_bug.cgi?id=13173) - Not needed mandatory stats object module function in 'ObjectModuleCheck'.
 - 2017-09-20 Improved accessbility of dialog buttons, thanks to Balazs Ur (PR#1842).
 - 2017-09-19 Fixed bug#[13076](https://bugs.otrs.org/show_bug.cgi?id=13076) - Multi-upload should also support cases where just one file can be added.
 - 2017-09-18 Added a link to the notification web view to the new personal flyout for agents.
 - 2017-09-18 Fixed bug#[13164](https://bugs.otrs.org/show_bug.cgi?id=13164) - Certain AJAX Error Types are still unprocessed.
 - 2017-09-16 Fixed bug#[12955](https://bugs.otrs.org/show_bug.cgi?id=12955) - System Configuration is detected dirty when a User Specific Setting is still dirty.
 - 2017-09-16 Fixed bug#[12987](https://bugs.otrs.org/show_bug.cgi?id=12987) - Handling inline attachments with Content-Disposition set to "attachment".
 - 2017-09-14 Fixed bug#[12968](https://bugs.otrs.org/show_bug.cgi?id=12968) - RebuildConfig error message.
 - 2017-09-14 Fixed bug#[13148](https://bugs.otrs.org/show_bug.cgi?id=13148) - Emal Template "Alert" is always preselected.
 - 2017-09-14 Fixed bug#[12991](https://bugs.otrs.org/show_bug.cgi?id=12991) - Search with additional filters returns previous results after bulk change unless exit and re-run search.
 - 2017-09-14 Added new support data plugins for additional UI stats.
 - 2017-09-13 Fixed bug#[13045](https://bugs.otrs.org/show_bug.cgi?id=13045) - Usability / visibilty of error handling screens.
 - 2017-09-13 Added new command Admin::Package::UpgradeAll, which allows updating all installed packages at once. This can also be triggered from the package manager screen.
 - 2017-09-12 Follow-up fix for bug#[13133](https://bugs.otrs.org/show_bug.cgi?id=13133) - AdminCustomerUser - missing check for mandatory field if autocomplete search is used for customer ID field.

# 6.0.0.beta2 2017-09-19
 - 2017-09-11 Fixed bug#[13133](https://bugs.otrs.org/show_bug.cgi?id=13133) - AdminCustomerUser - missing check for mandatory field if autocomplete search is used for customer ID field.
 - 2017-09-11 Fixed bug#[13132](https://bugs.otrs.org/show_bug.cgi?id=13132) - Problems with UserLastLoginTimestampa and UserMailString in customer user LDAP backend.
 - 2017-09-11 Fixed bug#[12963](https://bugs.otrs.org/show_bug.cgi?id=12963) - SysConfig: empty tree items should not be clickable.
 - 2017-09-08 Improved initial message in advanced user preferences for OTRS Business Solution™.
 - 2017-09-08 Fixed bug#[13046](https://bugs.otrs.org/show_bug.cgi?id=13046) - System Configuration scrolling issue.
 - 2017-09-08 Fixed bug#[13121](https://bugs.otrs.org/show_bug.cgi?id=13121) - Use of undefined variables.
 - 2017-09-07 Improved validation in statistic import and export.
 - 2017-09-07 Fixed bug#[7307](https://bugs.otrs.org/show_bug.cgi?id=7307) - mixed html/plain e-mail.
 - 2017-09-06 Fixed bug#[13056](https://bugs.otrs.org/show_bug.cgi?id=13071) - Sending form by pressing RETURN key.
 - 2017-09-06 Fixed bug#[13049](https://bugs.otrs.org/show_bug.cgi?id=13049) - System Configuration setting value is not valid! - can not be enabled again.
 - 2017-09-05 Fixed bug#[12843](https://bugs.otrs.org/show_bug.cgi?id=12843) - Ticket Notifications over 4.000 characters are being removed from db.
 - 2017-09-05 Fixed bug#[13047](https://bugs.otrs.org/show_bug.cgi?id=13047) - High contrast skin visibilty issues.
 - 2017-09-05 Fixed bug#[13053](https://bugs.otrs.org/show_bug.cgi?id=13053) - There are no dialogs available at this point in the process is not shown.
 - 2017-09-04 Fixed bug#[13071](https://bugs.otrs.org/show_bug.cgi?id=13071) - SysConfig UT errors.
 - 2017-09-04 Fixed bug#[12955](https://bugs.otrs.org/show_bug.cgi?id=12955) - System Configuration is detected dirty when a User Specific Setting is still dirty.
 - 2017-09-01 Fixed bug#[13103](https://bugs.otrs.org/show_bug.cgi?id=13103) - Sorting in admin favourites is id based.
 - 2017-09-01 Fixed bug#[13081](https://bugs.otrs.org/show_bug.cgi?id=13081) - Article field not mandatory if attachment is added.
 - 2017-09-01 Fixed bug#[13094](https://bugs.otrs.org/show_bug.cgi?id=13094) - Admin->Performance log enable/disable leads to System Configuration start page instead of correct setting.
 - 2017-08-31 Fixed bug#[12953](https://bugs.otrs.org/show_bug.cgi?id=12953) - AJAXLoader in autocomplete box disapears when typing longer terms.

# 6.0.0.beta1 2017-09-05
 - 2017-08-25 Improved XSLT mapping functionality.
     Added XSLT regex functionality.
     Improved XSLT backend (module handling and error reporting).
     Added richtext (ckeditor/codemirror) functionality to XSLT frontend.
     Improved XSLT frontend (wording, structure).
     Added data include functionality to XSLT mapping.
 - 2017-08-24 Added error handling to the Generic Interface.
     Configurable retry module for requester.
 - 2017-08-23 Added numerous Generic Interface improvements.
     Updated default web service configurations.
     Improved Authentication, Proxy and SSL handling in SOAP and REST transport.
     Improved usability of debugger.
     Added SOAPAction naming flexibility.
     Improved SOAP output generation.
     Prevent usage of invalid web services in provider.
     Globally changed wording from 'webservice' to 'web service'.
 - 2017-08-23 Added a new mechanism to autoload Perl files to override existing functionality from custom packages (please see `Kernel/Autoload/Test.pm` for a demo).
 - 2017-08-21 Added new SysConfig setting 'Ticket::Frontend::UserDefaultQueue' to set a pre-selected queue for ticket creation. This is available in New Phone, Email and Process screens.
 - 2017-08-17 Fixed bug#[8301](https://bugs.otrs.org/show_bug.cgi?id=8301) - Unable to use Pending UntilTime in notifications.
 - 2017-08-16 Added possibility to stay in ticket zoom screen after an action that sets ticket into a closed state, instead of been redirected to the last overview or dashboard. This functionality can toggled by using the new SysConfig setting 'Ticket::Frontend::RedirectAfterCloseDisabled'.
 - 2017-08-15 Fixed bug#[13042](https://bugs.otrs.org/show_bug.cgi?id=13042) - ViewEmailResend is not located in navigation group Frontend::Agent::View.
 - 2017-08-15 Fixed bug#[13050](https://bugs.otrs.org/show_bug.cgi?id=13050) - Dropdown fields in ACL editor not modernized.
 - 2017-08-15 Fixed bug#[12927](https://bugs.otrs.org/show_bug.cgi?id=12927) - Web Notifications kills PostMaster::Read performance.
 - 2017-08-15 Fixed bug#[13034](https://bugs.otrs.org/show_bug.cgi?id=13034) - Enable SMIME and/or PGP Support jumps to wrong setting.
 - 2017-08-12 Merged FAO OTRSGenericInterfaceInvokerEventFilter.
 - 2017-08-11 Made bcrypt cost configurable for agent and customer password hashing, thanks to Pawel Boguslawski.
 - 2017-08-09 Reduced Daemon debug information.
 - 2017-08-09 Removed RHEL6 spec files as it is not supported with OTRS 6 (Perl version too old).
 - 2017-08-09 Fixed bug#[13000](https://bugs.otrs.org/show_bug.cgi?id=13000) - Error message in the log when changing out of office time in user preferences.
 - 2017-08-09 Fixed bug#[13005](https://bugs.otrs.org/show_bug.cgi?id=13005) - Enable Ticket Service link is broken.
 - 2017-08-09 Fixed bug#[12970](https://bugs.otrs.org/show_bug.cgi?id=12970) - Issue with text overflow and scroll.
 - 2017-08-09 Fixed bug#[12999](https://bugs.otrs.org/show_bug.cgi?id=12999) - Error when changing user data (agent data) or adding a user in AdminUser.pm.
 - 2017-08-09 Fixed bug#[13001](https://bugs.otrs.org/show_bug.cgi?id=13001) - Duplicated description for the password field in the admin user add screen.
 - 2017-08-09 Fixed bug#[12984](https://bugs.otrs.org/show_bug.cgi?id=12984) - Customer naming convention in link object table.
 - 2017-08-07 Added improvements for the user online dashboard widget.
 - 2017-08-05 Added Generic Interface operation SessionGet, thanks to Marco Ferrante.
 - 2017-08-04 Added possibility to store unfinished ticket forms as drafts for later reuse.
 - 2017-08-03 Speed up configuration file loading by dropping support for the old configuration format (1) and instead enforcing the new package-based format (1.1) for Perl configuration files. OTRS 6+ can only load files with this format, please make sure to convert any custom developments to it (see Kernel/Config/Files/ZZZ*.pm for examples).
 - 2017-08-01 Added Ticket event module to lock new tickets to the agents that creates them.
 - 2017-08-01 Dropped obsolete create_time_unix columns from ticket and ticket_index tables. Use create_time instead.
 - 2017-07-28 Fixed bug#[12104](https://bugs.otrs.org/show_bug.cgi?id=12104) - TimeAccounting statistic silently returns only last full month unless Period filter is used.
 - 2017-07-25 Fixed bug#[12580](https://bugs.otrs.org/show_bug.cgi?id=12580) - Processes cannot be listed in search view.
 - 2017-07-24 Added ObjectDataGet() to dynamic field object types, for OTRS Business Solution™.
 - 2017-07-24 Added drag & drop multi upload functionality to agent and customer interface.
 - 2017-07-21 Fixed bug#[12958](https://bugs.otrs.org/show_bug.cgi?id=12958) - OTRSAppointmentCalendar Module sends an update notification when an event is deleted.
 - 2017-07-20 Fixed bug#[11643](https://bugs.otrs.org/show_bug.cgi?id=11643) - No validity check for GoogleAuthenticator shared secret.
 - 2017-07-20 Fixed bug#[12610](https://bugs.otrs.org/show_bug.cgi?id=12610) - Ticket history comments are not translated.
 - 2017-07-18 Fixed bug#[12945](https://bugs.otrs.org/show_bug.cgi?id=12945) - Assigned appointments notification is not translated.
 - 2017-07-18 Added possibility to send notifications to agent who created a ticket, thanks to Dian Tong Software.
 - 2017-07-18 Fixed bug#[12929](https://bugs.otrs.org/show_bug.cgi?id=12929) - Commented SysConfig settings are still set in the DB.
 - 2017-07-17 Added the possibility to add an external link to the action menu in AgentTicketZoom, thanks to Paweł Bogusławski.
 - 2017-07-14 Fixed bug#[12914](https://bugs.otrs.org/show_bug.cgi?id=12914) - ACLs using Process Propoerties only work when written in certain ways.
 - 2017-07-13 Updated all bundled CPAN modules to their current versions.
 - 2017-07-11 Fixed bug#[12893](https://bugs.otrs.org/show_bug.cgi?id=12893) - Missing documentation about SSL. Added new configuration setting HTTPSForceRedirect that can be used to ensure HTTPS-only GUI usage.
 - 2017-07-11 Fixed bug#[12870](https://bugs.otrs.org/show_bug.cgi?id=12870) - Display of zero values in SysConfig.
 - 2017-07-07 Fixed bug#[6682](https://bugs.otrs.org/show_bug.cgi?id=6682) - Line filled for permissions when selecting "rw".
 - 2017-07-04 Fixed bug#[11520](https://bugs.otrs.org/show_bug.cgi?id=11520) - Human readable history entry for dynamic fields.
 - 2017-07-03 Fixed bug#[12896](https://bugs.otrs.org/show_bug.cgi?id=12896) - SysConfig not possible to save empty value.
 - 2017-07-03 Fixed bug#[12884](https://bugs.otrs.org/show_bug.cgi?id=12884) - Wrong field type for migrated setting.
 - 2017-06-30 Fixed bug#[12491](https://bugs.otrs.org/show_bug.cgi?id=12491) - TicketSlaveLinkAdd, TicketSlaveLinkDelete, TicketMasterLinkDelete events are not triggered.
 - 2017-06-30 Added new FirstnameLastname configuration value for proper Chinese name formatting, thanks to Dian Tong Software.
 - 2017-06-28 Fixed bug#[11028](https://bugs.otrs.org/show_bug.cgi?id=11028) - Owner and responsible always pre-selected in initial process screen.
 - 2017-06-27 Fixed bug#[11422](https://bugs.otrs.org/show_bug.cgi?id=11422) - List in the Dashboard: standard priority is ignored if you use a filter.
 - 2017-06-23 Fixed bug#[12850](https://bugs.otrs.org/show_bug.cgi?id=12850) - Pre-Selection for processes directly in the URL doesn't work any longer.
 - 2017-06-21 Added Generic Interface TicketGet operation response attribute 'TimeUnit', thanks to Thomas Wouters.
 - 2017-06-21 Fixed bug#[12869](https://bugs.otrs.org/show_bug.cgi?id=12869) - Queue highlighting is not possible to disable.
 - 2017-06-19 Added Generic Interface debug log cleanup console command and daemon task.
 - 2017-06-19 Added Generic Interface operation TicketHistoryGet, thanks to Renée Bäcker.
 - 2017-06-15 Fixed bug#[12848](https://bugs.otrs.org/show_bug.cgi?id=12848) - Quoting is not visible in the Rich Text Editor.
 - 2017-06-12 Fixed bug#[12827](https://bugs.otrs.org/show_bug.cgi?id=12827) - Translation of error messages is not applied in preferences.
 - 2017-06-09 Fixed bug#[12851](https://bugs.otrs.org/show_bug.cgi?id=12851) - Duplicated favorite entry in the new admin overview.
 - 2017-06-01 Improved otrs.CheckModules.pl for FreeBSD, thanks to Felix J. Ogris.
 - 2017-05-30 Fixed bug#[12837](https://bugs.otrs.org/show_bug.cgi?id=12837) - Existing Dynamic Field's RegEx config cannot be removed.
 - 2017-05-29 Added a high-contrast skin for visually impaired users to ease usability.
 - 2017-05-26 Added PostMaster state keep feature via additional xheaders.
 - 2017-05-26 Added information about the ticket responsible to medium and preview view in ticket lists, thanks to frennkie.
 - 2017-05-26 Added the possibility to include the ticket data in web service response data.
 - 2017-05-26 Added support for smart tags in the TicketCreate TransitionAction.
 - 2017-05-24 Added support for additional response headers in REST and SOAP provider configuration.
 - 2017-05-23 Extended Unit test Escalations.t for test case described at https://bugs.otrs.org/show_bug.cgi?id=11243.
 - 2017-05-23 Fixed bug#[11461](https://bugs.otrs.org/show_bug.cgi?id=11461) - Ticket search ignores the Condition TicketNumber => 0.
 - 2017-05-23 Fixed bug#[7958](https://bugs.otrs.org/show_bug.cgi?id=7958) - Agent email-address is visible in CustomerTicketZoom on note-external.
 - 2017-05-23 Show the name of the used search template on the search result screen.
 - 2017-05-22 Added the possibility to use the auto complete search for the customer ID selection in the AdminCustomerUser frontend.
 - 2017-05-19 Added setting TimeInputMinutesStep to allow for reducing the available options in time selection drop downs by given steps (e.g. only every 10 minutes).
 - 2017-05-16 Removed spell check feature from OTRS. Please use the according functionality of your browser or available plug-ins for it.
 - 2017-05-15 Moved ticket number counter from the TicketCounter.log file to the database. This allows OTRS to process incoming e-mails much faster and in parallel.
 - 2017-05-11 Fixed bug#[10509](https://bugs.otrs.org/show_bug.cgi?id=10509) - Incorrect handling of empty mime parts.
 - 2017-05-11 Fixed bug#[11910](https://bugs.otrs.org/show_bug.cgi?id=11910) - URLs sometimes get replaced with [#####] characters.
 - 2017-05-11 Fixed bug#[12442](https://bugs.otrs.org/show_bug.cgi?id=12442) - Add-ons verification fails in some Oracle configurations because they are stored as CHAR instead of BLOB.
 - 2017-05-11 Fixed bug#[11066](https://bugs.otrs.org/show_bug.cgi?id=11066) - Can only spell check everything or nothing.
 - 2017-05-10 Fixed bug#[12607](https://bugs.otrs.org/show_bug.cgi?id=12607) - Missing explanation for sending e-mail at bulk menu (not obvious).
 - 2017-05-10 Fixed bug#[8089](https://bugs.otrs.org/show_bug.cgi?id=8089) - Escalated Tickets widget does not show time as in other dashboard widgets.
 - 2017-05-09 Added SHA-512 as new password digest method to agent and customer authentication.
 - 2017-05-08 Fixed bug#[8249](http://bugs.otrs.org/show_bug.cgi?id=8249) - System addresses should be unique.
 - 2017-05-08 Fixed bug#[12193](https://bugs.otrs.org/show_bug.cgi?id=12193) - Article never decrypted when StoreDecryptedData set to no.
     Disabling permanent storage of decrypted articles caused encrypted articles to be virtually unusable on any OTRS system that didn't use specific customized code for decryption.
     OTRS currently isn't equipped to decrypt and display mails and their attachments on the fly in ticket zoom.
     Therefore the SysConfig options to disable permanent decryption (PGP::StoreDecryptedData and SMIME::StoreDecryptedData) have been removed.
 - 2017-05-08 Fixed bug#[9397](https://bugs.otrs.org/show_bug.cgi?id=9397) - User time zone isn't considered in the ticket search.
 - 2017-05-02 Require at least PostgreSQL 9.2.
 - 2017-04-24 Fixed bug#[12788](https://bugs.otrs.org/show_bug.cgi?id=12788) - Error during DB Update Script when Appointment tables already exist.
 - 2017-04-19 Fixed bug#[10873](https://bugs.otrs.org/show_bug.cgi?id=10873)(PR#1706) - Agent names sorted incorrectly in AgentTicketSearch. Thanks to S7!
 - 2017-04-11 Improved the customer id selection for the ticket frontends and added the autocomplete search for the customer fields in the ticket search and statistics.
 - 2017-04-11 Added the Customer User Information Center frontend.
 - 2017-04-11 Added support for multi-tiered customer and customer user relationships.
 - 2017-04-04 Added new recipient notification groups 'AllRecipientsFirstArticle' and 'AllRecipientsLastArticle'.
 - 2017-04-04 Added new db function 'QueryInCondition' (bug#9723).
 - 2017-03-31 Fixed bug#[8811](https://bugs.otrs.org/show_bug.cgi?id=8811) - Link screen doesn't indicate search progress in any way.
 - 2017-03-30 Fixed bug#[12696](https://bugs.otrs.org/show_bug.cgi?id=12696) - Follow-up: radio buttons were partically overlapped in mobile mode.
 - 2017-03-29 Fixed bug#[12704](https://bugs.otrs.org/show_bug.cgi?id=12704)(PR#1664) - Ticket age values in statistic export is in seconds (not human readable). Thanks to S7!
 - 2017-03-28 Added option to display number of all customer tickets in AgentTicketZoom.
 - 2017-03-28 Fixed bug#[12696](https://bugs.otrs.org/show_bug.cgi?id=12696) - Missing save button from personal preferences in mobile mode.
 - 2017-03-24 Modernized address book. It is now possible to search for all configured custom user and customer fields.
 - 2017-03-21 Fixed bug#[12188](https://bugs.otrs.org/show_bug.cgi?id=12188)(PR#1661) - Dashboard stats do not refresh automatically. Thanks to S7!
 - 2017-03-18 (PR#1550) Added possibility to prevent return of attachments content in Generic Interface TicketGet operation and added FileID, thanks to Esteban Marín
 - 2017-03-18 Changed TicketSearch GenericInterface operation dynamic fields API parameters.
 - 2017-03-18 Fixed bug#[12655](https://bugs.otrs.org/show_bug.cgi?id=12655) - Invalid WSDL for TicketSearch operation.
 - 2017-03-17 Use the configured product name in messages and other places instead of hardcoded "OTRS".
 - 2017-03-10 Fixed bug#[12477](https://bugs.otrs.org/show_bug.cgi?id=12477) - Untranslated string in 7 days statistic.
 - 2017-03-09 Implemented new System Configuration mechanism.
 - 2017-03-08 Fixed bug#[12502](https://bugs.otrs.org/show_bug.cgi?id=12502) - Agent gets "Session invalid" if large group names are used.
 - 2017-03-06 Merged FAO OTRSAppointmentCalendar.
 - 2017-02-17 Fixed bug#[8853](https://bugs.otrs.org/show_bug.cgi?id=8853) - Hardcoded Priority and State in bin/otrs.FillDB.pl.
 - 2017-02-17 Add support for setting owner and responsible via filter also for follow-ups, thanks to Renée Bäcker.
 - 2017-01-20 Added command to list configured queues, thanks to Martin Burggraf.
 - 2017-01-13 Blinking mechanism for queues is now disabled by default (can be enabled using Ticket::Frontend::AgentTicketQueue###Blink).
 - 2016-12-19 Added the posibility to filter content of the CCI Dashboard Widget.
 - 2016-12-08 Updated CPAN module YAML to version 1.20.
 - 2016-11-25 (PR#1124) Added new SysConfig setting 'Daemon::Log::RotationType' to use internal or external log file rotation mechanism, thanks to Pawel Boguslawski.
 - 2016-11-21 Redesigned admin overview screen; add items as favourite by hovering over it and clicking the star icon; switch between grid and listview by clicking the icon on the top right.
 - 2016-11-04 Make it possible to search for emtpy dynamic fields via the TicketSearch API, thanks to Rolf Schmidt and Moritz Lenz.
 - 2016-11-02 Added sort criteria to TicketSearch call in PendingCheck console command. Thanks to Torsten Thau.
 - 2016-10-31 Removed default queue group restriction from TicketQueueOverview dashlet.
 - 2016-10-28 Fixed bug#[12374](https://bugs.otrs.org/show_bug.cgi?id=12374) - ticket deleting on postgresql is slow.
 - 2016-10-26 Updated translations, thanks to all translators.
 - 2016-10-21 Fixed bug#[12285](http://bugs.otrs.org/show_bug.cgi?id=12285) - Invalid customer user still receive admin notification.
 - 2016-10-20 Simplified the way how fontawesome is being integrated to ease future updates and updated to 4.6.3.
 - 2016-09-21 Fixed bug#[12065](http://bugs.otrs.org/show_bug.cgi?id=12065) - queue and state not mandatory.
 - 2016-09-12 Fixed bug#[11365](http://bugs.otrs.org/show_bug.cgi?id=11365) - ACLs editor shows actions where ACLs does not apply.
 - 2016-09-08 Made possible to define ServiceIDs and SLAIDs as default shown ticket search attributes, thanks to Paweł Bogusławski.
 - 2016-09-08 Fixed status passing and redundant TicketGet calls, thanks to Paweł Bogusławski.
 - 2016-09-08 Fixed bug#[5420](http://bugs.otrs.org/show_bug.cgi?id=5420) - Email received with many recipients or large 'From' can't be created in OTRS.
 - 2016-09-07 Fixed empty attachment links and file size formatting, thanks to Paweł Bogusławski.
 - 2016-08-25 Added possibility to send encrypted emails to multiple recipients.
 - 2016-06-07 Added index for searching dynamic field text values.
 - 2016-08-18 Added per-address email loop protection setting (PostmasterMaxEmailsPerAddress), thanks to Moritz Lenz.
 - 2016-08-12 Fixed bug#[12229](http://bugs.otrs.org/show_bug.cgi?id=12229) - Queue is not selectable if the name contains "<" or ">" characters.
 - 2015-08-01 Updated CPAN module CGI to version 4.32.
 - 2016-07-26 Added a new postmaster filter to decrypt and handle encrypted mails.
 - 2016-07-18 Fixed bug#[7860](http://bugs.otrs.org/show_bug.cgi?id=7860) - AgentTicketSearch and Statistics are missing TicketPending option.
 - 2016-07-13 Added a javascript templating mechanism. Use Core.Template.Render() to fill given templates from either files or strings with data.
 - 2016-06-24 Improved TicketSearch() to return error on a search for inexistent dynamic fields instead of ignoring them, thanks to Moritz Lenz.
 - 2016-06-06 Added checks for length of words in search terms when using search index/StaticDB backend.
 - 2016-06-06 Fixed bug#[12020](http://bugs.otrs.org/show_bug.cgi?id=12020) - Option CaseSensitive has no impact on external customer database.
 - 2016-06-03 Improved default procmail config (disabled comsat and added postmaster pipe waiting), thanks to Pawel Boguslawski.
 - 2016-06-03 Speed up TicketNewMessageUpdate, thanks to Moritz Lenz.
 - 2016-06-03 Make it possible to re-enable auto responses from Postmaster filters by setting X-OTRS-Loop to no/false, thanks to Pawel Boguslawski.
 - 2016-06-03 Make it possible to configure which ticket state types to show striked trhough in the link table, thanks to Renée Bäcker.
 - 2016-06-03 Improved web upload cache performance, thanks to Pawel Boguslawski.
 - 2016-06-03 Added an interactive OTRS API shell (Dev::Tools::Shell, aka REPL), special thanks to Thorsten Eckel.
 - 2016-06-03 Added dynamic field support for customer users and companies. To set it up: 1) Add dynamic fields for the new types (via AdminDynamicField). 2) Extend the CustomerUser and CustomerCompany mapping with the dynamic fields. See example mappings in Kernel::Config::Defaults.
 - 2016-05-04 Added the possiblity to configure the responsible field as mandatory (enabled by default for AgentTicketResponsible, if responsible feature is enabled), thanks to S7.
 - 2016-04-29 Reduced error log noise by reducing the log level of less important messages, thanks to Pawel Boguslawski.
 - 2016-04-29 Fixed parsing CSV data with quoted values containing newlines, thanks to Pawel Boguslawski.
 - 2016-04-29 Added support for real time zones like Europe/Berlin. Dropped support for time offsets like +2.
 - 2016-04-26 Added possibility to push custom data directly from Perl code to JavaScript without having to embed it into templates.
 - 2016-04-26 Added possibility to translate strings directly in JavaScript files.
 - 2016-04-22 Added possibility to set the ticket title in Postmaster filters, thanks to Renée Bäcker.
 - 2016-04-15 Added possibility to use multiple named captures in Postmaster filters, thanks to Renée Bäcker.
 - 2016-04-08 Removed dummy 'Reply All' and 'Forward' options to align with 'Reply' select, thanks to Nils Leideck.
 - 2016-04-01 Fixed dropdown for CustomerTicketOverview.
 - 2016-04-01 Changed reply template selection to not include -Reply- anymore but a label instead, thanks to Nils Leideck.
 - 2016-03-29 Added possibility to configure default headers for outgoing emails (Sendmail::DefaultHeaders), thanks to Renée Bäcker.
 - 2016-03-04 Fixed bug#[11787](http://bugs.otrs.org/show_bug.cgi?id=11787) - No Ticket::StateAfterPending found with manual state update.
 - 2016-03-03 Fixed bug#[7542](http://bugs.otrs.org/show_bug.cgi?id=7542) - Results of HistoryTicketStatusGet() are slightly wrong (and don't take time zones into account)
 - 2016-03-03 Fixed bug#[11872](http://bugs.otrs.org/show_bug.cgi?id=11872) - TicketGet function returns SolutionTime variable.
 - 2016-03-03 Fixed bug#[8631](http://bugs.otrs.org/show_bug.cgi?id=8631) - "ghost" tickets after merge.
 - 2016-03-02 Fixed bug#[8313](http://bugs.otrs.org/show_bug.cgi?id=8313) - No such package: package-x.x.x message in package installation.
 - 2016-03-02 Fixed bug#[8055](http://bugs.otrs.org/show_bug.cgi?id=8055) - Disable Add/Edit customers when usign LDAP.
 - 2016-03-01 Updated CPAN module Net::SSLGlue to version 1.055.
 - 2016-03-01 Fixed bug#[11858](http://bugs.otrs.org/show_bug.cgi?id=11858) - Queues can just choose between 50 Calendar.
 - 2016-02-19 Fixed bug#[11468](http://bugs.otrs.org/show_bug.cgi?id=11468) - Using SVG images for Agent and Customer logo requires additional CSS.
 - 2016-02-19 Added dynamic filter fields to several admin frontends, thanks to Nils Leideck.
 - 2016-02-19 Fixed bug#[8298](http://bugs.otrs.org/show_bug.cgi?id=8298) - Made use of "Submit" and "Save" buttons more consistent, thanks to Niels Dimmers.
 - 2016-02-18 Drop deprecated unused ObjectLockState package and gi_object_lock_state table.
 - 2016-02-16 Added possibility to create non-singleton objects to the ObjectManager via Create().
 - 2016-02-16 Add support for JSON pretty print, thanks to Renée Bäcker.
 - 2016-02-05 Removed deprecated methods CustomerUserList() and GetTableData() (S7).
 - 2016-02-04 Modularized AgentTicketZoom, thanks to Moritz Lenz. It is now possible to add own widgets in the ticket zoom.
 - 2015-12-16 Fixed bug#[6333](http://bugs.otrs.org/show_bug.cgi?id=6333) - Ticket merging does not work with customized state name.
 - 2015-12-15 Fixed bug#[8653](http://bugs.otrs.org/show_bug.cgi?id=8653) - Sysconfig option ComposeExcludeCCRecipients for AgentTicketCompose is obsolete.
 - 2015-11-27 Added possibility to restrict Zoom and Print screens in the customer interface by using ACLs. Thanks to Sanjin Vik @ s7design.
 - 2015-11-27 Improved Generic Agent performance at deleting old execution times. Thanks to Moritz Lenz @ noris networks.
 - 2015-11-27 Improved command Maint::Ticket::InvalidUserCleanup. It can now now both unlock tickets of invalid users and also (optionally) change their state to make sure they will not be overlooked. Thanks to Moritz Lenz @ noris networks.

# 5.0.24 2017-11-21
 - 2017-12-26 Fixed bug#[13002](https://bugs.otrs.org/show_bug.cgi?id=13002) - Deep recursion error when notification is triggered for HistoryAdd event.
 - 2017-11-03 Fixed bug#[11165](https://bugs.otrs.org/show_bug.cgi?id=11165) - Agent list for Owner and Responsible fields in bulk screen is different.
 - 2017-11-03 Fixed bug#[13130](https://bugs.otrs.org/show_bug.cgi?id=13130) - Broken From-Header in auto response.
 - 2017-10-27 Fixed bug#[13241](https://bugs.otrs.org/show_bug.cgi?id=13241) - Index for fulltext search not created when body empty or contains only stopwords.
 - 2017-10-27 Fixed bug#[13142](https://bugs.otrs.org/show_bug.cgi?id=13142) - Error The given param 'QueueIDs' is invalid or an empty array reference!.
 - 2017-10-27 Fixed bug#[13162](https://bugs.otrs.org/show_bug.cgi?id=13162) - In the settings of Agent's personal profile drop down field of "Screen after new ticket" view is in English.
 - 2017-10-27 Fixed bug#[13222](https://bugs.otrs.org/show_bug.cgi?id=13222) - Missing QueueID in AgentTicketPhone causes ACL error during the creation of a ticket.
 - 2017-10-26 Fixed bug#[13212](https://bugs.otrs.org/show_bug.cgi?id=13212) - Queue filter in dashboard not working for "Tickets in My Queues".
 - 2017-10-26 Fixed bug#[13244](https://bugs.otrs.org/show_bug.cgi?id=13244) - Visibility issues when hovering over "No data found." row.
 - 2017-10-24 Fixed bug#[12832](https://bugs.otrs.org/show_bug.cgi?id=12832) - Sort options for SOAP will not be saved.
 - 2017-10-20 Fixed bug#[11208](https://bugs.otrs.org/show_bug.cgi?id=11208) - OTRS installer.pl does not allow installing on MyISAM MySQL.
 - 2017-10-16 Fixed bug#[13032](https://bugs.otrs.org/show_bug.cgi?id=13032) - Search window closes on outside click.
 - 2017-10-13 Fixed bug#[13092](https://bugs.otrs.org/show_bug.cgi?id=13092) - ChangeTime of target ticket not updated on ticket merge.
 - 2017-10-13 Fixed bug#[13204](https://bugs.otrs.org/show_bug.cgi?id=13204) - Error when copying ACL.
 - 2017-10-11 Fixed bug#[12957](https://bugs.otrs.org/show_bug.cgi?id=12957) - SMTPS and SMTPTLS sending mail doesn't work on Ubuntu Server 16.04.2 LTS.
 - 2017-10-09 Fixed bug#[13205](https://bugs.otrs.org/show_bug.cgi?id=13205)(PR#1849) - No TreeView Queue selection in AgentTicketActionCommon after AjaxUpdate, thanks to Thorsten Eckel.
 - 2017-09-28 Fixed bug#[13100](https://bugs.otrs.org/show_bug.cgi?id=13100) - Ticket move action in ticket overview screens is not modernized.
 - 2017-09-25 Fixed bug#[13152](https://bugs.otrs.org/show_bug.cgi?id=13152) - TicketCreate log entry if Service is used for unknown customer.
 - 2017-09-25 Fixed bug#[12868](https://bugs.otrs.org/show_bug.cgi?id=12868) - SysConfig does not show overridden settings as readonly.
 - 2017-09-21 Fixed bug#[12858](https://bugs.otrs.org/show_bug.cgi?id=12858) - Daemon duplicate task identifiers.
 - 2017-09-21 Fixed bug#[13033](https://bugs.otrs.org/show_bug.cgi?id=13033) - Postmaster Filter Area - unused space - usability is bad.
 - 2017-09-19 Fixed bug#[13151](https://bugs.otrs.org/show_bug.cgi?id=13151) - Can't switch between mobil and desktop mode when Secure::DisableBanner.
 - 2017-09-14 Fixed bug#[13086](https://bugs.otrs.org/show_bug.cgi?id=13086) - Owner is resetted in AgentTicketFreeText if moved to another queue.

 #5.0.23 2017-09-19
 - 2017-09-13 Fixed bug#[13088](https://bugs.otrs.org/show_bug.cgi?id=13088) - EscalationTime shows in seconds in CSV export.
 - 2017-09-13 Fixed bug#[13035](https://bugs.otrs.org/show_bug.cgi?id=13075) - OTRS notification option for OTRS Business Solution™ Feature are shown in the free.
 - 2017-09-06 Fixed bug#[12569](https://bugs.otrs.org/show_bug.cgi?id=12569) - Missing explanation users (with visual impairments) in the 'Preferences' page.
 - 2017-09-05 Fixed bug#[13019](https://bugs.otrs.org/show_bug.cgi?id=13019) - Service translated in AdminSLA overview screen.
 - 2017-08-25 Fixed bug#[13075](https://bugs.otrs.org/show_bug.cgi?id=13075) - Short description for "pending time" not shown in D.
 - 2017-08-15 Fixed bug#[13052](https://bugs.otrs.org/show_bug.cgi?id=13052) - Explaining text is missing from the New ticket viewon the customer interface in case of mandatory texts.
 - 2017-08-15 Fixed bug#[12990](https://bugs.otrs.org/show_bug.cgi?id=12990) - Ticket Menu Module is overlapping.
 - 2017-08-14 Added possibility to specify a different directory where the OTRS Daemon creates its PID files by using the new SysConfig setting: 'Daemon::PID::Path'.
 - 2017-08-14 Fixed bug#[13054](https://bugs.otrs.org/show_bug.cgi?id=13054) - Daemon reports that is already running when it can't get the lock of the PID file.
 - 2017-08-10 Fixed bug#[12971](https://bugs.otrs.org/show_bug.cgi?id=12971) - AgentTicketMove - Queue list on AJAX update does not honor ListType setting.
 - 2017-08-09 Fixed bug#[13011](https://bugs.otrs.org/show_bug.cgi?id=13011) - Bad expires value in cookie.
 - 2017-08-08 Fixed bug#[11512](https://bugs.otrs.org/show_bug.cgi?id=11512) - ACL Type field restriction on DynamicField change in AgentTicketProcess does not work.
 - 2017-08-07 Fixed bug#[13003](https://bugs.otrs.org/show_bug.cgi?id=13003) - Statistic shows Out of Office info in agent name.
 - 2017-08-02 Fixed bug#[12871](https://bugs.otrs.org/show_bug.cgi?id=12871) - TicketACL->\_GetChecks fills Param with Ticket values and form ones are lost.
 - 2017-07-28 Fixed bug#[12933](https://bugs.otrs.org/show_bug.cgi?id=12933) - Change value for Order by column in report doesn't store.

# 5.0.22 2017-08-01
 - 2017-07-27 Updated translations, thanks to all translators.
 - 2017-07-27 Decreased the default value for the 'SessionMaxIdleTime' to two hours and fixed session counting to ignore sessions originating from the GenericInterface.
 - 2017-07-26 Reverted fix for bug#[11843](https://bugs.otrs.org/show_bug.cgi?id=11843) - Notifications tag CUSTOMER_FROM gets replaced by CUSTOMER_REALNAME.
 - 2017-07-20 Fixed bug#[12962](https://bugs.otrs.org/show_bug.cgi?id=12962) - Dynamic fields list values are not update when state is changed in AgentTicketActionCommon.
 - 2017-07-20 Fixed bug#[12928](https://bugs.otrs.org/show_bug.cgi?id=12928) - Web Service configuration does not let to delete invalid Operations or Invokers.
 - 2017-07-17 Fixed bug#[12913](https://bugs.otrs.org/show_bug.cgi?id=12913) - Articles do not load in IFRAME.
 - 2017-07-13 Fixed bug#[12734](https://bugs.otrs.org/show_bug.cgi?id=12734) - Dropdown not considered into TicketSolutionResponseTime Statistic.

# 5.0.21 2017-07-18
 - 2017-07-10 Updated translations, thanks to all translators.
 - 2017-07-10 Fixed bug#[12918](https://bugs.otrs.org/show_bug.cgi?id=12918) - Wrong ticket escalation solution time notification.
 - 2017-07-10 Fixed bug#[12930](https://bugs.otrs.org/show_bug.cgi?id=12930) - Dynamic field headers are not translated in Small overview.
 - 2017-07-10 Fixed bug#[12931](https://bugs.otrs.org/show_bug.cgi?id=12931) - Notification of escalated tickets is not displayed in service view.
 - 2017-06-21 Fixed bug#[12881](https://bugs.otrs.org/show_bug.cgi?id=12881) - Cache FileStorable race conditions provokes "Magic number checking on storable string failed" messages.
 - 2017-07-08 Updated translations, thanks to all translators.
 - 2017-07-07 Fixed bug#[12671](https://bugs.otrs.org/show_bug.cgi?id=12671) - ACL to restrict Status based on InputFields (TicketProperties) not working as expected.
 - 2017-07-07 Fixed bug#[12904](https://bugs.otrs.org/show_bug.cgi?id=12904) - Ticket::Frontend::CustomerSearchAutoComplete used in CustomerTicketProcess but not in SysConfig available.
 - 2017-07-06 Reverted fix for bug#[7811](https://bugs.otrs.org/show_bug.cgi?id=7811) - GenericAgent Search produces inconsistent results.
 - 2017-07-03 Fixed bug#[12865](https://bugs.otrs.org/show_bug.cgi?id=12865) - Send empty Mail reply without Quote.
 - 2017-07-03 Fixed bug#[12891](https://bugs.otrs.org/show_bug.cgi?id=12891) - Article Forward creates a wrong Time Stamp in Mail View.
 - 2017-06-30 Fixed bug#[12883](https://bugs.otrs.org/show_bug.cgi?id=12883) - From parameter in URL for preallocation of customer not working if customer user name is contained in customer ID.
 - 2017-06-27 Fixed bug#[12108](https://bugs.otrs.org/show_bug.cgi?id=12108) - Kernel::System::EmailParser not fully functional in Entity-Mode.
 - 2017-06-27 Fixed bug#[10683](https://bugs.otrs.org/show_bug.cgi?id=10683) - Custom column order in dashboard gets mixed after changing the "shown tickets" value.
 - 2017-06-26 Fixed bug#[12560](https://bugs.otrs.org/show_bug.cgi?id=12560) - Search DynamicField or Condition.
 - 2017-06-26 Fixed bug#[9731](https://bugs.otrs.org/show_bug.cgi?id=9731) - Reply screen uses only email instead of full customer details.
 - 2017-06-23 Fixed bug#[12850](https://bugs.otrs.org/show_bug.cgi?id=12850) - Pre-Selection for processes directly in the URL doesn't work any longer.
 - 2017-06-16 Fixed byg#[12892](https://bugs.otrs.org/show_bug.cgi?id=12892) - CreatedBy-User: No real name in overview.
 - 2017-06-15 Fixed bug#[12703](https://bugs.otrs.org/show_bug.cgi?id=12703) - dynamic list and dynamic matrix interpret agent/user Userfirstname.
 - 2017-06-15 Fixed bug#[12829](https://bugs.otrs.org/show_bug.cgi?id=12829) - Scheduler Daemon sends mail account password in plain text via E-mail.
 - 2017-06-15 Follow-up fix for bug#[12090](http://bugs.otrs.org/show_bug.cgi?id=12090) - 2 second sleep between email fetching causes bad performance on systems with high email traffic.
 - 2017-06-15 Fixed bug#[12885](https://bugs.otrs.org/show_bug.cgi?id=12885) - Customer User search shows always only one result.
 - 2017-06-15 Follow-up fix for bug#[11843](https://bugs.otrs.org/show_bug.cgi?id=11843) - Notifications tag CUSTOMER_FROM gets replaced by CUSTOMER_REALNAME.
 - 2017-06-14 Fixed bug#[11843](https://bugs.otrs.org/show_bug.cgi?id=11843) - Notifications tag CUSTOMER_FROM gets replaced by CUSTOMER_REALNAME. Thanks to S7.
 - 2017-06-14 Follow-up fix for bug#[11513](https://bugs.otrs.org/show_bug.cgi?id=11513) - Out of Office is missing in owner dropdown.
 - 2017-06-14 Fixed bug#[12781](https://bugs.otrs.org/show_bug.cgi?id=12781) - AdminCustomerCompany allows only one customer company backend.
 - 2017-06-14 Fixed bug#[12742](https://bugs.otrs.org/show_bug.cgi?id=12742) - IE 11: magnifying glass isn't visible.
 - 2017-06-13 Fixed bug#[12890](https://bugs.otrs.org/show_bug.cgi?id=12890) - Mask New Mail Ticket - signature frame require login.
 - 2017-06-13 Fixed bug#[12854](https://bugs.otrs.org/show_bug.cgi?id=12854) - ACL Editor shows wrong values.
 - 2017-06-12 Fixed bug#[12824](https://bugs.otrs.org/show_bug.cgi?id=12824) - AjaxErrorDialog visible when printing Ticket via Browser.
 - 2017-06-12 Fixed bug#[12808](https://bugs.otrs.org/show_bug.cgi?id=12808) - Wrong counting in Dashlets for "Ticket in My Queues".
 - 2017-06-09 Fixed bug#[12816](https://bugs.otrs.org/show_bug.cgi?id=12816) - GI Ticket operations require time value for Dynamic Fields of type "Date".
 - 2017-06-09 Fixed bug#[11212](https://bugs.otrs.org/show_bug.cgi?id=11212) - Validity of customer company has no impact in CIC search.
 - 2017-06-08 Removed the config option 'SessionActiveTime' and use from now the 'SessionMaxIdleTime' for the session limit.
 - 2017-06-08 Fixed bug#[10681](https://bugs.otrs.org/show_bug.cgi?id=10681) - Dynamic Field Creation Default Field Order Error.
 - 2017-06-07 Fixed bug#[12752](https://bugs.otrs.org/show_bug.cgi?id=12752) - Regular expression for dynamic field also affects search.
 - 2017-06-05 Fixed bug#[12835](https://bugs.otrs.org/show_bug.cgi?id=12835) - Wrong Event in History - ProcessManagement Article Field.
 - 2017-06-01 Fixed bug#[12862](https://bugs.otrs.org/show_bug.cgi?id=12862) - Queues don't update when ACL triggers.
 - 2017-06-01 Follow-up fix for bug#[10691](https://bugs.otrs.org/show_bug.cgi?id=10691) - No CustomerID shown after TicketCreate (for unknown customers): activate new config setting `PostMaster::NewTicket::AutoAssignCustomerIDForUnknownCustomers` by default, restoring old default behaviour on incoming mails with unknown customers.

# 5.0.20 2017-06-06
 - 2017-05-31 Updated translations, thanks to all translators.
 - 2017-05-31 Improved SecureMode detection in Installer.
 - 2017-05-31 Fixed bug#[12765](https://bugs.otrs.org/show_bug.cgi?id=12765) - Show page buttons of dynamic fields are not displayed in mobile view.
 - 2017-05-30 Masked passwords in Kernel/Config.pm and in files located in Kernel/Config/Files during SupportBundle create.
 - 2017-05-30 Fixed bug#[12740](https://bugs.otrs.org/show_bug.cgi?id=12740) - Notification to customer of the ticket is send more than once.
 - 2017-05-30 Fixed bug#[12819](https://bugs.otrs.org/show_bug.cgi?id=12819) - Unable to select queue if it contains two spaces.
 - 2017-05-30 Fixed bug#[12855](https://bugs.otrs.org/show_bug.cgi?id=12855) - Webservice HTTPBasicAuth User and Password Field are not escaped correct.
 - 2017-05-29 Fixed bug#[12735](https://bugs.otrs.org/show_bug.cgi?id=12735) - OTRS console does not allow adding of sub services when their name exists as a service.
 - 2017-05-29 Fixed bug#[12838](https://bugs.otrs.org/show_bug.cgi?id=12838) - Typo in SysConfig Frontend::NavBarModule###7-AgentTicketService.
 - 2017-05-29 Fixed bug#[12762](https://bugs.otrs.org/show_bug.cgi?id=12762) - Missing information in the process ticket (follow up Bug 12443).
 - 2017-05-26 Fixed bug#[12482](https://bugs.otrs.org/show_bug.cgi?id=12482) - Show link URL of DF doesn't work in CustomerTicketZoom.
 - 2017-05-26 Fixed bug#[12853](https://bugs.otrs.org/show_bug.cgi?id=12853) - Notification tags like OTRS_CUSTOMER_DATA_* not working in AgentTicketEmail signature field.
 - 2017-05-26 Fixed bug#[12849](https://bugs.otrs.org/show_bug.cgi?id=12849) - Default entry sorting broken for e.g. AgentTicketPhone if 'Ticket::Frontend::ListType' set to 'list'.
 - 2017-05-23 Fixed bug#[12797](https://bugs.otrs.org/show_bug.cgi?id=12797) - Unknown Customer is not displayed in a Process Dialog.
 - 2017-05-19 Fixed bug#[12801](https://bugs.otrs.org/show_bug.cgi?id=12801) - Set Role validity state to invalid, doesn't effect permissions.
 - 2017-05-19 Follow-up fix for bug#[12701](https://bugs.otrs.org/show_bug.cgi?id=12701) - Default values of "Owner" and "Responsible" fields placed in the activity dialogs in the process tickets cannot be settled.
 - 2017-05-19 Fixed bug#[12834](https://bugs.otrs.org/show_bug.cgi?id=12834) - NotificationTag of a Date field displays a time-stamp "00:00".
 - 2017-05-17 Fixed bug#[12749](https://bugs.otrs.org/show_bug.cgi?id=12749) - Logo doesn't scale well on mobile view.
 - 2017-05-17 Fixed bug#[12743](https://bugs.otrs.org/show_bug.cgi?id=12743) - ACLs with ticket conditions are not matching on process list in AgentTicketProcess.
 - 2017-05-17 Fixed bug#[12832](https://bugs.otrs.org/show_bug.cgi?id=12832) - Sort options for SOAP will not be saved.
 - 2017-05-12 Fixed bug#[12796](https://bugs.otrs.org/show_bug.cgi?id=12796) - GenericInterface only works with FastCGI for GET requests.
 - 2017-05-11 Fixed bug#[12216](https://bugs.otrs.org/show_bug.cgi?id=12216) - Inconsistent behaviour in pop-ups which lock tickets.
 - 2017-05-11 Fixed bug#[12809](https://bugs.otrs.org/show_bug.cgi?id=12809) - Unable to select queue if queue comment is empty (with modified Ticket::Frontend::NewQueueSelectionString).
 - 2017-05-11 Fixed bug#[11066](https://bugs.otrs.org/show_bug.cgi?id=11066) - Can only spell check everything or nothing.
 - 2017-05-11 Fixed bug#[10685](https://bugs.otrs.org/show_bug.cgi?id=10685) - Removing an agent's access to a ticket while he is viewing the ticket leads to interface issues on the agent's side.
 - 2017-05-10 Fixed bug#[10569](https://bugs.otrs.org/show_bug.cgi?id=10569) - DynamicField of type date resets after ticket split.
 - 2017-05-10 Fixed bug#[7913](https://bugs.otrs.org/show_bug.cgi?id=7913) - Incorrect parsing of Content-Type with additional attributes.
 - 2017-05-10 Fixed bug#[6144](https://bugs.otrs.org/show_bug.cgi?id=6144) - Invaild System Email Address Problem.
 - 2017-05-09 Fixed bug#[12498](https://bugs.otrs.org/show_bug.cgi?id=12498) - An invalid date used in a search attribute returns a wrong result.
 - 2017-05-09 Fixed bug#[12613](https://bugs.otrs.org/show_bug.cgi?id=12613) - Accents are missing from accented letters.
 - 2017-05-09 Fixed bug#[12086](https://bugs.otrs.org/show_bug.cgi?id=12086) - Labels overflows for some languages.
 - 2017-05-09 Fixed bug#[4424](http://bugs.otrs.org/show_bug.cgi?id=4424) - Package Manager rebuild() creates invalid XML packages.
 - 2017-05-09 Fixed bug#[8249](http://bugs.otrs.org/show_bug.cgi?id=8249) - System addresses should be unique.
 - 2017-05-09 Fixed bug#[12417](https://bugs.otrs.org/show_bug.cgi?id=12417) - Missing CustomerCompanyName column from LinkObject.
 - 2017-05-09 Fixed bug#[9972](https://bugs.otrs.org/show_bug.cgi?id=9972) - Spelling check unit test is not working correctly.
 - 2017-05-09 Fixed bug#[12086](https://bugs.otrs.org/show_bug.cgi?id=12086) - Labels overflows for some languages.
 - 2017-05-09 Fixed bug#[12697](https://bugs.otrs.org/show_bug.cgi?id=12697) - Ticket menu in customer interface doesn't expand on touchscreen devices.
 - 2017-05-09 Updated UnitTest DynamicFieldFromCustomerUser with new scenarios (bug#12587).
 - 2017-05-09 Fixed bug#[12389](https://bugs.otrs.org/show_bug.cgi?id=12389) - Attachments with alias charsets are not properly processed in GenericInterface.
 - 2017-05-08 Fixed bug#[6751](http://bugs.otrs.org/show_bug.cgi?id=6751) - Problem if service name gets to long, or if service has too many subservices.
 - 2017-05-08 Fixed bug#[12286](https://bugs.otrs.org/show_bug.cgi?id=12286) - Article body with non-allowed characters breaks SOAP response.
 - 2017-05-08 Fixed bug#[12193](https://bugs.otrs.org/show_bug.cgi?id=12193) - Article never decrypted when StoreDecryptedData set to no.
 - 2017-05-08 Fixed bug#[12347](https://bugs.otrs.org/show_bug.cgi?id=12347) - Error message "No such TicketID" on ticket delete.
 - 2017-05-08 Fixed bug#[11508](https://bugs.otrs.org/show_bug.cgi?id=11508) - Change Date has a confussing label in the ticket list statistic result.
 - 2017-05-05 Fixed bug#[12791](https://bugs.otrs.org/show_bug.cgi?id=12791) - ArticleSend Documentation is incorrect.

# 5.0.19 2017-05-09
 - 2017-05-10 Fixed bug#[12572](https://bugs.otrs.org/show_bug.cgi?id=12572) - Non-process tickets generate error messages in the syslog if process data are allowed to be displayed.
 - 2017-05-04 Updated translations, thanks to all translators.
 - 2017-05-03 Fixed bug#[12803](https://bugs.otrs.org/show_bug.cgi?id=12803) - TranslationsUpdate console command does not consider strings from var/packagesetup folder.
 - 2017-05-03 Added a web timeout config option for the support data collection and suppress the log message, if the internal web request for the support data collection doesn't work.
 - 2017-05-02 Updated translations, thanks to all translators.
 - 2017-04-28 Fixed bug#[10556](https://bugs.otrs.org/show_bug.cgi?id=10556)(PR#1737) - Missing library used in IMAP authentication mechanism. Thanks to S7!
 - 2017-04-28 Fixed bug#[12784](https://bugs.otrs.org/show_bug.cgi?id=12784)(PR#1738) - Webservice Debugger shows no Entry. Thanks to S7!
 - 2017-04-27 Updated translations, thanks to all translators.
 - 2017-04-26 Fixed bug#[12783](https://bugs.otrs.org/show_bug.cgi?id=12783) - Display of Dynamic Field Date/Time values changed.
 - 2017-04-20 Fixed bug#[12773](https://bugs.otrs.org/show_bug.cgi?id=12773) - In case of big screen resolution the Subject field is too long.
 - 2017-04-19 Fixed bug#[12736](https://bugs.otrs.org/show_bug.cgi?id=12736)(PR#1709) - Malformed pgp-signed multipart mail can cause error in PGP.pm. Thanks to Michael and S7!
 - 2017-04-13 Fixed bug#[7811](https://bugs.otrs.org/show_bug.cgi?id=7811)(PR#1710) - GenericAgent Search produces inconsistent results. Thanks to S7!
 - 2017-04-13 Fixed bug#[12649](https://bugs.otrs.org/show_bug.cgi?id=12649)(PR#1669) - The long and short description of the process ticket are not displayed at the first activity. Thanks to S7!
 - 2017-04-13 Fixed bug#[12681](https://bugs.otrs.org/show_bug.cgi?id=12681)(PR#1647) - In agent ticket search, profile field is not modernise. Thanks to S7!
 - 2017-04-12 Fixed bug#[12714](https://bugs.otrs.org/show_bug.cgi?id=12714)(PR#1674) - In dynamic matrix statistics preview x-axis is not sorted. Thanks to S7!
 - 2017-04-12 Fixed bug#[12744](https://bugs.otrs.org/show_bug.cgi?id=12744)(PR#1704) - Responsible Filter in Queue View does not work. Thanks to S7!
 - 2017-04-10 Fixed bug#[12764](https://bugs.otrs.org/show_bug.cgi?id=12764) - Database function SQLProcessor() modifies given parameter data.
 - 2017-04-07 Fixed bug#[12761](https://bugs.otrs.org/show_bug.cgi?id=12761) - Cache values can be modified from the outside in function XMLParse().
 - 2017-04-07 Fixed bug#[9723](https://bugs.otrs.org/show_bug.cgi?id=9723) - TicketAccountedTime stat does not run on Oracle with many tickets.
 - 2017-04-05 Fixed bug#[12753](https://bugs.otrs.org/show_bug.cgi?id=12753) - Function "SystemDataGroupGet" has problems with empty values in oracle.
 - 2017-04-04 Fixed bug#[12627](https://bugs.otrs.org/show_bug.cgi?id=12627) - ACL value with brackets is not shown in ACL Editor.
 - 2017-04-04 Follow-up fix for bug#[12334](https://bugs.otrs.org/show_bug.cgi?id=12334) - Net::SSLGlue issues warnings on modern systems.
 - 2017-04-04 Fixed bug#[12746](https://bugs.otrs.org/show_bug.cgi?id=12746) - ACL ignores checks on dynamic fields.
 - 2017-04-03 Fixed typo in otrs.Daemon.pl.
 - 2017-04-03 Fixed bug#[12725](https://bugs.otrs.org/show_bug.cgi?id=12725) - Tickets link on themselves.
 - 2017-03-31 Follow-up fix: Activity dialog doesn't check process status before submit (bug#12443), thanks to Balázs Úr.
 - 2017-03-31 Fixed bug#[12680](https://bugs.otrs.org/show_bug.cgi?id=12680) - Templates are not loaded in several views in mobile browsers.
 - 2017-03-31 Fixed bug#[12603](https://bugs.otrs.org/show_bug.cgi?id=12603) - The notification during the import of a process appears in English.
 - 2017-03-31 Fixed bug#[12604](https://bugs.otrs.org/show_bug.cgi?id=12604) - Creating new Customer-User in case the given user already exists, the error message appears in English.
 - 2017-03-30 Fixed bug#[11958](https://bugs.otrs.org/show_bug.cgi?id=11958) - "http://" or "ftp://" may be added to hostnames in filtered text.
 - 2017-03-28 Fixed bug#[12720](https://bugs.otrs.org/show_bug.cgi?id=12720)(PR#1676) - Settings window of Complex LinkObject is not translated. Thanks to S7!
 - 2017-03-26 Fixed bug#[12650](https://bugs.otrs.org/show_bug.cgi?id=12650)(PR#1636) - SendCustomerNotification does not respect newly assigned mail address. Thanks to S7!
 - 2017-03-24 Updated translations, thanks to all translators.
 - 2017-03-24 Fixed bug#[12719](https://bugs.otrs.org/show_bug.cgi?id=12719)(PR#1671) - The result of SQL box displays the unique column headers not with the right character encoding. Thanks to S7!
 - 2017-03-24 Fixed bug#[12614](http://bugs.otrs.org/show_bug.cgi?id=12614) - PopUpAction doesn't work on the Create phone Ticket or Create e-mail ticket widgets.
 - 2017-03-24 Fixed bug#[12718](https://bugs.otrs.org/show_bug.cgi?id=12718)(PR#1668) - There is no check for the similar names when creating a mail filter. Thanks to S7!
 - 2017-03-24 Fixed bug#[12703](https://bugs.otrs.org/show_bug.cgi?id=12703)(PR#1663) - dynamic list and dynamic matrix interpret agent/user Userfirstname. Thanks to S7!
 - 2017-03-23 Fixed bug#[12723](https://bugs.otrs.org/show_bug.cgi?id=12723) - TicketNumber generators uses TicketCheckNumber() in a wrong way.
 - 2017-03-23 Fixed bug#[12701](https://bugs.otrs.org/show_bug.cgi?id=12701)(PR#1666) - Default values of "Owner" and "Responsible" fields placed in the activity dialogs in the process tickets cannot be settled. Thanks to S7!
 - 2017-03-23 Fixed bug#[12702](https://bugs.otrs.org/show_bug.cgi?id=12702) - TicketTypeUpdate not seen in Ticket history.

# 5.0.18 2017-03-28
 - 2017-03-22 Updated translations, thanks to all translators.
 - 2017-03-22 Fixed bug#[12716](https://bugs.otrs.org/show_bug.cgi?id=12716)(PR#1667) - Activity dialog causes an Error in customer interface. Thanks to S7!
 - 2017-03-20 Fixed bug#[12684](https://bugs.otrs.org/show_bug.cgi?id=12684)(PR#1649) - The format buttons are missing from the stacked area chart on the dashboard if the language is not English. Thanks to S7!
 - 2017-03-17 Fixed bug#[12683](https://bugs.otrs.org/show_bug.cgi?id=12683)(PR#1651) - There is a difference between key and content display in the Events Ticket Calendar. Thanks to S7!
 - 2017-03-17 Fixed bug#[12695](https://bugs.otrs.org/show_bug.cgi?id=12695)(PR#1657) - Collapse/Expand event does not work after submit table configuration (e.g. Linked) in AgentTicketZoom. Thanks to S7!
 - 2017-03-17 Fixed bug#[12611](https://bugs.otrs.org/show_bug.cgi?id=12611)(PR#1656) - Dropdown fields in large overview not modernized. Thanks to S7!
 - 2017-03-17 Fixed bug#[12382](https://bugs.otrs.org/show_bug.cgi?id=12382) - TicketSolutionResponseTime and TicketAccountedTime do not appear in Dynamic Metric but incorrectly in Dynamic List.
 - 2017-03-14 Fixed: Net::SSLGlue issues warnings on modern systems.
 - 2017-03-14 Fixed bug#[12676](https://bugs.otrs.org/show_bug.cgi?id=12676)(PR#1645) - Ticket delete slows exponentially with dynamic fields. Thanks to S7!
 - 2017-03-14 Improved backpup.pl to really only dump the database if -t dbonly is specified.
 - 2017-03-13 Fixed bug#[12571](https://bugs.otrs.org/show_bug.cgi?id=12571) - Missing column descriptions in External backends.
 - 2017-03-13 Fixed bug#[12679](https://bugs.otrs.org/show_bug.cgi?id=12679)(PR#1644) - Customer Menu can be clicked through in a certain instance. Thanks to S7!
 - 2017-03-13 Fixed bug#[12685](https://bugs.otrs.org/show_bug.cgi?id=12685) - Typos in TicketSearch operation in WSDL.
 - 2017-03-10 Fixed bug#[12569](https://bugs.otrs.org/show_bug.cgi?id=12569) - Missing explanation users (with visual impairments) in the 'Preferences' page.
 - 2017-03-10 Fixed bug#[12602](https://bugs.otrs.org/show_bug.cgi?id=12602) - The error message during editing the process ticket appears in English.
 - 2017-03-10 Fixed bug#[12678](https://bugs.otrs.org/show_bug.cgi?id=12678) - DynamicField Date and DateTime only have the default values for 10 years in past and 1 year in future for the search.
 - 2017-03-10 Fixed bug#[12600](https://bugs.otrs.org/show_bug.cgi?id=12600) - The speech bubble (alternative text) is missing for New Article column on the Dashboard widgets.
 - 2017-03-10 Fixed bug#[12624](https://bugs.otrs.org/show_bug.cgi?id=12624) - AgentTicketSearch gets broken with very long search templates.
 - 2017-03-10 Fixed bug#[12663](https://bugs.otrs.org/show_bug.cgi?id=12663)(PR#1642) - AgentTicketZoom does not jump to first unread article when it's not on the first page. Thanks to S7!
 - 2017-03-10 Fixed bug#[12677](https://bugs.otrs.org/show_bug.cgi?id=12677) - OTRS breaks with DBD::mysql 4.042.
 - 2017-03-09 Fixed bug#[12669](https://bugs.otrs.org/show_bug.cgi?id=12669)(PR#1641) - ToolBar icon 'Ticket in my Services' is shown without access to tickets. Thanks to S7!
 - 2017-03-08 Fixed bug#[12657](https://bugs.otrs.org/show_bug.cgi?id=12657)(PR#1640) - Search result different on DynamicFields if DB is case sensitive. Thanks to S7!
 - 2017-03-07 Fixed bug#[12565](https://bugs.otrs.org/show_bug.cgi?id=12565) - The translation is missing in the setting belonging to dynamic fields on the Generic Agent edit view.
 - 2017-03-07 Fixed bug#[12661](https://bugs.otrs.org/show_bug.cgi?id=12661)(PR#1639) - In overview views wrong dates are displayed in the Created column. Thanks to S7!
 - 2017-03-07 Fixed bug#[12665](https://bugs.otrs.org/show_bug.cgi?id=12665) - The search button in the main navigation is not visible sometimes.
 - 2017-03-06 Fixed bug#[12273](https://bugs.otrs.org/show_bug.cgi?id=12273) - ACLs do not work if referencing on DF with value 0.
 - 2017-03-03 Follow-up for bug#[12443](https://bugs.otrs.org/show_bug.cgi?id=12443) - Activity dialog doesn't check process status before submit.
 - 2017-03-03 Fixed bug#[11880](https://bugs.otrs.org/show_bug.cgi?id=11880) - TicketSolutionResponseTime - No Values when Solution Time it NOT in use.
 - 2017-03-03 Fixed bug#[12659](https://bugs.otrs.org/show_bug.cgi?id=12659) - Process editor freezes when "No data found" element is dragged on canvas.
 - 2017-03-03 Fixed bug#[12253](https://bugs.otrs.org/show_bug.cgi?id=12253) - Stats per Customer User not possible.
 - 2017-03-03 Fixed bug#[12585](https://bugs.otrs.org/show_bug.cgi?id=12585) - Samples are not translated in the search view of text type dynamic field.
 - 2017-03-03 Fixed bug#[12554](https://bugs.otrs.org/show_bug.cgi?id=12554) - The change of FirstnameLastnameOrder does not affect QueueView.
 - 2017-03-03 Fixed bug#[12648](https://bugs.otrs.org/show_bug.cgi?id=12648) - User cache is beeing deleted every time a user logins and LDAP sync causes a user update.
 - 2017-03-02 Fixed bug#[9729](https://bugs.otrs.org/show_bug.cgi?id=9729)(PR#1631) - An article body may be replaced with attachments in AgentTicketZoom. Thanks to S7!
 - 2017-03-02 Fixed bug#[4640](https://bugs.otrs.org/show_bug.cgi?id=4640)(PR#1635) - Wrong variable <OTRS_CUSTOMER_REALNAME> in Auto Responses. Thanks to S7!
 - 2017-03-02 Fixed bug#[8657](https://bugs.otrs.org/show_bug.cgi?id=8657)(PR#1634) - PasswordMinSize returns %s instead of minimum size in the AgentPreferences. Thanks to S7!

# 5.0.17 2017-03-07
 - 2017-02-27 Updated translations, thanks to all translators.
 - 2017-02-24 Fixed bug#[12612](https://bugs.otrs.org/show_bug.cgi?id=12612) - Exchange of the axis and the translations doesn't work in the dashboard statistic widgets.
 - 2017-02-24 Fixed bug#[12628](https://bugs.otrs.org/show_bug.cgi?id=12628)(PR#1623) - Sorting of columns in Dashboard-Ticket-Widgets is toggling with every refresh of the widget. Thanks to S7!
 - 2017-02-24 Unified the search from text and textarea dynamic fields (bug#12118).
 - 2017-02-22 Updated translations, thanks to all translators.
 - 2017-02-22 Fixed bug#[12596](https://bugs.otrs.org/show_bug.cgi?id=12596)(PR#1625) - AgentTicketQueue articles are not displayed properly. Thanks to S7!
 - 2017-02-18 Fixed bug#[12443](https://bugs.otrs.org/show_bug.cgi?id=12443) - Activity dialog doesn't check process status before submit.
 - 2017-02-17 Fixed bug#[12552](https://bugs.otrs.org/show_bug.cgi?id=12552) - Merging Tickets will not move linked objects to target ticket.
 - 2017-02-17 Fixed bug#[12573](https://bugs.otrs.org/show_bug.cgi?id=12573) - Permissions are not completely translated.
 - 2017-02-17 Follow-up fix for bug#12487: Statistic with a  '+' in the  CustomerId doesn't work.
 - 2017-02-17 Fixed bug#[12595](https://bugs.otrs.org/show_bug.cgi?id=12595) - Not able to search for tickets at customer portal with brackets within login name.
 - 2017-02-17 Fixed bug#[12555](https://bugs.otrs.org/show_bug.cgi?id=12555) - Deleting tickets via GenericAgent does not remove tickets completely (immediately?).
 - 2017-02-17 Fixed bug#[12564](https://bugs.otrs.org/show_bug.cgi?id=12564) - Values that belong to the checkbox, appear in English in the statistics settings.
 - 2017-02-17 Fixed bug#[12620](https://bugs.otrs.org/show_bug.cgi?id=12620) - bug with spec file for SLES 11.
 - 2017-02-16 Fixed bug#[12546](https://bugs.otrs.org/show_bug.cgi?id=12546) - SOAP:1007 SRT: Unsupported xstream found: ("HTTP Code 200  : OK").
 - 2017-02-14 Added the possibility to configure ticket notification recipients by OTRS-tags (replaced with values from current ticket).
 - 2017-02-14 Fixed bug#[12558](https://bugs.otrs.org/show_bug.cgi?id=12558)(PR#1603) - Filtering of "Available Columns" in Allocation List is not working well when columns are changed. Thanks to S7!
 - 2017-02-13 Fixed bug#[12606](https://bugs.otrs.org/show_bug.cgi?id=12606) - In LinkObject module the class names are not translated even if they are translated in the language file.
 - 2017-02-10 Fixed bug#[12588](https://bugs.otrs.org/show_bug.cgi?id=12588) - Unicode characters crash Postmaster with HTMLUtil.pm error.
 - 2017-02-10 Fixed bug#[10918](https://bugs.otrs.org/show_bug.cgi?id=10918) - Reducing available processes by ACLs not possible.
 - 2017-02-09 Fixed bug#[12548](https://bugs.otrs.org/show_bug.cgi?id=12548) - In the search menu the examples are delusive.
 - 2017-02-08 Follow-up fix for bug#10691: add new config setting PostMaster::NewTicket::AutoAssignCustomerIDForUnknownCustomers to control creation of tickets with unknown customers.
 - 2017-02-04 Fixed bug#[12591](https://bugs.otrs.org/show_bug.cgi?id=12591) - Statistic preview for ticket list statistic is very slow in systems with many tickets.
 - 2017-02-03 Fixed bug#[12287](https://bugs.otrs.org/show_bug.cgi?id=12287) - Missing date validation for ITSM date and datetime fields.
 - 2017-02-03 Fixed bug#[12549](https://bugs.otrs.org/show_bug.cgi?id=12549) - Columns not translated in several widgets and views.
 - 2017-02-03 Fixed bug#[12533](https://bugs.otrs.org/show_bug.cgi?id=12533) - Setting a Dynamic Field to = 0  in a activity dialogue does  not set the value but deletes it.
 - 2017-02-03 Fixed bug#[12577](https://bugs.otrs.org/show_bug.cgi?id=12577)(PR#1606) - Select All Checkboxes in Ticket Overview screens. Thanks to S7!
 - 2017-02-01 Fixed bug#[12458](https://bugs.otrs.org/show_bug.cgi?id=12458) - JavaScript events do not work when Customer History is loaded.
 - 2017-01-27 Fixed bug#[12559](https://bugs.otrs.org/show_bug.cgi?id=12559) - Moving ticket to disabled queue causes corrupted layout.
 - 2017-01-27 Fixed bug#[11902](https://bugs.otrs.org/show_bug.cgi?id=11902) - Stats - TicketSolutionResponseTime does not show any  Escalation - First Response Time.
 - 2017-01-26 Fixed bug#[12547](https://bugs.otrs.org/show_bug.cgi?id=12547) - System maintenance arranges notes in time order.
 - 2017-01-24 Fixed bug#[12529](https://bugs.otrs.org/show_bug.cgi?id=12529) - Notifications break AgentTicketBulk.
 - 2017-01-20 Fixed bug#[12528](https://bugs.otrs.org/show_bug.cgi?id=12528) - Problem with dash as value in a modernized form field.
 - 2017-01-20 Follow-up fix for bug#[11810](http://bugs.otrs.org/show_bug.cgi?id=11810) - <OTRS_TICKET_State> not translated to spanish when answering from AgentTicketZoom screen.
 - 2017-01-20 Fixed bug#[4512](https://bugs.otrs.org/show_bug.cgi?id=4512) - HTMLUtils ToAscii forces line breake on fixed line-length 78.
 - 2017-01-20 Fixed bug#[12543](https://bugs.otrs.org/show_bug.cgi?id=12543) - Missing header and footer after file upload in CustomerTicketProcess.
 - 2017-01-20 Fixed bug#[12536](https://bugs.otrs.org/show_bug.cgi?id=12536) - It's possible for an GenericAgent task to be submitted multiple times and depending on the jobs configuration, lead to a Denial of Service.
 - 2017-01-17 Fixed bug#[12481](https://bugs.otrs.org/show_bug.cgi?id=12481) - URLs in Chat are not converted to clickable links.

# 5.0.16 2017-01-24
 - 2017-01-16 Updated translations, thanks to all translators.
 - 2017-01-13 Fixed bug#[12494](https://bugs.otrs.org/show_bug.cgi?id=12494) - Not able to start chat at AgentTicketZoom and CIC with customer.
 - 2017-01-12 Updated translations, thanks to all translators.
 - 2017-01-06 Fixed bug#[12523](https://bugs.otrs.org/show_bug.cgi?id=12523) - Can't cache: StatID  has no time period, so you can't cache the stat!.
 - 2017-01-06 Fixed bug#[12516](https://bugs.otrs.org/show_bug.cgi?id=12516) - Error when next state is not set and state is disabled in AgentTicketPhoneCommon.
 - 2017-01-06 Fixed bug#[12421](https://bugs.otrs.org/show_bug.cgi?id=12421) - Wrong out of office state in statistics.
 - 2017-01-06 Fixed bug#[12512](https://bugs.otrs.org/show_bug.cgi?id=12512) - https RSS feeds don't use the proxy.
 - 2016-12-23 Fixed bug#[12471](https://bugs.otrs.org/show_bug.cgi?id=12471) - out of office time calculation wrong if user time zone differs from OTRS default.
 - 2016-12-23 Fixed bug#[10691](https://bugs.otrs.org/show_bug.cgi?id=10691) - No CustomerID shown after TicketCreate (for unknown customers).
 - 2016-12-23 Fixed bug#[12480](https://bugs.otrs.org/show_bug.cgi?id=12480) - Bulk function ignores queues <-> agent/role permissions. Thanks to S7 (PR#1590).
 - 2016-12-20 Fixed bug#[11197](https://bugs.otrs.org/show_bug.cgi?id=11197) - AJAX Error while being logged in but nothing is done for a while.
 - 2016-12-19 Fixed bug#[12501](https://bugs.otrs.org/show_bug.cgi?id=12501) - Mandatoy dyn. multiselect field occur error message in AgentTicketEmailOutbound.
 - 2016-12-16 Fixed bug#[12486](https://bugs.otrs.org/show_bug.cgi?id=12486) - Return-path is set to "<>" instead of having SMTP-From identical to Mailheader-From.
 - 2016-12-16 Fixed bug#[12435](https://bugs.otrs.org/show_bug.cgi?id=12435) - otrs.Console.pl Maint::Stats::Generate - ISO-8859 encoding.
 - 2016-12-16 Improved the support data collection to work without a internal web request.
 - 2016-12-16 Follow-up fix for bug#[12040](https://bugs.otrs.org/show_bug.cgi?id=12040) - Emails are incorrectly attached to tickets.
 - 2016-12-16 Fixed bug#[12473](https://bugs.otrs.org/show_bug.cgi?id=12473) - Banner cannot be disabled in customer interface.
 - 2016-12-09 Fixed bug#[12487](https://bugs.otrs.org/show_bug.cgi?id=12487) - Statistic with a  '+' in the  CustomerId doesn't work.
 - 2016-12-09 Fixed bug#[12429](https://bugs.otrs.org/show_bug.cgi?id=12429) - Nested form elements in AgentLinkObject prevent submit, thanks to Thorsten Eckel.

# 5.0.15 2016-12-13
 - 2016-12-07 Fixed bug#[12483](https://bugs.otrs.org/show_bug.cgi?id=12483) - YAML load problems with dynamic fields.
 - 2016-12-07 Updated translations, thanks to all translators.
 - 2016-12-04 Fixed bug#[12439](https://bugs.otrs.org/show_bug.cgi?id=12439) - Import/Export of notifications do not work between two instances.
 - 2016-12-02 Fixed bug#[12472](https://bugs.otrs.org/show_bug.cgi?id=12472) - Bug in Output Filter  Frontend::Output::FilterText###AAAUR: wrong FTP recognition.
 - 2016-12-02 Fixed bug#[12467](https://bugs.otrs.org/show_bug.cgi?id=12467) - Column header in excel format start from second row.
 - 2016-11-29 Fixed bug#[12293](https://bugs.otrs.org/show_bug.cgi?id=12293) - Auto response presents confidential information from internal communication to customer user. Please note that for this fix, the configuration setting "PostMaster::PostFilterModule###000-FollowUpArticleTypeCheck" was renamed to "PostMaster::PreCreateFilterModule###000-FollowUpArticleTypeCheck". If you had customized the old setting, please also apply your customizations to the new setting.
 - 2016-11-25 Fixed bug#[12464](http://bugs.otrs.org/show_bug.cgi?id=12464) - Customer History table is still visible even though no selected customer users, thanks to S7.
 - 2016-11-25 Fixed bug#[12457](http://bugs.otrs.org/show_bug.cgi?id=12457) - text/html Part only E-Mails with HTML Entities are Converted to Incorrect Charset.
 - 2016-11-25 Fixed bug#[12450](http://bugs.otrs.org/show_bug.cgi?id=12450) - Error handling with ???. Thanks to Dorothea Doerffel.
 - 2016-11-25 Fixed bug#[1370](https://bugs.otrs.org/show_bug.cgi?id=1370) - Postmaster filters with 2 match conditions doesnt work.
 - 2016-11-25 Fixed bug#[12461](https://bugs.otrs.org/show_bug.cgi?id=12461) - Chrome can not display attached PDF files since 5.0.14.
 - 2016-11-22 Fixed bug#[12445](https://bugs.otrs.org/show_bug.cgi?id=12445) - Save and finish button does not "finish" in statistics.
 - 2016-11-21 Fixed bug#[11548](https://bugs.otrs.org/show_bug.cgi?id=11548) - Filtering the greek symbol sigma "Σ".
 - 2016-11-21 Fixed bug#[12302](https://bugs.otrs.org/show_bug.cgi?id=12302) - Default column config for customer and customer user data.
 - 2016-11-21 Fixed bug#[12357](https://bugs.otrs.org/show_bug.cgi?id=12357) - CustomerTicketProcess Problem paste or upload image.
 - 2016-11-18 Removed superfluous colons in table heading, thanks to Balázs Úr (PR#1566).
 - 2016-11-18 Fixed error when importing emails without valid address in From field, thanks to Paweł Bogusławski (PR#1559).
 - 2016-11-18 Fixed warnings when saving permissions for users and roles, thanks to Paweł Bogusławski (PR#1557).
 - 2016-10-10 Disabled warnings on internal unicode chacter printing, thanks to Pawel Boguslawski.
 - 2016-11-18 Fixed bug#[12427](https://bugs.otrs.org/show_bug.cgi?id=12427) - Missing table cell in Customer User Management modal screen.
 - 2016-11-18 Moved the save buttons into a separate widget for better usability in AdminACL, thanks to urbalazs.
 - 2016-11-18 Fixed an issue where the group selection in SysConfig would lead to empty results in the content area, thanks to S7
 - 2016-11-18 Fixed bug#[12438](https://bugs.otrs.org/show_bug.cgi?id=12438) - Race condition in ArticleCreate.
 - 2016-11-18 Fixed bug#[12353](http://bugs.otrs.org/show_bug.cgi?id=12353) - DynamicField Multiselect default value is not correct on creation. Thanks to S7!
 - 2016-11-18 Fixed bug#[12418](https://bugs.otrs.org/show_bug.cgi?id=12418) - Blinking mechanism not working.
 - 2016-11-12 Fixed bug#[10825](https://bugs.otrs.org/show_bug.cgi?id=10825) - <OTRS_CUSTOMER_Body> in Reply-Template, thanks to S7.
 - 2016-11-11 Improved output of customer data in AdminSession.
 - 2016-11-11 Fixed bug#[12415](https://bugs.otrs.org/show_bug.cgi?id=12415) - Problems with malformed utf8 chars in emails.
 - 2016-11-11 Fixed bug#[12403](https://bugs.otrs.org/show_bug.cgi?id=12403) - Ticketview M or L actionline in ie11 not working.
 - 2016-11-11 Fixed bug#[12383](https://bugs.otrs.org/show_bug.cgi?id=12383) - OTRS does way to many DBD::Pg ping test.
 - 2016-11-11 Fixed bug#[12405](https://bugs.otrs.org/show_bug.cgi?id=12405) - Admin Notification does not show realname.
 - 2016-11-11 Fixed bug#[12410](https://bugs.otrs.org/show_bug.cgi?id=12410) - ACL GUI doesn not contain AgentTicketSearch.
 - 2016-11-11 Fixed bug#[12395](https://bugs.otrs.org/show_bug.cgi?id=12395) - Support Data Collector Plugin Table Charset incorrectly reports utf8 Problem for a Table View.
 - 2016-11-11 Fixed bug#[12408](https://bugs.otrs.org/show_bug.cgi?id=12408) - Missing SecretConfigOptions in TemplateGenerator.
 - 2016-11-08 Fixed bug#[12401](https://bugs.otrs.org/show_bug.cgi?id=12401) - Same HTML IDs in the statistics edit screen (x-axis, y-axis and filter).
 - 2016-11-07 Fixed bug#[12400](https://bugs.otrs.org/show_bug.cgi?id=12400) - Package manager does not list freely selectable features via cloud service.
 - 2016-11-06 Fixed bug#[8998](https://bugs.otrs.org/show_bug.cgi?id=12400)(PR#1033) - Empty sender name in response, thanks to Pawel Boguslawski.
 - 2016-11-04 Fixed bug#[12378](https://bugs.otrs.org/show_bug.cgi?id=12378) - TicketNumber in LinkObject sort columns can't change its position.
 - 2016-11-04 Fixed bug#[12317](https://bugs.otrs.org/show_bug.cgi?id=12317) - DropDown with many values has doubled scrollbar.
 - 2016-11-04 Fixed bug#[12384](http://bugs.otrs.org/show_bug.cgi?id=12384) - Stats translates ticket type values.
 - 2016-11-04 Fixed bug#[12316](http://bugs.otrs.org/show_bug.cgi?id=12316) - No tickets found, empty lines in customer user management on () in uid. Thanks to Paweł Bogusławski (PR#1510).
 - 2016-11-04 Fixed bug#[12397](https://bugs.otrs.org/show_bug.cgi?id=12397) - backup.pl doesn't backup articles in special case. Thanks to Jens Pfeifer.
 - 2016-11-04 Fixed bug#[12391](http://bugs.otrs.org/show_bug.cgi?id=12391) - Base64 encoded image does not display in article.
 - 2016-11-04 Fixed bug#[12369](http://bugs.otrs.org/show_bug.cgi?id=12369) - Errors in deleting tickets. Thanks to S7.
 - 2016-11-04 Fixed bug#[12367](https://bugs.otrs.org/show_bug.cgi?id=12367) - * in CustomerID breaks all CustomerUser.CustomerIDs.
 - 2016-11-04 Follow-up fix for bug#[9460](https://bugs.otrs.org/show_bug.cgi?id=9460) - Under some circumstances OTRS does not join Tickets to the Customernumber.
 - 2016-11-02 Fixed bug#[12388](http://bugs.otrs.org/show_bug.cgi?id=12388) - Using obsolete GenericAgent module jobs causes errors in logs. Thanks to Paweł Bogusławski.
 - 2016-10-28 Fixed bug#[12364](https://bugs.otrs.org/show_bug.cgi?id=12364) - Blank lines at top of signature lost when editing.
 - 2016-10-28 Fixed bug#[12349](https://bugs.otrs.org/show_bug.cgi?id=12349) - Module not working properly ArchiveRestore.
 - 2016-10-28 Fixed bug#[12334](https://bugs.otrs.org/show_bug.cgi?id=12334) - Net::SSLGlue issues warnings on modern systems.
 - 2016-10-27 Fixed bug#[12380](http://bugs.otrs.org/show_bug.cgi?id=12380) - GenericInterface: Buttons to mapping configuration are missing session data.

# 5.0.14 2016-11-01
 - 2016-10-27 Added a new support data collector plugin to check for spooled (incorrectly processed) emails.
 - 2016-10-26 Added a new agent session limit prior warning notification (SysConfig setting 'AgentSessionLimitPriorWarning') and added the concurrent agent management for the otrs business solution.
 - 2016-10-25 Added notification type handling for NotificationList in NotificationEvent backend.
 - 2016-10-25 Added caching to NotificationEvent backend.
 - 2016-10-23 Fixed bug#[11766](http://bugs.otrs.org/show_bug.cgi?id=11766) - Ticket unlock via Generic Interface not possible.
 - 2016-10-21 Fixed bug#[12311](http://bugs.otrs.org/show_bug.cgi?id=12311) - Process names are listed by ID instead of by name.
 - 2016-10-18 Fixed bug#[12284](http://bugs.otrs.org/show_bug.cgi?id=12284) - Precious little information regarding SMIME signatures.
 - 2016-10-09 Fixed bug#[12343](http://bugs.otrs.org/show_bug.cgi?id=12343) - Cache kept for ViewableLocks.
 - 2016-10-09 Fixed bug#[12351](http://bugs.otrs.org/show_bug.cgi?id=12351) - Multiple sort / order parameters for Ticket::Frontend::Agent::Dashboard.
 - 2016-10-07 Fixed bug#[11073](http://bugs.otrs.org/show_bug.cgi?id=11073) - Default expanded article in queue view (preview mode) should not be an autoreply.
 - 2016-10-07 Fixed bug#[12294](http://bugs.otrs.org/show_bug.cgi?id=12294) - modern field breaks when we minimize Free Field widget and the form is still open.
 - 2016-10-07 Fixed bug#[12208](http://bugs.otrs.org/show_bug.cgi?id=12208) - Print Process Information screen can not be canceled/closed.
 - 2016-10-06 Improved sandboxing of displayed attachments.
 - 2016-09-30 Fixed bug#[12341](http://bugs.otrs.org/show_bug.cgi?id=12341) - Wrong <OTRS_TICKET_DynamicField_NameX_Value> in ProcessManagement  Transition Actions.
 - 2016-09-30 Fixed bug#[666](http://bugs.otrs.org/show_bug.cgi?id=666) - INSERTs into 'ticket_history' fail sometimes.
 - 2016-09-30 Added warning message for Console commands executed in non UTF-8 terminal.
 - 2016-09-30 Fixed bug#[12272](http://bugs.otrs.org/show_bug.cgi?id=12272) - Tickets in status "removed" get reopened from Junk Queue.
 - 2016-09-28 Fixed bug#[12331](http://bugs.otrs.org/show_bug.cgi?id=12331) - pdf generation runs in to errors on spllited pages because of many columns.
 - 2016-09-27 Fixed bug#[4640](http://bugs.otrs.org/show_bug.cgi?id=4640) - Wrong variable <OTRS_CUSTOMER_REALNAME> in Auto Responses.
 - 2016-09-27 Fixed bug#[11805](http://bugs.otrs.org/show_bug.cgi?id=11805) - Cancel the Bulk Action always unlocks tickets.
 - 2016-09-27 Fixed bug#[11710](http://bugs.otrs.org/show_bug.cgi?id=11710) - Using ArticleFilter causes numeration issues.
 - 2016-09-23 Fixed bug#[12306](http://bugs.otrs.org/show_bug.cgi?id=12306)(PR#1474) - SOAP won't use certificates, thanks to Thorsten Eckel.
 - 2016-09-23 Fixed bug#[12328](http://bugs.otrs.org/show_bug.cgi?id=12328) - Translate State, Lock and Priority values in the Lined ticket widget (Complex).
 - 2016-09-22 Fixed bug#[12283](http://bugs.otrs.org/show_bug.cgi?id=12283) - If Customer users <-> Groups is activated, some queues are not available in the customer interface, when starting a process ticket.
 - 2016-09-21 Fixed bug#[12313](http://bugs.otrs.org/show_bug.cgi?id=12313) - Spam log error in AdminSysConfig.
 - 2016-09-21 Added possibility to define Minimum and Maximum framework version in opm files (e.g. <Framework Minimum="5.0.14">5.0.x</Framework>).
 - 2016-09-20 Fixed bug#[12310](http://bugs.otrs.org/show_bug.cgi?id=12310) - Error when invoking the installer with SecureMode = 1.
 - 2016-09-19 Fixed bug#[12309](http://bugs.otrs.org/show_bug.cgi?id=12309) - LinkObject Complex Table column sorting only works for tickets.
 - 2016-09-16 Fixed bug#[12305](http://bugs.otrs.org/show_bug.cgi?id=12305) - Incorrect charset handling in content type of SOAP messages.
 - 2016-09-15 Fixed bug#[12126](http://bugs.otrs.org/show_bug.cgi?id=12126) - Daemon's Task SpoolMailsReprocess causes loop tickets.
 - 2016-09-15 Fixed bug#[12301](http://bugs.otrs.org/show_bug.cgi?id=12301) - CSV reading code is broken, thanks to Pawel Boguslawski.

# 5.0.13 2016-09-20
 - 2016-09-14 Updated translations, thanks to all translators.
 - 2016-09-12 Fixed bug#[12297](http://bugs.otrs.org/show_bug.cgi?id=12297) - AdminCustomerUser and AdminCustomerCompany generate log errors if RunInitialWildcardSearch is disabled.
 - 2016-09-09 Fixed bug#[12290](http://bugs.otrs.org/show_bug.cgi?id=12290) - LDAP Size Limit exceeded is marked as error.
 - 2016-09-09 Fixed bug#[5149](http://bugs.otrs.org/show_bug.cgi?id=5149) - Incomplete multipart/mixed processing causes incomplete display of e-mails.
 - 2016-09-05 Added new console commands to print (Maint::Log::Print) and clear (Maint::Log::Clear) the OTRS log.
 - 2016-09-05 Followup for bug#[11922](http://bugs.otrs.org/show_bug.cgi?id=11922) - Notification to non RealCustomer.
 - 2016-09-02 Fixed bug#[12199](http://bugs.otrs.org/show_bug.cgi?id=12199) - ProcessManagement: Comma separated Lastnames are not shown correctly on article creation.
 - 2016-09-02 Fixed bug#[12079](http://bugs.otrs.org/show_bug.cgi?id=12079) - Regex in transition condition not working for empty match.
 - 2016-09-02 Added additional positive ResponseCodes for Generic Interface transport module REST, thanks to Robert Ullrich.
 - 2016-09-02 Fixed bug#[12280](http://bugs.otrs.org/show_bug.cgi?id=12280) - GenericAgent job does not send out notifications, even when the option is set to Yes. Thanks to Johannes Hoerburger.
 - 2016-09-02 Fixed bug#[12257](http://bugs.otrs.org/show_bug.cgi?id=12257) - Ticketnotification: Ticketfilter of a uncheck checkbox doesn't work.
 - 2016-09-02 Fixed bug#[7288](http://bugs.otrs.org/show_bug.cgi?id=7288) - Hyperlink creation cuts URLs after a closing square bracket.
 - 2016-09-01 Fixed bug#[12106](http://bugs.otrs.org/show_bug.cgi?id=12106) - Use of uninitialized value in splice.
 - 2016-08-26 Fixed bug#[12233](http://bugs.otrs.org/show_bug.cgi?id=12233) - ACL for restricting services depending on queue does not work as exspected.
 - 2016-08-26 Fixed bug#[10608](http://bugs.otrs.org/show_bug.cgi?id=10608) - Can't search tickets by CustomerID that contain quotes.
 - 2016-08-26 Fixed bug#[12270](http://bugs.otrs.org/show_bug.cgi?id=12270) - AdminMailAccount - Mail account password returned back to form.
 - 2016-08-26 Fixed bug#[12259](http://bugs.otrs.org/show_bug.cgi?id=12259) - Images in a note are lost when using "reply to note".
 - 2016-08-26 Fixed bug#[12263](http://bugs.otrs.org/show_bug.cgi?id=12263) - Time-related search attributes only cover last 10 years.
 - 2016-08-22 Fixed bug#[12264](http://bugs.otrs.org/show_bug.cgi?id=12264) - Incorrect link to ACL documentation.
 - 2016-08-19 Fixed bug#[12236](http://bugs.otrs.org/show_bug.cgi?id=12236) - ACL - negate a role.
 - 2016-08-19 Fixed bug#[12242](http://bugs.otrs.org/show_bug.cgi?id=12242) - GenericInterface Dynamic Fields with multiple values not possible (TicketCreate).
 - 2016-08-19 Fixed bug#[12261](http://bugs.otrs.org/show_bug.cgi?id=12261) - SupportBundle generator dialog has double separator lines.
 - 2016-08-19 Fixed bug#[12225](http://bugs.otrs.org/show_bug.cgi?id=12225) - actual day can not be added if a dynamic field (Date) requires future date.
 - 2016-08-19 Fixed bug#[12258](http://bugs.otrs.org/show_bug.cgi?id=12258) - restore.pl doesn't work with crypted passwords.
 - 2016-08-19 Fixed bug#[12222](http://bugs.otrs.org/show_bug.cgi?id=12222) - closing curly bracket in hyperlink.
 - 2016-08-19 Fixed bug#[12210](http://bugs.otrs.org/show_bug.cgi?id=12210) - GenericAgent can not be submitted if a dynamic field (Date) requires future date.
 - 2016-08-19 Fixed bug#[12243](http://bugs.otrs.org/show_bug.cgi?id=12243) - Modern input fields leaves broken selection on search field remove.
 - 2016-08-19 Fixed bug#[12256](http://bugs.otrs.org/show_bug.cgi?id=12256) - Parameter "Active" in method QueueStandardTemplateMemberAdd is optional but method returns if not set.
 - 2016-08-19 Fixed bug#[9460](http://bugs.otrs.org/show_bug.cgi?id=9460) - Under some circumstances OTRS does not join Tickets to the Customernumber.
 - 2016-08-18 Fixed bug#[12246](http://bugs.otrs.org/show_bug.cgi?id=12246) - HTML mail not displayed correctly.
 - 2016-08-18 Fixed bug#[12252](http://bugs.otrs.org/show_bug.cgi?id=12252) - Support Bundle cannot be created via GUI if cloud services are disabled.
 - 2016-08-15 Fixed bug#[12245](http://bugs.otrs.org/show_bug.cgi?id=12245) - Missing information for Article Dynamic Fields update event thanks to Rene (rwese).
 - 2016-08-15 Fixed a problem with the axis exchange not working correctly in the OTRS Business Solution™ reports.
 - 2016-08-12 Fixed bug#[4389](http://bugs.otrs.org/show_bug.cgi?id=4389) - Singular/plural issue with age.
 - 2016-08-12 Fixed bug#[12218](http://bugs.otrs.org/show_bug.cgi?id=12218) - PostmasterFilter, not possible to set X-OTRS-DynamicField.
 - 2016-08-12 Fixed bug#[8705](http://bugs.otrs.org/show_bug.cgi?id=8705) - StandardResponse2QueueByCreating in wrong Sysconfig area.
 - 2016-08-12 Fixed bug#[4439](http://bugs.otrs.org/show_bug.cgi?id=4439) - Ticket sort order is based on database ids.
 - 2016-08-12 Fixed bug#[12224](http://bugs.otrs.org/show_bug.cgi?id=12224) - Plain password stored in database temporarily when adding new users.
 - 2016-08-12 Follow-up fix for bug#[12150](http://bugs.otrs.org/show_bug.cgi?id=12150) - Ticket::HookDivider missing in TicketZoom and History View.
 - 2016-08-08 Fixed bug#[12205](http://bugs.otrs.org/show_bug.cgi?id=12205) - Default setting for Ticket::Frontend::CustomerTicketMessage###TicketTypeDefault incorrect.
 - 2016-08-09 Fixed bug#[12232](http://bugs.otrs.org/show_bug.cgi?id=12232) - Modern input fields leaves a broken value on refresh.
 - 2016-08-05 Fixed bug#[12086](http://bugs.otrs.org/show_bug.cgi?id=12086) - Labels overflows for some languages.
 - 2016-08-05 Fixed bug#[12221](http://bugs.otrs.org/show_bug.cgi?id=12221) - Key/value fields are very small in AdminProcessManagementTransitionAction.

# 5.0.12 2016-08-09
 - 2016-08-03 Updated translations, thanks to all translators.
 - 2016-07-29 Fixed bug#[12196](http://bugs.otrs.org/show_bug.cgi?id=12196) - SOAP Response missing trailing slash.
 - 2016-07-24 Followup for bug#[12090](http://bugs.otrs.org/show_bug.cgi?id=12090) - 2 second sleep between email fetching causes bad performance on systems with high email traffic.
 - 2016-07-13 Fixed bug#[12118](http://bugs.otrs.org/show_bug.cgi?id=12118) - Text Area filter doesn't work for Statistic.
 - 2016-07-13 Fixed bug#[12189](http://bugs.otrs.org/show_bug.cgi?id=12189) - ACL beginning with @ results in 500 internal server error.
 - 2016-07-12 Fixed bug#[12185](http://bugs.otrs.org/show_bug.cgi?id=12185) - Sometimes page leave confirmation is shown when completing a popup action.
 - 2016-07-12 Fixed bug#[12083](http://bugs.otrs.org/show_bug.cgi?id=12083) - When no result is found for a stats the result is 0.
 - 2016-07-12 Fixed bug#[12182](http://bugs.otrs.org/show_bug.cgi?id=12182) - CIC - Customer Login still shows merged tickets as closes tickets.
 - 2016-07-12 Fixed bug#[12181](http://bugs.otrs.org/show_bug.cgi?id=12181) - Object StateAction -> Names are not readable.
 - 2016-07-11 Corrected date format for Thai and added new Indonesian language translation, thanks to all translators.
 - 2016-07-11 Fixed bug#[11934](http://bugs.otrs.org/show_bug.cgi?id=11934) - GenericAgent - not possible to uncheck a checkbox.
 - 2016-07-08 Fixed bug#[12179](http://bugs.otrs.org/show_bug.cgi?id=12179) - Wrong OTRS tags conversion in transition actions called by Generic Agent over multiple tickets.
 - 2016-07-08 Fixed bug#[12105](http://bugs.otrs.org/show_bug.cgi?id=12105) - "Create summation row" and "Create summation column" are transposed.
 - 2016-07-08 Fixed bug#[12177](http://bugs.otrs.org/show_bug.cgi?id=12177) - "Close ticket" and "Close window".
 - 2016-07-08 Fixed bug#[12150](http://bugs.otrs.org/show_bug.cgi?id=12150) - Ticket::HookDivider missing in TicketZoom and History View.
 - 2016-07-08 Fixed bug#[12134](http://bugs.otrs.org/show_bug.cgi?id=12134) - Tag <OTRS_CUSTOMER_REALNAME> wrongly documented.
 - 2016-07-08 Fixed bug#[7108](http://bugs.otrs.org/show_bug.cgi?id=7108) - Email not sent if FQDN has port number in it.
 - 2016-07-07 Fixed bug#[12178](http://bugs.otrs.org/show_bug.cgi?id=12178) - CustomerUser in Config.pm breaks the system.
 - 2016-07-06 Fixed bug#[8671](http://bugs.otrs.org/show_bug.cgi?id=8671) - Can not link to archived ticket.
 - 2016-07-04 Fixed bug#[12147](http://bugs.otrs.org/show_bug.cgi?id=12147) - Transition Action - to set Service and SLA.
 - 2016-07-01 Fixed bug#[12141](http://bugs.otrs.org/show_bug.cgi?id=12141) - Wrong check for needed objects.
 - 2016-07-01 Fixed bug#[8640](http://bugs.otrs.org/show_bug.cgi?id=8640) - Article bounce does not conform to rfc 2822.
 - 2016-07-01 Fixed bug#[12111](http://bugs.otrs.org/show_bug.cgi?id=12111) - Auto response sometimes not translated in German.
 - 2016-07-01 Fixed bug#[12120](http://bugs.otrs.org/show_bug.cgi?id=12120) - Untranslated words in dashboard stats.
 - 2016-07-01 Fixed bug#[11248](http://bugs.otrs.org/show_bug.cgi?id=11248) - FollowUp handling on internal mails does not work at all times.
 - 2016-07-01 Fixed bug#[12124](http://bugs.otrs.org/show_bug.cgi?id=12124) - Usability bug - Attributes in Stats are not shown like in 4.
 - 2016-06-30 Improved debug output of Maint::PostMaster::Read.
 - 2016-06-27 Fixed bug#[11986](http://bugs.otrs.org/show_bug.cgi?id=11986) - Wrong class paramenter for Admin Menu in Navbar.
 - 2016-06-27 Fixed bug#[12097](http://bugs.otrs.org/show_bug.cgi?id=12097) - Ticket responses with non-breaking whitespace cause PostgreSQL database error.
 - 2016-06-27 Fixed bug#[11596](http://bugs.otrs.org/show_bug.cgi?id=11596) - Invalid byte sequence for encoding "UTF8": 0xa0 PostgreSQL.
 - 2016-06-27 Fixed bug#[10970](http://bugs.otrs.org/show_bug.cgi?id=10970) - byte sequence errors on notifications.
 - 2016-06-27 Followup for bug#[12078](http://bugs.otrs.org/show_bug.cgi?id=12078) - Change wording for better translation, thanks to Balázs Úr.
 - 2016-06-24 Don't write error log entry on first LDAP user login, thanks to Pawel Boguslawski.
 - 2016-06-24 Fixed bug#[9000](http://bugs.otrs.org/show_bug.cgi?id=9000) - shm errors on OTRS server startup.
 - 2016-06-23 Fixed bug#[11981](http://bugs.otrs.org/show_bug.cgi?id=11981) - GenericTicketConnector ignoring "<ContentSearch>OR</ContentSearch>" in full text search.

# 5.0.11 2016-06-28
 - 2016-08-03 Updated translations, thanks to all translators.
 - 2016-06-22 Updated translations, thanks to all translators.
 - 2016-06-22 Fixed bug#[12143](http://bugs.otrs.org/show_bug.cgi?id=12143) - TicketSearch: if you filter a search attribute and then select 'all', the search screen disappear.
 - 2016-06-21 Fixed bug#[12114](http://bugs.otrs.org/show_bug.cgi?id=12114) - Reply to an outbound email-internal may fail to be classified as email-internal.
 - 2016-06-21 Fixed bug#[12100](http://bugs.otrs.org/show_bug.cgi?id=12100) - Error Premature end of script headers: index.pl when using long URL.
 - 2016-06-20 Improved performance of CustomerGroup::GroupMemberList(), thanks to Thorsten Eckel.
 - 2016-06-17 Fixed bug#[11920](http://bugs.otrs.org/show_bug.cgi?id=11920) - Activity Dialogs will not translated.
 - 2016-06-15 Fixed bug#[12131](http://bugs.otrs.org/show_bug.cgi?id=12131) - Parameter --with-header does not work.
 - 2016-06-15 Fixed bug#[12088](http://bugs.otrs.org/show_bug.cgi?id=12088) - Possible race condition in scheduler worker daemon.
 - 2016-06-14 Fixed bug#[11848](http://bugs.otrs.org/show_bug.cgi?id=11848) - Generic agent don't set pending time without new pending state.
 - 2016-06-14 Fixed bug#[11816](http://bugs.otrs.org/show_bug.cgi?id=11816)(PR#940)  - Ticket::Service::KeepChildren parameter - invalid Parent Service.
 - 2016-06-13 Fixed bug#[12078](http://bugs.otrs.org/show_bug.cgi?id=12078) - AdminCustomerUser timeout because of too many customer users.
 - 2016-06-13 Faster new stat add operation, thanks to Pawel Boguslawski.
 - 2016-06-09 Fixed bug#[12129](http://bugs.otrs.org/show_bug.cgi?id=12129) - Process Management: Ticket locks even when is not needed, thanks to Thorsten Eckel.
 - 2016-06-09 Fixed bug#[12128](http://bugs.otrs.org/show_bug.cgi?id=12128) - Can not store 0 in Admin Customer screen, thanks to Renée Bäcker.
 - 2016-06-09 Fixed bug#[12116](http://bugs.otrs.org/show_bug.cgi?id=12116) - Tooltip error messages in combination with modern input fields.
 - 2016-06-09 Fixed performance issue in PermissionUserGet(), thanks to Thorsten Eckel.
 - 2016-06-06 Fixed bug#[12122](http://bugs.otrs.org/show_bug.cgi?id=12122) - Wrong offset in substr function, ForeignKeyCreate function.
 - 2016-06-05 Add CustomerCompanyName Column to Dashboard and CIC, thanks to Ernst Oudhof.
 - 2016-06-04 Fixed bug#[12094](http://bugs.otrs.org/show_bug.cgi?id=12094) - Stats matrix with month columns and year rows gets first row wrong.
 - 2016-06-03 Fixed bug#[12110](http://bugs.otrs.org/show_bug.cgi?id=12110) - ACL Queue limitation not working in CustomerTicketProcess, thanks to Thorsten Eckel.
 - 2016-06-03 Added support for fractional timeunits in GenericInterface TicketConnector, thanks to Jonas Wanninger.
 - 2016-06-03 Fixed bug#[12085](http://bugs.otrs.org/show_bug.cgi?id=12085) - CIC search links don't work when customer login contains parentheses.
 - 2016-06-23 Fixed Internal Server Error on attachment removal page reload, thanks to Pawel Boguslawski.
 - 2016-06-03 Fixed bug#[9241](http://bugs.otrs.org/show_bug.cgi?id=9241) - Ticket searching in GenericAgent not working as expected.
 - 2016-06-03 Fixed bug#[8761](http://bugs.otrs.org/show_bug.cgi?id=8761) - OTRS doesn't recognize URLs which contain nested URLs.
 - 2016-06-02 Fixed bug#[11775](http://bugs.otrs.org/show_bug.cgi?id=11775) - Link search term preserved when target object is changed.
 - 2016-06-01 Fixed bug#[12093](http://bugs.otrs.org/show_bug.cgi?id=12093) - OTRS Modern reply field issue.
 - 2016-05-27 Fixed bug#[12005](http://bugs.otrs.org/show_bug.cgi?id=12005) - Daemon / Scheduler will not run commands.
 - 2016-05-27 Fixed bug#[12074](http://bugs.otrs.org/show_bug.cgi?id=12074) - Redundant and confusing code in Kernel/System/TemplateGenerator.pm.
 - 2016-05-27 Fixed bug#[12018](http://bugs.otrs.org/show_bug.cgi?id=12018) - HTML body not retrieved on by GI operation TicketGet (Added HTMLBodyAsAttachment parameter to retrieve is as an attachment).
 - 2016-05-27 Fixed dynamic field backend POD, Thanks to Thorsten Eckel.
 - 2016-05-27 Fixed bug#[12090](http://bugs.otrs.org/show_bug.cgi?id=12090) - 2 second sleep between email fetching causes bad performance on systems with high email traffic.
 - 2016-05-25 Fixed bug#[12099](http://bugs.otrs.org/show_bug.cgi?id=12099) - Passing parameters to CustomerTicketMessage doesn't work correctly.
 - 2016-05-23 Added debugging switch for AJAX errors. Set Frontend::AjaxDebug to 1 in order to see more details in case of any "error during ajax communication" errors.
 - 2016-05-21 Fixed bug#[12012](http://bugs.otrs.org/show_bug.cgi?id=12012) - JSON Response contains all Dynamic Fields in Article response.
 - 2016-05-20 Fixed bug#[12069](http://bugs.otrs.org/show_bug.cgi?id=12069) - enabling/disabling Article Filter show wrong article.
 - 2016-05-19 7 Day Stats performance optimizations, thanks to Pawel Boguslawski.
 - 2016-05-20 Fixed bug#[12087](http://bugs.otrs.org/show_bug.cgi?id=12087) - AdminTemplate loses HTML tags.
 - 2016-05-20 Fixed bug#[8153](http://bugs.otrs.org/show_bug.cgi?id=8153) - When configuration area is not activated, it is still editable.
 - 2016-05-20 Fixed bug#[12084](http://bugs.otrs.org/show_bug.cgi?id=12084) - Missing day names from 7 Day Stat.
 - 2016-05-20 Fixed bug#[12066](http://bugs.otrs.org/show_bug.cgi?id=12066) - Hamburger icon shows up unwanted.
 - 2016-05-19 Followup for bug#[9950](http://bugs.otrs.org/show_bug.cgi?id=9950) - Ticket Split takes uses system address as the customer.
 - 2016-05-15 Added possibility to sign and/or encrypt ticket notifications.
 - 2016-05-13 Fixed bug#[12045](http://bugs.otrs.org/show_bug.cgi?id=12045) - Not possible to create a Ticket using TransitionAction::TicketCreate with Owner instead of OwnerID.
 - 2016-05-12 Fixed bug#[12062](http://bugs.otrs.org/show_bug.cgi?id=12062) - From field with dot is filled with spaces.
 - 2016-05-12 Fixed bug#[9345](http://bugs.otrs.org/show_bug.cgi?id=9345) - OTRS exceeds 998 character limit in References Line of E-Mail Header.
 - 2016-05-12 Fixed bug#[12061](http://bugs.otrs.org/show_bug.cgi?id=12061) - Secure::DisableBanner is ignored in Notification Mail.
 - 2016-05-12 Fixed bug#[12058](http://bugs.otrs.org/show_bug.cgi?id=12058) - Attribute CreatedQueues and CreatedQueueIDs in dashboard widget does not work.

# 5.0.10 2016-05-17
 - 2016-05-11 Updated translations, thanks to all translators.
 - 2016-05-11 Re-added missing console command Dev::Tools::GenericInterface::DebugRead, thanks to Rolf Schmidt.
 - 2016-05-10 Updated translations, thanks to all translators.
 - 2016-05-09 Fixed bug#[12053](http://bugs.otrs.org/show_bug.cgi?id=12053) - Use of uninitialized value $ModuleDirectory in concatenation (.) or string.
 - 2016-05-04 Fixed bug#[12040](http://bugs.otrs.org/show_bug.cgi?id=12040) - Emails are incorrectly attached to tickets.
 - 2016-05-04 Fixed bug#[12044](http://bugs.otrs.org/show_bug.cgi?id=12044) - PostMaster process crashed if a non existent ticket type is set via PostMaster filter.
 - 2016-05-04 Fixed bug#[12031](http://bugs.otrs.org/show_bug.cgi?id=12031) - SubSelected class not applied to My Tickets in CustomerTicketOverview Navigation.
 - 2016-05-04 Fixed bug#[12048](http://bugs.otrs.org/show_bug.cgi?id=12048) - error message with HTML <br> code.
 - 2016-05-04 Fixed bug#[12049](http://bugs.otrs.org/show_bug.cgi?id=12049) - Encoding problems in REST transport.
 - 2016-04-29 Fixed bug#[11614](http://bugs.otrs.org/show_bug.cgi?id=11614) - LDAP Auth loses Agent-Group relationships every 2nd login.
 - 2016-04-29 Fixed bug#[12036](http://bugs.otrs.org/show_bug.cgi?id=12036) - Escalation Notification % does not work for short intervals.
 - 2016-04-29 Fixed bug#[12033](http://bugs.otrs.org/show_bug.cgi?id=12033) - Wrong value selected automatically for Responsible in Bulk action..
 - 2016-04-29 Fixed bug#[12039](http://bugs.otrs.org/show_bug.cgi?id=12039) - Wrong default article type in reply.
 - 2016-04-27 Fixed bug#[11783](http://bugs.otrs.org/show_bug.cgi?id=11783) - EscalationsCheck alwasy triggers every Event.
 - 2016-04-26 Improved the way user last used zoom view type is stored for Timeline view in OTRS Business Solution™.
 - 2016-04-25 Fixed bug#[11729](http://bugs.otrs.org/show_bug.cgi?id=11729) - FAQ zoom elements are not collapsed correctly in IE if iframes are empty.
 - 2016-04-22 Fixed bug#[12017](http://bugs.otrs.org/show_bug.cgi?id=12017) - Modernized forms do not work as exspected in conjunction with ACLs.
 - 2016-04-22 Fixed bug#[12009](http://bugs.otrs.org/show_bug.cgi?id=12009) - Request-URI Too Large  The requested URL's length exceeds the capacity limit for this server.
 - 2016-04-22 Fixed bug#[12015](http://bugs.otrs.org/show_bug.cgi?id=12015) - FollowUpArticleTypeCheck.pm never fulfilled / check if current sender is customer (do nothing).
 - 2016-04-21 Added package verification information to Admin::Package::List console command, use bin/otrs.Console.pl Admin::Package::List --show-verification-info (to show package verification information) or bin/otrs.Console.pl Admin::Package::List --show-verification-info --delete-verification-cache (to show package verification information deleting the cache before).
 - 2016-04-15 Fixed bug#[12008](http://bugs.otrs.org/show_bug.cgi?id=12008) - Problem with UTF-8 argument passed to otrs.Console.pl.
 - 2016-04-15 Fixed bug#[11171](http://bugs.otrs.org/show_bug.cgi?id=11171) - Missing translation entries.
 - 2016-04-15 Fixed bug#[11996](http://bugs.otrs.org/show_bug.cgi?id=11996) - AgentCustomerSearch causes log errors.
 - 2016-04-15 Fixed bug#[11430](http://bugs.otrs.org/show_bug.cgi?id=11430) - (Ticket )Cache won't get updated on DynamicField ValueDelete.
 - 2016-04-15 Fixed bug#[11994](http://bugs.otrs.org/show_bug.cgi?id=11994) - Activating  PreferencesGroups###CSVSeparator triggers internal server error.
 - 2016-04-15 Fixed bug#[11992](http://bugs.otrs.org/show_bug.cgi?id=11992) - Cannot add or update a child row: a foreign key constraint fails when saving customer user theme.
 - 2016-04-12 Fixed bug#[11749](http://bugs.otrs.org/show_bug.cgi?id=11749) - Customer Search: attributes can't add with '+'.
 - 2016-04-08 Fixed bug#[11921](http://bugs.otrs.org/show_bug.cgi?id=11921) - Wrong attachment is deleted if deleting from multiple attachments from template in new ticket.
 - 2016-04-08 Fixed bug#[11917](http://bugs.otrs.org/show_bug.cgi?id=11917) - Generic Interface does show empty/wrong results when a space (+) is used with in the name.
 - 2016-04-08 Make out of office message configurable (setting OutOfOfficeMessageTemplate).
 - 2016-04-08 Improve X-Mailer email header if Secure::DisableBanner is active to avoid the mail being classified as SPAM, thanks to Renée Bäcker.
 - 2016-04-08 Fixed bug#[11982](http://bugs.otrs.org/show_bug.cgi?id=11982) - Follow-up: Labels overlap each other also on line charts.
 - 2016-04-08 Fixed bug#[11970](http://bugs.otrs.org/show_bug.cgi?id=11970) - Kill all sessions button text too long for button.
 - 2016-04-08 Fixed bug#[11990](http://bugs.otrs.org/show_bug.cgi?id=11990) - Kernel/Config/ files matching regex .pm may throw an error while loading.
 - 2016-04-08 Fixed bug#[11842](http://bugs.otrs.org/show_bug.cgi?id=11842) - Restful API with data type Boolean.
 - 2016-04-08 Fixed bug#[4640](http://bugs.otrs.org/show_bug.cgi?id=4640) - Wrong variable <OTRS_CUSTOMER_REALNAME> in Auto Responses.
 - 2016-04-06 Fixed bug#[11975](http://bugs.otrs.org/show_bug.cgi?id=11975) - Use of uninitialized value $NotUseTag in /opt/otrs/Kernel/System/Package.pm.
 - 2016-04-05 Fixed bug#[11918](http://bugs.otrs.org/show_bug.cgi?id=11918) - Placement of activities and other elements shifted.
 - 2016-04-05 Fixed bug#[11980](http://bugs.otrs.org/show_bug.cgi?id=11980) - Priority sorting in dashboard widgets not working for a custom column.
 - 2016-04-04 Fixed bug#[11973](http://bugs.otrs.org/show_bug.cgi?id=11973) - Mapping backend "Simple" can't get initialized multiple times. Thanks to Thorsten Eckel.
 - 2016-04-04 Fixed bug#[11353](http://bugs.otrs.org/show_bug.cgi?id=11353) - Not able to filter for CustomerID with brackets () at TicketViews.
 - 2016-04-04 Fixed bug#[11982](http://bugs.otrs.org/show_bug.cgi?id=11982) - Labels overlap each other on stacked area charts.
 - 2016-04-04 Fixed bug#[11978](http://bugs.otrs.org/show_bug.cgi?id=11978) - Something missing from PreferencesGroups###TicketOverviewFilterSettings description.
 - 2016-04-04 Fixed bug#[11979](http://bugs.otrs.org/show_bug.cgi?id=11979) - When OpenMainMenuOnHover is disabled, overlays open twice.
 - 2016-04-04 Fixed bug#[939](http://bugs.otrs.org/show_bug.cgi?id=939) - Change title to another text to distinguish it in other languages.
 - 2016-04-04 Fixed bug#[11948](http://bugs.otrs.org/show_bug.cgi?id=11948) - Dest preselect by URI in CustomerTicketMessage.
 - 2016-04-04 Fixed bug#[11966](http://bugs.otrs.org/show_bug.cgi?id=11966) - Creation of new LDAP-Users not working with GoogleAuthenticator activated.
 - 2016-03-30 Fixed bug#[11922](http://bugs.otrs.org/show_bug.cgi?id=11922) - Notification to non RealCustomer.

# 5.0.9 2016-04-05
 - 2016-03-30 Updated translations, thanks to all translators.
 - 2016-03-28 Fixed bug#[11957](http://bugs.otrs.org/show_bug.cgi?id=11957) - Inform agents not working, the agent who is different to owner not received notification.
 - 2016-03-22 Fixed bug#[11836](http://bugs.otrs.org/show_bug.cgi?id=11836) - Pending date selection impossible due ACL limitation.
 - 2016-03-22 Fixed bug#[11956](http://bugs.otrs.org/show_bug.cgi?id=11956) - locked tickets for invalid users are not shown in support data collector.
 - 2016-03-22 Fixed bug#[11954](http://bugs.otrs.org/show_bug.cgi?id=11954) - Can't handle double quotes as option value in modernized InputFields, thanks to Thorsten Eckel.
 - 2016-03-22 Fixed bug#[11944](http://bugs.otrs.org/show_bug.cgi?id=11944) - Inline images possible although image functionality is disabled.
 - 2016-03-21 Fixed bug#[11067](http://bugs.otrs.org/show_bug.cgi?id=11067) - Using a filter breaks the role - agent allocation in the admin interface.
 - 2016-03-18 Fixed bug#[11952](http://bugs.otrs.org/show_bug.cgi?id=11952) - Generic Interface - TicketUpdate operation - DynamicFields not possible empty value.
 - 2016-01-15 Follow-up fix for bug#[11560](http://bugs.otrs.org/show_bug.cgi?id=11560) - Error for connection to cloud on OTRS in a network which outbound access is blocked.
 - 2016-03-18 Fixed bug#[11811](http://bugs.otrs.org/show_bug.cgi?id=11811) - Error processing mail with incorrectly encoded emoticons.
 - 2016-03-18 Fixed bug#[11939](http://bugs.otrs.org/show_bug.cgi?id=11939) - Ticket move permission problem.
 - 2016-03-18 Fixed bug#[11894](http://bugs.otrs.org/show_bug.cgi?id=11894) - Notification to agents with write permissions ignores user roles.
 - 2016-03-18 Fixed bug#[11930](http://bugs.otrs.org/show_bug.cgi?id=11930) - Error 500 when searching string that ends with "\" in AdminCustomerUser.
 - 2016-03-17 Fixed bug#[11937](http://bugs.otrs.org/show_bug.cgi?id=11937) - Error opening PackageManager.
 - 2016-03-14 Fixed bug#[11528](http://bugs.otrs.org/show_bug.cgi?id=11528) - Group Name like 'test::Support::1st Line' is not possible to use for group restrictions.
 - 2016-03-11 Fixed bug#[11324](http://bugs.otrs.org/show_bug.cgi?id=11324) - OTRS webservices TicketGet operation returns always all articles.
 - 2016-03-10 Fixed bug#[10117](http://bugs.otrs.org/show_bug.cgi?id=10117) - Filter in queue view for customer userID shows only customers from given backend.
 - 2016-03-10 Fixed bug#[7301](http://bugs.otrs.org/show_bug.cgi?id=7301) - Customer can reply to merged tickets, wrong ticket will be reopened.

# 5.0.8 2016-03-15
 - 2016-03-09 Updated translations, thanks to all translators.
 - 2016-03-09 Fixed bug#[11560](http://bugs.otrs.org/show_bug.cgi?id=11560) - Error for connection to cloud on OTRS in a network which outbound access is blocked.
 - 2016-03-08 Fixed bug#[11893](http://bugs.otrs.org/show_bug.cgi?id=11893) - Pending reminder events not triggered if there are no valid pending auto states.
 - 2016-03-08 Fixed bug#[11840](http://bugs.otrs.org/show_bug.cgi?id=11840) - Inline images not displayed after ticket create via ProcessManagement.
 - 2016-03-08 Fixed bug#[11914](http://bugs.otrs.org/show_bug.cgi?id=11914) - Modernized InputField Dropdowns not working after AJAX reload.
 - 2016-03-06 Fixed bug#[11899](http://bugs.otrs.org/show_bug.cgi?id=11899) - Columns are stored multiple times in preferences.
 - 2016-03-04 Fixed bug#[11913](http://bugs.otrs.org/show_bug.cgi?id=11913) - Description in SysConfig breakes when you click 'more'.
 - 2016-03-03 Fixed bug#[9441](http://bugs.otrs.org/show_bug.cgi?id=9441) - Display of seconds after attachment upload.
 - 2016-03-03 Fixed bug#[11912](http://bugs.otrs.org/show_bug.cgi?id=11912) - Answer to email-internal is preset to email-external.
 - 2016-03-03 Fixed bug#[11791](http://bugs.otrs.org/show_bug.cgi?id=11791) - Can't use FullTextSearch with Russian words.
 - 2016-03-03 Fixed bug#[11754](http://bugs.otrs.org/show_bug.cgi?id=11754) - OwnerOnly is not respected in Dashboard Widget for Upcoming Events.
 - 2016-03-03 Fixed bug#[11526](http://bugs.otrs.org/show_bug.cgi?id=11526) - Some dropdowns in AgentTicketZoom do not use modernized input fields.
 - 2016-03-03 Fixed bug#[8188](http://bugs.otrs.org/show_bug.cgi?id=8188) - Disabled skins are still used.
 - 2016-03-03 Fixed bug#[6492](http://bugs.otrs.org/show_bug.cgi?id=6492) - Saving Search Templates.
 - 2016-03-03 Fixed bug#[11249](http://bugs.otrs.org/show_bug.cgi?id=11249) - EventsTicketCalendar: dynamic fields' value isn't translated for dropdown dynamic field type.
 - 2016-03-02 Fixed bug#[11877](http://bugs.otrs.org/show_bug.cgi?id=11877) - Closing AgentLinkObject popup throws JavaScript error in IE 11.
 - 2016-03-02 Fixed bug#[11839](http://bugs.otrs.org/show_bug.cgi?id=11839) - Generic Agent does not filter a value int text DF.
 - 2016-03-02 Fixed bug#[11745](http://bugs.otrs.org/show_bug.cgi?id=11745) - apostrophe in email can't be searched.
 - 2016-03-02 Fixed bug#[11873](http://bugs.otrs.org/show_bug.cgi?id=11873) - Click on disabled branches in modern inputs result provokes jquery errors.
 - 2016-03-02 Fixed bug#[11150](http://bugs.otrs.org/show_bug.cgi?id=11150) - Handling of dashboard widget names with special characters.
 - 2016-03-02 Fixed bug#[10117](http://bugs.otrs.org/show_bug.cgi?id=10117) - Filter in queue view for customer userID shows only customers from given backend.
 - 2016-03-02 Fixed bug#[11810](http://bugs.otrs.org/show_bug.cgi?id=11810) - <OTRS_TICKET_State> not translated to spanish when answering from AgentTicketZoom screen.
 - 2016-03-02 Fixed bug#[8154](http://bugs.otrs.org/show_bug.cgi?id=8154) - Uninstall button can be pressed twice.
 - 2016-03-01 Fixed bug#[11835](http://bugs.otrs.org/show_bug.cgi?id=11835) - Events Ticket Calendar disappears when EndTime before StartTime.
 - 2016-03-01 Fixed bug#[11901](http://bugs.otrs.org/show_bug.cgi?id=11901) - Process Configuration ist destroyed in IE11 if changing data in e.g. Activity popup.
 - 2016-03-01 Fixed bug#[11804](http://bugs.otrs.org/show_bug.cgi?id=11804) - Too much whitespace in AgentTicketCustomer popup.
 - 2016-03-01 Fixed bug#[11855](http://bugs.otrs.org/show_bug.cgi?id=11855) - Y-axis labels of TicketStats dashboard module cut off if more than 3 digits long.
 - 2016-03-01 Fixed bug#[11168](http://bugs.otrs.org/show_bug.cgi?id=11168) - Lost condition in AgentTicketSearch.
 - 2015-03-01 Fixed bug#[11116](http://bugs.otrs.org/show_bug.cgi?id=11116) - No Loading symbol while searching for customer.
 - 2016-03-01 Fixed bug#[11888](http://bugs.otrs.org/show_bug.cgi?id=11888) - Customer Information center closed ticket counter includes merged and removed.
 - 2016-03-01 Fixed bug#[11886](http://bugs.otrs.org/show_bug.cgi?id=11886) - ACL Action missing.
 - 2016-03-01 Fixed bug#[11854](http://bugs.otrs.org/show_bug.cgi?id=11854) - Using the spam button with a restricting ACL leads to useless error message, thanks to S7.
 - 2016-03-01 Fixed bug#[11220](http://bugs.otrs.org/show_bug.cgi?id=11220) - Highlighting broken for holiday dates in Calendar Datepicker.
 - 2016-03-01 Fixed bug#[11897](http://bugs.otrs.org/show_bug.cgi?id=11897) - Text in the Queue View is not translateable.
 - 2016-03-01 Fixed bug#[11900](http://bugs.otrs.org/show_bug.cgi?id=11900) - Browser zoom: Link page design broken.
 - 2016-03-01 Fixed bug#[11234](http://bugs.otrs.org/show_bug.cgi?id=11234) - Attachments lost due to filename collision in ArticleStorageFS.
 - 2016-03-01 Fixed bug#[11866](http://bugs.otrs.org/show_bug.cgi?id=11866) - Customer history destroys the customer information.
 - 2016-02-29 Fixed bug#[11874](http://bugs.otrs.org/show_bug.cgi?id=11874) - Restrict service based on state when posting a note.
 - 2016-02-29 Fixed bug#[11693](http://bugs.otrs.org/show_bug.cgi?id=11693) - Display issues with new style fields filters with many entries.
 - 2016-02-29 Fixed bug#[11757](http://bugs.otrs.org/show_bug.cgi?id=11757) - otrs.Console.pl Maint::Stats::Generate - language option not working.
 - 2016-02-29 Fixed bug#[11821](http://bugs.otrs.org/show_bug.cgi?id=11821) - Invisible fields are validated in ActivityDialogs.
 - 2016-02-29 Fixed bug#[11878](http://bugs.otrs.org/show_bug.cgi?id=11878) - Dashboard Widget Online removes menu bar if Italian language is set.
 - 2016-02-26 Fixed bug#[10303](http://bugs.otrs.org/show_bug.cgi?id=10303) - Created Date Not Available as a Dashboard Column.
 - 2016-02-26 Fixed bug#[11891](http://bugs.otrs.org/show_bug.cgi?id=11891) - Unit Tests fail if MIME::EncWords is installed.
 - 2016-02-23 Fixed bug#[11882](http://bugs.otrs.org/show_bug.cgi?id=11882) - Untraslatable string.
 - 2016-02-23 Fixed bug#[8971](http://bugs.otrs.org/show_bug.cgi?id=8971) - NewPhoneTicket toolbar button - does not check group settings, thanks to S7.
 - 2016-02-23 Fixed bug#[11179](http://bugs.otrs.org/show_bug.cgi?id=11179) - InformUser and InvolvedUser can be injected even if they are disabled in SysConfig.
 - 2016-02-23 Fixed bug#[11807](http://bugs.otrs.org/show_bug.cgi?id=11807) - Inconsistent key navigation in modernized input fields.
 - 2016-02-22 Fixed bug#[11862](http://bugs.otrs.org/show_bug.cgi?id=11862) - Ticket Notification Management - 'Send by default' has no impact.
 - 2016-02-18 Deprecated unused ObjectLockState package and gi_object_lock_state table.
 - 2016-02-15 Fixed bug#[11870](http://bugs.otrs.org/show_bug.cgi?id=11870) - Missing quoting in Layout::AgentQueueListOption().

# 5.0.7 2016-02-16
 - 2016-02-10 Updated translations, thanks to all translators.
 - 2016-02-08 Made both the Subject and Reference follow up checks optional, so that they can be turned off.
 - 2016-02-08 Add new config setting Package::AllowLocalModifications. If this setting is active, local modifications will not be highlighted as errors in the package manager and the support data collector.
 - 2016-02-04 Added a --quiet option to suppress console command output, thanks to Moritz Lenz.
 - 2016-02-01 Fixed bug#[11820](http://bugs.otrs.org/show_bug.cgi?id=11820) - Match on !~ "int" for external articles not enough.
 - 2016-02-01 Fixed bug#[11838](http://bugs.otrs.org/show_bug.cgi?id=11838) - New tabs opened from links in a sandboxed Iframe cannot execute JavaScript.
 - 2016-02-01 Fixed bug#[11829](http://bugs.otrs.org/show_bug.cgi?id=11829) - Main and ticket menu subentries disappear.
 - 2016-01-26 Fixed bug#[11827](http://bugs.otrs.org/show_bug.cgi?id=11827) - Invalid or missing default ticket type throws error in log.
 - 2016-01-25 Fixed bug#[11825](http://bugs.otrs.org/show_bug.cgi?id=11825) - Agent Notification Preferences cannot be set in AdminUser.
 - 2016-01-25 Added new button "Remove Quote" to richtext editor.
 - 2016-01-22 Fixed bug#[11813](http://bugs.otrs.org/show_bug.cgi?id=11813) - Changing agent email address disables his notifications preferences.
 - 2016-01-21 Fixed bug#[11818](http://bugs.otrs.org/show_bug.cgi?id=11818) - Missing required settings in default TicketConnecor SOAP yaml web service.
 - 2016-01-21 Fixed bug#[11817](http://bugs.otrs.org/show_bug.cgi?id=11817) - SLAID from TicketGet response Article has wrong cardinality in WSDL.
 - 2016-01-21 Fixed bug#[11803](http://bugs.otrs.org/show_bug.cgi?id=11803) - Got no ProcessEntityID or TicketID and ActivityDialogEntityID!.
 - 2016-01-21 Fixed bug#[6350](http://bugs.otrs.org/show_bug.cgi?id=6350) - Sort order in "Auto Responses <-> Queues", thanks to S7.
 - 2016-01-21 Fixed bug#[11802](http://bugs.otrs.org/show_bug.cgi?id=11802) - Customer user can get access to all ticket data.
 - 2016-01-19 Fixed bug#[11717](http://bugs.otrs.org/show_bug.cgi?id=11717) - Views with iFrames not scrollable on iOS.
 - 2016-01-15 Follow-up fix for bug#[11696](http://bugs.otrs.org/show_bug.cgi?id=11696) - Queue overview displays Queues with no avaible tickets.
 - 2016-01-15 Do not let customers know if other tickets exist or not (thanks to Renée Bäcker).
 - 2016-01-15 Fixed bug#[11786](http://bugs.otrs.org/show_bug.cgi?id=11786) - Reference of undefined variable in AgentTicketSearch.
 - 2016-01-15 Fixed bug#[11794](http://bugs.otrs.org/show_bug.cgi?id=11794) - Agent with quote in this name cannot list owner.
 - 2016-01-15 Fixed bug#[11801](http://bugs.otrs.org/show_bug.cgi?id=11801) - Default value "Lock after follow-up" changed in Queue Management.

# 5.0.6 2016-01-19
 - 2016-01-13 Updated translations, thanks to all translators.
 - 2016-01-12 Fixed bug#[11798](http://bugs.otrs.org/show_bug.cgi?id=11798) -  HTML preview on Ticket Notification is broken.
 - 2016-01-12 Improved OTRS Business Solution™ availability check to be performed only on already upgraded systems.
 - 2016-01-12 Fixed bug#[11793](http://bugs.otrs.org/show_bug.cgi?id=11793) - Wrong subgroup for agent preference settings.
 - 2016-01-12 Fixed bug#[11728](http://bugs.otrs.org/show_bug.cgi?id=11728) - Dashboard Widget: Attributes OwnerIDs is not working.
 - 2016-01-11 Updated CKEditor to version 4.5.6.
 - 2016-01-10 Added Hungarian notification event messages, thanks to Balazs Ur.
 - 2016-01-08 Fixed a bug where chat message times would not include user time zone information.
 - 2016-01-07 Fixed bug#[11755](http://bugs.otrs.org/show_bug.cgi?id=11755) - PGP MIME signed email with long lines does not verify signature correctly.
 - 2016-01-07 Slightly improved fatal error screen.
 - 2016-01-04 Added new Thai translation.
 - 2015-12-22 Fixed bug#[10969](http://bugs.otrs.org/show_bug.cgi?id=10969) - Problem whith SMIME-Cert that is valid for more than one E-Mail-Address.
 - 2015-12-22 Fixed bug#[11764](http://bugs.otrs.org/show_bug.cgi?id=11764) - Wrong Ticket::Frontend::AgentTicketService###DefaultColumns subgroup.
 - 2015-12-22 Fixed bug#[11765](http://bugs.otrs.org/show_bug.cgi?id=11765) - Wrong Sysconfig descriptions in Kernel/Config/Files/Ticket.xml.
 - 2015-12-22 Improved support for Hungarian, thanks to Balazs Ur.
 - 2015-12-17 Fixed bug#[11759](http://bugs.otrs.org/show_bug.cgi?id=11759) - AgentStats does not work if you try to configure the x-axis of an ITSMConfigItem statistic.
 - 2015-12-16 Fixed bug#[11628](http://bugs.otrs.org/show_bug.cgi?id=11628) - DynamicField - BaseSelect.pm - missing check of DF in parameter Template in method "EditFieldValueGet".
 - 2015-12-16 Fixed bug#[11696](http://bugs.otrs.org/show_bug.cgi?id=11696) - Queue overview displays Queues with no avaible tickets.
 - 2015-12-16 Fixed bug#[9038](http://bugs.otrs.org/show_bug.cgi?id=9038) - Default Ticket Type in Emails.....
 - 2015-12-16 Fixed bug#[11695](http://bugs.otrs.org/show_bug.cgi?id=11695) - Inconsistency with the sorting icon.
 - 2015-12-16 Fixed bug#[8760](http://bugs.otrs.org/show_bug.cgi?id=8760) - digest algorithm SHA1 is hardcoded in PGP/MIME signed messages.
 - 2015-12-16 Fixed bug#[3688](http://bugs.otrs.org/show_bug.cgi?id=3688) - Emails to a "deeply merged" ticket are added to the wrong ticket.
 - 2015-12-15 Fixed bug#[3785](http://bugs.otrs.org/show_bug.cgi?id=3785) - issuing cron jobs include backup files from them.
 - 2015-12-15 Fixed bug#[8828](http://bugs.otrs.org/show_bug.cgi?id=8828) - No embedded images in autoresponses.
 - 2015-12-15 Fixed bug#[7730](http://bugs.otrs.org/show_bug.cgi?id=7730) - Security: Notification Tags can be used to display critical data in Answers.
 - 2015-12-15 Fixed bug#[11373](http://bugs.otrs.org/show_bug.cgi?id=11373) - CustomerID in AgentTicketPhone accepts any value, thanks to S7.
 - 2015-12-15 Fixed bug#[10883](http://bugs.otrs.org/show_bug.cgi?id=10883) - Do not hardcode X-Frame-Options: SAMEORIGIN.
 - 2015-12-15 Fixed bug#[11182](http://bugs.otrs.org/show_bug.cgi?id=11182) - otrs.SyncLDAP2DB.pl produces invalid SQL statements.
 - 2015-12-15 Fixed bug#[11705](http://bugs.otrs.org/show_bug.cgi?id=11705) - Ticket filters are displayed incorrectly.
 - 2015-12-14 Fixed bug#[7708](http://bugs.otrs.org/show_bug.cgi?id=7708) - Only 400 agents available in AdminUser.
 - 2015-12-14 Fixed bug#[11406](http://bugs.otrs.org/show_bug.cgi?id=11406) - Values of a dynamic field of type multiselect are not shown in dashoard ticket calendar.
 - 2015-12-14 Fixed bug#[11286](http://bugs.otrs.org/show_bug.cgi?id=11286) - Default-Value "X-Envelope-To" instead of "Envelope-To" in PostmasterX-Header.
 - 2015-12-14 Fixed bug#[11738](http://bugs.otrs.org/show_bug.cgi?id=11738) - Generate Support Bundle throws errors when HTTPS is used as HTTPTYPE.
 - 2015-12-14 Fixed bug#[10510](http://bugs.otrs.org/show_bug.cgi?id=10510) - Problem sending attachments with wrong mime type.
 - 2015-12-14 Fixed bug#[11722](http://bugs.otrs.org/show_bug.cgi?id=11722) - Undefined for undefined variable at requesting LostPasswordToken, thanks to Norihiro Tanaka.
 - 2015-12-14 Fixed bug#[11733](http://bugs.otrs.org/show_bug.cgi?id=11733) - Field details in activity dialogs are not correctly loaded if they contain single quotes.
 - 2015-12-11 Fixed bug#[11667](http://bugs.otrs.org/show_bug.cgi?id=11667) - Can't perform POST on https://cloud.otrs.com/otrs/public.pl: 500 read timeout.

# 5.0.5 2015-12-15
 - 2015-12-08 Updated translations, thanks to all translators.
 - 2015-12-08 Fixed bug#[11721](http://bugs.otrs.org/show_bug.cgi?id=11721) - $Self->{Debug} is not passed to frontend modules.
 - 2015-12-07 Fixed bug#[10266](http://bugs.otrs.org/show_bug.cgi?id=10266) - Time Units can not be displayed and used in process Activity Dialogues.
 - 2015-12-04 Follow-up fix for bug#[11625](http://bugs.otrs.org/show_bug.cgi?=11625) - Daemon tasks error messages does not show the task name.
 - 2015-12-04 Fixed bug#[11652](http://bugs.otrs.org/show_bug.cgi?id=11652) - Jobs from the GenericAgent Config file use wrong ticket limit.
 - 2015-12-04 Fixed bug#[11680](http://bugs.otrs.org/show_bug.cgi?id=11680) - Error in support data collector.
 - 2015-12-03 Fixed bug#[11666](http://bugs.otrs.org/show_bug.cgi?id=11666) - Problem Creating DynamicField For Article and Including It on an Activity Window.
 - 2015-12-03 Fixed bug#[11712](http://bugs.otrs.org/show_bug.cgi?id=11712) - Sysconfig validation fills newly added field with default value.
 - 2015-12-03 Fixed bug#[8511](http://bugs.otrs.org/show_bug.cgi?id=8511) - TemplateGenerator.pm - Use of uninitialized value in substitution iterator at 1028.
 - 2015-12-02 Fixed bug#[11096](http://bugs.otrs.org/show_bug.cgi?id=11096) - action URL overwrites permission settings thanks to S7.
 - 2015-12-02 Fixed bug#[11709](http://bugs.otrs.org/show_bug.cgi?id=11709) - In move notification <OTRS_CUSTOMER_BODY> is replaced with ticket comment, not last customer body, thanks to S7.
 - 2015-12-02 Fixed bug#[11708](http://bugs.otrs.org/show_bug.cgi?id=11708) - Missing Ticket Escalation cron task.
 - 2015-11-30 Fixed bug#[11700](http://bugs.otrs.org/show_bug.cgi?id=11700) - IE is closing popup directly after opening it.
 - 2015-11-30 Fixed bug#[11686](http://bugs.otrs.org/show_bug.cgi?id=11686) - Signature Management does not keep an inserted image when editing the source HTML.
 - 2015-11-27 Fixed bug#[9074](http://bugs.otrs.org/show_bug.cgi?id=9074) - No owner restriction via ACL using Frontend -> Action.
 - 2015-11-27 Fixed bug#[11694](http://bugs.otrs.org/show_bug.cgi?id=11694) - Various errors in GenericTicketConnectorSOAP.wsdl file, thanks to Cyrille Bollu.
 - 2015-11-26 Fixed bug#[11692](http://bugs.otrs.org/show_bug.cgi?id=11692) - Typo in AdminNotificationEvent.tt (Attibutes).
 - 2015-11-26 Fixed bug#[11393](http://bugs.otrs.org/show_bug.cgi?id=11393) - ACL not hiding Process NavBar link when Type is Menu.
 - 2015-11-26 Fixed bug#[11574](http://bugs.otrs.org/show_bug.cgi?id=11574) - Dashboard - Queue - Attributes of the Widget are not used in the  'Tickets in my Service' view.
 - 2015-11-26 Fixed bug#[11605](http://bugs.otrs.org/show_bug.cgi?id=11605) - New ticket notification names are not translated in agent preferences.
 - 2015-11-26 Fixed bug#[9061](http://bugs.otrs.org/show_bug.cgi?id=9061) - Initial queues are set to "Ticket lock after follow-up: yes".
 - 2015-11-26 Fixed bug#[11663](http://bugs.otrs.org/show_bug.cgi?id=11663) - View type not saved to UserPreferences in AgentTicketZoom.
 - 2015-11-26 Fixed bug#[11688](http://bugs.otrs.org/show_bug.cgi?id=11688) - otrs.Console.pl Maint::Session::ListExpired shows wrong message.
 - 2015-11-25 Fixed bug#[9152](http://bugs.otrs.org/show_bug.cgi?id=9152) - Event based notification with attachments does not quote article content.

# 5.0.4 2015-12-01
 - 2015-11-24 Updated translations, thanks to all translators.
 - 2015-11-24 Fixed bug#[11654](http://bugs.otrs.org/show_bug.cgi?id=11654) - Internal server error with limit 0 in out-of-office-dashboard.
 - 2015-11-24 Fixed bug where some special unicode characters (line terminators) were not correctly encoded to JSON.
 - 2015-11-24 Fixed bug#[11472](http://bugs.otrs.org/show_bug.cgi?id=11472) - Process Management: Activity Dialog configuration for Article field is default set to "Do not show field".
 - 2015-11-24 Fixed bug#[10931](http://bugs.otrs.org/show_bug.cgi?id=10931) - Reply to note does not use the origin note subject, thanks to S7.
 - 2015-11-23 Added the possibility to set notifications as mandatory. Agents will be forced to chose at least one method for such notifications on their preferences.
 - 2015-11-23 Fixed bug#[11677](http://bugs.otrs.org/show_bug.cgi?id=11677) - Stale entries in article_search table prevent ticket from being deleted.
 - 2015-11-20 Fixed bug#[11675](http://bugs.otrs.org/show_bug.cgi?id=11675) - A wrong cron schedule such as 2 2 31 2 * (Feb 31th) causes daemon to hang.
 - 2015-11-20 Fixed bug#[11647](http://bugs.otrs.org/show_bug.cgi?id=11647) - Ticket Notifications Broke when RichText is turned off.
 - 2015-11-20 Fixed bug#[10938](http://bugs.otrs.org/show_bug.cgi?id=10938) - Missing translation 'Linked As' in OTRS Interface.
 - 2015-11-20 Fixed bug#[11607](http://bugs.otrs.org/show_bug.cgi?id=11607) - charset string in body gets replaced.
 - 2015-11-20 Add possibility to XMLExecute command to only run pre or post SQL, thanks to Elias Probst.
 - 2015-11-19 Fixed bug#[11168](http://bugs.otrs.org/show_bug.cgi?id=11168) - Lost condition in AgentTicketSearch, thanks to Norihiro Tanaka.
 - 2015-11-18 Don't show warning about running otrs.Console.pl --allow-root as root as this changes the output stream.
 - 2015-11-17 Fixed bug#[7987](http://bugs.otrs.org/show_bug.cgi?id=7987) - Ticket dashboard modules not working with unlocked tickets attributes, thanks to S7.
 - 2015-11-16 Fixed bug#[11205](http://bugs.otrs.org/show_bug.cgi?id=11205) - Popup window height does not check for actual screen height.
 - 2015-11-16 Fixed bug#[11651](http://bugs.otrs.org/show_bug.cgi?id=11651) - All customers shown as invalid if using an LDAP backend.
 - 2015-11-13 Fixed bug#[11351](http://bugs.otrs.org/show_bug.cgi?id=11351) - S/Mime signed mails always show "Signature verified before!".
 - 2015-11-06 Fixed bug#[11348](http://bugs.otrs.org/show_bug.cgi?id=11348) - Error handling in AgentTicketForward.
 - 2015-11-12 Added dutch stopwords, thanks to Thomas Wouters.
 - 2015-11-11 Added translation strings form Kernel/Output/HTML/Templates/Standard sub-directories.
 - 2015-11-11 Fixed bug#[11642](http://bugs.otrs.org/show_bug.cgi?id=11642) - Console Command Dev::Tools::TranslationsUpdate skips nested .tt files when gather translation strings.
 - 2015-11-11 Fixed bug#[11641](http://bugs.otrs.org/show_bug.cgi?id=11641) - SchedulerDB TaskUnlockExpired() Need String! message..
 - 2015-11-11 Set all OTRS Daemon cron tasks SysConfig settings to "Expert" ConfigLevel.

# 5.0.3 2015-11-17
 - 2014-11-11 Updated translations, thanks to all translators.
 - 2015-11-11 Fixed bug#[11601](http://bugs.otrs.org/show_bug.cgi?id=11601) - OTRS 5 - 2fa and password change - error.
 - 2015-11-09 Fixed bug#[11511](http://bugs.otrs.org/show_bug.cgi?id=11511) - Text length for title is cut off after 50 characters.
 - 2015-11-09 Fixed bug#[11630](http://bugs.otrs.org/show_bug.cgi?id=11630) - Localization French.
 - 2015-11-09 Fixed bug#[11320](http://bugs.otrs.org/show_bug.cgi?id=11320) - Invalid customer user can update password.
 - 2015-11-09 Fixed bug#[11633](http://bugs.otrs.org/show_bug.cgi?id=11633) - When running the Maint::Database::Check before upgrading a confusing message appears.
 - 2015-11-09 Fixed bug#[11572](http://bugs.otrs.org/show_bug.cgi?id=11572) - Multiple responsive layout issues in AgentTicketCompose.
 - 2015-11-09 Fixed bug#[5509](http://bugs.otrs.org/show_bug.cgi?id=5509) - Wrong umlauts if bounce function is used.
 - 2015-11-09 Fixed bug#[11475](http://bugs.otrs.org/show_bug.cgi?id=11475) - Kernel::System::MailAccount::IMAP->Fetch() could delete unprocessed mails from server.
 - 2015-11-08 Fixed bug#[11592](http://bugs.otrs.org/show_bug.cgi?id=11592) - NotificationArticleType ignored at notification for customer.
 - 2015-11-08 Fixed bug#[11632](http://bugs.otrs.org/show_bug.cgi?id=11632) - TicketNotification, English is not always the default language.
 - 2015-11-06 Fixed bug#[9884](http://bugs.otrs.org/show_bug.cgi?id=9884) - Solution Time counts wrong on daylight time changes.
 - 2015-11-06 Follow-up fix for bug#[11586](http://bugs.otrs.org/show_bug.cgi?id=11586) - Cannot show collapsed view by default if config Ticket::Frontend::ZoomExpand is true.
 - 2015-11-06 Follow-up fix for bug#[11194](http://bugs.otrs.org/show_bug.cgi?id=11194) - Download button for dashboard stats visible even if no permissions for AgentStats exist.
 - 2015-11-06 Fixed bug#[10477](http://bugs.otrs.org/show_bug.cgi?id=10477) - Printing: numbering of article does not equal to the numbering of PDF.
 - 2015-11-05 Fixed bug#[11600](http://bugs.otrs.org/show_bug.cgi?id=11600) - Dynamic Field of type multiselect is not substituted correctly.
 - 2015-11-05 Fixed bug#[11340](http://bugs.otrs.org/show_bug.cgi?id=11340) - Broken value after copying values from DynamicField multiselect to multiselect during process transition action TicketCreate.
 - 2015-11-05 Fixed bug#[11625](http://bugs.otrs.org/show_bug.cgi?id=11625) - Daemon tasks error messages does not show the task name.
 - 2015-11-05 Fixed bug#[11492](http://bugs.otrs.org/show_bug.cgi?id=11492) - Stats do not honor the Ticket::Service::KeepChildren parameter.
 - 2015-11-05 Fixed bug#[11595](http://bugs.otrs.org/show_bug.cgi?id=11595) - Infinite notification loop caused by ArticleCustomerNotification.
 - 2015-11-05 Fixed bug#[11350](http://bugs.otrs.org/show_bug.cgi?id=11350) - Translation for string Created not working at Dashboard widget.
 - 2015-11-05 Fixed bug#[11269](http://bugs.otrs.org/show_bug.cgi?id=11269) - Admin Service: empty value for description field shows as () below the form field.
 - 2015-11-05 Fixed bug#[11468](http://bugs.otrs.org/show_bug.cgi?id=11468) - Using SVG images for Agent and Customer logo requires additional CSS.
 - 2015-11-05 Fixed bug#[11616](http://bugs.otrs.org/show_bug.cgi?id=11616) - \_DBGroupRoleGet will return incorrect permissions.
 - 2015-11-03 Fixed bug#[11565](http://bugs.otrs.org/show_bug.cgi?id=11565) - New article notification(star) and entry created for agent that creates the ticket.
 - 2015-11-03 Added possibility to search for console commands. Just use bin/otrs.Console.pl Help SearchTerm to search for commands similar to SearchTerm.
 - 2015-11-02 Fixed bug#[11558](http://bugs.otrs.org/show_bug.cgi?id=11558) - Empty Agent preferences tooltip in AdminNotificationEvent.

# 5.0.2 2015-11-03
 - 2015-10-30 Fixed bug#[11608](http://bugs.otrs.org/show_bug.cgi?id=11608) - Console command Dev::Tools::TranslationsUpdate skips the first language.
 - 2015-10-30 Fixed bug#[11552](http://bugs.otrs.org/show_bug.cgi?id=11552) - No modernized input fields in the dashboard stat settings.
 - 2015-10-30 Fixed bug#[11575](http://bugs.otrs.org/show_bug.cgi?id=11575) - Logo overlaps toolbar when using slim skins.
 - 2015-10-30 Fixed bug#[11604](http://bugs.otrs.org/show_bug.cgi?id=11604) - AgentTicketForward is still using the old select fields style.
 - 2015-10-18 Updated translations, thanks to all translators.
 - 2015-10-27 Fixed richtext editor drag and drop functionality for images.
 - 2015-10-26 Fixed bug#[11559](http://bugs.otrs.org/show_bug.cgi?id=11559) - Can not upgrade user preferences for notification with DBUpdate-to-5.pl, thanks to Norihiro Tanaka.
 - 2015-10-23 Fixed bug#[11545](http://bugs.otrs.org/show_bug.cgi?id=11545) - When Phone or Email ticket created, runtime error.
 - 2015-10-22 Fixed bug#[11570](http://bugs.otrs.org/show_bug.cgi?id=11570) - Calling AgentStatisticsReports does not show the correct message when OpenMainMenuOnHover is disabled.
 - 2015-10-22 Fixed bug#[11553](http://bugs.otrs.org/show_bug.cgi?id=11553) - In some languages the buttons to create a statistics have diffrent heights.
 - 2015-10-22 Fixed bug#[11557](http://bugs.otrs.org/show_bug.cgi?id=11557) - Ticket Notifications in personal preferences is sorted badly.
 - 2015-10-20 Fixed LogObject call in InterfaceInstaller.pm.

# 5.0.1 2015-10-20
 - 2015-10-19 Fixed bug#[11566](http://bugs.otrs.org/show_bug.cgi?id=11566) - Once per day notification setting is not honored if sendmail backend is used under certain circumstances.
 - 2015-10-16 Fixed bug#[11562](http://bugs.otrs.org/show_bug.cgi?id=11562) -  Tickets with status 'pending auto close -/+' will be closed as usually, but a 'Ticket locked out' notification is send to agents.
 - 2015-10-15 Added new 'Unformatted' template for email notification method.
 - 2015-10-15 Fixed bug#[11556](http://bugs.otrs.org/show_bug.cgi?id=11556) - Searching in inputfields does not hide non-matching entries.
 - 2015-10-14 Updated CPAN module URI to version 1.69.
 - 2015-10-14 Updated CPAN module Text::Diff to version 1.43.
 - 2015-10-14 Updated CPAN module SOAP::Lite to version 1.19.
 - 2015-10-14 Updated CPAN module REST::Client to version 273.
 - 2015-10-14 Updated CPAN module PDF::API2 to version 2.025.
 - 2015-10-13 Updated translations, thanks to all translators.
 - 2015-10-13 Fix missing ticket cache clear after ticket merge, fixes Ticket#2015092442000716.
 - 2015-10-13 Updated CKEditor to version 4.5.4.
 - 2015-10-12 Fixed bug#[11535](http://bugs.otrs.org/show_bug.cgi?id=11535) -  Listed message for disabled languages in ticket notification management, thanks to S7.
 - 2015-10-12 Fixed bug#[11519](http://bugs.otrs.org/show_bug.cgi?id=11519) - Old message in AgentTicketBounce, thanks to Norihiro Tanaka.
 - 2015-10-12 Fixed bug#[11510](http://bugs.otrs.org/show_bug.cgi?id=11510) - AgentTicketMove empty by sysconfig changes.
 - 2015-10-12 Fixed bug#[11255](http://bugs.otrs.org/show_bug.cgi?id=11255) - Forwarding Templates do not work with rich text disabled.
 - 2015-10-10 Fixed bug#[11260](http://bugs.otrs.org/show_bug.cgi?id=11260) - Missing translation escalation, thanks to S7.
 - 2015-10-09 Fixed bug#[11467](http://bugs.otrs.org/show_bug.cgi?id=11467) - ACL does not work with Dest Link in Customer::ModuleRegistration, thanks to S7.
 - 2015-10-09 Fixed bug#[11513](http://bugs.otrs.org/show_bug.cgi?id=11513) - Out of Office is missing in owner dropdown.
 - 2015-10-09 Fixed bug#[11530](http://bugs.otrs.org/show_bug.cgi?id=11530) - Some messages are not translatable, thanks to S7.
 - 2015-10-09 Fixed bug#[11544](http://bugs.otrs.org/show_bug.cgi?id=11544) - Missing Dynamic Field Name in container div class in Customer Interface.

# 5.0.0.rc1 2015-10-13
 - 2015-10-08 Updated translations, thanks to all translators.
 - 2015-10-07 Fixed bug#[11541](http://bugs.otrs.org/show_bug.cgi?id=11541) - Wrong HTML quoted on text sending 2 or more notifications.
 - 2015-10-06 Updated CKEditor to version 4.5.3.
 - 2015-10-06 Updated qUnit to version 1.19.0.
 - 2015-10-06 Updated MomentJS to version 2.10.6.
 - 2015-10-06 Updated jQuery Validate to version 1.14.0.
 - 2015-10-06 Updated FullCalendar to version 2.4.0.
 - 2015-10-06 Updated d3 to verion 3.5.6.
 - 2015-10-06 Updated CanVG to version 1.4.
 - 2015-10-05 Fixed bug#[11517](http://bugs.otrs.org/show_bug.cgi?id=11517) - Error in password of customer user is blank with Oracle Database, thanks to Norihiro Tanaka.
 - 2015-10-05 Fixed bug#[11527](http://bugs.otrs.org/show_bug.cgi?id=11527) - Validation highlights wrong field.
 - 2015-10-05 Fixed bug#[11523](http://bugs.otrs.org/show_bug.cgi?id=11523) - Attachments from a selected template disappear when add another attachment.
 - 2015-10-05 Fixed bug#[11532](http://bugs.otrs.org/show_bug.cgi?id=11532) - Error messages generated by DBUpdate-to-5.pl.
 - 2015-10-05 Fixed bug#[11531](http://bugs.otrs.org/show_bug.cgi?id=11531) - uninitialized value $identifier in DBUpdate-to-5.pl.
 - 2015-10-03 Updated CPAN module Mozilla::CA to version 20150826.
 - 2015-10-03 Updated CPAN module MIME::Tools to version 5.507.
 - 2015-10-03 Updated CPAN module Locale::Codes to version 3.36.
 - 2015-10-02 Fixed bug#[11524](http://bugs.otrs.org/show_bug.cgi?id=11524) - HTMLUtils::Truncate() dies if string contains an utf8 character that needs more than 2 bytes.
 - 2015-10-02 Updated CPAN module HTTP::Headers to version 6.11.
 - 2015-10-02 Updated CPAN module Excel::Writer::XLSX to version 0.85.
 - 2015-10-02 Fixed bug#[11471](http://bugs.otrs.org/show_bug.cgi?id=11471) - Generic Agent: Select fields can not be unset.
 - 2015-10-01 Fixed bug#[11525](http://bugs.otrs.org/show_bug.cgi?id=11525) - Wrong HTML quoted on notification for ticket created from plain text email.
 - 2015-10-01 Fixed bug#[11486](http://bugs.otrs.org/show_bug.cgi?id=11486) - endless recursion if sub module of Layout is buggy.
 - 2015-09-30 Fixed bug#[11514](http://bugs.otrs.org/show_bug.cgi?id=11514) - Unable to use bulk action in mobile mode.
 - 2015-09-29 Fixed bug#[11516](http://bugs.otrs.org/show_bug.cgi?id=11516) - Pending time will be ignored in the console command for the pending auto close check.
 - 2015-09-29 Fixed bug#[11515](http://bugs.otrs.org/show_bug.cgi?id=11515) - Ticket notifications sends the content of the previous notification on the same event.
 - 2015-09-29 Fixed bug#[11507](http://bugs.otrs.org/show_bug.cgi?id=11507) - No ticket event notifications with out of office enabled, but not within ooO timeframe..
 - 2015-09-29 Updated DejaVu fonts to version 2.35.
 - 2015-09-25 Stats::Dynamic::TicketList: Add 'NumberOfArticles' ticket attribute. Thanks to Elias Probst.
 - 2015-09-25 Fixed bug#[11078](http://bugs.otrs.org/show_bug.cgi?id=11078) - Extra newline is inserted in the text wrapping.
 - 2015-09-25 Fixed bug#[8220](http://bugs.otrs.org/show_bug.cgi?id=8220) - OutOfOffice does not check if end date is before start date.
 - 2015-09-25 Fixed bug#[11317](http://bugs.otrs.org/show_bug.cgi?id=11317) - When service is mandatory in customerfrontend -  error occurred!.
 - 2015-09-25 Fixed bug#[11196](http://bugs.otrs.org/show_bug.cgi?id=11196) - "Created by" detail missing in PDF print.
 - 2015-09-25 Fixed bug#[11352](http://bugs.otrs.org/show_bug.cgi?id=11352) - Wrong behaviour of AdminCustomerUser::RunInitialWildcardSearch.
 - 2015-09-25 Fixed bug#[11496](http://bugs.otrs.org/show_bug.cgi?id=11496) - Search field shown even if type and service disabled.
 - 2015-09-25 Fixed bug#[11152](http://bugs.otrs.org/show_bug.cgi?id=11152) - Ending of daylight saving time caused system collapse.
 - 2015-09-25 Fixed bug#[11315](http://bugs.otrs.org/show_bug.cgi?id=11315) - subservice not apparent in overview when many services are in the list.
 - 2015-09-25 Fixed bug#[4661](http://bugs.otrs.org/show_bug.cgi?id=4661) - stored searches are lost after changing the username of an agent or customer.
 - 2015-09-25 Fixed bug#[11457](http://bugs.otrs.org/show_bug.cgi?id=11457) - Agent language preference select field is not translated.
 - 2015-09-24 Fixed bug#[11502](http://bugs.otrs.org/show_bug.cgi?id=11502) - DynamicField based ACLs does not work in AgentTicketPhoneCommon.

# 5.0.0.beta5 2015-09-29
 - 2015-09-24 Updated translations, thanks to all translators.
 - 2015-09-23 Added SysConfig settings (Daemon::Log::STDOUT, Daemon::Log::STDERR) to control the redirection of standard streams to log files.
 - 2015-09-23 Added missing SysConfig setting (Daemon::Log::DaysToKeep) to customize the number of days to keep the otrs.Daemon.pl log files, default to 1 day.
 - 2015-09-23 Fixed otrs.Daemon.pl old log files delete, added mechanism to also delete current log files if they have no content.
 - 2015-09-23 Added '--force' option to otrs.Daemon.pl 'stop' action to reduce the time the main daemon waits for its child processes to stop (from 30 secs to 5 secs).
 - 2015-09-23 Added default values for statistic time field selections instead of max/min values.
 - 2015-09-23 Fixed bug#[10530](http://bugs.otrs.org/show_bug.cgi?id=10530) - HTML emails not properly displayed (parts missing).
 - 2015-09-22 Fixed bug#[11495](http://bugs.otrs.org/show_bug.cgi?id=11495) - AdminCustomerUser only shows the first 250 CustomerIDs in dropdown.
 - 2015-09-21 Fixed bug#[11470](http://bugs.otrs.org/show_bug.cgi?id=11470) - AgentPreferences shows "My Services" even when Ticket::Service is disabled.
 - 2015-09-21 Fixed bug#[11481](http://bugs.otrs.org/show_bug.cgi?id=11481) - AutoResponse will be sent altough it is set to invalid.
 - 2015-09-18 Fixed bug#[11441](http://bugs.otrs.org/show_bug.cgi?id=11441) - It is not possible to sort by Owner.
 - 2015-09-18 Added new console command to create customer companies, thanks to babafou.
 - 2015-09-18 Fixed bug#[10878](http://bugs.otrs.org/show_bug.cgi?id=10878) - bulk action for owner change: tickets are not locked.
 - 2015-09-18 Fixed bug#[11283](http://bugs.otrs.org/show_bug.cgi?id=11283) - Cropped upper part of the column filters.
 - 2015-09-18 Fixed bug#[10984](http://bugs.otrs.org/show_bug.cgi?id=10984) - Issues when adding customer users using "Customer user" link.
 - 2015-09-18 Fixed bug#[11112](http://bugs.otrs.org/show_bug.cgi?id=11112) - Number of affected tickets of GenericAgent job via web interface is limited hardcoded.
 - 2015-09-18 Fixed bug#[11307](http://bugs.otrs.org/show_bug.cgi?id=11307) - Reference to uninitialized value at change of sort order of search result in AgentTicketSearch.
 - 2015-09-18 Fixed bug#[11330](http://bugs.otrs.org/show_bug.cgi?id=11330) - LogModule::LogFile::Date creates log files ending in single digit.
 - 2015-09-17 Added the time zone support in the statistics for systems which use UTC as system time and with active TimeZoneUser feature.
 - 2015-09-17 Fixed bug#[11387](http://bugs.otrs.org/show_bug.cgi?id=11387) - TimeZoneUser setting not working within stats.
 - 2015-09-17 Fixed bug#[9744](http://bugs.otrs.org/show_bug.cgi?id=9744) - In 7 Day Stats, stats displayed in GMT.
 - 2015-09-16 Fixed a nasty JSON::XS crash on some platforms.
 - 2015-09-11 Fixed bug#[11462](http://bugs.otrs.org/show_bug.cgi?id=11462) - Article sort order not respected in Print.

# 5.0.0.beta4 2015-09-15
 - 2015-09-09 Updated translations, thanks to all translators.
 - 2015-08-19 Followup for bug#[11367](http://bugs.otrs.org/show_bug.cgi?id=11367) - timezone in time stamps of outgoing mails is always UTC.
 - 2015-09-04 Improved modernized input fields to ignore accents when searching (thanks to Dusan Vuckovic). This will find México when you just search for Mexico.
 - 2015-09-02 Fixed bug#[11437](http://bugs.otrs.org/show_bug.cgi?id=11437) - Filter not available if Y-axis is not defined.
 - 2015-09-02 Fixed bug#[11321](http://bugs.otrs.org/show_bug.cgi?id=11321) - Translate is called twice on Months of Year.
 - 2015-09-01 Fixed bug#[11465](http://bugs.otrs.org/show_bug.cgi?id=11465) - New ticket notifications not working correctly.
 - 2015-08-31 Fixed bug#[11438](http://bugs.otrs.org/show_bug.cgi?id=11438) - Daemon not running.
 - 2015-08-31 Improved otrs.Daemon.pl PID detection mechanism.
 - 2015-08-31 Fixed bug#[11264](http://bugs.otrs.org/show_bug.cgi?id=11264) - Reducing article dropdown dynamic fields via ACL does not work.
 - 2015-08-31 Fixed bug#[11398](http://bugs.otrs.org/show_bug.cgi?id=11398) - Selecting a template in AgentTicketPhone (and likely other components) silently overrides existing content, losing data.
 - 2015-08-31 Fixed bug#[11435](http://bugs.otrs.org/show_bug.cgi?id=11435) - If opening navigation bar or sidebar in responsive mode, OTRS jumps back to the top of the window.
 - 2015-08-31 Fixed bug#[11460](http://bugs.otrs.org/show_bug.cgi?id=11460) - CustomerSearch fails for searches containing '\_'.
 - 2015-08-28 Added the new time scale values 'half-year(s)' and 'quarter(s)' and the possibility to select a upcoming relative time value for the statistic time field.
 - 2015-08-28 Fixed bug#[11450](http://bugs.otrs.org/show_bug.cgi?id=11450) - Modern input fields does not refresh correctly in Ticket Search.
 - 2015-08-28 Fixed bug#[11400](http://bugs.otrs.org/show_bug.cgi?id=11400) - Inconsistency in AgentTicketZoom and AgentTicketCompose.
 - 2015-08-28 Fixed bug#[11309](http://bugs.otrs.org/show_bug.cgi?id=11309) - Bug in Statistic Deletion.
 - 2015-08-28 Fixed bug#[8146](http://bugs.otrs.org/show_bug.cgi?id=8146) - Generate report in Chinese from command line.

# 5.0.0.beta3 2015-09-01
 - 2015-08-25 Followup for bug#[9460](http://bugs.otrs.org/show_bug.cgi?id=9460) - Under some circumstances OTRS does not join Tickets to the Customernumber.
 - 2015-08-25 Fixed search dialog call from navigation bar.
 - 2015-08-25 Added new Galician translation, thanks to ARTURO MONDELO RUIZ-FALCO.
 - 2016-08-24 Changed Scheduler Cron task definition 'Params' attribute: from string to array.
 - 2015-08-21 Fixed bug#[11302](http://bugs.otrs.org/show_bug.cgi?id=11302) - Out of office data incorrect.
 - 2015-08-20 Fixed bug#[11405](http://bugs.otrs.org/show_bug.cgi?id=11405) - AgentTicketForward not possible to hide by ACL.
 - 2015-08-19 Fixed bug#[11440](http://bugs.otrs.org/show_bug.cgi?id=11440) - TransitionAction TicketLockSet typo, thanks to Torsten Thau (c.a.p.e. IT).
 - 2015-08-19 Fixed bug#[11436](http://bugs.otrs.org/show_bug.cgi?id=11436) - Auto response will not generated.
 - 2015-08-19 Followup for bug#[11367](http://bugs.otrs.org/show_bug.cgi?id=11367) - timezone in time stamps of outgoing mails is always UTC.
 - 2015-08-18 Added transition action TicketArticleCreate capability to use current user information, if 'From' attribute is not defined, thanks to Jaroslav Balaz (Mühlbauer).
 - 2015-08-18 Fixed bug#[11279](http://bugs.otrs.org/show_bug.cgi?id=11279) - auto reply with DynamicFields from webservice.
 - 2015-08-18 Fixed bug#[11416](http://bugs.otrs.org/show_bug.cgi?id=11416) - incoming tickets might be assigned to wrong customer due to fuzzy e-mail address matching.
 - 2015-08-17 Added AgentTicketBulk screen capability load plugin modules.
 - 2015-08-13 Added switchable display of sender and recipients (realname or full field incl. email address) in ticket zoom for agent and customer interface.

# 5.0.0.beta2 2015-08-18
 - 2015-08-10 Fixed bug#[11413](http://bugs.otrs.org/show_bug.cgi?id=11413) - Responsible list is not filled in AgentTicketResponsible.
 - 2015-08-10 Added funnel icon to "Filters" button on input fields when the list values is using a filter, thanks to Dusan Vuckovic (Mühlbauer)..
 - 2015-08-10 Added new parameter "ExpandFilters" to Layout::BuildSelection() to show input fields filters list by default when values list is shown, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-10 Fixed bug#[11429](http://bugs.otrs.org/show_bug.cgi?id=11429) - New input fields duplicate values show duplicate names when selected, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-07 Added support to activate filters by default in input fields, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-07 Fixed bug#[11427](http://bugs.otrs.org/show_bug.cgi?id=11427) - Wrong sorting for modernize input fields without a alphanumeric sorting, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-06 Removed external commands execution capability from scheduler daemon Cron tasks.
 - 2015-08-06 Added fetchmail wrapper.
 - 2015-08-05 Added possibility to execute otrs.Console.pl as root.
 - 2015-08-05 Added otrs.postmaster.pl for backwards compatibility.
 - 2015-08-05 Fixed bug#[11419](http://bugs.otrs.org/show_bug.cgi?id=11419) - Selection of multiple values of  Multiselect DynamicFields in AgentTicketPhone is not possible due AJAX refresh, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-04 Fixed bug#[11420](http://bugs.otrs.org/show_bug.cgi?id=11420) - New input fields are wider that expected when they are in the sidebar.
 - 2015-08-04 Fixed bug#[11418](http://bugs.otrs.org/show_bug.cgi?id=11418) - Input fields in AgentTicketEmailOutbound are not consistent with other screens, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-08-03 Followup for bug#[11367](http://bugs.otrs.org/show_bug.cgi?id=11367) - timezone in time stamps of outgoing mails is always UTC.

# 5.0.0.beta1 2015-08-04
 - 2015-07-17 Finished existing outbound element sorting for SOAP transport. Added graphical sorting functionality.
 - 2015-07-16 Added two factor authentication layer and google auth algorithm to agent and customer interface.
 - 2015-07-16 Switched to case insensitive sorting for select fields.
 - 2015-07-16 Modernized input fields, thanks to Dusan Vuckovic (Mühlbauer).
 - 2015-07-15 Added possibility of opening new process ticket screen with a preselected process to CustomerTicketProcess (taken from AgentTicketProcess).
 - 2015-07-13 Added possibility to define a time difference for pending states during ticket create or update, using the  generic ticket connector (GenericInterface), thanks to Frederic Van Espen.
 - 2015-07-13 Updated CPAN module parent to version 0.234.
 - 2015-07-13 Updated CPAN module YAML to version 1.15.
 - 2015-07-13 Updated CPAN module XML::Parser::Lite to version 0.721.
 - 2015-07-13 Updated CPAN module XML::TreePP to version 0.43.
 - 2015-07-13 Updated CPAN module URI to version 1.68.
 - 2015-07-13 Updated CPAN module Text::CSV to version 1.33.
 - 2015-07-13 Updated CPAN module Selenium::Remote::Driver to version 0.26.
 - 2015-07-13 Updated CPAN module SOAP::Lite to version 1.14.
 - 2015-07-13 Updated CPAN module REST::Client to version 272.
 - 2015-07-13 Updated CPAN module Net::IMAP::Simple to version 1.2206.
 - 2015-07-13 Updated CPAN module Net::SSLGlue to version 1.054.
 - 2015-07-13 Updated CPAN module Net::HTTP to version 6.09.
 - 2015-07-13 Updated CPAN module Mozilla::CA to version 20141217.
 - 2015-07-13 Updated CPAN module MailTools to version 2.14.
 - 2015-07-13 Updated CPAN module MIME::Tools to version 5.506.
 - 2015-07-13 Updated CPAN module Locale::Codes to version 3.35.
 - 2015-07-13 Updated CPAN module Linux::Distribution to version 0.23.
 - 2015-07-13 Updated CPAN module libwww-perl to version 6.13.
 - 2015-07-13 Updated CPAN module JavaScript::Minifier to version 1.14.
 - 2015-07-13 Updated CPAN module Excel::Writer::XLSX to version 0.84.
 - 2015-07-13 Updated CPAN module Encode::Locale to version 1.05.
 - 2015-07-13 Updated CPAN module Email::Valid to version 1.196.
 - 2015-07-13 Updated CPAN module Algorithm::Diff to version 1.19_03.
 - 2015-07-10 Updated CPAN module CGI to version 4.21.
 - 2015-07-09 Added support for SOAP requests with chunked Transfer-Encoding, thanks to Frederic Van Espen.
 - 2015-07-09 Added possibility to add or change auto-increment columns during 'TABLE ALTER' SQL statements for PostgreSQL.
 - 2015-07-02 Removed external dependency to PDF::API2 by bundling it. Dropped HTML print view in favor of PDF.
 - 2015-06-30 Added OTRS Scheduler daemon task handlers for: generic agent, cron, and asynchronous executor tasks.
 - 2015-06-30 Ported OTRS Scheduler to the OTRS Daemon architecture.
 - 2015-06-30 Added OTRS Daemon sub-framework.
 - 2015-06-30 Added possibility to execute any method of any object asynchronously Kernel/System/AsynchronousExecutor.
 - 2015-06-30 Increased flexibility for time based generic agent jobs to be executed even each minute.
 - 2015-06-30 Added CronEvent wrapper Kernel/System/CronEvent.
 - 2015-06-29 Redesigned statistics GUI.
 - 2015-06-11 Added possibility to define read only SysConfig settings.
 - 2015-06-11 Added possibility to disable a Date/Time field (created with Layout object BuildDateSelection()).
 - 2015-06-10 Added possibility to show tickets from subqueues in AgenTicketQueue.
   Default on initial view is configurable (show or hide subqueue tickets).
 - 2015-06-08 Updated 7 day stats dashboard widget to use d3 instead of flot and removed flot completely.
 - 2015-06-08 Updated jQuery to 2.1.4; jQuery UI to 1.11.4; FontAwesome to 4.3.0; FullCalendar to 2.3.1, StackTrace to 0.6.4.
 - 2015-06-02 Updated jstree to version 3.1.1.
 - 2015-06-02 Ported all frontend modules to the ObjectManager.
 - 2015-06-01 Added the possibility to extract translation strings directly from Perl code.
 - 2015-05-27 Fixed wrong column types in PostgreSQL.
 - 2015-05-26 Added new function Kernel::System::HTMLUtils::HTMLTruncate(), to trim HTML strings without loosing the tag structure.
 - 2015-05-26 Added possibility to replace some removed tags in Kernel::System::HTMLUtils::Safety() with a custom string.
 - 2015-05-26 Added possibility to remove image tags in Kernel::System::HTMLUtils::Safety().
 - 2015-05-18 Added storable wrapper /Kernel/System/Storable.pm.
 - 2015-05-18 Removed AutoConnectNo feature from DB.pm.
 - 2015-05-18 Added support for Gentoo/emerge in bin/otrs.CheckModules.pl, thanks to Elias Probst.
 - 2015-05-13 Removed support for IE8 and IE9.
 - 2015-05-12 Only show article accounted time if there is a nonzero value, thanks to Paweł Bogusławski.
 - 2015-05-12 Removed support for pre output filters. This can cause bad performance problems and can be replaced by post output filters that render their own templates instead.
 - 2015-05-08 Changed format for all successful messages in customer login screen, thanks to S7.
 - 2015-04-24 Added possibility to create a ticket without article in transition action "TicketCreate".
 - 2015-04-21 Improved performance of ticket merging in bulk action, thanks to Moritz Lenz.
 - 2015-04-21 Added support for multiple mirror databases (failsafe).
 - 2015-04-16 Added possibility to use list of TicketIDs (array reference) as a parameter for TicketSearch().
 - 2015-04-13 Addition to fix of bug#[10712](http://bugs.otrs.org/show_bug.cgi?id=10712) - Incorrect utf8 in ZZZAuto.pm (via SysConfig) also for hash keys.
 - 2015-04-10 Support customer company data in ticket small overviews, thanks to Renée Bäcker.
 - 2015-04-10 Added searching for article flags, thanks to Moritz Lenz.
 - 2015-04-09 Added no match message for administration screens that use filters, thanks to S7.
 - 2015-04-01 Added link from dashboard queue overview to AgentTicketQueue for better usability, thanks to Norihiro Tanaka.
 - 2015-03-31 Fixed bug#[11200](http://bugs.otrs.org/show_bug.cgi?id=11200) - Wrong realization of  Dynamic Fields in SOAP Response.
 - 2015-03-26 Fixed bug#[10978](http://bugs.otrs.org/show_bug.cgi?id=10978) - AgentTicketCompose: Deactivate ArticleTypes isn't possible.
 - 2015-03-24 Added new console interface for a massively improved user and developer experience on the commandline.
 - 2015-03-24 Removed Kernel::System::Crypt layer to use Kernel::System::Crypt::PGP and ::SMIME directly.
 - 2015-03-20 Let LWP::UserAgent handle https-proxy commands, thanks to Michiel Beijen.
 - 2015-03-20 Added possibility to specify minimum log level, thanks to Renée Bäcker.
 - 2015-02-23 Added Ping() to Kernel::System::DB.pm API.
 - 2015-02-06 Fixed bug#[11054](http://bugs.otrs.org/show_bug.cgi?id=11054) - HTMLUtils::Safety breaks links.
 - 2015-02-03 Fixed bug#[11029](http://bugs.otrs.org/show_bug.cgi?id=11029) - Improved wording for responsible to make it more consistent.
 - 2015-01-21 Improved fulltext filters in Ticket::SearchIndex::Filters.
 - 2015-01-15 Show 'add agent' and 'add group' action in UserGroup overview, thanks to ReneeB.
 - 2015-01-09 Improved stopword lists for StaticDB fulltext index to improve perfromance of fulltext searches. It is recommended to rebuild the fulltext search index.
 - 2015-01-08 Added new indices to link_relation table.
 - 2015-01-07 Fixed ticket# 2015010142053495 - Unable to change password in customer interface.
 - 2015-01-06 Added ACLs handling for Owner and Responsible on screen load for AgentTicketOwner and AgentTicketResponsible.

# 4.0.11 2015-08-04
 - 2015-07-13 Fixed bug#[11386](http://bugs.otrs.org/show_bug.cgi?id=11386) - Wrong behavior for the relative period 'the last week(s)' in the stats time field.
 - 2015-07-10 Fixed bug#[11295](http://bugs.otrs.org/show_bug.cgi?id=11295) - 'No such user' notification while otrs automatically responses to client ticket.
 - 2015-07-09 Fixed bug#[11191](http://bugs.otrs.org/show_bug.cgi?id=11191) - Dashboard ticket filter TYPE.
 - 2015-07-09 Fixed syntax error in generated SQL of Kernel::System::Group::GroupGroupMemberList when called with parameter UserIDs.

# 4.0.10 2015-07-14
 - 2015-07-08 Updated translations, thanks to all translators.
 - 2015-07-07 Fixed bug#[11367](http://bugs.otrs.org/show_bug.cgi?id=11367) - timezone in time stamps of outgoing mails is always UTC.
 - 2015-07-03 Fixed bug#[11337](http://bugs.otrs.org/show_bug.cgi?id=11337) - Customer Information Center does not show CustomerUsers.
 - 2015-06-30 Fixed bug#[11325](http://bugs.otrs.org/show_bug.cgi?id=11325) - Dashboard TicketList: Queuefilter in an empty list shows inactive queues, too.

# 4.0.9 2015-06-23
 - 2015-06-22 Fixed bug#[11347](http://bugs.otrs.org/show_bug.cgi?id=11347) - BuildSelection() + TreeView loose selected ID if ARRAY-HASH data is used.
 - 2015-06-19 Added option to package manager list action, to show deployment info of installed packages.
 - 2015-06-17 Updated translations, thanks to all translators.
 - 2015-05-21 Fixed bug#[11287](http://bugs.otrs.org/show_bug.cgi?id=11287) - Scheduler warning links to non-existent module.
 - 2015-05-21 Followup for bug#[10837](http://bugs.otrs.org/show_bug.cgi?id=10837) - Reply in process ticket on webrequest article  fills customer mail into "cc" instead of "to".
 - 2015-05-21 Followup for bug#[11199](http://bugs.otrs.org/show_bug.cgi?id=11199) - GI MappingSinple screen is not consistent.
 - 2015-05-20 Extended the support data collector with an asynchronous mechanism with the possibility to collect data asynchronously (offline).
 - 2015-05-13 Fixed bug#[11290](http://bugs.otrs.org/show_bug.cgi?id=11290) - Lang parameter not correctly validated.
 - 2015-05-11 Fixed bug#[11277](http://bugs.otrs.org/show_bug.cgi?id=11277) - Search for multiple ticket numbers with GenericInterface.

# 4.0.8 2015-05-12
 - 2015-05-15 Fixed bug#[11241](http://bugs.otrs.org/show_bug.cgi?id=11241) - Queue Filter: only the subqueue Name is displayed.
 - 2015-05-06 Updated translations, thanks to all translators.
 - 2015-05-04 Fixed preselecting CustomerID when creating a new customer user from CIC, thanks to Elias Probst.
 - 2015-04-30 Fixed bug#[11102](http://bugs.otrs.org/show_bug.cgi?id=11102) - Refresh bug on process client interface using ie8
 - 2015-04-28 Added new console command to list all installed package files.
 - 2015-04-28 Fixed bug#[11262](http://bugs.otrs.org/show_bug.cgi?id=11262) - AJAX calls keep session alive.
 - 2015-04-27 Added new support data check for prefork MPM.
 - 2015-04-24 Fixed bug#[11246](http://bugs.otrs.org/show_bug.cgi?id=11246) - Information Disclosure on "Outbound E-Mail".
 - 2015-04-24 Fixed bug#[10534](http://bugs.otrs.org/show_bug.cgi?id=10534) - Wildcard hacking the customer information center.
 - 2015-04-24 Fixed bug#[10988](http://bugs.otrs.org/show_bug.cgi?id=10988) - Queues will not be visible in CustomerTicketMessage, if they are using a group which was newly created.
 - 2015-04-23 Fixed bug#[11139](http://bugs.otrs.org/show_bug.cgi?id=11139) - StaticDB - Search incorrect.
 - 2015-04-21 Activated customer company support for the default customer user configuration.
 - 2015-04-20 Fixed bug#[10961](http://bugs.otrs.org/show_bug.cgi?id=10961) - Adding email recipients via addressbook does not update customer information.
 - 2015-04-17 Fixed bug#[11244](http://bugs.otrs.org/show_bug.cgi?id=11244) - Slave database not used in OTRS 4.
 - 2015-04-16 Fixed bug#[11123](http://bugs.otrs.org/show_bug.cgi?id=11123) - DynamicFieldText RegEx message problem on create and edit.
 - 2015-04-14 Fixed bug#[11226](http://bugs.otrs.org/show_bug.cgi?id=11226) - Tags in transition actions work only if there is only a tag in the field.
 - 2015-04-10 Fixed bug#[11237](http://bugs.otrs.org/show_bug.cgi?id=11237) - SpellChecker logs an error if text is empty or '0'.
 - 2015-04-10 Fixed issue with double SessionID parameter in some links.
 - 2015-04-10 Fixed bug#[11167](http://bugs.otrs.org/show_bug.cgi?id=11167) - DashboardEventsTicketCalendar week starting day should be configurable.
 - 2015-04-10 Fixed bug#[11185](http://bugs.otrs.org/show_bug.cgi?id=11185) - Mismatch between shown columns order and default columns order and in DashboardTicketGeneric.
 - 2015-04-10 Fixed bug#[11163](http://bugs.otrs.org/show_bug.cgi?id=11163) - Uninitialized value warning in Excel output in AgentTicketSearch.
 - 2015-04-09 Fixed bug#[11156](http://bugs.otrs.org/show_bug.cgi?id=11156) - No translated headers in Excel output in AgentTicketSearch.
 - 2015-04-09 Fixed bug#[11219](http://bugs.otrs.org/show_bug.cgi?id=11219) - Uninitialized warning in Kernel::Output::HTML::DashboardCalendar.
 - 2015-04-09 Fixed bug#[11232](http://bugs.otrs.org/show_bug.cgi?id=11232) - OTRS does not recognize language "vi" as it only provides "vi_VI".
 - 2015-04-07 Fixed display bug in IE when showing ticket list tables with only one entry (Ticket#2015031842001505).
 - 2015-04-02 Fixed bug#[11161](http://bugs.otrs.org/show_bug.cgi?id=11161) - ticket_history table is always joined in TicketSearch.
 - 2015-04-01 Fixed bug#[11214](http://bugs.otrs.org/show_bug.cgi?id=11214) - Ticket Zoom JS breaks on French language.
 - 2015-03-31 Fixed bug#[11211](http://bugs.otrs.org/show_bug.cgi?id=11211) - REST WADL file does not pass validation tests.
 - 2015-03-30 Fixed bug#[11207](http://bugs.otrs.org/show_bug.cgi?id=11207) - Wrong column encoding in Kernel::System::Notification::NotificationGet().
 - 2015-03-30 Fixed bug#[9449](http://bugs.otrs.org/show_bug.cgi?id=9449) - Generic Agent ticket actions can't be unselect.
 - 2015-03-28 Fixed bug#[11204](http://bugs.otrs.org/show_bug.cgi?id=11204) - SOAP WSDL file does not pass validation tests.
 - 2015-03-27 Fixed bug#[11202](http://bugs.otrs.org/show_bug.cgi?id=11202) - Dashboard errors on only admin group user.
 - 2015-03-27 Fixed bug#[11201](http://bugs.otrs.org/show_bug.cgi?id=11201) - GI: Use of uninitialized value in string ne at AdminGenericInterfaceWebservice.pm.
 - 2015-03-26 Fixed bug#[11199](http://bugs.otrs.org/show_bug.cgi?id=11199) - GI MappingSinple screen is not consistent.
 - 2015-03-26 Fixed bug#[10837](http://bugs.otrs.org/show_bug.cgi?id=10837) - Reply in process ticket on webrequest article  fills customer mail into "cc" instead of "to".
 - 2015-03-26 Improved ServiceList() cache, tanks to Norihiro Tanaka.
 - 2015-03-26 Fixed bug#[11117](http://bugs.otrs.org/show_bug.cgi?id=11117) - AutoResponse messages not "comply" Customer Language.
 - 2015-03-26 Fixed bug#[10995](http://bugs.otrs.org/show_bug.cgi?id=10995) - Characters not correctly managed by OTRS scripts..

# 4.0.7 2015-03-31
 - 2015-03-25 Updated translations, thanks to all translators.
 - 2015-03-24 Fixed bug#[11189](http://bugs.otrs.org/show_bug.cgi?id=11189) - Go to Dashboard link in No Permissions screen is broken.
 - 2015-03-23 Fixed bug#[11194](http://bugs.otrs.org/show_bug.cgi?id=11194) - Download button for dashboard stats visible even if no permissions for AgentStats exist..
 - 2015-03-23 Fixed bug#[11104](http://bugs.otrs.org/show_bug.cgi?id=11104) - Invalid utf-8 parameters not filtered sufficciently.
 - 2015-03-20 Fixed bug#[11072](http://bugs.otrs.org/show_bug.cgi?id=11072) - DynamicField Filter in AgentDashboard accepts only one value.
 - 2015-03-20 Fixed bug#[10702](http://bugs.otrs.org/show_bug.cgi?id=10702) - Can't select customer and/or public interface in AdminACL.
 - 2015-03-20 Fixed bug#[11178](http://bugs.otrs.org/show_bug.cgi?id=11178) - Undefined variable warning with "Reply to note" in AgentTicketZoom.
 - 2015-03-20 Fixed bug#[11188](http://bugs.otrs.org/show_bug.cgi?id=11188) - SOAP WSDL TicketGet response is incomplete.
 - 2015-03-20 Fixed bug#[10816](http://bugs.otrs.org/show_bug.cgi?id=10816) - apache2 with mod_deflate enabled will not start.
 - 2015-03-19 Fixed bug#[11181](http://bugs.otrs.org/show_bug.cgi?id=11181) - outputfilters pre not matching on includes.
 - 2015-03-13 Fixed bug#[11119](http://bugs.otrs.org/show_bug.cgi?id=11119) - Activity Dialog can't be hidden if ACL features Action condition in CustomerTicketZoom.
 - 2015-03-13 Fixed bug#[11136](http://bugs.otrs.org/show_bug.cgi?id=11136) - uninitialized value $RealName NotificationEvent.pm line 717.
 - 2015-03-13 Fixed bug#[11106](http://bugs.otrs.org/show_bug.cgi?id=11106) - Owner type is ignored if set previous owner to blanc in AgentTicketOwner.
 - 2015-03-06 Fixed bug#[11084](http://bugs.otrs.org/show_bug.cgi?id=11142) - Transition do not store more than one criteria in a condition.
 - 2015-03-06 Fixed bug#[11142](http://bugs.otrs.org/show_bug.cgi?id=11142) - At times, undefined variable warning in agent interface.
 - 2015-03-06 Fixed bug#[11147](http://bugs.otrs.org/show_bug.cgi?id=11147) - SLA can not be set over Free Fields Dialog.
 - 2015-03-06 Fixed bug#[11113](http://bugs.otrs.org/show_bug.cgi?id=11113) - Internal server error at importing with IMAP.
 - 2015-03-06 Fixed bug#[11135](http://bugs.otrs.org/show_bug.cgi?id=11135) - Use of uninitialized value warning in CustomerCompanyList.
 - 2015-03-05 MySQL: Added check for innodb_log_file_size setting to both the installer and the support data collector in order to make sure it matches the minimum requirements.
 - 2015-03-04 Fixed bug#[11097](http://bugs.otrs.org/show_bug.cgi?id=11097) - Generic Agent - Event Delete Icon disappear.
 - 2015-03-04 Fixed bug#[11137](http://bugs.otrs.org/show_bug.cgi?id=11137) - Installer fails on Oracle.
 - 2015-03-03 Fixed bug#[11133](http://bugs.otrs.org/show_bug.cgi?id=11133) - Not possible to change customer.
 - 2015-03-03 Fixed bug#[11115](http://bugs.otrs.org/show_bug.cgi?id=11115) - Error from GenericInterface using SOAP and TicketGet operation.
 - 2015-03-03 Fixed bug#[11134](http://bugs.otrs.org/show_bug.cgi?id=11134) - TicketAccountedTime dynamic field restriction does not work anymore.
 - 2015-03-03 Fixed bug#[11088](http://bugs.otrs.org/show_bug.cgi?id=11088) - <OTRS_...> placeholders in mailto-links don't get replaced, thanks to Thorsten Eckel.
 - 2015-03-02 Fixed wrong header in customer login.
 - 2015-03-02 Fixed bug#[11120](http://bugs.otrs.org/show_bug.cgi?id=11120) - Logged invalid message at login failure, thanks to Norihiro Tanaka.
 - 2015-03-02 Fixed bug#[11128](http://bugs.otrs.org/show_bug.cgi?id=11128) - Uninitialized variable warning in dashboard after addition of new dynamic field, thanks to Norihiro Tanaka.
 - 2015-02-27 Fixed bug#[11065](http://bugs.otrs.org/show_bug.cgi?id=11065) - Transitions based in DynamicFields Multi-Select does not work.
 - 2015-02-27 Make sure article data is escaped properly in timeline view.
 - 2015-02-25 Fixed bug#[10820](http://bugs.otrs.org/show_bug.cgi?id=10820) - memory cache does not get updated.
 - 2015-02-23 Improved performance on Article Attachment read from Database.
 - 2015-02-20 Allow multiline chat feeds; reduced chat request polling frequency.
 - 2015-02-23 Improved automated scrolling of article table in TicketZoom, if a new active article is not completely visible in the article table.

# 4.0.6 2015-02-24
 - 2015-02-18 Updated translations, thanks to all translators.
 - 2015-02-13 Fixed bug#[11038](http://bugs.otrs.org/show_bug.cgi?id=11038) - Notification is not sent.
 - 2015-02-13 Added otrs.CheckCloudServices.pl script to help to diagnose cloud services connection problems.
 - 2015-02-09 Fixed bug#[10905](http://bugs.otrs.org/show_bug.cgi?id=10905) - ArticleContent with Inline-Images are not shown completely.
 - 2015-02-09 Fixed bug for IE8 - Handle jQuery selectors correctly (Ticket#2014120242045831).
 - 2015-02-06 Fixed bug#[10942](http://bugs.otrs.org/show_bug.cgi?id=10942) - Adressbook search does not permit to add contacts via click.
 - 2015-02-06 Fixed bug#[11011](http://bugs.otrs.org/show_bug.cgi?id=11011) - OTRS does not honor customer change.
 - 2015-02-03 Fixed bug#[10902](http://bugs.otrs.org/show_bug.cgi?id=10902) - Missing translations on login screen.
 - 2015-02-03 Fixed bug#[11047](http://bugs.otrs.org/show_bug.cgi?id=11047) - Missing translation when updating password.
 - 2015-02-03 Fixed bug#[11050](http://bugs.otrs.org/show_bug.cgi?id=11050) - Wrong sortation of Ticket Overview settings.
 - 2015-02-03 Fixed bug#[10955](http://bugs.otrs.org/show_bug.cgi?id=10955) - Missing translations in Dashboard and TicketOverview settings.
 - 2015-01-29 Fixed bug#[10968](http://bugs.otrs.org/show_bug.cgi?id=10968) - Dashlet: Filter Attributes with more then one CustomerID doesn't work.
 - 2015-01-28 Fixed bug#[11033](http://bugs.otrs.org/show_bug.cgi?id=11033) - Wrong webservice update confirmation text.
 - 2015-01-28 Fixed bug#[11023](http://bugs.otrs.org/show_bug.cgi?id=11023) - SQL error with "0 oracle" for article body in Ticket Search.
 - 2015-01-27 Fixed bug#[11037](http://bugs.otrs.org/show_bug.cgi?id=11037) - TranstionAction smart thats should support <OTRS_TICKET_*> instead of <OTRS_Ticket_*>.
 - 2015-01-27 Added OTRS Business Solution™ dynamic fields removal on downgrade to OTRS Free.
 - 2015-01-27 Added DB consistency checks to the deployment check for the OTRS Business Solution™.
 - 2015-01-27 Fixed bug#[10198](http://bugs.otrs.org/show_bug.cgi?id=10198) - ORA-1795 occurrs, if a lot of tickets are selected at Column Filter in TicketOverviwSmall.
 - 2015-01-26 Fixed bug#[11034](http://bugs.otrs.org/show_bug.cgi?id=11034) - generic interface invoker event delete and add bug.
 - 2015-01-24 Fixed bug#[11018](http://bugs.otrs.org/show_bug.cgi?id=11018) - Internal Server Error, instead of warning.
 - 2015-01-24 Improved migration script to be tolerant on missing ProcessManagement Transition Actions.
 - 2015-01-22 Fixed bug#[11021](http://bugs.otrs.org/show_bug.cgi?id=11021) - ProcessManagement: TransitionAction delete does not check if is used.
 - 2015-01-22 Fixed bug#[11019](http://bugs.otrs.org/show_bug.cgi?id=11019) - ACLs for hiding Processes are not working anymore in 4.0.
 - 2015-01-20 Updated translations, thanks to all translators.
 - 2015-01-20 Message about opening external links from articles is now removable.
 - 2015-01-20 Removed buttons for System Registration if System Registration is disabled.
 - 2015-01-19 Fixed bug#[10980](http://bugs.otrs.org/show_bug.cgi?id=10980) - InterfaceCustomer.pm has no translation.

# 4.0.5 2015-01-20
 - 2015-01-14 Updated translations, thanks to all translators.
 - 2015-01-12 Fixed bug#[10992](http://bugs.otrs.org/show_bug.cgi?id=10992) - "Delete Filter" unsets general navigation selection in overviews.
 - 2015-01-09 Fixed bug#[9856](http://bugs.otrs.org/show_bug.cgi?id=9856) - gpg option 0xlong breaks decryption of emails.
 - 2015-01-09 Fixed bug#[10492](http://bugs.otrs.org/show_bug.cgi?id=10492) - ORA-03113 Error after scheduler start.
 - 2015-01-08 Fixed bug#[10884](http://bugs.otrs.org/show_bug.cgi?id=10884) - /etc/init.d/otrs running httpd is not detected on CentOS 7.

# 4.0.4 2015-01-13
 - 2015-01-08 Updated translations, thanks to all translators.
 - 2015-01-06 Fixed bug#[10967](http://bugs.otrs.org/show_bug.cgi?id=10967) - Error 500 instead of showing a finished process.
 - 2015-01-06 Fixed bug#[10972](http://bugs.otrs.org/show_bug.cgi?id=10972) - AgentTicketProcess - Form not loading when RichText Editor is turned off.
 - 2015-01-05 Fixed bug#[10895](http://bugs.otrs.org/show_bug.cgi?id=10895) - Dynamic Field shown information in customer interface is not consistent with agent interface.
 - 2015-01-05 Fixed bug#[10898](http://bugs.otrs.org/show_bug.cgi?id=10898) - Reply to note does not select the origin note sender.
 - 2014-12-22 Fixed bug#[10551](http://bugs.otrs.org/show_bug.cgi?id=10551) - Error: No Process configured! - Agent interface.
 - 2014-12-18 Added Invoker name requirement in Generic Interface Invoker constructor.
 - 2014-12-18 Fixed bug#[10954](http://bugs.otrs.org/show_bug.cgi?id=10954) - Column title disappear  in list for CustumerCompany.
 - 2014-12-18 Fixed bug#[10934](http://bugs.otrs.org/show_bug.cgi?id=10934) - Error while splitting ticket.
 - 2014-12-18 Fixed bug#[10945](http://bugs.otrs.org/show_bug.cgi?id=10945) - Invalid CustomerCompanys are not marked invalid in CIC.
 - 2014-12-18 Fixed bug#[10802](http://bugs.otrs.org/show_bug.cgi?id=10802) - Ticket Count in Dashboard Widget  with set Filter.
 - 2014-12-17 Fixed bug#[10572](http://bugs.otrs.org/show_bug.cgi?id=10572) - ActivityDialogEntityID not working in ACLs from Process screens reducing States.
 - 2014-12-16 Fixed bug#[10574](http://bugs.otrs.org/show_bug.cgi?id=10574) - DropDown "Crypt" is to large.
 - 2014-12-16 Fixed bug#[10957](http://bugs.otrs.org/show_bug.cgi?id=10957) - Low "Max" attribute from Layout BuildSelection breaks execution.
 - 2014-12-15 Fixed bug#[10941](http://bugs.otrs.org/show_bug.cgi?id=10941) - Process activity names not correctly displayed in process information widget.
 - 2014-12-12 Followup for bug#[10724](http://bugs.otrs.org/show_bug.cgi?id=10724) - Sorting of DynamicField object types based on its Prio does not work.
 - 2014-12-12 Fixed bug#[10948](http://bugs.otrs.org/show_bug.cgi?id=10948) - CloseParentAfterClosedChilds ACL does not work anymore.

# 4.0.3 2014-12-16
 - 2014-12-11 Updated translations, thanks to all translators.
 - 2014-12-11 Fixed bug#[10935](http://bugs.otrs.org/show_bug.cgi?id=10935) - "bin/otrs.ArticleStorageSwitch.pl" not working any more.
 - 2014-12-10 Fixed bug#[10868](http://bugs.otrs.org/show_bug.cgi?id=10868) - Impossible to remove filter in dashboard-block when no tickets are found.
 - 2014-12-10 Fixed bug#[10904](http://bugs.otrs.org/show_bug.cgi?id=10904) - Upon entering CIC, search only returns hits during the first search.
 - 2014-12-10 Fixed bug#[10873](http://bugs.otrs.org/show_bug.cgi?id=10873) - Agent names sorted incorrectly in AgentTicketSearch.
 - 2014-12-10 Fixed bug#[10944](http://bugs.otrs.org/show_bug.cgi?id=10944) - Multiple selection in Tree Selection also affects filtered elements.
 - 2014-12-09 Follow-up fix for bug#[6284](http://bugs.otrs.org/show_bug.cgi?id=6284) - Problem with unicode characters when using FastCGI.
 - 2014-12-09 Fixed bug#[10899](http://bugs.otrs.org/show_bug.cgi?id=10899) - SplitQuote in WYSIWYG editor creates unnecessary empty quote line when splitting quote at end of line.
 - 2014-12-08 Fixed bug#[10830](http://bugs.otrs.org/show_bug.cgi?id=10830) - Textarea Limitation in Generic Agent.
 - 2014-12-08 Fixed bug#[10914](http://bugs.otrs.org/show_bug.cgi?id=10914) - Migration issue to 4.0.1 (mssql).
 - 2014-12-08 Fixed bug#[10920](http://bugs.otrs.org/show_bug.cgi?id=10920) - ProcessManagement: Deleting Activities from canvas does not update process layout.
 - 2014-12-08 Fixed bug#[10801](http://bugs.otrs.org/show_bug.cgi?id=10801) - Editor is extremely slow with large articles.
 - 2014-12-05 Re-added possibility to have a custom RSS feed in Agent Dashboard.
 - 2014-12-05 Enhanced Permission Checks in GenericInterface Ticket Connector.
 - 2014-12-05 Fixed bug#[10926](http://bugs.otrs.org/show_bug.cgi?id=10926) - Missing Apache2::Reload.pm.
 - 2014-12-05 Follow-up for bug#[10613](http://bugs.otrs.org/show_bug.cgi?id=10613) - Fixed the problem with calling TicketGet() twice.
 - 2014-12-05 Fixed bug#[10922](http://bugs.otrs.org/show_bug.cgi?id=10922) - There is no automatic wildcard search in AdminCustomerCompany by default.
 - 2014-12-05 Fixed bug#[10929](http://bugs.otrs.org/show_bug.cgi?id=10929) - Twice rewrap body in CustomerTicketZoom.
 - 2014-12-05 Show only services assigned to the customer user in customer ticket search (configurable).
 - 2014-12-05 Fixed bug#[10932](http://bugs.otrs.org/show_bug.cgi?id=10932) - JS error if no entry in queue list.
 - 2014-12-04 Fixed bug#[10634](http://bugs.otrs.org/show_bug.cgi?id=10634) - ProcessManagement: Can not use an arbitrary email address as a CustomerUser.
 - 2014-12-04 Fixed bug#[10901](http://bugs.otrs.org/show_bug.cgi?id=10901) - Database Update to 4.pl.
 - 2014-12-04 Removed incorrect notice about SQL query length. (#d0bd52b)
 - 2014-12-03 Improved the AdminRegistration frontend for systems without a running scheduler.
 - 2014-12-03 Improved stability of RegistrationUpdate handling.
 - 2014-12-02 Fixed bug#[10917](http://bugs.otrs.org/show_bug.cgi?id=10917) - Wrong messages for password reset.
 - 2014-12-02 Fixed bug#[10916](http://bugs.otrs.org/show_bug.cgi?id=10916) - Missing values AgentTicketEscalation / Localize function call does not work.
 - 2014-11-28 Fixed bug#[10897](http://bugs.otrs.org/show_bug.cgi?id=10897) - PDFs don't open in browser.
 - 2014-11-28 Fixed bug#[10839](http://bugs.otrs.org/show_bug.cgi?id=10839) - ACL cannot set possible TicketType in AgentTicketPhone and AgentTicketEmail.
 - 2014-11-28 Fixed bug#[10776](http://bugs.otrs.org/show_bug.cgi?id=10776) - Medium and Large view don't indicate active filters.
 - 2014-11-28 Fixed bug#[10808](http://bugs.otrs.org/show_bug.cgi?id=10808) - Set of pending time is not working at all in Frontend::Agent::Ticket::ViewNote.
 - 2014-11-28 Fixed bug#[10843](http://bugs.otrs.org/show_bug.cgi?id=10843) - Adding Queue's with same name in AdminQueue leads to SQL error message.

# 4.0.2 2014-12-02
 - 2014-11-27 Updated translations, thanks to all translators.
 - 2014-11-27 Fixed bug#[10906](http://bugs.otrs.org/show_bug.cgi?id=10906) - SysConfig settings are mistakenly reset.
 - 2014-11-25 Added overview of data that is transferred to cloud.otrs.com. Only call BusinessPermissionCheck for registered systems.
 - 2014-11-24 Fixed bug#[10892](http://bugs.otrs.org/show_bug.cgi?id=10892) - TicketActionsPerTicket open multiple popups at TicketOverview.
 - 2014-11-24 Fixed bug#[10857](http://bugs.otrs.org/show_bug.cgi?id=10857) - JS added too often in AgentTicketOverviewSmall.
 - 2014-11-24 Fixed bug#[10639](http://bugs.otrs.org/show_bug.cgi?id=10639) - Set of pending time/state not working properly (process management).
 - 2014-11-23 Fixed bug#[10893](http://bugs.otrs.org/show_bug.cgi?id=10893) - Missing log name partitions in Service Center.

# 4.0.1 2014-11-25
 - 2014-11-21 Added possibility to turn of SSL certificate validation.
 - 2014-11-20 Updated translations, thanks to all translators.
 - 2014-11-18 Fixed bug#[10879](http://bugs.otrs.org/show_bug.cgi?id=10879) - GenericInterfae: TicketSearch operation does not take escalation parameters.
 - 2014-11-18 Fixed bug#[10812](http://bugs.otrs.org/show_bug.cgi?id=10812) - SOAP Response is always in version SOAP 1.2.
 - 2014-11-18 Fixed bug#[10083](http://bugs.otrs.org/show_bug.cgi?id=10083) - SMIME and Email address detection is case sensitive (for the right part)..
 - 2014-11-18 Fixed bug#[10841](http://bugs.otrs.org/show_bug.cgi?id=10841) - ORA-00932 in DBUpdate-to-4.pl.
 - 2014-11-18 Fixed bug#[10872](http://bugs.otrs.org/show_bug.cgi?id=10872) - Dynamic field regular expressions don't work.
 - 2014-11-18 Fixed bug#[10712](http://bugs.otrs.org/show_bug.cgi?id=10712) - Incorrect utf8 in ZZZAuto.pm (via SysConfig).
 - 2014-11-18 Fixed bug#[10826](http://bugs.otrs.org/show_bug.cgi?id=10826) - German - Translation Problem.
 - 2014-11-18 Fixed bug#[10506](http://bugs.otrs.org/show_bug.cgi?id=10506) - Title mouse over text is truncated.
 - 2014-11-18 Fixed bug#[10678](http://bugs.otrs.org/show_bug.cgi?id=10678) - Dates off by one on area diagram in dashboard widget.
 - 2014-11-18 Added new Swahili language translation, thanks to all translators.

# 4.0.0.rc1 2014-11-18
 - 2014-10-30 Updated translation files, thanks to all translators.
 - 2014-11-12 Fixed bug#[10866](http://bugs.otrs.org/show_bug.cgi?id=10866) - Wrong default article shown in AgentTicketZoom.
 - 2014-11-11 Fixed bug#[7369](http://bugs.otrs.org/show_bug.cgi?id=7369) - LinkQoute fails for some characters in hash or parameter.
 - 2014-11-11 Fixed bug#[8404](http://bugs.otrs.org/show_bug.cgi?id=8404) - Wrong sorting of responses dropdown in TicketZoom.
 - 2014-11-11 Fixed bug#[8781](http://bugs.otrs.org/show_bug.cgi?id=8781) - 508 Compliance: In Ticket Overviews the title attribute of large view link is incorrect.
 - 2014-11-10 Fixed bug#[10669](http://bugs.otrs.org/show_bug.cgi?id=10669) - Maxlength validation of textarea dynamic fields does not work correctly in IE.
 - 2014-11-10 Fixed bug#[10471](http://bugs.otrs.org/show_bug.cgi?id=10471) - Missing translations for tooltips of TicketOverviewSmall columns.
 - 2014-11-10 Fixed bug#[10850](http://bugs.otrs.org/show_bug.cgi?id=10850) - Double-quoted special characters in title of dynamic field sidebar output in TicketZoom.
 - 2014-11-07 Fixed bug#[10856](http://bugs.otrs.org/show_bug.cgi?id=10856) - TicketHistoryGet() dynamic field values.
 - 2014-11-07 Fixed bug#[10805](http://bugs.otrs.org/show_bug.cgi?id=10805) - Open tickets in 3 days show right function but wrong number.
 - 2014-11-04 Added the possibility to define a sleeptime to a lot of .pl scripts.
 - 2014-11-04 Fixed bug#[10838](http://bugs.otrs.org/show_bug.cgi?id=10838) - Adding types with same name in AdminType leads to SQL error message.
 - 2014-11-03 Fixed bug#[10799](http://bugs.otrs.org/show_bug.cgi?id=10799) - AgentTicketFreeText displays Service on top of queue.
 - 2014-11-03 Fixed bug#[10842](http://bugs.otrs.org/show_bug.cgi?id=10842) - Customers missing when searching..
 - 2014-11-03 Fixed bug#[10706](http://bugs.otrs.org/show_bug.cgi?id=10706) - dashboard settings are lost by different user login.
 - 2014-11-03 Fixed bug#[10786](http://bugs.otrs.org/show_bug.cgi?id=10786) - TimeZoneUserBrowserAutoOffset not working with SSO.
 - 2014-11-03 Fixed bug#[10613](http://bugs.otrs.org/show_bug.cgi?id=10613) - Tickets can be selected for bulk, even if locked.
 - 2014-10-31 Fixed bug#[10577](http://bugs.otrs.org/show_bug.cgi?id=10577) - Service Center does not show MOD_PERL version on Ubuntu 14.04.
 - 2014-10-30 Fixed bug#[10679](http://bugs.otrs.org/show_bug.cgi?id=10679) - Texts in notification tags loose their empty lines and spaces.

# 4.0.0.beta5 2014-11-04
 - 2014-10-30 Updated translation files, thanks to all translators.
 - 2014-10-30 Fixed bug#[10656](http://bugs.otrs.org/show_bug.cgi?id=10656) - Generated CSV file cannot display Chinese characters in MS Excel.
 - 2014-10-28 Added Excel export as an alternative to CSV export.
 - 2014-10-28 Added calendar specific weekday start options for date picker.
 - 2014-10-28 Fixed bug#[8460](http://bugs.otrs.org/show_bug.cgi?id=8460) - Smart tag <OTRS_CUSTOMER_EMAIL[]> is display with HTML coding tags.
 - 2014-10-28 Added a small delay for opening the submenus of the main navigation when OpenMainMenuOnHover is enabled.
 - 2014-10-28 Reimplemented otrs.SetPermissions.pl. It is now much faster and has a --skip-article-dir option.
 - 2014-10-27 Updated SupportDataBundle email address.
 - 2014-10-27 Fixed bug#[10587](http://bugs.otrs.org/show_bug.cgi?id=10587) - Find.pm "Can't cd to .." error in DynamicField subdirectories.
 - 2014-10-23 Fixed bug#[10665](http://bugs.otrs.org/show_bug.cgi?id=10665) - Backup script should delete incomplete backups.
 - 2014-10-23 Added possibility to search for 'NotTicketFlags', thanks to Moritz Lenz.
 - 2014-10-23 Added the possibility to define a custom logo per skin. Fallback will be still AgentLogo.
 - 2014-10-22 Fixed bug#[10828](http://bugs.otrs.org/show_bug.cgi?id=10828) - MyServices select misbehaves on empty values.
 - 2014-10-22 Fixed bug#[10820](http://bugs.otrs.org/show_bug.cgi?id=10820) - memory cache does not get updated.
 - 2014-10-21 Improved IndexAccelerator SQL to use proper JOINs, thanks to Moritz Lenz.
 - 2014-10-20 Fixed bug#[5252](http://bugs.otrs.org/show_bug.cgi?id=5252) - For pending- and escalation-notification only the standard calendar is used.
 - 2014-10-20 Fixed bug#[10041](http://bugs.otrs.org/show_bug.cgi?id=10041) - Queue Based Calendars not shown only the standard calendar is used.
 - 2014-10-17 Fixed bug#[10817](http://bugs.otrs.org/show_bug.cgi?id=10817) - generic agent ticket date filter 'year' one year has 365 instead of 356.
 - 2014-10-17 Fixed bug#[10813](http://bugs.otrs.org/show_bug.cgi?id=10813) - GenericInterface event handler only listens to ticket events.
 - 2014-10-17 Fixed bug#[10810](http://bugs.otrs.org/show_bug.cgi?id=10810) - Reference of uninitialized value at login.

# 4.0.0.beta4 2014-10-21
 - 2014-10-16 Updated translations, thanks to all translators.
 - 2014-10-16 Fixed bug#[10631](http://bugs.otrs.org/show_bug.cgi?id=10631) - Search attribute are unordered.
 - 2014-10-16 Added new screen for outgoing emails on a ticket that are not replies.
 - 2014-10-16 Follow-up fix for bug#10644. Make sure that params get passed to any modules used. Make tests more robust.
 - 2014-10-14 Added flat design skin for the customer interface.
 - 2014-10-14 Fixed bug#[10728](http://bugs.otrs.org/show_bug.cgi?id=10728) - Removing watcher does not work on ticket merge.
 - 2014-10-14 Fixed bug#[10750](http://bugs.otrs.org/show_bug.cgi?id=10750) - Strange tree view in complex tree of queues.
 - 2014-10-14 Fixed bug#[10790](http://bugs.otrs.org/show_bug.cgi?id=10790) - Editing fields in Activity Dialogs not possible in IE8.
 - 2014-10-14 Fixed bug#[10725](http://bugs.otrs.org/show_bug.cgi?id=10725) - Translation affects suggested article type.
 - 2014-10-14 Improved email address validity check to conform to RFC 5321, thanks to gitbensons.
 - 2014-10-14 Added cache benchmark script, thanks to ib.pl.
 - 2014-10-14 Fixed bug#10579 - Error with &-sign in an eMail address.
 - 2014-10-14 Fixed bug#[10621](http://bugs.otrs.org/show_bug.cgi?id=10621) - Queues are false sorted in Ticket Zoom select box.
 - 2014-10-13 Changed default skin for CKEditor to bootstrapck, http://ckeditor.com/addon/bootstrapck.
 - 2014-10-07 Fixed support data collection hangs in some mod_perl environments.
 - 2014-10-07 Added the possibility to restrict customer self registration by email address whitelist or blacklist.
 - 2014-10-07 Fixed customer account creation message.
 - 2014-10-07 Added new dashboard module that shows the output of an external command, thanks to ib.pl.

# 4.0.0.beta3 2014-10-07
 - 2014-09-29 Fixed bug#[10588](http://bugs.otrs.org/show_bug.cgi?id=10588) - Search profile names with special characters break functionality.
 - 2014-09-26 Added functionality to search for the last change time of the ticket (TicketLastChangeTimeOlderMinutes, TicketLastChangeTimeNewerMinutes, TicketLastChangeTimeNewerDate, TicketLastChangeTimeOlderDate).
 - 2014-09-25 Readded AgentZoom.pm to fix compatibility problems of older systems.
 - 2014-09-23 Fixed bug#[10759](http://bugs.otrs.org/show_bug.cgi?id=10759) - Migrate ProcessManagement EntityIDs can't use string error.
 - 2014-09-23 Fixed bug#[10758](http://bugs.otrs.org/show_bug.cgi?id=10758) - isn't numeric in numeric eq (==) error on Article.pm.
 - 2014-09-22 Fixed bug#[10749](http://bugs.otrs.org/show_bug.cgi?id=10749) - generic agent limitted by notifications for escalations.
 - 2014-09-22 Fixed bug#[10460](http://bugs.otrs.org/show_bug.cgi?id=10460) - Namespace error in Internet Explorer Compatibility Mode.
 - 2014-09-22 Fixed bug#[8290](http://bugs.otrs.org/show_bug.cgi?id=8290) - Browser Detection is skipped when using Single Sign On.
 - 2014-09-22 Fixed bug of new navigation sorting in IE8.

# 4.0.0.beta2 2014-09-23
 - 2014-09-18 Added possibility to disable sysconfig import via configuration.
 - 2014-09-17 Fixed bug#[10736](http://bugs.otrs.org/show_bug.cgi?id=10736) - Wrong update behavior for the proccess change time by the scheduler, when a time zone is used.
 - 2014-09-16 Updated translations, thanks to all translators.
 - 2014-09-15 Added dependency check for Perl module Time::Piece.
 - 2014-09-12 Fixed bug#[10724](http://bugs.otrs.org/show_bug.cgi?id=10724) - Sorting of DynamicField object types based on its Prio does not work.
 - 2014-09-12 Added Apache MD5 as a new password hashing backend, thanks to Norihiro Tanaka.
 - 2014-09-12 Make KeepChildren in service lists configurable, thanks to Peter Krall.
 - 2014-09-12 Fixed bug#[5189](http://bugs.otrs.org/show_bug.cgi?id=5189) - Queue name not updated in QueueView after rename for StaticDB.
 - 2014-09-12 Fixed bug#[10718](http://bugs.otrs.org/show_bug.cgi?id=10718) - Typo in $HOME/Kernel/System/Ticket/Article.pm.
 - 2014-09-12 Fixed bug#[10582](http://bugs.otrs.org/show_bug.cgi?id=10582) - Adding templates with same name in AdminTemplate leads to SQL error message.
 - 2014-09-10 Fixed bug#[8008](http://bugs.otrs.org/show_bug.cgi?id=8008) - Session ID should not be visible in the address bar after logging in if cookies are used.
 - 2014-09-10 Fixed bug#[10717](http://bugs.otrs.org/show_bug.cgi?id=10717) - Incomplete error message creating CryptObject.
 - 2014-09-09 Fixed bug#[10715](http://bugs.otrs.org/show_bug.cgi?id=10715) - Wrong object name in CloseParentAfterClosedChilds.pm.
 - 2014-09-09 Fixed bug#[10714](http://bugs.otrs.org/show_bug.cgi?id=10714) - Wrong Object call in TicketUpdate Operation.
 - 3024-09-09 Followup fix for bug#[9418](http://bugs.otrs.org/show_bug.cgi?id=9418) - Incorrect decoding email subject and From token
 - 2014-09-04 Fixed bug#[10708](http://bugs.otrs.org/show_bug.cgi?id=10708) - ProcessManagement: ActivityDialog Description short and long are not displaying.

# 4.0.0.beta1 2014-09-09
 - 2014-09-03 Fixed bug#[10208](http://bugs.otrs.org/show_bug.cgi?id=10208) - Added additional checks to see if something has changed and invalidates a spell check which had already been done, thanks to S7.
 - 2014-08-25 Added task type icon to activities, thanks to Nils Leideck.
 - 2014-08-29 Fixed bug#[10128](http://bugs.otrs.org/show_bug.cgi?id=10128) - WorkingTime/DestinationTime roundtrip exposes calculation errors.
 - 2014-08-25 Updated CPAN module YAML to version 1.09.
 - 2014-08-25 Updated CPAN module URI to version 1.64.
 - 2014-08-25 Updated CPAN module Net::SSLGlue to version 1.053.
 - 2014-08-25 Updated CPAN module Net::IMAP::Simple to version 1.2205.
 - 2014-08-25 Updated CPAN module Net::HTTP to version 6.07.
 - 2014-08-25 Updated CPAN module Locale::Codes to version 3.31.
 - 2014-08-25 Updated CPAN module LWP::Protocol::https to version 6.06.
 - 2014-08-25 Updated CPAN module LWP to version 6.08.
 - 2014-08-25 Updated CPAN module Email::Valid to version 1.194.
 - 2014-08-25 Updated CPAN module CGI::Emulate::PSGI to version 0.18.
 - 2014-08-25 Updated CPAN module CGI::Fast to version 2.02.
 - 2014-08-25 Updated CPAN module CGI to version 4.03.
 - 2014-08-18 Added Attachment Name option in ticket search screens.
 - 2014-08-18 Added ProcessManagement Dashboard widget (for valid running process tickets).
 - 2014-08-18 Fixed bug#[10682](http://bugs.otrs.org/show_bug.cgi?id=10682) - Customers are able to search in non customer articles.
 - 2014-08-15 Moved Scheduler backend files from Kernel/Scheduler to Kernel/System/Scheduler.
 - 2014-08-07 Removed possibility to start scheduler from GUI.
 - 2014-08-07 Added possibility to use Date and Date/Time dynamic fields as restrictions in statistics.
 - 2014-08-07 Removed AgentZoom.pm.
 - 2014-08-04 Removed CacheInternal.pm. Caching is now done with the global Cache object stored in the ObjectManager, which also does in-memory caching.
 - 2014-07-25 Added possibility to use process ticket information as dynamic values for transition actions.
 - 2014-07-25 Added new Process Management transition action to create a new ticket.
 - 2014-07-25 Added possibility to enroll existing tickets into a process.
 - 2014-07-25 Added new Process Management transition debugging options.
 - 2014-07-25 Re-enabled update feature during process import.
 - 2014-07-25 Changed ProcessManagement EntityIDs to random strings.
 - 2014-07-24 Fixed bug#[8244](http://bugs.otrs.org/show_bug.cgi?id=8244) - QueueView hides queues that do not have at least one unlocked ticket.
 - 2014-07-22 Fixed bug#[10644](http://bugs.otrs.org/show_bug.cgi?id=10644) - Module parameters in GenericAgent are copied to ticket parameters
 - 2017-07-21 Changed Action based Ticket ACLs format from a hash form to an array form just like the other ACLs, including possibility to define Action based Ticket ACLs in the PossibleNot and PossibleAdd sections.
 - 2017-07-21 Added new Ticket ACL debugging options.
 - 2014-07-21 Added [Not], [NotRegExp] and [Notregexp] modifiers for all Ticket ACL sections.
 - 2014-07-21 Added possibility to combine different Ticket ACLs with Possible, PossibleAdd and PossibleNot sections.
 - 2014-07-21 Added PossibleAdd section to Ticket ACls.
 - 2014-07-21 Added "My Services" feature including: "Status View", "Tickets in My Services" filter for ticket based dashboard dashlets and more notification options under agent preferences.
 - 2014-07-21 Added DTL -> TT migration script for templates.
 - 2014-07-18 Changed customer user item to font awesome, thanks to Nils Leideck.
 - 2014-07-16 Added Generic Interface Transport HTTP REST
 - 2014-07-14 Added possibility to reply directly to internal and external notes.
 - 2014-07-10 Fixed bug#[10623](http://bugs.otrs.org/show_bug.cgi?id=10623) - Ticket owner is not shown regardless what is configured, thanks to Renee Bäcker.
 - 2014-07-10 Changed default settings to use a quick connect string instead of SID to connect to an oracle database, because SID is not working with an Oracle RAC cluster.
 - 2014-07-10 Changed default settings of oracles NLS_LANG variable from UTF8 to AL32UTF8 to fix problems with 4 byte unicode character.
 - 2014-07-08 Linked tickets of a specific type (e.g. merged) can now be hidden via SysConfig option.
 - 2014-07-08 Added: Customizable main navigation bar item sorting on a per-user basis with drag & drop.
 - 2014-07-07 Fixed bug#[7531](http://bugs.otrs.org/show_bug.cgi?id=7531) - Queue and Service delimiter '::' should be replaced in the output by ': :' to allow browsers a line break.
 - 2014-06-30 Fixed bug#[10581](http://bugs.otrs.org/show_bug.cgi?id=10581) - wrong underline color in ivory slim menu module links..
 - 2014-06-26 Fixed bug#[10396](http://bugs.otrs.org/show_bug.cgi?id=10396) - OTRS, MySQL, utf8 charset and non-BMP characters problem(thanks to ib.pl).
 - 2014-06-23 Fixed bug#[10522](http://bugs.otrs.org/show_bug.cgi?id=10522) - HTTP 500 error when uploading attachments to ticket on Windows.
 - 2014-06-23 Added edit and delete icon fonts to process management canvas elements, thanks to Nils Leideck.
 - 2014-06-10 Fixed bug#[10549](http://bugs.otrs.org/show_bug.cgi?id=10549) - SelectAllCheckboxes doesn't work as expected.
 - 2014-05-19 Fixed bug#[10519](http://bugs.otrs.org/show_bug.cgi?id=10519) - Opening and closing popups in ProcessManagement leads to performance issues.
 - 2014-05-19 Updated jsPlumb, Farahey and label spacer code.
 - 2014-05-16 Added: unlock ticket if owner is away, thanks to Moritz Lenz.
 - 2014-05-16 Added merging of dynamic fields on ticket merge, thanks to Moritz Lenz.
 - 2014-05-16 Detect cookie capability before login, thanks to Moritz Lenz.
 - 2014-05-16 Added support for HTTP basic auth in WebUserAgent, thanks to Renée Bäcker.
 - 2014-05-15 Added per user limit for agent and customer sessions.
 - 2014-05-06 Customer online list now links to the CIC.
 - 2014-04-16 Speedup TicketACLs by gather only the needed data from the DB based in the ACLs requirements, thanks to Moritz Lenz @ noris networks.
 - 2014-04-15 Added foreign db param to the customer user map.
 - 2014-04-04 Fixed bug#[10371](http://bugs.otrs.org/show_bug.cgi?id=10371) - Missing Note and NoteMandatory options for AgentTicketMove.
 - 2014-04-01 Fixed bug#[10320](http://bugs.otrs.org/show_bug.cgi?id=10320) - PostMaster Filter // possibility to Set more Email Headers.
 - 2014-03-24 Fixed bug#[10400](http://bugs.otrs.org/show_bug.cgi?id=10400) - AgentTicketProccess will not use error messages of dynamic field drivers.
 - 2014-03-20 Fixed bug#[10141](http://bugs.otrs.org/show_bug.cgi?id=10141) - invalid agents can't be selected in search form.
 - 2014-03-20 Fixed bug#[10208](http://bugs.otrs.org/show_bug.cgi?id=10208) - NeedSpellCheck does not work.
 - 2014-03-20 Fixed bug#[10385](http://bugs.otrs.org/show_bug.cgi?id=10385) - Wrong Queue ID for Errors and FormUpdate in AgentTicketActionCommon.
 - 2014-03-13 Fixed bug#[4224](http://bugs.otrs.org/show_bug.cgi?id=4224) - Unused variable $From, thanks to Bernhard Schmalhofer.
 - 2014-03-13 Fixed bug#[5114](http://bugs.otrs.org/show_bug.cgi?id=5114) - No Rich Text Editor on Notification (Event).
 - 2014-03-07 Added possibility to display tickets with thousands of articles, thanks to Moritz Lenz @ noris network. GUI improvements pending.
 - 2014-03-04 Fixed bug#[8903](http://bugs.otrs.org/show_bug.cgi?id=8903) - Forward Email - not inline attachments with Content-ID.
 - 2014-03-04 Added a new central ObjectManager to simplify singleton object creation and usage. Thanks a lot to Moritz Lenz @ noris network.
 - 2014-03-04 Fixed bug#[10244](http://bugs.otrs.org/show_bug.cgi?id=10244) - No mouseover popup for fields in ActivityDialogs.
 - 2014-02-24 Updated CPAN module parent to version 0.228.
 - 2014-02-24 Updated CPAN module YAML to version 0.90.
 - 2014-02-24 Updated CPAN module XML::TreePP to version 0.42.
 - 2014-02-24 Updated CPAN module Net::SSLGlue to version 1.052.
 - 2014-02-24 Updated CPAN module Net::IMAP::Simple to version 1.2204.
 - 2014-02-24 Updated CPAN module Mozilla::CA to version 20130114.
 - 2014-02-24 Updated CPAN module MailTools to version 2.13.
 - 2014-02-24 Updated CPAN module MIME::Tools to version 5.505.
 - 2014-02-24 Updated CPAN module Locale::Codes to version 3.29.
 - 2014-02-24 Updated CPAN module JavaScript::Minifier to version 1.11.
 - 2014-02-24 Updated CPAN module JSON::PP to version 2.27203.
 - 2014-02-24 Updated CPAN module JSON to version 2.90.
 - 2014-02-24 Updated CPAN module Email::Valid to version 1.192.
 - 2014-02-24 Updated CPAN module Crypt::PasswdMD5 to version 1.40.
 - 2014-02-24 Updated CPAN module CGI to version 3.65.
 - 2014-02-24 Updated CPAN module SOAP::Lite to version 1.11.
 - 2014-02-24 Updated CPAN module XML::Parser::Lite to version 0.719.
 - 2014-02-24 Removed CPAN module Apache2::Reload from Kernel/cpan-lib/ because this module is included in mod_perl 2.0.5 and later.
 - 2014-02-24 Fixed bug#[10295](http://bugs.otrs.org/show_bug.cgi?id=10295) - DateInFuture / DateNotInFuture validation.
 - 2014-02-21 Added new options to check dynamic fields of type text on patterns relating to error messages (translated), if they do not match.
 - 2014-02-21 Added new options to restrict dynamic fields of type date/datetime on future or past dates.
 - 2014-02-20 Fixed bug#[10093](http://bugs.otrs.org/show_bug.cgi?id=10093) - Dyn Field not used in auto-reply subject
 - 2014-02-18 Fixed bug#[10258](http://bugs.otrs.org/show_bug.cgi?id=10258) - yellow color for UnreadArticles.
 - 2014-02-18 Re-implemented Process Management ProcessImport().
 - 2014-02-13 Added browser check for IE10 in compatibility mode.
 - 2014-02-03 Improved DynamicFields history entries and events to also include the previous value, thanks to Dietmar Berg!
 - 2014-02-03 Follow-up for bug#[6802](http://bugs.otrs.org/show_bug.cgi?id=6802) - Consider window resize properly.
 - 2014-02-03 Fixed bug#[10177](http://bugs.otrs.org/show_bug.cgi?id=10177) - Missing sources in tarball.
 - 2014-02-03 Fixed bug#[9616](http://bugs.otrs.org/show_bug.cgi?id=9616) - Too long activities and transitions are not displayed correctly.
 - 2014-02-03 Fixed bug#[7440](http://bugs.otrs.org/show_bug.cgi?id=7440) - Ticket overviews don't show column headers for priority and unread articles in small mode.
 - 2014-02-03 Added process management canvas label spacer to avoid overlapping transition labels.
 - 2014-01-31 Fixed bug#[6802](http://bugs.otrs.org/show_bug.cgi?id=6802) - Navigation broken if many modules installed.
 - 2014-01-31 Fixed bug#[4512](http://bugs.otrs.org/show_bug.cgi?id=4512) - HTMLUtils ToAscii forces line breake on fixed line-length 78.
 - 2014-01-31 Fixed bug#[6671](http://bugs.otrs.org/show_bug.cgi?id=6671) - GenericAgent - Ticket-Action should be renamed to Ticket-Attribute.
 - 2014-01-31 Fixed bug#[6742](http://bugs.otrs.org/show_bug.cgi?id=6742) - Move mask in new window: Note is not required.
 - 2014-01-27 Use Template::Toolkit for template rendering instead of DTL. Upgrading instructions for Perl code will follow in the developer manual.
 - 2014-01-24 Removed json2.js, it is no longer needed because all supported browser have built-in json support now (see bug#10079).
 - 2014-01-10 Fixed bug#[10145](http://bugs.otrs.org/show_bug.cgi?id=10145) - %A is not correctly substituted in Language::Time().
 - 2014-01-10 Make it possible to pass HTTP headers to WebUserAgent, thanks to Renée Bäcker.
 - 2014-01-10 Added functionality to unlock just one single ticket in otrs.UnlockTickets.pl, thanks to Martin Gross @ rtt.ag.
 - 2013-12-16 Improved mail address parsing speed, thanks to Moritz Lenz!
 - 2013-12-13 Fixed bug#[10090](http://bugs.otrs.org/show_bug.cgi?id=10090) - Problems with special characters in Kernel/System/WebUserAgent.pm.
 - 2013-12-12 Added additional information to install commands for different distributions (see perl bin/otrs.CheckModules.pl -h) for more information.

# 3.3.9 2014-09-09
 - 2014-11-03 Fixed bug#[10845](http://bugs.otrs.org/show_bug.cgi?id=10845) - No date search if TimeInputFormat is Input.
 - 2014-10-14 Fixed bug#[8535](http://bugs.otrs.org/show_bug.cgi?id=8535) - Only first 1000 Tickets are shown in CustomerInterface.
 - 2014-10-14 Fixed bug#[10729](http://bugs.otrs.org/show_bug.cgi?id=10729) - Dynamic Fields are shown incorrect at Ticket Overview, thanks to S7.
 - 2014-09-12 Fixed bug#[10710](http://bugs.otrs.org/show_bug.cgi?id=10710) - Adding agent with username that has already existed in AdminUser leads to SQL error message, thanks to S7.
 - 2014-09-12 Fixed bug#[10703](http://bugs.otrs.org/show_bug.cgi?id=10703) - Fulltext field is not added by default if there are not default fields in Ticket search, thanks to S7.
 - 2014-08-29 Fixed bug#[10697](http://bugs.otrs.org/show_bug.cgi?id=10697) - Column name in CSV report of stats is lowercase.
 - 2014-08-29 Fixed bug#[10652](http://bugs.otrs.org/show_bug.cgi?id=10652) - Process tickets without any articles create empty lines in AgentTicketSearch CSV result file.
 - 2014-08-29 Fixed bug#[10607](http://bugs.otrs.org/show_bug.cgi?id=10607) - SQL Box can change the database.
 - 2014-08-28 Fixed bug#[10700](http://bugs.otrs.org/show_bug.cgi?id=10700) - Bugfix: TimeUnits not written if E-Mail is sent via BulkAction.
 - 2014-08-28 Fixed bug#[10699](http://bugs.otrs.org/show_bug.cgi?id=10699) - Cannot add new customer (company).
 - 2014-08-21 Fixed bug#[10497](http://bugs.otrs.org/show_bug.cgi?id=10497) - CustomerUser secondary database access opens multitude of database connections.
 - 2014-08-08 Fixed bug#[9756](http://bugs.otrs.org/show_bug.cgi?id=9756) - Owner will be set after QueueMove screen AND undo.
 - 2014-08-08 Fixed bug#[10606](http://bugs.otrs.org/show_bug.cgi?id=10606) - Dynamic fields in dashboard overview are empty.
 - 2014-08-07 Updated Danish translation, thanks to Lars Jørgensen.
 - 2014-08-01 Fixed bug#[10670](http://bugs.otrs.org/show_bug.cgi?id=10670) - It is possible to start the scheduler more than once.
 - 2014-07-29 Fixed bug#[10598](http://bugs.otrs.org/show_bug.cgi?id=10598) - Field tags not parsed properly in auto response subject.
 - 2014-07-29 Fixed bug#[10658](http://bugs.otrs.org/show_bug.cgi?id=10658) - Issue with multiple customer company backends.
 - 2014-07-29 Fixed bug#[10622](http://bugs.otrs.org/show_bug.cgi?id=10622) - eMail address only with uppercases - wrong display.
 - 2014-07-29 Fixed bug#[10596](http://bugs.otrs.org/show_bug.cgi?id=10596) - Manual Generic Agent Run doesn't show archived tickets as affected.
 - 2014-07-29 Fixed bug#[10601](http://bugs.otrs.org/show_bug.cgi?id=10601) - ExternalTicketNumberRecognition produces errors in log file.
 - 2014-07-17 Fixed bug#[10612](http://bugs.otrs.org/show_bug.cgi?id=10612) - Wrong Time in DashboardField "Changed", thanks to S7.
 - 2014-07-10 Fixed bug#[10595](http://bugs.otrs.org/show_bug.cgi?id=10595) - Standard Replies are false sorted in Ticket Zoom select box.
 - 2014-07-07 Fixed bug#[10534](http://bugs.otrs.org/show_bug.cgi?id=10534) - Wildcard hacking the customer information center, thanks to S7.
 - 2014-07-03 Fixed bug#[10586](http://bugs.otrs.org/show_bug.cgi?id=10586) - In Customer Portal no attachments are shown.
 - 2014-06-30 Fixed bug#[6601](http://bugs.otrs.org/show_bug.cgi?id=6601) - Changing search options changes order of fields, thanks to S7.
 - 2014-06-23 Fixed bug#[10246](http://bugs.otrs.org/show_bug.cgi?id=10246) - ProcessManagement: ConditionLinking OR in a Transition doesn't work.
 - 2014-06-23 Fixed bug#[10559](http://bugs.otrs.org/show_bug.cgi?id=10559) - "Previous Owner" don't use the FirstnameLastnameOrder configuration.
 - 2014-06-23 Fixed bug#[10532](http://bugs.otrs.org/show_bug.cgi?id=10532) - PostMasterMailbox.pl hangs parsing mails.
 - 2014-06-23 Fixed bug#[10578](http://bugs.otrs.org/show_bug.cgi?id=10578) - Service selection in GA Ticket Action allows multi select.

# 3.3.8 2014-06-24
 - 2014-06-16 Fixed bug#[10524](http://bugs.otrs.org/show_bug.cgi?id=10524) - Internal Dynamic Fields in Activity Dialog.
 - 2014-06-16 Updated Brazilian Portugese translation, thanks to Murilo Moreira de Oliveira.
 - 2014-06-13 Fixed bug#[10508](http://bugs.otrs.org/show_bug.cgi?id=10508) - (Agent|Customer)TicketProcess javascript errors when uploading attachments/having server errors.
 - 2014-06-10 Fixed bug#[10521](http://bugs.otrs.org/show_bug.cgi?id=10521) - OutputFilterText AutoLink CVE.
 - 2014-06-03 Fixed bug#[10430](http://bugs.otrs.org/show_bug.cgi?id=10430) - backup.pl doesn't work with PostgreSQL unix sockets.
 - 2014-06-03 Fixed bug#[5012](http://bugs.otrs.org/show_bug.cgi?id=5012) - Merging a watched ticket _into_ another should "transfer" the Watch status to the final ticket, thanks to Michiel Beijen!
 - 2014-06-02 Fixed bug#[10544](http://bugs.otrs.org/show_bug.cgi?id=10544) - Upgrade to OTRS 3.3.7 breaks connection to external customer user tables.
 - 2014-05-28 Fixed bug#[10535](http://bugs.otrs.org/show_bug.cgi?id=10535) - ACLListGet() produces DB warning message.
 - 2014-05-28 Fixed bug#[10163](http://bugs.otrs.org/show_bug.cgi?id=10163) - subject shows only 30 characters, thanks to S7designcreative.
 - 2014-05-28 Updated Latin Serbian translation, thanks to S7designcreative.
 - 2014-05-28 Updated Cyrillic Serbian translation, thanks to S7designcreative.
 - 2014-05-16 Fixed bug#[10427](http://bugs.otrs.org/show_bug.cgi?id=10427) - Bulk action locks tickets - cancel keeps them locked.
 - 2014-05-15 Fixed bug#[10513](http://bugs.otrs.org/show_bug.cgi?id=10513) - Some SupportData Plugin Identifiers ends with ::.
 - 2014-05-14 Updated Latin Serbian translation, thanks to S7designcreative.
 - 2014-05-12 Fixed bug#[8494](http://bugs.otrs.org/show_bug.cgi?id=8494) - Possibility to split quotes in rich text editor.
 - 2014-05-09 Fixed bug#[10491](http://bugs.otrs.org/show_bug.cgi?id=10491) - CIC not always accessible via TicketZoom.
 - 2014-05-09 Updated Swedish translation, thanks to Peter Krantz.

# 3.3.7 2014-05-13
 - 2014-05-08 Fixed bug#[10475](http://bugs.otrs.org/show_bug.cgi?id=10475) - otrs.RebuildFulltextIndex.pl - multiple output lines.
 - 2014-05-07 Updated Japanese translation, thanks to Toshihiro Takehara.
 - 2014-05-07 Updated Swedish translation, thanks to Peter Krantz.
 - 2014-05-02 Fixed bug#[9350](http://bugs.otrs.org/show_bug.cgi?id=9350) - Initial notes by ticket split not visible it the ticket zoom.
 - 2014-05-02 Fixed bug#[10501](http://bugs.otrs.org/show_bug.cgi?id=10501) - Support-Data Swap plugin reports KB instead of MB.
 - 2014-05-02 Fixed bug#[10458](http://bugs.otrs.org/show_bug.cgi?id=10458) - Can't use system registration with some OTRS-IDs.
 - 2014-04-29 Fixed bug#[10470](http://bugs.otrs.org/show_bug.cgi?id=10470) - Need FormID! error when embedding image when creating a Process Ticket.
 - 2014-04-28 Fixed bug#[9876](http://bugs.otrs.org/show_bug.cgi?id=9876) - CaseSensitive option wrong in CustomerCompany.
 - 2014-04-17 Removed OTRS Scheduler Service startup files in favor of Watchdog mode via cron jobs.
 - 2014-04-17 Fixed bug#[10468](http://bugs.otrs.org/show_bug.cgi?id=10468) - Wrong regexp in Kernel/System/HTMLUtils.pm line 171.
 - 2014-04-17 Fixed bug#[10441](http://bugs.otrs.org/show_bug.cgi?id=10441) - Eventbased notification - infinite loop.
 - 2014-04-17 Fixed bug#[10428](http://bugs.otrs.org/show_bug.cgi?id=10428) - Event Notification ArticleSend Loop.
 - 2014-04-17 Fixed bug#[10462](http://bugs.otrs.org/show_bug.cgi?id=10462) - Translation of static statistic widgets (Dashboard).
 - 2014-04-16 Added OTRS Scheduler Watchdog mode.
 - 2014-04-17 Fixed bug#[10469](http://bugs.otrs.org/show_bug.cgi?id=10469) - Adding Links in AgentLinkObject not possible if no search term was selected.
 - 2014-04-16 Fixed bug#[10464](http://bugs.otrs.org/show_bug.cgi?id=10464) - Closing link delete screen in AgentTicketPhone reloads page for temporary links.
 - 2014-04-16 Fixed bug#[10461](http://bugs.otrs.org/show_bug.cgi?id=10461) - Link to CustomerTicketProcess in Customer interface displayed even though no process is available..
 - 2014-04-16 Fixed bug#[8253](http://bugs.otrs.org/show_bug.cgi?id=8253) - Missing hover texts for actions in German translation of AgentTicketZoom.
 - 2014-04-15 Fixed bug#[10442](http://bugs.otrs.org/show_bug.cgi?id=10442) - Translation of states in statistic widgets (Dashboard).
 - 2014-04-11 Fixed bug#[10395](http://bugs.otrs.org/show_bug.cgi?id=10395) - E-mail header parsing bug.
 - 2014-04-11 Fixed bug#[10394](http://bugs.otrs.org/show_bug.cgi?id=10394) - rfc822 attachments name creating bug and validation enhancement.
 - 2014-04-11 Fixed bug#[10449](http://bugs.otrs.org/show_bug.cgi?id=10449) - Safer commands to upgrade OTRS using PostgreSQL.
 - 2014-04-10 Fixed bug#[10402](http://bugs.otrs.org/show_bug.cgi?id=10402) - Transition or Transition Action popup a login page.
 - 2014-04-10 Fixed bug#[10446](http://bugs.otrs.org/show_bug.cgi?id=10446) - otrs.PostMasterMailbox.pl Unknown encoding '3DISO-8859-2?=' at /usr/local/otrs/Kernel/System/Encode.pm line 367.
 - 2014-04-10 Fixed bug#[9592](http://bugs.otrs.org/show_bug.cgi?id=9592) - Ticket history overflows for dynamic field.
 - 2014-04-10 Fixed bug#[8207](http://bugs.otrs.org/show_bug.cgi?id=8207) - Wrong encoding in graphs.
 - 2014-04-10 Fixed bug#[10416](http://bugs.otrs.org/show_bug.cgi?id=10416) - Customer selection is not translated.
 - 2014-04-10 Fixed bug#[9098](http://bugs.otrs.org/show_bug.cgi?id=9098) - The system still consider the customer_ids, even after field is empty on table customer_user.
 - 2014-04-09 Fixed bug#[10202](http://bugs.otrs.org/show_bug.cgi?id=10202) - Process Modules, Dynamic Fields, and ACLs with AJAX update.
 - 2014-04-08 Fixed bug#[10432](http://bugs.otrs.org/show_bug.cgi?id=10432) - ACLs not working correctly in CustomerTicketZoom (Message Followup).
 - 2014-04-04 Fixed bug#[10436](http://bugs.otrs.org/show_bug.cgi?id=10436) - Error message in syslog about ACL then there is no ACL defined.
 - 2014-04-04 Fixed bug#[10438](http://bugs.otrs.org/show_bug.cgi?id=10438) - Strange sorting of columns in Ticket Dashboard widgets.
 - 2014-04-04 Fixed bug#[10425](http://bugs.otrs.org/show_bug.cgi?id=10425) - Customer Information in AgentTicketZoom.
 - 2014-04-03 Followup for bug#10340 - Dynamic field not visible in queue view screen (AgentTicketOverviewSmall.dtl).
 - 2014-04-03 Fixed bug#[10406](http://bugs.otrs.org/show_bug.cgi?id=10406) - Ticket Templates Type "Create" will be not translated.
 - 2014-04-03 Fixed bug#[10378](http://bugs.otrs.org/show_bug.cgi?id=10378) - SessionID created with generic interface wont work using it as Agent.
 - 2014-04-01 Fixed bug#[10399](http://bugs.otrs.org/show_bug.cgi?id=10399) - Columns Settings lost after search.
 - 2014-04-01 Fixed bug#[10431](http://bugs.otrs.org/show_bug.cgi?id=10431) - Fallback configuration for scheduler log is wrong.
 - 2014-04-01 Fixed bug#[10426](http://bugs.otrs.org/show_bug.cgi?id=10426) - Scheduler RegistrationUpdate task dies with PostgreSQL DB.
 - 2014-03-31 Fixed bug#[10362](http://bugs.otrs.org/show_bug.cgi?id=10362) - .procmailrc is reset with wrong permissions on otrs.SetPermisssion.pl execution.
 - 2014-03-30 Fixed bug#[10350](http://bugs.otrs.org/show_bug.cgi?id=10350) - Events Ticket Calender: In case TicketCalendarStartTime=TicketCalendarEndTime, displayed ticket event time frame always 2 hours.
 - 2014-03-28 Enhanced DiskSpacePatitions SupportDataCollector plugin to deal correctly with multiple partitions with the same name.
 - 2014-03-27 Followup for bug#[10130](http://bugs.otrs.org/show_bug.cgi?id=10130) - Events Ticket Calendar not working.

# 3.3.6 2014-04-01
 - 2014-03-27 Fixed bug#[10412](http://bugs.otrs.org/show_bug.cgi?id=10412) - customer.pl: Use of uninitialized value $Param{"Title"}.
 - 2014-03-27 Fixed bug#[10413](http://bugs.otrs.org/show_bug.cgi?id=10413) - vertical scroll not shown in search screen.
 - 2014-03-27 Updated French translation, thanks to Guillaume Houdmon..
 - 2014-03-25 Extended the OTRS system registration to optionally also send the support assessment data along with the system registration data. Support assessment data is improved and extended and can be accessed in the new Service Center module of the admin area.
 - 2014-03-25 Fixed bug#[10405](http://bugs.otrs.org/show_bug.cgi?id=10405) - When using the search feature of the tree selection overlay, one is not able to expand subtrees of matching entries.
 - 2014-03-24 Fixed bug#[10340](http://bugs.otrs.org/show_bug.cgi?id=10340) - Dynamic field not visible in queue view screen (AgentTicketOverviewSmall.dtl).
 - 2014-03-24 Fixed bug#[10397](http://bugs.otrs.org/show_bug.cgi?id=10397) - DynamicField configuration in SysConfig 'DefaultOverviewColumns' causes JS error.
 - 2014-03-21 Fixed bug#[10368](http://bugs.otrs.org/show_bug.cgi?id=10368) - Ticket title isn't shown.
 - 2014-03-21 Updated Japanese translation, thanks to Toshihiro Takehara..
 - 2014-03-21 Fixed bug#[10381](http://bugs.otrs.org/show_bug.cgi?id=10381) - AgentTicket*View has invalid SortBy options.
 - 2014-03-21 Fixed bug#[10383](http://bugs.otrs.org/show_bug.cgi?id=10383) - Missing 'DefaultColumns' SysConfig for AgentTicketSearch view.
 - 2014-03-21 Fixed bug#[10384](http://bugs.otrs.org/show_bug.cgi?id=10384) - out-of-office information not displayed in Ticket Zoom.
 - 2014-03-20 Fixed bug#[10379](http://bugs.otrs.org/show_bug.cgi?id=10379) - ACL Not Working.
 - 2014-03-20 Fixed bug#[10369](http://bugs.otrs.org/show_bug.cgi?id=10369) - Ticket::Frontend::Quote does not work with RichText Editor.
 - 2014-03-20 Improved handling of cachekeys in Stats.pm to prevent cacheing problems in the dashboard stats.
 - 2014-03-18 Fixed bug#[10334](http://bugs.otrs.org/show_bug.cgi?id=10334) - Deleting the attachment deletes the  recepients too.
 - 2014-03-18 Fixed bug#[10374](http://bugs.otrs.org/show_bug.cgi?id=10374) - OTRS does not protect against clickjacking.
 - 2014-03-15 Fixed bug#[10364](http://bugs.otrs.org/show_bug.cgi?id=10364) - Inline images displayed as attachment in SMIME and PGP signed messages.
 - 2014-03-14 Fixed bug#[10251](http://bugs.otrs.org/show_bug.cgi?id=10251) - SMIME signing fail on mails with attachements.
 - 2014-03-14 Fixed bug#[10277](http://bugs.otrs.org/show_bug.cgi?id=10277) - Statistics per agent also shows invalid agents.
 - 2014-03-14 Fixed bug#[10318](http://bugs.otrs.org/show_bug.cgi?id=10318) - Dynamic Field: Multi Select does not allow empty values.
 - 2014-03-14 Fixed bug#[10365](http://bugs.otrs.org/show_bug.cgi?id=10365) - Custom State types not working with "otrs.PendingJobs.pl" any more.
 - 2014-03-14 Fixed bug#[10349](http://bugs.otrs.org/show_bug.cgi?id=10349) - System Email notification external not highlighted correctly.
 - 2014-03-13 Fixed bug#[10361](http://bugs.otrs.org/show_bug.cgi?id=10361) - Incorrect handling of special characters in DynamicFields.
 - 2014-03-11 Fixed bug#[10324](http://bugs.otrs.org/show_bug.cgi?id=10324) - Customer user field still marked as empty even after providing data.
 - 2014-03-11 Fixed bug#[10019](http://bugs.otrs.org/show_bug.cgi?id=10019) - Tickets via "In line action bar" cannot be moved.
 - 2014-03-10 Fixed bug#[10283](http://bugs.otrs.org/show_bug.cgi?id=10283) - MouseOver on the Transitions does not show transition actions.
 - 2014-03-10 Fixed bug#[10241](http://bugs.otrs.org/show_bug.cgi?id=10241) - ACL-Editor Bug..
 - 2014-03-10 Fixed bug#[10338](http://bugs.otrs.org/show_bug.cgi?id=10338) - Empty Content-ID causes strange result -> HTML-tags are "corrupted".
 - 2014-03-07 Fixed bug#[9951](http://bugs.otrs.org/show_bug.cgi?id=9951) - Line breaks at the end of salutation templates are not saved.
 - 2014-03-07 Fixed bug#[10275](http://bugs.otrs.org/show_bug.cgi?id=10275) - Problem with encoding in attachment.
 - 2014-03-07 Fixed bug#[10085](http://bugs.otrs.org/show_bug.cgi?id=10085) - Postmaster incorrectly decodes headers, causes garbage in the database.
 - 2014-03-06 Fixed bug#[10336](http://bugs.otrs.org/show_bug.cgi?id=10336) - Problem with symlinked theme directories.
 - 2014-03-06 Fixed bug#[10328](http://bugs.otrs.org/show_bug.cgi?id=10328) - Error in AdminPostMasterFilter if the name of DynamicField changed.
 - 2014-03-04 Fixed bug#[10264](http://bugs.otrs.org/show_bug.cgi?id=10264) - Description (espacially article description) in processes are shown on improper place.
 - 2014-03-03 Fixed bug#[10240](http://bugs.otrs.org/show_bug.cgi?id=10240) - Restricting process list by ACLs is only working with UserID.
 - 2014-03-03 Fixed bug#[10299](http://bugs.otrs.org/show_bug.cgi?id=10299) - "Ouf of Office" shows inactive agents.
 - 2014-03-03 Fixed bug#[10321](http://bugs.otrs.org/show_bug.cgi?id=10321) - Applying Filters to tickets in Status View or Queue View will log out session..
 - 2014-03-03 Fixed bug#[9600](http://bugs.otrs.org/show_bug.cgi?id=9600) - When a ticket is deleted by generic agent job,  No such TicketID error.
 - 2014-02-28 Fixed bug#[9675](http://bugs.otrs.org/show_bug.cgi?id=9675) - No use Ticket::Hook in AgentLinkObject.
 - 2014-02-28 Updated Japanese translation, thanks to Norihiro Tanaka!
 - 2014-02-27 Fixed bug#[10300](http://bugs.otrs.org/show_bug.cgi?id=10300) - Special character in customer id cuts off string..
 - 2014-02-27 Fixed bug#[10309](http://bugs.otrs.org/show_bug.cgi?id=10309) - mails with an empty return-path header must not trigger auto responses in OTRS.
 - 2014-02-21 Fixed bug#[10245](http://bugs.otrs.org/show_bug.cgi?id=10245) - Use of uninitialized value $Param{"Value2"} in string.
 - 2014-02-21 Fixed bug#[10182](http://bugs.otrs.org/show_bug.cgi?id=10182) - Customer email suddenly treated by OTRS as 'email-internal'.
 - 2014-02-21 Fixed bug#[10285](http://bugs.otrs.org/show_bug.cgi?id=10285) - No use Ticket::Hook in CustomerTicketZoom.
 - 2014-02-21 Fixed bug#[9787](http://bugs.otrs.org/show_bug.cgi?id=9787) - Queue field doesn't appear in ProcessMgmt.
 - 2014-02-21 Fixed bug#[10222](http://bugs.otrs.org/show_bug.cgi?id=10222) - Customer search during ticket creation - OTRS shows details also if no customer match the search.
 - 2014-02-20 Fixed bug#[10259](http://bugs.otrs.org/show_bug.cgi?id=10259) - GenericInterface: mapping key can't map from / to 0.

# 3.3.5 2014-02-25
 - 2014-02-20 Improved HTML filter.
 - 2014-02-19 Followup fix for bug#[10116](http://bugs.otrs.org/show_bug.cgi?id=10116) - Random ordering of columns in "Small" ticket lists.
 - 2014-02-17 Updated Japanese translation, thanks to Norihiro Tanaka!
 - 2014-02-17 Updated Brazilian Portugese translation, thanks to Murilo Moreira de Oliveira!
 - 2014-02-17 Updated Polish translation, thanks to Wojciech Myrda.
 - 2014-02-13 Added feature to download report data shown in dashboard stats as CSV and PDF.
 - 2014-02-13 Fixed bug#[6323](http://bugs.otrs.org/show_bug.cgi?id=6323) - Graph/Chart generation selects slice/background color identical to text color.
 - 2014-02-13 Fixed bug#[10248](http://bugs.otrs.org/show_bug.cgi?id=10248) - OTRS Portal - Overview of registered systems.
 - 2014-02-13 Followup for bug#[9011](http://bugs.otrs.org/show_bug.cgi?id=9011) - New value after value mapping can't be 0.
 - 2014-02-13 Fixed bug#[9673](http://bugs.otrs.org/show_bug.cgi?id=9673) - CustomerTicketMessage does not show loading icon for dynamic fields.
 - 2014-02-13 Fixed bug#[10249](http://bugs.otrs.org/show_bug.cgi?id=10249) - Restore.pl bugs on Postgresql restore failed on DB.
 - 2014-02-13 Fixed bug#[7818](http://bugs.otrs.org/show_bug.cgi?id=7818) - Menu simplification is not working for item "responsible".
 - 2014-02-11 Added new option "bin/otrs.LoaderCache.pl -o generate" to generate the loader cache for all frontend modules. This can be useful in cluster setups.
 - 2014-02-07 Fixed bug#[10214](http://bugs.otrs.org/show_bug.cgi?id=10214) - Value "0" for DynamicsFields prevents TicketCreation.
 - 2014-02-07 Fixed bug#[10201](http://bugs.otrs.org/show_bug.cgi?id=10201) - Wrong column sort order in ticketoverview widget.
 - 2014-02-07 Fixed bug#[10195](http://bugs.otrs.org/show_bug.cgi?id=10195) - Folluw up notification shows old prio after prio change.
 - 2014-02-07 Fixed bug#[9303](http://bugs.otrs.org/show_bug.cgi?id=9303) - Body of new e-mail/phone ticket not inserting when creating new ticket from customer creation.
 - 2014-02-07 Fixed bug#[10194](http://bugs.otrs.org/show_bug.cgi?id=10194) - CustomerTicketMessage parsing feild Dest in URI.
 - 2014-02-06 Fixed bug#[9970](http://bugs.otrs.org/show_bug.cgi?id=9970) - Problem with DBUpgrade-to-3.3.pl on Oracle databases.
 - 2014-02-04 Follow-up fix for bug#[10110](http://bugs.otrs.org/show_bug.cgi?id=10110) - Stats list may show too few or too many stats.
 - 2014-02-04 Fixed bug#[10220](http://bugs.otrs.org/show_bug.cgi?id=10220) - Invalid Statistics not displayed in overview.
 - 2014-02-04 Fixed bug#[10218](http://bugs.otrs.org/show_bug.cgi?id=10218) - Header X-UA-Compatible in HeaderSmall.tt/HeaderSmall.dtl not set.
 - 2014-01-31 Fixed bug#[10212](http://bugs.otrs.org/show_bug.cgi?id=10212) - My tickets & Company tickets in 3.3.4.
 - 2014-01-31 Fixed bug#[10211](http://bugs.otrs.org/show_bug.cgi?id=10211) - Dashbord: Widget DefaultColumns is not working.
 - 2014-01-31 Fixed bug#[10163](http://bugs.otrs.org/show_bug.cgi?id=10163) - subject shows only 30 characters.
 - 2014-01-31 Fixed bug#[10193](http://bugs.otrs.org/show_bug.cgi?id=10193) - Expired cookie bug in customer interface..
 - 2014-01-31 Fixed bug#[8729](http://bugs.otrs.org/show_bug.cgi?id=8729) - Oracle ignores NLS_DATE_FORMAT set in environment.
 - 2014-01-31 Fixed bug#[10207](http://bugs.otrs.org/show_bug.cgi?id=10207) - DynamicField Search-Function in CustomerFrontend is not working.
 - 2014-01-31 Fixed bug#[8729](http://bugs.otrs.org/show_bug.cgi?id=8729) - Oracle ignores NLS_DATE_FORMAT set in environment.
 - 2014-01-30 Fixed bug#[9868](http://bugs.otrs.org/show_bug.cgi?id=9868) - Queues in popup box are not sorted by alphabetical order.
 - 2014-01-30 Fixed bug#[9678](http://bugs.otrs.org/show_bug.cgi?id=9678) - Locked tickets don't unlock when customer closes ticket.
 - 2014-01-30 Fixed bug#[8656](http://bugs.otrs.org/show_bug.cgi?id=8656) - Clicking the cancel button in the Add Web services screen results in an error no matter what data was filled in.
 - 2014-01-30 Fixed bug#[10209](http://bugs.otrs.org/show_bug.cgi?id=10209) - When opening tree selection dialog, the search field should get the focus.
 - 2014-01-28 Fixed bug#[10205](http://bugs.otrs.org/show_bug.cgi?id=10205) - GenericInterface: Mandatory TimeUnits can't be 0.
 - 2014-01-28 Fixed bug#[10196](http://bugs.otrs.org/show_bug.cgi?id=10196) - Ticket merge action does not notify the owner of the existing ticket.
 - 2014-01-28 Fixed bug#[10130](http://bugs.otrs.org/show_bug.cgi?id=10130) - Events Ticket Calendar not working.
 - 2014-01-28 Fixed bug#[9692](http://bugs.otrs.org/show_bug.cgi?id=9692) - On PhoneOutbound articles,  the FROM field shows Customer ID instead Agent ID.
 - 2014-01-28 Fixed bug#[10147](http://bugs.otrs.org/show_bug.cgi?id=10147) - Cache may remain incorrectly in SearchProfile.
 - 2014-01-24 Fixed bug#[10189](http://bugs.otrs.org/show_bug.cgi?id=10189) - ProcessManagement: Use article subject if no ticket title is set.
 - 2014-01-24 Fixed bug#[9654](http://bugs.otrs.org/show_bug.cgi?id=9654) - TicketUpdate operation doesn't work when authenticated as a customer.
 - 2014-01-24 Fixed bug#[10137](http://bugs.otrs.org/show_bug.cgi?id=10137) - Generic interface TicketCreate operation doesn't work when authenticated as a customer.
 - 2014-01-24 Fixed bug#[10176](http://bugs.otrs.org/show_bug.cgi?id=10176) - available columns selection in search result view is not scrollable.
 - 2014-01-24 Fixed bug#[10120](http://bugs.otrs.org/show_bug.cgi?id=10120) - Management Dashboard: page reload erases stat graph settings.
 - 2014-01-24 Fixed bug#[9276](http://bugs.otrs.org/show_bug.cgi?id=9276) - Auto-reply to ticket entered via Web interface is sent with all lines concatenated to one
 - 2014-01-24 Fixed bug#[10179](http://bugs.otrs.org/show_bug.cgi?id=10179) - No LinkOption in CustomerNavigationBar.dtl.
 - 2014-01-24 Fixed bug#[10178](http://bugs.otrs.org/show_bug.cgi?id=10178) - Stat Permissions.
 - 2014-01-24 Fixed bug#[10188](http://bugs.otrs.org/show_bug.cgi?id=10188) - Inconsistency in graphical ACL editor.
 - 2014-01-23 Fixed bug#[10155](http://bugs.otrs.org/show_bug.cgi?id=10155) - backup.pl doesn't compress database dump on non-MySQL-dumps.
 - 2014-01-20 Fixed bug#[10106](http://bugs.otrs.org/show_bug.cgi?id=10106) - Sending Articles with ArticleSend() ignores ReplyTo.

# 3.3.4 2014-01-28
 - 2014-01-20 Fixed bug#[10172](http://bugs.otrs.org/show_bug.cgi?id=10172) - Can't create process tickets with disabled richtext.
 - 2014-01-17 Fixed bug#[10121](http://bugs.otrs.org/show_bug.cgi?id=10121) - QQMails break in OTRS.
 - 2014-01-17 Fixed bug#[10153](http://bugs.otrs.org/show_bug.cgi?id=10153) - Error shown in SysConfig when Setting PendingDiffTime to 30 Days.
 - 2014-01-17 Fixed bug#[10161](http://bugs.otrs.org/show_bug.cgi?id=10161) - Edit Stats - 500 internal Server Error.
 - 2014-01-17 Fixed bug#[10167](http://bugs.otrs.org/show_bug.cgi?id=10167) - Non-deterministic hash key construction in Stats.pm.
 - 2014-01-14 Fixed bug#[10158](http://bugs.otrs.org/show_bug.cgi?id=10158) - Missing quoting in State::StateGetStatesByType().
 - 2014-01-14 Fixed bug#[10048](http://bugs.otrs.org/show_bug.cgi?id=10048) - RPM upgrade breaks permissions on config files.
 - 2014-01-14 Fixed bug#[8969](http://bugs.otrs.org/show_bug.cgi?id=8969) - FAQ module Language files installation fails (Kernel/Language permissions).
 - 2014-01-10 Updated traditional Chinese translation.
 - 2014-01-10 Updated Brazilian Portugese translation, thanks to Murilo Moreira de Oliveira!
 - 2014-01-10 Fixed bug#[10145](http://bugs.otrs.org/show_bug.cgi?id=10145) - %A is not correctly substituted in Language::Time().
 - 2014-01-10 Fixed bug#[10079](http://bugs.otrs.org/show_bug.cgi?id=10079) - Cannot operate OTRS on IE7 because of JavaScript error.
 - 2014-01-10 Fixed bug#[10113](http://bugs.otrs.org/show_bug.cgi?id=10113) - Management dashboard setting doesn't show up when agent only has RO on stats.
 - 2014-01-10 Fixed bug#[10088](http://bugs.otrs.org/show_bug.cgi?id=10088) - Error messages on recieving mailer daemons.
 - 2014-01-10 Fixed bug#[10011](http://bugs.otrs.org/show_bug.cgi?id=10011) - Management Dashboard: X-Axis element labels may overlap.
 - 2014-01-09 Fixed bug#[10012](http://bugs.otrs.org/show_bug.cgi?id=10012) - Management Dashboard: strings not translatable.
 - 2014-01-07 Fixed bug#[10140](http://bugs.otrs.org/show_bug.cgi?id=10140) - Unable to search using before/after in Date Dynamic Fields.
 - 2014-01-06 Fixed bug#[10008](http://bugs.otrs.org/show_bug.cgi?id=10008) - Customer user is automatically added to Cc at response for email-internal in AgentTicketCompose.
 - 2014-01-06 Added Hebrew translation file, thanks to Amir Elion!
 - 2014-01-03 Fixed bug#[9978](http://bugs.otrs.org/show_bug.cgi?id=9978) - Activity Dialog for Customer shows "No Process configured!".
 - 2014-01-03 Fixed bug#[10134](http://bugs.otrs.org/show_bug.cgi?id=10134) - Missing information on icon actions for SMIME certificates and keys.
 - 2014-01-02 Fixed bug#[10116](http://bugs.otrs.org/show_bug.cgi?id=10116) - Random ordering of columns in "Small" ticket lists.
 - 2013-12-23 Fixed bug#[10094](http://bugs.otrs.org/show_bug.cgi?id=10094) - Former FAO OTRSACLExtensions not available in the ACL Editor.
 - 2013-12-20 Fixed bug#[10099](http://bugs.otrs.org/show_bug.cgi?id=10099) - Missing challenge token checks on customer interface.
 - 2013-12-18 Fixed bug#[10110](http://bugs.otrs.org/show_bug.cgi?id=10110) - Stats list may show too few or too many stats.
 - 2013-12-17 Fixed bug#[10103](http://bugs.otrs.org/show_bug.cgi?id=10103) - ArticleTypeID is always undef in AgentTicketCompose
 - 2013-12-16 Fixed bug#[10080](http://bugs.otrs.org/show_bug.cgi?id=10080) - Bad group check in otrs-scheduler-linux.
 - 2013-12-16 Fixed bug#[10097](http://bugs.otrs.org/show_bug.cgi?id=10097) - $Param{NextState} is always undef in AgentTicketCompose.
 - 2013-12-16 Updated Russian translation, thanks to Yuriy Kolesnikov.
 - 2013-12-13 Fixed bug#[10074](http://bugs.otrs.org/show_bug.cgi?id=10074) - Error if no queue matched in DashboardEventsTicketCalendar.
 - 2013-12-12 Fixed bug#[965](http://bugs.otrs.org/show_bug.cgi?id=9650) - Special character in customer id breaks Open Tickets in AgentTicketZoom.
 - 2013-12-12 Added functionality to disable access to tickets of other customers with the same customer company in customer interface.
 - 2013-12-12 Fixed bug#[9702](http://bugs.otrs.org/show_bug.cgi?id=9702) - Wrong article type with external ticketnumber recognition i.c.w. follow-up reject option.
 - 2013-12-11 Fixed bug#[9723](http://bugs.otrs.org/show_bug.cgi?id=9723) - TicketAccountedTime stat does not run on Oracle with many tickets
 - 2013-12-09 Fixed bug#[10078](http://bugs.otrs.org/show_bug.cgi?id=10078) - Installer: error log after creating mysql database.
 - 2013-12-09 Fixed bug#[10056](http://bugs.otrs.org/show_bug.cgi?id=10056) - Installer fails when special characters in database user's password.
 - 2013-12-09 Fixed bug#[10077](http://bugs.otrs.org/show_bug.cgi?id=10077) - regular expressions in postmaster filter return 1 if no regex match.
 - 2013-12-09 Updated Swedish translation, thanks to Andreas Berger.
 - 2013-12-09 Fixed bug#[10075](http://bugs.otrs.org/show_bug.cgi?id=10075) - Stats widgets permission group is hardcoded to "stats"
 - 2013-12-09 Updated Russian translation, thanks to Andrey N. Burdin.
 - 2013-12-06 Fixed bug#[10070](http://bugs.otrs.org/show_bug.cgi?id=10070) - Wrong error message if Transition contains no transition actions.
 - 2013-12-06 Fixed bug#[10058](http://bugs.otrs.org/show_bug.cgi?id=10058) - Owner and Responsible are mandatory if enabled.
 - 2013-12-06 Fixed bug#[7792](http://bugs.otrs.org/show_bug.cgi?id=7792) - Ticket-Action "Change Queue" is hardcoded and should be called "Queue" only.
 - 2013-12-06 Fixed bug#[9109](http://bugs.otrs.org/show_bug.cgi?id=9109) - Printing ticket does not show the full subject line.
 - 2013-12-06 Fixed bug#[10064](http://bugs.otrs.org/show_bug.cgi?id=10064) - Translated fields loose sorting in Activity Dialog admin screen.
 - 2013-12-06 Fixed bug#[10066](http://bugs.otrs.org/show_bug.cgi?id=10066) - Required field isn't marked in AgentTicketCustomer.
 - 2013-12-05 Fixed bug#[10059](http://bugs.otrs.org/show_bug.cgi?id=10059) - Service selection unavailable if customer selection is possible.
 - 2013-12-05 Fixed bug#[10062](http://bugs.otrs.org/show_bug.cgi?id=10062) - Text label indent for locale RU - AgentÒicketViewCompose
 - 2013-12-05 Fixed bug#[10044](http://bugs.otrs.org/show_bug.cgi?id=10044) - PendingDiffTime removes 2013 (current year) when reaching end of the year.
 - 2013-12-05 Fixed bug#[10049](http://bugs.otrs.org/show_bug.cgi?id=10049) - Transition names in path edit screen ordered by ID instead of name.
 - 2013-12-05 Fixed bug#[10055](http://bugs.otrs.org/show_bug.cgi?id=10055) - Queue-Treeview not working correctly.
 - 2013-12-05 Fixed bug#[10061](http://bugs.otrs.org/show_bug.cgi?id=10061) - ArticleType dropdown in graphical ActivityDialog mask loads with empty value
 - 2013-12-05 Fixed bug#[10060](http://bugs.otrs.org/show_bug.cgi?id=10060) - Field names are not translated in graphical process editor.

# 3.3.3 2013-12-10
 - 2013-11-07 Updated Chinese simplified translation, thanks to Michael Shi.
 - 2013-12-03 Fixed bug#[10022](http://bugs.otrs.org/show_bug.cgi?id=10022) - Ticket form looses To, Cc and Bcc when submitting form.
 - 2013-12-02 Fixed bug#[9928](http://bugs.otrs.org/show_bug.cgi?id=9928) - Dropdown field in tree mode are not displayed in tree mode in column filters.
 - 2013-12-02 Fixed bug#[9327](http://bugs.otrs.org/show_bug.cgi?id=9327) - Filter breaks "Select all" functionality.
 - 2013-11-29 Fixed bug#[10035](http://bugs.otrs.org/show_bug.cgi?id=10035) - Adding a GenericAgent Job with an already existing name, will not be added, no error displayed.
 - 2013-11-29 Fixed bug#[10036](http://bugs.otrs.org/show_bug.cgi?id=10036) - Reset filters in small overviews does not reset the ticket list.
 - 2013-11-29 Fixed bug#[9997](http://bugs.otrs.org/show_bug.cgi?id=9997) - After empty ticket list, Column Filters are reset in Overview Small screens.
 - 2013-11-29 Fixed bug#[10028](http://bugs.otrs.org/show_bug.cgi?id=10028) - Duplicate Access Keys/hardcoded assignments.
 - 2013-11-29 Fixed bug#[9999](http://bugs.otrs.org/show_bug.cgi?id=9999) - Timestamps in HistoricalValueGet return milliseconds on SQL Server.
 - 2013-11-29 Fixed bug#[10023](http://bugs.otrs.org/show_bug.cgi?id=10023) - Subject always cleaned from prefixes, irrespective of configuration.
 - 2013-11-29 Fixed bug#[10027](http://bugs.otrs.org/show_bug.cgi?id=10027) - Added old ticket information to ticket_history.
 - 2013-11-28 Fixed bug#[10020](http://bugs.otrs.org/show_bug.cgi?id=10020) - Event Information within Events Ticket Calender has wrong translation.
 - 2013-11-28 Fixed bug#[10019](http://bugs.otrs.org/show_bug.cgi?id=10019) - Tickets via "In line action bar" cannot be moved.
 - 2013-11-28 Fixed bug#[9911](http://bugs.otrs.org/show_bug.cgi?id=9911) - Column filter by 'Queue' shouldn't be available on 'Queue view'.
 - 2013-11-28 Fixed bug#[9950](http://bugs.otrs.org/show_bug.cgi?id=9950) - Ticket Split takes uses system address as the customer.
 - 2013-11-25 Fixed bug#[9975](http://bugs.otrs.org/show_bug.cgi?id=9975) - Generic Interface (TicketSearch Operation) Limit param is ignored.
 - 2013-11-25 Updated jsPlumb to version 1.5.4.
 - 2013-11-22 Fixed bug#[10007](http://bugs.otrs.org/show_bug.cgi?id=10007) - StandardTemplateList() generates invalid SQL.

# 3.3.2 2013-11-26
 - 2013-11-21 Fixed bug#[9998](http://bugs.otrs.org/show_bug.cgi?id=9998) - Password fields on OTRS 3.3 do not allow typing in blanks.
 - 2013-11-19 Fixed bug#[7337](http://bugs.otrs.org/show_bug.cgi?id=7337) - AJAX Error on new Phone Ticket on IIS when using JSON::XS.
 - 2013-11-18 Fixed bug#[8991](http://bugs.otrs.org/show_bug.cgi?id=8991) - Back-action does not work when search result returned just  1 ticket.
 - 2013-11-18 Updated CKEditor to version 4.3.
 - 2013-11-14 Fixed bug#[9976](http://bugs.otrs.org/show_bug.cgi?id=9976) - Statistic Graphs not showing in IE 10.
 - 2013-11-14 Fixed bug#[9973](http://bugs.otrs.org/show_bug.cgi?id=9973) - DashboardUserOnline wiget display problems
 - 2013-11-14 Fixed bug#[9946](http://bugs.otrs.org/show_bug.cgi?id=9946) - Misplaced pagination in ticket overviews.
 - 2013-11-14 Fixed bug#[9962](http://bugs.otrs.org/show_bug.cgi?id=9962) - Datepicker localization data could not be found! when choosing French canadian language.
 - 2013-11-14 Fixed bug#[9968](http://bugs.otrs.org/show_bug.cgi?id=9968) - Multiple Result Set problem during DB upgrade on SQL Server 2012.
 - 2013-11-12 Fixed bug#[9937](http://bugs.otrs.org/show_bug.cgi?id=9937) - Activity-Dialogs in wrong order.
 - 2013-11-12 Fixed bug#[9935](http://bugs.otrs.org/show_bug.cgi?id=9935) - Dashboard shows internal server error if product.xml content is not valid XML.
 - 2013-11-12 Fixed bug#[9933](http://bugs.otrs.org/show_bug.cgi?id=9933) - DefaultOverviewColumns under Ticket -> Frontend::Agent Wrong Description.
 - 2013-11-12 Fixed bug#[7008](http://bugs.otrs.org/show_bug.cgi?id=7008) - Can not find customers in SQL Server database containing non-ascii characters.
 - 2013-11-11 Fixed bug#[9921](http://bugs.otrs.org/show_bug.cgi?id=9921) - Reply to previously signed email breaks PGP verification.
 - 2013-11-11 Fixed bug#[9945](http://bugs.otrs.org/show_bug.cgi?id=9945) - Cannot search for "Date" dynamic fields.
 - 2013-11-11 Fixed bug#[9954](http://bugs.otrs.org/show_bug.cgi?id=9954) - PGP Crypted and Signed emails could be wrongly parsed.
 - 2013-11-07 Follow-up fix for bug#[9931](http://bugs.otrs.org/show_bug.cgi?id=9931) - After upgrading to MIME::Tools 5.504 (without OTRS patches) SMIME signatures are broken.

# 3.3.1 2013-11-12
 - 2013-11-07 Updated Chinese simplified translation, thanks to Michael Shi.
 - 2013-11-07 Fixed bug#[9639](http://bugs.otrs.org/show_bug.cgi?id=9639) - TextArea validation message not translated.
 - 2013-11-07 Fixed bug#[9938](http://bugs.otrs.org/show_bug.cgi?id=9938) - ActivityDialog doesn't show queues with move_into permissions.
 - 2013-11-07 Fixed bug#[9942](http://bugs.otrs.org/show_bug.cgi?id=9942) - installer.pl returns "The check '' doesn't exist!" after mail configuration.
 - 2013-11-06 Fixed bug#[9862](http://bugs.otrs.org/show_bug.cgi?id=9862) - Missing Dynamic Field column headers in dashboard widgets.
 - 2013-11-06 Fixed bug#[9940](http://bugs.otrs.org/show_bug.cgi?id=9940) - Fedora misses dependency on Sys::Syslog.
 - 2013-11-06 Fixed bug#[9930](http://bugs.otrs.org/show_bug.cgi?id=9930) - CustomerInformationCenter breaks navigation bar.
 - 2013-11-06 Fixed bug#[9934](http://bugs.otrs.org/show_bug.cgi?id=9934) - Customer RichText Editor is not aligned with other fields.
 - 2013-11-05 Fixed bug#[9931](http://bugs.otrs.org/show_bug.cgi?id=9931) - After upgrading to MIME::Tools 5.504 (without OTRS patches) SMIME signatures are broken.
 - 2013-11-05 Fixed bug#[9778](http://bugs.otrs.org/show_bug.cgi?id=9778) - Web Installer fails on SQL Server Named Instances.
 - 2013-11-05 Updated cpan module MIME::Tools to version 5.504.
 - 2013-11-05 Fixed bug#[9916](http://bugs.otrs.org/show_bug.cgi?id=9916) - Error when updating CustomerUser Login on ForeignDB.
 - 2013-11-05 Fixed bug#[9841](http://bugs.otrs.org/show_bug.cgi?id=9841) - Tabbing changes radio button of owner change selection.
 - 2013-11-05 Fixed bug#[9867](http://bugs.otrs.org/show_bug.cgi?id=9867) - Validation errors are not shown correctly when replying to a ticket in Customer Interface.
 - 2013-11-04 Fixed bug#[9923](http://bugs.otrs.org/show_bug.cgi?id=9923) - Application type XML config files does not overwrite framework ones.
 - 2013-11-04 Fixed bug#[9926](http://bugs.otrs.org/show_bug.cgi?id=9926) - Cookies do not set HttpOnly attribute.
 - 2013-11-04 Fixed bug#[9914](http://bugs.otrs.org/show_bug.cgi?id=9914) - Spellchecker ignores double wrong words.
 - 2013-11-04 Fixed bug#[9832](http://bugs.otrs.org/show_bug.cgi?id=9832) - Perl 5.18.1 problems with MIME::Entity.
 - 2013-11-02 Fixed bug#[9924](http://bugs.otrs.org/show_bug.cgi?id=9924) - Scheduler can not stop or restart correctly if was started by another host.
 - 2013-11-01 Fixed bug#[9918](http://bugs.otrs.org/show_bug.cgi?id=9918) - Dropdown field in tree mode are not displayed in tree mode when opening CustomerTicketProcess.
 - 2013-11-01 Fixed bug#[9840](http://bugs.otrs.org/show_bug.cgi?id=9840) - Toolbar Icons not shown correctly in IE8.
 - 2013-11-01 Fixed bug#[9901](http://bugs.otrs.org/show_bug.cgi?id=9901) - CustomerFatalError expand/collapse error details is broken.
 - 2013-11-01 Fixed bug#[9891](http://bugs.otrs.org/show_bug.cgi?id=9891) - Table header of dashboard widgets text misaligned.
 - 2013-11-01 Fixed bug#[9903](http://bugs.otrs.org/show_bug.cgi?id=9903) - CustomerTicketOverview: Column header may wrap into table content.

# 3.3.0 RC1 2013-11-05
 - 2013-10-31 Updated French translation, thanks to Olivier Sallou.
 - 2013-10-31 Updated Italian translation, thanks to Luca Maranzano.
 - 2013-10-31 Added support for Apache 2.4 in the web server configuration file.
 - 2013-10-31 Fixed bug#[9910](http://bugs.otrs.org/show_bug.cgi?id=9910) - Startup warnings/errors with Perl 5.18.1.
 - 2013-10-29 Fixed bug#[9902](http://bugs.otrs.org/show_bug.cgi?id=9902) - Column Filters does not use NavBarFilters and other parameters.
 - 2013-10-29 Fixed bug#[9753](http://bugs.otrs.org/show_bug.cgi?id=9753) - `META HTTP-EQUIV="Refresh"` tag not stripped from HTML email.
 - 2013-10-29 Improved creation of sequences on Oracle databases to better support Oracle RAC clusters.
 - 2013-10-28 Fixed bug#[9897](http://bugs.otrs.org/show_bug.cgi?id=9897) - process ticket 'fading away' -> Process is invalid.
 - 2013-10-28 Fixed bug#[9850](http://bugs.otrs.org/show_bug.cgi?id=9850) - Dashboard Filter error in ticket and page count.
 - 2013-10-28 Fixed bug#[9888](http://bugs.otrs.org/show_bug.cgi?id=9888) - Warning when using standard template.
 - 2013-10-28 Fixed bug#[9749](http://bugs.otrs.org/show_bug.cgi?id=9749) - Using spell checker in rich text Editor strips HTML formatting.
 - 2013-10-28 Fixed bug#[4465](http://bugs.otrs.org/show_bug.cgi?id=4465) - Spell checker ispell ignores some characters such German umlauts.
 - 2013-10-28 Fixed bug#[9890](http://bugs.otrs.org/show_bug.cgi?id=9890) - Cannot use unicode content in DTL files.
 - 2013-10-28 Fixed bug#[9889](http://bugs.otrs.org/show_bug.cgi?id=9889) - Browser does not interpret CSS/JS files as UTF8.
 - 2013-10-25 Fixed bug#[9839](http://bugs.otrs.org/show_bug.cgi?id=9839) - Inline images not showing up when cookies are disabled.
 - 2013-10-25 Fixed bug#[9870](http://bugs.otrs.org/show_bug.cgi?id=9870) - `<OTRS_CUSTOMER_FROM>` not replaced in notification emails.
 - 2013-10-25 Moved process import functionality in the backend module Kernel/System/ProcessManagement/DB/Process.pm.
 - 2013-10-25 Fixed bug#[9880](http://bugs.otrs.org/show_bug.cgi?id=9880) - Auto response editor looses HTML formatting.
 - 2013-10-24 Fixed bug#[9872](http://bugs.otrs.org/show_bug.cgi?id=9872) - Default service is not applied to new customerusers.
 - 2013-10-23 Fixed bug#[9863](http://bugs.otrs.org/show_bug.cgi?id=9863) - Reset single filter in overviews leads to no results page.
 - 2013-10-22 Fixed bug#[9864](http://bugs.otrs.org/show_bug.cgi?id=9864) - No filter icon for dynamic fields in ticket overviews.
 - 2013-10-22 Fixed bug#[9844](http://bugs.otrs.org/show_bug.cgi?id=9844) - Column filter not saved on ticket overviews.
 - 2013-10-22 Fixed bug#[9842](http://bugs.otrs.org/show_bug.cgi?id=9842) - Script backup.pl fails to create backup in given directory..
 - 2013-10-22 Fixed bug#[9855](http://bugs.otrs.org/show_bug.cgi?id=9855) - OTRS can't connect to IMAP/TLS based servers from Windows.
 - 2013-10-21 Fixed bug#[9828](http://bugs.otrs.org/show_bug.cgi?id=9828) - Dynamic field updates of unchanged dynamic fields cause event based actions to fail.
 - 2013-10-21 Fixed bug#[9821](http://bugs.otrs.org/show_bug.cgi?id=9821) - Wrong description in Ticket::Frontend::AgentTicketLockedView###DefaultColumns.
 - 2013-10-21 Added new toolbar shortcut for "New process ticket".
 - 2013-10-18 Fixed bug#[9838](http://bugs.otrs.org/show_bug.cgi?id=9838) - OPM line endings changed by mail client leading to unverified package.
 - 2013-10-18 Fixed bug#[9835](http://bugs.otrs.org/show_bug.cgi?id=9835) - Redirect on IIS 7 leads to login screen.
 - 2013-10-18 Fixed bug#[9834](http://bugs.otrs.org/show_bug.cgi?id=9834) - Remove any double quotes in the email sender.
 - 2013-10-18 Fixed bug#[9669](http://bugs.otrs.org/show_bug.cgi?id=9669) - Accessibility: ticket submenu not expandable with the keyboard.
 - 2013-10-18 Speed up Kernel::System::TemplateGenerator, thanks to Moritz Lenz @ noris network!
 - 2013-10-18 Fixed bug#[9737](http://bugs.otrs.org/show_bug.cgi?id=9737) - Sort order in queue view labelled incorrectly for all columns except age.

# 3.3.0 beta5 2013-10-22
 - 2013-10-17 Added new feature "management dashboard". This makes it possible to display statistic charts in the dashboard. Please not that IE8 does not support this feature.
 - 2013-10-14 Fixed bug#[9804](http://bugs.otrs.org/show_bug.cgi?id=9804) - If access to a module not given permission, output the error to httpd log.
 - 2013-10-14 Fixed bug#[9815](http://bugs.otrs.org/show_bug.cgi?id=9815) - Different FirstnameLastname Format in "Involved Agent" window.
 - 2013-10-14 Fixed bug#[9819](http://bugs.otrs.org/show_bug.cgi?id=9819) - Inconsistent API in Date Dynamic Field EditFieldValueGet().
 - 2013-10-14 Fixed bug#[9818](http://bugs.otrs.org/show_bug.cgi?id=9818) - Wrong default sorting in user out of office widget.
 - 2013-10-14 Updated CPAN module SOAP::Lite to version 1.06.
 - 2013-10-14 Fixed bug#[9817](http://bugs.otrs.org/show_bug.cgi?id=9817) - Wrong default sorting in user online widget.
 - 2013-10-14 Fixed bug#[9814](http://bugs.otrs.org/show_bug.cgi?id=9814) - Tickets without articles not shown correcly in medium view.
 - 2013-10-14 Fixed bug#[9391](http://bugs.otrs.org/show_bug.cgi?id=9391) - Incorrect permissions on .procmailrc.
 - 2013-10-14 Fixed bug#[9812](http://bugs.otrs.org/show_bug.cgi?id=9812) - Sysconfig descriptions for tooltips and placeholder values of toolbar widgets are ignored.
 - 2013-10-14 Fixed bug#[9811](http://bugs.otrs.org/show_bug.cgi?id=9811) - JavaScript is not executed in QueueView Large in Strict Mode.
 - 2013-10-14 Fixed bug#[9810](http://bugs.otrs.org/show_bug.cgi?id=9810) - Queue View Settings cannot be opened in IE8.
 - 2013-10-10 Fixed bug#[9698](http://bugs.otrs.org/show_bug.cgi?id=9698) - Dynamic Fields with links open in same tab instead of in new window from overviews.
 - 2013-10-10 Fixed bug#[9788](http://bugs.otrs.org/show_bug.cgi?id=9788) - Preview overviews empty if no templates are available for queue.
 - 2013-10-10 Fixed bug#[9790](http://bugs.otrs.org/show_bug.cgi?id=9790) - OTRSExternalTicketNumberRecognition Feature addon settings are not migrated.
 - 2013-10-08 Fixed bug#[9796](http://bugs.otrs.org/show_bug.cgi?id=9796) - Misaligned Headers on Simple Stats.
 - 2013-10-07 Improved database update to 3.3 on PostgreSQL and MySQL databases; this is now much faster on larger data sets.
 - 2013-10-07 Fixed bug#[9770](http://bugs.otrs.org/show_bug.cgi?id=9770) - JavaScript Execution in ProcessManagement is broken in IE8.

# 3.3.0 beta4 2013-10-08
 - 2013-10-03 Replaced Registration feature in Web Installer with Registration functionality in Admin section.
 - 2013-10-03 Fixed bug#[9786](http://bugs.otrs.org/show_bug.cgi?id=9786) - Missing tooltip text in Dropdown and Multiselect Dynamic Fields admin.
 - 2013-10-03 Fixed bug#[9766](http://bugs.otrs.org/show_bug.cgi?id=9766) - Switch to customer simply enters customer user administration.
 - 2013-10-03 Fixed bug#[9785](http://bugs.otrs.org/show_bug.cgi?id=9785) - Switch Customer should not be displayed in New Ticket Customer Option.
 - 2013-10-02 Fixed bug#[9238](http://bugs.otrs.org/show_bug.cgi?id=9238) - After move via Process Management an error is displayed if agent has no ro permission.
 - 2013-10-02 Fixed bug#[9777](http://bugs.otrs.org/show_bug.cgi?id=9777) - Different config option values for SessionName in Defaults.pm and Framework.xml.
 - 2013-10-02 Fixed bug#[9775](http://bugs.otrs.org/show_bug.cgi?id=9775) - Dashboard widget "online" customer list empty.
 - 2013-10-01 Fixed bug#[9542](http://bugs.otrs.org/show_bug.cgi?id=9542) - Uninitialized value in AgentTicketForward.
 - 2013-10-01 Fixed bug#[9771](http://bugs.otrs.org/show_bug.cgi?id=9771) - SMTP backends ignore the port setting.
 - 2013-09-30 Fixed bug#[9765](http://bugs.otrs.org/show_bug.cgi?id=9765) - Dynamic Field values are completely removed if one entry contains a dash.
 - 2013-09-30 Fixed bug#[9768](http://bugs.otrs.org/show_bug.cgi?id=9768) - Ticket Queue Overview Dashboard widget has no proper "no data" message.
 - 2013-09-27 Fixed bug#[9764](http://bugs.otrs.org/show_bug.cgi?id=9764) - ACL, Queue will ignored with customerID.
 - 2013-09-27 Fixed bug#[9762](http://bugs.otrs.org/show_bug.cgi?id=9762) - Queue View - S / M / L views - not saved after logout.
 - 2013-09-26 Fixed bug#[9580](http://bugs.otrs.org/show_bug.cgi?id=9580) - Time fields in TicketGetResponse Ticket element do not comply with xsd:DateTime format.
 - 2013-09-26 Fixed bug#[9748](http://bugs.otrs.org/show_bug.cgi?id=9748) - ProcessManagement: Duplicate articles in a process-ticket (TransitionAction).
 - 2013-09-26 Fixed bug#[9759](http://bugs.otrs.org/show_bug.cgi?id=9759) - Installer Error DB - max key length is 767 bytes.
 - 2013-09-26 Fixed bug#[9747](http://bugs.otrs.org/show_bug.cgi?id=9747) - Only first selected process displays the RichText editor.
 - 2013-09-25 Fixed bug#[9688](http://bugs.otrs.org/show_bug.cgi?id=9688) - ORA-01839 error occurs at DynamicField in TicketSearch.
 - 2013-09-25 Fixed bug#[9435](http://bugs.otrs.org/show_bug.cgi?id=9435) - Ticket not created if first dialog has CustomerID configured as 'do not show'.
 - 2013-09-25 Fixed bug#[9751](http://bugs.otrs.org/show_bug.cgi?id=9751) - TimeUnits are not accepted with a value of 0.
 - 2013-09-24 Fixed bug#[9750](http://bugs.otrs.org/show_bug.cgi?id=9750) - Problem with SSO and security restricted iframes in IE8+WXP by adding SysConfig option *DisableMSIFrameSecurityRestricted*.
    Thanks to Pawel @ ib.pl.
 - 2013-09-24 Added otrs.AddCustomerUser2Group.pl command line script.
 - 2013-09-20 Fixed bug#[9720](http://bugs.otrs.org/show_bug.cgi?id=9720) - CIC gives error message when clicking on phone ticket while that module is not registered.
 - 2013-09-20 Fixed bug#[9742](http://bugs.otrs.org/show_bug.cgi?id=9742) - Double close icon on TreeView for Customer Interface.

# 3.3.0 beta3 2013-09-24
 - 2013-09-20 Fixed bug#[9739](http://bugs.otrs.org/show_bug.cgi?id=9739) - Customer interface not working with MySQL 5.6.
 - 2013-09-12 Fixed bug#[9726](http://bugs.otrs.org/show_bug.cgi?id=9726) - otrs.DeleteCache.pl returns error state if cache was empty.
 - 2013-09-12 Fixed bug#[9728](http://bugs.otrs.org/show_bug.cgi?id=9728) - Bulk action (send email) ignores reply-to address from unknown customers.
 - 2013-09-10 Added md5sum.pl script in scripts/tools - to easily generate md5sums on platforms that need it (Windows).
 - 2013-09-09 Fixed bug#[9705](http://bugs.otrs.org/show_bug.cgi?id=9705) - Ticket search result screen is empty.
 - 2013-09-09 Speed up template rendering for large pages, thanks to Moritz Lenz (noris network AG).
 - 2013-09-06 Fixed bug#[9661](http://bugs.otrs.org/show_bug.cgi?id=9661) - Useless code in DynamicField backend.
 - 2013-09-06 Fixed bug#[9713](http://bugs.otrs.org/show_bug.cgi?id=9713) - Agent Ticket Search Results settings leads to Search screen.
 - 2013-09-06 Fixed bug#[9701](http://bugs.otrs.org/show_bug.cgi?id=9701) - Ticket overview Queue Sort Filter is missing.
 - 2013-09-06 Fixed bug#[8777](http://bugs.otrs.org/show_bug.cgi?id=8777) - 508 Compliance: No indication of the meaning of asterisks throughout the application.
 - 2013-09-06 Added Kernel::System::Environment, a module that has methods to get information about
   the current system. Features information about OS, database, perl and OTRS.

# 3.3.0 beta2 2013-09-10
 - 2013-09-05 Updated French translation, thanks to Dylan Oberson.
 - 2013-09-04 Fixed bug#[8173](http://bugs.otrs.org/show_bug.cgi?id=8173) - Dashboard Widget "Online" does not save state.
 - 2013-09-04 Fixed bug#[9188](http://bugs.otrs.org/show_bug.cgi?id=9188) - AgentTicketEmail always loads a signature, even if no queue is selected.
 - 2013-09-03 Updated CPAN module parent from 0.225 to 0.227.
 - 2013-09-03 Updated CPAN module Apache::DBI from 1.11 to 1.12.
 - 2013-09-03 Updated CPAN module JSON from 2.53 to 2.59.
 - 2013-09-03 Updated CPAN module JSON::PP from 2.27200 to 2.27202.
 - 2013-09-03 Updated CPAN module Locale::Codes from 3.24 to 3.26.
 - 2013-09-03 Updated CPAN module LWP from 6.04 to 6.05.
 - 2013-09-03 Updated CPAN module Net::IMAP::Simple from 1.2200 to 1.2201.
 - 2013-09-03 Updated CPAN module Text::CSV from 1.21 to 1.32.
 - 2013-09-02 Fixed bug#[9672](http://bugs.otrs.org/show_bug.cgi?id=9672) - Undecrypted HTML part displayed when viewing a multipart/alternative PGP encrypted HTML mail.
 - 2013-09-02 Fixed bug#[9691](http://bugs.otrs.org/show_bug.cgi?id=9691) - Customized widgets don't show columns after upgrade.
 - 2013-08-30 Fixed bug#[9646](http://bugs.otrs.org/show_bug.cgi?id=9646) - Selection of customers from autocomplete always adds them under To in new email ticket.
 - 2013-08-30 Fixed bug#[9670](http://bugs.otrs.org/show_bug.cgi?id=9670) - Ticket Number is removed wrongly from Article Subject if it contains a space.
 - 2013-08-30 Fixed bug#[9684](http://bugs.otrs.org/show_bug.cgi?id=9684) - Bulk select checkbox in AgentLinkObject does not work anymore.
 - 2013-08-30 Fixed bug#[9663](http://bugs.otrs.org/show_bug.cgi?id=9663) - Kernel\System\SysConfig.pm error message incomplete.
 - 2013-08-29 Fixed bug#[9431](http://bugs.otrs.org/show_bug.cgi?id=9431) - Terminology used for customer user contact.
 - 2013-08-28 Added config option to prevent storage of decrypted data in ArticleCheckPGP and SMIME.
 - 2013-08-26 Fixed a bug where using a CustomerKey other than UserLogin would not work
    in AdminCustomerUser.
 - 2013-08-26 Allow TicketSearch GI operation to also work for logged in customers.
 - 2013-08-20 Fixed bug#[9686](http://bugs.otrs.org/show_bug.cgi?id=9686) - Slowdown after heavy usage, thanks to Moritz Lenz (noris network AG)!

# 3.3.0 beta1 2013-08-27
 - 2013-08-22 Updated Spanish translation, thanks to Enrique Matías Sánchez!
 - 2013-08-15 Added possibility to negate postmaster filter settings, thanks to Renée Bäcker!
 - 2013-08-15 Refactored email handling code. Added support for POP3/TLS connections.
 - 2013-08-13 Added support for templates in phone and email ticket creation, forward, and inbound/outbound phone calls.
 - 2013-08-13 Added experimental support for Plack/PSGI (see http://plackperl.org).
 - 2013-08-12 Updated CKEditor to version 4.2.
 - 2013-08-08 The OTRS Scheduler Service should now always be running, and not just if there is a web service configured; because it will
    be used by more parts of OTRS than just the Generic Interface. The notification test to see if the Scheduler is running, is now always active.
 - 2013-08-05 Fixed bug#[9644](http://bugs.otrs.org/show_bug.cgi?id=9644) - External Ticket Number filter does not work with Ticket::SubjectFormat None.
 - 2013-07-25 Fixed bug#[7759](http://bugs.otrs.org/show_bug.cgi?id=7759) - Ticket watcher ToolBar position configuration isn't applied.
 - 2013-07-24 Added support for start processes in the Customer Interface.
 - 2013-07-24 Added support to restrict processes by ACLs.
 - 2013-07-23 Refactored AutoComplete feature (code cleanup, configuration cleanup).
 - 2013-07-22 Implemented bug#[8023](http://bugs.otrs.org/show_bug.cgi?id=8023) - Added possibility to set Owner or Responsible for tickets using Postmaster Filters.
 - 2013-07-18 Renamed CommonSearchFieldParameterBuild() to StatsSearchFieldParameterBuild() in Dynamic Fields BackendObject and Drivers.
 - 2013-07-18 Removed IsMatchable(), IsSortable(), IsAJAXUpdatable() from Dynamic Fields BackendObject and Drivers.
 - 2013-07-18 Added HasBehavior() to Dynamic Fields BackendObject and Drivers.
 - 2013-07-15 Fixed bug#[5412](http://bugs.otrs.org/show_bug.cgi?id=5412) - Text fields are sometimes required, sometimes optional.
 - 2013-07-12 Fixed bug#[7593](http://bugs.otrs.org/show_bug.cgi?id=7593) - GroupUserRoleMemberList returns user ID, not role name.
 - 2013-07-12 Fixed bug#[7885](http://bugs.otrs.org/show_bug.cgi?id=7885) - Links of 'merged' tickets are not displayed with a 'line-through'.
 - 2013-07-12 Fixed bug#[8629](http://bugs.otrs.org/show_bug.cgi?id=8629) - number of articles on the ticket.
 - 2013-07-12 Fixed bug#[9602](http://bugs.otrs.org/show_bug.cgi?id=9602) - Dynamic Field sorting in Customer Interface looks broken.
 - 2013-07-12 Added Recursive option to DirectoryRead() in MainObject.
 - 2013-07-12 Fixed bug#[8469](http://bugs.otrs.org/show_bug.cgi?id=8469) - Warning message about max_allowed_packet should be in the Package Manager.
 - 2013-07-12 Fixed bug#[5127](http://bugs.otrs.org/show_bug.cgi?id=5127) - Configurable listing of agent names in stead of hardcoded layout.
 - 2013-07-11 Fixed bug#[8588](http://bugs.otrs.org/show_bug.cgi?id=8588) - DynamicFieldOrderSrtg doesn't include field name.
 - 2013-07-11 Fixed bug#[7805](http://bugs.otrs.org/show_bug.cgi?id=7805) - Adding an agent requires a password in the frontend which is not neccessary from the backend.
 - 2013-07-11 Fixed bug#[5852](http://bugs.otrs.org/show_bug.cgi?id=5852) - Queue preselection via URL.
 - 2013-07-11 Fixed bug#[9051](http://bugs.otrs.org/show_bug.cgi?id=9051) - Unified field sizes.
 - 2013-07-10 Added Column Headers to SQL Box output.
 - 2013-07-10 Added GetColumnNames() function to DBObject.
 - 2013-07-10 Fixed bug#[9597](http://bugs.otrs.org/show_bug.cgi?id=9597) - Customer company cache data will not be deleted correctly when changing data.
 - 2013-07-09 Fixed bug#[9589](http://bugs.otrs.org/show_bug.cgi?id=9589) - AgentLinkObject does not show TreeView option for linkable ITSMConfigurationManagement objects.
 - 2013-07-09 Fixed bug#[9581](http://bugs.otrs.org/show_bug.cgi?id=9581) - No TreeView for Queues in AdminNotificationEvent.
 - 2013-07-09 Fixed bug#[9563](http://bugs.otrs.org/show_bug.cgi?id=9563) - Dashboard Calendar Floater shows numeric values.
 - 2013-07-08 Fixed bug#[9583](http://bugs.otrs.org/show_bug.cgi?id=9583) - Dynamic Fields of type Date have timestamp in notifications.
 - 2013-07-05 Changed Dynamic Field function name from CommonSearchFieldParameterBuild() to StatsSearchFieldParameterBuild() as it is now only used in statistics.
 - 2013-07-02 Fixed bug#[3436](http://bugs.otrs.org/show_bug.cgi?id=3436) - PGP attachments not decrypted.
 - 2013-07-02 Added Version() function to DBObject that reports back version of database.
 - 2013-07-01 Re-implemented auto refresh feature for dashboards on a per-widget basis. Widgets now refresh via AJAX instead of reloading the whole screen with meta refresh.
 - 2013-07-01 Added new config option 'AutoResponseForWebTickets' to turn off auto responses for new tickets created via the web interface (auto responses are active by default), thanks to Theo van Hoesel!
 - 2013-06-28 Added support for CustomerID in GenericInterface TicketCreate and TicketUpdate.
 - 2013-06-28 Fixed bug#[9233](http://bugs.otrs.org/show_bug.cgi?id=9233) - GenericInterface (TicketCreate and TicketUpdate can't set a defined CustomerID).
 - 2013-06-28 Fixed bug#[6502](http://bugs.otrs.org/show_bug.cgi?id=6502) - AdminQueueAutoResponse interface changes.
 - 2013-06-24 Added support for bcrypt, a strong password hashing algorithm.
 - 2013-06-24 Fixed incorrect multiline INSERT statements generated by the database drivers.
 - 2013-06-24 Fixed bug#[9543](http://bugs.otrs.org/show_bug.cgi?id=9543) - Log error if empty UserLogin in LostPasswordToken for Agent.
 - 2013-06-21 Fixed bug#[9540](http://bugs.otrs.org/show_bug.cgi?id=9540) - AgentTicketOwner doesn't activate PreviousOwner if new owner is selected.
 - 2013-06-21 Fixed bug#[7201](http://bugs.otrs.org/show_bug.cgi?id=7201) - Setting Ticket::Frontend::ListType is not respected
 - 2013-06-21 Fixed bug#[8200](http://bugs.otrs.org/show_bug.cgi?id=8200) - GenericAgent Ticket filter escalation times not working.
 - 2013-06-20 Added support to mark important articles.
 - 2013-06-18 Added graphical ACL editor feature.
 - 2013-06-18 Added SystemData backend - a key/value store for arbitrary data.
 - 2013-06-18 Added tree mode feature for dynamic fields (dropdown and multiselect).
 - 2013-06-14 Fixed bug#[9489](http://bugs.otrs.org/show_bug.cgi?id=9489) - Setting Ticket::DefaultNextMoveStateType name is confusing and not consistent with similar settings in other screens.
 - 2013-06-14 Fixed bug#[9251](http://bugs.otrs.org/show_bug.cgi?id=9251) - Sending a too large mail doesn't generate error message.
 - 2013-06-14 Fixed bug#[8859](http://bugs.otrs.org/show_bug.cgi?id=8859) - otrs.AddRole2Group.pl falsely informs a group is added to a role.
 - 2013-06-11 Added possibility to execute generic agent jobs for configured ticket events.
 - 2013-06-11 Added new feature to allow selecting services, queues, etc. from a JSTree view which is opened
    within an overlay (agent and customer frontend).
 - 2013-06-10 Added new feature that set a ticket to be displayed as an even on a ticket dashboard widget.
 - 2013-06-10 Fixed bug#[5759](http://bugs.otrs.org/show_bug.cgi?id=5759) - Company ID is listed twice in SQL field list.
 - 2013-06-10 Fixed bug#[9366](http://bugs.otrs.org/show_bug.cgi?id=9366) - Order of involved agents in AgentTicketNote is incorrect.
 - 2013-06-10 Fixed bug#[8973](http://bugs.otrs.org/show_bug.cgi?id=8973) - Updating Customer Login looses Service relations.
 - 2013-06-10 Added new version of ivory skin.
 - 2013-06-08 Added caching to search profiles.
 - 2013-06-07 Fixed bug#[8222](http://bugs.otrs.org/show_bug.cgi?id=8222) - List of recipients is not well structured.
 - 2013-06-07 Added events to CustomerUser and CustomerCompany objects.
    Tickets are now automatically updated when a CustomerID or Customer Login changes.
 - 2013-06-06 Fixed bug#[9503](http://bugs.otrs.org/show_bug.cgi?id=9503) - no connection header in soap responses.
 - 2013-06-05 Added sort functionality to ticket medium and preview overviews.
 - 2013-06-05 Fixed bug#[8475](http://bugs.otrs.org/show_bug.cgi?id=8475) - Screen refresh after action not always correct.
 - 2013-06-04 Added new dashboard widget that shows in a matrix form the number of tickets per state and per queue.
 - 2013-06-04 Added support to recognize numbers from external ticket systems in email subject and body to create follow-up articles in existing tickets.
 - 2013-06-04 Added support for storing customer user data in dynamic ticket fields on ticket create or customer user update.
 - 2013-05-31 Fixed bug#[9486](http://bugs.otrs.org/show_bug.cgi?id=9486) - Database error by invalid condition with parentheses in TicketSearch, thanks to Norihiro Tanaka!
 - 2013-05-31 Added multiple backends support for CustomerCompany, thanks to Cyrille @ belnet-ict!
 - 2013-05-30 Fixed bug#[7439](http://bugs.otrs.org/show_bug.cgi?id=7439) - Installer breaks on dash in database name or database user.
 - 2013-05-25 Fixed bug#[9381](http://bugs.otrs.org/show_bug.cgi?id=9381) - Replaced otrs.cleanup shell script with perl version.
 - 2013-05-25 Fixed bug#[4656](http://bugs.otrs.org/show_bug.cgi?id=4656) - Implement md5sum of message_ID field.
 - 2013-05-24 Improved performance of AgentTicketZoom for tickets with many articles, thanks to Norihiro Tanaka!
 - 2013-05-17 Added SMIME cache to speed up performance of SMIME certificate handling.
 - 2013-05-13 Improved handling of the CaseSensitive configuration. There is no CaseInsensitive configuration anymore.
 - 2013-05-11 Fixed bug#[9246](http://bugs.otrs.org/show_bug.cgi?id=9246) - ProcessManagement: TranstionAction error messages not sufficient enough.
 - 2013-04-30 Fixed bug#[9376](http://bugs.otrs.org/show_bug.cgi?id=9376) - Configurable automatic merge subject.
 - 2013-04-30 Fixed bug#[9372](http://bugs.otrs.org/show_bug.cgi?id=9372) - Configurable envelope sender address.
 - 2013-04-30 Added article link to every article box in ticket zoom.
 - 2013-04-30 Added possibility to specify relative dates for X-OTRS-State-PendingTime and X-OTRS-FollowUp-State-PendingTime in postmaster filters.
 - 2013-04-29 Fixed bug#[9339](http://bugs.otrs.org/show_bug.cgi?id=9339) - Poor stat generation performance with dynamic fields.
 - 2013-04-24 Added support to bin/otrs.SetPassword.pl to set passwords for customers
    and to generate passwords for logins.
 - 2013-04-08 Fixed bug#[8490](http://bugs.otrs.org/show_bug.cgi?id=8490) - No History record added when changing ticket title.
 - 2013-04-08 Removed File::Temp as it is core in perl 5.6.1 and up.
 - 2013-04-03 Removed Digest::SHA::PurePerl as Digest::SHA is core in perl 5.10.
 - 2013-04-02 Changed required perl version to 5.10.0.
 - 2013-03-29 Fixed bug#[8967](http://bugs.otrs.org/show_bug.cgi?id=8967) - Can't use Date or Timestamps in LinkObject.
 - 2013-03-29 Fixed bug#[9058](http://bugs.otrs.org/show_bug.cgi?id=9058) - AgentLinkObject.pm refers to non-existing dtl blocks.
 - 2013-03-29 Fixed bug#[7716](http://bugs.otrs.org/show_bug.cgi?id=7716) - Improve permissions on OTRS files.
 - 2013-03-27 Fixed bug#[8962](http://bugs.otrs.org/show_bug.cgi?id=8962) - RequestObject GetUploadAll Source 'File' option is unused
    and hard-coded to use /tmp.

# 3.2.10 2013-08-27
 - 2013-08-20 Fixed bug#[9617](http://bugs.otrs.org/show_bug.cgi?id=9617) - Event-based notifications are not sent for process-tickets.
 - 2013-08-14 Fixed bug#[9666](http://bugs.otrs.org/show_bug.cgi?id=9666) - Installing an invalid package cause an server error on package manager.
 - 2013-08-06 Fixed bug#[8408](http://bugs.otrs.org/show_bug.cgi?id=8408) - No separator used in CSV files if UserCSVSeparator enabled and not set.
 - 2013-08-01 Fixed bug#[9635](http://bugs.otrs.org/show_bug.cgi?id=9635) - article_search not updated on ticket merges.
 - 2013-07-31 Fixed bug#[9629](http://bugs.otrs.org/show_bug.cgi?id=9629) - ORA-936 error in AgentTicketSearch with some search clauses.
 - 2013-07-30 Fixed bug#[9631](http://bugs.otrs.org/show_bug.cgi?id=9631) - BuildSelection() Selected does not work if value contains strings that are HTML-escaped.
 - 2013-07-30 Fixed bug#[9630](http://bugs.otrs.org/show_bug.cgi?id=9630) - Dynamic Fields of type Date can record wrong date when TimeZoneSettings are used.
 - 2013-07-25 Fixed bug#[9316](http://bugs.otrs.org/show_bug.cgi?id=9316) - Under nginx CustomerInformationCenter search returns Bad Gateway.
 - 2013-07-25 Fixed bug#[9610](http://bugs.otrs.org/show_bug.cgi?id=9610) - When email does not specify charset, content is not displayed in IE10.
 - 2013-07-24 Fixed bug#[9622](http://bugs.otrs.org/show_bug.cgi?id=9622) - Actions in Small ticket overview don't work when cookies are turned off.
 - 2013-07-24 Updated Danish translation, thanks to Lars Jørgensen!
 - 2013-07-22 Fixed bug#[9541](http://bugs.otrs.org/show_bug.cgi?id=9541) - Package manager cannot use https proxy.
 - 2013-07-22 Fixed bug pull#[83](https://github.com/OTRS/otrs/pull/83) - Pagination next page link, thanks to Renée Bäcker.
 - 2013-07-18 Fixed bug#[9613](http://bugs.otrs.org/show_bug.cgi?id=9613) - CustomerTicketZoom shows JSLint error if no dynamic fields are configured
 - 2013-07-17 Updated Turkish translation, thanks to Sefer Şimşek @ Network Group!
 - 2013-07-17 Fixed bug#[9594](http://bugs.otrs.org/show_bug.cgi?id=9594) - No auto-reply sent with multiple From addresses in
    AgentTicketPhone on PostgreSQL and Oracle.
 - 2013-07-12 Fixed bug#[3434](http://bugs.otrs.org/show_bug.cgi?id=3434) - Validity of search time frame not checked by OTRS.
 - 2013-07-12 Fixed bug#[5475](http://bugs.otrs.org/show_bug.cgi?id=5475) - Incorrectly limited ticket list queries in queue view.
 - 2013-07-12 Fixed bug#[8667](http://bugs.otrs.org/show_bug.cgi?id=8667) - No error Message when trying to Merge Ticket with itself.
 - 2013-07-12 Fixed bug#[6985](http://bugs.otrs.org/show_bug.cgi?id=6985) - SMTPTLS backend requires username and password.
 - 2013-07-10 Fixed bug#[9598](http://bugs.otrs.org/show_bug.cgi?id=9598) - Typo in vacation message for German locale.
 - 2013-07-10 Fixed bug#[9595](http://bugs.otrs.org/show_bug.cgi?id=9595) - Incomplete page reload handling in merge and bounce.
 - 2013-07-10 Fixed bug#[5307](http://bugs.otrs.org/show_bug.cgi?id=5307) - Tickets can be raised against an invalid Customer Company.
 - 2013-07-10 Fixed bug#[9596](http://bugs.otrs.org/show_bug.cgi?id=9596) - On merge and bounce screens is confusing when fill or not 'To',  'Subject' and 'Body' fields.
 - 2013-07-10 Fixed bug#[9514](http://bugs.otrs.org/show_bug.cgi?id=9514) - Bulk action (send email) uses senders address instead of customer id.
 - 2013-07-09 Fixed bug#[3007](http://bugs.otrs.org/show_bug.cgi?id=3007) - CheckMXRecord and CheckEmailAddresses have no effect on AgentTicketBounce.
 - 2013-07-09 Fixed bug#[9512](http://bugs.otrs.org/show_bug.cgi?id=9512) - Database error for invalid date in AgentTicketSearch.
 - 2013-07-09 Fixed bug#[4465](http://bugs.otrs.org/show_bug.cgi?id=4465) - Spell checker ispell ignores some characters such German umlauts.
 - 2013-07-09 Fixed bug#[8428](http://bugs.otrs.org/show_bug.cgi?id=8428) - Bad usability of multiple sender/recipient feature.
 - 2013-07-09 Fixed bug#[9556](http://bugs.otrs.org/show_bug.cgi?id=9556) - Bounce and merge require notification recipient, subject and body even if no notification is sent.
 - 2013-07-09 Fixed bug#[9584](http://bugs.otrs.org/show_bug.cgi?id=9584) - No server side validation of To/Subject/Body in merge mask.
 - 2013-07-09 Fixed bug#[9578](http://bugs.otrs.org/show_bug.cgi?id=9578) - DynamicField sorting does not work on TicketSearch results in Customer Interface.
 - 2013-07-08 Fixed bug#[9579](http://bugs.otrs.org/show_nug.cgi?id=9579) - SOAP Serializer used in Kernel/GenericInterface/Transport/HTTP/SOAP.pm does not correctly set namespace.
 - 2013-07-08 Fixed bug#[7359](http://bugs.otrs.org/show_bug.cgi?id=7359) - Setting pending states via generic agent does not set pending time.
 - 2013-07-08 Fixed bug#[9577](http://bugs.otrs.org/show_bug.cgi?id=9577) - Engine translate date to dado from English to pt_BR.
 - 2013-07-08 Fixed bug#[5920](http://bugs.otrs.org/show_bug.cgi?id=5920) - Search restriction for dates is not displayed in customer interface.
 - 2013-07-08 Fixed bug#[8380](http://bugs.otrs.org/show_bug.cgi?id=8380) - Middle name not displayed in AdminCustomerUser.
 - 2013-07-05 Fixed bug#[9576](http://bugs.otrs.org/show_bug.cgi?id=9576) - GI TicketSearch Date and Date/Time dynamic fields are ignored.
 - 2013-07-04 Changed Dynamic Field SearchFieldParameterBuild() API, LayoutObject is now optional.
 - 2013-07-04 Fixed bug#[9573](http://bugs.otrs.org/show_bug.cgi?id=9573) - Date and DateTime dynamic fields not considered in GenericAgent Jobs.

# 3.2.9 2013-07-09
 - 2013-07-03 Fixed bug#[9561](http://bugs.otrs.org/show_bug.cgi?id=9561) - ACL restriction with CustomerID for DynamicFields at new Ticket screen not working.
 - 2013-07-02 Fixed bug#[8728](http://bugs.otrs.org/show_bug.cgi?id=8728) - Problem loading otrs-initial_insert.oracle.sql.
 - 2013-07-01 Fixed bug#[9481](http://bugs.otrs.org/show_bug.cgi?id=9481) - Possible to select invalid services in SLA admin screen.
 - 2013-06-29 Fixed bug#[9539](http://bugs.otrs.org/show_bug.cgi?id=9539) - Cannot send notification to a group of customers.
 - 2013-06-28 Fixed bug#[8273](http://bugs.otrs.org/show_bug.cgi?id=8273) - Copying text in preview mode not possible.
 - 2013-06-27 Fixed bug#[9011](http://bugs.otrs.org/show_bug.cgi?id=9011) - GenericInterface: New value after value mapping can't be 0.
 - 2013-06-25 Improved parameter quoting in various places.
 - 2013-06-24 Fixed bug#[9104](http://bugs.otrs.org/show_bug.cgi?id=9104) - Group permission for customer subset overwrites permissions for other customers.
 - 2013-06-21 Fixed bug#[9434](http://bugs.otrs.org/show_bug.cgi?id=9434) - Activities are not translated.
 - 2013-06-21 Fixed bug#[9261](http://bugs.otrs.org/show_bug.cgi?id=9261) - Ticket Inbound changes FROM in view.
 - 2013-06-21 Fixed bug#[9365](http://bugs.otrs.org/show_bug.cgi?id=9365) - AgentLinkObject screen does not provide a search restriction for ticket type.
 - 2013-06-19 Fixed bug#[9533](http://bugs.otrs.org/show_bug.cgi?id=9533) - Delete Inactive Process button not aligned.
 - 2013-06-18 Fixed bug#[9504](http://bugs.otrs.org/show_bug.cgi?id=9504) - wrong status after answer via customer portal.
 - 2013-06-18 Fixed bug#[9425](http://bugs.otrs.org/show_bug.cgi?id=9425) - Wrong created date for queue view.
 - 2013-06-18 Follow-up fix for bug#[8880](http://bugs.otrs.org/show_bug.cgi?id=8880) - No inline image shown if HTML email contains 'base' tag.
 - 2013-06-17 Updated Spanish translation, thanks to Enrique Matías Sánchez!
 - 2013-06-17 Fixed bug#[8112](http://bugs.otrs.org/show_bug.cgi?id=8112) - Display issue in FROM column of AgentTicketZoom with some agent names.
 - 2013-06-14 Fixed bug#[9524](http://bugs.otrs.org/show_bug.cgi?id=9524) - Uninitialized  value after step2 in TicketAccountedTime stats.
 - 2013-06-14 Fixed bug#[9511](http://bugs.otrs.org/show_bug.cgi?id=9511) - ProcessManagement: No SLA verification after Service update.
 - 2013-06-14 Fixed bug#[9513](http://bugs.otrs.org/show_bug.cgi?id=9513) - Frontend::ToolBarModule###11-CICSearchCustomerUser does not use settings of Frontend::Agent::CustomerSearch.
 - 2013-06-13 Fixed bug#[8719](http://bugs.otrs.org/show_bug.cgi?id=8719) - PasswordMin2Lower2UpperCharacters problem.

# 3.2.8 2013-06-18
 - 2013-06-13 Fixed bug#[9464](http://bugs.otrs.org/show_bug.cgi?id=9464) - Unique email address only checked during CustomerUserAdd, not during Update.
 - 2013-06-11 Fixed bug#[9497](http://bugs.otrs.org/show_bug.cgi?id=9497) - AgentTicketSearch logs a Uninitialized error message in Oracle.
 - 2013-06-11 Fixed bug#[9481](http://bugs.otrs.org/show_bug.cgi?id=9481) - Possible to select invalid services in SLA admin screen.
 - 2013-06-11 Fixed bug#[9451](http://bugs.otrs.org/show_bug.cgi?id=9451) - Possible to select invalid autoresponses for queues.
 - 2013-06-11 Fixed bug#[9516](http://bugs.otrs.org/show_bug.cgi?id=9516) - Field names for account signups in some languages are broken.
 - 2013-06-08 Fixed bug#[9501](http://bugs.otrs.org/show_bug.cgi?id=9501) - Missing values in GenericAgent ticket list for tickets without articles.
 - 2013-06-08 Fixed bug#[9447](http://bugs.otrs.org/show_bug.cgi?id=9447) - Empty line at PDF search result with process tickets (0 article).
 - 2013-06-07 Fixed bug#[9409](http://bugs.otrs.org/show_bug.cgi?id=9409) - If HTTP_USER_AGENT isn't set, error on Layout.pm.
 - 2013-06-07 Fixed bug#[9454](http://bugs.otrs.org/show_bug.cgi?id=9454) - Use of uninitialized value error in AgentTicketForward.pm, undef Next ticket state.
 - 2013-06-07 Fixed bug#[9493](http://bugs.otrs.org/show_bug.cgi?id=9493) - Use of uninitialized value error in AgentTicketPhone.pm on Ticket Split action.
 - 2013-06-06 Improved permission checks in AgentTicketWatcher.
 - 2013-06-04 Fixed bug#[7143](http://bugs.otrs.org/show_bug.cgi?id=7143) - "SFTP." gets rewritten to "Shttp://FTP."
 - 2013-06-04 Fixed bug#[9488](http://bugs.otrs.org/show_bug.cgi?id=9488) - Use of uninitialized value at OutofOffice setting in AgentPreferences.
 - 2013-05-31 Fixed bug#[9479](http://bugs.otrs.org/show_bug.cgi?id=9479) - ProcessManagement: Article and CustomerID should not be Hidden.
 - 2013-05-31 Fixed bug#[9491](http://bugs.otrs.org/show_bug.cgi?id=9491) - GenericAgent job update with dynamic fields sends Uninitialized value error.
 - 2013-05-31 Fixed bug#[9456](http://bugs.otrs.org/show_bug.cgi?id=9456) - Empty 'Dropdown' dynamic field value of GenericAgent job wont get used and stored.
 - 2013-05-31 Follow-up fix for bug#[9245](http://bugs.otrs.org/show_bug.cgi?id=9245) - Added translatable titles for transition buttons.
 - 2013-05-31 Updated Russian translation, thanks to Alexey Gluhov!
 - 2013-05-31 Fixed bug#[9245](http://bugs.otrs.org/show_bug.cgi?id=9245) - Improve user interaction on transitions.
 - 2013-05-31 Fixed bug#[9284](http://bugs.otrs.org/show_bug.cgi?id=9284) - Improve user experience of accordion widget.
 - 2013-05-31 Fixed bug#[9105](http://bugs.otrs.org/show_bug.cgi?id=9105) - Opening reply view crashes browsers on iPad 3.
 - 2013-05-28 Added '-a reinstall-all' feature to bin/otrs.PackageManager.pl.
 - 2013-05-27 Fixed bug#[9476](http://bugs.otrs.org/show_bug.cgi?id=9476) - AgentTicketZoom: translation of "split" into German language.
 - 2013-05-27 Fixed bug#[9459](http://bugs.otrs.org/show_bug.cgi?id=9459) - Creating a new transition action coming from the transition path view produces errors.
 - 2013-05-27 Fixed bug#[9458](http://bugs.otrs.org/show_bug.cgi?id=9458) - Double click on Transition opens error message.
 - 2013-05-24 Fixed bug#[9241](http://bugs.otrs.org/show_bug.cgi?id=9241) - Article ignored in article search index if body is almost empty.
    The StaticDB fulltext search backend is now fully configurable.
 - 2013-05-24 Fixed bug#[9462](http://bugs.otrs.org/show_bug.cgi?id=9462) - Package Management page timeout due to HTTPS disabled on Proxy connections.
 - 2013-05-22 Fixed bug#[9408](http://bugs.otrs.org/show_bug.cgi?id=9408) - A value of Dest inputed in CustomerTicketMessage isn't validated.
 - 2013-05-21 Fixed bug#[9418](http://bugs.otrs.org/show_bug.cgi?id=9418) - Incorrect decoding email subject and From token.
 - 2013-05-21 Fixed bug#[9448](http://bugs.otrs.org/show_bug.cgi?id=9448) - AgentTicketPhoneInbound/Outbound inserts Agent's personal email address into article "from".
 - 2013-05-17 Fixed bug#[9445](http://bugs.otrs.org/show_bug.cgi?id=9445) - ProcessManagement: Error Message: Need ServiceID or Name!.
 - 2013-05-17 Fixed bug#[9439](http://bugs.otrs.org/show_bug.cgi?id=9439) - ProcessManagement: Customer field value is not remembered after server error is detected.

# 3.2.7 2013-05-21
 - 2013-05-17 Updated Package Manager, that will ensure that packages to be installed
    meet the quality standards of OTRS Group. This is to guarantee that your package
    wasn’t modified, which may possibly harm your system or have an influence on the
    stability and performance of it. All independent package contributors will have
    to conduct a check of their Add-Ons by OTRS Group in order to take full advantage
    of the OTRS package verification.
 - 2013-05-16 Fixed bug#[9387](http://bugs.otrs.org/show_bug.cgi?id=9387) - Error in a condition with dynamic fields in NotificationEvent.
 - 2013-05-14 Fixed bug#[9286](http://bugs.otrs.org/show_bug.cgi?id=9286) - Ticket::ChangeOwnerToEveryone isn't functional, After a AJAX Load the setting is ignored.
 - 2013-05-14 Fixed bug#[7518](http://bugs.otrs.org/show_bug.cgi?id=7518) - Escalation Notify by not working properly (follow-up fix).
 - 2013-05-14 Fixed bug#[9410](http://bugs.otrs.org/show_bug.cgi?id=9410) - SessionID isn't added to URL when using ajax customer search without cookies active.
 - 2013-05-14 Fixed bug#[9419](http://bugs.otrs.org/show_bug.cgi?id=9419) - Process Management: List of available dialog fields lists Responsible
    even if feature is inactive.
 - 2013-05-11 Fixed bug#[9246](http://bugs.otrs.org/show_bug.cgi?id=9246) - ProcessManagement: TranstionAction error messages not sufficient enough.
 - 2013-05-07 Fixed bug#[9345](http://bugs.otrs.org/show_bug.cgi?id=9345) - OTRS exceeds 998 character limit in References Line of E-Mail Header.
 - 2013-05-07 Fixed bug#[7478](http://bugs.otrs.org/show_bug.cgi?id=7478) - Got an external answer to an internal mail.
 - 2013-05-07 Improved permission checks in AgentTicketPhone.
 - 2013-05-02 Fixed bug#[9360](http://bugs.otrs.org/show_bug.cgi?id=9360) - DynamicField Names shown in CSV output.
 - 2013-05-01 Fixed bug#[8880](http://bugs.otrs.org/show_bug.cgi?id=8880) - No inline image shown if HTML email contains 'base' tag.
 - 2013-04-30 Fixed bug#[9374](http://bugs.otrs.org/show_bug.cgi?id=9374) - Add more functions to rich text editor.
 - 2013-04-30 Fixed postmaster filter edit screen layout.
 - 2013-04-30 Fixed bug#[9358](http://bugs.otrs.org/show_bug.cgi?id=9358) - Date/Time DynamicFields are broken in CustomerInterface.
 - 2013-04-30 Fixed bug#[9384](http://bugs.otrs.org/show_bug.cgi?id=9384) - Problem with Method ServiceParentsGet of ServiceObject.
 - 2013-04-29 Fixed bug#[9371](http://bugs.otrs.org/show_bug.cgi?id=9371) - UserSalutation field in LDAP.pm fix.
 - 2013-04-29 Fixed bug#[8997](http://bugs.otrs.org/show_bug.cgi?id=8997) - Owner warnings translatable.
 - 2013-04-29 Fixed bug#[9375](http://bugs.otrs.org/show_bug.cgi?id=9375) - Extra colon at the end of recipient lists in forwarded message.
 - 2013-04-29 Updated Polish translation file, thanks to ib.pl!
 - 2013-04-29 Fixed bug#[9040](http://bugs.otrs.org/show_bug.cgi?id=9040) - CustomerTicketPrint crashes when no attributes are configured to be printed.
 - 2013-04-26 Added UnitTest for case sensivity parameter of customer databases
 - 2013-04-23 Fixed bug#[9362](http://bugs.otrs.org/show_bug.cgi?id=9362) - cannot redirect to external url containing & character.
 - 2013-04-23 Fixed bug#[7856](http://bugs.otrs.org/show_bug.cgi?id=7856) - Statistics only use non archived tickets.
 - 2013-04-23 Fixed bug#[9072](http://bugs.otrs.org/show_bug.cgi?id=9072) - Reply to email-internal includes customer users email in Cc. field.
 - 2013-04-22 Fixed bug#[9349](http://bugs.otrs.org/show_bug.cgi?id=9349) - SQL warnings on Oracle DB if more than 4k characters are sent to the database.
 - 2013-04-22 Fixed bug#[9353](http://bugs.otrs.org/show_bug.cgi?id=9353) - Customer Ticket Zoom shows owner login name instead of full name.
 - 2013-04-18 Fixed bug#[8599](http://bugs.otrs.org/show_bug.cgi?id=8599) - Problem with "[]" characters in name of attachment file.

# 3.2.6 2013-04-23
 - 2013-04-18 Fixed bug#[9310](http://bugs.otrs.org/show_bug.cgi?id=9310) - AgentTicketProcess has the same shortkey "o" as AgentTicketQueue.
 - 2013-04-18 Fixed bug#[9280](http://bugs.otrs.org/show_bug.cgi?id=9280) - Database upgrade procedure problems when upgrading database to 3.2 that
    has been upgraded from 2.4 previously.
 - 2013-04-16 Updated Hungarian translation, thanks to Csaba Németh!
 - 2013-04-15 Added Malay translation.
 - 2013-04-12 Fixed bug#[9264](http://bugs.otrs.org/show_bug.cgi?id=9264) - Dynamic ticket text fields are displayed with value "1" if enabled
    and displayed by default in ticket search screen.
 - 2013-04-12 Fixed bug#[8960](http://bugs.otrs.org/show_bug.cgi?id=8960) - AgentTicketSearch.pm SearchProfile problem.
 - 2013-04-12 Fixed bug#[9328](http://bugs.otrs.org/show_bug.cgi?id=9328) - Notification event does not work on process ticket.
 - 2013-04-11 Fixed broken process import.
 - 2013-04-11 Follow-up for bug#[9215](http://bugs.otrs.org/show_bug.cgi?id=9215) - Process import always creates new process.
    The overwrite optionwas removed again because of logical problems.
 - 2013-04-09 Added parameter "-t dbonly" to backup.pl to only backup the database
    (if files are backed up otherwise).
 - 2013-04-09 Fixed bug#[9302](http://bugs.otrs.org/show_bug.cgi?id=9302) - Process Management: Misleading description for activities without dialogs.
 - 2013-04-08 Fixed bug#[9182](http://bugs.otrs.org/show_bug.cgi?id=9182) - Customer Search Function -\> If you go into a ticket and go back you got not the search results
 - 2013-04-08 Fixed bug#[9297](http://bugs.otrs.org/show_bug.cgi?id=9297) - customer information widget losing data
 - 2013-04-08 Fixed bug#[9244](http://bugs.otrs.org/show_bug.cgi?id=9244) - Process Management: Transitions on Activities does not scale well
 - 2013-04-08 Fixed bug#[9287](http://bugs.otrs.org/show_bug.cgi?id=9287) - Process Management: strange placement of target point for new transitions.
 - 2013-04-08 Fixed bug#[9294](http://bugs.otrs.org/show_bug.cgi?id=9294) - Process Management: Activity hover window not displayed properly if
    activity is very close to bottom canvas border.
 - 2013-04-08 Fixed bug#[9314](http://bugs.otrs.org/show_bug.cgi?id=9314) - Process Management: Unexpected redirection after creating a new process.
 - 2013-04-08 Fixed bug#[9312](http://bugs.otrs.org/show_bug.cgi?id=9312) - LinkObject permission check problem.

# 3.2.5 2013-04-09
 - 2013-04-04 Fixed bug#[9313](http://bugs.otrs.org/show_bug.cgi?id=9313) - No such file or directory in otrs.SetPermission.pl.
 - 2013-04-04 Updated Brazilian Portugese translation, thanks to Alexandre!
 - 2013-04-04 Fixed bug#[9306](http://bugs.otrs.org/show_bug.cgi?id=9306) - Auto Response fails when ticket is created from Customer Interface and
    last name contains a comma.
 - 2013-04-04 Fixed bug#[9308](http://bugs.otrs.org/show_bug.cgi?id=9308) - Impossible to create a new stats report with absolute period.
 - 2013-04-03 Fixed bug#[9307](http://bugs.otrs.org/show_bug.cgi?id=9307) - Packages not compatible with 3.2.4 listed as available in Package Manager.
 - 2013-04-02 Fixed bug#[9198](http://bugs.otrs.org/show_bug.cgi?id=9198) - Linked search with fulltext AND additional attributes.
 - 2013-03-28 Fixed bug#[9298](http://bugs.otrs.org/show_bug.cgi?id=9298) - version.pm not found on perl 5.8.x.
 - 2013-03-27 Fixed bug#[9295](http://bugs.otrs.org/show_bug.cgi?id=9295) - Article dynamic field is not searchable.
 - 2013-03-27 Fixed bug#[9288](http://bugs.otrs.org/show_bug.cgi?id=9288) - DynamicField Content overwrites TicketTitle for Links from Dynamic Fields.

# 3.2.4 2013-04-02
 - 2013-03-21 Fixed bug#[9279](http://bugs.otrs.org/show_bug.cgi?id=9279) - Inaccurate German translation of ,,Priority Update''.
 - 2013-03-21 Fixed bug#[9257](http://bugs.otrs.org/show_bug.cgi?id=9257) - No notifications to agents with out-of-office set but period not reached.
 - 2013-03-21 Fixed bug#[1689](http://bugs.otrs.org/show_bug.cgi?id=1689) - Allow bin/SetPermissions.sh to follow symlink for OTRS_HOME.
 - 2013-03-21 Fixed bug#[8981](http://bugs.otrs.org/show_bug.cgi?id=8981) - Tickets reopened via customer interface are locked to invalid agents.
 - 2013-03-19 Fixed bug#[9242](http://bugs.otrs.org/show_bug.cgi?id=9242) - ProcessManagement: TransitionAction TicketStateSet does not allow to set a pending time.
 - 2013-03-19 Fixed bug#[9247](http://bugs.otrs.org/show_bug.cgi?id=9247) - ProcessManagement: Transitions Actions always use actual user permissions.
 - 2013-03-18 Fixed bug#[9254](http://bugs.otrs.org/show_bug.cgi?id=9254) - No Sorting in Accordion for Activties, Activity Dialog, Transitions and Transition Actions.
 - 2013-03-18 Improved permission checks in LinkObject.
 - 2013-03-18 Fixed bug#[9252](http://bugs.otrs.org/show_bug.cgi?id=9252) - Type of linking displayed wrong and also updated wrong in transitions.
 - 2013-03-18 Fixed bug#[9255](http://bugs.otrs.org/show_bug.cgi?id=9255) - Email is sent to customer, when agents email address is similar
    but not identical.
 - 2013-03-18 Updated Norwegian translation, thanks to Espen Stefansen.
 - 2013-03-18 Updated Czech translation, thanks to Peter Pruchnerovic.
 - 2013-03-18 Fixed bug#[9215](http://bugs.otrs.org/show_bug.cgi?id=9215) - Process import always creates new process. Now there is a new option
    "overwrite existing entities" for the process import.
 - 2013-03-15 Fixed bug#[4716](http://bugs.otrs.org/show_bug.cgi?id=4716) - Logout page should use ProductName instead of 'OTRS'.
 - 2013-03-15 Fixed bug#[9249](http://bugs.otrs.org/show_bug.cgi?id=9249) - Warning not to use internal articles in customer frontend
    shown on agent interface also.
 - 2013-03-14 Fixed bug#[9191](http://bugs.otrs.org/show_bug.cgi?id=9191) - When ticket types are restricted, first available type is selected
    in AgentTicketActionCommon-based screens.
 - 2013-03-12 Updated Chinese translation, thanks to Never Min!
 - 2013-03-12 Updated Turkish translation, thanks to Sefer Simsek / Network Group!

# 3.2.3 2013-03-12
 - 2013-03-05 Fixed bug#[9221](http://bugs.otrs.org/show_bug.cgi?id=9221) - Got error log message when customer user take activity dialog operation in customer interface.
 - 2013-03-04 Fixed bug#[8727](http://bugs.otrs.org/show_bug.cgi?id=8727) - Webservices can be created with an invalid/incomplete configuration.
 - 2013-03-02 Fixed bug#[9214](http://bugs.otrs.org/show_bug.cgi?id=9214) - IE10: impossible to open links from rich text articles.
 - 2013-03-01 Fixed bug#[9218](http://bugs.otrs.org/show_bug.cgi?id=9218) - Cannot use special characters in TicketHook.
 - 2013-02-28 Fixed bug#[9056](http://bugs.otrs.org/show_bug.cgi?id=9056) - Unused SysConfig option Ticket::Frontend::CustomerInfoQueueMaxSize.
 - 2013-02-28 Added the possibility to use ticket data in dynamic fields links.
 - 2013-02-28 Fixed bug#[8764](http://bugs.otrs.org/show_bug.cgi?id=8764) - Added @ARGV encoding to command line scripts.
 - 2013-02-28 Fixed bug#[9189](http://bugs.otrs.org/show_bug.cgi?id=9189) - Executing DBUpdate-to-3.2.pl as root user leaves file permissions on ZZZAuto.pm in incorrect state.
 - 2013-02-27 Fixed bug#[9196](http://bugs.otrs.org/show_bug.cgi?id=9196) - ProcessManagement: Internal Server Error for "Ended" process zoom in Customer Interface.
 - 2013-02-26 Fixed bug#[9202](http://bugs.otrs.org/show_bug.cgi?id=9202) - ProcessManagement: ActivityDialog Admin GUI should not let internal article types for Customer Interface.
 - 2013-02-26 Fixed bug#[9193](http://bugs.otrs.org/show_bug.cgi?id=9193) - Process Management: (First) article filled in in customer frontend causes "Need ArticleTypeID!" error.
 - 2013-02-26 Follow-up fix for bug#[8533](http://bugs.otrs.org/show_bug.cgi?id=8533) apache will not start on Fedora.
 - 2013-02-26 Fixed bug#[9172](http://bugs.otrs.org/show_bug.cgi?id=9172) - Generic Interface does not work on IIS 7.0.
 - 2013-02-25 Updated French language translation, thanks to Raphaël Doursenaud!
 - 2013-02-23 Updated Hungarian language translation, thanks to Németh Csaba!
 - 2013-02-21 Updated Czech language translation, thanks to Katerina Bubenickova!
 - 2013-02-20 Fixed bug#[8865](http://bugs.otrs.org/show_bug.cgi?id=8865) - Additional empty data column in statistics CSV-Output.
 - 2013-02-19 Fixed bug#[4056](http://bugs.otrs.org/show_bug.cgi?id=4056) - Delete S/MIME Certificate via AdminSMIME does not update CustomerUserPreferences.
 - 2013-02-18 Fixed bug#[9128](http://bugs.otrs.org/show_bug.cgi?id=9128) - OTRS uses internal sub of Locale::Codes::Country which causes trouble for
    Debian.
 - 2013-02-18 Fixed bug#[9173](http://bugs.otrs.org/show_bug.cgi?id=9173) - ProcessManagement: Very right aligned activities can't display assigned dialogs.
 - 2013-02-18 Fixed bug#[9174](http://bugs.otrs.org/show_bug.cgi?id=9174) - Process Management: Save / Save and finish / Cancel inside process diagram canvas.
 - 2013-02-15 Fixed bug#[9155](http://bugs.otrs.org/show_bug.cgi?id=9155) - SMIME: DefaultSignKey not selected in AJAX refreshes.
 - 2013-02-15 Fixed bug#[9164](http://bugs.otrs.org/show_bug.cgi?id=9164) - ProcessManagement: Default values of assigned hidden activity dialogs not considered.
 - 2013-02-15 Fixed bug#[7312](http://bugs.otrs.org/show_bug.cgi?id=7312) - otrs.SetPermissions.pl does not take scripts in $OTRSHOME/Custom into account.
 - 2013-02-15 Fixed bug#[7237](http://bugs.otrs.org/show_bug.cgi?id=7237) - Better Shortening Logic in Ascii2Html.
 - 2013-02-15 Fixed bug#[9139](http://bugs.otrs.org/show_bug.cgi?id=9139) - Context sensitive search in CIC doesn't open CIC search.
 - 2013-02-14 Fixed bug#[9087](http://bugs.otrs.org/show_bug.cgi?id=9087) - ProcessManagement: AgentTicketProcess doesn't show multi level queue structure.
 - 2013-02-14 Follow-up fix for bug#[9158](http://bugs.otrs.org/show_bug.cgi?id=9158) - ProcessManagement: Priority field error message: Need Priority or PriorityID!.

# 3.2.2 2013-02-19
 - 2013-02-14 Fixed bug#[9171](http://bugs.otrs.org/show_bug.cgi?id=9171) - ProcessManagement: AgentTicketProcess lists all state types.
 - 2013-02-14 Follow-up fix for bug#[4513](http://bugs.otrs.org/show_bug.cgi?id=4513) - Password and Username are added
    automatically by the browser in AdminUser dialog.
 - 2013-02-14 Updated Spanish translation, thanks to Enrique Matías Sánchez!
 - 2013-02-14 Fixed bug#[9157](http://bugs.otrs.org/show_bug.cgi?id=9157) - ProcessManagement: Activity labels not aligned well.
 - 2013-02-14 Fixed bug#[9156](http://bugs.otrs.org/show_bug.cgi?id=9156) - ProcessManagement: Transition Condition Fields cannot be removed correctly.
 - 2013-02-14 Fixed bug#[9160](http://bugs.otrs.org/show_bug.cgi?id=9160) - ProcessManagement: Path dialog looses data after editing transition actions.
 - 2013-02-13 Fixed bug#[9159](http://bugs.otrs.org/show_bug.cgi?id=9159) - ProcessManagement: Date fields are activated by default.
 - 2013-02-13 Added display restriction for field "CustomerID" in Process Management Activity
    Dialogs to only be shown as mandatory or not shown.
 - 2013-02-13 Fixed bug#[9150](http://bugs.otrs.org/show_bug.cgi?id=9150) - Process Management: CustomerUser field not indicated as required field.
 - 2013-02-13 Fixed bug#[9158](http://bugs.otrs.org/show_bug.cgi?id=9158) - ProcessManagement: Priority field error message: Need Priority or PriorityID!
 - 2013-02-13 Fixed bug#[9162](http://bugs.otrs.org/show_bug.cgi?id=9162) - Setting the start day of the week for the datepicker to Sunday does not work.
 - 2013-02-13 Fixed bug#[9127](http://bugs.otrs.org/show_bug.cgi?id=9127) - Problem with CustomerPanelOwnSelection.
 - 2013-02-12 Added new Canadian French translation, thanks to Evans Bernier / CDE Solutions Informatique!
 - 2013-02-12 Fixed bug#[5492](http://bugs.otrs.org/show_bug.cgi?id=5492) - Need Template or TemplateFile Param error message after activating AgentInfo.
 - 2013-02-12 Fixed bug#[9138](http://bugs.otrs.org/show_bug.cgi?id=9138) - Unused X-OTRS-Info header in SysConfig.
 - 2013-02-11 Fixed bug#[9117](http://bugs.otrs.org/show_bug.cgi?id=9117) - CustomerUpdate history entry added even if customer user has not
    been updated.
 - 2013-02-11 Fixed bug#[9006](http://bugs.otrs.org/show_bug.cgi?id=9006) - Labels and values are misaligned.
 - 2013-02-11 Fixed bug#[9132](http://bugs.otrs.org/show_bug.cgi?id=9132) - Button to create new ticket appears in Customer Interface although
    ticket creation is disabled.
 - 2013-02-08 Added Patch/Workaround for CPAN MIME::Parser v5.503 that prevent the trimming of empty
    lines that lead to inconsistencies between signed and actual email contents
 - 2013-02-08 Fixed bug#[9146](http://bugs.otrs.org/show_bug.cgi?id=9146) - Signed SMIME mails with altered content shows a not clear message.
 - 2013-02-08 Fixed bug#[9145](http://bugs.otrs.org/show_bug.cgi?id=9145) - SMIME sign verification errors are not displayed in TicketZoom.
 - 2013-02-07 Fixed bug#[9140](http://bugs.otrs.org/show_bug.cgi?id=9140) - Postmaster Filter for empty subjects does not work.
 - 2013-02-07 Fixed bug#[8024](http://bugs.otrs.org/show_bug.cgi?id=8024) - WYSIWYG editor does not get correct language information.
 - 2013-02-07 Fixed bug#[9135](http://bugs.otrs.org/show_bug.cgi?id=9135) - Can't upgrade databases that have been changed from MyISAM \> InnoDB.
 - 2013-02-07 Fixed bug#[9125](http://bugs.otrs.org/show_bug.cgi?id=9125) - AgentTicketSearch dialog does not expand when choosing more search criteria.
 - 2013-02-06 Fixed bug#[9118](http://bugs.otrs.org/show_bug.cgi?id=9118) - TicketDynamicFieldUpdate history entry added even if value has not
    been updated.
 - 2013-02-06 Fixed bug#[9134](http://bugs.otrs.org/show_bug.cgi?id=9134) - Sidebar columns on some screens don't support more than one widget.
 - 2013-02-06 Fixed bug#[4662](http://bugs.otrs.org/show_bug.cgi?id=4662) - Unable to save article with '0' as only content.
 - 2013-02-05 Fixed bug#[9068](http://bugs.otrs.org/show_bug.cgi?id=9068) - ProcessManagement: Entity Names not shown in Deletion Dialogs.
 - 2013-02-05 Fixed bug#[9121](http://bugs.otrs.org/show_bug.cgi?id=9121) - Filenames with Unicode NFD are incorrectly reported as NFC by Main::DirectoryRead().
 - 2013-02-05 Fixed bug#[9126](http://bugs.otrs.org/show_bug.cgi?id=9126) - ProcessManagement: both article fields must be filled.
 - 2013-02-05 Added bug#[1197](http://bugs.otrs.org/show_bug.cgi?id=1197) - Feature enhancement: Link tickets at "Follow up".
 - 2013-02-05 Fixed bug#[9108](http://bugs.otrs.org/show_bug.cgi?id=9108) - Check for opened/closed tickets not working with Ticket::SubjectFormat = Right.
 - 2013-02-02 Made Web Installer reload after writing Config.pm under PerlEx.
 - 2013-02-01 Added restriction to TransitionAction TicketArticleCrete to do not allow the creation
    email article types.
 - 2013-02-01 Fixed bug#[9112](http://bugs.otrs.org/show_bug.cgi?id=9112) - ProcessManagment: TransitionAction TicketActicleCreate should not
    accept email type articles.
 - 2013-02-01 Fixed bug#[8839](http://bugs.otrs.org/show_bug.cgi?id=8839) - DateChecksum followup doesn't get correctly SystemID.
 - 2013-01-31 Fixed bug#[9111](http://bugs.otrs.org/show_bug.cgi?id=9111) - ProcessManagement: Empty Service or SLA causes an error.
 - 2013-01-31 Fixed bug#[9077](http://bugs.otrs.org/show_bug.cgi?id=9077) - Process Management: TicketType not available as field for activity.
    dialogs.
 - 2013-01-31 Updated Finnish translation, thanks to Niklas Lampén!
 - 2013-01-31 Updated Italian translation, thanks to Massimo Bianchi!
 - 2013-01-31 Updated Portugese (Brazilian) translation, thanks to Alexandre!
 - 2013-01-31 Updated Russian translation, thanks to Vadim Goncharov!
 - 2013-01-31 Added script otrs.MySQLInnoDBSwitch.pl to switch all database tables from MyISAM
    to InnoDB on the fly.
 - 2013-01-31 Added bin/otrs.ExecuteDatabaseXML.pl to directly execute Database DDL XML files on
    the OTRS database.
 - 2013-01-30 Fixed bug#[9097](http://bugs.otrs.org/show_bug.cgi?id=9097) - ProcessManagement: Uninitialized value after Ticket is created if
    notification event is triggered.
 - 2013-01-30 Fixed bug#[9101](http://bugs.otrs.org/show_bug.cgi?id=9101) - Not possible to create dropdown with autocomplete attribute.
 - 2013-01-29 Fixed bug#[9095](http://bugs.otrs.org/show_bug.cgi?id=9095) - ProcessManagement: Service field does not show default services.
 - 2013-01-29 Fixed bug#[9096](http://bugs.otrs.org/show_bug.cgi?id=9096) - All services list is shown instead of only default services.
 - 2013-01-29 Fixed bug#[9088](http://bugs.otrs.org/show_bug.cgi?id=9088) - ProcessManagement: Service field is not displayed in
    AgentTicketProcess.
 - 2013-01-29 Updated CPAN module MIME::Tools to version 5.503, keeping an OTRS patch in MIME::Words.
 - 2013-01-29 Fixed bug#[9092](http://bugs.otrs.org/show_bug.cgi?id=9092) - Problem running DBUpdate-to-3.2.mysql.sql on InnoDB.
 - 2013-01-28 Fixed bug#[9078](http://bugs.otrs.org/show_bug.cgi?id=9078) - Fields of type "email" loosing style format.
 - 2013-01-28 Fixed bug#[9090](http://bugs.otrs.org/show_bug.cgi?id=9090) - ProcessManagement popup dialogs cannot be saved by pressing Enter.
 - 2013-01-28 Fixed bug#[8470](http://bugs.otrs.org/show_bug.cgi?id=8470) - otrs.GenericAgent.pl reports: Can't open
    '/opt/otrs/otrs\_vemco/var/tmp/CacheFileStorable/DynamicField/f3b7e10730fb6c9cab5ae0e7f7e034f3'.
 - 2013-01-28 Fixed bug#[7678](http://bugs.otrs.org/show_bug.cgi?id=7678) - SecureMode does not do what it should.
 - 2013-01-28 Fixed bug#[5158](http://bugs.otrs.org/show_bug.cgi?id=5158) - Unsafe UTF8 handling in Encode module.
 - 2013-01-28 Fixed bug#[8959](http://bugs.otrs.org/show_bug.cgi?id=8959) - AgentTicketResponsible Responsible Changed not checked/forced.
 - 2013-01-28 Fixed bug#[9089](http://bugs.otrs.org/show_bug.cgi?id=9089) - Activities and transitions with HTML special characters are
    not displayed correctly.
 - 2013-01-28 Added new translation for Spanish (Colombia), thanks to John Edisson Ortiz Roman!
 - 2013-01-28 Updated Finnish translation, thanks to Niklas Lampén!

# 3.2.1 2013-01-29
 - 2013-01-24 Updated Dutch translation.
 - 2013-01-24 Added test to check if there are problems with the MySQL storage engine used
    in OTRS tables to bin/otrs.CheckModules.pl.
 - 2013-01-23 Fixed bug#[9082](http://bugs.otrs.org/show_bug.cgi?id=9082) - Process Management: Wrong popup redirect handling to Process Path
    from TransitionAction.
 - 2013-01-22 Fixed bug#[9065](http://bugs.otrs.org/show_bug.cgi?id=9065) - Process Management: Service and SLA fields are always shown in ActivityDialogs.
 - 2013-01-21 Fixed bug#[9054](http://bugs.otrs.org/show_bug.cgi?id=9054) - Link Object deletes all links under certain conditions.
 - 2013-01-21 Fixed bug#[9059](http://bugs.otrs.org/show_bug.cgi?id=9059) - Process Management: transition actions module field too short.
 - 2013-01-21 Fixed bug#[9066](http://bugs.otrs.org/show_bug.cgi?id=9066) - ProcessManagement: edit links not displayed in popups.
 - 2013-01-21 Fixed an issue where default values would be used erroneously for ActivityDialog
    fields where a value was already present.
 - 2013-01-21 Fixed bug#[9052](http://bugs.otrs.org/show_bug.cgi?id=9052) - Accordion is reset after submitting a popup.
 - 2013-01-21 Fixed bug#[9067](http://bugs.otrs.org/show_bug.cgi?id=9067) - New process ticket: state selection empty after AJAX reload.

# 3.2.0 rc1 2013-01-22
 - 2013-01-18 Fixed bug#[8944](http://bugs.otrs.org/show_bug.cgi?id=8944) - do not backup the cache.
 - 2013-01-17 Updated Finnish translation, thanks to Niklas Lampén!
 - 2013-01-16 Fixed bug#[8929](http://bugs.otrs.org/show_bug.cgi?id=8929) - Fix problems with empty ticket search results while
    Ticket::Frontend::AgentTicketSearch###ExtendedSearchCondition is inactive.
 - 2013-01-16 Fixed bug#[9057](http://bugs.otrs.org/show_bug.cgi?id=9057) - Generating a PDF with bin/otrs.GenerateStats.pl produces lots
    of warnings.
 - 2013-01-15 Fixed bug#[9050](http://bugs.otrs.org/show_bug.cgi?id=9050) - Process Management: ticket title disappears.
 - 2013-01-15 Fixed bug#[9049](http://bugs.otrs.org/show_bug.cgi?id=9049) - Process Management: process with a starting AD for CustomerInterface
    only breaks in AgentInterface.
 - 2013-01-15 Fixed problems with YAML parsing long lines. Added new module dependency YAML::XS.
 - 2013-01-15 Updated CPAN module Mozilla::CA to version 20130114.
 - 2013-01-15 Updated CPAN module MailTools to version 2.12.
 - 2013-01-15 Updated CPAN module Locale::Codes to version 3.24.
 - 2013-01-15 Updated CPAN module Digest::SHA::PurePerl to version 5.81.
 - 2013-01-15 Updated CPAN module Authen::SASL to version 2.16.
 - 2013-01-14 Fixed bug#[9044](http://bugs.otrs.org/show_bug.cgi?id=9044) - ProcessManagement: Transition is duplicated on redraw.
 - 2013-01-14 Fixed bug#[9035](http://bugs.otrs.org/show_bug.cgi?id=9035) - Event Based mails, triggered by a process ticket, have no sender.
 - 2013-01-14 Fixed bug#[9043](http://bugs.otrs.org/show_bug.cgi?id=9043) - ProcessManagement: Transitions without EndActivity are not correctly removed.
 - 2013-01-14 Fixed bug#[9045](http://bugs.otrs.org/show_bug.cgi?id=9045) - Process Management: Activity Dialog field order lost.
 - 2013-01-14 Fixed bug#[9042](http://bugs.otrs.org/show_bug.cgi?id=9042) - Add X-Spam-Score to Ticket.xml.
 - 2013-01-14 Fixed bug#[9047](http://bugs.otrs.org/show_bug.cgi?id=9047) - HistoryTicketGet caches info on disk directly.
 - 2013-01-11 The Phone Call Outbound and Inbound buttons where moved from the Article menu to
    the Ticket menu in the TicketZoom screen for the agent interface, in order to be able to
    register phone calls on tickets without articles.
 - 2013-01-11 Fixed bug#[9036](http://bugs.otrs.org/show_bug.cgi?id=9036) - Process# hook does not register an incoming email to the process.
 - 2013-01-11 The names of the TransitionActions were changed to make them more consistent.
    Please check your processes if you have already defined some which use TransitionActions.
    Also, the parameter names of the TransitionAction TicketQueueSet and TicketTypeSet were changed.
 - 2013-01-11 Fixed bug#[4513](http://bugs.otrs.org/show_bug.cgi?id=4513) - Password and Username are added automatically by the browser
    in AdminUser dialog.
 - 2013-01-11 Fixed bug#[8923](http://bugs.otrs.org/show_bug.cgi?id=8923) - Alert message shown, if parent window is reloaded while
     bulk action popup is open.
 - 2013-01-11 Fixed bug#[9037](http://bugs.otrs.org/show_bug.cgi?id=9037) - TransitionAction TicketQueueSet parameters does not follow same name
    convention as others.
 - 2013-01-11 Fixed bug#[9032](http://bugs.otrs.org/show_bug.cgi?id=9032) - TransitionAction module name notation.
 - 2013-01-10 Fixed bug#[9029](http://bugs.otrs.org/show_bug.cgi?id=9029) - Switching on Queue in AgentTicketActionCommon will always result in
    a move.
 - 2013-01-09 Fixed bug#[9031](http://bugs.otrs.org/show_bug.cgi?id=9031) - ProcessManagement Transition condition with regexp fails.
 - 2013-01-09 Fixed bug#[9030](http://bugs.otrs.org/show_bug.cgi?id=9030) - Wrong handling of Invalid YAML in Scheduler Tasks.
 - 2013-01-07 Fixed bug#[8966](http://bugs.otrs.org/show_bug.cgi?id=8966) - Cc and Bcc lists are hidden if one entry is deleted.
 - 2013-01-07 Fixed bug#[8993](http://bugs.otrs.org/show_bug.cgi?id=8993) - OTRS JavaScript does not handle session timeouts gracefully.
 - 2013-01-07 Updated Polish translation, thanks to Pawel @ ib.pl!
 - 2013-01-04 Fixed bug#[9015](http://bugs.otrs.org/show_bug.cgi?id=9015) - otrs.CheckModules.pl reports module as not installed
    if prerequisite is missing.
 - 2013-01-04 Follow-up fix for bug#[8805](http://bugs.otrs.org/show_bug.cgi?id=8805) - Cron missing as RPM dependency on Red Hat Enterprise Linux.
    Changed dependency on `anacron` to `vixie-cron` on RHEL5.
 - 2013-01-04 Removed CPAN module Net::IMAP::Simple::SSL, this can be handled by
    Net::IMAP::Simple now.
 - 2013-01-04 Updated CPAN module Net::IMAP::Simple to version 1.2034.
 - 2013-01-04 Configured `mod_deflate` in bundled Apache configuration file.

# 3.2.0 beta5 2013-01-08
 - 2013-01-02 Fixed bug#[9020](http://bugs.otrs.org/show_bug.cgi?id=9020) - Generic Ticket Connector does not support attachments with
    ContentType without charset.
 - 2013-01-02 Fixed bug#[8545](http://bugs.otrs.org/show_bug.cgi?id=8545) - Attachment download not possible if pop up of another action is open.
 - 2012-12-27 Fixed bug#[8990](http://bugs.otrs.org/show_bug.cgi?id=8990) - Autocompletion returns stale requests.
 - 2012-12-20 Fixed bug#[9009](http://bugs.otrs.org/show_bug.cgi?id=9009) - Empty Multiselect Dynamic Fields provokes an error.
 - 2012-12-19 Fixed bug#[8999](http://bugs.otrs.org/show_bug.cgi?id=8999) - Upcoming event with duplicate dates not displayed in Dashboard.
 - 2012-12-17 Fixed bug#[8457](http://bugs.otrs.org/show_bug.cgi?id=8457) - Error if accessing AgentTicketSearch from AgentTicketPhone in IE8.
 - 2012-12-17 Fixed bug#[8589](http://bugs.otrs.org/show_bug.cgi?id=8589) - Bulk-Action not possible for single ticket.
 - 2012-12-17 Fixed bug#[8695](http://bugs.otrs.org/show_bug.cgi?id=8695) - Table head of Customer Ticket History does not resize on window resize.
 - 2012-12-13 Fixed bug#[8533](http://bugs.otrs.org/show_bug.cgi?id=8533) - Apache will not start if you use mod\_perl on Fedora 16 or 17.
 - 2012-12-12 Fixed bug#[8950](http://bugs.otrs.org/show_bug.cgi?id=8950) - "Sign" and "crypt" are displayed two times in AgentTicketCompose.
 - 2012-12-12 Added RPM specfiles for RHEL5 and RHEL6.
 - 2012-12-12 Fixed bug#[8977](http://bugs.otrs.org/show_bug.cgi?id=8977) - ArticleStorageFS fails after upgrade beta3 \>\> beta4.
 - 2012-12-11 Fixed bug#[5644](http://bugs.otrs.org/show_bug.cgi?id=5644) - In Article Zoom, Article Filter: Reset Icon is not showing "reset" action. Search for better icon.
 - 2012-12-11 Updated json2.js.
 - 2012-12-11 Added TicketList statistic option for historic states and historic state types.
 - 2012-12-11 Updated QUnit to version 1.10.0.
 - 2012-12-11 Updated StacktraceJS to version 0.4.
 - 2012-12-11 Updated jQuery Validate to version 1.10.
 - 2012-12-11 Added support for limiting result sets in the SQL Server DB Driver.
 - 2012-12-10 Fixed bug#[8974](http://bugs.otrs.org/show_bug.cgi?id=8974) - Event Based Notification does not populate REALNAME with
    Customer User data.
 - 2012-12-10 Fixed bug#[8928](http://bugs.otrs.org/show_bug.cgi?id=8928) - Link in Groups and Roles screens shows agent login, not name.
 - 2012-12-10 Upgraded CKEditor to version 4.0.

# 3.2.0 beta4 2012-12-11
 - 2012-12-05 Fixed bug#[7697](http://bugs.otrs.org/show_bug.cgi?id=7697) - Creating queues: sub-queues after level 4 not shown in dropdown box.
 - 2012-12-03 Fixed bug#[8933](http://bugs.otrs.org/show_bug.cgi?id=8933) - ArticleStorageInit permission check problem.
 - 2012-12-03 Various improvements in CustomerInformationCenter and ProcessManagement.
 - 2012-12-03 Fixed bug#[8963](http://bugs.otrs.org/show_bug.cgi?id=8963) - CIC Company attributes not marked as visible are displayed in
    Company Dashlet.
 - 2012-11-30 Updated Estonian language translation, thanks to Margus Värton!
 - 2012-11-29 Fixed bug#[8949](http://bugs.otrs.org/show_bug.cgi?id=8949) - CIC can't open in a new tab in Firefox 17.
 - 2012-11-29 Fixed bug#[8948](http://bugs.otrs.org/show_bug.cgi?id=8948) - CIC Dashboard Filters shows error, customer\_id will be lost.
 - 2012-11-29 Fixed bug#[8763](http://bugs.otrs.org/show_bug.cgi?id=8763) - Added charset conversion for customer companies.
 - 2012-11-29 Fixed bug#[1970](http://bugs.otrs.org/show_bug.cgi?id=1970) - Email attachments of type .msg (Outlook-Message) are converted.
 - 2012-11-28 Fixed bug#[8955](http://bugs.otrs.org/show_bug.cgi?id=8955) - Init script might fail on SUSE.
 - 2012-11-24 Fixed bug#[8936](http://bugs.otrs.org/show_bug.cgi?id=8936) - Ticket close date is empty when ticket is created in closed state.
 - 2012-11-24 Fixed bug#[8942](http://bugs.otrs.org/show_bug.cgi?id=8942) - Dates show UTC offset on systems with Timezone support activated.
 - 2012-11-23 Fixed problem with out of office feature in dashboard module DashboardUserOnline.

# 3.2.0 beta3 2012-11-27
 - 2012-11-22 Fixed bug#[8937](http://bugs.otrs.org/show_bug.cgi?id=8937) - "$" should be escaped in interpolated strings when javascript is meant.
 - 2012-11-20 Fixed bug#[8932](http://bugs.otrs.org/show_bug.cgi?id=8932) - DB backend CustomerName function is prefixed with login.
 - 2012-11-20 Fixed bug#[8896](http://bugs.otrs.org/show_bug.cgi?id=8896) - ProcessManagement GUI Transition arrows overlaps.
    To achieve this, the rendering engine of the ProcessManagement admin GUI was replaced
    by jsplumb.
 - 2012-11-19 Fixed bug#[8919](http://bugs.otrs.org/show_bug.cgi?id=8919) - Customer interface search results: ticket can only be accessed
    via ticket number and subject.
 - 2012-11-19 Fixed bug#[8809](http://bugs.otrs.org/show_bug.cgi?id=8809) - CustomerTicketOverview shows Queue and Owner fields hardcoded.
 - 2012-11-19 Fixed another possible race condition in the new DB session backend.
 - 2012-11-19 Fixed bug#[8850](http://bugs.otrs.org/show_bug.cgi?id=8850) - CustomerTicketOverview - MouseOver Age isn't always correct.
 - 2012-11-17 Follow up fix for added feature Ideascale#934 / bug#[1682](http://bugs.otrs.org/show_bug.cgi?id=1682) - Add
    timescale for Week in Stats.
 - 2012-11-18 Fixed bug#[8927](http://bugs.otrs.org/show_bug.cgi?id=8927) - OTRS under mod\_perl generates core dumps when
    used on SysLog log backend.
 - 2012-11-17 Fixed bug#[8926](http://bugs.otrs.org/show_bug.cgi?id=8926) - RoleList and GroupList cache is not reset when groups or
    roles are added or updated.
 - 2012-11-17 Updated Dutch translation.
 - 2012-11-16 Fixed a bug where addresses were lost in AgentTicketCompose after adding
    or removing an attachment.
 - 2012-11-15 Added feature to edit Dynamic Fields in customer follow ups.
 - 2012-11-15 Updated CPAN module CGI to version 3.63.
 - 2012-11-15 Fixed a bug where articles would display an incorrect creation date.
 - 2012-11-15 Added feature to search on Company Name in CustomerID field in Customer
    Information Center.
 - 2012-11-15 Fixed bug#[8921](http://bugs.otrs.org/show_bug.cgi?id=8921) - Responsible selection has empty option after a selection is
    made in AgentTicketActionCommon based screens.
 - 2012-11-15 Fixed bug#[8920](http://bugs.otrs.org/show_bug.cgi?id=8920) - Owner selection is set to empty list after a selection is made
    in AgentTicketActionCommon based screens.
 - 2012-11-14 Fixed bug#[8868](http://bugs.otrs.org/show_bug.cgi?id=8868) - Event Based Notification problem saving 'text' Dynamic Fields.
 - 2012-11-13 Fixed bug#[8910](http://bugs.otrs.org/show_bug.cgi?id=8910) - AjaxUpdate of DynamicFields in CustomerFrontend.
 - 2012-11-12 Fixed bug#[8915](http://bugs.otrs.org/show_bug.cgi?id=8915) - CustomerCompany List returns extra spaces.
 - 2012-11-12 Added feature to hide archived tickets in the customer interface.
 - 2012-11-12 Updated CPAN module CGI to version 3.62.
 - 2012-11-09 Fixed bug#[8914](http://bugs.otrs.org/show_bug.cgi?id=8914) - Syntax error in hash loop in TicketGet operation.

# 3.2.0 beta2 2012-11-13
 - 2012-11-07 Fixed bug#[8749](http://bugs.otrs.org/show_bug.cgi?id=8749) - CustomerFrontend: missing dynamicfield in  search results.
 - 2012-11-07 Fixed bug#[8908](http://bugs.otrs.org/show_bug.cgi?id=8908) - ProcessManagement import config feature doesn't works if
    dynamic fields are included.
 - 2012-11-07 Fixed bug#[8907](http://bugs.otrs.org/show_bug.cgi?id=8907) - ProcessManagement StartActivityDialog Owner and Responsible fields
    produces an error.
 - 2012-11-07 Fixed bug#[8906](http://bugs.otrs.org/show_bug.cgi?id=8906) - ProcessManagement Activities without AtivityDialogs leads to a
    internal error in TicketZoom.
 - 2012-11-07 Fixed handling of scalar refs in the new DB based session backend.
 - 2012-11-07 Fixed race condition in new DB based session backend.
 - 2012-11-07 Changed default setting for `Ticket::Frontend::ZoomRichTextForce`.
    Now OTRS will display HTML emails as HTML by default, even if RichText is not
    activated for composing new messages. This helps for devices which cannot
    use RichText for editing, but are able to display HTML content, such as certain
    iPads.
 - 2012-11-07 Fixed bug#[8897](http://bugs.otrs.org/show_bug.cgi?id=8897) - Wrong ProcessManagement Transition config format.
 - 2012-11-06 Fixed bug#[8873](http://bugs.otrs.org/show_bug.cgi?id=8873) - Bad example of customization of "static" dynamic fields in
    AgentTicketOverviewSmall.
 - 2012-11-06 Fixed bug#[8901](http://bugs.otrs.org/show_bug.cgi?id=8901) - ProcessManagement No article created on StartActivityDialog.
 - 2012-11-06 Fixed bug#[8890](http://bugs.otrs.org/show_bug.cgi?id=8890) - ProcessManagement Undefined EntityID error on
    AdminProcessManagementTransition edit.
 - 2012-11-06 Fixed bug#[8899](http://bugs.otrs.org/show_bug.cgi?id=8899) - ProcessManagement Articles should not have ArticleType email.
 - 2012-11-06 Fixed bug#[8898](http://bugs.otrs.org/show_bug.cgi?id=8898) - ProcessManagement GUI error on popup close (without change).
 - 2012-11-06 Fixed bug#[8895](http://bugs.otrs.org/show_bug.cgi?id=8895) - ProcessManagement Transition Path JS error on Transition Dbl Click.
 - 2012-11-06 Fixed bug#[3419](http://bugs.otrs.org/show_bug.cgi?id=3419) - Kernel/Config/GenericAgent.pm and utf8.
 - 2012-11-06 Fixed a typo in the auto-generated process configuration cache.
 - 2012-11-05 Updated Swedish translation, thanks to Andreas Berger!
 - 2012-11-02 Fixed bug#[8791](http://bugs.otrs.org/show_bug.cgi?id=8791) - IMAPTLS fails with some Microsoft Exchange servers.
 - 2012-10-31 Fixed bug#[8430](http://bugs.otrs.org/show_bug.cgi?id=8430) - Dynamic field management: selection dropdowns
    aren't translated.
 - 2012-10-30 Fixed bug#[8872](http://bugs.otrs.org/show_bug.cgi?id=8872) - Need a scalar reference! error on File uploads.
 - 2012-10-30 Updated CPAN module MailTools to version 2.11.
 - 2012-10-30 Updated CPAN module Mozilla::CA to version 20120823.
 - 2012-10-30 Updated CPAN module Locale::Codes to version 3.23.
 - 2012-10-30 Updated CPAN module HTTP::Message to version 6.06.
 - 2012-10-30 Updated CPAN module Digest::SHA::PurePerl to version 5.72.
 - 2012-10-30 Updated CPAN module Class::Inspector to version 1.28.
 - 2012-10-30 Updated CPAN module CGI to version 3.60.
 - 2012-10-30 Updated CPAN module Authen::SASL to version 2.16.

# 3.2.0 beta1 2012-10-30
 - 2012-11-19 Fixed bug#[8919](http://bugs.otrs.org/show_bug.cgi?id=8919) - Customer interface search results: ticket can only be accessed
    via ticket number and subject.
 - 2012-10-25 Fixed bug#[8864](http://bugs.otrs.org/show_bug.cgi?id=8864) - Increasing the column size of a varchar column does not work on oracle
    under certain conditions.
 - 2012-10-24 Fixed bug#[8062](http://bugs.otrs.org/show_bug.cgi?id=8062) - Optimize images in all defualt skins.
 - 2012-10-24 Fixed bug#[8861](http://bugs.otrs.org/show_bug.cgi?id=8861) - Ticket History overlaid calender choice function.
 - 2012-10-24 Fixed bug#[8818](http://bugs.otrs.org/show_bug.cgi?id=8818) - Slash in attachment filename breaks webinterface.
 - 2012-10-24 Added feature to limit the numbers of cuncurrent working agents and customers.
 - 2012-10-24 Refactored session management to improve performance and scalability.
 - 2012-10-23 Fixed bug#[8566](http://bugs.otrs.org/show_bug.cgi?id=8566) - Cannot download attachment if filename has character #.
 - 2012-10-23 Fixed bug#[8541](http://bugs.otrs.org/show_bug.cgi?id=8541) - Tooltip hides customer field in AgentTicketPhoneNew.
 - 2012-10-23 Fixed bug#[8833](http://bugs.otrs.org/show_bug.cgi?id=8833) - Article table in TicketZoom does not scroll correctly.
 - 2012-10-23 Fixed bug#[8685](http://bugs.otrs.org/show_bug.cgi?id=8685) - Cannot use address book / customer / spell check in phone / email if cookies are disabled.
 - 2012-10-23 Fixed bug#[8861](http://bugs.otrs.org/show_bug.cgi?id=8861) - Placeholder container for multiple customer fields are being displayed though being empty.
 - 2012-10-23 Fixed bug#[8673](http://bugs.otrs.org/show_bug.cgi?id=8673) - Richtext-Editor popups broken on Customer-Interface.
 - 2012-10-23 Upgraded CKEditor to version 3.6.5.
 - 2012-10-22 Fixed bug#[8840](http://bugs.otrs.org/show_bug.cgi?id=8840) - Verifying signature of inline-pgp-signed email with utf8 characters
    fails even though signatures without such characters get verified.
 - 2012-10-22 Fixed bug#[8746](http://bugs.otrs.org/show_bug.cgi?id=8746) - Unequal usage for ticket ACL match and limitation settings for
    dynamic fields.
 - 2012-10-22 Fixed bug#[7121](http://bugs.otrs.org/show_bug.cgi?id=7121) - Upgrading OTRS using RPM will not upgrade changed ITSM files.
 - 2012-10-22 Removed obsolete and slow cache backend FileRaw in favor of the better FileStorable.
    Config setting is updated automatically if needed.
 - 2012-10-22 Fixed bug#[1423](http://bugs.otrs.org/show_bug.cgi?id=1423) - Trim OTRS fields before processing.
    Kernel::System::Web::Request::GetParam()/GetArray() now always perform whitespace trimming
    by default. Use Raw =\> 1 to get the unchanged data if you need it.
 - 2012-10-20 Fixed bug#[8678](http://bugs.otrs.org/show_bug.cgi?id=8678) - 'WidgetAction Toggle' is always shown as 'Expanded' when nesting elements
 - 2012-10-20 Fixed bug#[8378](http://bugs.otrs.org/show_bug.cgi?id=8378) - Validation fails if the ID of the element contains a dot (.) or a
    colon (:)
 - 2012-10-17 Added possibility to select the queue in AgentTicketActionCommon based
    screens.
 - 2012-10-17 Fixed bug#[8842](http://bugs.otrs.org/show_bug.cgi?id=8842) - Stats outputs DynamicField keys, not values.
 - 2012-10-16 Added unit test for SOAP::Lite "Incorrect parameter" error.
 - 2012-10-16 Fixed "Incorrect parameter" error in SOAP::Lite 0.715 on any RPC with more than 2
    parameters.
 - 2012-10-15 Added bug#[8815](http://bugs.otrs.org/show_bug.cgi?id=8815) - List each SQL column at most once in INSERT statement in
    CustomerUser Backend, thanks to Michael Kromer!
 - 2012-10-15 Removed insecure storage of the last password of the user as unsalted plain md5. OTRS no
    longer checks if a user enters a different password than the previous one.
 - 2012-10-12 Fixed bug#[8807](http://bugs.otrs.org/show_bug.cgi?id=8807) - Company database with ForeignDB settings show empty columns.
 - 2012-10-10 Implemented redirect to the TicketZoom if Search result returns only one ticket.
 - 2012-10-08 Fixed bug#[7274](http://bugs.otrs.org/show_bug.cgi?id=7274) - Ticket QueueView sorts by priority on first page but subsequent
    pages sort incorrectly by Age.
 - 2012-10-08 Fixed bug#[8802](http://bugs.otrs.org/show_bug.cgi?id=8802) - Update to 3.1 leaves freetext columns in article\_search.
 - 2012-09-28 Fixed bug#[8794](http://bugs.otrs.org/show_bug.cgi?id=8794) - Depreciation warnings in web server error log for
    AdminEmail.pm when using perl \>= 5.16.
 - 2012-09-27 Fixed bug#[8551](http://bugs.otrs.org/show_bug.cgi?id=8551) - Missing DynamicFields values in TemplateGenerator and
    NotificationEvent (only show keys).
 - 2012-09-26 Added support for new SysConfig settings type "DateTime" (Date and DateTime).
 - 2012-09-24 Fixed bug#[5098](http://bugs.otrs.org/show_bug.cgi?id=5098) - OTRS does not verify that SMIME signatures match email senders.
 - 2012-09-21 Added new feature "SwitchToCustomer". The feature can be enabled
    with the new sysconfig setting "SwitchToCustomer".
 - 2012-09-13 Added possibility to search for tickets based on escalation time.
 - 2012-08-10 Added bug#[7183](http://bugs.otrs.org/show_bug.cgi?id=7183) - Usage of HTML5 Form field 'email'.
 - 2012-09-10 Added caching to Kernel::System::CustomerCompany.
 - 2012-09-07 Updated FSF address.
 - 2012-08-20 Fixed bug#[3463](http://bugs.otrs.org/show_bug.cgi?id=3463) - \<OTRS\_TICKET\_EscalationDestinationIn\> incorrect.
 - 2012-08-20 Fixed bug#[5954](http://bugs.otrs.org/show_bug.cgi?id=5954) - Ticket::Frontend::OverviewSmall###ColumnHeader has
    no effect on customer frontend.
 - 2012-08-17 HTML mails will now be displayed in the restricted zone in IE.
    This means that more restrictive security settings will apply, such as blocking of
    JavaScript content by default.
 - 2012-08-16 Added possibility to expand DynamicFields by default in ticket search
    via config option Ticket::Frontend::AgentTicketSearch###DynamicField.
 - 2012-08-14 Fixed bug#[8679](http://bugs.otrs.org/show_bug.cgi?id=8679) - OTRS changes "UTF-8" to "utf-8" in displayed emails.
 - 2012-08-10 Fixed bug#[5240](http://bugs.otrs.org/show_bug.cgi?id=5240) - Don't update read only fields in the CustomerUser DB.
 - 2012-08-03 Improved HTML mail display filtering. SVG content is now filtered out because
    it is potentially dangerous.
 - 2012-08-03 Generated HTML mails now always have the HTML5 doctype.
    HTML mail content to be displayed in OTRS now always gets the HTML5 doctype
    if it does not have a doctype yet. The HTML5 doctype is compatible to HTML4 and
    causes the browsers to render the content in standards mode, which is safer.
 - 2012-08-02 Improved HTML mail display filtering.
    Simple Microsoft CSS expressions are now filtered out.
 - 2012-07-31 Removed unused script otrs.XMLMaster.pl.
 - 2012-07-31 Changed the behaviour of HTML mail display filtering.
    By default, all inline/active content (such as script, object, applet or embed tags)
    will be stripped. If there are external images in mails from the customer, they will be stripped too,
    but a message will be shown allowing the user to reload the page showing the external images.
 - 2012-07-31 HTML mails will now be displayed in an HTML5 sandbox iframe.
    This means that modern browsers will not execute plugins or JavaScript on the content
    any more. Currently, this is supported by Chrome and Safari, but IE10 and FF16 are also
    planned to support this.
 - 2012-07-30 Switched the OTRS frontend to use the HTML5 doctype.
 - 2012-07-23 Added object check in the event handler mechanism.
 - 2012-07-16 Updated CPAN module Apache2::Reload to version 0.12.
 - 2012-07-16 Updated CPAN module LWP::UserAgent to version 6.04.
 - 2012-07-16 Updated CPAN module YAML to version 0.84.
 - 2012-07-16 Updated CPAN module URI to version 1.60.
 - 2012-07-16 Updated CPAN module Mail::Address to version 2.09.
 - 2012-07-16 Updated CPAN module SOAP::Lite to version 0.715.
 - 2012-07-16 Updated CPAN module Mozilla::CA to version 20120309.
 - 2012-07-16 Updated CPAN module Local::Codes to version 3.22.
 - 2012-07-16 Updated CPAN module Encode::Locale to version 1.03.
 - 2012-07-16 Updated CPAN module Digest::SHA::PurePerl to version 5.71.
 - 2012-07-16 Updated CPAN module Class::Inspector to version 1.27.
 - 2012-07-16 Fixed bug#[8616](http://bugs.otrs.org/show_bug.cgi?id=8616) - Spell Checker does not work using IE9.
 - 2012-07-05 Added the ability to hide the Article Type from TicketActionCommon-based screens
    which can be helpful to fit more data in the browser window.
 - 2012-07-04 The customer web interface now fully supports AJAX and ACLs.
    It now requires JavaScript and can no longer be used with Internet Explorer 6 or earlier versions.
 - 2012-07-03 Added new feature to remove seen flags and ticket watcher information of
    archived tickets. Use the config settings Ticket::ArchiveSystem::RemoveSeenFlags and
    Ticket::ArchiveSystem::RemoveTicketWatchers to control if this data is removed when
    a ticket is being archived (active by default).
    Archived tickets will now always be shown as 'seen' by the agent.
 - 2012-06-26 Improved cache performance with many cache files.
 - 2012-06-26 Removed unneeded columns from the ticket table.
 - 2012-06-21 Added bin/otrs.TicketDelete.pl script to delete tickets.
 - 2012-06-21 Fixed bug#[8596](http://bugs.otrs.org/show_bug.cgi?id=8596) - user/group/role data updated unnecessarily on LDAP agent sync.
 - 2012-06-19 Reduced the number of database calls for the article flags in AgentTicketZoom.
 - 2012-06-18 Removed unneeded indices from the article\_flags table.
 - 2012-06-08 Added feature SMIME certificate read.
 - 2012-05-25 Fixed bug#[8522](http://bugs.otrs.org/show_bug.cgi?id=8522) - Multiple recipient feature is missing in AgentTicketForward.
 - 2012-05-25 Added template list to all output filter config to improve performance.
 - 2012-05-24 Added feature IdeaScale#925 - possibility to place customized DTL files in
    Custom/Kernel/Output/HTML, so that they override the system's default DTL files just like
    it already works for Perl files.
 - 2012-05-22 Fixed bug#[8442](http://bugs.otrs.org/show_bug.cgi?id=8442) - Can not submit tickets in customer interface if Queue selection is
    disabled and no Default queue is specified.
 - 2012-05-21 Added feature Ideascale#72 / bug#[5471](http://bugs.otrs.org/show_bug.cgi?id=5471) - Out-of-Office dashboard widget.
 - 2012-05-14 Added feature Ideascale#934 / bug#[1682](http://bugs.otrs.org/show_bug.cgi?id=1682) - Add timescale for Week in Stats.
 - 2012-05-14 Added feature Ideascale#896 - Have the ability to set the default ticket type
    or hide the ticket type in the Customer Interface for new tickets.
 - 2012-05-07 Fixed bug#[8196](http://bugs.otrs.org/show_bug.cgi?id=8196) - Wrong article sender type for web service tickets.
 - 2012-04-27 Added bug#[8075](http://bugs.otrs.org/show_bug.cgi?id=8075) - Article Sender Type to be added to
    NotificationEvent definitions.

# 3.1.18 2013-07-09
 - 2013-07-03 Fixed bug#[9561](http://bugs.otrs.org/show_bug.cgi?id=9561) - ACL restriction with CustomerID for DynamicFields at new Ticket screen not working.
 - 2013-07-02 Fixed bug#[9425](http://bugs.otrs.org/show_bug.cgi?id=9425) - Wrong created date for queue view.
 - 2013-06-28 Fixed bug#[9125](http://bugs.otrs.org/show_bug.cgi?id=9125) - AgentTicketSearch dialog does not expand when choosing more search criteria.
 - 2013-06-28 Fixed bug#[8273](http://bugs.otrs.org/show_bug.cgi?id=8273) - Copying text in preview mode not possible.
 - 2013-06-28 Fixed bug#[9557](http://bugs.otrs.org/show_bug.cgi?id=9557) - Cannot see quoted text in customer ticket zoom.
 - 2013-06-27 Fixed bug#[9011](http://bugs.otrs.org/show_bug.cgi?id=9011) - GenericInterface: New value after value mapping can't be 0.
 - 2013-06-25 Improved parameter quoting in various places.
 - 2013-06-24 Fixed bug#[9104](http://bugs.otrs.org/show_bug.cgi?id=9104) - Group permission for customer subset overwrites permissions for other customers.
 - 2013-06-13 Fixed bug#[8719](http://bugs.otrs.org/show_bug.cgi?id=8719) - PasswordMin2Lower2UpperCharacters problem.

# 3.1.17 2013-06-18
 - 2013-06-06 Improved permission checks in AgentTicketWatcher.
 - 2013-06-06 Fixed bug#[9503](http://bugs.otrs.org/show_bug.cgi?id=9503) - no connection header in soap responses.
 - 2013-06-04 Added parameter "-t dbonly" to backup.pl to only backup the database
 - 2013-05-31 Fixed bug#[9491](http://bugs.otrs.org/show_bug.cgi?id=9491) - GenericAgent job update with dynamic fields sends Uninitialized value error.
 - 2013-05-24 Fixed bug#[9462](http://bugs.otrs.org/show_bug.cgi?id=9462) - Package Management page timeout due to HTTPS disabled on Proxy connections.

# 3.1.16 2013-05-21
 - 2013-05-17 Updated Package Manager, that will ensure that packages to be installed
    meet the quality standards of OTRS Group. This is to guarantee that your package
    wasn’t modified, which may possibly harm your system or have an influence on the
    stability and performance of it. All independent package contributors will have
    to conduct a check of their Add-Ons by OTRS Group in order to take full advantage
    of the OTRS package verification.
 - 2013-05-16 Fixed bug#[9387](http://bugs.otrs.org/show_bug.cgi?id=9387) - Error in a condition with dynamic fields in NotificationEvent.
 - 2013-05-14 Fixed bug#[9286](http://bugs.otrs.org/show_bug.cgi?id=9286) - Ticket::ChangeOwnerToEveryone isn't functional, After a AJAX Load the setting is ignored.
 - 2013-05-14 Fixed bug#[7518](http://bugs.otrs.org/show_bug.cgi?id=7518) - Escalation Notify by not working properly (follow-up fix).
 - 2013-05-07 Fixed bug#[7478](http://bugs.otrs.org/show_bug.cgi?id=7478) - Got an external answer to an internal mail.
 - 2013-05-07 Improved permission checks in AgentTicketPhone.
 - 2013-05-02 Fixed bug#[9360](http://bugs.otrs.org/show_bug.cgi?id=9360) - DynamicField Names shown in CSV output.
 - 2013-04-30 Fixed bug#[9384](http://bugs.otrs.org/show_bug.cgi?id=9384) - Problem with Method ServiceParentsGet of ServiceObject.
 - 2013-04-23 Fixed bug#[9072](http://bugs.otrs.org/show_bug.cgi?id=9072) - Reply to email-internal includes customer users email in Cc. field.

# 3.1.15 2013-04-23
 - 2013-04-15 Added Malay translation.
 - 2013-04-12 Fixed bug#[8960](http://bugs.otrs.org/show_bug.cgi?id=8960) - AgentTicketSearch.pm SearchProfile problem.
 - 2013-04-09 Fixed bug#[9182](http://bugs.otrs.org/show_bug.cgi?id=9182) - Customer Search Function -> If you go into a ticket and go back you got not the search results.
 - 2013-04-02 Fixed bug#[9198](http://bugs.otrs.org/show_bug.cgi?id=9198) - Linked search with fulltext AND additional attributes.
 - 2013-03-27 Fixed bug#[9295](http://bugs.otrs.org/show_bug.cgi?id=9295) - Article dynamic field is not searchable.
 - 2013-04-08 Fixed bug#[9312](http://bugs.otrs.org/show_bug.cgi?id=9312) - LinkObject permission check problem.

# 3.1.14 2013-04-02
 - 2013-03-21 Fixed bug#[9257](http://bugs.otrs.org/show_bug.cgi?id=9257) - No notifications to agents with out-of-office set but period not reached.
 - 2013-03-18 Improved permission checks in LinkObject.
 - 2013-03-14 Fixed bug#[9191](http://bugs.otrs.org/show_bug.cgi?id=9191) - When ticket types are restricted, first available type is selected
   in AgentTicketActionCommon-based screens.
 - 2013-03-12 Updated Turkish translation, thanks to Sefer Şimşek / Network Group!
 - 2013-03-02 Fixed bug#[9214](http://bugs.otrs.org/show_bug.cgi?id=9214) - IE10: impossible to open links from rich text articles.
 - 2013-03-01 Fixed bug#[9218](http://bugs.otrs.org/show_bug.cgi?id=9218) - Cannot use special characters in TicketHook.
 - 2013-02-28 Fixed bug#[9056](http://bugs.otrs.org/show_bug.cgi?id=9056) - Unused SysConfig option Ticket::Frontend::CustomerInfoQueueMaxSize.
 - 2013-02-26 Follow-up fix for bug#8533 apache will not start on Fedora.
 - 2013-02-26 Fixed bug#[9172](http://bugs.otrs.org/show_bug.cgi?id=9172) - Generic Interface does not work on IIS 7.0.
 - 2013-02-21 Updated Czech language translation, thanks to Katerina Bubenickova!
 - 2013-02-20 Fixed bug#[8865](http://bugs.otrs.org/show_bug.cgi?id=8865) - Additional empty data column in statistics CSV-Output.

# 3.1.13 2013-02-19
 - 2013-02-19 Fixed bug#[9128](http://bugs.otrs.org/show_bug.cgi?id=9128) - OTRS uses internal sub of Locale::Codes::Country which causes trouble for
    Debian.
 - 2013-02-13 Fixed bug#[9162](http://bugs.otrs.org/show_bug.cgi?id=9162) - Setting the start day of the week for the datepicker to Sunday does not work.
 - 2013-02-13 Fixed bug#[9141](http://bugs.otrs.org/show_bug.cgi?id=9141) - Confused Columns in CustomerTicketSearch (ResultShort).
 - 2013-02-08 Fixed bug#[9146](http://bugs.otrs.org/show_bug.cgi?id=9146) - Signed SMIME mails with altered content shows a not clear message.
 - 2013-02-08 Fixed bug#[9145](http://bugs.otrs.org/show_bug.cgi?id=9145) - SMIME sign verification errors are not displayed in TicketZoom.
 - 2013-02-07 Fixed bug#[9140](http://bugs.otrs.org/show_bug.cgi?id=9140) - Postmaster Filter for empty subjects does not work.
 - 2013-02-05 Fixed bug#[9121](http://bugs.otrs.org/show_bug.cgi?id=9121) - Filenames with Unicode NFD are incorrectly reported as NFC by Main::DirectoryRead().
 - 2013-02-05 Fixed bug#[9108](http://bugs.otrs.org/show_bug.cgi?id=9108) - Check for opened/closed tickets not working with Ticket::SubjectFormat = Right.
 - 2013-02-01 Fixed bug#[8839](http://bugs.otrs.org/show_bug.cgi?id=8839) - DateChecksum followup doesn't get correctly SystemID.
 - 2013-01-31 Updated Russian translation, thanks to Vadim Goncharov!
 - 2013-01-30 Fixed bug#[9101](http://bugs.otrs.org/show_bug.cgi?id=9101) - Not possible to create dropdown with autocomplete attribute.
 - 2013-01-29 Fixed bug#[9096](http://bugs.otrs.org/show_bug.cgi?id=9096) - All services list is shown instead of only default services.
 - 2013-01-28 Fixed bug#[8470](http://bugs.otrs.org/show_bug.cgi?id=8470) - otrs.GenericAgent.pl reports: Can't open
    '/opt/otrs/otrs\_vemco/var/tmp/CacheFileStorable/DynamicField/f3b7e10730fb6c9cab5ae0e7f7e034f3'.
 - 2013-01-28 Added new translation for Spanish (Colombia), thanks to John Edisson Ortiz Roman!
 - 2013-01-21 Fixed bug#[9054](http://bugs.otrs.org/show_bug.cgi?id=9054) - Link Object deletes all links under certain conditions.
 - 2013-01-18 Fixed bug#[8944](http://bugs.otrs.org/show_bug.cgi?id=8944) - do not backup the cache.
 - 2013-01-16 Fixed bug#[9057](http://bugs.otrs.org/show_bug.cgi?id=9057) - Generating a PDF with bin/otrs.GenerateStats.pl produces lots
    of warnings.
 - 2013-01-15 Fixed bug#[8929](http://bugs.otrs.org/show_bug.cgi?id=8929) - Fix problems with empty ticket search results while
    Ticket::Frontend::AgentTicketSearch###ExtendedSearchCondition is inactive.
 - 2013-01-14 Fixed bug#[9042](http://bugs.otrs.org/show_bug.cgi?id=9042) - Add X-Spam-Score to Ticket.xml.
 - 2013-01-14 Fixed bug#[9047](http://bugs.otrs.org/show_bug.cgi?id=9047) - HistoryTicketGet caches info on disk directly.
 - 2013-01-11 Fixed bug#[8923](http://bugs.otrs.org/show_bug.cgi?id=8923) - Alert message shown, if parent window is reloaded while
    bulk action popup is open.
 - 2013-01-09 Fixed bug#[9030](http://bugs.otrs.org/show_bug.cgi?id=9030) - Wrong handling of Invalid YAML in Scheduler Tasks.
 - 2013-01-07 Updated CKEditor to version 3.6.6.
 - 2013-01-07 Updated Polish translation, thanks to Pawel @ ib.pl!
 - 2013-01-04 Follow-up fix for bug#[8805](http://bugs.otrs.org/show_bug.cgi?id=8805) - Cron missing as RPM dependency on Red Hat Enterprise Linux.
    Changed dependency on `anacron` to `vixie-cron` on RHEL5.
 - 2013-01-02 Fixed bug#[9020](http://bugs.otrs.org/show_bug.cgi?id=9020) - Generic Ticket Connector does not support attachments with
    ContentType without charset.
 - 2013-01-02 Fixed bug#[8545](http://bugs.otrs.org/show_bug.cgi?id=8545) - Attachment download not possible if pop up of another action is open.
 - 2012-12-20 Fixed bug#[9009](http://bugs.otrs.org/show_bug.cgi?id=9009) - Empty Multiselect Dynamic Fields provokes an error.
 - 2012-12-17 Fixed bug#[8589](http://bugs.otrs.org/show_bug.cgi?id=8589) - Bulk-Action not possible for single ticket.
 - 2012-12-17 Fixed bug#[7198](http://bugs.otrs.org/show_bug.cgi?id=7198) - Broken repository selection width in Package Manager.
 - 2012-12-17 Fixed bug#[8457](http://bugs.otrs.org/show_bug.cgi?id=8457) - Error if accessing AgentTicketSearch from AgentTicketPhone in IE8.
 - 2012-12-17 Fixed bug#[8695](http://bugs.otrs.org/show_bug.cgi?id=8695) - Table head of Customer Ticket History does not resize on window resize.
 - 2012-12-13 Fixed bug#[8533](http://bugs.otrs.org/show_bug.cgi?id=8533) - Apache will not start if you use mod\_perl on Fedora 16 or 17.
 - 2012-12-10 Fixed bug#[8974](http://bugs.otrs.org/show_bug.cgi?id=8974) - Event Based Notification does not populate REALNAME with
    Customer User data.

# 3.1.12 2012-12-11
 - 2012-12-03 Fixed bug#[8933](http://bugs.otrs.org/show_bug.cgi?id=8933) - ArticleStorageInit permission check problem.
 - 2012-11-29 Fixed bug#[8763](http://bugs.otrs.org/show_bug.cgi?id=8763) - Please add charset conversion for customer companies.
 - 2012-11-29 Fixed bug#[1970](http://bugs.otrs.org/show_bug.cgi?id=1970) - Email attachments of type .msg (Outlook-Message) are converted.
 - 2012-11-28 Fixed bug#[8955](http://bugs.otrs.org/show_bug.cgi?id=8955) - Init script might fail on SUSE.
 - 2012-11-24 Fixed bug#[8936](http://bugs.otrs.org/show_bug.cgi?id=8936) - Ticket close date is empty when ticket is created in closed state.
 - 2012-11-19 Fixed bug#[8850](http://bugs.otrs.org/show_bug.cgi?id=8850) - CustomerTicketOverview - MouseOver Age isn't always correct.
 - 2012-11-14 Fixed bug#[8868](http://bugs.otrs.org/show_bug.cgi?id=8868) - Event Based Notification problem saving 'text' Dynamic Fields.
 - 2012-11-09 Fixed bug#[8914](http://bugs.otrs.org/show_bug.cgi?id=8914) - Syntax error in hash loop in TicketGet operation.
 - 2012-11-07 Fixed bug#[8749](http://bugs.otrs.org/show_bug.cgi?id=8749) - CustomerFrontend: missing dynamicfield in  search results.
 - 2012-11-06 Fixed bug#[8873](http://bugs.otrs.org/show_bug.cgi?id=8873) - Bad example of customization of "static" dynamic fields in
    AgentTicketOverviewSmall.
 - 2012-11-02 Fixed bug#[8791](http://bugs.otrs.org/show_bug.cgi?id=8791) - IMAPTLS fails with some Microsoft Exchange servers.
 - 2012-10-24 Fixed bug#[8841](http://bugs.otrs.org/show_bug.cgi?id=8841) - Search for Dynamic Fields shows all tickets (on "enter" key pressed).
 - 2012-10-23 Fixed bug#[8862](http://bugs.otrs.org/show_bug.cgi?id=8862) - GI debugger GUI does not show SOAP XML tags correctly.
 - 2012-10-22 Fixed bug#[8859](http://bugs.otrs.org/show_bug.cgi?id=8859) - Package upgrade does not work if an installed testpackage
    should be upgraded with a newer regular package.
 - 2012-10-20 Fixed bug#[8678](http://bugs.otrs.org/show_bug.cgi?id=8678) - 'WidgetAction Toggle' is always shown as 'Expanded' when nesting elements
 - 2012-10-20 Fixed bug#[8378](http://bugs.otrs.org/show_bug.cgi?id=8378) - Validation fails if the ID of the element contains a dot (.) or a
    colon (:)
 - 2012-10-17 Fixed bug#[8847](http://bugs.otrs.org/show_bug.cgi?id=8847) - Inline PGP message description routine does not add any info, thanks
    to IB Development Team.
 - 2012-10-17 Fixed bug#[8848](http://bugs.otrs.org/show_bug.cgi?id=8848) - AgentTicketEmail does not preserve PGP Signatures set if attachment
    is added.
 - 2012-10-16 Fixed bug#[8149](http://bugs.otrs.org/show_bug.cgi?id=8149) - Wrong handling of subject when SubjectFormat=right.
 - 2012-10-12 Updated Polish translation, thanks to Pawel!
 - 2012-10-13 Fixed bug#[8820](http://bugs.otrs.org/show_bug.cgi?id=8820) - Service rcotrs restart fails because a race condition happens.
 - 2012-10-12 Fixed bug#[8819](http://bugs.otrs.org/show_bug.cgi?id=8819) - Syntax error (stop crontab command) in SuSE rc script.
 - 2012-10-12 Removed auto cleanup of expired sessions in CreateSessionID() to improve the scalability
    of the hole system.
 - 2012-10-11 Fixed bug#[8667](http://bugs.otrs.org/show_bug.cgi?id=8667) - TicketSplit does not use QueueID of old Ticket for ACL Checking.
 - 2012-10-08 Fixed bug#[8780](http://bugs.otrs.org/show_bug.cgi?id=8780) - 508 Compliance: Text descriptions of "Responsible Tickets"
    and "Locked Tickets" links are insufficient for screen reader users.
 - 2012-10-05 Fixed bug#[8812](http://bugs.otrs.org/show_bug.cgi?id=8812) - Encrypted email doesn't see properly in Outlook.
 - 2012-10-03 Fixed bug#[8214](http://bugs.otrs.org/show_bug.cgi?id=8214) - OTRS Init script on Red Hat fails to check scheduler.
 - 2012-10-03 Fixed bug#[8805](http://bugs.otrs.org/show_bug.cgi?id=8805) - Cron missing as RPM dependency on Red Hat Enterprise Linux.
 - 2012-09-28 Fixed bug#[7274](http://bugs.otrs.org/show_bug.cgi?id=7274) - Ticket QueueView sorts by priority on first page but subsequent
    pages sort incorrectly by Age.
 - 2012-09-27 Fixed bug#[8792](http://bugs.otrs.org/show_bug.cgi?id=8792) - TriggerEscalationStopEvents logs as loglevel 'error'.
 - 2012-09-26 Fixed bug#[8743](http://bugs.otrs.org/show_bug.cgi?id=8743) - AgentTicketCompose.pm creates To, CC, BCC filelds without spaces after comma.
 - 2012-09-25 Fixed bug#[8606](http://bugs.otrs.org/show_bug.cgi?id=8606) - Escalation notifications should not be sent to agents who are set out-of-office.
 - 2012-09-25 Fixed bug#[8740](http://bugs.otrs.org/show_bug.cgi?id=8740) - backup.pl: insufficient handling of system() return values.
 - 2012-09-24 Fixed bug#[8622](http://bugs.otrs.org/show_bug.cgi?id=8622) - Storing a new GI Invoker or Operation with an existing name doesn't
    complain anything.
 - 2012-09-24 Fixed bug#[8770](http://bugs.otrs.org/show_bug.cgi?id=8770) - AJAX Removes Default Options (follow-up fix).
 - 2012-09-21 Improved caching for Services and Service Lists.

# 3.1.11 2012-10-16
 - 2012-09-18 Fixed bug#[8770](http://bugs.otrs.org/show_bug.cgi?id=8770) - AJAX Removes Default Options.
 - 2012-09-17 Fixed bug#[7135](http://bugs.otrs.org/show_bug.cgi?id=7135) - Queueview, Ticketwindow closing on Refresh.
 - 2012-09-17 Fixed bug#[7294](http://bugs.otrs.org/show_bug.cgi?id=7294) - Ticket search window closes on background refresh of ticket queue.
 - 2012-09-13 Fixed bug#[8765](http://bugs.otrs.org/show_bug.cgi?id=8765) - Package Manager OS detection does not work.
 - 2012-09-13 Improved HTML security filter to better find javascript source URLs.
 - 2012-09-11 Fixed bug#[8575](http://bugs.otrs.org/show_bug.cgi?id=8575) - SSL protocol negotiation fails using SMTPTLS with recent
    IO::Socket::SSL versions by upgrading TLS module to 0.20.
 - 2012-09-10 Fixed bug#[4475](http://bugs.otrs.org/show_bug.cgi?id=4475) - Extra double quote added to HTML links when using http-link field.
 - 2012-09-07 Improved caching of search results when the result set is empty.

# 3.1.10 2012-08-30
 - 2012-08-28 Improved HTML security filter to detect tag nesting.
 - 2012-08-24 Fixed bug#[8611](http://bugs.otrs.org/show_bug.cgi?id=8611) - Ticket count is wrong in QueueView.
 - 2012-08-21 Fixed bug#[8698](http://bugs.otrs.org/show_bug.cgi?id=8698) - Layout.pm only looks at first entry from
    HTTP\_ACCEPT\_LANGUAGE to determine language.
 - 2012-08-21 Fixed bug#[8731](http://bugs.otrs.org/show_bug.cgi?id=8731) - LDAP group check returns wrong error.

# 3.1.9 2012-08-21
 - 2012-08-20 Fixed bug#[3463](http://bugs.otrs.org/show_bug.cgi?id=3463) - \<OTRS\_TICKET\_EscalationDestinationIn\> incorrect.
 - 2012-08-20 Fixed bug#[5954](http://bugs.otrs.org/show_bug.cgi?id=5954) - Ticket::Frontend::OverviewSmall###ColumnHeader has
    no effect on customer frontend.
 - 2012-08-19 Fixed bug#[8584](http://bugs.otrs.org/show_bug.cgi?id=8584) Email address not added to recipients after collision/duplicate occurred.
 - 2012-08-17 HTML mails will now be displayed in an HTML5 sandbox iframe.
    This means that modern browsers will not execute plugins or JavaScript on the content
    any more. Currently, this is supported by Chrome and Safari, but IE10 and FF16 are also
 - 2012-08-17 HTML mails will now be displayed in the restricted zone in IE.
    This means that more restrictive security settings will apply, such as blocking of
    JavaScript content by default.
 - 2012-08-14 Fixed bug#[8360](http://bugs.otrs.org/show_bug.cgi?id=8360) Cannot search for tickets by dynamic fields via SOAP.
 - 2012-08-14 Fixed bug#[8697](http://bugs.otrs.org/show_bug.cgi?id=8697) Time related restrictions in TicketSearch operator (GenericInterface) not working.
 - 2012-08-14 Fixed bug#[8685](http://bugs.otrs.org/show_bug.cgi?id=8685) - Cannot use address book / customer / spell check in phone /
    email if cookies are disabled. (partly fixed)
 - 2012-08-06 Fixed bug#[8682](http://bugs.otrs.org/show_bug.cgi?id=8682) - linking search conditions with && in
    Customersearch is not working since Update from 3.1.1 to 3.1.7.
 - 2012-08-06 Fixed bug#[8683](http://bugs.otrs.org/show_bug.cgi?id=8683) - Cannot create dynamic field if cookies are disabled.
 - 2012-08-06 Fixed bug#[8672](http://bugs.otrs.org/show_bug.cgi?id=8672) - Search Profile can't have an ampersand in the name via
    Toolbar module.
 - 2012-08-06 Fixed bug#[8619](http://bugs.otrs.org/show_bug.cgi?id=8619) - The UPGRADING file has incorrect patchlevel upgrade description.
 - 2012-08-03 Fixed bug#[6882](http://bugs.otrs.org/show_bug.cgi?id=6882) - Dummy field set first child to the very right in edit screen.
 - 2012-08-03 Fixed bug#[8680](http://bugs.otrs.org/show_bug.cgi?id=8680) - Bulk action fails if cookies are disabled.

# 3.1.8 2012-08-07
 - 2012-08-02 Updated Greek translation file, thanks to Maistros Stelios!
 - 2012-07-31 Improved robustness of HTML security filter: Detect masked UTF-7 \< and \> signs.
 - 2012-07-31 Added config option for ticket permission in the escalation view.
 - 2012-07-31 Fixed bug#[8675](http://bugs.otrs.org/show_bug.cgi?id=8675) - Kernel::GenericInterface::Mapping doesn't provide a ConfigObject.
 - 2012-07-20 Fixed bug#[8660](http://bugs.otrs.org/show_bug.cgi?id=8660) - Duplicate DF X-Headers in PostMaster module.
 - 2012-07-17 Fixed bug#[8647](http://bugs.otrs.org/show_bug.cgi?id=8647) - otrs.GenerateStats.pl "-S" option does not function.
 - 2012-07-16 Fixed bug#[8616](http://bugs.otrs.org/show_bug.cgi?id=8616) - Spell Checker does not work using IE9.
 - 2012-07-11 Fixed bug#[8568](http://bugs.otrs.org/show_bug.cgi?id=8568) - IMAPTLS - More than one email at one cron run will not work.
 - 2012-07-05 Added bug#[8627](http://bugs.otrs.org/show_bug.cgi?id=8627) - bin/otrs.AddQueue2StdResponse.pl Script to add standard responses
    to queues, thanks to Oliver Skibbe @ CIPHRON GmbH.
 - 2012-07-04 Fixed bug#[8607](http://bugs.otrs.org/show_bug.cgi?id=8607) - otrs service fails in 3.1.7 on SUSE linux.
 - 2012-07-02 Increased cache TTL of some core modules to improve performance.
 - 2012-07-01 Fixed bug#[8620](http://bugs.otrs.org/show_bug.cgi?id=8620) - Using a default queue in the customer interface causes database
    error on PostgresSQL if ACLs are used.
 - 2012-06-29 Fixed bug#[8618](http://bugs.otrs.org/show_bug.cgi?id=8618) - Inform and Involved Agents select boxes can not be resizable.
 - 2012-06-27 Fixed bug#[8558](http://bugs.otrs.org/show_bug.cgi?id=8558) - GenericInterface: response isn't valid UTF-8 content.
 - 2012-06-27 Added bug#[7039](http://bugs.otrs.org/show_bug.cgi?id=7039) - bin/otrs.AddService.pl script to add services from the command
    line.
 - 2012-06-26 Made display of pending time consistent with escalation time display.
 - 2012-06-22 Fixed bug#[8230](http://bugs.otrs.org/show_bug.cgi?id=8230) - Invalid Challenge Token when creating ticket out of hyperlinks.

# 3.1.7 2012-06-26
 - 2012-06-18 Fixed bug#[8593](http://bugs.otrs.org/show_bug.cgi?id=8593) - Wrong description for 'Agent Notifications' on Admin interface.
 - 2012-06-18 Fixed bug#[8587](http://bugs.otrs.org/show_bug.cgi?id=8587) - Typo in French translation.
 - 2012-06-15 Fixed bug#[7879](http://bugs.otrs.org/show_bug.cgi?id=7879) - Broken Content-Type in forwarded attachments.
 - 2012-06-15 Fixed bug#[8583](http://bugs.otrs.org/show_bug.cgi?id=8583) - Unneeded complexity and performance degradation creating Service
    Lists (Replacement for bug fix 7947).
 - 2012-06-15 Fixed bug#[8580](http://bugs.otrs.org/show_bug.cgi?id=8580) - SQL warnings for CustomerCompanyGet on some database backends.
 - 2012-06-14 Fixed bug#[8251](http://bugs.otrs.org/show_bug.cgi?id=8251) - Defect handling of invalid Queues in AJAX refresh.
 - 2012-06-14 Fixed bug#[8574](http://bugs.otrs.org/show_bug.cgi?id=8574) - Perl special variable $/ is changed and never restored.
 - 2012-06-14 Fixed bug#[8337](http://bugs.otrs.org/show_bug.cgi?id=8337) - Parentheses in user last\_name / first\_name are not sanitized (follow-up fix).
 - 2012-06-12 Fixed bug#[8575](http://bugs.otrs.org/show_bug.cgi?id=8575) - Assignment of users does not work for responsible or owner permission
    in AgentTicketPhone.
 - 2012-06-12 Updated Hungarian translation, thanks to Németh Csaba!
 - 2012-06-12 Updated Danish translation, thanks to Lars Jørgensen!
 - 2012-06-12 Fixed bug#[7872](http://bugs.otrs.org/show_bug.cgi?id=7872) - "Created" date in Large view is actually Last Updated date.
 - 2012-06-12 Fixed bug#[8457](http://bugs.otrs.org/show_bug.cgi?id=8457) -  Paste on a newly created ckeditor instance does not work on webkit based browsers.
 - 2012-06-11 Fixed bug#[8565](http://bugs.otrs.org/show_bug.cgi?id=8565) - Exportfile action from otrs.PackageManaget.pl is broken.
 - 2012-06-11 Fixed bug#[8458](http://bugs.otrs.org/show_bug.cgi?id=8458) - $OTRS\_SCHEDULER -a start missing from /etc/init.d/otrs after update.
 - 2012-06-11 Fixed bug#[8139](http://bugs.otrs.org/show_bug.cgi?id=8139) - SUSE RPM has no dependency on Date::Format perl
    module.
 - 2012-06-11 Fixed bug#[8544](http://bugs.otrs.org/show_bug.cgi?id=8544) - Hovering ticket title is still shortened.
 - 2012-06-07 Fixed bug#[8553](http://bugs.otrs.org/show_bug.cgi?id=8553) - Agent notifications can't be loaded from the database in some
    scenarios.
 - 2012-06-05 Fixed bug#[8383](http://bugs.otrs.org/show_bug.cgi?id=8383) - Email address in 'To' field is lost after second reload if address is not in customer database.
 - 2012-06-06 Fixed bug#[8549](http://bugs.otrs.org/show_bug.cgi?id=8549) - "Need User" warning in error log when creating a ticket for a
    customer not in DB.
 - 2012-06-05 Fixed bug#[8546](http://bugs.otrs.org/show_bug.cgi?id=8546) - LinkObject Type is not translated in ticket zoom.
 - 2012-06-04 Fixed bug#[7533](http://bugs.otrs.org/show_bug.cgi?id=7533) - SQL error if body contains only a picture.
 - 2012-06-04 Fixed bug#[2626](http://bugs.otrs.org/show_bug.cgi?id=2626) - Default Service does not work for "unknown" customers.
    You can use the new setting "Ticket::Service::Default::UnknownCustomer" to specify if unknown customers
    should also receive the default services.
 - 2012-06-04 Improved performance of TemplateGenerator.pm, thanks to Stelios Gikas!
 - 2012-05-31 Fixed bug#[8481](http://bugs.otrs.org/show_bug.cgi?id=8481) - Dynamic Fields lost after ticket move to another queue (using quick
    move Dropdown).
 - 2012-05-31 Fixed bug#[8533](http://bugs.otrs.org/show_bug.cgi?id=8533) - Apache will not start using mod\_perl on Fedora 16.

# 3.1.6 2012-06-05
 - 2012-05-30 Fixed bug#[8495](http://bugs.otrs.org/show_bug.cgi?id=8495) - Generic Agent TicketAction single value attributes should not let
    multiple selection.
 - 2012-05-30 Fixed bug#[8378](http://bugs.otrs.org/show_bug.cgi?id=8378) - Validation fails if the ID of the element contains a dot (.) or a colon (:).
 - 2012-05-30 Fixed bug#[7532](http://bugs.otrs.org/show_bug.cgi?id=7532) - 'Field is required' message should be removed in RTE if content is added.
 - 2012-05-30 Fixed bug#[8514](http://bugs.otrs.org/show_bug.cgi?id=8514) - Long words in description break rendering of SysConfig items.
 - 2012-05-30 Fixed bug#[8537](http://bugs.otrs.org/show_bug.cgi?id=8537) - DynamicField caching issue.
 - 2012-05-29 Fixed bug#[8482](http://bugs.otrs.org/show_bug.cgi?id=8482) - Responsible of a ticket without responsible permission.
 - 2012-05-29 Fixed bug#[8485](http://bugs.otrs.org/show_bug.cgi?id=8485) - CustomerUser validation fails in GI Ticket Operations if there is no
    ValidID in the mapping.
 - 2012-05-29 Fixed bug#[8529](http://bugs.otrs.org/show_bug.cgi?id=8529) - Fixed print to STDERR in ReferenceData.pm.
 - 2012-05-28 Fixed bug#[8427](http://bugs.otrs.org/show_bug.cgi?id=8427) - Dynamic Field Type Multiselect not shown in Notification (event).
 - 2012-05-27 Updated Norwegian translation, thanks to Lars Magnus Herland!
 - 2012-05-25 Fixed bug#[8189](http://bugs.otrs.org/show_bug.cgi?id=8189) - AgentTicketCompose: Pressing "Enter" will delete Attachment.
 - 2012-05-25 Fixed bug#[7844](http://bugs.otrs.org/show_bug.cgi?id=7844) - Escalation Event does not respect service calendar of ticket/queue.
 - 2012-05-25 Fixed bug#[8228](http://bugs.otrs.org/show_bug.cgi?id=8228) - Ticket::Frontend::AgentTicketNote###StateDefault doesn't work.
 - 2012-05-25 Added template list to all output filter config to improve performance.
 - 2012-05-25 Fixed bug#[8519](http://bugs.otrs.org/show_bug.cgi?id=8519) - Kernel::System::TicketSearch-\>TicketSearch() doesn't properly handle
     array references in SortBy parameter
 - 2012-05-24 Fixed bug#[7512](http://bugs.otrs.org/show_bug.cgi?id=7512) - AJAX-reload of SMIME-fields did not work properly.
 - 2012-05-24 Fixed bug#[8518](http://bugs.otrs.org/show_bug.cgi?id=8518) - Crypt on multiple recipients error replaces Crypt selection.
 - 2012-05-22 Fixed bug#[8164](http://bugs.otrs.org/show_bug.cgi?id=8164) - Internal articles are visible within customer ticket overview.
 - 2012-05-22 Fixed bug#[8506](http://bugs.otrs.org/show_bug.cgi?id=8506) - Customer email link won't open in popup as expected.
 - 2012-05-20 Fixed bug#[7844](http://bugs.otrs.org/show_bug.cgi?id=7844) - Escalation Event does not respect service calendar of ticket/queue.
 - 2012-05-18 Added otrs.RefreshSMIMEKeys.pl to refresh SMIME certificate filenames according to the
    system's current OpenSSL version.
 - 2012-05-17 Fixed bug#[8498](http://bugs.otrs.org/show_bug.cgi?id=8498) - OpenSSL 1.0.0 does not get the stored SMIME certificates when
    -CApath is used in the command.
 - 2012-05-16 Fixed bug#[8337](http://bugs.otrs.org/show_bug.cgi?id=8337) - Parentheses in user last\_name / first\_name are not sanitized.
 - 2012-05-15 Updated French translation, thanks to Romain Monnier!
 - 2012-05-11 Fixed bug#[8467](http://bugs.otrs.org/show_bug.cgi?id=8467) - Reply to an e-mail address with ' not possible.
 - 2012-05-11 Fixed bug#[8352](http://bugs.otrs.org/show_bug.cgi?id=8352) - Wrong substitution regex in HTMLUtils.pm-\>ToAscii.
 - 2012-05-11 Fixed bug#[8401](http://bugs.otrs.org/show_bug.cgi?id=8401) - DynamicField Update doesn't update the X-OTRS-DynamicField-XXX
    Fields in Postmaster Filters.
 - 2012-05-11 Fixed bug#[5746](http://bugs.otrs.org/show_bug.cgi?id=5746) - Using PerlEx you have to restart IIS each time a setting is
    changed in SysConfig.
 - 2012-05-10 Fixed bug#[8452](http://bugs.otrs.org/show_bug.cgi?id=8452) - Dynamic Field Date/Time not working when server runs on UTC.

# 3.1.5 2012-05-15
 - 2012-05-09 Fixed bug#[8466](http://bugs.otrs.org/show_bug.cgi?id=8466) - On Win32 GenericInterface does not return results properly.
 - 2012-05-08 Fixed bug#[8465](http://bugs.otrs.org/show_bug.cgi?id=8465) - Can't create cache for web service debug log on win32 platforms.
 - 2012-05-08 Fixed bug#[7919](http://bugs.otrs.org/show_bug.cgi?id=7919) - Translation of ticket states in CSV Export of CustomerTicketSearch.
 - 2012-05-08 Fixed bug#[8461](http://bugs.otrs.org/show_bug.cgi?id=8461) - CustomerTicketSearch doesn't use ticket ACL rules.
 - 2012-05-04 Fixed bug#[7877](http://bugs.otrs.org/show_bug.cgi?id=7877) - SMIME emails don't get parsed properly (follow-up fix).
 - 2012-05-04 Fixed bug#[2452](http://bugs.otrs.org/show_bug.cgi?id=2452) - SMIME encoded E-Mails are not decrypted properly by OTRS (follow-up fix).
 - 2012-05-03 Fixed bug#[8446](http://bugs.otrs.org/show_bug.cgi?id=8446) - Dynamic Field type TextArea missing \> 3800 characters validation.
 - 2012-05-02 Fixed bug#[8447](http://bugs.otrs.org/show_bug.cgi?id=8447) - Checkbox Dynamic Field is wrong calculated in statistics.
 - 2012-05-02 Fixed bug#[8328](http://bugs.otrs.org/show_bug.cgi?id=8328) - Statistic containing restriction on dynamic field ignores the
    restriction.
 - 2012-05-01 Fixed bug#[8439](http://bugs.otrs.org/show_bug.cgi?id=8439) - AgentTicketForward: ticket not unlocked after
    selecting a close state.
 - 2012-04-27 Fixed bug#[7168](http://bugs.otrs.org/show_bug.cgi?id=7168) - Ticket Overview Control Row can only be one line high.
 - 2012-04-26 Fixed bug#[8437](http://bugs.otrs.org/show_bug.cgi?id=8437) - Dynamic Field order duplicated when change the order of a field.
 - 2012-04-26 Fixed bug#[8409](http://bugs.otrs.org/show_bug.cgi?id=8409) - Deselecting 'select all' in queue view does not work.
 - 2012-04-26 Updated Hungarian translation, thanks to Csaba Nemeth!
 - 2012-04-26 Fixed bug#[8424](http://bugs.otrs.org/show_bug.cgi?id=8424) - Ticket articles of large tickets cannot be opened.
 - 2012-04-25 Added possibility to specify a cache type for selective cache cleaning
    in bin/otrs.DeleteCache.
 - 2012-04-24 Added possibility to define ACL rules by user role.
 - 2012-04-24 Fixed bug#[8415](http://bugs.otrs.org/show_bug.cgi?id=8415) - Setting Ticket::Responsible ignored by AgentTicketActionCommon.
 - 2012-04-24 Fixed bug#[8288](http://bugs.otrs.org/show_bug.cgi?id=8288) - Autocomplete search results show up in Times font when using Internet Explorer.
 - 2012-04-24 Fixed bug#[8414](http://bugs.otrs.org/show_bug.cgi?id=8414) - ACL for AgentTicketCustomer in AgentTicketZoom doesn't affect
    CustomerID link in ticket information.
 - 2012-04-24 Updated CKEditor to version 3.6.3.
 - 2012-04-23 Fixed bug#[8369](http://bugs.otrs.org/show_bug.cgi?id=8369) - Wrong handling of Ticket ACL in AJAX Updates.

# 3.1.4 2012-04-24
 - 2012-04-15 Fixed bug#[8284](http://bugs.otrs.org/show_bug.cgi?id=8284) - The text "Cc: (xx@mail.com) added database email!" is confusing.
 - 2012-04-16 Fixed bug#[8392](http://bugs.otrs.org/show_bug.cgi?id=8392) - DynamicFieldAdd returns wrong value.
 - 2012-04-16 Fixed bug#[8387](http://bugs.otrs.org/show_bug.cgi?id=8387) - UseSyncBackend configuration does not conform to OTRS style.
 - 2012-04-16 Fixed bug#[8367](http://bugs.otrs.org/show_bug.cgi?id=8367) - Customer entry not marked as mandatory.
 - 2012-04-13 Fixed uninitialized value problem in Kernel/Output/HTML/Layout.pm.
 - 2012-04-06 Fixed bug#[8348](http://bugs.otrs.org/show_bug.cgi?id=8348) - Wrong pop-up close behavior when no URL is given
    and SessionUseCookie is set to No.
 - 2012-04-06 Fixed bug#[8346](http://bugs.otrs.org/show_bug.cgi?id=8346) - Incoming phone calls trigger NewTicket
    notification, even for existing tickets.
 - 2012-04-06 Fixed bug#[8353](http://bugs.otrs.org/show_bug.cgi?id=8353) - Small typo in print CSS.
 - 2012-04-06 Fixed bug#[8370](http://bugs.otrs.org/show_bug.cgi?id=8370) - AgentTicketForward does not set pending date for pending states.
 - 2012-04-05 Fixed bug#[8368](http://bugs.otrs.org/show_bug.cgi?id=8368) - Personal queues update is not reflected in UI.
 - 2012-04-03 Fixed bug#[8363](http://bugs.otrs.org/show_bug.cgi?id=8363) - SOAP Transport can't send a value '0'.
 - 2012-04-02 Added new Slovenian translation, thanks to Gorazd Zagar and Andrej Cimerlajt!
 - 2012-04-02 Updated Italian translation, thanks to Massimo Bianchi!
 - 2012-03-30 Fixed bug#[8356](http://bugs.otrs.org/show_bug.cgi?id=8356) - ACLs for DynamicFields does not work on AgentTicketSearch.
 - 2012-03-30 Added new config feature to limit the number of 'From' entries in
    AgentTicketPhone to 1 (optional). Use the setting
    'Ticket::Frontend::AgentTicketPhone::AllowMultipleFrom' if you want this.
 - 2012-03-29 Fixed uninitialized value error in Kernel/System/Log.pm.
 - 2012-03-29 Added caching for DynamicFieldValue entries to improve system performance.
 - 2012-03-29 Fixed bug#[8336](http://bugs.otrs.org/show_bug.cgi?id=8336) - otrs.ExportStatsToOPM.pl  broken.
 - 2012-03-29 Fixed bug#[8349](http://bugs.otrs.org/show_bug.cgi?id=8349) - Caching breaks Admin frontend.
 - 2012-03-26 Improved performance on MySQL databases by removing useless LOWER statements.
 - 2012-03-26 Fixed bug#[7877](http://bugs.otrs.org/show_bug.cgi?id=7877) - SMIME emails don't get parsed properly.
 - 2012-03-23 Disabled error message in RemoveSessionID().
 - 2012-03-23 Repaired broken cache handling in DynamicFieldList().

# 3.1.3 2012-03-29
 - 2012-03-27 Fixed bug#[8343](http://bugs.otrs.org/show_bug.cgi?id=8343) - Configuration of additional modules can be lost during upgrade.
 - 2012-03-22 Renamed form id in AgentLinkObject.dtl to make sure it doesn't interfere with wrong CSS
 - 2012-03-22 Updated Portugese translation, thanks to Rui Francisco!
 - 2012-03-21 Fixed bug#[8333](http://bugs.otrs.org/show_bug.cgi?id=8333) - Type option '-' should not be available in
    ActionTicketCommon screens.
 - 2012-03-20 Fixed bug#[8331](http://bugs.otrs.org/show_bug.cgi?id=8331) - Unable to delete ticket with \> 1000 articles
    on Oracle database.
 - 2012-03-20 Fixed bug#[8335](http://bugs.otrs.org/show_bug.cgi?id=8335) - Cache keys are not always properly constructed.
 - 2012-03-20 Dynamic fields and associated values can now be deleted in the admin area.
 - 2012-03-20 Do not show the empty item in dynamic field search fields.
 - 2012-03-19 Fixed an issue where DBUpdate-to-3.1.pl would die because
    of certain free text or free time configuration settings.
 - 2012-03-19 Fixed bug#[8334](http://bugs.otrs.org/show_bug.cgi?id=8334) migration fails if FreeTime fields are not in use.
 - 2012-03-18 Added internal cache to Kernel/System/Lock.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/Salutation.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/Type.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/Valid.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/Queue.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/State.pm to improve performance.
 - 2012-03-18 Added internal cache to Kernel/System/Priority.pm to improve performance.
 - 2012-03-18 Improved performance of Kernel/Modules/AdminPackageManager.
 - 2012-03-18 Improved performance of Kernel/System/Package.pm.
 - 2012-03-17 Improved performance by using SlaveDB in Dashboard if it is configured.
 - 2012-03-17 Improved performance by using Digest::SHA if it is available.
 - 2012-03-16 Added cache to Kernel/System/XML.pm to improve performance.
 - 2012-03-16 Added cache to Kernel/System/Package.pm to improve performance.
 - 2012-03-15 Fixed bug#[8320](http://bugs.otrs.org/show_bug.cgi?id=8320) - IMAP FLAGS (\Seen \Recent) are appended to article body
    by upgrading bundled Net::IMAP::Simple to version 1.2030.
 - 2012-03-14 Added internal cache to user preferences backend to improve performance.
 - 2012-03-14 Added internal cache to customer user preferences backend to improve performance.
 - 2012-03-14 Added internal cache to queue preferences backend to improve performance.
 - 2012-03-14 Added internal cache to service preferences backend to improve performance.
 - 2012-03-14 Added internal cache to sla preferences backend to improve performance.
 - 2012-03-09 Fixed bug#[8286](http://bugs.otrs.org/show_bug.cgi?id=8286) - Adressbook forgets selected entries.
 - 2012-03-07 Fixed bug#[8297](http://bugs.otrs.org/show_bug.cgi?id=8297) - Selectbox for new owner causes ajax update
    on every change made via keyboard.
 - 2012-03-07 Updated Catalan translation, thanks to Antionio Linde!
 - 2012-03-05 Fixed bug#[7545](http://bugs.otrs.org/show_bug.cgi?id=7545) - AgentTicketBounce lacks permission checks.

# 3.1.2 2012-03-06
 - 2012-03-01 Fixed bug#[8282](http://bugs.otrs.org/show_bug.cgi?id=8282) - Dropdown and Multiselect Dynamic Fields without Possible values
    causes errors with LayoutObject BuildSelection function.
 - 2012-03-01 Fixed bug#[8277](http://bugs.otrs.org/show_bug.cgi?id=8277) - DynamicField Values not deleted when ticket is deleted.
 - 2012-02-28 Fixed bug#[8274](http://bugs.otrs.org/show_bug.cgi?id=8274) - Dynamic Fields ACLs does not work correctly at Ticket Split.
 - 2012-02-28 Improved #[7526](http://bugs.otrs.org/show_bug.cgi?id=7526) - Fixed handling of special characters (, ), &, - within statistics.
 - 2012-02-27 Fixed bug#[8255](http://bugs.otrs.org/show_bug.cgi?id=8255) - TicketSearch in DynamicFields doesn't support ExtendedSearchCondition.
 - 2012-02-25 Fixed bug#[8258](http://bugs.otrs.org/show_bug.cgi?id=8258) - DynamicField date value is reset to NULL.
 - 2012-02-23 Fixed bug#[8214](http://bugs.otrs.org/show_bug.cgi?id=8214) - OTRS Init script on Red Hat / SUSE fails to check scheduler.
 - 2012-02-23 Fixed bug#[8227](http://bugs.otrs.org/show_bug.cgi?id=8227) - LDAP user syncronisation doesn't work.
 - 2012-02-23 Fixed bug#[8235](http://bugs.otrs.org/show_bug.cgi?id=8235) - Searching on DynamicFields, results are lost on next page.
 - 2012-02-21 Fixed bug#[8252](http://bugs.otrs.org/show_bug.cgi?id=8252) - Small typo in German translation of AgentTicketZoom.
 - 2012-02-16 Fixed bug#[8226](http://bugs.otrs.org/show_bug.cgi?id=8226) - Problem with Customized DynamicFields in TicketOverviewSmall.
 - 2012-02-16 Fixed bug#[8233](http://bugs.otrs.org/show_bug.cgi?id=8233) - DB error migrating stats on Oracle.
 - 2012-02-14 Fixed bug#[8224](http://bugs.otrs.org/show_bug.cgi?id=8224) - Admin Responses screen does not allow to filter responses.
 - 2012-02-14 Fixed bug#[7652](http://bugs.otrs.org/show_bug.cgi?id=7652) - OpenSearch providers are served with wrong mime type.
    Follow-up fix.
 - 2012-02-14 Fixed bug#[8140](http://bugs.otrs.org/show_bug.cgi?id=8140) - Shortcut for creating new e-mail ticket doesn't work.
    The hotkey for "new email ticket" was changed from e to m to avoid a collision.
 - 2012-02-14 Fixed bug#[8144](http://bugs.otrs.org/show_bug.cgi?id=8144) - Typo and improved logging in GenericAgent.pm.
 - 2012-02-14 Fixed bug#[8183](http://bugs.otrs.org/show_bug.cgi?id=8183) - Canceling AgentTicketCompose on an unlocked ticket generates
    ChallengeToken error.
 - 2012-02-13 Fixed bug#[8219](http://bugs.otrs.org/show_bug.cgi?id=8219) - TicketCreate and TicketUpdate GI ticket operations requires a valid
    CustomerUser.
 - 2012-02-13 Fixed bug#[8201](http://bugs.otrs.org/show_bug.cgi?id=8201) - Popup in browser always open on leftmost display when using
    dual monitor setup.
 - 2012-02-13 Fixed bug#[8202](http://bugs.otrs.org/show_bug.cgi?id=8202) - Kernel::System::JSON-\>Decode() dies when providing malformed JSON.
 - 2012-02-13 Fixed bug#[8211](http://bugs.otrs.org/show_bug.cgi?id=8211) - Typos in Labels: DYNAMICFILED.
 - 2012-02-09 Fixed bug#[7109](http://bugs.otrs.org/show_bug.cgi?id=7109) - Statistics error when PDF support is not active.

# 3.1.1 2012-02-14
 - 2012-02-09 Fixed bug#[8184](http://bugs.otrs.org/show_bug.cgi?id=8184) - Uninstall and upgrade fails if file in package can't be removed.
 - 2012-02-09 Fixed bug#[8199](http://bugs.otrs.org/show_bug.cgi?id=8199) - Linked tickets open only in tabs.
 - 2012-02-03 Fixed bug#[8148](http://bugs.otrs.org/show_bug.cgi?id=8148) - Wrong presentation of queue structure in CustomerTicketMessage.
 - 2012-02-03 Fixed bug#[8137](http://bugs.otrs.org/show_bug.cgi?id=8137) - Issues with Owner list refresh when selecting a new Owner.
 - 2012-02-03 Fixed bug#[8180](http://bugs.otrs.org/show_bug.cgi?id=8180) - bin/otrs.LoaderCache.pl exit code is wrong.

# 3.1.0 rc1 2012-02-07
 - 2012-02-03 Fixed bug#[8171](http://bugs.otrs.org/show_bug.cgi?id=8171) - Table rows have different heights.
 - 2012-02-02 Fixed bug#[7937](http://bugs.otrs.org/show_bug.cgi?id=7937) - HTMLUtils.pm ignore to much of e-mail source code.
 - 2012-02-02 Fixed bug#[7972](http://bugs.otrs.org/show_bug.cgi?id=7972) - Some mails may not present HTML part when using rich viewing.
 - 2012-02-02 Fixed bug#[8179](http://bugs.otrs.org/show_bug.cgi?id=8179) - DynamicField backend DateTime renders timestamps with seconds.
 - 2012-01-31 Fixed bug#[8163](http://bugs.otrs.org/show_bug.cgi?id=8163) - Ticket / Article title can't be copied if value is too long.
 - 2012-01-31 Fixed bug#[8161](http://bugs.otrs.org/show_bug.cgi?id=8161) - History hover broken - missing title attribute.
 - 2012-01-30 Fixed bug#[8147](http://bugs.otrs.org/show_bug.cgi?id=8147) - Possible values for queues not being considered in ACLs.
 - 2012-01-30 Fixed bug#[8021](http://bugs.otrs.org/show_bug.cgi?id=8021) - Creating new Dynamic Field is not adding the field name
    to the X-OTRS header lists configuration for the PostMaster filters.
 - 2012-01-27 Fixed bug#[8145](http://bugs.otrs.org/show_bug.cgi?id=8145) - TicketFreeTime entries in search profiles don't get updated.
 - 2012-01-27 Fixed bug#[2820](http://bugs.otrs.org/show_bug.cgi?id=2820) - Wide character in Syslog message causes Perl crash on utf8 systems.

# 3.1.0 beta5 2012-01-31
 - 2012-01-25 Fixed bug#[7890](http://bugs.otrs.org/show_bug.cgi?id=7890) - Changed wording of config setting for RFC 5321 compliance.
 - 2012-01-24 Fixed bug#[8068](http://bugs.otrs.org/show_bug.cgi?id=8068) - Corrected field & DynamicField preselection on TicketSplit.
 - 2012-01-24 Fixed bug#[8115](http://bugs.otrs.org/show_bug.cgi?id=8115) - Richtext editor not show in customer interface after switching
    to Catalan frontend language.
 - 2012-01-23 Fixed bug#[7994](http://bugs.otrs.org/show_bug.cgi?id=7994) - ACL: action-restrictions not possible for all ticket actions.
 - 2012-01-23 Fixed bug#[7984](http://bugs.otrs.org/show_bug.cgi?id=7984) - Unable to select the output format of statistics.
 - 2012-01-23 Fixed bug#[8136](http://bugs.otrs.org/show_bug.cgi?id=8136) - Browser Time Detection and time zone UTC generates warning in
    web server error log.
 - 2012-01-23 Fixed bug#[8132](http://bugs.otrs.org/show_bug.cgi?id=8132) - Browser version message misleading when 'compatibility mode'
    is enabled in Internet Explorer.
 - 2012-01-23 Fixed bug#[7916](http://bugs.otrs.org/show_bug.cgi?id=7916) - Address Book doesn't work correctly.
 - 2012-01-23 Fixed bug#[8019](http://bugs.otrs.org/show_bug.cgi?id=8019) - Ticket customer info widget has unneeded scroll bars.
 - 2012-01-23 Fixed bug#[8066](http://bugs.otrs.org/show_bug.cgi?id=8066) - TicketAcl with empy possible List for DynamicFields crashes.
 - 2012-01-20 Fixed bug#[7495](http://bugs.otrs.org/show_bug.cgi?id=7495) - Cursor stands still in editor in IE 9.
 - 2012-01-20 Fixed bug#[8129](http://bugs.otrs.org/show_bug.cgi?id=8129) - Ticket Unwatch may lead to errorscreen.
 - 2012-01-20 Updated Finnish translation file, thanks to Mikko Hynninen!
 - 2012-01-17 Fixed bug#[8117](http://bugs.otrs.org/show_bug.cgi?id=8117) - Can't create ticket for newly created customer user.
 - 2012-01-16 Fixed bug#[8094](http://bugs.otrs.org/show_bug.cgi?id=8094) - Typo In Ticket.pm.
 - 2012-01-16 Creation of QueueObject was not possible because of missing EncodeObject in CustomerUserGenericTicket.pm.

# 3.1.0 beta4 2012-01-17
 - 2012-01-12 Fixed bug#[8107](http://bugs.otrs.org/show_bug.cgi?id=8107) - Ticket state is not set as default on ticket edit screens.
 - 2012-01-12 Fixed bug#[8105](http://bugs.otrs.org/show_bug.cgi?id=8105) - Changing Priority does not update all relevant SysConfig fields.
 - 2012-01-11 Dramatically improved HTML rendering performance for pages with a large
    amount of data, thanks to Stefan Bedorf!
 - 2012-01-11 Fixed bug#[8103](http://bugs.otrs.org/show_bug.cgi?id=8103) - Edit screens does not get Dynamic Field values from selected ticket.
 - 2012-01-11 Fixed bug#[8070](http://bugs.otrs.org/show_bug.cgi?id=8070) - Configured year ranges do not apply for date DynamicFields.
 - 2012-01-11 Updated CPAN module YAML to version 0.78.
 - 2012-01-11 Updated CPAN module Net::IMAP::Simple to version 1.20271.
 - 2012-01-11 Updated CPAN module LWP::UserAgent to version 6.03.
 - 2012-01-11 Updated CPAN module Digest::SHA::PurePerl to version 5.70.
 - 2012-01-11 Updated CPAN module CGI to version 3.59.
 - 2012-01-10 Fixed bug#[8095](http://bugs.otrs.org/show_bug.cgi?id=8095) - Dashboard ticket list does not support DynamicFields.
 - 2012-01-10 Ticket search and ticket link should require at least one search parameter.
 - 2012-01-09 Improved consistency of ChallengeToken checks in the agent and admin interface.
 - 2012-01-03 Updated Serbian translation, thanks to Milorad Jovanovic!
 - 2011-12-23 Fixed bug#[8052](http://bugs.otrs.org/show_bug.cgi?id=8052) - ACLs code is called even when there is no defined ACL or ACL module.
 - 2011-12-23 Fixed bug#[8037](http://bugs.otrs.org/show_bug.cgi?id=8037) - Registration screen in web installer produces HTTP 500 error.
 - 2011-12-22 Fixed bug#[7947](http://bugs.otrs.org/show_bug.cgi?id=7947) - Service list can be made useless with simple ACL and/or disabling
    services.
 - 2011-12-22 Fixed bug#[8049](http://bugs.otrs.org/show_bug.cgi?id=8049) - TicketFreeText X-headers should not exist on new installations.
 - 2011-12-22 Fixed bug#[8043](http://bugs.otrs.org/show_bug.cgi?id=8043) - TicketSplit does not use default ACLs from parent.
 - 2011-12-21 Fixed bug#[8044](http://bugs.otrs.org/show_bug.cgi?id=8044) - TicketACL does not get dynamic fields as ticket attributes always.
 - 2011-12-21 Fixed bug#[8039](http://bugs.otrs.org/show_bug.cgi?id=8039) - SysConfig writes files in a non-atomic way.
 - 2011-12-20 Fixed bug#[4239](http://bugs.otrs.org/show_bug.cgi?id=4239) - Include ticket number in toolbar fulltext search.
 - 2011-12-20 Fixed bug#[7955](http://bugs.otrs.org/show_bug.cgi?id=7955) - Customer identity is not displayed on Customer Interface.
 - 2011-12-20 Fixed bug#[8035](http://bugs.otrs.org/show_bug.cgi?id=8035) - SOAP interface does not allow to create/update
    CustomerCompany records.
 - 2011-12-20 Fixed bug#[8027](http://bugs.otrs.org/show_bug.cgi?id=8027) - Duplicated slash in cache subdirectory names.
 - 2011-12-20 Make sure the customer is being returned to ticket search result after using
    'back' link from a ticket he has reached from the search result page.
 - 2011-12-19 Fixed bug#[7666](http://bugs.otrs.org/show_bug.cgi?id=7666) - Queue Preferences potentially slow.
 - 2011-12-19 Updated Polish translation file, thanks to Pawel!
 - 2011-12-16 Fixed Lithuanian language file encoding.
 - 2011-12-16 Added OTRS 2.4-style article colors to the article list in AgentTicketZoom.
    This is disabled by default, enable 'Ticket::UseArticleColors' in SysConfig to use it.

# 3.1.0 beta3 2011-12-20
 - 2011-12-15 Fixed bug#[8012](http://bugs.otrs.org/show_bug.cgi?id=8012) - Confusing dashboard filter names.
 - 2011-12-14 Fixed bug#[8000](http://bugs.otrs.org/show_bug.cgi?id=8000) - Queues are translated if are displayed in list-style.
 - 2011-12-13 Added feature bug#[7893](http://bugs.otrs.org/show_bug.cgi?id=7893) - Customer Info in TicketZoom can now also list open tickets
    based on CustomerUserLogin rather than CustomerID, and can list closed tickets as well.
 - 2011-12-13 Fixed bug#[8020](http://bugs.otrs.org/show_bug.cgi?id=8020) - Queue list in new move window has the current queue enabled.
 - 2011-12-13 Fixed bug#[8017](http://bugs.otrs.org/show_bug.cgi?id=8017) - After first AJAXUpdate call, MultiSelect DynamicFields gets empty.
 - 2011-12-13 Fixed bug#[7999](http://bugs.otrs.org/show_bug.cgi?id=7999) - Uncheck all services for a customer doesn't work.
 - 2011-12-13 Fixed bug#[7005](http://bugs.otrs.org/show_bug.cgi?id=7005) - JavaScript Init function is executed more than once in TicketZoom.
 - 2011-12-13 Fixed bug#[7020](http://bugs.otrs.org/show_bug.cgi?id=7020) - Error in MySQL Syntax when CustomerID contains special characters.
 - 2011-12-12 Improved #7526 - Automatic TicketSearch for special characters (, ), &, - fails.
 - 2011-12-12 Fixed bug#[8009](http://bugs.otrs.org/show_bug.cgi?id=8009) - Statistic overview does not show the statistic object name
    for static statistics.
 - 2011-12-12 Changed the default behaviour of TicketGet() and ArticleGet() to NOT return the
    dynamic field values for performance reasons. If you need them, pass DynamicFields =\> 1.
 - 2011-12-09 Fixed bug#[7014](http://bugs.otrs.org/show_bug.cgi?id=7014) - Inline article gets bigger than Ticket::Frontend::HTMLArticleHeightMax.
 - 2011-12-09 Removed compatibility modules AgentTicketMailbox and CustomerZoom
    (these only performed redirects to newer screens).
 - 2011-12-09 Fixed bug#[7997](http://bugs.otrs.org/show_bug.cgi?id=7997) - Fetching mail via AdminMailAccount does not work.
 - 2011-12-09 Fixed bug#[7991](http://bugs.otrs.org/show_bug.cgi?id=7991) - Locale::Codes is not bundled in 3.1.0beta2 tarball, breaking Customer Cumpany
    screen.
 - 2011-12-09 Fixed bug#[7995](http://bugs.otrs.org/show_bug.cgi?id=7995) - Previous owner is missing in AgentTicketMove.
 - 2011-12-09 Updated Japanese Translation, thanks to Kaoru Hayama!
 - 2011-12-08 A bug related to oracle made database updates necessary ON ALL PLATFORMS when upgrading from beta1 or beta2.
    Please see the UPGRADING file for details.
 - 2011-12-07 Fixed bug#[7959](http://bugs.otrs.org/show_bug.cgi?id=7959) - Problem when entering a customer in the autocomplete field in AgentTicketPhone.
 - 2011-12-07 Fixed bug#[7976](http://bugs.otrs.org/show_bug.cgi?id=7976) - Add Event Trigger Asynchronous not correctly displayed in Event Triggers Table.
 - 2011-12-06 Fixed bug#[7981](http://bugs.otrs.org/show_bug.cgi?id=7981) - Stats sum on X axis does not display total if the total is zero.
 - 2011-12-06 Fixed bug#[4740](http://bugs.otrs.org/show_bug.cgi?id=4740) - HTTP header in Redirect is not syntactically correct.
 - 2011-12-06 Fixed bug#[5253](http://bugs.otrs.org/show_bug.cgi?id=5253) - User preferences are updated when displaying an overview.
 - 2011-12-05 Fixed bug#[5356](http://bugs.otrs.org/show_bug.cgi?id=5356) - TicketFreeText (now Dynamic Fields) containing domain name - causes
    Agent interface issues
 - 2011-12-05 Fixed bug#[3334](http://bugs.otrs.org/show_bug.cgi?id=3334) - FreeFields (now Dynamic Fields) with content "0" aren't displayed
    within TicketZoom view
 - 2011-12-05 Fixed bug#[4032](http://bugs.otrs.org/show_bug.cgi?id=4032) - TicketFreeText (now Dynamic Fields)- DefaultSelection does not work
    for AgentTicketForward
 - 2011-12-05 Fixed bug#[7923](http://bugs.otrs.org/show_bug.cgi?id=7923) - Free field value not correctly migrated error on DBUpdate-to-3.1.pl.
 - 2011-12-05 Fixed bug#[7975](http://bugs.otrs.org/show_bug.cgi?id=7975) - Wrong Type parameter is sent on Dynamic Fields ACLs.
 - 2011-12-05 Fixed bug#[7968](http://bugs.otrs.org/show_bug.cgi?id=7968) - DynamicField empty value "-" disappears on AJAX reload.
 - 2011-12-05 Fixed bug#[3544](http://bugs.otrs.org/show_bug.cgi?id=3544) - Don't show link to AgentTicketCustomer if agent does not have
    permissions.
 - 2011-12-05 Fixed bug#[7900](http://bugs.otrs.org/show_bug.cgi?id=7900) - DefaultQueue does not preselect queue in CustomerTicketMessage.
 - 2011-12-05 Fixed bug#[7184](http://bugs.otrs.org/show_bug.cgi?id=7184) - Service catalog is not useable with sophisticated amount of entries.
 - 2011-12-05 Fixed bug#[7864](http://bugs.otrs.org/show_bug.cgi?id=7864) - Inconsequent wrapping of text causes ugly notifications.
 - 2011-12-05 Fixed bug#[7967](http://bugs.otrs.org/show_bug.cgi?id=7967) - Misleading comment on DF Dropdown setup.
 - 2011-12-05 Fixed bug#[7966](http://bugs.otrs.org/show_bug.cgi?id=7966) - Little german translation enhancement.
 - 2011-12-02 Fixed bug#[5437](http://bugs.otrs.org/show_bug.cgi?id=5437) - Reload of TicketFreeTexFields (now DynamicFields) (for ACL).
 - 2011-12-02 Fixed bug#[7056](http://bugs.otrs.org/show_bug.cgi?id=7056) - AgentTicketMove.pm does not handle TicketFreeText
    (now DynamicFields) correctly.
 - 2011-12-02 Fixed bug#[7442](http://bugs.otrs.org/show_bug.cgi?id=7442) - Dashboard permission check for multiple Groups only
    tests first group.
 - 2011-12-02 Fixed bug#[4548](http://bugs.otrs.org/show_bug.cgi?id=4548) - 'Ajax overwrites OnChange' in BuildSelection().

# 3.1.0 beta2 2011-12-06
 - 2011-11-30 Fixed bug#[6715](http://bugs.otrs.org/show_bug.cgi?id=6715) - Setting CustomerID with otrs.AddCustomerUser.pl.
 - 2011-11-29 Fixed bug#[7719](http://bugs.otrs.org/show_bug.cgi?id=7719) - Agent login page does not offer user to save password
    with Firefox browser.
 - 2011-11-29 Fixed bug#[4957](http://bugs.otrs.org/show_bug.cgi?id=4957) - Password Change dialog misses "Current Password" option.
 - 2011-11-29 Show Article Creator in article view, similar to Idea#378.
 - 2011-11-28 Updated CPAN module Apache::DBI to version 1.11.
 - 2011-11-28 Updated CPAN module Mozilla::CA to version 20111025.
 - 2011-11-26 Added ReferenceData object that provides ISO-3166 country codes.
    Could be extend to contain other data later.
 - 2011-11-23 Fixed bug#[7926](http://bugs.otrs.org/show_bug.cgi?id=7926) - AJAX refresh does not work on some fields.
 - 2011-11-24 Fixed bug#[7931](http://bugs.otrs.org/show_bug.cgi?id=7931) - Operations and Invokers can't be deleted from web service if the
    Controller is not present or not  registered.
 - 2011-11-23 Fixed bug#[7921](http://bugs.otrs.org/show_bug.cgi?id=7921) - Running DBUpdate-to-3.1-post.mssql.sql on Microsoft SQL Server
    generates errors.
 - 2011-11-23 Added Idea#378 - Show ticket creator in zoom view.
 - 2011-11-23 Fixed bug#[6139](http://bugs.otrs.org/show_bug.cgi?id=6139) - Hide current queue in queue move dialog in AgentTicketZoom.
 - 2011-11-23 Fixed bug#[6365](http://bugs.otrs.org/show_bug.cgi?id=6365) - AdminMailAccount Queue field should be hidden or disabled if Dispatching
    is set to 'By Mail'.
 - 2011-11-23 Fixed bug#[7930](http://bugs.otrs.org/show_bug.cgi?id=7930) - Depreciation warnings in error log when running OTRS on
    Perl 5.14.
 - 2011-11-21 Fixed bug#[7914](http://bugs.otrs.org/show_bug.cgi?id=7914) - DynamicField value Storage on AgentTicketActionCommon.pm and
    AgentTicketPhoneCommon.pm.
 - 2011-11-21 Fixed bug#[7923](http://bugs.otrs.org/show_bug.cgi?id=7923) - Free field value not correctly migrated error on DBUpdate-to-3.1.pl.
 - 2011-11-21 Fixed bug#[3804](http://bugs.otrs.org/show_bug.cgi?id=3804) - Stats in Bar or Pie chart formats don't display non-
    ascii characters correctly.
 - 2011-11-21 Fixed bug#[7920](http://bugs.otrs.org/show_bug.cgi?id=7920) - New ACL mechanism does not update Ticket{StateType} when a State
    or StateID is given.
 - 2011-11-21 Use the secure attribute to restrict cookies to HTTPS if it is used.
 - 2011-11-21 Fixed bug#[7909](http://bugs.otrs.org/show_bug.cgi?id=7909) - Errors should be logged in web server error log only.
 - 2011-11-21 Added feature to drag and drop/copy and paste images to richtext editor in firefox (base64 encoded).
 - 2011-11-19 Fixed bug#[7917](http://bugs.otrs.org/show_bug.cgi?id=7917) - New ACL mechanism does not generate DynamicField hash check when
    only TicketID is given.

# 3.1.0 beta1 2011-11-22
 - 2011-11-15 Added IE7 to browser blacklist.
 - 2011-11-15 Updated German translation.
 - 2011-11-14 Fixed bug#[7526](http://bugs.otrs.org/show_bug.cgi?id=7526) - OTRS Ticket Search not working with ( or ).
 - 2011-11-14 Added Idea#724 - Connect to IMAP servers using TLS encryption.
 - 2011-11-14 Fixed bug#[7879](http://bugs.otrs.org/show_bug.cgi?id=7879) - Add the option to get mail from a specified IMAP folder.
 - 2011-11-14 Added new 'registration' mask to install process.
 - 2011-11-10 Fixed bug#[5863](http://bugs.otrs.org/show_bug.cgi?id=5863) - Added autocomplete for Cc and Bcc in AgentTicketCompose
 - 2011-11-10 Fixed AgentBook (addressbook) to cooperate with the new autocomplete handling
    in the ticket screens.
 - 2011-11-08 Fixed correct validation handling of RTE.
 - 2011-11-07 Fixed spelling mistake in README.
 - 2011-11-04 Removed 'address' and 'div' style formats from CKEditor.
 - 2011-11-04 Added support for CKEditor on iPhone and iPad with iOS5.
 - 2011-11-04 Added config option Frontend::AgentLinkObject::WildcardSearch to enable
    wildcard search if the AgentLinkObject mask is started.
 - 2011-11-01 Added functionality to allow to use auto-complete feature for more
    than one entry in To, From, Cc and Bcc fields into TicketPhone and EmailTicket screens.
 - 2011-10-31 Fixed bug#[7454](http://bugs.otrs.org/show_bug.cgi?id=7454) - MSSQL should use NVARCHAR to store text strings rather than VARCHAR.
 - 2011-10-31 Fixed bug#[7858](http://bugs.otrs.org/show_bug.cgi?id=7858) - Make "Apache::DBI" option not being overwritten with each update.
    Apache::DBI is now loaded in web server configuration file.
 - 2011-10-28 Updated CKEditor to 3.6.2.
 - 2011-10-28 Updated json2.js to current version 2011-10-19.
 - 2011-10-28 Updated stacktrace.js to 0.3.
 - 2011-10-28 Updated jQuery Validate plugin to 1.9.
 - 2011-10-28 Updated jQuery UI to 1.8.16.
 - 2011-10-28 Updated jQuery to 1.6.4.
 - 2011-10-24 Fixed bug#[7824](http://bugs.otrs.org/show_bug.cgi?id=7824) - Tickets locked through 'tmp\_lock' lock type aren't shown as locked
    tickets
 - 2011-10-20 Fixed bug#[7168](http://bugs.otrs.org/show_bug.cgi?id=7168) - Ticket Overview Control Row can only be one line high.
 - 2011-09-28 Fixed Ticket#2011080542009673 - Improved location check for \_FileInstall().
 - 2011-09-26 Added missing cpan module Encode::Locale which is now required
    for HTTP::Response and LWP::UserAgent.
 - 2011-09-16 Added new legacy driver for PostgreSQL 8.1 or earlier. This
    needs to be activated for such older installations in Kernel/Config.pm
    as follows:
```perl
    $Self->{DatabasePostgresqlBefore82} = 1;
```
 - 2011-09-09 Updated CPAN module Mozilla::CA to version 20110904.
 - 2011-09-06 Converted all translation files to utf-8.
 - 2011-09-01 Changed Postgresql driver to also use standard\_conforming\_strings
    in regular database connections.
 - 2011-09-01 Fixed bug#[7684](http://bugs.otrs.org/show_bug.cgi?id=7684) - PostMaster Filter Module fails to create ticket
    if state set in filter is invalid.
 - 2011-08-30 Updated CPAN module SOAP::Lite to version 0.714.
 - 2011-08-30 Updated CPAN module libwww-perl to version 6.02.
 - 2011-08-30 Updated CPAN module YAML to version 0.73.
 - 2011-08-30 Updated CPAN module URI to version 1.59.
 - 2011-08-30 Updated CPAN module Text::Diff to version 1.41.
 - 2011-08-30 Updated CPAN module Proc::Daemon to version 0.14.
 - 2011-08-30 Updated CPAN module Net::SMTP::TLS::ButMaintained to version 0.18.
 - 2011-08-30 Updated CPAN module Net::IMAP::Simple to version 1.2024.
 - 2011-08-30 Updated CPAN module Mozilla::CA to version 20110409.
 - 2011-08-30 Updated CPAN module MailTools to version 2.08.
 - 2011-08-30 Updated CPAN module JSON to version 2.53.
 - 2011-08-30 Updated CPAN module JSON::PP to version 2.27200.
 - 2011-08-30 Updated CPAN module HTTP::Message to version 6.02.
 - 2011-08-30 Updated CPAN module Digest::SHA::PurePerl to version 5.62.
 - 2011-08-30 Updated CPAN module CGI to version 3.55.
 - 2011-08-24 Fixed bug#[6718](http://bugs.otrs.org/show_bug.cgi?id=6718) - error when running otrs-initial-insert.postgresql.sql by making
    otrs.xml2sql.pl write out utf8 files and by adding 'SET standard\_conforming\_strings TO ON'.
 - 2011-08-22 Fixed bug#[7635](http://bugs.otrs.org/show_bug.cgi?id=7635) - Remove support for Suse 9.
 - 2011-08-22 Fixed bug#[6444](http://bugs.otrs.org/show_bug.cgi?id=6444) - OTRS rc scripts checks and stops local mysql database
    and complains about having no database if you use a remote one.
 - 2011-08-22 Fixed bug#[7638](http://bugs.otrs.org/show_bug.cgi?id=7638) - OTRS rc scripts installation/check/stop of Scheduler service.
 - 2011-08-22 Fixed bug#[2365](http://bugs.otrs.org/show_bug.cgi?id=2365) - Removed dependency on MySQL in RPMs.
 - 2011-08-12 Removed support for non-utf-8 internal encodings.
 - 2011-07-29 Fixed bug#[7538](http://bugs.otrs.org/show_bug.cgi?id=7538) - CustomerSearchAutoComplete###QueryDelay has incorrect pattern match.
 - 2011-07-20 Added feature bug#[976](http://bugs.otrs.org/show_bug.cgi?id=976) - Send emails via bulk action.
 - 2011-07-18 Added feature bug#[7479](http://bugs.otrs.org/show_bug.cgi?id=7479) - Add "TicketChangeTime" as filter parameter
    in Generic agent.
 - 2011-07-01 Now stores binary data in VARBINARY rather than deprecated type
    TEXT on MS SQL Server.
 - 2011-07-01 Fixed bug#[7454](http://bugs.otrs.org/show_bug.cgi?id=7454) - MS SQL should use NVARCHAR to store text strings
    rather than VARCHAR.
 - 2011-06-21 TicketGet() now also returns ChangeBy and CreateBy.
 - 2011-06-06 Fixed bug#[4946](http://bugs.otrs.org/show_bug.cgi?id=4946) - Notification mails lack "Precedence: bulk" or similar headers.
 - 2011-05-20 Added feature bug#[7340](http://bugs.otrs.org/show_bug.cgi?id=7340) - It's not possible to sort tickets on last changed date.
 - 2011-05-18 Added feature bug#[7207](http://bugs.otrs.org/show_bug.cgi?id=7207) - Display warning if user is logged in and out-of-office
    is activated.
 - 2011-05-16 Added feature bug#[7316](http://bugs.otrs.org/show_bug.cgi?id=7316) - Possibility to exclude articles of certain sender types from
    being displayed in OverviewPreview mode and to display a certain article type as expanded when
    entering the view.
 - 2011-05-03 Added feature Ideascale#488 - Use ticket number in the URL to access to
    its zoom view.
 - 2011-05-02 Added feature bug#[6108](http://bugs.otrs.org/show_bug.cgi?id=6108) / Ideascale#87 - add the possibility to
    register inbound phone conversations.
 - 2011-04-29 Added enhancement bug#[7267](http://bugs.otrs.org/show_bug.cgi?id=7267) 0 Performance issue in dtl with large
    pages. Thanks to Stelios Gikas \<stelios.gikas@noris.net\>!
 - 2011-04-29 Added enhancement bug#[7266](http://bugs.otrs.org/show_bug.cgi?id=7266) - Performance issue in ticket zoom -
    article seen with many article. Thanks to Stelios Gikas \<stelios.gikas@noris.net\>!
 - 2011-04-27 Added feature bug#[5484](http://bugs.otrs.org/show_bug.cgi?id=5484) / IdeaScale#497 - Bulk action to set/change Ticket Type.
 - 2011-04-27 Added feature bug#[7258](http://bugs.otrs.org/show_bug.cgi?id=7258) - Stats output always has a timestamp and report name in
    the filename.
 - 2011-04-27 Fixed bug#[7257](http://bugs.otrs.org/show_bug.cgi?id=7257) - Stats CSV outputs report name and timestamp as first line.
 - 2011-04-27 Added feature bug#[5607](http://bugs.otrs.org/show_bug.cgi?id=5607) - otrs.GenerateStats.pl report only can be sent to one
    recipient at a time.
 - 2011-04-27 Fixed bug#[7211](http://bugs.otrs.org/show_bug.cgi?id=7211) - 'Valid' used in labels is now replaced with 'Validity'.
 - 2011-04-25 Fixed bug#[7236](http://bugs.otrs.org/show_bug.cgi?id=7236) - Ticket::TicketTitleUpdate() does not update change\_time of ticket.
 - 2011-04-20 Fixed ticket#2011041942007629 - Uninitialized value problem in AgentPreferences.pm.
 - 2011-04-20 Fixed bug#[7243](http://bugs.otrs.org/show_bug.cgi?id=7243) - Problem if current\_timestamp of database system is
    different to system time (e. g. time()).
 - 2011-04-19 Fixed bug#[3549](http://bugs.otrs.org/show_bug.cgi?id=3549) - ACLs don't work against queues with nonlatin characters.
 - 2011-04-18 Fixed bug#[7216](http://bugs.otrs.org/show_bug.cgi?id=7216) - Company names containing "&" pulled from Active Directory cause
    errors in error.log when using Company Tickets.
 - 2011-04-06 Added generic notification module to show messages in the agent interface.
 - 2011-04-05 Fixed bug#[7182](http://bugs.otrs.org/show_bug.cgi?id=7182) - AgentDashboard preferences are always translated.
 - 2011-03-29 Fixed bug#[6994](http://bugs.otrs.org/show_bug.cgi?id=6994) - AgentSelfNotifyOnAction is ignored for event based
    notifications.
 - 2011-03-24 Fixed bug#[6981](http://bugs.otrs.org/show_bug.cgi?id=6981) - ReadOnly CustomerUser sources should not be selectable for
    creating new customers.
 - 2011-03-15 Fixed bug#[7057](http://bugs.otrs.org/show_bug.cgi?id=7057) - Kernel::System::StandardResponse-\>StandardResponseLookup() is broken.
 - 2011-03-15 Fixed bug#[7053](http://bugs.otrs.org/show_bug.cgi?id=7053) - Installer page titles are not localized.
 - 2011-03-07 Added feature bug#[6992](http://bugs.otrs.org/show_bug.cgi?id=6992) - Ticket Responsible can't be set by GenericAgent.
 - 2011-03-07 Added feature bug#[6140](http://bugs.otrs.org/show_bug.cgi?id=6140) - Make the refresh interval of the dashboard
    configurable.
 - 2011-03-01 Added feature bug#[6977](http://bugs.otrs.org/show_bug.cgi?id=6977) - Next Screen after AgentTicketMove should
    be configurable.
 - 2011-02-28 Added feature bug#[6894](http://bugs.otrs.org/show_bug.cgi?id=6894). Events for escalations.
 - 2011-02-24 Fixed bug#[6867](http://bugs.otrs.org/show_bug.cgi?id=6867). CustomerCompany external source requires
    change\_time and create\_time columns.
 - 2011-02-07 Fixed bug#[2452](http://bugs.otrs.org/show_bug.cgi?id=2452) - SMIME encoded E-Mails are not decrypted properly by OTRS.
 - 2011-02-02 Fixed bug#[3125](http://bugs.otrs.org/show_bug.cgi?id=3125) - No translation for ticket-state in notifications.
 - 2011-02-02 Fixed bug#[6618](http://bugs.otrs.org/show_bug.cgi?id=6618) - TicketIndex can not be created if queue name
     of \> 70 characters exists.

# 3.0.22 2013-07-09
 - 2013-06-25 Improved parameter quoting in various places.

# 3.0.21 2013-06-18
 - 2013-06-06 Improved permission checks in AgentTicketWatcher.

# 3.0.20 2013-05-21
 - 2013-05-17 Updated Package Manager, that will ensure that packages to be installed
    meet the quality standards of OTRS Group. This is to guarantee that your package
    wasn’t modified, which may possibly harm your system or have an influence on the
    stability and performance of it. All independent package contributors will have
    to conduct a check of their Add-Ons by OTRS Group in order to take full advantage
    of the OTRS package verification.
 - 2013-05-07 Improved permission checks in AgentTicketPhone.
 - 2013-05-07 Fixed bug#[7478](http://bugs.otrs.org/show_bug.cgi?id=7478) - Got an external answer to an internal mail.
 - 2013-04-08 Fixed bug#[9312](http://bugs.otrs.org/show_bug.cgi?id=9312) - LinkObject permission check problem.

# 3.0.19 2013-04-02
 - 2013-03-18 Improved permission checks in LinkObject.

# 3.0.18 2013-03-12
 - 2013-03-04 Updated CKEditor to version 3.6.6.
 - 2013-03-02 Fixed bug#[9214](http://bugs.otrs.org/show_bug.cgi?id=9214) - IE10: impossible to open links from rich text articles.
 - 2012-12-03 Fixed bug#[8933](http://bugs.otrs.org/show_bug.cgi?id=8933) - ArticleStorageInit permission check problem.
 - 2012-11-28 Fixed bug#[8955](http://bugs.otrs.org/show_bug.cgi?id=8955) - Init script might fail on SUSE.
 - 2012-10-23 Fixed bug#[8566](http://bugs.otrs.org/show_bug.cgi?id=8566) - Cannot download attachment if filename has character #.
 - 2012-10-23 Fixed bug#[8833](http://bugs.otrs.org/show_bug.cgi?id=8833) - Article table in TicketZoom does not scroll correctly.
 - 2012-10-23 Fixed bug#[8673](http://bugs.otrs.org/show_bug.cgi?id=8673) - Richtext-Editor popups broken on Customer-Interface.
 - 2012-10-16 Fixed bug#[8149](http://bugs.otrs.org/show_bug.cgi?id=8149) - Wrong handling of subject when SubjectFormat=right.

# 3.0.17 2012-10-16
 - 2012-10-05 Fixed bug#[6820](http://bugs.otrs.org/show_bug.cgi?id=6820) - OTRS crash with "division by zero" if escalation set incorrectly.
 - 2012-09-25 Fixed bug#[8606](http://bugs.otrs.org/show_bug.cgi?id=8606) - Escalation notifications should not be sent to agents who are set out-of-office.
 - 2012-09-13 Improved HTML security filter to better find javascript source URLs.

# 3.0.16 2012-08-30
 - 2012-08-28 Improved HTML security filter to detect tag nesting.
 - 2012-08-24 Fixed bug#[8611](http://bugs.otrs.org/show_bug.cgi?id=8611) - Ticket count is wrong in QueueView.

# 3.0.15 2012-09-04
 - 2012-08-17 HTML mails will now be displayed in an HTML5 sandbox iframe.
    This means that modern browsers will not execute plugins or JavaScript on the content
    any more. Currently, this is supported by Chrome and Safari, but IE10 and FF16 are also
 - 2012-08-17 HTML mails will now be displayed in the restricted zone in IE.
    This means that more restrictive security settings will apply, such as blocking of
    JavaScript content by default.
 - 2012-08-06 Fixed bug#[8672](http://bugs.otrs.org/show_bug.cgi?id=8672) - Search Profile can't have an ampersand in the name via
    Toolbar module.

# 3.0.14 2012-08-07
 - 2012-07-31 Improved robustness of HTML security filter: Detect masked UTF-7 \< and \> signs.
 - 2012-07-16 Fixed bug#[8616](http://bugs.otrs.org/show_bug.cgi?id=8616) - Spell Checker does not work using IE9.
 - 2012-07-16 Fixed JavaScript error when no suggestions can be made by the spell checker.
 - 2012-06-29 Fixed bug#[8618](http://bugs.otrs.org/show_bug.cgi?id=8618) - Inform and Involved Agents select boxes can not be resizable.
 - 2012-06-15 Fixed bug#[7879](http://bugs.otrs.org/show_bug.cgi?id=7879) - Broken Content-Type in forwarded attachments.
 - 2012-06-14 Fixed bug#[8574](http://bugs.otrs.org/show_bug.cgi?id=8574) - Perl special variable $/ is changed and never restored.
 - 2012-06-14 Fixed bug#[8337](http://bugs.otrs.org/show_bug.cgi?id=8337) - Parentheses in user last\_name / first\_name are not sanitized (follow-up fix).
 - 2012-06-12 Fixed bug#[7872](http://bugs.otrs.org/show_bug.cgi?id=7872) - "Created" date in Large view is actually Last Updated date.
 - 2012-06-04 Improved performance of TemplateGenerator.pm, thanks to Stelios Gikas!

# 3.0.13 2012-06-05
 - 2012-05-30 Fixed bug#[7532](http://bugs.otrs.org/show_bug.cgi?id=7532) - 'Field is required' message should be removed in RTE if content is added.
 - 2012-05-30 Fixed bug#[8514](http://bugs.otrs.org/show_bug.cgi?id=8514) - Long words in description break rendering of SysConfig items.
 - 2012-05-25 Fixed bug#[8189](http://bugs.otrs.org/show_bug.cgi?id=8189) - AgentTicketCompose: Pressing "Enter" will delete Attachment.
 - 2012-05-24 Fixed bug#[7512](http://bugs.otrs.org/show_bug.cgi?id=7512) - AJAX-reload of SMIME-fields did not work properly.
 - 2012-05-24 Fixed bug#[8518](http://bugs.otrs.org/show_bug.cgi?id=8518) - Crypt on multiple recipients error replaces Crypt selection.
 - 2012-05-22 Fixed bug#[8164](http://bugs.otrs.org/show_bug.cgi?id=8164) - Internal articles are visible within customer ticket overview.
 - 2012-05-16 Fixed bug#[8337](http://bugs.otrs.org/show_bug.cgi?id=8337) - Parentheses in user last\_name / first\_name are not sanitized.
 - 2012-05-04 Fixed bug#[7877](http://bugs.otrs.org/show_bug.cgi?id=7877) - SMIME emails don't get parsed properly (follow-up fix).
 - 2012-04-26 Fixed bug#[8424](http://bugs.otrs.org/show_bug.cgi?id=8424) - Ticket articles of large tickets cannot be opened.
 - 2012-04-24 Fixed bug#[8288](http://bugs.otrs.org/show_bug.cgi?id=8288) - Autocomplete search results show up in Times font when using Internet Explorer.
 - 2012-03-26 Fixed bug#[7877](http://bugs.otrs.org/show_bug.cgi?id=7877) - SMIME emails don't get parsed properly.
 - 2012-03-20 Fixed bug#[8331](http://bugs.otrs.org/show_bug.cgi?id=8331) - Unable to delete ticket with \> 1000 articles
    on Oracle database.

# 3.0.12 2012-03-13
 - 2012-03-05 Fixed bug#[7545](http://bugs.otrs.org/show_bug.cgi?id=7545) - AgentTicketBounce lacks permission checks.
 - 2012-02-28 Improved #7526 - Fixed handling of special characters (, ), &, - within statistics.
 - 2012-02-23 Fixed bug#[8227](http://bugs.otrs.org/show_bug.cgi?id=8227) - LDAP user syncronisation doesn't work.
 - 2012-02-15 Fixed bug#[8144](http://bugs.otrs.org/show_bug.cgi?id=8144) - Typo and improved logging in GenericAgent.pm.
 - 2012-02-14 Fixed bug#[7652](http://bugs.otrs.org/show_bug.cgi?id=7652) - OpenSearch providers are served with wrong mime type.
    Follow-up fix.
 - 2012-02-09 Fixed bug#[7109](http://bugs.otrs.org/show_bug.cgi?id=7109) - no one statistic is working with your selected.
 - 2012-02-09 Fixed bug#[8199](http://bugs.otrs.org/show_bug.cgi?id=8199) - Linked tickets open only in tabs.
 - 2012-02-03 Fixed bug#[8180](http://bugs.otrs.org/show_bug.cgi?id=8180) - bin/otrs.LoaderCache.pl exit code is wrong.
 - 2012-02-02 Fixed bug#[7937](http://bugs.otrs.org/show_bug.cgi?id=7937) - HTMLUtils.pm ignore to much of e-mail source code.
 - 2012-02-02 Fixed bug#[7972](http://bugs.otrs.org/show_bug.cgi?id=7972) - Some mails may not present HTML part when using rich viewing.
 - 2012-01-27 Fixed bug#[2820](http://bugs.otrs.org/show_bug.cgi?id=2820) - Wide character in Syslog message causes Perl crash on utf8 systems.
 - 2012-01-23 Fixed bug#[8019](http://bugs.otrs.org/show_bug.cgi?id=8019) - Ticket customer info widget has scroll bars
 - 2012-01-20 Fixed bug#[8128](http://bugs.otrs.org/show_bug.cgi?id=8128) - Ticket Unwatch may lead to errorscreen.
 - 2012-01-16 Creation of QueueObject was not possible because of missing EncodeObject in CustomerUserGenericTicket.pm
 - 2011-12-20 Fixed bug#[8035](http://bugs.otrs.org/show_bug.cgi?id=8035) - SOAP interface does not allow to create/update
    CustomerCompany records.
 - 2011-12-19 Fixed bug#[7005](http://bugs.otrs.org/show_bug.cgi?id=7005) - JavaScript Init function is executed more than once in TicketZoom
 - 2011-12-14 Fixed bug#[7014](http://bugs.otrs.org/show_bug.cgi?id=7014) - Inline article gets bigger than Ticket::Frontend::HTMLArticleHeightMax.
 - 2011-12-16 Fixed Lithuanian language file encoding.
 - 2011-12-14 Fixed bug#[8000](http://bugs.otrs.org/show_bug.cgi?id=8000) - Queues are translated if are displayed in list-style.
 - 2011-12-13 Fixed bug#[7020](http://bugs.otrs.org/show_bug.cgi?id=7020) - Error in MYSQL Syntax when CustomerID contains special characters.
 - 2011-12-12 Improved #7526 - Automatic TicketSearch for special characters (, ), &, - fails.
 - 2011-12-09 Fixed bug#[7997](http://bugs.otrs.org/show_bug.cgi?id=7997) - Fetching mail via AdminMailAccount does not work.
 - 2011-12-09 Fixed bug#[7995](http://bugs.otrs.org/show_bug.cgi?id=7995) - Previous owner is missing in AgentTicketMove.
 - 2011-12-06 Fixed bug#[5253](http://bugs.otrs.org/show_bug.cgi?id=5253) - User preferences are updated when displaying an overview.
 - 2011-12-05 Fixed bug#[7971](http://bugs.otrs.org/show_bug.cgi?id=7971) - ACL to restrict Priority based on Service does not work in Customer
    interface
 - 2011-12-05 Fixed bug#[7864](http://bugs.otrs.org/show_bug.cgi?id=7864) - Inconsequent wrapping of text causes ugly notifications.
 - 2011-12-05 Fixed bug#[7338](http://bugs.otrs.org/show_bug.cgi?id=7338) - Upgrade Script DBUpdate-to-3.0.pl fails to create
    virtual\_fs tables on oracle.
 - 2011-12-02 Fixed bug#[7442](http://bugs.otrs.org/show_bug.cgi?id=7442) - Dashboard permission check for multiple Groups only
    tests first group.
 - 2011-11-29 Fixed bug#[7719](http://bugs.otrs.org/show_bug.cgi?id=7719) - Agent login page does not offer user to save password
    with Firefox browser.
 - 2011-11-30 Fixed bug#[6715](http://bugs.otrs.org/show_bug.cgi?id=6715) - Setting CustomerID with otrs.AddCustomerUser.pl.
 - 2011-11-28 Updated CPAN module Apache::DBI to version 1.11.
 - 2011-11-23 Fixed bug#[7930](http://bugs.otrs.org/show_bug.cgi?id=7930) - Depreciation warnings in error log when running OTRS on
    Perl 5.14.
 - 2011-11-21 Fixed bug#[3804](http://bugs.otrs.org/show_bug.cgi?id=3804) - Stats in Bar or Pie chart formats don't display non-
    ascii characters correctly.
 - 2011-11-21 Use the secure attribute to restrict coookies to HTTPS if it is used.
 - 2011-11-21 Fixed bug#[7909](http://bugs.otrs.org/show_bug.cgi?id=7909) - Errors should be logged in web server error log only.
 - 2011-11-17 Fixed bug#[7896](http://bugs.otrs.org/show_bug.cgi?id=7896) - Inline images are broken in ticket answers.
 - 2011-11-17 Fixed bug#[5782](http://bugs.otrs.org/show_bug.cgi?id=5782) - Skipped GenericAgent cron executions because of
    timing issues.
 - 2011-11-17 Fixed bug#[7674](http://bugs.otrs.org/show_bug.cgi?id=7674) - Pagination in dashboard appears even with one page of
    results.
 - 2011-11-16 Fixed bug#[7903](http://bugs.otrs.org/show_bug.cgi?id=7903) - Improve MarkTicketsAsSeen for use with large amounts
    of tickets.
 - 2011-11-15 Fixed bug#[7901](http://bugs.otrs.org/show_bug.cgi?id=7901) - Package Manager does not clear the cache.
 - 2011-11-15 Fixed bug#[7120](http://bugs.otrs.org/show_bug.cgi?id=7120) - Inline images from Lotus Notes do not show in
    AgentTicketCompose interface.
 - 2011-11-14 Fixed bug#[7526](http://bugs.otrs.org/show_bug.cgi?id=7526) - OTRS Ticket Search not working with ( or ).
 - 2011-11-10 Fixed bug#[7879](http://bugs.otrs.org/show_bug.cgi?id=7879) - Ticket forward not working if content-id exists.
 - 2011-11-07 Fixed bug#[7887](http://bugs.otrs.org/show_bug.cgi?id=7887) - Type based ACLs do not match if Type (Name) is sent.
 - 2011-11-05 Fixed bug#[7876](http://bugs.otrs.org/show_bug.cgi?id=7876) - NewTicketReject Postmaster module uses Admin Address
    as 'from' in reject emails.
 - 2011-11-05 Fixed bug#[7884](http://bugs.otrs.org/show_bug.cgi?id=7884) - Error message in web server error log when assigning
    queues to standard responses.
 - 2011-11-03 Fixed bug#[7865](http://bugs.otrs.org/show_bug.cgi?id=7865) - Special characters in group names.
 - 2011-11-01 Fixed bug#[7875](http://bugs.otrs.org/show_bug.cgi?id=7875) - Restricting visibility of SLA in the Customer Ticket zoom does not work.
 - 2011-11-01 Fixed bug#[7823](http://bugs.otrs.org/show_bug.cgi?id=7823) - ACL could remove default state from ticket masks.
 - 2011-10-26 Fixed bug#[7465](http://bugs.otrs.org/show_bug.cgi?id=7465) - Out-of-office unlock does not work upon customer's web reply.
 - 2011-10-25 Fixed bug#[7843](http://bugs.otrs.org/show_bug.cgi?id=7843) - Customer and Agent Ticket Zoom issue with Sessions.
 - 2011-10-24 Improved rpc-example.pl to not use autodispatch any more.
 - 2011-10-21 Fixed bug#[7845](http://bugs.otrs.org/show_bug.cgi?id=7845) - No DispatchMultiple Method in rpc.pl script.

# 3.0.11 2011-10-18
 - 2011-10-07 Fixed bug#[7812](http://bugs.otrs.org/show_bug.cgi?id=7812) - Height of search terms doesn't fit on search results page on IE7
 - 2011-10-05 Fixed bug#[7807](http://bugs.otrs.org/show_bug.cgi?id=7807) - Ticket free text misplaced in IE7.
 - 2011-09-22 Fixed bug#[7776](http://bugs.otrs.org/show_bug.cgi?id=7776) - Double encoding for AJAX responses on ActiveState perl.
 - 2011-09-19 Fixed bug#[7756](http://bugs.otrs.org/show_bug.cgi?id=7756) - DefaultViewNewLine Config does not get used.
 - 2011-09-13 Fixed bug#[6902](http://bugs.otrs.org/show_bug.cgi?id=6902) - QueueView: My Queues \> bulk menu duplication.
 - 2011-09-12 Fixed bug#[7708](http://bugs.otrs.org/show_bug.cgi?id=7708) - Only 400 agents available in AdminUser.
 - 2011-09-07 Fixed bug#[7678](http://bugs.otrs.org/show_bug.cgi?id=7678) - ArticleContentIndex: API Documentation disagrees with code.
 - 2011-09-07 Fixed bug#[7633](http://bugs.otrs.org/show_bug.cgi?id=7633) - Status flag in customer interface ticket zoom has wrong colors.
 - 2011-09-07 Fixed bug#[7591](http://bugs.otrs.org/show_bug.cgi?id=7591) - Email address field validation fails if name server does not respond.
 - 2011-09-06 Fixed bug#[7566](http://bugs.otrs.org/show_bug.cgi?id=7566) - Ticket search with article create date not working with StaticDB.
 - 2011-09-05 Fixed ticket#2010111742013515 - import/export of static states with .pm file
    and umlaut in file is not working.
 - 2011-08-30 Improved fix of bug#[7195](http://bugs.otrs.org/show_bug.cgi?id=7195) to log a understandable error message if png, gif and
    jpeg support are not activated in the GD CPAN module.
 - 2011-08-26 Fixed bug#[7525](http://bugs.otrs.org/show_bug.cgi?id=7525) - Move in new window doesn't indicate required fields.
 - 2011-08-26 Fixed bug#[7507](http://bugs.otrs.org/show_bug.cgi?id=7507) - AgentTicketActionCommon.dtl don't know about selected Priority.
 - 2011-08-26 Fixed bug#[7504](http://bugs.otrs.org/show_bug.cgi?id=7504) - 7 Day Stats graph doesn't fit into alloted width.
 - 2011-08-25 Fixed bug#[7393](http://bugs.otrs.org/show_bug.cgi?id=7393) - Error when bouncing a ticket with a new state of open or new.
 - 2011-08-23 Fixed bug#[5621](http://bugs.otrs.org/show_bug.cgi?id=5621) - OpenSearch not working for Internet Explorer 8.
 - 2011-08-23 Fixed bug#[7652](http://bugs.otrs.org/show_bug.cgi?id=7652) - OpenSearch providers are served with wrong mime type.
 - 2011-08-17 Fixed bug#[7599](http://bugs.otrs.org/show_bug.cgi?id=7599) - Back-Link does not work in permission denied screen if
    this screen is a popup window.
 - 2011-08-16 Fixed bug#[7407](http://bugs.otrs.org/show_bug.cgi?id=7407) - Event based notifications with roles as recipients can
    produce multiple notifications.
 - 2011-08-16 Fixed bug#[7589](http://bugs.otrs.org/show_bug.cgi?id=7589) - Ticket Search - TicketWatcher doesn't expand.
 - 2011-08-15 Fixed bug#[7343](http://bugs.otrs.org/show_bug.cgi?id=7343) - Typos in Customer Company Countries list.
 - 2011-08-15 Fixed bug#[7081](http://bugs.otrs.org/show_bug.cgi?id=7081) - Kernel::System::Log fails when module does not return
    VERSION.
 - 2011-08-15 Fixed bug#[6263](http://bugs.otrs.org/show_bug.cgi?id=6263) - RPM upgrade should run otrs.RebuildConfig.pl and
    otrs.DeleteCache.pl.
 - 2011-08-12 Updated Simplified Chinese Translation, thanks to Martin Liu!
 - 2011-08-12 Updated Danish translation, thanks to Lars JÃ¸rgensen!
 - 2011-08-10 Fixed bug#[7550](http://bugs.otrs.org/show_bug.cgi?id=7550) - SLA and Service is not written to history.
 - 2011-08-10 Fixed bug#[7549](http://bugs.otrs.org/show_bug.cgi?id=7549) - Missing mandatory class and \* identifier in AgentTicketMove.

# 3.0.10 2011-08-16
 - 2011-07-28 Fixed bug#[7518](http://bugs.otrs.org/show_bug.cgi?id=7518) - Escalation Notify by not working properly.
 - 2011-07-22 Fixed bug#[6978](http://bugs.otrs.org/show_bug.cgi?id=6978) - UTF characters got broken.
 - 2011-07-22 Fixed bug#[6259](http://bugs.otrs.org/show_bug.cgi?id=6259) - Search matching no results to Print opens extra tab.
 - 2011-07-22 Fixed bug#[7527](http://bugs.otrs.org/show_bug.cgi?id=7527) - Calling AgentTicketPhone with pre-selected values fails on
    ticket status of type "pending XYZ".
 - 2011-07-20 Fixed bug#[7097](http://bugs.otrs.org/show_bug.cgi?id=7097) - Length of name of event based notifications limited in the
    admin interface.
 - 2011-07-18 Fixed bug#[7477](http://bugs.otrs.org/show_bug.cgi?id=7477) - Dashboard shows "My Queues" even if a queue is preselected
    in the configuration.
 - 2011-07-18 Fixed bug#[6348](http://bugs.otrs.org/show_bug.cgi?id=6348) - GenericAgent cron job concurrency issues.
 - 2011-07-18 Fixed bug#[7502](http://bugs.otrs.org/show_bug.cgi?id=7502) - crontab.txt empty on Win32.
 - 2011-07-12 Fixed bug#[7015](http://bugs.otrs.org/show_bug.cgi?id=7015) - Closing split ticked assigned to different agents
    causes "Locked Tickets Total" to be negative (or off by one).
 - 2011-07-11 Fixed bug#[7362](http://bugs.otrs.org/show_bug.cgi?id=7362) - AuthSyncModule::LDAP::UserSyncMap with multiple auth backends.
 - 2011-07-08 Fixed bug#[7472](http://bugs.otrs.org/show_bug.cgi?id=7472) - TicketSearch for FreeTexts with _ in string not working on Oracle.
 - 2011-07-07 Fixed bug#[7484](http://bugs.otrs.org/show_bug.cgi?id=7484) - Customer items too much right-aligned in customer information box.
 - 2011-07-01 Fixed bug#[7434](http://bugs.otrs.org/show_bug.cgi?id=7434) - CustomerTicketOverview.dtl - closing listitems missing in HTML.

# 3.0.9 2011-07-05
 - 2011-07-01 Fixed bug#[7419](http://bugs.otrs.org/show_bug.cgi?id=7419) - 3.0.8 RPM does not include var/fonts directory.
 - 2011-06-30 Fixed bug#[7380](http://bugs.otrs.org/show_bug.cgi?id=7380) - Undo & close window or Cancel & close window NOT working IE9.
 - 2011-06-29 Fixed bug#[7435](http://bugs.otrs.org/show_bug.cgi?id=7435) - Ticket::Frontend::CustomerTicketZoom###AttributesView settings not used for pdf output.
 - 2011-06-29 Fixed bug#[7459](http://bugs.otrs.org/show_bug.cgi?id=7459) - Files partly in database after executing bin/otrs.ArticleStorageSwitch.pl.
 - 2011-06-27 Fixed bug#[7367](http://bugs.otrs.org/show_bug.cgi?id=7367) - No notification of notes when ticket is closed.
 - 2011-06-24 Fixed bug#[7335](http://bugs.otrs.org/show_bug.cgi?id=7335) - No empty state selection in AgentTicketForward.
 - 2011-06-22 Fixed bug#[7433](http://bugs.otrs.org/show_bug.cgi?id=7433) - CustomerTicketZoom is not able to display owner and/or responsible.
 - 2011-06-21 Fixed bug#[4946](http://bugs.otrs.org/show_bug.cgi?id=4946) - Notification mails lack "Precedence: bulk" or similar headers.
 - 2011-06-21 Updated XML::TreePP to 0.41.
 - 2011-06-21 Updated XML::FeedPP to 0.43.
 - 2011-06-20 Fixed bug#[7400](http://bugs.otrs.org/show_bug.cgi?id=7400) - Setting Ticket::Frontend::ShowCustomerTickets not effective.
 - 2011-06-17 Fixed bug#[6469](http://bugs.otrs.org/show_bug.cgi?id=6469) - i18n: "Forwarded message" string is not translatable.
 - 2011-06-17 Fixed bug#[4524](http://bugs.otrs.org/show_bug.cgi?id=4524) - SQL errors when there are no valid states for a given state type.
 - 2011-06-17 Fixed bug#[7368](http://bugs.otrs.org/show_bug.cgi?id=7368) - Error in TicketEscalationDateCalculation.
 - 2011-06-17 Fixed bug#[7420](http://bugs.otrs.org/show_bug.cgi?id=7420) - Cache issue when updating states.
 - 2011-06-15 Fixed bug#[4606](http://bugs.otrs.org/show_bug.cgi?id=4606) - Possible to select invalid dates for Out-of-Office.
 - 2011-06-15 Fixed bug#[7398](http://bugs.otrs.org/show_bug.cgi?id=7398) - FreeTime fields have no validation.
 - 2011-06-14 Fixed bug#[7396](http://bugs.otrs.org/show_bug.cgi?id=7396) - Selectboxes with long entries are cut off in dialogs in IE7.
 - 2011-06-14 Fixed bug#[7350](http://bugs.otrs.org/show_bug.cgi?id=7350) - Permissiontable in Role \<-\> Group is cut.
 - 2011-06-14 Added new Lithuanian translation, thanks to Edgaras Lukoschevidsius!
 - 2011-06-11 Fixed bug#[7161](http://bugs.otrs.org/show_bug.cgi?id=7161) - Single page ticket list does not indicate how much tickets are displayed.
 - 2011-06-11 Updated Net::SMTP::TLS::ButMaintained to 0.17.
 - 2011-06-11 Fixed bug#[7354](http://bugs.otrs.org/show_bug.cgi?id=7354) - bin/otrs.Cron4Win32.pl creates an empty crontab.txt.
 - 2011-06-07 Fixed bug#[7119](http://bugs.otrs.org/show_bug.cgi?id=7119) - Search profile names not visible in URL anymore.
 - 2011-05-30 Fixed bug#[7361](http://bugs.otrs.org/show_bug.cgi?id=7361) - "$HOME/bin/otrs.DeleteCache.pl --expired" causes error message :
    Invalid option --expired
 - 2011-05-27 Fixed bug#[7355](http://bugs.otrs.org/show_bug.cgi?id=7355) - Memory leak in XML.pm.
 - 2011-05-27 Fixed bug#[7356](http://bugs.otrs.org/show_bug.cgi?id=7356) - AgentTicketForward ignores free text fields.
 - 2011-05-26 Fixed bug#[7311](http://bugs.otrs.org/show_bug.cgi?id=7311) - bouncing a ticket to multiple email-addresses is not possible anymore.
 - 2011-05-24 Fixed bug#[7348](http://bugs.otrs.org/show_bug.cgi?id=7348) - otrs.ArticleStorageSwitch.pl gives 'Corrupt file' errors on some attachments.
 - 2011-05-24 Fixed bug#[7329](http://bugs.otrs.org/show_bug.cgi?id=7329) - PendingJobs - auto unlock for closed tickets does not work in all cases.
 - 2011-05-24 Fixed bug#[6896](http://bugs.otrs.org/show_bug.cgi?id=6896) - Small inconcistencies in German translation for AgentTicketBulk screen.
 - 2011-05-24 Fixed bug#[7328](http://bugs.otrs.org/show_bug.cgi?id=7328) - PostMastFollowUp.pm value assignment issue.

# 3.0.8 2011-05-24
 - 2011-05-19 Updated Japanese translation, thanks to Kaz Kamimura!
 - 2011-05-19 Fixed bug#[7332](http://bugs.otrs.org/show_bug.cgi?id=7332) - Some buttons are not shown in the AdminSysConfig in IE7.
 - 2011-05-16 Fixed bug#[7300](http://bugs.otrs.org/show_bug.cgi?id=7300) - Wrong dropdown pre-selection in AdminQueue.
 - 2011-05-16 Fixed bug#[7288](http://bugs.otrs.org/show_bug.cgi?id=7288) - hyperlink creationcuts URLs after a closing square bracket.
 - 2011-05-16 Fixed bug#[7287](http://bugs.otrs.org/show_bug.cgi?id=7287) - Ticket Type in Customer Interface is not indicated as a required field.
 - 2011-05-16 Fixed bug#[7310](http://bugs.otrs.org/show_bug.cgi?id=7310) - AdminNotification.dtl restricts subject line to 120 characters.
 - 2011-05-10 Fixed bug#[7280](http://bugs.otrs.org/show_bug.cgi?id=7280) - AgentTicketCompose :: empty state selection causes many log entries.
 - 2011-05-10 Fixed bug#[7111](http://bugs.otrs.org/show_bug.cgi?id=7111) - Customer Password reset mail is sent even if the DB could not be updated.
 - 2011-05-10 Fixed bug#[7271](http://bugs.otrs.org/show_bug.cgi?id=7271) - AJAX issue when clicking 'Submit' while AJAX requests are still running.
 - 2011-05-09 Fixed bug#[7270](http://bugs.otrs.org/show_bug.cgi?id=7270) - Changing the customer from overviews opens the ticket zoom.
 - 2011-05-09 Fixed bug#[7262](http://bugs.otrs.org/show_bug.cgi?id=7262) - Customer Ticket Overview Sorting by \<th\>.
 - 2011-05-09 Fixed bug#[6901](http://bugs.otrs.org/show_bug.cgi?id=6901) - Ticket Search -\> CSV export -\> close date incorrect.
 - 2011-05-09 Fixed bug#[7289](http://bugs.otrs.org/show_bug.cgi?id=7289) - Ticket::Frontend::CustomerSearchAutoComplete###QueryDelay
    should be specified in milliseconds rather than seconds.
 - 2011-05-09 Added new Croatian translation, thanks to Damir Dzeko!
 - 2011-05-09 Fixed bug#[7092](http://bugs.otrs.org/show_bug.cgi?id=7092) - Non-existent theme set in user\_preferences makes login impossible.
 - 2011-05-09 Fixed bug#[7010](http://bugs.otrs.org/show_bug.cgi?id=7010) - Latest version of PDF::API2 no longer includes DejaVu fonts.
    Fixed by including DejaVu fonts in var/fonts.
 - 2011-05-09 Fixed bug#[7245](http://bugs.otrs.org/show_bug.cgi?id=7245) - Event based notifications are not sent to roles.
 - 2011-05-04 Fixed bug#[7277](http://bugs.otrs.org/show_bug.cgi?id=7277) - otrs.cleanup is called in Cron on Win32.
 - 2011-05-04 Fixed bug#[7272](http://bugs.otrs.org/show_bug.cgi?id=7272) - i18n: TicketFreeTime field label is not translated.
 - 2011-05-02 Updated Brasilian Portugese translation, thanks to Murilo Moreira de Oliveira!
 - 2011-05-02 Updated Persian translation, thanks to Masood Ramezani!
 - 2011-04-28 Fixed bug#[7244](http://bugs.otrs.org/show_bug.cgi?id=7244) - Plain Auth with SMTP/TLS does not work.
 - 2011-04-21 Fixed bug#[7212](http://bugs.otrs.org/show_bug.cgi?id=7212) - IE7 Move box alignment issue in AgentTicketZoom.
 - 2011-04-21 Fixed bug#[7188](http://bugs.otrs.org/show_bug.cgi?id=7188) - Resizable handle always in foreground.
 - 2011-04-19 Fixed bug#[7229](http://bugs.otrs.org/show_bug.cgi?id=7229) - Apache configuration file references nonexisting javascript directory.
 - 2011-04-14 Fixed bug#[7230](http://bugs.otrs.org/show_bug.cgi?id=7230) - Password fields in SysConfig GUI are not protected.
 - 2011-04-14 Fixed bug#[7222](http://bugs.otrs.org/show_bug.cgi?id=7222) - Translation strings with more than 3 placeholders are not translated.
 - 2011-04-12 Fixed bug#[7213](http://bugs.otrs.org/show_bug.cgi?id=7213) - TicketSearch() TicketFlags handling broken.
 - 2011-04-11 Fixed bug#[7209](http://bugs.otrs.org/show_bug.cgi?id=7209) - TimeUnits validation not working.
 - 2011-04-11 Updated Italian translation, thanks to Lucia Magnanelli!
 - 2011-04-06 Fixed bug#[7058](http://bugs.otrs.org/show_bug.cgi?id=7058) - AJAX communication error when picking queue during ticket split.
 - 2011-04-05 Fixed bug#[7179](http://bugs.otrs.org/show_bug.cgi?id=7179) - MasterAction causes browser problem.
 - 2011-04-05 Fixed bug#[7169](http://bugs.otrs.org/show_bug.cgi?id=7169) - Archived tickets can not be un-archived.
 - 2011-04-04 Fixed bug#[6801](http://bugs.otrs.org/show_bug.cgi?id=6801) - Bulk Actions are not working.
 - 2011-04-04 Fixed bug#[7156](http://bugs.otrs.org/show_bug.cgi?id=7156) - NewTicketInNewWindow misplaced group.
 - 2011-04-01 Fixed bug#[7096](http://bugs.otrs.org/show_bug.cgi?id=7096) - CSS for navigation bar :: wrong z-index for selected area and hover.
 - 2011-04-01 Fixed bug#[7160](http://bugs.otrs.org/show_bug.cgi?id=7160) - Typo "Anwort" in translation file de.pm.
 - 2011-04-01 Fixed bug#[7158](http://bugs.otrs.org/show_bug.cgi?id=7158) - Customer search can not be started via URL.
 - 2011-04-01 Fixed bug#[7119](http://bugs.otrs.org/show_bug.cgi?id=7119) - Search profile names not visible in URL anymore in customer and agent panel.
 - 2011-04-01 Fixed bug#[7151](http://bugs.otrs.org/show_bug.cgi?id=7151) - Secure::DisableBanner does not disable E-Mail Headers
 - 2011-03-28 Fixed bug#[7115](http://bugs.otrs.org/show_bug.cgi?id=7115) - Search profiles are not working after upgrade to OTRS 3.

# 3.0.7 2011-04-12
 - 2011-03-24 Fixed bug#[7106](http://bugs.otrs.org/show_bug.cgi?id=7106) - Customer user login can't be updated nor changed.
 - 2011-03-24 Fixed bug#[6954](http://bugs.otrs.org/show_bug.cgi?id=6954) - Option "NewTicketInNewWindow::Enabled"  is not working.
 - 2011-03-22 Fixed bug#[7052](http://bugs.otrs.org/show_bug.cgi?id=7052) - Clicking on items in Dashboard and Overview causes
    two GET request instead of one.
 - 2011-03-22 Fixed bug#[7077](http://bugs.otrs.org/show_bug.cgi?id=7077) - Customer Interface Article Information not displayed properly in IE7.
 - 2011-03-18 Fixed bug#[7063](http://bugs.otrs.org/show_bug.cgi?id=7063) - TicketZoom Customer information display issue in IE7.
 - 2011-03-16 Fixed bug#[7060](http://bugs.otrs.org/show_bug.cgi?id=7060) - Unexisting value is passed to several subroutines in AgentTicketPhone when there is no subaction.
 - 2011-03-15 Fixed bug#[7057](http://bugs.otrs.org/show_bug.cgi?id=7057) - Kernel::System::StandardResponse-\>StandardResponseLookup() is broken
 - 2011-03-15 Fixed bug#[5604](http://bugs.otrs.org/show_bug.cgi?id=5604) - Show name of static statistic, if there is only one.
 - 2011-03-14 Updated Norwegian translation, thanks to Espen Stefansen!
 - 2011-03-14 Fixed bug#[7040](http://bugs.otrs.org/show_bug.cgi?id=7040) - SQL error when retrieving CustomerCompanyList with Valid =\> 0.
 - 2011-03-14 Updated Chinese translation, thanks to Martin Liu!
 - 2011-03-13 Fixed bug#[7042](http://bugs.otrs.org/show_bug.cgi?id=7042) - Textual and layout issue Archive option in AgentTicketSearch.
 - 2011-03-10 Fixed bug#[6946](http://bugs.otrs.org/show_bug.cgi?id=6946) - SelectAllXXX checkbox is not checked when you first enter to the module.
 - 2011-03-09 Fixed bug#[7007](http://bugs.otrs.org/show_bug.cgi?id=7007) - Loader unit tests fail on MSWin32.
 - 2011-03-08 Fixed bug#[6790](http://bugs.otrs.org/show_bug.cgi?id=6790) - Custom directory not considered when running in CGI.
 - 2011-03-08 Fixed bug#[5354](http://bugs.otrs.org/show_bug.cgi?id=5354) - Gratuitous "use lib '../..';" in Kernel::Output::HTML::Layout
     preventing modules in /Custom to be loaded when deployed as CGI.
 - 2011-03-07 Fixed bug#[6014](http://bugs.otrs.org/show_bug.cgi?id=6014) - Printed pdf tickets are not searchable.
 - 2011-03-07 Fixed bug#[7006](http://bugs.otrs.org/show_bug.cgi?id=7006) - One MainObject unit test fails on Win32.
 - 2011-03-02 Fixed bug#[6936](http://bugs.otrs.org/show_bug.cgi?id=6936) - Click on Customer triggers Wildcard-Search.
 - 2011-02-28 Fixed bug#[6961](http://bugs.otrs.org/show_bug.cgi?id=6961) - TicketActionsPerTicket - Buttons not localized.
 - 2011-02-28 Fixed bug#[5578](http://bugs.otrs.org/show_bug.cgi?id=5578) - TicketSolutionResponseTime.pm fix.
 - 2011-02-28 Fixed bug#[6974](http://bugs.otrs.org/show_bug.cgi?id=6974) - Ticket Search does not find tickets if searching by
    in between 2 dates, and the ticket time is 00:00:00.
 - 2011-02-28 Fixed bug#[6930](http://bugs.otrs.org/show_bug.cgi?id=6930) - en\_GB (united kingdom) notification events blank.
 - 2011-02-25 Fixed bug#[6822](http://bugs.otrs.org/show_bug.cgi?id=6822) -  Underscore in username problem in 3.0.5.
 - 2011-02-25 Added Hindi translation, thanks to Chetan Nagaonkar!

# 3.0.6 2011-02-29
 - 2011-02-21 Fixed bug#[6938](http://bugs.otrs.org/show_bug.cgi?id=6938). CustomerUser AutoLoginCreation doesn't work.
 - 2011-02-21 Updated Russian translation, thanks to Eugene Kungurov!
 - 2011-02-18 Fixed bug#[6912](http://bugs.otrs.org/show_bug.cgi?id=6912) - MIME-Viewer (PDF Preview) is not properly displayed in 3.x UI.
 - 2011-02-16 Changed UserID 1 notification
 - 2011-02-16 Updated Brazilian Portugese translation, thanks to Humberto Diogenes!
 - 2011-02-15 Fixed bug#[6861](http://bugs.otrs.org/show_bug.cgi?id=6861) - Navigation should be disabled when linking an object.
 - 2011-02-14 Fixed bug#[6869](http://bugs.otrs.org/show_bug.cgi?id=6869) - ITSM 3 Link Object "close window" refreshes and settings lost
 - 2011-02-09 Fixed bug#[6878](http://bugs.otrs.org/show_bug.cgi?id=6878) - Agent and customer usernames and passwords stored plaintext
    in database and session.
 - 2011-02-09 Updated French translation, thanks to Rï¿½mi Seguy!
 - 2011-02-08 Fixed bug#[6808](http://bugs.otrs.org/show_bug.cgi?id=6808) - change queue with note destroyes rich text in note
    when file is attached.
 - 2011-02-04 Fixed bug#[4350](http://bugs.otrs.org/show_bug.cgi?id=4350) - Time\_accounting not merged when merging ticket.
 - 2011-02-03 Fixed bug#[6831](http://bugs.otrs.org/show_bug.cgi?id=6831) - CustomerLogo not shown if external URL.
 - 2011-02-02 Fixed bug#[2877](http://bugs.otrs.org/show_bug.cgi?id=2877) - Licence is "License" in British English.
 - 2011-02-01 Fixed bug#[6837](http://bugs.otrs.org/show_bug.cgi?id=6837) - Queue cannot be created, just changed
 - 2011-02-01 Fixed bug#[6696](http://bugs.otrs.org/show_bug.cgi?id=6696) - TicketFreeTime options are line breaked in the
    search window.
 - 2011-01-31 Implemented bug#[6824](http://bugs.otrs.org/show_bug.cgi?id=6824) - Adding system addresses from CLI, via new
    script bin/otrs.AddSystemAddress.pl.
 - 2011-01-31 Fixed bug#[6818](http://bugs.otrs.org/show_bug.cgi?id=6818) - PDF Printing does not work with newest PDF::API2
    2.x module.
 - 2011-01-28 Fixed bug#[6506](http://bugs.otrs.org/show_bug.cgi?id=6506) - Ticket::Frontend::ZoomRichTextForce no longer
    available.
 - 2011-01-27 Fixed bug#[6539](http://bugs.otrs.org/show_bug.cgi?id=6539) - CustomerUser LDAP Fetch is requesting all attributes
    instead of configured attributes from map.
 - 2011-01-27 Added database connection information to otrs.CheckDB.pl script.
 - 2011-01-27 Fixed bug#[6729](http://bugs.otrs.org/show_bug.cgi?id=6729) - SMIME-Encryption broken in Interface.
 - 2011-01-27 Fixed bug#[6792](http://bugs.otrs.org/show_bug.cgi?id=6792) - ArticleFreeText default selection is not respected
    by input masks.
 - 2011-01-27 Fixed bug#[6791](http://bugs.otrs.org/show_bug.cgi?id=6791) - In TicketZoom Total Accounted Time is displayed
    when AccountTime is set to "off".
 - 2011-01-26 Fixed bug#[6721](http://bugs.otrs.org/show_bug.cgi?id=6721) - New users with empty password creation is allowed
    but a random password is assigned without notification.
 - 2011-01-26 Fixed bug#[4188](http://bugs.otrs.org/show_bug.cgi?id=4188) - Moving junk mails unnecessarily need subject and
    body (for 3.0 version).
 - 2011-01-25 Fixed bug#[6789](http://bugs.otrs.org/show_bug.cgi?id=6789) - Ticket OpenSearch in Customer Interface is broken.
 - 2011-01-25 Fixed bug#[4764](http://bugs.otrs.org/show_bug.cgi?id=4764) - Public frontend has Customer frontend opensearch
    descriptions.
 - 2011-01-25 Fixed bug#[6600](http://bugs.otrs.org/show_bug.cgi?id=6600) - AgentTicketSearch date selection issues.
 - 2011-01-25 Fixed bug#[5487](http://bugs.otrs.org/show_bug.cgi?id=5487) - Event Based notification - respect "Include
    Attachments to Notification".
 - 2011-01-25 Fixed bug#[6745](http://bugs.otrs.org/show_bug.cgi?id=6745) - Disabling out of office does not work until
    logging out.
 - 2011-01-25 Fixed bug#[6740](http://bugs.otrs.org/show_bug.cgi?id=6740) - Link CI to new phone or mail ticket does not work.
 - 2011-01-25 Fixed bug#[6764](http://bugs.otrs.org/show_bug.cgi?id=6764) - Usage of TicketHook as TicketZoom Subject.
 - 2011-01-24 Fixed bug#[6684](http://bugs.otrs.org/show_bug.cgi?id=6684) - CustomerInfoSize doesn't size the info box.
 - 2011-01-21 Fixed bug#[6728](http://bugs.otrs.org/show_bug.cgi?id=6728) - Notification Management not usable if many
    notifications exist.
 - 2011-01-21 Fixed bug#[6741](http://bugs.otrs.org/show_bug.cgi?id=6741) - Select box does not display helpful error messages.
 - 2011-01-21 Fixed bug#[6530](http://bugs.otrs.org/show_bug.cgi?id=6530) - Problem sending inline PGP answer.
 - 2011-01-21 Fixed bug#[6044](http://bugs.otrs.org/show_bug.cgi?id=6044) - Toolbar - show static buttons first
 - 2011-01-21 Fixed bug#[6654](http://bugs.otrs.org/show_bug.cgi?id=6654) - Can't add a queue with Unlock set to No using a PostgreSQL
    database.
 - 2011-01-20 Fixed bug#[4814](http://bugs.otrs.org/show_bug.cgi?id=4814) - Need UserID or UserLogin error message in some scenarios
    when using BasicAuth.
 - 2011-01-20 Fixed bug#[6725](http://bugs.otrs.org/show_bug.cgi?id=6725) - Typo in description for Stats in SysConfig.
 - 2011-01-20 Fixed bug#[6001](http://bugs.otrs.org/show_bug.cgi?id=6001) - Configuration issues when Apache::DBI is not installed.
    Apache::DBI is now bundled in Kernel/cpan-lib, mainly because it's not part of the
    RHEL5 package repositories.
 - 2011-01-19 Fixed bug#[6704](http://bugs.otrs.org/show_bug.cgi?id=6704) - Core.AJAX throws exceptions which cannot be handled.
 - 2011-01-17 Fixed bug#[6599](http://bugs.otrs.org/show_bug.cgi?id=6599) - Ticket sub-sorting in dashlets isn't working.
 - 2011-01-17 Fixed bug#[6706](http://bugs.otrs.org/show_bug.cgi?id=6706) - Add Google Chrome Frame support.

# 3.0.5 2011-01-18
 - 2011-01-13 Fixed bug#[6628](http://bugs.otrs.org/show_bug.cgi?id=6628) - Attachments don't show up in Exchange when using WebUploadCacheModule::FS.
 - 2011-01-12 Fixed bug#[6681](http://bugs.otrs.org/show_bug.cgi?id=6681) - Font of notes is not fixed font (Frontend::RichText is disabled).
 - 2011-01-12 Fixed bug#[6458](http://bugs.otrs.org/show_bug.cgi?id=6458) - "Lock" not indicated on compose (lock/unlock message was not shown).
 - 2011-01-11 Fixed bug#[6653](http://bugs.otrs.org/show_bug.cgi?id=6653) - Time Format Dashboard etc.
 - 2011-01-11 Fixed bug#[6505](http://bugs.otrs.org/show_bug.cgi?id=6505) - Ticket::Frontend::PlainView has no effect.
 - 2011-01-10 Fixed bug#[6668](http://bugs.otrs.org/show_bug.cgi?id=6668) - Upgrade to OTRS 3.0.x fails if OTRS 2.4.x is used with OTRS::ITSM 2.x
 - 2011-01-07 Fixed bug#[6555](http://bugs.otrs.org/show_bug.cgi?id=6555) - no decoder for iso-8859-1 at /opt/otrs/Kernel/cpan-lib/MIME/Parser.pm line 821.
 - 2011-01-07 Fixed bug#[6582](http://bugs.otrs.org/show_bug.cgi?id=6582) - Admin-\>Manage Queues wrong subqueue default.
 - 2011-01-07 Fixed bug#[6658](http://bugs.otrs.org/show_bug.cgi?id=6658) - History contains redundant SetPendingTime entries.
 - 2011-01-06 Fixed bug#[5053](http://bugs.otrs.org/show_bug.cgi?id=5053) - Some inline images (bitmaps) from MS Outlook clients are not displayed in ticket zoom.
 - 2011-01-06 Fixed bug#[6627](http://bugs.otrs.org/show_bug.cgi?id=6627) - Queue names are wrapped badly by the browser.
 - 2011-01-06 Fixed bug#[6591](http://bugs.otrs.org/show_bug.cgi?id=6591) - Date selector calendar does not open on agent out of office.
 - 2011-01-06 Fixed bug#[6563](http://bugs.otrs.org/show_bug.cgi?id=6563) - Article list in AgentTicketZoom scrolls inconveniently.
 - 2011-01-06 Fixed bug#[6629](http://bugs.otrs.org/show_bug.cgi?id=6629) - Opening a link in a new Tab with IE doesn't allow you to navigate away from the SOURCE tab.
 - 2011-01-06 Fixed bug#[6650](http://bugs.otrs.org/show_bug.cgi?id=6650) - AgentTicketPhone loses Responsible selection after reload.
 - 2011-01-06 Fixed bug#[6354](http://bugs.otrs.org/show_bug.cgi?id=6354) - SMTPTLS multiplies attachments.
 - 2011-01-05 Fixed bug#[6624](http://bugs.otrs.org/show_bug.cgi?id=6624) - If ticket is displayed in "Show all articles mode" only the last article can be replied in IE7.
 - 2011-01-04 Fixed bug#[6578](http://bugs.otrs.org/show_bug.cgi?id=6578) - Agent settings 'My Queues' selection not shown.
 - 2011-01-04 Fixed bug#[5175](http://bugs.otrs.org/show_bug.cgi?id=5175) - Documentation of Kernel::System::Main::FileRead.
 - 2011-01-04 Updated Italian translation, thanks to Alessandro Grassi!
 - 2011-01-04 Updated Norwegian translation, thanks to Eirik Wulff!
 - 2011-01-03 Fixed bug#[6604](http://bugs.otrs.org/show_bug.cgi?id=6604) - Some attachments from mails created with OTRS 2.4.6
    are missing from the attachment list after upgrade to 3.0.
 - 2010-12-30 Fixed bug#[6473](http://bugs.otrs.org/show_bug.cgi?id=6473) - Error at Apache log "uninitialized value".
 - 2010-12-30 Fixed bug#[4886](http://bugs.otrs.org/show_bug.cgi?id=4886) - FollowUp-notification send not to owner.
 - 2010-12-30 Updated CPAN module JSON to version 2.50.
 - 2010-12-30 Updated CPAN module JSON::PP to version 2.27103.
 - 2010-12-30 Updated CPAN module Text::CSV to version 1.21.
 - 2010-12-28 Fixed bug#[6595](http://bugs.otrs.org/show_bug.cgi?id=6595) - umleiten != Zurï¿½ckweisen an.
 - 2010-12-28 Fixed bug#[6057](http://bugs.otrs.org/show_bug.cgi?id=6057) - Some action buttons don't have tooltips.
 - 2010-12-27 Fixed bug#[6606](http://bugs.otrs.org/show_bug.cgi?id=6606) - Login screen in area of ticket details.
 - 2010-12-27 Fixed bug#[6609](http://bugs.otrs.org/show_bug.cgi?id=6609) - Created date in article is overlapping the Loader icon.
 - 2010-12-27 Added extra documentation for bug#[6610](http://bugs.otrs.org/show_bug.cgi?id=6610) -
    OTRS\_CURRENT\_UserSalutation is always "-".
 - 2010-12-27 Fixed bug#[6605](http://bugs.otrs.org/show_bug.cgi?id=6605) - Error in url on admin package manager screen because wrong use of LQData.
 - 2010-12-23 Fixed bug#[6579](http://bugs.otrs.org/show_bug.cgi?id=6579) - ArticleTypeDefault is not selected in 'Note'
    on Bulk Action
 - 2010-12-23 Fixed bug#[6570](http://bugs.otrs.org/show_bug.cgi?id=6570) - Services/SLAs are not loaded if
    Ticket::Frontend::CustomerTicketMessage###Queue is set to "No"
 - 2010-12-23 Fixed bug#[6553](http://bugs.otrs.org/show_bug.cgi?id=6553) - Add CC for ticket customer function is no longer working.
 - 2010-12-22 Fixed bug#[4502](http://bugs.otrs.org/show_bug.cgi?id=4502) - Event Based Notification ignores SendNoNotification flag.
 - 2010-12-22 Fixed bug#[6596](http://bugs.otrs.org/show_bug.cgi?id=6596) - Ticket::Frontend::AgentTicketBounce###StateDefault doesn't work.
 - 2010-12-21 Fixed bug#[6576](http://bugs.otrs.org/show_bug.cgi?id=6576) - Unneeded entries in @INC.
 - 2010-12-21 Fixed bug#[6573](http://bugs.otrs.org/show_bug.cgi?id=6573) - Dutch notification texts don't display the ticket data.
 - 2010-12-20 Fixed bug#[6580](http://bugs.otrs.org/show_bug.cgi?id=6580) - Troubles modifying AgentTicketPhone in OTRS 3.0.3
    - using FreeText... failed.
 - 2010-12-20 Fixed bug#[6577](http://bugs.otrs.org/show_bug.cgi?id=6577) - AdminNotification screen does not work in IE7 on Windows XP.
 - 2010-12-17 Fixed bug#[6559](http://bugs.otrs.org/show_bug.cgi?id=6559) - the CK EDITOR for entering comments does not starts
    if you use CZ localization.
 - 2010-12-17 Fixed bug#[6560](http://bugs.otrs.org/show_bug.cgi?id=6560) - Link to "AgentPreferences" is shown even when the module is disabled.
 - 2010-12-17 Fixed bug#[6561](http://bugs.otrs.org/show_bug.cgi?id=6561) - Text sometimes too long for button.
 - 2010-12-17 Fixed bug#[6543](http://bugs.otrs.org/show_bug.cgi?id=6543) - UPGRADING should clearly state changed parameters
    of SetPermissions script.
 - 2010-12-16 Fixed bug#[6554](http://bugs.otrs.org/show_bug.cgi?id=6554) - SysConfig Group Handling.
 - 2010-12-15 Fixed bug#[6380](http://bugs.otrs.org/show_bug.cgi?id=6380) - Change Search Options does not list default fields.
 - 2010-12-14 Fixed bug#[6476](http://bugs.otrs.org/show_bug.cgi?id=6476) - Stats overview table has display error in table header.
 - 2010-12-14 Fixed bug#[6540](http://bugs.otrs.org/show_bug.cgi?id=6540) - System Log Hint could make room for more log information.
 - 2010-12-14 Fixed bug#[6541](http://bugs.otrs.org/show_bug.cgi?id=6541) - Left pane in AdminNotification is empty.
 - 2010-12-14 Fixed bug#[6542](http://bugs.otrs.org/show_bug.cgi?id=6542) - Typo in file UPGRADING.
 - 2010-12-14 Fixed bug#[6535](http://bugs.otrs.org/show_bug.cgi?id=6535) - Stats CSV output is not CSV, despite preference change.
 - 2010-12-14 Fixed bug#[6532](http://bugs.otrs.org/show_bug.cgi?id=6532) - With multiple inline images, only first one is
    preserved when replying.
 - 2010-12-14 Fixed bug#[6533](http://bugs.otrs.org/show_bug.cgi?id=6533) - Not possible to search tickets by responsible agent.
 - 2010-12-13 Fixed bug#[6520](http://bugs.otrs.org/show_bug.cgi?id=6520) - backup.pl doesn't backup with strong password.

# 3.0.4 2010-12-15
 - 2010-12-10 Improved handling of JavaScript code. Now post output filters
    are able to inject and modify JavaScript code.
 - 2010-12-09 Fixed bug#[6498](http://bugs.otrs.org/show_bug.cgi?id=6498) - Creating module translations with
    otrs.CreateTranslationFile.pl -l all creates new files.
 - 2010-11-09 Upgraded jQuery UI to 1.8.6 (to fix some IE9 bugs).
 - 2010-12-09 Fixed bug#[6515](http://bugs.otrs.org/show_bug.cgi?id=6515) - CSV export of SQL statement isn't working.
 - 2010-12-09 Updated Danish Translation, thanks to Lars Jorgensen!
 - 2010-12-09 Fixed bug#[6496](http://bugs.otrs.org/show_bug.cgi?id=6496) - Article Filter only displays one article.
 - 2010-12-08 Fixed bug#[6421](http://bugs.otrs.org/show_bug.cgi?id=6421) - AdminCustomerUser does not show customers without searching
 - 2010-12-08 Fixed bug#[6470](http://bugs.otrs.org/show_bug.cgi?id=6470) - AgentTicketForward does not support ArticleFreeText
 - 2010-12-08 Fixed bug#[6436](http://bugs.otrs.org/show_bug.cgi?id=6436) - Content validation with javascript does not
    consider "CheckEmailAddresses".
 - 2010-12-07 Fixed bug#[6200](http://bugs.otrs.org/show_bug.cgi?id=6200) - OTRS 3.0 customer navigation not configurable.
 - 2010-12-07 Fixed bug#[6012](http://bugs.otrs.org/show_bug.cgi?id=6012) - DashboardTicketGeneric.pm fails handing over
    "Attributes" to AgentTicketSearch().
 - 2010-12-07 Fixed bug#[6459](http://bugs.otrs.org/show_bug.cgi?id=6459) - Unwanted and unconfigurable text when customer has no ticket created yet.
    This text was adapted and can now optionally be configured with the SysConfig setting
    'Ticket::Frontend::CustomerTicketOverviewCustomEmptyText'.
 - 2010-12-06 Fixed bug#[6477](http://bugs.otrs.org/show_bug.cgi?id=6477) - There are no hooks for Output filters on ticket composing screens.
 - 2010-12-06 Fixed bug#[6414](http://bugs.otrs.org/show_bug.cgi?id=6414) - Ticket overview small: resizing problems.
 - 2010-12-06 Fixed bug#[6451](http://bugs.otrs.org/show_bug.cgi?id=6451) - Article Tree doesn't expand.
 - 2010-12-06 Fixed bug#[6427](http://bugs.otrs.org/show_bug.cgi?id=6427) - Building large number of CacheFileStorable/
    CacheInternalTicket Files will cause Software error.
 - 2010-12-06 Fixed bug#[6408](http://bugs.otrs.org/show_bug.cgi?id=6408) - Uploading an attachment removed previously uploaded inline images.
 - 2010-12-06 Fixed bug#[6234](http://bugs.otrs.org/show_bug.cgi?id=6234) - Field validation in the AgentTicketPhone mask kicks in after uploading a picture.
 - 2010-12-06 Fixed bug#[6425](http://bugs.otrs.org/show_bug.cgi?id=6425) - Ticket::Frontend::MenuModule###460-Delete and
    Ticket::Frontend::PreMenuModule###450-Delete resulting in white page.
 - 2010-12-03 Added possibility to see ticket actions on hover on every single ticket in medium and large
    ticket overviews (enable with TicketActionsPerTicket item on Ticket::Frontend::Overview###Medium or
    Ticket::Frontend::Overview###Preview setting).
 - 2010-12-03 Fixed bug#[6458](http://bugs.otrs.org/show_bug.cgi?id=6458) - "Lock" not indicated on compose.
 - 2010-12-03 Fixed bug#[6471](http://bugs.otrs.org/show_bug.cgi?id=6471) - Public interface handler is not able to load module
    specific JavaScript and CSS.
 - 2010-12-03 Fixed bug#[6262](http://bugs.otrs.org/show_bug.cgi?id=6262) - Results list can expand behind ticket history table.
 - 2010-12-03 Fixed bug#[6456](http://bugs.otrs.org/show_bug.cgi?id=6456) - Searches won't save selected queues.
 - 2010-12-03 Fixed bug#[6431](http://bugs.otrs.org/show_bug.cgi?id=6431) - TicketSearch Window broken in IE8.
 - 2010-12-03 Fixed bug#[6468](http://bugs.otrs.org/show_bug.cgi?id=6468) - Can't add "To" field to TicketSearch.
 - 2010-12-03 Fixed bug#[6289](http://bugs.otrs.org/show_bug.cgi?id=6289) - i18n: Creating a new stat shows hardcoded value 'New'.
 - 2010-12-03 Fixed bug#[6304](http://bugs.otrs.org/show_bug.cgi?id=6304) - Not sure about the meaning of "3".
 - 2010-12-03 Updated Russian translation, thanks to Sergey Romanov!
 - 2010-12-02 Fixed bug#[6366](http://bugs.otrs.org/show_bug.cgi?id=6366) - gnupg signatures not working correct for partly signed messages.
 - 2010-12-01 Fixed bug#[6303](http://bugs.otrs.org/show_bug.cgi?id=6303) - Article display height in ticket zoom of customer interface can be too high.
 - 2010-12-01 Updated Danish translation, thanks to Lars Jorgensen!
 - 2010-12-01 Fixed bug#[6440](http://bugs.otrs.org/show_bug.cgi?id=6440) - Incomplete Action parameter after logging in to the
    customer interface.
 - 2010-12-01 Fixed bug#[6455](http://bugs.otrs.org/show_bug.cgi?id=6455) - Ticket actions in Ticket Overview are not usable if
    session id is not in cookie.
 - 2010-12-01 Fixed bug#[6453](http://bugs.otrs.org/show_bug.cgi?id=6453) - Moving Tickets via AgentTicketMove empties set Free Fields.
 - 2010-11-30 Updated Serbian translation, thanks to Milorad Jovanovic!
 - 2010-11-30 Fixed bug#[6401](http://bugs.otrs.org/show_bug.cgi?id=6401) - Invalid agents are partially ignored/shown in ticket masks.
 - 2010-11-30 Fixed bug#[6040](http://bugs.otrs.org/show_bug.cgi?id=6040) - Remove ReplyAll option if possible in agent interface.
 - 2010-11-29 Fixed bug#[4856](http://bugs.otrs.org/show_bug.cgi?id=4856) - Notifications are sent even if ticket is created with closed state.
 - 2010-11-29 Fixed bug#[6420](http://bugs.otrs.org/show_bug.cgi?id=6420) - Customer Search with No Results does not display appropriate message.
 - 2010-11-29 Fixed bug#[6428](http://bugs.otrs.org/show_bug.cgi?id=6428) - FreeText field alignment is wrong in AdminGenericAgent.
 - 2010-11-29 Updated Japanese translation, thanks to Kaz Kamimura!
 - 2010-11-29 Fixed bug#[2950](http://bugs.otrs.org/show_bug.cgi?id=2950) - Field labels for ArticleFreeTime are not translated in PDF print.
 - 2010-11-29 Fixed bug#[6401](http://bugs.otrs.org/show_bug.cgi?id=6401) - Field label for Content not aligned in SysConfig.
 - 2010-11-26 Fixed bug#[6390](http://bugs.otrs.org/show_bug.cgi?id=6390) - Customer Interface - Latest article hover text is always 'Loading'.

# 3.0.3 2010-11-29
 - 2010-11-26 Fixed bug#[6393](http://bugs.otrs.org/show_bug.cgi?id=6393) - ArticleFreeText is missing in Customer Interface TicketZoom.
 - 2010-11-26 Fixed bug#[6396](http://bugs.otrs.org/show_bug.cgi?id=6396) - Freetext fields can't be added to ticket search.
 - 2010-11-25 Fixed bug#[6131](http://bugs.otrs.org/show_bug.cgi?id=6131) - Lack of warning for revoked and expired keys for PGP signs on emails.
 - 2010-11-25 Fixed bug#[6361](http://bugs.otrs.org/show_bug.cgi?id=6361) - Upgrade v2.4-\>v3.0 on MySQL with InnoDB as storage
    engine generates an error.
 - 2010-11-25 Fixed bug#[6199](http://bugs.otrs.org/show_bug.cgi?id=6199) - OTRS 3.0 ToolBarSearchFulltext has no product design.
 - 2010-11-25 Fixed bug#[2638](http://bugs.otrs.org/show_bug.cgi?id=2638) - Broken email syntax detection.
 - 2010-11-25 Fixed bug#[6392](http://bugs.otrs.org/show_bug.cgi?id=6392) - Email addresses containing special but allowed
    characters are not accepted in customer administration.
 - 2010-11-25 Fixed bug#[6367](http://bugs.otrs.org/show_bug.cgi?id=6367) - My Queues Selection Box doesn't display well on lower resolutions.
 - 2010-11-24 Fixed bug#[6379](http://bugs.otrs.org/show_bug.cgi?id=6379) - No Ajax Update fro Crypt and Sign fields when you set the customer on Email Compose.
 - 2010-11-24 Fixed bug#[6395](http://bugs.otrs.org/show_bug.cgi?id=6395) - Broken use of PGP Sign on AgentTicketEmail screen.
 - 2010-11-24 Fixed bug#[6388](http://bugs.otrs.org/show_bug.cgi?id=6388) - In the Medium view, the title of the ticket is truncated after 25 characters.
 - 2010-11-24 Fixed bug#[6389](http://bugs.otrs.org/show_bug.cgi?id=6389) - Customer TicketZoom - Ticket Title is truncated after 25 characters.
 - 2010-11-24 Fixed bug#[6370](http://bugs.otrs.org/show_bug.cgi?id=6370) - New customer form submission - errors are silently dropped.
 - 2010-11-24 Fixed bug#[6264](http://bugs.otrs.org/show_bug.cgi?id=6264) - CKEditor Image upload does not show a correct behavior in case a FormID is missing.
 - 2010-11-24 Fixed bug#[6353](http://bugs.otrs.org/show_bug.cgi?id=6353) - GenericAgent throws error when ArticleFS storage used.
 - 2010-11-24 Added new Japanese translation, thanks to Kaz Kamimura Thomas!
 - 2010-11-24 Fixed bug#[6187](http://bugs.otrs.org/show_bug.cgi?id=6187) - IE9: article height incorrectly calculated.
 - 2010-11-24 Fixed bug#[6188](http://bugs.otrs.org/show_bug.cgi?id=6188) - IE9: article table resize handle has no effect.
 - 2010-11-24 Fixed bug#[6189](http://bugs.otrs.org/show_bug.cgi?id=6189) - IE9: ticket overview table headers behave incorrectly.
 - 2010-11-24 Fixed bug#[6382](http://bugs.otrs.org/show_bug.cgi?id=6382) - otrs.ArticleStorageSwitch.pl script not working.
 - 2010-11-24 Fixed bug#[6378](http://bugs.otrs.org/show_bug.cgi?id=6378) - The error messages are displayed incorrectly in the action list.
 - 2010-11-23 Fixed bug#[6314](http://bugs.otrs.org/show_bug.cgi?id=6314) - Upgrade 2.4.x -\> 3.0.x - older tickets in database
    are marked as unread.
 - 2010-11-23 Fixed bug#[6360](http://bugs.otrs.org/show_bug.cgi?id=6360) - Bulk Action link all to ticket number doesn't link anything.
 - 2010-11-23 Fixed bug#[6286](http://bugs.otrs.org/show_bug.cgi?id=6286) - Adding a phone call outbound does indicate an unread article.
 - 2010-11-23 Fixed bug#[6283](http://bugs.otrs.org/show_bug.cgi?id=6283) - FreeText field search is not possible in Customer Interface.
 - 2010-11-23 Fixed bug#[6362](http://bugs.otrs.org/show_bug.cgi?id=6362) - Software error adding new PGP key.
 - 2010-11-23 Fixed bug#[6273](http://bugs.otrs.org/show_bug.cgi?id=6273) - IE7: Alert dialog display problems.
 - 2010-11-23 Fixed bug#[6260](http://bugs.otrs.org/show_bug.cgi?id=6260) - RichTextEditor Action for Inline-Image Upload is hard coded.
 - 2010-11-23 Fixed bug#[6371](http://bugs.otrs.org/show_bug.cgi?id=6371) - Opening the customer ticket zoom shows a browser error message.
 - 2010-11-23 Fixed bug#[6308](http://bugs.otrs.org/show_bug.cgi?id=6308) - Ticket search templates are not saved in agent interface.
 - 2010-11-23 Fixed bug#[6359](http://bugs.otrs.org/show_bug.cgi?id=6359) - Documentation fixes.
 - 2010-11-23 Fixed bug#[6368](http://bugs.otrs.org/show_bug.cgi?id=6368) - Change search options does not work in customer interface.
 - 2010-11-23 Fixed bug#[6346](http://bugs.otrs.org/show_bug.cgi?id=6346) - Upgrading script 2.4 -\> 3.0 may cause corruption of
    the configuration files (ZZZAuto.pm and ZZZAAuto.pm).
 - 2010-11-23 Fixed bug#[6357](http://bugs.otrs.org/show_bug.cgi?id=6357) - Customer search URL contains ampersands (&) instead of semicolons (;).
 - 2010-11-22 Fixed bug#[6358](http://bugs.otrs.org/show_bug.cgi?id=6358) - No custom CSS or JS is loaded from public module registration settings.
 - 2010-11-22 Fixed bug#[6355](http://bugs.otrs.org/show_bug.cgi?id=6355) - $HOME/bin/otrs.LoaderCache.pl cron job unhappy with
    files in var/httpd/htdocs/skins/Customer/.
 - 2010-11-22 Fixed bug#[6352](http://bugs.otrs.org/show_bug.cgi?id=6352) - var/cron/cache schedules nonexistent $HOME/bin/otrs.CacheDelete.pl.
 - 2010-11-22 Fixed bug#[6350](http://bugs.otrs.org/show_bug.cgi?id=6350) - Sort order in "Auto Responses \<-\> Queues".
 - 2010-11-19 Fixed bug#[6288](http://bugs.otrs.org/show_bug.cgi?id=6288) - Generating a stat that outputs to PDF or CSV opens an empty pop-up.
 - 2010-11-19 Fixed bug#[6300](http://bugs.otrs.org/show_bug.cgi?id=6300) - Revoked GPG-Keys are not shown as revoked.
 - 2010-11-19 Fixed bug#[6343](http://bugs.otrs.org/show_bug.cgi?id=6343) - CSS problem in the result list of ticket customer search.
 - 2010-11-19 Fixed bug#[6327](http://bugs.otrs.org/show_bug.cgi?id=6327) - More problems when using Session instead of Cookie.
 - 2010-11-19 Fixed bug#[6337](http://bugs.otrs.org/show_bug.cgi?id=6337) - Generic Agent has "Delete Ticket" as Default set -\> risk of ticket loss!
 - 2010-11-18 Fixed bug#[6330](http://bugs.otrs.org/show_bug.cgi?id=6330) - Bad character in Polish translation.
 - 2010-11-18 Fixed bug#[6324](http://bugs.otrs.org/show_bug.cgi?id=6324) - If you use Sessions in URLs and not in cookies,
    responding to tickets logs you out.
 - 2010-11-17 Upgraded jQuery to 1.4.4 because of a number of regressions in 1.4.3.
 - 2010-11-17 Fixed bug#[6232](http://bugs.otrs.org/show_bug.cgi?id=6232) - FreeText fields requiredness is not indicated.
 - 2010-11-17 Fixed bug#[6318](http://bugs.otrs.org/show_bug.cgi?id=6318) - Error in error log due to comparison with a value that sometimes does not exist on Customer Search.
 - 2010-11-17 Fixed bug#[6317](http://bugs.otrs.org/show_bug.cgi?id=6317) - No Pagination String in Customer Search Results.
 - 2010-11-17 Fixed bug#[6309](http://bugs.otrs.org/show_bug.cgi?id=6309) - SortBy columns performs a full ticket search on customer ticket search results.
 - 2010-11-16 Fixed bug#[6316](http://bugs.otrs.org/show_bug.cgi?id=6316) - CustomerLogo not working.
 - 2010-11-16 Fixed bug#[5797](http://bugs.otrs.org/show_bug.cgi?id=5797) - SMIME functionality does not work with OpenSSL 1.0.0.
 - 2010-11-16 Fixed bug#[6302](http://bugs.otrs.org/show_bug.cgi?id=6302) - Inbound mail password displayed in clear text during install.
 - 2010-11-16 Fixed bug#[6261](http://bugs.otrs.org/show_bug.cgi?id=6261) - Remove drop down from SysConfig start screen.
 - 2010-11-16 Fixed bug#[6294](http://bugs.otrs.org/show_bug.cgi?id=6294) - GenericAgent - Time Selection is not in columns.

# 3.0.2 2010-11-17
 - 2010-11-16 Fixed bug#[6278](http://bugs.otrs.org/show_bug.cgi?id=6278) - Public and Customer frontends disclose version information.
 - 2010-11-16 Fixed bug#[6297](http://bugs.otrs.org/show_bug.cgi?id=6297) - [IE8] can't open popups.
 - 2010-11-15 Fixed bug#[6290](http://bugs.otrs.org/show_bug.cgi?id=6290) - Generic Agent Weekdays are not correctly sorted.

# 3.0.1 2010-11-15
 - 2010-11-12 Fixed bug#[6268](http://bugs.otrs.org/show_bug.cgi?id=6268) - Error in web installer when setting up RPM on CentOS.
 - 2010-11-12 Fixed bug#[6271](http://bugs.otrs.org/show_bug.cgi?id=6271) - In IE8 customer name does not come up when
    you create new Tickets and enter customer name.
 - 2010-11-12 Fixed bug#[6225](http://bugs.otrs.org/show_bug.cgi?id=6225) - User creation gives confusing error message when
    email address is incorrect.
 - 2010-11-12 Fixed bug#[6266](http://bugs.otrs.org/show_bug.cgi?id=6266) - Order of TicketOverview columns in CPanel.
 - 2010-11-11 Fixed bug#[5984](http://bugs.otrs.org/show_bug.cgi?id=5984) - Attachment is lost when replying / forwarding /
    splitting articles.
 - 2010-11-11 Fixed bug#[6222](http://bugs.otrs.org/show_bug.cgi?id=6222) - Links are not displayed completely in HTML articles.
 - 2010-11-10 Fixed bug#[6257](http://bugs.otrs.org/show_bug.cgi?id=6257) - Watched Tickets ToolBarModule does not have a shortcut defined
    - leads to display issues.
 - 2010-11-10 Fixed bug#[6254](http://bugs.otrs.org/show_bug.cgi?id=6254) - Reloading article in ticket zoom corrupts encoding.
 - 2010-11-10 Fixed bug#[6111](http://bugs.otrs.org/show_bug.cgi?id=6111): i18n - Admin Link relation edit screens translation issues.
 - 2010-11-10 Fixed bug#[6061](http://bugs.otrs.org/show_bug.cgi?id=6061): Field size harmonization.
 - 2010-11-10 Updated zh\_CN translation, thanks to Never Min!
 - 2010-11-09 Updated CPAN module CGI to version 3.50.
 - 2010-11-09 Fixed bug#[6251](http://bugs.otrs.org/show_bug.cgi?id=6251) - Admin Group Interface produces an error log entry.
 - 2010-11-09 Fixed bug#[5043](http://bugs.otrs.org/show_bug.cgi?id=5043) - All Tickets / Locked Tickets View in QueueView missing.
 - 2010-11-09 Fixed bug#[6238](http://bugs.otrs.org/show_bug.cgi?id=6238) - Global Overview settings are centered on the results, not on the page.
 - 2010-11-09 Fixed bug#[6071](http://bugs.otrs.org/show_bug.cgi?id=6071) - Ticket Zoom - back button does not work as expected.
 - 2010-11-09 Fixed bug#[5788](http://bugs.otrs.org/show_bug.cgi?id=5788) - IE Browser Error "Out of memory at line: 35".
 - 2010-11-08 Fixed bug#[6225](http://bugs.otrs.org/show_bug.cgi?id=6225) - User creation gives confusing error message when email address is incorrect.
 - 2010-11-08 Fixed bug#[6227](http://bugs.otrs.org/show_bug.cgi?id=6227) - Customer User creation gives confusing error message when email address is
     not validated.
 - 2010-11-08 Fixed bug#[6241](http://bugs.otrs.org/show_bug.cgi?id=6241) - Need Ticket::ViewableStateType in Kernel/Config.pm.
 - 2010-11-08 Fixed bug#[6240](http://bugs.otrs.org/show_bug.cgi?id=6240) - Agent Dashboard - ticket opens only when clicking on the number.
 - 2010-11-08 Fixed bug#[5935](http://bugs.otrs.org/show_bug.cgi?id=5935) - TicketSearch Button - various improvements.
 - 2010-11-05 Fixed bug#[6113](http://bugs.otrs.org/show_bug.cgi?id=6113) - SysConfig - add a shortcut to "Change" button.
 - 2010-11-05 Fixed bug#[5930](http://bugs.otrs.org/show_bug.cgi?id=5930) - Optimisation in
    Kernel::Modules::CustomerTicketOverView-\>ShowTicketStatus.

# 3.0.0 beta7 2010-11-08
 - 2010-11-05 Fixed bug#[6151](http://bugs.otrs.org/show_bug.cgi?id=6151) - No visual notification when generated article in ticket views.
 - 2010-11-05 Upgraded CKEditor to 3.4.2.
 - 2010-11-05 Fixed bug#[6237](http://bugs.otrs.org/show_bug.cgi?id=6237) - Datepicker starts weeks always on Sunday.
 - 2010-11-04 Skins can now be selected based on hostname with the configuration
    settings "Loader::Agent::DefaultSelectedSkin::HostBased" and
    "Loader::Customer::SelectedSkin::HostBased".
 - 2010-11-04 Fixed bug#[6216](http://bugs.otrs.org/show_bug.cgi?id=6216) - Queue names with spaces not displayed correctly in ticket view.
 - 2010-11-04 Fixed bug#[6186](http://bugs.otrs.org/show_bug.cgi?id=6186) - IE9: Dashboard widget functions broken.
 - 2010-11-04 Fixed bug#[6185](http://bugs.otrs.org/show_bug.cgi?id=6185) - IE9: JS error in the Dashboard.
 - 2010-11-04 Fixed bug#[6231](http://bugs.otrs.org/show_bug.cgi?id=6231) - Link delete screen redirects to itself if the bulk checkbox is used.
 - 2010-11-04 Fixed bug#[6215](http://bugs.otrs.org/show_bug.cgi?id=6215) - Agents can't have two popups open at the same time.
 - 2010-11-04 Fixed bug#[6228](http://bugs.otrs.org/show_bug.cgi?id=6228) - No difference between prio 1, 2 and 3 in overviews.
 - 2010-11-04 Fixed bug#[5757](http://bugs.otrs.org/show_bug.cgi?id=5757) - Article table resizing does not work correctly in IE7.
 - 2010-11-04 Fixed bug#[6229](http://bugs.otrs.org/show_bug.cgi?id=6229) - Submit button for Change Customer is below the fold with large amount of history.
 - 2010-11-04 Fixed bug#[6191](http://bugs.otrs.org/show_bug.cgi?id=6191) - Dashboard filter loses context after moving to next "bundle".
 - 2010-11-04 Fixed bug#[6207](http://bugs.otrs.org/show_bug.cgi?id=6207) - Pagination does not work in dashboard.
 - 2010-11-04 Fixed bug#[5937](http://bugs.otrs.org/show_bug.cgi?id=5937) - Large overview data presentation issues.
 - 2010-11-04 Fixed bug#[6203](http://bugs.otrs.org/show_bug.cgi?id=6203) - Rich Text Editor - right click on misspelled words in Firefox does not work as expected.
 - 2010-11-03 Fixed bug#[4273](http://bugs.otrs.org/show_bug.cgi?id=4273) - No required fields indication in AdminUser screen.
 - 2010-11-03 Added Serbian translation, thanks to Milorad JovanoviÄ‡!
 - 2010-11-03 Fixed bug#[6073](http://bugs.otrs.org/show_bug.cgi?id=6073) - Search window does not resize to selected content.
 - 2010-11-03 Fixed bug#[6122](http://bugs.otrs.org/show_bug.cgi?id=6122) - TicketZoom Scroller Height is calculation is broken.
 - 2010-11-03 Fixed bug#[5649](http://bugs.otrs.org/show_bug.cgi?id=5649) - Changing owner in M and S views opens in same tab instead of popup.
 - 2010-11-03 Fixed bug#[6181](http://bugs.otrs.org/show_bug.cgi?id=6181) - Customer Login box does not work if password is in browser cache.
 - 2010-11-03 Fixed bug#[6206](http://bugs.otrs.org/show_bug.cgi?id=6206) - DefineEmailFrom is not used when creating an email-ticket.
 - 2010-11-03 Fixed bug#[6156](http://bugs.otrs.org/show_bug.cgi?id=6156) - No FreeText Fields in Search.
 - 2010-11-02 Fixed bug#[6092](http://bugs.otrs.org/show_bug.cgi?id=6092) - Skins cannot be selected based on hostname.
 - 2010-11-02 Fixed bug#[5054](http://bugs.otrs.org/show_bug.cgi?id=5054) - Page titles could be more compact and informative.
 - 2010-11-02 Fixed bug#[6213](http://bugs.otrs.org/show_bug.cgi?id=6213) - If you use AgentTicketMove in a separate screen,
    it does not open in a popup.
 - 2010-11-02 Fixed bug#[6208](http://bugs.otrs.org/show_bug.cgi?id=6208) - If ticket zoom is not fully loaded actions will
    open in same window instead of popup.
 - 2010-11-02 Fixed bug#[6210](http://bugs.otrs.org/show_bug.cgi?id=6210) - GetUserData() function caching does not work correctly in all scenarios.
 - 2010-11-02 Fixed bug#[4565](http://bugs.otrs.org/show_bug.cgi?id=4565) - OutOfOffice information is displayed in responses and signatures.
 - 2010-11-02 Fixed bug#[6055](http://bugs.otrs.org/show_bug.cgi?id=6055) - 500 Error when closing ticket with non-original/changed customer.
 - 2010-11-02 Fixed bug#[5830](http://bugs.otrs.org/show_bug.cgi?id=5830) - Sometimes when replying on ticket getting error
    "Can't use an undefined value as a SCALAR reference".
 - 2010-11-02 Fixed bug#[5296](http://bugs.otrs.org/show_bug.cgi?id=5296) - Event based notifications do not check for local mail address.
 - 2010-11-02 Fixed bug#[1639](http://bugs.otrs.org/show_bug.cgi?id=1639) - Limit search time to certain amount by default.
 - 2010-11-02 Updated CPAN module JSON to version 2.27.
 - 2010-11-02 Fixed bug#[6205](http://bugs.otrs.org/show_bug.cgi?id=6205) - DefineEmailFrom does not use SystemAddress when set to
    Agent Name + FromSeparator + System Address Display Name.
 - 2010-11-02 Fixed bug#[6162](http://bugs.otrs.org/show_bug.cgi?id=6162) - When you close a search before complete load,
    it will be reopened automatically.
 - 2010-11-02 Fixed bug#[6060](http://bugs.otrs.org/show_bug.cgi?id=6060) - IE7 customer management in a popup breaks ticket creation page.
 - 2010-11-02 Fixed bug#[6204](http://bugs.otrs.org/show_bug.cgi?id=6204) - Autocomplete of customer users shows encoding characters.
 - 2010-11-02 Fixed bug#[6201](http://bugs.otrs.org/show_bug.cgi?id=6201) - Not able to save FreeText fields if TimeInput it set to required.
 - 2010-11-01 Fixed bug#[6137](http://bugs.otrs.org/show_bug.cgi?id=6137) - Split action does not create a link to the original ticket.
 - 2010-10-29 Fixed bug#[6163](http://bugs.otrs.org/show_bug.cgi?id=6163) - In Phone Ticket you can't attach files automatically after choosing a customer.
 - 2010-10-29 Fixed bug#[5917](http://bugs.otrs.org/show_bug.cgi?id=5917) - Thirdparty [Firefox]: Search freezes after deleting one field from profile.
 - 2010-10-29 Fixed bug#[5989](http://bugs.otrs.org/show_bug.cgi?id=5989) - Thirdparty [ckeditor?]: Using address book in reply window breaks the message body text box.
 - 2010-10-29 Updated Russian translation, thanks to Eugene Kungurov!
 - 2010-10-29 Fixed bug#[6184](http://bugs.otrs.org/show_bug.cgi?id=6184) - Streamline required field error messages.
 - 2010-10-28 Fixed bug#[5657](http://bugs.otrs.org/show_bug.cgi?id=5657) - In Global Ticket Overview, sorting for Prio is missing.
 - 2010-10-28 Fixed bug#[6141](http://bugs.otrs.org/show_bug.cgi?id=6141) - Sysconfig Address Book disable.
 - 2010-10-28 Upgraded CKEditor to 3.4.1.
 - 2010-10-27 Fixed bug#[6082](http://bugs.otrs.org/show_bug.cgi?id=6082) - Graph selections appear even if GD is not installed.
 - 2010-10-27 Fixed bug#[6059](http://bugs.otrs.org/show_bug.cgi?id=6059) - Customer name with quotes is truncated.
 - 2010-10-27 Fixed bug#[6094](http://bugs.otrs.org/show_bug.cgi?id=6094) - Responses in ticket view don't match.
 - 2010-10-27 Fixed bug#[6116](http://bugs.otrs.org/show_bug.cgi?id=6116) - ZoomExpand preference works inverted for articles.
 - 2010-10-27 Fixed bug#[6125](http://bugs.otrs.org/show_bug.cgi?id=6125) - Customer IDs with underscores do not work properly.
 - 2010-10-27 Fixed bug#[5637](http://bugs.otrs.org/show_bug.cgi?id=5637) - In Phone Ticket -\> Create a new customer via Popup,
    it's not possible to take over the recent created customer.
    Only a link to create a new ticket appears.
 - 2010-10-26 Fixed bug#[6076](http://bugs.otrs.org/show_bug.cgi?id=6076) - Bulk unlock does not work correctly.
 - 2010-10-26 Fixed bug#[6163](http://bugs.otrs.org/show_bug.cgi?id=6163) - In Phone Ticket you can't attach files automatically after choosing a customer.
 - 2010-10-26 Fixed bug#[6114](http://bugs.otrs.org/show_bug.cgi?id=6114) - Percentage sign in Customers \<-\> Services interface when using
    Dutch translation.
 - 2010-10-25 Fixed bug#[6160](http://bugs.otrs.org/show_bug.cgi?id=6160) - ServiceList function breaks if you have service names with
    special characters like ? ? ? or + + +.
 - 2010-10-25 Fixed bug#[6118](http://bugs.otrs.org/show_bug.cgi?id=6118) - The "Small", "Medium" and "Large" Queue views are broken if no
    data is found.

# 3.0.0 beta6 2010-10-25
 - 2010-10-22 Fixed bug#[6150](http://bugs.otrs.org/show_bug.cgi?id=6150) - Spell checker should not be enabled by default.
 - 2010-10-22 Fixed bug#[6149](http://bugs.otrs.org/show_bug.cgi?id=6149) - New users get Ivory skin when created by admin using non-english language.
 - 2010-10-22 Updated CPAN module Text::CSV to version 1.20.
 - 2010-10-21 Fixed bug#[6089](http://bugs.otrs.org/show_bug.cgi?id=6089) - Close Window in Statistics doesn't work.
 - 2010-10-20 Fixed bug#[6132](http://bugs.otrs.org/show_bug.cgi?id=6132) - Wrong caching in RoleLookup function in Kernel/System/Group.pm.
 - 2010-10-19 Fixed bug#[6124](http://bugs.otrs.org/show_bug.cgi?id=6124) - Wrong caching in GroupLookup function in Kernel/System/Group.pm.
 - 2010-10-19 Fixed bug#[6127](http://bugs.otrs.org/show_bug.cgi?id=6127) - External function to create validation rules fails in Firefox on Ubuntu Linux.
 - 2010-10-19 Updated CPAN module Net::POP3::SSLWrapper to version 0.05.
 - 2010-10-19 Updated CPAN module Net::IMAP::Simple to version 1.2017.
 - 2010-10-19 Updated CPAN module MailTools to version 2.07.
 - 2010-10-19 Updated CPAN module JSON to version 2.26.
 - 2010-10-19 Updated CPAN module Apache::Reload to version 0.11.
 - 2010-10-18 Fixed bug#[6117](http://bugs.otrs.org/show_bug.cgi?id=6117) - Find method in VirtualFS is not able to find a file
    by Filename and Preferences
 - 2010-10-17 Fixed bug#[6090](http://bugs.otrs.org/show_bug.cgi?id=6090) - Accounted Time is not displayed in articles if
    Ticket::ZoomTimeDisplay is set to 'yes'.
 - 2010-10-17 Fixed bug#[6112](http://bugs.otrs.org/show_bug.cgi?id=6112) - Database IDs displayed in Admin GUI.
 - 2010-10-17 Fixed bug#[6110](http://bugs.otrs.org/show_bug.cgi?id=6110) - AdminCustomerUserGroup lists non-existing group 'info'.
 - 2010-10-17 Fixed bug#[6109](http://bugs.otrs.org/show_bug.cgi?id=6109) - '0' is not recognized as a valid input for TimeUnits.
 - 2010-10-12 Fixed bug#[6058](http://bugs.otrs.org/show_bug.cgi?id=6058) - Keyboard shortcuts should be shown via tooltip.
 - 2010-10-12 Added ability to open ticket history and other ticket actions
    in parallel.
 - 2010-10-12 Fixed bug#[6047](http://bugs.otrs.org/show_bug.cgi?id=6047) - Secure::DisableBanner does not work.
 - 2010-10-11 Fixed bug#[6079](http://bugs.otrs.org/show_bug.cgi?id=6079) - Unread tickets does mark as readed only second time.
 - 2010-10-11 Fixed bug#[5921](http://bugs.otrs.org/show_bug.cgi?id=5921) - RedHat rc script does not ignore ".save" files
    when rebuilding the cron jobs.
 - 2010-10-11 Fixed bug#[6040](http://bugs.otrs.org/show_bug.cgi?id=6040) - Remove ReplyAll option if possible.
 - 2010-10-07 Fixed bug#[5994](http://bugs.otrs.org/show_bug.cgi?id=5994) - Creating new statistic, field validation kicks in immediately.
 - 2010-10-07 Fixed bug#[5975](http://bugs.otrs.org/show_bug.cgi?id=5975) - Notifications (event-based) to external email
    address are visible to customers.

# 3.0.0 beta5 2010-10-11
 - 2010-10-04 Fixed bug#[6064](http://bugs.otrs.org/show_bug.cgi?id=6064) - Predefined responses does not work.
 - 2010-10-01 Big improvements to TicketZoom rendering performance.
 - 2010-09-30 Fixed bug#[6054](http://bugs.otrs.org/show_bug.cgi?id=6054) - The default services are not loaded when creating a new ticket.
 - 2010-09-30 Fixed bug#[5911](http://bugs.otrs.org/show_bug.cgi?id=5911) - Enhance menu behavior.
    The submenus in the agent main menu open on click by default. With the new
    config "OpenMainMenuOnHover" setting it can be specified that they should
    also open on mouse hover.
 - 2010-09-30 Updated Ukrainian translation file, thanks to Ð‘ÐµÐ»ÑŒÑ?ÐºÐ¸Ð¹ Ð?Ñ€Ñ‚ÐµÐ¼!
 - 2010-09-30 Fixed bug#[5979](http://bugs.otrs.org/show_bug.cgi?id=5979) - IE8 - articles for a ticket doesn't switch
 - 2010-09-29 Fixed bug#[6017](http://bugs.otrs.org/show_bug.cgi?id=6017) - QueueLookup function returns wrong QueueID if a
    queue name was updated.
 - 2010-09-29 Fixed bug#[6019](http://bugs.otrs.org/show_bug.cgi?id=6019) - Choosing a search template does nothing.
 - 2010-09-29 Fixed bug#[6033](http://bugs.otrs.org/show_bug.cgi?id=6033) - Too many toolbar icons shown by default.
    Toolbar shortcuts are not shown by default.
    Toolbar items for tickets (such as locked tickets) are only shown if
    they have active tickets.
 - 2010-09-29 Fixed bug#[6032](http://bugs.otrs.org/show_bug.cgi?id=6032) - Customer History context settings not working.
 - 2010-09-28 Fixed bug#[6021](http://bugs.otrs.org/show_bug.cgi?id=6021) - Ticket Types are still displayed if they're invalid.
 - 2010-09-28 Fixed bug#[4732](http://bugs.otrs.org/show_bug.cgi?id=4732) - Mysql table index not used when LOWER()
    is used in queries for customer\_user.login. There is now a new flag CaseSensitive
    in the customer DB settings. Setting this to 1 will improve performance
    dramatically on large databases.
 - 2010-09-24 Fixed bug#[6007](http://bugs.otrs.org/show_bug.cgi?id=6007) - Free field content not saved.

# 3.0.0 beta4 2010-09-27
 - 2010-09-24 Updated Russian translation file, thanks to Eugene Kungurov!
 - 2010-09-24 Fixed bug#[5655](http://bugs.otrs.org/show_bug.cgi?id=5655) - In Article Zoom, after a new article got created
    and page reloads, new article is shown as new. It's confusing.
 - 2010-09-24 Fixed bug#[5848](http://bugs.otrs.org/show_bug.cgi?id=5848) - Wrong characters in Czech language.
 - 2010-09-24 Updated Czech translation file, thanks to Pavel!
 - 2010-09-24 Fixed bug#[5962](http://bugs.otrs.org/show_bug.cgi?id=5962) - ToolBarModule and TicketSearchProfile, management
    of search profiles is not working correctly.
 - 2010-09-23 Fixed bug#[5950](http://bugs.otrs.org/show_bug.cgi?id=5950) - Customer History not shown in Change Customer View.
 - 2010-09-23 Changed ResponseFormat to TOFU (what people expect).
 - 2010-09-23 Fixed bug#[3515](http://bugs.otrs.org/show_bug.cgi?id=3515) - AgentTicketMove standard "Note" and "Subject" cannot be configured.
 - 2010-09-23 Fixed bug#[5965](http://bugs.otrs.org/show_bug.cgi?id=5965) - AgentTicketMove does not support setting of "Note" and "Subject".
 - 2010-09-23 Fixed bug#[5999](http://bugs.otrs.org/show_bug.cgi?id=5999) - Undefined variables generate warning in CustomerTicketMessage.
 - 2010-09-23 Fixed bug#[5980](http://bugs.otrs.org/show_bug.cgi?id=5980) - Free fields are not properly aligned.
 - 2010-09-23 Fixed bug#[5983](http://bugs.otrs.org/show_bug.cgi?id=5983) - Outlook inline image is displayed in attachment list.
 - 2010-09-23 Fixed bug#[5849](http://bugs.otrs.org/show_bug.cgi?id=5849) - Headline / Company Name is hardcoded in the DTL of the customer interface.
 - 2010-09-23 Fixed bug#[5988](http://bugs.otrs.org/show_bug.cgi?id=5988) - ActionRow in customer interface displays incorrectly
    when zoomed, in Firefox/Webkit browser
 - 2010-09-23 Fixed bug#[5995](http://bugs.otrs.org/show_bug.cgi?id=5995) - Pagination in Customer Interface does not work.
 - 2010-09-23 Fixed bug#[5982](http://bugs.otrs.org/show_bug.cgi?id=5982) - Email address does not render properly if it
    contains braces.
 - 2010-09-23 Fixed bug#[5987](http://bugs.otrs.org/show_bug.cgi?id=5987) - No column titles for ticket list in customer interface.
    This can now be configured with the config setting
    "Ticket::Frontend::CustomerTicketOverviewSortable".
 - 2010-09-22 Fixed bug#[5964](http://bugs.otrs.org/show_bug.cgi?id=5964) - The given param 'klant@ykoon.xx' in 'WatchUserIDs' is
    invalid in customer panel!
 - 2010-09-22 Fixed bug#[5956](http://bugs.otrs.org/show_bug.cgi?id=5956) - Arrows to expand/collapse Support Module details point
    in the wrong direction.
 - 2010-09-22 Fixed bug#[5976](http://bugs.otrs.org/show_bug.cgi?id=5976) - Admin Notification (event) text box runs outside the screen.
 - 2010-09-22 Fixed bug#[5959](http://bugs.otrs.org/show_bug.cgi?id=5959) - Agent gets "Invalid argument" JavaScript Error in Ticket Zoom.
 - 2010-09-21 Fixed bug#[5970](http://bugs.otrs.org/show_bug.cgi?id=5970) - Wrong orientation of expand / collapse arrows.
 - 2010-09-20 Fixed bug#[5707](http://bugs.otrs.org/show_bug.cgi?id=5707) - Web Installer Mail Configuration does not list all SMTP backends/options.
 - 2010-09-15 Fixed bug#[5948](http://bugs.otrs.org/show_bug.cgi?id=5948) - Address Book will not open for ticket forwarding.
 - 2010-09-15 Fixed bug#[5943](http://bugs.otrs.org/show_bug.cgi?id=5943) - Customer Link behaviour in ZoomView.
 - 2010-09-13 Fixed bug#[5649](http://bugs.otrs.org/show_bug.cgi?id=5649) - Changing owner from L view opens in same tab instead of popup.
 - 2010-09-13 Fixed bug#[5929](http://bugs.otrs.org/show_bug.cgi?id=5929) - CheckURLHash();get's called every 500ms - generates
    not needed load.

# 3.0.0 beta3 2010-09-13
 - 2010-09-10 Fixed bug#[5525](http://bugs.otrs.org/show_bug.cgi?id=5525) - If submit button is clicked repeatedly two or more tickets
    can be created instead of one.
 - 2010-09-10 Fixed bug#[5923](http://bugs.otrs.org/show_bug.cgi?id=5923) - Can't set pending date to today but few hours later.
 - 2010-09-10 Fixed bug#[5913](http://bugs.otrs.org/show_bug.cgi?id=5913) - Time field of adminlog has to be bigger.
 - 2010-09-09 Fixed bug#[5916](http://bugs.otrs.org/show_bug.cgi?id=5916) - Used search fields are not removed from the
    available search fields list.
 - 2010-09-09 Fixed bug#[5866](http://bugs.otrs.org/show_bug.cgi?id=5866) - AutoLoginCreation does not work.
 - 2010-09-09 Fixed bug#[5674](http://bugs.otrs.org/show_bug.cgi?id=5674) - Attachment name and size are not displayed in
    attachment column in ticket zoom article table.
 - 2010-09-09 Fixed bug#[5902](http://bugs.otrs.org/show_bug.cgi?id=5902) - Long text overflow in infobox is not cut or wrapped.
 - 2010-09-09 Fixed bug#[5900](http://bugs.otrs.org/show_bug.cgi?id=5900) - ~otrs/bin/otrs.DeleteCache.pl should also delete the
    minified JS cache.
 - 2010-09-08 Fixed bug#[5665](http://bugs.otrs.org/show_bug.cgi?id=5665) - In Admin-Customer Management, required fields are not shown but
    validation is working.
 - 2010-09-08 Fixed bug#[5881](http://bugs.otrs.org/show_bug.cgi?id=5881) - ArticleDialog does not show last article description
    fully.
 - 2010-09-08 Fixed bug#[5846](http://bugs.otrs.org/show_bug.cgi?id=5846) - Missing error message if tickets pending time gets
    set to an invalid time.
 - 2010-09-08 Fixed bug#[5651](http://bugs.otrs.org/show_bug.cgi?id=5651) - Spellcheck can't be disabled.
 - 2010-09-08 Updated Danish translation file, thanks to Mads Nï¿½shauge Vestergaard!
 - 2010-09-08 Fixed bug#[5668](http://bugs.otrs.org/show_bug.cgi?id=5668) - Dashboard Widgets "Agents Online" shows pagination
   links even if no pagination is needed.
 - 2010-09-08 Fixed bug#[5882](http://bugs.otrs.org/show_bug.cgi?id=5882) - ArticleBox 'Direction' is not implemented.
 - 2010-09-03 Fixed bug#[5779](http://bugs.otrs.org/show_bug.cgi?id=5779) - Mandatory FreeTime fields are not validated.
 - 2010-09-03 Fixed bug#[5811](http://bugs.otrs.org/show_bug.cgi?id=5811) - Customer Interface account creation error handling
    does not work correctly.
 - 2010-09-07 Fixed bug#[5861](http://bugs.otrs.org/show_bug.cgi?id=5861) - Dashboard: CacheTTL for Stats breaks the generation of the chart.
 - 2010-09-07 Fixed bug#[5886](http://bugs.otrs.org/show_bug.cgi?id=5886) - Forwarding rich text tickets adds extra attachment.
 - 2010-09-07 Fixed bug#[5885](http://bugs.otrs.org/show_bug.cgi?id=5885) - Forwarding an article adds string to subject.
 - 2010-09-07 Fixed bug#[5024](http://bugs.otrs.org/show_bug.cgi?id=5024) - Adding a new ticket-priority results in a PriorityID-\<new ID\> tag
    from the layout engine in the generated HTML wo/ matching CSS class.
 - 2010-09-07 Fixed bug#[5884](http://bugs.otrs.org/show_bug.cgi?id=5884) - For CSV and Print (PDF) search results the search window does not auto close.
 - 2010-09-06 Fixed bug#[5887](http://bugs.otrs.org/show_bug.cgi?id=5887) - The size of the widget in the import statistic is too small for the input file.
 - 2010-09-06 Fixed bug#[5877](http://bugs.otrs.org/show_bug.cgi?id=5877) - No screen refresh when linking tickets.
 - 2010-09-06 Fixed bug#[4411](http://bugs.otrs.org/show_bug.cgi?id=4411) - CustomerTicket plain print (PDF=off) shows wrong URLs.
 - 2010-09-06 Fixed bug#[3521](http://bugs.otrs.org/show_bug.cgi?id=3521) - Error messages from password regex rules are
    truncated at comma which should't be there.
 - 2010-09-06 Fixed bug#[5875](http://bugs.otrs.org/show_bug.cgi?id=5875) - Customer ticket print view has too much information.
 - 2010-09-06 Fixed bug#[5867](http://bugs.otrs.org/show_bug.cgi?id=5867) - Navigation bar does not obey click path.
 - 2010-09-06 Fixed bug#[5871](http://bugs.otrs.org/show_bug.cgi?id=5871) - Ticket information in dashboard is not properly aligned.
 - 2010-09-06 Fixed bug#[5876](http://bugs.otrs.org/show_bug.cgi?id=5876) - Chinese UI issue.
 - 2010-09-03 Fixed bug#[5873](http://bugs.otrs.org/show_bug.cgi?id=5873) - Permissions fields are displaced in the EditSpecification of a Stat.
 - 2010-09-03 Fixed bug#[5812](http://bugs.otrs.org/show_bug.cgi?id=5812) - Customer Interface Password Sent dialog could be less confusing.
 - 2010-09-03 Fixed bug#[5870](http://bugs.otrs.org/show_bug.cgi?id=5870) - Login boxes in Customer Interface are too small.
 - 2010-09-03 Fixed bug#[5811](http://bugs.otrs.org/show_bug.cgi?id=5811) - Customer Interface account creation error handling
    does not work correctly.
 - 2010-09-03 Fixed bug#[5632](http://bugs.otrs.org/show_bug.cgi?id=5632) - New Ticket Search Dialog takes about 3 Seconds to load, 3 seconds
    with no feedback. User Experience need to get improved. Faster load of the dialog.
 - 2010-09-03 Fixed bug#[5789](http://bugs.otrs.org/show_bug.cgi?id=5789) - Use of uninitialized value $\_ in Kernel/System/CustomerUser/LDAP.pm.
 - 2010-09-03 Fixed bug#[5691](http://bugs.otrs.org/show_bug.cgi?id=5691) - Not possbible for a package to modify a file
    that belongs to another package.
 - 2010-09-02 Fixed bug#[5860](http://bugs.otrs.org/show_bug.cgi?id=5860) - Tooltips are not displayed correct in Customer
    interface.
 - 2010-09-02 Fixed bug#[5811](http://bugs.otrs.org/show_bug.cgi?id=5811) - Customer Interface account creation error
    handling does not work correctly.
 - 2010-09-02 Fixed bug#[5818](http://bugs.otrs.org/show_bug.cgi?id=5818) - Standard height of the article list.
 - 2010-09-02 Fixed bug#[5693](http://bugs.otrs.org/show_bug.cgi?id=5693) - Error messages appearing during mysql tables
    migration.
 - 2010-09-02 Fixed bug#[5802](http://bugs.otrs.org/show_bug.cgi?id=5802) - OTRS 3.0.0 beta 2 doesn't install default packages
    on login.
 - 2010-09-02 Fixed bug#[5780](http://bugs.otrs.org/show_bug.cgi?id=5780) - Have to resize window when replying on ticket.
 - 2010-09-02 Fixed bug#[5638](http://bugs.otrs.org/show_bug.cgi?id=5638) - Strange labels/buttons in TicketSearch "Create New  Delete".
 - 2010-09-02 Fixed bug#[5629](http://bugs.otrs.org/show_bug.cgi?id=5629) - Search Dialog of new Ticket Search Feature is not working with IE7.
 - 2010-09-02 Fixed bug#[5582](http://bugs.otrs.org/show_bug.cgi?id=5582) - Ticket::Frontend::MergeText and special character.
 - 2010-09-01 Fixed bug#[5851](http://bugs.otrs.org/show_bug.cgi?id=5851) - 3 AJAX refresh indicators are shown at the top of the AgentTicketPhone page.
 - 2010-09-01 Fixed bug#[5835](http://bugs.otrs.org/show_bug.cgi?id=5835) - Client side validation without JavaScript broken in
    customer interface.
 - 2010-09-01 Fixed bug#[5816](http://bugs.otrs.org/show_bug.cgi?id=5816) - SysConfig HighlightAge, wrong limits and handling.
 - 2010-09-01 Fixed bug#[5747](http://bugs.otrs.org/show_bug.cgi?id=5747) - Too much whitespace in popups.
 - 2010-09-01 Fixed bug#[5801](http://bugs.otrs.org/show_bug.cgi?id=5801) - Article action "Bounce article" gives error message.
 - 2010-09-01 Fixed bug#[5813](http://bugs.otrs.org/show_bug.cgi?id=5813) - Attachments of Tickets could not be loaded,
    caused by an (for IIS) invalid URL.
 - 2010-09-01 Fixed bug#[4423](http://bugs.otrs.org/show_bug.cgi?id=4423) - Hard coded CSS-Path in DTL templates.
 - 2010-09-01 Fixed bug#[5844](http://bugs.otrs.org/show_bug.cgi?id=5844) - Missing AJAX refresh indicator in the selection lists.
 - 2010-08-31 Fixed bug#[5729](http://bugs.otrs.org/show_bug.cgi?id=5729) - In Database creation or delete from Installer.pl the green colored word
    "Done" higher that the rest of the line.
 - 2010-08-31 Fixed bug#[5751](http://bugs.otrs.org/show_bug.cgi?id=5751) - TicketZoom Scroller Height is incorrectly calculated in Opera 10.61 Browser.
 - 2010-08-31 Fixed bug#[5809](http://bugs.otrs.org/show_bug.cgi?id=5809) - SLA should be Service Level Agreement.
 - 2010-08-31 Fixed bug#[2671](http://bugs.otrs.org/show_bug.cgi?id=2671) - Postmaster filter creation does not require a name.
 - 2010-08-31 Fixed bug#[5838](http://bugs.otrs.org/show_bug.cgi?id=5838) - Dialogs are not shown correctly in IE7.
 - 2010-08-31 Fixed bug#[5837](http://bugs.otrs.org/show_bug.cgi?id=5837) - Tooltips have transparent background in IE7.
 - 2010-08-31 Fixed bug#[5714](http://bugs.otrs.org/show_bug.cgi?id=5714) - Selecting a customer in AgentTicketEmail/Phone
    changes "Priority" and "Next ticket state" selections.
 - 2010-08-31 Fixed bug#[5791](http://bugs.otrs.org/show_bug.cgi?id=5791) - When creating a new ticket,
    changing the queue will change the priority and state.
 - 2010-08-30 Fixed bug#[5794](http://bugs.otrs.org/show_bug.cgi?id=5794) - Error when using Customer link when creating new ticket.
 - 2010-08-30 Fixed bug#[5807](http://bugs.otrs.org/show_bug.cgi?id=5807) - New mail account default state is "Invalid".
 - 2010-08-30 Fixed bug#[5824](http://bugs.otrs.org/show_bug.cgi?id=5824) - "Cancel & close window" link do nothing on Bulk operation at Tickets Status.
 - 2010-08-30 Fixed bug#[5829](http://bugs.otrs.org/show_bug.cgi?id=5829) - The body of the most recent article is not shown in the CustomerTicketZoom.
 - 2010-08-30 Fixed bug#[5800](http://bugs.otrs.org/show_bug.cgi?id=5800) - Ticket response drop down.
 - 2010-08-30 Fixed bug#[5765](http://bugs.otrs.org/show_bug.cgi?id=5765) - reply buttons in queue view produce perl error.
 - 2010-08-30 Updated Chinese translation file, thanks to Never Min!
 - 2010-08-30 Fixed bug#[5743](http://bugs.otrs.org/show_bug.cgi?id=5743) - Popup blocker should be detected.
 - 2010-08-30 Fixed bug#[5786](http://bugs.otrs.org/show_bug.cgi?id=5786) - -Reply- dropdown menu not reverting to initial state then closing reply
    window.
 - 2010-08-27 Fixed bug#[5833](http://bugs.otrs.org/show_bug.cgi?id=5833) - The text "Attachment" is above the paper-clip icon in the CustomerTicketZoom.
 - 2010-08-27 Fixed bug#[5831](http://bugs.otrs.org/show_bug.cgi?id=5831) - English language typo: "doesn't exists" should
    be "doesn't exist".
 - 2010-08-27 Updated Polish translation file, thanks to Janek Rumianek!
 - 2010-08-25 Fixed bug#[5805](http://bugs.otrs.org/show_bug.cgi?id=5805) - Customer interface: creation of a new ticket
    requires two clicks on the submit button.
 - 2010-08-26 Fixed bug#[5819](http://bugs.otrs.org/show_bug.cgi?id=5819) - Queue-View on size "S" is missing  the link to size "L".
 - 2010-08-26 Fixed bug#[5821](http://bugs.otrs.org/show_bug.cgi?id=5821) - SysConfig CSSLoader description is displayed incorrectly.
 - 2010-08-25 Fixed bug#[5795](http://bugs.otrs.org/show_bug.cgi?id=5795) - Some .pl files in bin directory fails to load
    modules from  Kernel/cpan-lib.
 - 2010-08-25 Fixed bug#[5817](http://bugs.otrs.org/show_bug.cgi?id=5817) Button to adjust the article-list-size contains a link on IE 8.0.
 - 2010-08-25 Fixed bug#[5805](http://bugs.otrs.org/show_bug.cgi?id=5805) - Customer interface: creation of a new ticket
    requires two clicks on the submit button.
 - 2010-08-25 Fixed bug#[5820](http://bugs.otrs.org/show_bug.cgi?id=5820) - Ticket owner get no email reminder reached
    notification if ticket is unlocked and owner is not subscribed to queue.
 - 2010-08-25 Fixed bug#[5815](http://bugs.otrs.org/show_bug.cgi?id=5815) - Customer interface field validation takes place before submitting.
 - 2010-08-25 Fixed bug#[5808](http://bugs.otrs.org/show_bug.cgi?id=5808) - Generic Agent does not display job info.
 - 2010-08-24 Applied change suggested in bug#[5733](http://bugs.otrs.org/show_bug.cgi?id=5733). $Text should be dereferenced while counting its length.
 - 2010-08-24 Fixed bug#[5806](http://bugs.otrs.org/show_bug.cgi?id=5806) - Default services aren't checked in AdminCustomerUserService.
 - 2010-08-24 Fixed bug#[5803](http://bugs.otrs.org/show_bug.cgi?id=5803) - TimeInputFormat "Input" generates CSS errors.

# 3.0.0 beta2 2010-08-23
 - 2010-08-21 Fixed bug#[5697](http://bugs.otrs.org/show_bug.cgi?id=5697) - IMAP Connector Failing in IMAP mode, IMAPS is working.
 - 2010-08-21 Fixed bug#[5766](http://bugs.otrs.org/show_bug.cgi?id=5766) - Complex LinkObject Table is broken when more
    than one kind of object is linked.
 - 2010-08-20 Fixed bug#[5784](http://bugs.otrs.org/show_bug.cgi?id=5784) - Core.AJAX.js fails if if called without callback
    parameter and also exception handler breaks.
 - 2010-08-20 Fixed bug#[5783](http://bugs.otrs.org/show_bug.cgi?id=5783) - Warning: Ticket locked! message when replying to
    unlocked ticket.
 - 2010-08-20 Updated database diagram to reflect changes in OTRS 3.
 - 2010-08-19 Fixed bug#[5768](http://bugs.otrs.org/show_bug.cgi?id=5768) - No tickets shown at customer interface if no open
    tickets exist.
 - 2010-08-19 Fixed bug#[5639](http://bugs.otrs.org/show_bug.cgi?id=5639) - Global Overview: No action when clicking a row in
    S/M/L view mode.
 - 2010-08-19 Fixed bug#[5728](http://bugs.otrs.org/show_bug.cgi?id=5728) - Ticket history shows wrong date and time for agent
    actions "createtime" (actually shows user creation date).
 - 2010-08-19 Fixed bug#[5727](http://bugs.otrs.org/show_bug.cgi?id=5727) - Ticket search results are not sortable.
 - 2010-08-19 Fixed bug#[5611](http://bugs.otrs.org/show_bug.cgi?id=5611) - Company Button has the same function as Tickets Button.
 - 2010-08-19 Fixed bug#[5760](http://bugs.otrs.org/show_bug.cgi?id=5760) - Adding a new ticket in the customer interface
    can result in 2 tickets.
 - 2010-08-19 Fixed bug#[5722](http://bugs.otrs.org/show_bug.cgi?id=5722) - Customer interface does not display error messages
    when creating a ticket.
 - 2010-08-18 Fixed bug#[5662](http://bugs.otrs.org/show_bug.cgi?id=5662) - In Global Ticket Overview, in L-Mode, template
    support is missing in "Reply" feature.
 - 2010-08-18 Fixed bug#[5764](http://bugs.otrs.org/show_bug.cgi?id=5764) - No move option in S/M/L mode available.
 - 2010-08-18 Fixed bug#[5725](http://bugs.otrs.org/show_bug.cgi?id=5725) - Missing labels for search-terms in customer interface.
 - 2010-08-17 Fixed bug#[5598](http://bugs.otrs.org/show_bug.cgi?id=5598) - Address Book To: field does is not populated.
 - 2010-08-17 Fixed bug#[5679](http://bugs.otrs.org/show_bug.cgi?id=5679) - In "New Ticket" in customer interface,
    selecting the queue automatically submits the ticket.
 - 2010-08-17 Fixed bug#[5724](http://bugs.otrs.org/show_bug.cgi?id=5724) - Security leak: Edit HTML source code as customer.
 - 2010-08-17 Fixed bug#[5682](http://bugs.otrs.org/show_bug.cgi?id=5682) - Collapse / expand for GenericAgent.
 - 2010-08-17 Fixed bug#[5370](http://bugs.otrs.org/show_bug.cgi?id=5370) - The word "subscribe" should be changed to "watch".
 - 2010-08-17 Fixed bug#[5742](http://bugs.otrs.org/show_bug.cgi?id=5742) - Outgoing email link detection does not work properly.
 - 2010-08-13 Fixed bug#[5660](http://bugs.otrs.org/show_bug.cgi?id=5660) - In Global Ticket Overview, with IE7: S/M/L, character
    is not clickable, only hover area is clickable, fixed changing images for S/M/L letters.
 - 2010-08-12 Fixed bug#[5648](http://bugs.otrs.org/show_bug.cgi?id=5648) - Submitting a note does not work as expected in all scenarios.
 - 2010-08-12 Fixed bug#[5654](http://bugs.otrs.org/show_bug.cgi?id=5654) - Missing shortcut icon (product.ico).
 - 2010-08-12 Fixed bug#[5643](http://bugs.otrs.org/show_bug.cgi?id=5643) - Articles are sorted alphabetically in TicketZoom.
 - 2010-08-12 Fixed bug#[5613](http://bugs.otrs.org/show_bug.cgi?id=5613) - WYSIWYG Editor not in center position.
 - 2010-08-12 Fixed bug#[5612](http://bugs.otrs.org/show_bug.cgi?id=5612) - Change free text fields not working correct in Firefox.
 - 2010-08-11 Fixed bug#[5652](http://bugs.otrs.org/show_bug.cgi?id=5652) - Can't select Service and SLA when creating new
     tickets.
 - 2010-08-11 Fixed bug#[5669](http://bugs.otrs.org/show_bug.cgi?id=5669) - The customer panel login shows "Request new password"
     on FF 3.5.
 - 2010-08-11 Fixed bug#[5689](http://bugs.otrs.org/show_bug.cgi?id=5689) - The body of the response message is incomplete.
 - 2010-08-11 Fixed bug#[5650](http://bugs.otrs.org/show_bug.cgi?id=5650) - Height of the article list is not retained.
 - 2010-08-11 Fixed bug#[5684](http://bugs.otrs.org/show_bug.cgi?id=5684) - Drag&Drop in agent dashboard is not working
    with IE7.
 - 2010-08-10 Fixed bug#[5579](http://bugs.otrs.org/show_bug.cgi?id=5579) - Spaces in filenames are converted to + characters
    when downloading in IE.
 - 2010-08-10 Fixed bug#[5701](http://bugs.otrs.org/show_bug.cgi?id=5701) - Tarball includes empty directories.
 - 2010-08-10 Fixed bug#[5255](http://bugs.otrs.org/show_bug.cgi?id=5255) - Accessibility: "ALL" link when selecting an owner
 - 2010-08-10 Fixed bug#[5694](http://bugs.otrs.org/show_bug.cgi?id=5694) - Images in web based installer are not displayed
    when performing installation from source.
 - 2010-08-09 Fixed bug#[5661](http://bugs.otrs.org/show_bug.cgi?id=5661) - In Global Ticket Overview, with IE7 and L-Mode,
    Hover of first Ticket overlaps Action Row Area.
 - 2010-08-09 Fixed bug#[5633](http://bugs.otrs.org/show_bug.cgi?id=5633) - Customer user information is not shown in
    ticket zoom if it was set by AgentTicketCustomer.
 - 2010-08-06 Fixed bug#[5676](http://bugs.otrs.org/show_bug.cgi?id=5676) - Ticket Free Time selection in customer panel is
    broken, because wrong "for" statement inside Label.
 - 2010-08-06 Fixed bug#[5691](http://bugs.otrs.org/show_bug.cgi?id=5691) - Not possbible for a package to modify a file
    that belongs to another package.
 - 2010-08-06 Fixed bug#[5690](http://bugs.otrs.org/show_bug.cgi?id=5690) - In AgentTicketZoom, "reset filter" is not
    taken over for next login.
 - 2010-08-06 Fixed bug#[5659](http://bugs.otrs.org/show_bug.cgi?id=5659) - In Global Ticket Overview, Small View,
    "FROM/SUBJECT" is problematically to read. now it reads "FROM / SUBJECT".
 - 2010-08-06 Fixed bug#[5628](http://bugs.otrs.org/show_bug.cgi?id=5628) - In new Ticket Search, the attribute
    TicketCreateTime, wording is wrong + Checkbox is not longer needed.
 - 2010-08-06 Fixed bug#[5645](http://bugs.otrs.org/show_bug.cgi?id=5645) - Changing the ticket search options does not
    work.
 - 2010-08-06 Fixed bug#[5627](http://bugs.otrs.org/show_bug.cgi?id=5627) - "Fulltext" attribute in new ticket search
    feature is missing for initial use.
 - 2010-08-06 Fixed bug#[5663](http://bugs.otrs.org/show_bug.cgi?id=5663) - In Global Ticket Overview, in M+L Mode, orange
    hyper links are not shown on hover a record.
 - 2010-08-05 Fixed bug#[5670](http://bugs.otrs.org/show_bug.cgi?id=5670) - In Agent Interface, e. g. note action, you can
    select a file, which is uploaded automatically. This is not working in
    customer panel.
 - 2010-08-05 Fixed bug#[5625](http://bugs.otrs.org/show_bug.cgi?id=5625) - Article Zoom Screen -\> New Message Indicator
    is not removed after clicking on an article item.
 - 2010-08-05 Fixed bug#[5671](http://bugs.otrs.org/show_bug.cgi?id=5671) - In Customer Panel, there are not used links in
    footer (FAQ, Help, ...).
 - 2010-08-05 Fixed bug#[5635](http://bugs.otrs.org/show_bug.cgi?id=5635) - It's not possible to open Ticket Search feature
    in own browser tab.
 - 2010-08-02 Fixed bug#[2774](http://bugs.otrs.org/show_bug.cgi?id=2774) - Added sha1 and sha2 for additional auth method.
    Now otrs is able to crypt passwords using sha-1 and sha-256 for users and
    customer using DB backend.

# 3.0.0 beta1 2010-08-02
 - 2010-07-30 Fixed bug#[5361](http://bugs.otrs.org/show_bug.cgi?id=5361) - Wrong link detection, because regexp looking for url
   like "www.exam.com" and needed "xwww.exam.com", added unit test.
 - 2010-07-28 Added new sysconfig validation module layer to verify and auto-correct
    some sysconfig settings.
 - 2010-07-21 Fixed bug#[5566](http://bugs.otrs.org/show_bug.cgi?id=5566) - StateDefault, PriorityDefault and ArticleTypeDefault
    not working in AgentTicketNote and other frontend modules.
 - 2010-07-20 Fixed bug#[4483](http://bugs.otrs.org/show_bug.cgi?id=4483) - AgentTicketActionCommon, set radio button when select
    old/ new owner are selected.
 - 2010-07-19 Fixed bug#[5563](http://bugs.otrs.org/show_bug.cgi?id=5563) - Static statistic file StateAction is overwritten
    by an older version.
 - 2010-07-16 Removed support for the deprecated DTL commands \<dtl if\>, \<dtl set\>
    and \<dtl system-call\>. They were deprecated since OTRS 2.2.
 - 2010-07-15 Fixed bug#[5416](http://bugs.otrs.org/show_bug.cgi?id=5416) - AgentTicketMove does not support Pending Date.
 - 2010-07-15 Fixed bug#[5556](http://bugs.otrs.org/show_bug.cgi?id=5556) - Broken unicode chars in CustomerUser selections.
 - 2010-07-14 Fixed bug#[5132](http://bugs.otrs.org/show_bug.cgi?id=5132) - New owner validation always ask to set a owner.
 - 2010-07-14 Fixed bug#[5343](http://bugs.otrs.org/show_bug.cgi?id=5343) - Widespread typo in Agent-/CustomerPreferences - replaced "Activ"
                for "Active".
 - 2010-07-13 Fixed bug#[5550](http://bugs.otrs.org/show_bug.cgi?id=5550) - Broken linebreaks in textareas of Google Chrome.
 - 2010-07-09 Fixed bug#[5545](http://bugs.otrs.org/show_bug.cgi?id=5545) - LIKE pattern must not end with escape character.
 - 2010-07-09 Fixed bug#[5494](http://bugs.otrs.org/show_bug.cgi?id=5494) - Handle attachments with java script.
 - 2010-07-09 Fixed bug#[5544](http://bugs.otrs.org/show_bug.cgi?id=5544) - Wrong handling of underscore in LIKE
    search with oracle.
 - 2010-07-06 Removed AgentLookup (was not used in OTRS framework itself
     and is not state of the art of dealing with dynamic data any more).
 - 2010-07-01 Streamlined messages in AgentTicketBulk.
 - 2010-07-01 Added option to ticket bulk action to define if tickets for bulk
    action need to get locked for current agent or not.
     * Config Name: Ticket::Frontend::AgentTicketBulk###RequiredLock
    Thanks to Jeroen van Meeuwen!
 - 2010-06-22 Improved otrs.CheckModules.pl script.
 - 2010-06-22 Updated CPAN module Authen::SASL to version 2.15.
 - 2010-06-22 Updated CPAN module Net::IMAP::Simple to version 1.1916.
 - 2010-06-22 Updated CPAN module MIME::Tools to version 5.428.
 - 2010-06-22 Updated CPAN module Net::POP3::SSLWrapper to version 0.04.
 - 2010-06-22 Updated CPAN module XML::Parser to version 0.712.
 - 2010-06-22 Updated CPAN module Text::CSV to version 1.18.
 - 2010-06-18 Updated CPAN module JSON::PP to version 2.21
 - 2010-06-14 New DirectoryRead Function to read filenames with Unicode::Normalize
 - 2010-06-09 Fixed bug#[5447](http://bugs.otrs.org/show_bug.cgi?id=5447) - Added SMTP TLS support, to send out emails via
    mail servers (MS Exchange!) that require this.
 - 2010-06-02 Fixed bug#[5426](http://bugs.otrs.org/show_bug.cgi?id=5426) - Can't set timezone for customer users.
 - 2010-05-28 Fixed bug#[5262](http://bugs.otrs.org/show_bug.cgi?id=5262) - Sort by "pending time" includes ticket with no
    pending state.
 - 2010-05-28 Added option to use TicketPendingTimeSet() to null out the
    Pending Time, similar to the implementation for TicketFreeTimeSet().
 - 2010-05-21 Fixed bug#[4459](http://bugs.otrs.org/show_bug.cgi?id=4459) - Two related error messages in S/MIME if you
    call it and it's disabled, and one message is enough.
 - 2010-05-21 Fixed bug#[5377](http://bugs.otrs.org/show_bug.cgi?id=5377) - Show all users in AdminUser as a default.
 - 2010-05-20 Fixed bug#[1846](http://bugs.otrs.org/show_bug.cgi?id=1846) - AdminCustomerUserGroup shows all CustomerUsers,
    even if you have thousands of them.
 - 2010-05-20 Fixed bug#[5103](http://bugs.otrs.org/show_bug.cgi?id=5103) - Searching for non-existing company does not
    return "no results found".
 - 2010-05-20 Implemented bug#[1701](http://bugs.otrs.org/show_bug.cgi?id=1701) - In customer's ticket overview, subject
    should come from the first article.
 - 2010-05-20 Fixed bug#[5186](http://bugs.otrs.org/show_bug.cgi?id=5186) - Prepend fwd: instead of re: to the subject of
    forwarded mails.
 - 2010-05-19 Added Groups and Roles support to Event Based Notifications.
    You can now also send a notification to agens in a certain group or role.
 - 2010-05-19 Implemented bug#[4337](http://bugs.otrs.org/show_bug.cgi?id=4337) - Added lock state to ticket search.
 - 2010-05-19 Reworked Kernel::System::Ticket API to have more intuitive
    wording (is still compat. to OTRS 1.x and 2.x).
    CustomerPermission()  -\> TicketCustomerPermission()
    InvolvedAgents()      -\> TicketInvolvedAgentsList()
    LockIsTicketLocked()  -\> TicketLockGet()
    LockSet()             -\> TicketLockSet()
    MoveList()            -\> TicketMoveList()
    MoveTicket()          -\> TicketQueueSet()
    MoveQueueList()       -\> TicketMoveQueueList()
    OwnerList()           -\> TicketOwnerList()
    OwnerSet()            -\> TicketOwnerSet()
    Permission()          -\> TicketPermission()
    PriorityList()        -\> TicketPriorityList()
    PrioritySet()         -\> TicketPrioritySet()
    ResponsibleList()     -\> TicketResponsibleList()
    ResponsibleSet()      -\> TicketResponsibleSet()
    SetCustomerData()     -\> TicketCustomerSet()
    StateList()           -\> TicketStateList()
    StateSet()            -\> TicketStateSet()
 - 2010-05-14 Fixed bug#[4199](http://bugs.otrs.org/show_bug.cgi?id=4199) - Hard limit of 200 services defined in front-end files.
 - 2010-05-12 Renamed core module 'Kernel/System/StdResponse.pm' to 'Kernel/System/StandardResponse.pm'.
 - 2010-05-12 Fixed bug#[4940](http://bugs.otrs.org/show_bug.cgi?id=4940) - SQL Improvement, deleted not needed GROUP BY statement.
 - 2010-05-07 Fixed bug#[5005](http://bugs.otrs.org/show_bug.cgi?id=5005) - 'Statuses' is not correct in British English.
 - 2010-05-06 Implemented bug#[3516](http://bugs.otrs.org/show_bug.cgi?id=3516) - added CustomerGroupSupport feature for
    customer navigation bar. Kudos Martin Balzarek.
 - 2010-05-04 Fixed bug#[5249](http://bugs.otrs.org/show_bug.cgi?id=5249) - ArticleStorageFS should not die on failed rm.
    Kudos Dominik Schulz.
 - 2010-04-30 Make it possible to use a version argument with bin/otrs.PackageManager.pl.
 - 2010-04-19 Improved bin/otrs.CreateTranslationFile.pl to get also
    translatable strings from sys config settings for translation catalog.
 - 2010-04-09 Added the feature to save searches in the Customer Frontend
 - 2010-04-08 Implemented fix for bug#[2673](http://bugs.otrs.org/show_bug.cgi?id=2673) -  Ticket subject lines in customer
    frontend can be confusing.
 - 2010-04-07 Fixed bug#[5118](http://bugs.otrs.org/show_bug.cgi?id=5118) - Printing an article should indicate that
    only 1 article is printed not the whole ticket.
 - 2010-04-06 made command line scripts consistent. They now all
     have the format `otrs.DoThis.pl`. Also, SetPermissions.sh is removed
     because we already have otrs.SetPermissions.pl.
    otrs.mkStats.pl                 -\>  otrs.GenerateStats.pl
    otrs.addGroup.pl                -\>  otrs.AddGroup.pl
    otrs.addQueue.pl                -\>  otrs.AddQueue.pl
    otrs.addRole.pl                 -\>  otrs.AddRole.pl
    otrs.addRole2Group.pl           -\>  otrs.AddRole2Group.pl
    otrs.addUser.pl                 -\>  otrs.AddUser.pl
    otrs.addUser2Group.pl           -\>  otrs.AddUser2Group.pl
    otrs.addUser2Role.pl            -\>  otrs.AddUser2Role.pl
    otrs.checkModules.pl            -\>  otrs.CheckModules.pl
    otrs.CreateNewTranslationFile.pl-\>  otrs.CreateTranslationFile.pl
    otrs.getConfig.pl               -\>  otrs.GetConfig.pl
    otrs.getTicketThread.pl         -\>  otrs.GetTicketThread.pl
    otrs.setPassword.pl             -\>  otrs.SetPassword.pl
    otrs.StatsExportToOPM.pl        -\>  otrs.ExportStatsToOPM.pl
    opm.pl                          -\>  otrs.PackageManager.pl
 - 2010-03-24 Reworked Kernel::System::Encode API to have more intuitive
    wording (is still compat. to OTRS 1.x and 2.x).
    EncodeInternalUsed() -\> CharsetInternal()
    Encode()             -\> EncodeInput()
    Decode()             -\> Convert2CharsetInternal()
 - 2010-03-24 Fixed bug#[5130](http://bugs.otrs.org/show_bug.cgi?id=5130) - Incorrect check for 'NoOutOfOffice' in
    GetUserData().
 - 2010-03-22 Fixed bug#[5161](http://bugs.otrs.org/show_bug.cgi?id=5161) - Envelope-To Header gets ignored for email
    dispatching.
 - 2010-03-18 Fixed bug#[5060](http://bugs.otrs.org/show_bug.cgi?id=5060) - Get email notification for tickets created by
    myself (new feature).
 - 2010-03-18 Updated CPAN module Text::CSV to version 1.17.
 - 2010-03-18 Updated CPAN module MailTools to version 2.06.
 - 2010-03-18 Updated CPAN module CGI to version 3.49.
 - 2010-03-18 Updated CPAN module Net::IMAP::Simple to version 1.1911.
 - 2010-03-11 Upgraded CKEditor from version 3.1 to version 3.2.
 - 2010-03-09 Fixed bug#[4996](http://bugs.otrs.org/show_bug.cgi?id=4996) - Rich Text Editor does not display in the Customer
    Frontend in IE8.
 - 2010-03-08 Fixed bug#[5085](http://bugs.otrs.org/show_bug.cgi?id=5085) - Wrong colours codes in Stats::Graph::dclrs.
 - 2010-03-08 Fixed bug#[5097](http://bugs.otrs.org/show_bug.cgi?id=5097) - AdminNotificationEvent does not display values
    on Change.
 - 2010-02-26 Fixed bug#[4874](http://bugs.otrs.org/show_bug.cgi?id=4874) - LDAP connection even if it is not needed.
    Moved to "Die =\> 0" as default value if no connection to customer ldap
    source was possible.
 - 2010-02-23 Fixed bug#[4957](http://bugs.otrs.org/show_bug.cgi?id=4957) - Password Change dialog misses "Current Password"
    option.
 - 2010-02-22 Fixed bug#[5020](http://bugs.otrs.org/show_bug.cgi?id=5020) - Framework version for stats export is outdated.
 - 2010-02-21 Extended QueryCondition() of Kernel::System::DB to allow
    also "some praise" expression as "some&&praise", to be compat. just add
`Extended => 1` to QueryCondition(). Short summary:
        some praise   -\> search for "some" and "praise" in a text (order of words
                         is not importand)
        "some praise" -\> search for "some praise" in a text as one string
 - 2010-02-16 Extended QueryCondition() of Kernel::System::DB to allow
    also "some praise" expression for search conditions to search this string
    1:1 in database.
 - 2010-02-15 Added "New Article" feature. Shows any agent in dashboard and
    global ticket overviews if there is a new article in a ticket which is not
    seen (like unread feature in email clients).
    Notice: Use scripts/DBUpdate-to-2.5.\*.sql for upgrading!
 - 2010-02-15 Removed example config files for Apache1, switched to only
    one config file for Apache2 instead of two.
 - 2010-02-15 Fixed bug#[4924](http://bugs.otrs.org/show_bug.cgi?id=4924) - Incorrect email address syntax check.
 - 2010-02-10 Fixed bug#[2376](http://bugs.otrs.org/show_bug.cgi?id=2376) - Customer preferences are lost after update
    of customer login.
 - 2010-02-10 Fixed bug#[4828](http://bugs.otrs.org/show_bug.cgi?id=4828) - In SysConfig, changed "Registration" to
    "Registrierung" in German description.
 - 2010-02-07 Fixed bug#[4918](http://bugs.otrs.org/show_bug.cgi?id=4918) - Delete only expired cache items by using
    e. g. `bin/otrs.CacheDelete.pl --expired`.
 - 2010-02-01 Added Kernel::System::Cache::FileStorable backend module for
    Kernel::System::Cache which is working with binary for dump and eval of
    perl data structures (a little bit faster the dump/eval in pure perl).
    Perl's Storable module is included in perl distibution it self.
 - 2010-01-26 IPC session backend (`Kernel::System::AuthSession::IPC`) is not
    longer supported. Increased performance of DB and FS backend (only sync
    session data to storage at end of a session).
 - 2010-01-25 Added agent preferences for max. shown tickets a page in
    ticket overviews.
 - 2010-01-19 Added security feature enhancement to block active elements
    and external images as auto load of html articles in zoom view (agent
    and customer interface).
 - 2010-01-15 Fixed bug#[4651](http://bugs.otrs.org/show_bug.cgi?id=4651) - Dashboard upcoming events does not look up
    statetypes for Pending Reminder.
 - 2010-01-14 Removed not needed tool `scripts/sync_node.sh`.
 - 2010-01-13 Added ticket fulltext search to dashboard.
 - 2010-01-06 Added dashboard widget for displaying external content via iframe.
 - 2009-12-31 Added cpan module for JSON support (version 2.16), removed JSON
    function from LayoutAJAX and changed all function calls to the new JSON
    wrapper.
 - 2009-12-24 Themes are now stored in SysConfig under Frontend::Themes rather
    than in the database. This to enable administrators to add a new theme by
    just modifying SysConfig instead of having to use mysql or isql or so.
 - 2009-12-23 Renamed inconsistent module name Kernel::System::Config to
    Kernel::System::SysConfig.
 - 2009-12-23 Added support for multiple Kernel::System::Ticket::Custom
    backends. Can now be defined via config key `Ticket::CustomModule`, e. g.

```xml
<ConfigItem Name="Ticket::CustomModule###001-CustomModule" Required="0" Valid="0">
   <Description Lang="en">A module with custom functions to redefine ....</Description>
   <Description Lang="de">Ein Modul mit angepassten Funktionen das ...</Description>
   <Group>Ticket</Group>
   <SubGroup>Core::Ticket</SubGroup>
   <Setting>
      <String Regex="">Kernel::System::Ticket::Custom</String>
   </Setting>
</ConfigItem>
```

 - 2009-12-21 Added the ability to hide the Queue, SLA and/or Service in
    the Customer interface.
 - 2009-12-15 Changed rich text editor from FCKEditor 2.6.4.1 to CKEditor 3.0.1
 - 2009-12-14 Fixed bug#[4660](http://bugs.otrs.org/show_bug.cgi?id=4660) - Admin Notification module does not send mail
    to customer users in groups.
 - 2009-12-14 Added the ability to use AdminEmail to send notifications based
    on roles.
 - 2009-12-14 Updated SysConfig to make sure OTRS toolbars and Admin section uses
    plural in interface where appropriate.
 - 2009-12-11 Replaced all OptionStrgHashRef() with the newer BuildSelection().
 - 2009-12-09 Added archive feature to improve performance.
 - 2009-12-09 Updated CPAN module Text::CSV to version 1.16.
 - 2009-12-08 Fixed bug#[4570](http://bugs.otrs.org/show_bug.cgi?id=4570) - Not processed attachment on incoming email
    (value too long for type).
    Increased varchar of article\_attachment.content\_type from 250 to 450.
 - 2009-12-08 Fixed bug#[1698](http://bugs.otrs.org/show_bug.cgi?id=1698) - Send emails with the real name from the agent.
 - 2009-12-08 Fixed bug#[2153](http://bugs.otrs.org/show_bug.cgi?id=2153) - Recognize domain names only if they are words.
 - 2009-12-08 Fixed bug#[4399](http://bugs.otrs.org/show_bug.cgi?id=4399) - Phone- / Email-Ticket AJAX reload does not
    consider ACL in Kernel/Config.pm.
 - 2009-12-08 Fixed bug#[4330](http://bugs.otrs.org/show_bug.cgi?id=4330) - Added new history-get results.
 - 2009-12-07 Fixed bug#[3887](http://bugs.otrs.org/show_bug.cgi?id=3887) - Processing headers with faulty charset definitions.
 - 2009-12-04 Removed OptionElement() from Layout.pm. Use BuildSelection()
    instead.
 - 2009-12-04 Changed line chart library again: from OFC to Flot.
 - 2009-12-02 Completely removed YUI from the OTRS code.
 - 2009-12-02 Switched line chart on the dashboard from YUI to OFC.
 - 2009-11-27 Updated CPAN module XML::Parser::Lite to version 0.710.10.
 - 2009-11-27 Updated CPAN module XML::TreePP to version 0.39.
 - 2009-11-27 Updated CPAN module XML::FeedPP to version 0.41.
 - 2009-11-27 Updated CPAN module Text::Diff to version 1.37.
 - 2009-11-27 Updated CPAN module Text::CSV to version 1.15.
 - 2009-11-27 Updated CPAN module Authen::SASL to version 2.13.
 - 2009-11-27 Changed directory structure for thirdparty javascript modules.
 - 2009-11-27 Switched AutoCompletion and Dialog from YUI to jQuery.
 - 2009-11-25 Switched to XHTML doctype
    - not all of the generated HTML is valid yet, but much
    - from now on, ";" will be used as a query parameter separator in URLs
        (old: index.pl?Action=AgentExample&Subaction=Test,
        new: index.pl?Action=AgentExample;Subaction=Test)
    - made some self-closing tags actually close themselves (e.g.`<img .../>`)
    - made some tags and attributes used lowercase
 - 2009-11-25 Updated CPAN module CGI to version 3.48.
 - 2009-11-23 Only database configuration is now saved in Config.pm.
 - 2009-11-18 Added database check and mail configuration steps
    to the web installer.
 - 2009-11-12 Fixed bug#[4509](http://bugs.otrs.org/show_bug.cgi?id=4509) - Notification (event based) comments are not
    saved.
 - 2009-11-11 Added feature/config option (Ticket::SubjectFormat) for subject
    format.
     - 'Left'  means '[TicketHook#:12345] Some Subject',
     - 'Right' means 'Some Subject [TicketHook#:12345]',
     - 'None'  means 'Some Subject' (without any ticket number ins subject).

    In the last case you should enable PostmasterFollowupSearchInRaw or
    PostmasterFollowUpSearchInReferences to recognize followups based on email
    headers and/or body.
    Wrote also unit tests to take care of functionality.
 - 2009-11-11 Moved from prototype js to jQuery
    (removed var/httpd/htdocs/js/prototype.js added
    var/httpd/htdocs/js/jquery-1.3.2.min.js).
 - 2009-11-03 Renamed some files in the bin/ directory

```
    CheckSum.pl                     -\>  otrs.CheckSum.pl
    CleanUp.pl                      -\>  otrs.CleanUp.pl
    Cron4Win32.pl                   -\>  otrs.Cron4Win32.pl
    CryptPassword.pl                -\>  otrs.CryptPassword.pl
    DeleteSessionIDs.pl             -\>  otrs.DeleteSessionIDs.pl
    GenericAgent.pl                 -\>  otrs.GenericAgent.pl
    mkStats.pl                      -\>  otrs.mkStats.pl
    otrs.addGroup                   -\>  otrs.addGroup.pl
    otrs.addQueue                   -\>  otrs.addQueue.pl
    otrs.addRole                    -\>  otrs.addRole.pl
    otrs.addRole2Group              -\>  otrs.addRole2Group.pl
    otrs.addUser                    -\>  otrs.addUser.pl
    otrs.addUser2Group              -\>  otrs.addUser2Group.pl
    otrs.addUser2Role               -\>  otrs.addUser2Role.pl
    otrs.checkModules               -\>  otrs.checkModules.pl
    otrs.CreateNewTranslationFile   -\>  otrs.CreateNewTranslationFile.pl
    otrs.getConfig                  -\>  otrs.getConfig.pl
    otrs.getTicketThread            -\>  otrs.getTicketThread.pl
    otrs.setPassword                -\>  otrs.setPassword.pl
    PendingJobs.pl                  -\>  otrs.PendingJobs.pl
    PostMaster.pl                   -\>  otrs.PostMaster.pl
    PostMasterClient.pl             -\>  otrs.PostMasterClient.pl
    PostMasterDaemon.pl             -\>  otrs.PostMasterDaemon.pl
    PostMasterMailbox.pl            -\>  otrs.PostMasterMailbox.pl
    PostMasterPOP3.pl               -\>  otrs.PostMasterPOP3.pl
    RebuildTicketIndex.pl           -\>  otrs.RebuildTicketIndex.pl
    SetPermissions.pl               -\>  otrs.SetPermissions.pl
    StatsExportToOPM.pl             -\>  otrs.StatsExportToOPM.pl
    UnitTest.pl                     -\>  otrs.UnitTest.pl
    UnlockTickets.pl                -\>  otrs.UnlockTickets.pl
    xml2sql.pl                      -\>  otrs.xml2sql.pl
    XMLMaster.pl                    -\>  otrs.XMLMaster.pl
```

 - 2009-10-26 Added CGI.pm back to packaged versions (auto\_build.sh).
 - 2009-10-14 Pending Date of tickets can be max. 1 year in the future.
 - 2009-10-14 Fixed bug#[1731](http://bugs.otrs.org/show_bug.cgi?id=1731) - Show last login time of agent and customer
    management.
 - 2009-10-12 TTL in Kernel::System::Cache::Set required but not checked.
 - 2009-10-12 Removed check on AttachmentDelete1 in function in
    AgentTicketMove.dtl.
 - 2009-10-12 AgentTicketOverviewPreview.dtl: superfluous hidden parameter
    'QueueID'.
 - 2009-10-07 Added global Search-Condition-Feature (AND/OR/()/!/+) for
    TicketNumber, From, To, Cc, Subject and Body also to generic agent.
 - 2009-10-05 Fixed bug#[939](http://bugs.otrs.org/show_bug.cgi?id=939) - "Salutation" should be renamed to "Title" for
    users and customer users.
    Notice: Use scripts/DBUpdate-to-2.5.\*.sql for upgrading!
 - 2009-10-02 Fixed bug#[4379](http://bugs.otrs.org/show_bug.cgi?id=4379) - Array parameters not working in mkStats.pl
 - 2009-09-23 Added virtual file system object for global file storage as
    Kernel::System::VirtualFS with FS and DB backends.
    Notice: Use scripts/DBUpdate-to-2.5.\*.sql for upgrading!
 - 2009-09-22 Fixed bug#[1774](http://bugs.otrs.org/show_bug.cgi?id=1774) - Updated documentation in AdminQueue.dtl.
 - 2009-09-22 Fixed bug#[4100](http://bugs.otrs.org/show_bug.cgi?id=4100) - ArticleFreeText Default Value not working.
 - 2009-09-22 Fixed bug#[1027](http://bugs.otrs.org/show_bug.cgi?id=1027) - Ticket csv export in customer interface incomplete.
 - 2009-09-21 Fixed bug#[4218](http://bugs.otrs.org/show_bug.cgi?id=4218) - No error message when sending mail through not
    installed sendmail.
 - 2009-09-21 Fixed bug#[4312](http://bugs.otrs.org/show_bug.cgi?id=4312) - MOTD module for Agent Dashboard, thanks to
    Alexander Scholler!
 - 2009-09-21 Fixed bug#[3978](http://bugs.otrs.org/show_bug.cgi?id=3978) - Better description for PGP passphrases.
 - 2009-09-16 Fixed bug#[3932](http://bugs.otrs.org/show_bug.cgi?id=3932) - Translation enhancements for AdminSession.dtl.
 - 2009-09-16 Fixed bug#[2786](http://bugs.otrs.org/show_bug.cgi?id=2786) - Wrong text labels
    AdminSystemAddressForm.dtl.
 - 2009-09-16 Fixed bug#[4288](http://bugs.otrs.org/show_bug.cgi?id=4288) - Use of uninitialized value in
    AdminGenericAgent.pm.
 - 2009-09-16 Moved to global event handler Kernel/System/EventHander.pm
    for ticket events (config is compatble with old one).
 - 2009-09-15 Improved performance of the PDF backend.

# 2.4.15 2012-10-16
 - 2012-09-13 Improved HTML security filter to better find javascript source URLs.

# 2.4.14 2012-08-30
 - 2012-08-28 Improved HTML security filter to detect tag nesting.

# 2.4.13 2012-08-21
 - 2012-08-17 HTML mails will now be displayed in an HTML5 sandbox iframe.
    This means that modern browsers will not execute plugins or JavaScript on the content
    any more. Currently, this is supported by Chrome and Safari, but IE10 and FF16 are also
 - 2012-08-17 HTML mails will now be displayed in the restricted zone in IE.
    This means that more restrictive security settings will apply, such as blocking of
    JavaScript content by default.
 - 2012-03-08 Fixed bug#[8300](http://bugs.otrs.org/show_bug.cgi?id=8300) - Database upgrade issue when upgrading from 2.3 > 2.4 > 3.0 > 3.1:
    table smime_signer_cert_relations' already exists.
 - 2012-03-05 Fixed bug#[7545](http://bugs.otrs.org/show_bug.cgi?id=7545) - AgentTicketBounce lacks permission checks.
 - 2012-02-23 Fixed bug#[8227](http://bugs.otrs.org/show_bug.cgi?id=8227) - LDAP user syncronisation doesn't work.
 - 2011-12-09 Fixed bug#[7997](http://bugs.otrs.org/show_bug.cgi?id=7997) - Fetching mail via AdminMailAccount does not work.
 - 2011-12-02 Fixed bug#[5086](http://bugs.otrs.org/show_bug.cgi?id=5086) - Emails with a long subject are not handled.
 - 2011-11-21 Use the secure attribute to restrict coookies to HTTPS if it is used.
 - 2011-11-21 Fixed bug#[7909](http://bugs.otrs.org/show_bug.cgi?id=7909) - Errors should be logged in web server error log only.
 - 2011-11-10 Fixed bug#[7879](http://bugs.otrs.org/show_bug.cgi?id=7879) - Ticket forward not working if content-id exists.
 - 2011-11-07 Fixed bug#[7362](http://bugs.otrs.org/show_bug.cgi?id=7362) - AuthSyncModule::LDAP::UserSyncMap with multiple auth backends.
 - 2011-11-02 Fixed bug#[7465](http://bugs.otrs.org/show_bug.cgi?id=7465) - Out-of-office unlock does not work upon customer's web reply.
 - 2011-10-21 Fixed bug#[7845](http://bugs.otrs.org/show_bug.cgi?id=7845) - No DispatchMultiple Method in rpc.pl script.

# 2.4.12 2011-10-18
 - 2011-09-22 Fixed bug#[7776](http://bugs.otrs.org/show_bug.cgi?id=7776) - Double encoding for AJAX responses on ActiveState perl.

# 2.4.11 2011-08-16
 - 2011-07-28 Fixed bug#[7518](http://bugs.otrs.org/show_bug.cgi?id=7518) - Escalation Notify by not working properly.
 - 2011-05-09 Fixed bug#[7010](http://bugs.otrs.org/show_bug.cgi?id=7010) - Latest version of PDF::API2 no longer includes DejaVu fonts.
    Fixed by including DejaVu fonts in var/fonts.
 - 2011-04-26 Fixed bug#[7250](http://bugs.otrs.org/show_bug.cgi?id=7250) - Add new queue mask crashes on PostgreSQL and MS SQL Server.
 - 2011-04-07 Fixed bug#[7195](http://bugs.otrs.org/show_bug.cgi?id=7195) - Graphs doesn't use GIF as fallback if PNG is not available.

# 2.4.10 2011-04-12
 - 2011-04-04 Fixed bug#[7140](http://bugs.otrs.org/show_bug.cgi?id=7140) - Attachments with percent symbol not working.
 - 2011-03-23 Updated Brazilian Portugese translation, thanks to Murilo Moreira de Oliveira!
 - 2011-03-18 Added required settings for oracle databases in apache2-httpd-new.include.conf.
 - 2011-03-07 Fixed bug#[6014](http://bugs.otrs.org/show_bug.cgi?id=6014) - Printed pdf tickets are not searchable.
 - 2011-02-17 Fixed bug#[6906](http://bugs.otrs.org/show_bug.cgi?id=6906) - Vendor URL points to Basename+URL instead of URL.
 - 2011-01-25 Event Based notification - respect "Include Attachments
    to Notification".
 - 2010-12-17 Fixed bug#[6510](http://bugs.otrs.org/show_bug.cgi?id=6510) - Signature ID missing.
 - 2010-12-14 Fixed bug#[6532](http://bugs.otrs.org/show_bug.cgi?id=6532) - With multiple inline images, only first one is
    preserved when replying.
 - 2010-12-13 Fixed bug#[6520](http://bugs.otrs.org/show_bug.cgi?id=6520) - backup.pl doesn't backup with strong password.
 - 2010-12-09 Fixed bug#[6488](http://bugs.otrs.org/show_bug.cgi?id=6488) - otrs.ArticleStorageSwitch.pl creating wrong files.
 - 2010-12-09 Fixed bug#[3984](http://bugs.otrs.org/show_bug.cgi?id=3984) - HTML Notifications - Links to ticketsystem are not clickable.
 - 2010-12-02 Fixed bug#[6366](http://bugs.otrs.org/show_bug.cgi?id=6366) - gnupg signatures not working correct for partly signed messages.
 - 2010-11-29 Fixed bug#[5981](http://bugs.otrs.org/show_bug.cgi?id=5981) - Warnings from TransfromDateSelection() in AgentTicketMove.
 - 2010-11-23 Fixed bug#[6131](http://bugs.otrs.org/show_bug.cgi?id=6131) - Lack of warning for revoked and expired PGP keys in email compose screens.
 - 2010-11-04 Fixed bug#[6211](http://bugs.otrs.org/show_bug.cgi?id=6211) - Wrong TicketFreeText-value in ticket creation by
    using event notifications.
 - 2010-11-02 Email.ticket: wrong signature is shown.
 - 2010-10-26 Improved German translation, thanks to Stelios Gikas!
 - 2010-10-13 Fixed some Perl "uninitialized value" warnings.
 - 2010-10-12 Fixed bug#[6087](http://bugs.otrs.org/show_bug.cgi?id=6087) - Search template name is broken if & or ; is used.

# 2.4.9 2010-10-25
 - 2010-09-30 Fixed bug#[6016](http://bugs.otrs.org/show_bug.cgi?id=6016) - AgentTicketZoom is vunerable to XSS attacks from HTML e-mails.
 - 2010-09-22 Fixed bug#[5903](http://bugs.otrs.org/show_bug.cgi?id=5903) - E-mail notification links don't contain \<a href... tags.
 - 2010-09-29 Fixed bug#[6030](http://bugs.otrs.org/show_bug.cgi?id=6030) - Event notifications are fired several times on
    event "TicketFreeTextUpdate".
 - 2010-09-14 Fixed bug#[5541](http://bugs.otrs.org/show_bug.cgi?id=5541) - Dashboard Chart generates error in webserver log.
 - 2010-09-09 Fixed bug#[5462](http://bugs.otrs.org/show_bug.cgi?id=5462) - Kernel::System::Ticket::TicketEscalationIndexBuild()
    does not invalidate the cache.
 - 2010-08-27 Fixed bug#[5667](http://bugs.otrs.org/show_bug.cgi?id=5667) - Rich Text is not working in ipad. It's not
    possible to add a note or close a ticket.
 - 2010-08-25 Fixed bug#[5266](http://bugs.otrs.org/show_bug.cgi?id=5266) - Ticket Zoom shows wrong html content if there
    is no text but two html attachments in there.

# 2.4.8 2010-09-15
 - 2010-08-24 Applied change suggested in bug#[5733](http://bugs.otrs.org/show_bug.cgi?id=5733). $Text should be dereferenced while counting its length.
 - 2010-08-18 Fixed bug#[5444](http://bugs.otrs.org/show_bug.cgi?id=5444) - TicketZoom mask vulnerable to XSS.
 - 2010-08-09 Fixed bug#[5698](http://bugs.otrs.org/show_bug.cgi?id=5698) - Ticket Assignment includes '(' character.
 - 2010-07-20 Fixed bug#[4483](http://bugs.otrs.org/show_bug.cgi?id=4483) - AgentTicketActions, set radio button when select
    old/ new owner are selected, fix wrong javascript behavior.
 - 2010-07-15 Fixed bug#[5416](http://bugs.otrs.org/show_bug.cgi?id=5416) - AgentTicketMove does not support Pending Date.
 - 2010-07-15 Fixed bug#[5556](http://bugs.otrs.org/show_bug.cgi?id=5556) - Broken unicode chars in CustomerUser selections.
 - 2010-07-14 Fixed bug#[5132](http://bugs.otrs.org/show_bug.cgi?id=5132) - New owner validation always ask to set a owner.
 - 2010-07-13 Fixed bug#[5210](http://bugs.otrs.org/show_bug.cgi?id=5210) - LinkQuote consumes all CPU memory when processing a
    large amount of data.
 - 2010-07-13 Fixed bug#[5550](http://bugs.otrs.org/show_bug.cgi?id=5550) - Broken linebreaks in textareas of Google Chrome.
 - 2010-07-07 Fixed bug#[5541](http://bugs.otrs.org/show_bug.cgi?id=5541) - Dashboard Chart generates error in webserver log.
 - 2010-07-01 Fixed bug#[5512](http://bugs.otrs.org/show_bug.cgi?id=5512) - Bulk Action No Access is displayed incorrectly.
 - 2010-06-25 Updated Danish translation, thanks to Jesper Rï¿½nnov,
    Faaborg-Midtfyn Kommune!
 - 2010-06-24 Fixed bug#[5445](http://bugs.otrs.org/show_bug.cgi?id=5445) - Reflected XSS vulnerability.
 - 2010-06-16 Fixed bug#[5488](http://bugs.otrs.org/show_bug.cgi?id=5488) - AutoPriorityIncrease runs into failures.
 - 2010-06-16 Fixed bug#[5478](http://bugs.otrs.org/show_bug.cgi?id=5478) - Web Installer has 'editable' license text.
 - 2010-05-31 Fixed bug#[5385](http://bugs.otrs.org/show_bug.cgi?id=5385) - Queue name is not used in signature on ticket
    creation.
 - 2010-05-28 Fixed bug#[5235](http://bugs.otrs.org/show_bug.cgi?id=5235) - Link in response not shown as link.
 - 2010-05-28 Added PNG version of data model in doc directory.
 - 2010-05-28 Fixed bug#[5395](http://bugs.otrs.org/show_bug.cgi?id=5395) - Function $LanguageObject-\>Time() can't process
    seconds.
 - 2010-05-07 Fixed bug#[5336](http://bugs.otrs.org/show_bug.cgi?id=5336) - Also set execute bit on scripts/tools.
 - 2010-04-30 Make it possible to use a version argument with bin/opm.pl.
 - 2010-04-21 Fixed bug#[5266](http://bugs.otrs.org/show_bug.cgi?id=5266) - Ticket Zoom shows wrong html content if there
    is no text but two html attachments in there.
 - 2010-04-15 Fixed bug#[5242](http://bugs.otrs.org/show_bug.cgi?id=5242) - Newlines are not displayed in html notification
    mails on Lotus Notes
 - 2010-04-14 Fixed bug#[4999](http://bugs.otrs.org/show_bug.cgi?id=4999) - Cache of customer user is not refreshed after
    a preference is updated.
 - 2010-04-13 Fixed bug#[5152](http://bugs.otrs.org/show_bug.cgi?id=5152) - responsible\_user\_id in ticket table is wrong in
    otrs-database.dia.
 - 2010-04-12 Fixed bug#[5108](http://bugs.otrs.org/show_bug.cgi?id=5108) - The RSS date was not displayed correctly.
 - 2010-04-12 Fixed bug#[5112](http://bugs.otrs.org/show_bug.cgi?id=5112) - Redirecting to a valid screen after unsubscribing a ticket
    that is on a queue in which the agent has no permissions.
 - 2010-04-06 Fixed bug#[4986](http://bugs.otrs.org/show_bug.cgi?id=4986) - There is no activate/deactivate check for Graphsize menu,
    when page loads in Stats Definition
 - 2010-04-01 Fixed bug#[4786](http://bugs.otrs.org/show_bug.cgi?id=4786) - AgentTicketCompose ONLY: Defining a next state,
    then adding and attachment, resets the next state upon screen refresh.
 - 2010-03-29 Improved handling of the StateType attribute of
    StateGetStatesByType() in Kernel/System/State.pm.
 - 2010-03-24 Fixed bug#[5164](http://bugs.otrs.org/show_bug.cgi?id=5164) - Pending time not working if agent as an other
    timezone.
 - 2010-03-19 Fixed bug#[5094](http://bugs.otrs.org/show_bug.cgi?id=5094) - Bulk pending date/time do not get applied to
    tickets.
 - 2010-03-18 Updated Ukrainian language translation, thanks to Belskii Artem!
 - 2010-03-10 Fixed bug#[4416](http://bugs.otrs.org/show_bug.cgi?id=4416) - Merge: whitespace before ticketnumber not removed.
 - 2010-03-09 Fixed bug#[5102](http://bugs.otrs.org/show_bug.cgi?id=5102) - Notification sent to OTRS instead of Customer.
 - 2010-03-08 Fixed bug#[5085](http://bugs.otrs.org/show_bug.cgi?id=5085) - Wrong colours codes in Stats::Graph::dclrs.
 - 2010-03-02 Updated Czech translation, thanks to O2BS.com, s r.o. Jakub Hanus!
 - 2010-02-26 Fixed bug#[4137](http://bugs.otrs.org/show_bug.cgi?id=4137) - Follow ups to internal forwarded message marked
    as customer reply.
 - 2010-02-23 Updated pt\_BR translation file, thanks to Fabricio Luiz Machado!
 - 2010-02-22 Fixed bug#[5020](http://bugs.otrs.org/show_bug.cgi?id=5020) - Framework version for stats export is outdated.
 - 2010-02-18 Fixed bug#[4969](http://bugs.otrs.org/show_bug.cgi?id=4969) - Event Based Notification: Body Match field displays
    Subject Match value.
 - 2010-02-16 Fixed bug#[4967](http://bugs.otrs.org/show_bug.cgi?id=4967) - Can't locate object method "new" via package
    error when using Perl 5.10.1.
 - 2010-02-15 Fixed bug#[4977](http://bugs.otrs.org/show_bug.cgi?id=4977) - mod\_perl is not used in fedora with RPM.
 - 2010-02-12 Fixed bug#[4936](http://bugs.otrs.org/show_bug.cgi?id=4936) - Kernel::System::Main::FileWrite has race condition.
 - 2010-02-11 Fixed bug#[4442](http://bugs.otrs.org/show_bug.cgi?id=4442) - Customer search fails when there is a space
    in the name.
 - 2010-02-11 Fixed bug#[4822](http://bugs.otrs.org/show_bug.cgi?id=4822) - No fulltext search with more than one word
    for FAQ.
 - 2010-02-10 Fixed bug#[4889](http://bugs.otrs.org/show_bug.cgi?id=4889) - Inline images from Lotus Notes are not
    displayed in ticket zoom.
 - 2010-02-09 Fixed bug#[4658](http://bugs.otrs.org/show_bug.cgi?id=4658) - Cannot delete attachment from AdminAttachment
    interface.

# 2.4.7 2010-02-08
 - 2010-02-03 Fixed bug#[4937](http://bugs.otrs.org/show_bug.cgi?id=4937) - Accounted time per article is not displayed
    in PDF print.
 - 2010-02-03 Fixed bug#[4848](http://bugs.otrs.org/show_bug.cgi?id=4848) - Issue with TicketOverView object - does not
    show all tickets when moving through list.
 - 2010-02-02 Fixed issue with migrating Customer Queue notifications to
    Event Based when upgrading OTRS 2.3 \> 2.4.
 - 2010-02-01 Fixed bug#[4393](http://bugs.otrs.org/show_bug.cgi?id=4393) - AgentTicketQueue - Small view takes long to
    load. -\> New solution with own config option for each view mode (S/M/L)
    Admin -\> SysConfig -\> Ticket -\> Frontend::Agent::TicketOverview.
 - 2010-01-25 Fixed bug#[4818](http://bugs.otrs.org/show_bug.cgi?id=4818) - Removed inline image of forwarded message gets
    still included.
 - 2010-01-20 Fixed bug#[4780](http://bugs.otrs.org/show_bug.cgi?id=4780) - Adding groups to a CustomerUser fails,
    adding CustomerUsers to a group works.
 - 2010-01-20 Fixed bug#[4486](http://bugs.otrs.org/show_bug.cgi?id=4486) - Some preferences displayed in AdminUser are not
    correct.
 - 2010-01-18 Fixed bug#[4770](http://bugs.otrs.org/show_bug.cgi?id=4770) - Attachments are stripped/not shown from
    outgoing emails in some scenarios with ms exchange.
 - 2010-01-15 Fixed bug#[4735](http://bugs.otrs.org/show_bug.cgi?id=4735) - TicketFreeTime search in Customer frontend
    does not work as expected
 - 2010-01-15 Fixed bug#[4758](http://bugs.otrs.org/show_bug.cgi?id=4758) - Dashboard RSS feeds doesn't display XML
    encoded entities correctly.
 - 2010-01-13 Fixed bug#[4754](http://bugs.otrs.org/show_bug.cgi?id=4754) - Multiple tickets with a huge POP3 Mailbox
    - more than 2000 email in the box ("Deep recursion on subroutine").
 - 2010-01-13 Fixed bug#[4713](http://bugs.otrs.org/show_bug.cgi?id=4713) - In ticket overview, after adding view=30 - no
    tickets are visible.
 - 2010-01-12 Upgrade of cpan Net::IMAP::Simple from 1.17 to 1.1910.

# 2.4.6 2010-01-12
 - 2010-01-11 Fixed bug#[4737](http://bugs.otrs.org/show_bug.cgi?id=4737) - Customer User update fails in 2.4.6 rc.
 - 2010-01-08 Fixed bug#[4730](http://bugs.otrs.org/show_bug.cgi?id=4730) - Unable to open Admin \> Attachments in IE8.
 - 2010-01-07 Fixed bug#[4731](http://bugs.otrs.org/show_bug.cgi?id=4731) - Service and SLA gets translated after AJAX
    reload in Phone an Email Ticket.
 - 2010-01-05 Fixed bug#[4718](http://bugs.otrs.org/show_bug.cgi?id=4718) - LDAP auth not possible with OTRS in iso-8859-1
    and utf-8 ldap directory.
 - 2010-01-05 Fixed bug#[4708](http://bugs.otrs.org/show_bug.cgi?id=4708) - Added ArticleID to output of
    bin/otrs.getTicketThread.
 - 2010-01-04 Fixed bug#[4704](http://bugs.otrs.org/show_bug.cgi?id=4704) - Package Manager: upload install fails with
    "Message: Need ContentType!" with Google Chrome browser.
 - 2009-12-30 Added Ukrainian language translation, thanks to Belskii Artem!
 - 2009-12-30 Fixed bug#[4727](http://bugs.otrs.org/show_bug.cgi?id=4727) - Added proper removal of FormID in
    AgentTicketPhoneOutbound.
 - 2009-12-23 Fixed bug#[3526](http://bugs.otrs.org/show_bug.cgi?id=3526) - Escalation emails are resent over and over again.
 - 2009-12-23 Fixed bug#[4428](http://bugs.otrs.org/show_bug.cgi?id=4428) - PGP-inline signed messages can't be encoded
    correctly with rich text editor.
 - 2009-12-22 Fixed bug#[4690](http://bugs.otrs.org/show_bug.cgi?id=4690) - AdminMailAccount - only 50 characters can be
    entered in username, password and host fields while database can store 200.
 - 2009-12-16 Fixed bug#[4503](http://bugs.otrs.org/show_bug.cgi?id=4503) - Border around image does not display well
    in some email clients.
 - 2009-12-13 Fixed bug#[4393](http://bugs.otrs.org/show_bug.cgi?id=4393) - AgentTicketQueue - Small view takes long to load.
 - 2009-12-09 Fixed crash in Ascii2Html() if no scalar reference is given.
 - 2009-12-09 Fixed bug#[4551](http://bugs.otrs.org/show_bug.cgi?id=4551) - GenericAgent appends leading zeros to dates
    if TimeInputFormat is "Input".
 - 2009-12-09 Fixed bug#[4584](http://bugs.otrs.org/show_bug.cgi?id=4584) - Auto response does not use selected from e-mail
    address.
 - 2009-12-09 Fixed bug#[4556](http://bugs.otrs.org/show_bug.cgi?id=4556) - Translation "Accounted Time" to german "Zugewiesene Zeit".
 - 2009-12-09 Fixed bug#[4184](http://bugs.otrs.org/show_bug.cgi?id=4184) - Can't call method "NotificationGet" on
    an undefined value.
 - 2009-12-09 Fixed bug#[4371](http://bugs.otrs.org/show_bug.cgi?id=4371) - DataSelected value for config option
    PreferencesGroups###WatcherNotify doesn't work.
 - 2009-12-09 Fixed bug#[4486](http://bugs.otrs.org/show_bug.cgi?id=4486) - Some preferences displayed in AdminUser are not correct.
 - 2009-12-09 Fixed bug#[4363](http://bugs.otrs.org/show_bug.cgi?id=4363) - Kernel/Output/HTML/Layout.pm -\> PageNavBar()
    mistakes because of missing checks and descriptions.
 - 2009-12-08 Fixed bug#[4361](http://bugs.otrs.org/show_bug.cgi?id=4361) - Umlauts in Dashboard are not displayed correcty
    after refresh on non-unicode databases.
 - 2009-12-08 Fixed bug#[4323](http://bugs.otrs.org/show_bug.cgi?id=4323) - Customer Interface shows last customer article
    instead of last article.
 - 2009-12-08 Fixed bug#[4435](http://bugs.otrs.org/show_bug.cgi?id=4435) - Inline attachments break in some scenarios like
    AgentTicketCompose and AgentTicketForward.
 - 2009-12-08 Fixed bug#[4384](http://bugs.otrs.org/show_bug.cgi?id=4384) - Customer User Info not deleted when From in
    AgentTicketPhone is changed.
 - 2009-12-08 Fixed bug#[4482](http://bugs.otrs.org/show_bug.cgi?id=4482) - Owner update possible with no new owner set.
 - 2009-12-07 Fixed bug#[4246](http://bugs.otrs.org/show_bug.cgi?id=4246) - Response Templates fail to populate for certain
    email tickets.
 - 2009-12-07 Fixed bug#[4381](http://bugs.otrs.org/show_bug.cgi?id=4381) - Function change\_selection in AgentTicketMove.
 - 2009-12-07 Fixed bug#[4400](http://bugs.otrs.org/show_bug.cgi?id=4400) - OTRS switches back to phone view when closing
    ticket after split.
 - 2009-12-07 Fixed bug#[4597](http://bugs.otrs.org/show_bug.cgi?id=4597) - Unnecessary slash in download links.
 - 2009-12-07 Fixed bug#[2768](http://bugs.otrs.org/show_bug.cgi?id=2768) - AttachmentsContent-Disposition header downloading
    a non-ASCII filename.
 - 2009-12-07 Fixed bug#[4282](http://bugs.otrs.org/show_bug.cgi?id=4282) - Fixed problems with CustomerInfo for Usernames
    with a '+'.
 - 2009-12-07 Fixed bug#[4477](http://bugs.otrs.org/show_bug.cgi?id=4477) - Uninitialized Value issue with Redirect()
    function in Layout.pm.
 - 2009-12-07 Fixed bug#[3907](http://bugs.otrs.org/show_bug.cgi?id=3907) - Caching function not working due to wrong
     hardcoded umask.
 - 2009-12-02 Fixed bug#[4613](http://bugs.otrs.org/show_bug.cgi?id=4613) - Umlauts in \<OTRS\_\*\> variable and also on whole
    message are not show right with ArticleStorageFS.
 - 2009-12-02 Fixed bug#[3667](http://bugs.otrs.org/show_bug.cgi?id=3667) - E-mail notification link is wrong when using
    FastCGI.
 - 2009-11-25 Fixed bug#[4498](http://bugs.otrs.org/show_bug.cgi?id=4498) - Rich text editor places whitespace in front of
    lines in plain text mail body.
 - 2009-11-23 Fixed bug#[4128](http://bugs.otrs.org/show_bug.cgi?id=4128) - Signature line breaks are stripped in
    E-Mail-Ticket.
 - 2009-11-18 Fixed bug#[4319](http://bugs.otrs.org/show_bug.cgi?id=4319) - 'no quotable message' error for old messages
    after upgrade.
 - 2009-11-18 Added FastCGI handle for web installer.
 - 2009-11-16 Fixed bug#[4464](http://bugs.otrs.org/show_bug.cgi?id=4464) - Spell checker (WYSIWIG + ispell) causes
    exceptions sometimes.
 - 2009-11-16 Fixed bug#[4507](http://bugs.otrs.org/show_bug.cgi?id=4507) - Add Ticket Events for SLAUpdate, ServiceUpdate,
    and TicketTypeUpdate in AdminNotificationEvent UI.
 - 2009-11-16 Fixed bug#[4509](http://bugs.otrs.org/show_bug.cgi?id=4509) - Notification (event based) comments are not
    saved.
 - 2009-11-06 Fixed bug#[2069](http://bugs.otrs.org/show_bug.cgi?id=2069) - Update of CustomerCompany company\_id is not
    working.
 - 2009-11-06 Fixed bug#[2948](http://bugs.otrs.org/show_bug.cgi?id=2948) - Renamed crypt config option "md5" to "md5-crypt"
    to avoid missunderstanding.
 - 2009-10-30 Fixed JS check for months, thanks to bes.
 - 2009-10-26 Fixed bug#[4455](http://bugs.otrs.org/show_bug.cgi?id=4455) - Input field in Preferences of a Dashboard
    module doesn't save settings.
 - 2009-10-26 Fixed bug#[4454](http://bugs.otrs.org/show_bug.cgi?id=4454) - scripts/restore.pl is not working.
 - 2009-10-26 Fixed bug#[4447](http://bugs.otrs.org/show_bug.cgi?id=4447) - TimeUnits not saved in AgentTicketMove.pm when
    omitting a note.
 - 2009-10-22 Fixed bug#[4188](http://bugs.otrs.org/show_bug.cgi?id=4188) - Restore original subject check in AgentTicketMerge.
 - 2009-10-21 Fixed bug#[4232](http://bugs.otrs.org/show_bug.cgi?id=4232) - SpellChecker Customer-Interface is not
    working.
 - 2009-10-19 Fixed bug#[4433](http://bugs.otrs.org/show_bug.cgi?id=4433) - StateDefault is being ignored in when composing
    an email answer, current ticket state or first one in list gets selected.

# 2.4.5 2009-10-15
 - 2009-10-12 Fixed bug#[3541](http://bugs.otrs.org/show_bug.cgi?id=3541) - Deleting tickets is not possible when using
    Full Text Search Index on MS-SQL or PostgreSQL.
 - 2009-10-12 Fixed bug#[4392](http://bugs.otrs.org/show_bug.cgi?id=4392) - TicketCounter.log is created after permissions
    are set.
 - 2009-10-07 Updated cpan module TEXT::CSV to version 1.14 to
    fix bug#[4195](http://bugs.otrs.org/show_bug.cgi?id=4195) - Import with leading 0 in a field not possible.
 - 2009-10-07 Fixed bug#[3581](http://bugs.otrs.org/show_bug.cgi?id=3581) - Wrong German translation of "no".
 - 2009-10-07 Fixed bug#[4397](http://bugs.otrs.org/show_bug.cgi?id=4397) - QueueView shows wrong filter name.
 - 2009-10-07 Fixed bug#[4395](http://bugs.otrs.org/show_bug.cgi?id=4395) - Can't delete locked tickets via GenericAgent
    on PostgreSQL and MS-SQL databases.
 - 2009-10-07 Fixed bug#[4367](http://bugs.otrs.org/show_bug.cgi?id=4367) - Generic agent produces TicketNumberLookup error
    messages.
 - 2009-10-05 Fixed bug#[3793](http://bugs.otrs.org/show_bug.cgi?id=3793) - UTF-8 PostgreSQL database encode issues on
    incoming emails.
 - 2009-10-05 Updated Spanish translation, thanks to Emiliano Augusto!
 - 2009-10-02 Fixed bug#[4379](http://bugs.otrs.org/show_bug.cgi?id=4379) - Array parameters not working in mkStats.pl
 - 2009-09-30 Fixed bug#[4348](http://bugs.otrs.org/show_bug.cgi?id=4348) - Dashboard: Upcoming Events Caching on a
    per-user basis.
 - 2009-09-30 Fixed bug#[4338](http://bugs.otrs.org/show_bug.cgi?id=4338) - Enhancement: Be able to disable customer
    feature of customer\_id to have access to all ticket with same customer id.
 - 2009-09-30 Fixed bug#[4358](http://bugs.otrs.org/show_bug.cgi?id=4358) - Unable to insert inline images in customer
    frontend if WebUploadCacheModule is set to "FS".
 - 2009-09-30 Fixed bug#[4355](http://bugs.otrs.org/show_bug.cgi?id=4355) - SLA dropdown does not populate in
    AgentTicketEmail.
 - 2009-09-29 Fixed bug#[3248](http://bugs.otrs.org/show_bug.cgi?id=3248) - TicketSearch with ExtendedSearchCondition not
    working correct.
 - 2009-09-29 Fixed bug#[4341](http://bugs.otrs.org/show_bug.cgi?id=4341) - RTE is not coupled with RichTextViewing. Rich
    text is being shown, even if the text/plain MIME part is available.
    Added new config option to force rich text viewing in ticket zoom.

```
     SysConfig -> Ticket -> Frontend::Agent::Ticket::ViewZoom ->
      -=> Ticket::Frontend::ZoomRichTextForce
```

 - 2009-09-28 Fixed bug#[4269](http://bugs.otrs.org/show_bug.cgi?id=4269) - Softwareerror in stats module after uninstall
    ITSMIncidentProblemManagement
 - 2009-09-28 Fixed bug#[4341](http://bugs.otrs.org/show_bug.cgi?id=4341) - No HighlightColors configured fills up OTRS log
    file with warnings.
 - 2009-09-28 Fixed bug#[4328](http://bugs.otrs.org/show_bug.cgi?id=4328) - Incorrect charset in AgentTicketAttachment.
 - 2009-09-28 Fixed bug#[4333](http://bugs.otrs.org/show_bug.cgi?id=4333) - StateGet() gives wrong error message.
 - 2009-09-26 Fixed bug#[4302](http://bugs.otrs.org/show_bug.cgi?id=4302) - Dashboard: Tickets Stats graph incorrect
   (permission related).
 - 2009-09-24 Fixed bug#[3909](http://bugs.otrs.org/show_bug.cgi?id=3909) - Optional TicketFreeTimes with AgentTicketCompose
    break when attaching a file
 - 2009-09-23 Fixed bug#[4326](http://bugs.otrs.org/show_bug.cgi?id=4326) - Notification emails have empty lines by using
    opera at creation time.
 - 2009-09-23 Fixed bug#[3001](http://bugs.otrs.org/show_bug.cgi?id=3001) - Agent ticket queue ordering by priority causes
    SQL error.
 - 2009-09-23 Fixed bug#[3969](http://bugs.otrs.org/show_bug.cgi?id=3969) - Role \<-\> User Admin Screen Refresh Error.
 - 2009-09-23 Fixed bug#[3787](http://bugs.otrs.org/show_bug.cgi?id=3787) - Generic Agent: Send no notifications is not
    working.
 - 2009-09-23 Fixed bug#[4222](http://bugs.otrs.org/show_bug.cgi?id=4222) - Changed Italian translation of "Login As".
 - 2009-09-23 Fixed bug#[3923](http://bugs.otrs.org/show_bug.cgi?id=3923) - Frontend::Output::FilterText###OutputFilterTextAutoLink
    does not work.
 - 2009-09-23 Fixed bug#[4226](http://bugs.otrs.org/show_bug.cgi?id=4226) - "Previous owner" alway empty when a new owner
    must be defined.
 - 2009-09-23 Fixed bug#[4322](http://bugs.otrs.org/show_bug.cgi?id=4322) - Bulk-Action checkboxes are refilled wrongly by
    Firefox-Autocomplete feature.
 - 2009-09-23 Fixed bug#[4320](http://bugs.otrs.org/show_bug.cgi?id=4320) - Javascript-check on empty body not working
    with RichText-Editor (RTE).
 - 2009-09-23 Fixed bug#[2936](http://bugs.otrs.org/show_bug.cgi?id=2936) - $QData{""} and $Quote{""} crashes if a space
    is set between the arguments.
 - 2009-09-22 Fixed bug#[4262](http://bugs.otrs.org/show_bug.cgi?id=4262) - Encoding issue with Event-based notifications.
 - 2009-09-22 Fixed bug#[1420](http://bugs.otrs.org/show_bug.cgi?id=1420) - $Text{"User"} instead of $Text{"Username"} in
    AdminUserForm.dtl
 - 2009-09-22 Ensured that plain article body is used for ArticleViewModules
    in AgentTicketZoom.
 - 2009-09-21 Fixed bug#[2087](http://bugs.otrs.org/show_bug.cgi?id=2087) - AgentTicketMove does not consider responsible
    feature.
 - 2009-09-21 Fixed bug#[4029](http://bugs.otrs.org/show_bug.cgi?id=4029) - S/MIME activation with unclear message
    message/incomplete documentation.
 - 2009-09-21 Fixed bug#[3408](http://bugs.otrs.org/show_bug.cgi?id=3408) - Richtext editor - editor windows is way to small.
 - 2009-09-21 Fixed bug#[4188](http://bugs.otrs.org/show_bug.cgi?id=4188) - Moving junk mails unnecessarily need subject and
    body.
 - 2009-09-21 Fixed bug#[4189](http://bugs.otrs.org/show_bug.cgi?id=4189) - RTE off inserts a blank line in the text editor
    field.
 - 2009-09-21 Fixed bug#[4080](http://bugs.otrs.org/show_bug.cgi?id=4080) - Rich editors javascript overrides onload function.
 - 2009-09-21 Fixed bug#[3818](http://bugs.otrs.org/show_bug.cgi?id=3818) - Customer History - Small/Medium/Preview does
    not work.
 - 2009-09-21 Fixed bug#[2532](http://bugs.otrs.org/show_bug.cgi?id=2532) - Problem when setting queues and subqueues to
    invalid.
 - 2009-09-18 Updated Spanish translation, thanks to Gustavo Azambuja!
 - 2009-09-16 Fixed bug#[4288](http://bugs.otrs.org/show_bug.cgi?id=4288) - 4288: Use of uninitialized value in
    AdminGenericAgent.pm.
 - 2009-09-16 Fixed bug#[4292](http://bugs.otrs.org/show_bug.cgi?id=4292) - "\<some@example.com\>" in body breaks body on
    ticket split.
 - 2009-09-08 Fixed bug#[4255](http://bugs.otrs.org/show_bug.cgi?id=4255) - RichText is not coupled with RichTextViewing.
    Rich Text is being shown, even if the text/plain MIME part is available.
 - 2009-09-08 Fixed bug#[4243](http://bugs.otrs.org/show_bug.cgi?id=4243) - Adding a key to DefaultTheme HostBased via
    Sysconfig breaks OTRS.
 - 2009-09-08 Fixed bug#[4257](http://bugs.otrs.org/show_bug.cgi?id=4257) - No event based notification is sent on queue
    or state update.
 - 2009-09-08 Fixed bug#[4233](http://bugs.otrs.org/show_bug.cgi?id=4233) - AgentTicketCompose doesn't remember next state
    while attaching a file.
 - 2009-09-08 Fixed bug#[4228](http://bugs.otrs.org/show_bug.cgi?id=4228) - scripts/DBUpdate-to-2.4.pl -
    MigrateCustomerNotification() fails.
 - 2009-09-08 Fixed bug#[4232](http://bugs.otrs.org/show_bug.cgi?id=4232) - SpellChecker Customer-Interface is not
    working.
 - 2009-09-08 Fixed bug#[4248](http://bugs.otrs.org/show_bug.cgi?id=4248) - follow up email contains the ticket number two
    times.
 - 2009-09-07 Fixed bug#[4253](http://bugs.otrs.org/show_bug.cgi?id=4253) - No customer get found by using german umlaut
    "e. g. mï¿½ller".
 - 2009-09-02 Fixed bug#[4186](http://bugs.otrs.org/show_bug.cgi?id=4186) - Customer search autocomplete result field is
    sometimes too small to show complete customer entry.
 - 2009-09-02 Fixed bug#[4234](http://bugs.otrs.org/show_bug.cgi?id=4234) - Typo in german update message.
 - 2009-09-01 Fixed bug#[4139](http://bugs.otrs.org/show_bug.cgi?id=4139) - Missing config option to show or hide customer
    history tickets.
 - 2009-09-01 Fixed bug#[4160](http://bugs.otrs.org/show_bug.cgi?id=4160) - Toolbar icons not correct in AdminCustomerUser.
 - 2009-09-01 Updated French translation, thanks to Remi Seguy.
 - 2009-09-01 Added Options for FirstResponseTime,UpdateTime,SolutionTime and
    CalendarID to bin/otrs.addQueue.
 - 2009-09-01 Fixed bug#[4214](http://bugs.otrs.org/show_bug.cgi?id=4214) - TicketSearch on TicketID with ArrayRef doesn't
    give results.

# 2.4.4 2009-08-31
 - 2009-08-31 Fixed bug#[4105](http://bugs.otrs.org/show_bug.cgi?id=4105) - CustomerUser has access to other Customers
    tickets than defined in CustomerIDs.
 - 2009-08-31 Fixed Android browser support.
 - 2009-08-31 Added SOAP::Lite, which is needed for the XML-RPC Interface,
    to bin/otrs.checkModules.
 - 2009-08-29 Fixed bug#[4018](http://bugs.otrs.org/show_bug.cgi?id=4018) - CustomerCompany in ModuleAction section while
    CustomerUser in Module section.
 - 2009-08-28 Fixed bug#[4159](http://bugs.otrs.org/show_bug.cgi?id=4159) - Text Editor does not work with Konqueror.
 - 2009-08-28 Fixed bug#[4117](http://bugs.otrs.org/show_bug.cgi?id=4117) - UPGRADING: SetPermission.sh has to be run
    before the update script is started.
 - 2009-08-28 Fixed bug#[1917](http://bugs.otrs.org/show_bug.cgi?id=1917) - Wrong Content-Type in downloaded message
    from ArticlePlain.
 - 2009-08-28 Fixed wrong quoting in links in AgentTicketZoom.dtl and
    CustomerTicketZoom.dtl.
 - 2009-08-28 Fixed bug#[4203](http://bugs.otrs.org/show_bug.cgi?id=4203) - No German translation for "My Locked Tickets".
 - 2009-08-28 Fixed bug#[1245](http://bugs.otrs.org/show_bug.cgi?id=1245) - Queues and responses are sorted descending
    instead of ascending in AdminQueueResponses.
 - 2009-08-27 Fixed bug#[4198](http://bugs.otrs.org/show_bug.cgi?id=4198) - Error with services with one bracket in the
    name.
 - 2009-08-27 Fixed bug#[4085](http://bugs.otrs.org/show_bug.cgi?id=4085) - The UPGRADING document is incorrect and
    misleading.
 - 2009-08-27 Fixed bug#[2768](http://bugs.otrs.org/show_bug.cgi?id=2768) - AttachmentsContent-Disposition header
    downloading a with non-ASCII filename.
 - 2009-08-27 Fixed bug#[3974](http://bugs.otrs.org/show_bug.cgi?id=3974) - Missing template stats in the 2.4.0 beta 5.
 - 2009-08-27 Fixed bug#[3297](http://bugs.otrs.org/show_bug.cgi?id=3297) - Disabling of AgentTicketMerge does not remove
    merge link.
 - 2009-08-26 Fixed bug#[3746](http://bugs.otrs.org/show_bug.cgi?id=3746) - Show expiration date for PGP or S/MIME keys.
 - 2009-08-25 Fixed bug#[2676](http://bugs.otrs.org/show_bug.cgi?id=2676) - Translation issue for May.
 - 2009-08-26 Fixed bug#[4122](http://bugs.otrs.org/show_bug.cgi?id=4122) - META: spell checker issues with Rich Text
    Editor.
 - 2009-08-25 Added prio color in dashboard ticket overview like in ticket
    overview "s" mode.
 - 2009-08-24 Fixed bug#[4090](http://bugs.otrs.org/show_bug.cgi?id=4090) - RSS feeds have broken umlauts.
 - 2009-08-24 Fixed bug#[4177](http://bugs.otrs.org/show_bug.cgi?id=4177) - ArticleFilterDialog does not work in IE
    Javascript.
 - 2009-08-24 Added COPYING-Third-Party - a list of all included party
    libraries.
 - 2009-08-21 Fixed bug#[4178](http://bugs.otrs.org/show_bug.cgi?id=4178) - Added bundle of Apache2::Reload in
    Kernel/cpan-lib/, because it's no longer distributed with mod\_perl.
 - 2009-08-21 Fixed bug#[4170](http://bugs.otrs.org/show_bug.cgi?id=4170) - Typos in AgentTicketQueue and Sysconfig:MOTD.
 - 2009-08-19 Fixed bug#[4070](http://bugs.otrs.org/show_bug.cgi?id=4070) - No refresh in CPanel activated by default /
    default values of preferences sys config not taken over.
 - 2009-08-18 Fixed bug#[4161](http://bugs.otrs.org/show_bug.cgi?id=4161) - System takes about 20sec to get edit screen
    like note or compose answer.
 - 2009-08-18 Fixed bug#[4073](http://bugs.otrs.org/show_bug.cgi?id=4073) - Forward form does not add attachment.
 - 2009-08-18 Fixed bug#[4102](http://bugs.otrs.org/show_bug.cgi?id=4102) - otrs.addUser2Group: "Use of uninitialized
    value" message.
 - 2009-08-18 Replaced a Die() call in Kernel/System/Package.pm with an normal
    return for a better error handling.
 - 2009-08-18 Fixed bug#[4049](http://bugs.otrs.org/show_bug.cgi?id=4049) - SetPermissions.sh fails if .fetchmailrc does
    not exist.
 - 2009-08-18 Added attachment support of ArticleCreate event in event based
    notification feature.
 - 2009-08-18 Fixed bug#[4149](http://bugs.otrs.org/show_bug.cgi?id=4149) - TicketCreate event does not have access to
    Article attributes.
 - 2009-08-18 Fixed bug#[4155](http://bugs.otrs.org/show_bug.cgi?id=4155) - Typo in German translation of
    AdminSystemAddressForm.dtl.
 - 2009-08-17 Fixed bug#[3872](http://bugs.otrs.org/show_bug.cgi?id=3872) - Typo in CustomerFrontend::CommonParam###Action
    issue.
 - 2009-08-17 Fixed bug#[4154](http://bugs.otrs.org/show_bug.cgi?id=4154) - Signature seperator is wrong.
 - 2009-08-16 Fixed bug#[4011](http://bugs.otrs.org/show_bug.cgi?id=4011) - Kernel/System/PostMaster/Filter/Match.pm
    global symbol $Prefix not declared.
 - 2009-08-14 Fixed bug#[4150](http://bugs.otrs.org/show_bug.cgi?id=4150) - US/English Date Format not available.
 - 2009-08-13 Fixed bug#[4092](http://bugs.otrs.org/show_bug.cgi?id=4092) - Junk tickets shown as New tickets in Dashboard.
 - 2009-08-13 Fixed bug#[4129](http://bugs.otrs.org/show_bug.cgi?id=4129) - Watched Tickets in Dashboard.
 - 2009-08-13 Fixed bug#[4072](http://bugs.otrs.org/show_bug.cgi?id=4072) - Inline images broken in reply with
    ArticleStorageFS as attachment backend.

# 2.4.3 2009-08-12
 - 2009-08-10 Fixed bug#[4123](http://bugs.otrs.org/show_bug.cgi?id=4123) - Reinstall of OPM packages with incorrect
    framework or OS possible.
 - 2009-08-10 Fixed bug#[4116](http://bugs.otrs.org/show_bug.cgi?id=4116) - Error when bouncing welcome ticket.
 - 2009-08-10 Fixed bug#[3870](http://bugs.otrs.org/show_bug.cgi?id=3870) - OTRS utf-8 to iso-8859-1 conversion error
    messages on every incoming mail.
 - 2009-08-05 Fixed bug#[4089](http://bugs.otrs.org/show_bug.cgi?id=4089) - root on OTRS Server gets an e-mail every 10
    minutes (Can't call method "FETCH" on an undefined value at ...Net/LDAP.pm
    line 274)
 - 2009-08-05 Fixed bug#[4107](http://bugs.otrs.org/show_bug.cgi?id=4107) - OpenSearch URL incorrect in Customer
    Interface.
 - 2009-08-03 Improved ChallengeTokenCheck to check all token of own
    sessions (not only of current session).
 - 2009-08-01 Fixed bug#[4086](http://bugs.otrs.org/show_bug.cgi?id=4086) - Kernel/System/Ticket.pm - next not in loop.
 - 2009-08-01 Fixed bug#[2795](http://bugs.otrs.org/show_bug.cgi?id=2795) - Modification on SubjectRe (possible use of
    "" in Ticket::SubjectRe).
 - 2009-07-31 Fixed bug#[4044](http://bugs.otrs.org/show_bug.cgi?id=4044) - WYSIWYG DefaultPreViewLines in ExpandMode.
 - 2009-07-30 Fixed bug#[4082](http://bugs.otrs.org/show_bug.cgi?id=4082) - Queue customer notification moved to new
    event based notification feature, but it's still in admin interface and
    initial insert file.
 - 2009-07-30 Fixed bug#[4081](http://bugs.otrs.org/show_bug.cgi?id=4081) - In Dashboard ticket overviews it is not
    possible to go to page 2,3,... and so on.
 - 2009-07-30 Fixed bug#[4039](http://bugs.otrs.org/show_bug.cgi?id=4039) - Use of uninitialized value -\>
    Kernel/Modules/AdminPackageManager.pm line.
 - 2009-07-30 Fixed bug#[4052](http://bugs.otrs.org/show_bug.cgi?id=4052) - Error composing a message in a Ticket with
    "empty answer" if $QData{"OrigFrom"} is used in config option
    Ticket::Frontend::ResponseFormat.
 - 2009-07-30 Fixed bug#[4048](http://bugs.otrs.org/show_bug.cgi?id=4048) - Subject starts with "Re:" when creating new
    ticket via EmailTicket.
 - 2009-07-30 Fixed bug#[4031](http://bugs.otrs.org/show_bug.cgi?id=4031) - Generic Agent does not handle ticket create
    time settings.

# 2.4.2 2009-07-29
 - 2009-07-28 Added "bin/otrs.CacheDelete.pl" to remove all cached items.
 - 2009-07-28 Updated Chinese Simple translation, thanks to Never Min!
 - 2009-07-28 Updated Swedish translation, thanks to Mikael Mattsson!
 - 2009-07-27 Fixed bug#[3962](http://bugs.otrs.org/show_bug.cgi?id=3962) - Page displayed with errors when filename
    in attachment has simple quotes in it.
 - 2009-07-27 Fixed bug#[4054](http://bugs.otrs.org/show_bug.cgi?id=4054) - Bulk-action don't change ticket state.
 - 2009-07-27 Fixed bug#[3944](http://bugs.otrs.org/show_bug.cgi?id=3944) - Obligated TicketFreeText in composer breaks
    WYSIWYG Editor when replying.
 - 2009-07-26 Fixed bug#[4009](http://bugs.otrs.org/show_bug.cgi?id=4009) - Improved sql statement in GenericAgent (
    SELECT distinct(job\_name) FROM generic\_agent\_jobs).
 - 2009-07-26 Fixed bug#[3987](http://bugs.otrs.org/show_bug.cgi?id=3987) - When executing upgrade script (
    scripts/DBUpdate-to-2.4.pl), get an error "Need Ticket::ViewableStateType
    in Kernel/Config.pm!".
 - 2009-07-26 Fixed bug#[3984](http://bugs.otrs.org/show_bug.cgi?id=3984) - HTML Notifications - Links to ticketsystem not
    "clickable" in email client thunderbird.
 - 2009-07-25 Fixed bug#[4038](http://bugs.otrs.org/show_bug.cgi?id=4038) - Entering text for RTL languages is impossible
    in rich text mode!
 - 2009-07-25 Fixed bug#[4046](http://bugs.otrs.org/show_bug.cgi?id=4046) - Dashboard New/Open do not show anything in
   "New Tickets" and "Open Tickets" section.
 - 2009-07-24 Fixed bug#[4043](http://bugs.otrs.org/show_bug.cgi?id=4043) - French translation is corrupted.
 - 2009-07-24 Fixed bug#[3904](http://bugs.otrs.org/show_bug.cgi?id=3904) - Signing Mails with PGP or S/MIME not possible
   in AgentTicketEmail.
 - 2009-07-23 Fixed bug#[4020](http://bugs.otrs.org/show_bug.cgi?id=4020) - OTRS crashes when signing with PGP/GnuPG
    - Got no EncodeObject!
 - 2009-07-23 Fixed bug#[2304](http://bugs.otrs.org/show_bug.cgi?id=2304) - Two notification when a owner is changed.
 - 2009-07-23 Fixed bug#[2495](http://bugs.otrs.org/show_bug.cgi?id=2495) - Annoying Responsible Update Notifications.
 - 2009-07-23 Fixed bug#[4036](http://bugs.otrs.org/show_bug.cgi?id=4036) - Dashboard Plugin Upcoming Events shows also
    "pending auto close" tickets as "pending reminder reached in".
 - 2009-07-22 Fixed bug#[4035](http://bugs.otrs.org/show_bug.cgi?id=4035) - Dashboard Product Notify get's shown always,
    also if no new release info is available.
 - 2009-07-22 Fixed bug#[4027](http://bugs.otrs.org/show_bug.cgi?id=4027) - RichText: Incoming emails written with MS
    Word 12 seems to be empty.
 - 2009-07-22 Fixed bug#[4026](http://bugs.otrs.org/show_bug.cgi?id=4026) - Quote in Auto-Responses of new tickets which
    are created over the web interface are not plain text. Quote in
    Auto-Responses based on emails are working fine.
 - 2009-07-22 Fixed bug#[4024](http://bugs.otrs.org/show_bug.cgi?id=4024) - Use of Sessions per URL (not cookie) breaks
    Dashboard.

# 2.4.1 2009-07-22
 - 2009-07-21 Updated Hungarian translation, thanks to Arnold Matyasi!
 - 2009-07-21 Updated Turkish translation, thanks to Meric Iktu!
 - 2009-07-21 Moved to default font "Geneva,Helvetica,Arial" of rich text
    feature.
 - 2009-07-21 Fixed bug#[4005](http://bugs.otrs.org/show_bug.cgi?id=4005) - Spellcheck with FCKEditor Plugin for WYSIWYG.
 - 2009-07-21 Fixed bug#[4022](http://bugs.otrs.org/show_bug.cgi?id=4022) - In AgentTicketZoom I get the following error
    message in log index.pl: Malformed UTF-8 character (unexpected
    non-continuation byte 0x74, immediately after start byte 0xe9) in
    substitution iterator at ../..//Kernel/Modules/AgentTicketAttachment.pm
    line 192.
 - 2009-07-21 Added/Updated new Chinese Traditional translation, thanks to
    Bin Du, Yiye Huang and Qingjiu Jia!

# 2.4.0 beta6 2009-07-19
 - 2009-07-19 Moved to fckeditor (http://www.fckeditor.net/) as rich text
    editor because of several problems regaring text formating with YUI rich
    text editor.
 - 2009-07-19 Updated CPAN File::Temp to verion 0.22.
 - 2009-07-19 Updated Chinese Simple translation, thanks to Never Min!
 - 2009-07-19 Added new Chinese Traditional translation, thanks to Bin Du,
    Yiye Huang and Qingjiu Jia!
 - 2009-07-19 Updated Chinese Simple translation, thanks to Bin Du,
    Yiye Huang and Qingjiu Jia!
 - 2009-07-18 Fixed bug#[4004](http://bugs.otrs.org/show_bug.cgi?id=4004) - Can not search for customer strings like
    "St. Peters", I always get the result of "St.+Peters" which is much
     more than I want. Please make it working like in OTRS 2.3.
 - 2009-07-18 Fixed bug#[3991](http://bugs.otrs.org/show_bug.cgi?id=3991) - Link in HTML Article opens in iframe.
 - 2009-07-18 Renamed Kernel/System/HTML2Ascii.pm to
    Kernel/System/HTMLUtils.pm, because of better naming.
 - 2009-07-17 Updated Russian translation, thanks to Andrey Cherepanov!
 - 2009-07-16 Fixed bug#[4001](http://bugs.otrs.org/show_bug.cgi?id=4001) - proxy usage - rss get's not loaded via
    proxy settings.
 - 2009-07-16 Updated Russian translation, thanks to Egor Tsilenko!
 - 2009-07-16 Fixed bug#[3994](http://bugs.otrs.org/show_bug.cgi?id=3994) - It's possible to create an email ticket
 - 2009-07-16 Fixed bug#[3997](http://bugs.otrs.org/show_bug.cgi?id=3997) - Wrong named variable in AgentTicketZoom.
 - 2009-07-16 Fixed bug#[3993](http://bugs.otrs.org/show_bug.cgi?id=3993) - Error message about wrong email adress
    not visible in AgentTicketPhone and AgentTicketEmail if AutoComplete
    is enabled.
 - 2009-07-16 Fixed bug#[3994](http://bugs.otrs.org/show_bug.cgi?id=3994) - It's possible to create an email ticket
    for internal queues.
 - 2009-07-15 Fixed bug#[3663](http://bugs.otrs.org/show_bug.cgi?id=3663) - Responsible Notification does not happen
    for pending reached.
    Added config optio to be compat. to old OTRS versions.
    --\>\> SysConfig -\> Ticket -\> Core::Ticket -\>
             Ticket::PendingNotificationNotToResponsible \<\<--
 - 2009-07-15 Updated Italian translation, thanks to Giordano Bianchi,
    Emiliano Coletti and Alessandro Faraldi!
 - 2009-07-14 Fixed bug#[3983](http://bugs.otrs.org/show_bug.cgi?id=3983) - bin/PendingJobs.pl is not sendign reminder
    email (Error Message: Message: Need RecipientID!).
 - 2009-07-14 Fixed bug#[3977](http://bugs.otrs.org/show_bug.cgi?id=3977) - Tags of auto responses get not replaced.
 - 2009-07-14 Fixed bug#[3960](http://bugs.otrs.org/show_bug.cgi?id=3960) - Split function does not use RichText content
    from original article for new article.
 - 2009-07-14 Fixed bug#[3976](http://bugs.otrs.org/show_bug.cgi?id=3976) - AgentTicketBounce does not work when
    Frontend::RichText is disabled.
 - 2009-07-13 Updated Russian translation, thanks to Mike Lykov!
 - 2009-07-13 Updated Italian translation, thanks to Remo Catelotti!
 - 2009-07-13 Fixed bug#[3975](http://bugs.otrs.org/show_bug.cgi?id=3975) - New Dashboard Featrue: SQL of Upcoming Events
    (for pending remidner time) is not using database index, index on
    until\_time is missing. Use scripts/DBUpdate-to-2.4.\*.sql for upgrading.
 - 2009-07-13 Fixed bug#[3972](http://bugs.otrs.org/show_bug.cgi?id=3972) - Sub Kernel::System::TicketOwnerCheck() gives
    wrong result if asked for different TicketIDs in one TicketObject.
 - 2009-07-13 Updated Persian translation, thanks to Amir Shams Parsa!
 - 2009-07-13 Updated Dutch translation, thanks to Michiel Beijen!
 - 2009-07-13 Fixed bug#[3790](http://bugs.otrs.org/show_bug.cgi?id=3790) - POP3S doesn't fail when IO::Socket::SSL is not
    installed or mail server address is wrong.
 - 2009-07-13 Improved dashboard api / module layer to load content changes
    via AJAX / no compiled dashboard reload is needed.
 - 2009-07-11 Added new dashboard backend to show online agent and customers.
 - 2009-07-11 Improved dashboard api / module layer (added Preferences() to
    API to get/modify config settings of backend at runtime).
 - 2009-07-11 Fixed bug#[3967](http://bugs.otrs.org/show_bug.cgi?id=3967) - Unable to create notes by using GenericAgent
    (Error: Need Charset!).
 - 2009-07-11 Fixed bug#[3965](http://bugs.otrs.org/show_bug.cgi?id=3965) - New TicketOverview S/M/L feature: Last used
    ticket view mode get't only stored in current session but get lost after
    new relogin.
 - 2009-07-11 Fixed bug#[3964](http://bugs.otrs.org/show_bug.cgi?id=3964) - Update script is not working correctly (Can't
    call method "NotificationAdd" on an undefined value at
    scripts/DBUpdate-to-2.4.pl line 218).
 - 2009-07-11 Fixed bug#[3963](http://bugs.otrs.org/show_bug.cgi?id=3963) - Upgrade script is not executable
    scripts/DBUpdate-to-2.4.pl.

# 2.4.0 beta5 2009-07-09
 - 2009-07-09 Fixed bug#[3938](http://bugs.otrs.org/show_bug.cgi?id=3938) - GenericAgent.pl - send agent escalation
    notification escalation ERROR (Got no EncodeObject).
 - 2009-07-09 Updated Polish translation, thanks to Artur Skalski!
 - 2009-07-09 Updated French translation, thanks to Olivier Sallou!
 - 2009-07-09 Updated Persian translation, thanks to Afshar Mohebbi!
    See also at
    http://afsharm.blogspot.com/2009/06/localizing-otrs-into-persian-farsi.html
 - 2009-07-09 Added CSV/HTML export for Admin-SQL-Box feature.
 - 2009-07-09 Fixed bug#[3956](http://bugs.otrs.org/show_bug.cgi?id=3956) - New OpenSearch feature for fulltext search
    is not working.
 - 2009-07-08 Fixed bug#[3954](http://bugs.otrs.org/show_bug.cgi?id=3954) - Lite Theme is not working.
 - 2009-07-07 Updated Italian translation, thanks to Remo Catelotti!
 - 2009-07-06 Fixed bug#[3948](http://bugs.otrs.org/show_bug.cgi?id=3948) - Some \<OTRS\> variables are not replaced in
    responses and auto responses.
 - 2009-07-06 Fixed bug#[3946](http://bugs.otrs.org/show_bug.cgi?id=3946) - Incomplete substitution of tag
    \<OTRS\_FIRST\_NAME\> in templates.
 - 2009-07-01 Added Kernel/Language/en\_CA.pm and Kernel/Language/en\_GB.pm
    to have different date formats for US, CA and GB.
 - 2009-07-01 Fixed bug#[3939](http://bugs.otrs.org/show_bug.cgi?id=3939) - Not able to configure an external
    customer dastabase source // Got no EncodeObject! at Kernel/System/DB.pm
    line 96.
 - 2009-07-01 Fixed bug#[3935](http://bugs.otrs.org/show_bug.cgi?id=3935) - Frontend::CustomerUser::Item###9-OpenTickets
    does not work anymore.
 - 2009-07-01 Fixed bug#[3936](http://bugs.otrs.org/show_bug.cgi?id=3936) - "select all" in bulk action is not working
    on only one ticket in overview.
 - 2009-06-30 Updated Italian translation, thanks to Remo Catelotti!
 - 2009-06-30 Fixed bug#[3934](http://bugs.otrs.org/show_bug.cgi?id=3934) - Error message on email processing - without
    any effect.

# 2.4.0 beta4 2009-06-30
 - 2009-06-25 Fixed bug#[3774](http://bugs.otrs.org/show_bug.cgi?id=3774) - Wrong processing of email address containing
    www.com.
 - 2009-06-25 Fixed bug#[3892](http://bugs.otrs.org/show_bug.cgi?id=3892) - Wrong error message on agents changing his
    password.
 - 2009-06-29 Fixed bug#[3933](http://bugs.otrs.org/show_bug.cgi?id=3933) - Kernel::System::LinkObject should be usable
    in rpc.pl.
 - 2009-06-20 Updated Norwegian translation, thanks to Fredrik Andersen!
 - 2009-06-29 Added Latvian translation, thanks to Ivars Strazdins!
 - 2009-06-25 Fixed bug#[3911](http://bugs.otrs.org/show_bug.cgi?id=3911) - Not all Dashboard Functions e. g. charts
    available in Internet Explorer 6.
 - 2009-06-25 Fixed bug#[3925](http://bugs.otrs.org/show_bug.cgi?id=3925) - Frontend::NavBarModule in agent navigation
    bar "Ticket::TicketSearchFulltext" and "Ticket::TicketSearchProfile" not
    working together.
 - 2009-06-25 Fixed bug#[3924](http://bugs.otrs.org/show_bug.cgi?id=3924) - Upcoming Events -\> wrong displayed Escalation
    time.
 - 2009-06-25 Fixed bug#[3917](http://bugs.otrs.org/show_bug.cgi?id=3917) - Dashboard will crash when no Internet
    connection available - Module: ProductNotify.
 - 2009-06-25 Fixed bug#[3913](http://bugs.otrs.org/show_bug.cgi?id=3913) - Missing Modules in 2.4.0 beta1-beta3:
    Kernel/Output/HTML/ServicePreferencesGeneric.pm and
    Kernel/Output/HTML/SLAPreferencesGeneric.pm.
 - 2009-06-24 Fixed bug#[3826](http://bugs.otrs.org/show_bug.cgi?id=3826) - In auto responses and agent notifications,
    WYSIWYG is not working.
 - 2009-06-24 Fixed bug#[3796](http://bugs.otrs.org/show_bug.cgi?id=3796) - Admin notification edit screen is not coming
    proper in WYSIWYG editor.
 - 2009-06-22 Added PasswordMaxLoginFailed as password preferences to define
    max login till user get gets disabled (invalid-temporarily). Feature
    provided by Torsten Thau.
 - 2009-06-22 Fixed bug#[3775](http://bugs.otrs.org/show_bug.cgi?id=3775) - Translation error in Kernel/Language/de.pm.
 - 2009-06-22 Fixed bug#[3879](http://bugs.otrs.org/show_bug.cgi?id=3879) - Typing mistakes in the notification texts
    (scripts/database/otrs-initial\_insert.xml).
 - 2009-06-22 Fixed bug#[3907](http://bugs.otrs.org/show_bug.cgi?id=3907) - Sum rows/columns in stats only adds integers.
 - 2009-06-16 Fixed bug#[3881](http://bugs.otrs.org/show_bug.cgi?id=3881) - Dashboard - Error message when
    http://otrs.org/rss/ is not reachable.
 - 2009-06-13 Fixed bug#[3791](http://bugs.otrs.org/show_bug.cgi?id=3791) - Safari v3+4 cannot work with WYSIWYG Editor.
 - 2009-06-10 Fixed bug#[3882](http://bugs.otrs.org/show_bug.cgi?id=3882) - Dashboard does not set LastScreenOverview.
 - 2009-06-10 Added own web user agent, Kernel::System::WebUserAgent. Removed
    http/ftp access from Kernel::System::Package, moved to new core module.
 - 2009-06-10 Moved default menu type form "Classic" to "Modern".

# 2.4.0 beta3 2009-06-08
 - 2009-06-08 Fixed bug#[3852](http://bugs.otrs.org/show_bug.cgi?id=3852) - installer.pl throws Got no EncodeObject.
 - 2009-06-08 Fixed bug#[3842](http://bugs.otrs.org/show_bug.cgi?id=3842) - DBUpdate-to-2.4.pl - Error when updating from
    beta1 to beta 2.
 - 2009-05-28 Added new management dashboard feature.
 - 2009-05-28 Added new event based notication management feature (notification
    can get easy managed via the admin interface).
 - 2009-05-28 Fixed bug#[3868](http://bugs.otrs.org/show_bug.cgi?id=3868) - the replacement of %s in $Text{} content
    doesn't work if the content is 0.
 - 2009-05-28 Fixed bug#[3846](http://bugs.otrs.org/show_bug.cgi?id=3846) - Generic Agents - cant set "Create Times"
    settings.
 - 2009-05-27 Fixed bug#[3862](http://bugs.otrs.org/show_bug.cgi?id=3862) - typos in english warning message of
    GenericAgent setup.
 - 2009-05-18 Updated CPAN module Text::CSV to version 1.12.

# 2.4.0 beta2 2009-05-15
 - 2009-05-15 Fixed bug#[3618](http://bugs.otrs.org/show_bug.cgi?id=3618) - Ticket history info (ticket\_history.queue\_id)
    on TicketMove-Event is saving the old queue\_id instead of the new queue\_id.
 - 2009-05-15 Fixed bug#[3598](http://bugs.otrs.org/show_bug.cgi?id=3598) - Attachments are incorrectly displayed in
    ticket zoom view when attachments are located in file system (done by
    AttachmentFS) and now AttachmentDB backned is used.
 - 2009-05-15 Fixed bug#[3583](http://bugs.otrs.org/show_bug.cgi?id=3583) - Watched tickets do not follow queue rights.
    Can't read watched tickets with no permissions in new queue.
 - 2009-05-15 Fixed bug#[3816](http://bugs.otrs.org/show_bug.cgi?id=3816) - Typo in some bin/\*.pl files like
    bin/PostMasterMailbox.pl.
 - 2009-05-15 Added escalation time selection in admin generic agent
    interface.
 - 2009-05-15 Added notification event feature (be able to create custom
    notifications based on ticket events). Old notifications get migrated
    by scripts/DBUpdate-to-2.4.pl. Removed queue attributes for customer
    notification options.
 - 2009-04-27 Fixed bug#[3805](http://bugs.otrs.org/show_bug.cgi?id=3805) - Error: Module
    Kernel/Output/HTML/NavBarTicketBulkAction.pm not found!'
 - 2009-04-27 Fixed bug#[3802](http://bugs.otrs.org/show_bug.cgi?id=3802) - Errormessage: "Got no EncodeObject!" if
    using rpc.pl (SOAP).
 - 2009-04-24 Fixed bug#[3691](http://bugs.otrs.org/show_bug.cgi?id=3691) - CustomerUser::LDAP does support GroupDN now.
 - 2009-04-23 Fixed bug#[3799](http://bugs.otrs.org/show_bug.cgi?id=3799) - The UPGRADING refrences a file not included
    in the source code.
 - 2009-04-20 Updated nb\_NO translation, thanks to Fredrik Andersen!
 - 2009-04-20 Fixed bug#[3786](http://bugs.otrs.org/show_bug.cgi?id=3786) - No CSS get found at installation time (no
    colors are visable).

# 2.4.0 beta1 2009-04-20
 - 2009-04-20 Changed default config size of IPC-Log (LogSystemCacheSize)
    to 32k (64k is not working on darwin).
 - 2009-04-20 Moved from bin/SetPermissions.sh to bin/SetPermissions.pl
    for a better maintanance.
 - 2009-04-20 Added warning screen to AdminSysConfig, AdminPackageManager,
    AdminGenericAgent to block to use it till SecureMode is activated.
 - 2009-04-18 Added SysConfig setting to (not) include custmers email address
    on composing an answer "Ticket::Frontend::ComposeAddCustomerAddress".
    Default is set to true.
 - 2009-04-17 Added own SysConfig settings for bulk action (
    Ticket // Frontend::Agent::Ticket::ViewBulk).
 - 2009-04-15 Removed AgentCanBeCustomer option from agent frontend.
    Customer followup messages can only be created from the customer frontend.
 - 2009-04-09 Added search for article create times in ticket search.
 - 2009-04-09 Improved email send functionality to properly format emails
    with alternative parts and inline images.
 - 2009-04-09 Added enhancement bug#[3514](http://bugs.otrs.org/show_bug.cgi?id=3514) - RegExp support in ACLs. Now you
    can use RegExp in ACLs like the following example:

```perl
    $Self->{TicketAcl}->{'ACL-Name-1'} = {
       # match properties
       Properties => {
           Queue => {
               Name => ['[RegExp]^Misc'],
           },
       },
       # return possible options (white list)
       Possible => {
           # possible ticket options (white list)
           Ticket => {
               Service  => ['[RegExp]^t1', '[RegExp]^t2'],
               Priority => [ '4 high' ],
           },
       },
    };
```
Starting with "[RegExp]" in value area means the following will be a regexp
    content.

This ACL will match all Queues with starting "Misc" and all services with
    starting "t1" and "t2". So you do not longer need to write every full queue
    names to the array list.

   Usage of [RegExp] results in case-sensitive matching.
   Usage of [regexp] results in case-insensitive matching.
 - 2009-04-08 Updated CPAN module CGI to version 3.43.
 - 2009-04-07 Changed default config size of IPC-Log (LogSystemCacheSize)
    to 64k (160k is not working on darwin).
 - 2009-04-07 Added SMTPS support for outgoing emails (e. g. for sending
    via gmail smtp server).
 - 2009-04-06 Added fulltext search feature for quick search (OpenSearch
    format and input field in nav bar - disabled per default).
 - 2009-04-03 Added check for required perl version 5.8.6.
 - 2009-04-02 Added possibility to search tickets with params like
    \*OlderMinutes and \*NewerMinutes with 0 minutes.
 - 2009-04-02 Fixed bug#[3732](http://bugs.otrs.org/show_bug.cgi?id=3732) - Improved russion translation.
 - 2009-04-02 Dropped MaxDB/SAPDB support due to some limitations.
 - 2009-04-01 Fixed bug#[3295](http://bugs.otrs.org/show_bug.cgi?id=3295) - SQL error when you have no state of type
    "pending reminder".
 - 2009-04-01 Fixed bug#[2296](http://bugs.otrs.org/show_bug.cgi?id=2296) - Enable/disable "blinking queue" in QueueView
    via SysConfig.
 - 2009-04-01 Fixed bug#[3641](http://bugs.otrs.org/show_bug.cgi?id=3641) - AgentTicketCustomer totally broken in CVS.
 - 2009-04-01 When merging tickets, assign article based ticket history
    entries to the merged ticket as well.
 - 2009-04-01 Implemented enhancement/bug#[3333](http://bugs.otrs.org/show_bug.cgi?id=3333) - Increased the memory of
    the shared memory used for SystemLog.
 - 2009-04-01 Fixed bug#[3737](http://bugs.otrs.org/show_bug.cgi?id=3737) - Non-ascii characters in filenames of outbound
    email attachments are not quoted.
 - 2009-04-01 Implement enhancement/bug#[3527](http://bugs.otrs.org/show_bug.cgi?id=3527) - the input fields at the
    restrictions of the stats module now allow the use of wildcards at the
    beginning and end of a word (e.g. 'huber\*'). This is now the same behavior
    as in GenericAgent. But not the behavior of the TicketSearch.
 - 2009-03-30 Updated CPAN module Authen::SASL to version 2.12.
 - 2009-03-30 Updated CPAN module Text::CSV to version 1.11.
 - 2009-03-30 Updated CPAN module File::Temp to version 0.21.
 - 2009-03-17 Fixed bug#[3729](http://bugs.otrs.org/show_bug.cgi?id=3729) - Missing translation of "Customer history"
    in AgentTicketCustomer.
 - 2009-03-17 Fixed bug#[3713](http://bugs.otrs.org/show_bug.cgi?id=3713) - Apache-error if ticket has only internal
    articles.
 - 2009-03-06 Added article filter feature in TicketZoom.
 - 2009-03-01 Replaced dtl variable for image location "$Env{"Images"}" by
    using config option "$Config{"Frontend::ImagePath"}" to remove not needed
    $Env{} "alias". Added "$Config{"Frontend::JavaScriptPath"}" for java script
    and "$Config{"Frontend::CSSPath"}" for css directory.
 - 2009-02-27 Added feature to show the ticket title or the last
    customer subject in TicketOverviewSmall.
 - 2009-02-27 Added enhancement bug#[3271](http://bugs.otrs.org/show_bug.cgi?id=3271) Added accessibility of
    Kernel::System::CustomerUser (CustomerUserObject) to bin/cgi-bin/rpc.pl
    (SOAP handle).
 - 2009-02-17 Added group permission support for bulk feature (config via
    SysConfig -\> Ticket -\> Core::TicketBulkAction).
 - 2009-02-17 Added read only permission support for watched tickets.
 - 2009-02-17 Added agent notification support for watched tickets (config
    via perferences setting for each agent).
 - 2009-02-11 Fixed ticket# 2009020942001554 - generic agent is logging many
    debug infos into log file.
 - 2009-02-09 Fixed bug#[3075](http://bugs.otrs.org/show_bug.cgi?id=3075) - IntroUpgrade Text is not shown during package
    upgrade in admin interface of package manager.
 - 2009-02-09 Implement the same identifier handling for customer as for
    user. This effects the files Kernel/Ouptut/HTML/\*/CustomerNavigationBar.dtl
    and Kernel/Ouptut/HTML/Layout.pm.
 - 2009-02-05 Removed the dtl-if from Header.dtl. And implement a new
    handling to set a indentifier for the user information (usually visible
    on the top of the right side of a page).
 - 2009-02-04 Implement a config option to remove OTRS version tags
    from the http headers.
 - 2009-02-04 Removed a useless slogan from the HTML/DTL-Headers (
    Kernel/Ouptut/HTML/\*/Header.dtl, Kernel/Ouptut/HTML/\*/Footer.dtl, ...).
 - 2009-01-28 Fixed bug#[3233](http://bugs.otrs.org/show_bug.cgi?id=3233) - Better error message when adding auto
    responses with same name.
 - 2009-01-26 Removed outdated function FetchrowHashref() from core module
    Kernel/System/DB.pm.
 - 2009-01-08 Fixed bug#[3571](http://bugs.otrs.org/show_bug.cgi?id=3571) - Output Filter Pre+Post of layout object will
    be use on any block, not on any template file like it was in 2.1-2.2. Moved
    back to old behavior.
 - 2009-01-05 Moved to new auth sync layer. Splited auth and agent
    sync into two module layers. For example:

    [Kernel/Config.pm]

```perl
    # agent authentication against http basic auth
    $Self->{'AuthModule'} = 'Kernel::System::Auth::HTTPBasic';

    # agent data sync against ldap
    $Self->{'AuthSyncModule'} = 'Kernel::System::Auth::Sync::LDAP';
    $Self->{'AuthSyncModule::LDAP::Host'} = 'ldap://ldap.example.com/';
    $Self->{'AuthSyncModule::LDAP::BaseDN'} = 'dc=otrs, dc=org';
    $Self->{'AuthSyncModule::LDAP::UID'} = 'uid';
    $Self->{'AuthSyncModule::LDAP::SearchUserDN'} = 'uid=sys, ou=user, dc=otrs, dc=org';
    $Self->{'AuthSyncModule::LDAP::SearchUserPw'} = 'some_pass';
    $Self->{'AuthSyncModule::LDAP::UserSyncMap'} = {
        # DB -> LDAP
        UserFirstname => 'givenName',
        UserLastname  => 'sn',
        UserEmail     => 'mail',
    };
```
 - 2008-12-28 Added daemon support to bin/PostMasterMailbox.pl and
    bin/GenericAgent.pl by using "-b \<BACKGROUND\_INTERVAL\_IN\_MIN\>".
 - 2008-12-22 Improved ticket escalation notification, moved to .dtl support
    (Kernel/Output/HTML/Standard/AgentTicketEscalation.dtl) and added ticket
    title as mouse on over note.
 - 2008-12-19 Added out of office feature for agent users.
 - 2008-12-15 Added new ticket attributes to CSV export of ticket in ticket
    search. New attributes are 'Closed', 'FirstLock' and 'FirstResponse'.
 - 2008-12-10 Added the text auto link feature to add http links for text body
    to add icons after conigured expressions the standard.
 - 2008-12-08 Added new postmaster filter to check if new arrived email is
    based on follow up of forwarded email. Then Followup should not be shown
    as "email-external", it should be shown as "email-internal".
 - 2008-11-12 Removed not supported PostMaster module
    Kernel/System/PostMaster/Filter/AgentInterface.pm.
 - 2008-11-10 Added autocomplete feature for customer search.
 - 2008-10-30 Fixed bug#[2371](http://bugs.otrs.org/show_bug.cgi?id=2371) - "Panic, no user data!" message should be more
    verbose.
 - 2008-10-29 Added additional default attributes of customer attributes like
    (phone, fax, mobile, street, zip, city). Use scripts/DBUpdate-to-2.4.\*.sql
    for upgrading.
 - 2008-10-28 Fixed bug#[1722](http://bugs.otrs.org/show_bug.cgi?id=1722) - weekday sorting in TimeWorkingHours corrected.
 - 2008-10-28 Fixed bug#[1491](http://bugs.otrs.org/show_bug.cgi?id=1491) - text in the file "UPGRADING" is misleading.
 - 2008-10-28 Implemented RFE (bug#[1006](http://bugs.otrs.org/show_bug.cgi?id=1006)): Added ticket change time to
    TicketGet and ArticleGet output. As a result, parameter 'Changed' is now
    usable as field in CSV search output as ticket change time.
 - 2008-10-24 Added StopAfterMatch attribute on postmaster filter (DB and
    config backend).
 - 2008-10-23 First version of improved ticket overview modus, added S/M/L
    options.
 - 2008-10-23 Added ticket change time option to agent ticket search.
 - 2008-10-14 Added COUNT as result option in TicketSearch() of
    Kernel::System::Ticket to increase performance of count lookups.
 - 2008-10-14 Added new tables for "RFC 2822 conform" and Service/SLA
    preferences feature (use scripts/DBUpdate-to-2.4.\*.sql for upgrading).
 - 2008-10-14 Added RFC 2822 conform In-Reply-To and References header
    support for outgoing emails (Threading).
 - 2008-10-02 Added script to move stored attachments from one backend to
    other backend, e. g. DB -\> FS (bin/otrs.ArticleStorageSwitch.pl).
 - 2008-10-02 Added service and sla preferences feature, like already exising
    user, customer and queue preferences. Can be extended by config settings.
 - 2008-10-02 Improved package manager to get info about documentation
    availabe in online repository packages.
 - 2008-10-02 Added password reset option based on auth backend for multi
    auth support.

# 2.3.6 2010-09-15
 - 2010-07-23 Fixed bug#[3426](http://bugs.otrs.org/show_bug.cgi?id=3426) - Abort while processing mails with invalid
    charset messes up POP3 mailbox handling.

# 2.3.5 2010-02-08
 - 2010-02-04 Fixed SQL quoting issue (see also
    http://otrs.org/advisory/OSA-2010-01-en/).
 - 2009-05-19 Fixed bug#[3844](http://bugs.otrs.org/show_bug.cgi?id=3844) - SLA get's not removed on reload if servics was
    selected before (in agent interface).
 - 2009-04-23 Fixed bug#[3495](http://bugs.otrs.org/show_bug.cgi?id=3495) - Missing ldap disconnects leaves CLOSE\_WAIT tcp
    sessions.
 - 2009-04-23 Fixed bug#[3674](http://bugs.otrs.org/show_bug.cgi?id=3674) - CustomerSearch() doesn't match non-single
    words if they are in the same DB field.
 - 2009-04-23 Fixed bug#[3684](http://bugs.otrs.org/show_bug.cgi?id=3684) - No search for \* in LDAP-CustomerBackend.
 - 2009-04-02 Fixed bug#[3732](http://bugs.otrs.org/show_bug.cgi?id=3732) - Improved russion translation.
 - 2009-04-01 Fixed bug#[3573](http://bugs.otrs.org/show_bug.cgi?id=3573) - Deleting tickets on PostgreSQL 8.3.0 failes.
 - 2009-04-01 Fixed bug#[3719](http://bugs.otrs.org/show_bug.cgi?id=3719) - otrs.checkModules incorrectly parses PDF::API2
    version.
 - 2009-04-01 Fixed bug#[3257](http://bugs.otrs.org/show_bug.cgi?id=3257) - otrs.checkModules incorrectly states DBD:mysql
    is required.
 - 2009-04-01 Fixed bug#[3739](http://bugs.otrs.org/show_bug.cgi?id=3739) - Customer can not logon to the Customer
    Interface if ShowAgentOnline is used.
 - 2009-04-01 Fixed bug#[3404](http://bugs.otrs.org/show_bug.cgi?id=3404) - PendingJobs.pl doesn't unlock the closed
    tickets.
 - 2009-04-01 Fixed bug#[3745](http://bugs.otrs.org/show_bug.cgi?id=3745) - German umlaut in customer login\_id breaks
    login.
 - 2009-03-24 Fixed bug#[3735](http://bugs.otrs.org/show_bug.cgi?id=3735) - Queue names should be quoted when editing
    queues (In this case if you use them in regular expressions).
 - 2009-02-19 Fixed bug#[3636](http://bugs.otrs.org/show_bug.cgi?id=3636) - Phone call link can be used without adding
    a body the ticket mask.
 - 2009-02-19 Fixed bug#[3671](http://bugs.otrs.org/show_bug.cgi?id=3671) - Priority in CustomerTicketZoom resets to
    pre-configured or 3.
 - 2009-02-13 Fixed bug#[3657](http://bugs.otrs.org/show_bug.cgi?id=3657) - Stats module: The locking attribute doesn't
    work.
 - 2009-02-11 Fixed ticket# 2009020942001554 - generic agent is logging many
    debug infos into log file.
 - 2009-02-09 Fixed bug#[3656](http://bugs.otrs.org/show_bug.cgi?id=3656) - The package manager testscript doesn't work
    on developer installations.
 - 2009-01-30 Fixed bug#[3635](http://bugs.otrs.org/show_bug.cgi?id=3635) - Was not able to install .opm packages bigger
    then 1MB (because of missing MySQL config) but OTRS error message was
    miss leading.
 - 2009-01-28 Fixed bug#[3242](http://bugs.otrs.org/show_bug.cgi?id=3242) - AdminGenericAgent produces apache-error-log
    entry.
 - 2009-01-26 Fixed bug#[3528](http://bugs.otrs.org/show_bug.cgi?id=3528) - Stats-cache-mechanism does not take unfixed
    restrictions in consideration.
 - 2009-01-23 Fixed bug#[3615](http://bugs.otrs.org/show_bug.cgi?id=3615) - The links to the related Customer User and
    related Group in [ Customer Users \<-\> Groups ] frontend were broken.
 - 2009-01-23 Fixed bug#[3499](http://bugs.otrs.org/show_bug.cgi?id=3499) - Permission problems if you change the
    configuration of the System::Permissions. Now it doesn't matter if you
    active or deactive one of the additional permissions.
 - 2009-01-22 Fixed bug#[3137](http://bugs.otrs.org/show_bug.cgi?id=3137) - Ticket search does not work with words like
    "BPX" and "new".
 - 2009-01-22 Fixed bug#[3596](http://bugs.otrs.org/show_bug.cgi?id=3596) - Show a warning, if some tries to renaming
    the admin group in admin frontend.

# 2.3.4 2009-01-21
 - 2009-02-09 Fixed bug#[3458](http://bugs.otrs.org/show_bug.cgi?id=3458) - Length of E-mail adress form in
    AdminSystemAddressForm is way too short.
 - 2009-01-20 Fixed bug#[3447](http://bugs.otrs.org/show_bug.cgi?id=3447) - CustomerUser-Renaming to existing UserLogin
    was possible.
 - 2009-01-20 Fixed bug#[3603](http://bugs.otrs.org/show_bug.cgi?id=3603) - Different Max-Attribute handling in Layout.pm
    BuildSelection and OptionStrgHashRef.
 - 2009-01-20 Fixed bug#[3601](http://bugs.otrs.org/show_bug.cgi?id=3601) - Problems in function BuildSelection with
   ''-Strings and 0.
 - 2009-01-15 Fixed bug#[3595](http://bugs.otrs.org/show_bug.cgi?id=3595) - VacationCheck() of Kernel::System::Time is
    ignoring different OTRS calendar.
 - 2009-01-13 Fixed bug#[3542](http://bugs.otrs.org/show_bug.cgi?id=3542) - Static Stats lose associated perlmodule after
    editing.
 - 2009-01-10 Fixed bug#[3575](http://bugs.otrs.org/show_bug.cgi?id=3575) - Framework file get lost after upgrading OTRS
    and reinstalling or uninstalling e. g. ITSM pakages then.
 - 2008-12-08 Added feature to install included packages located under
    var/packages/\*.opm on first/initial setup.
 - 2008-12-08 Fixed bug#[3462](http://bugs.otrs.org/show_bug.cgi?id=3462) - SMIME crypt and sign functions bail out -
     unable to save random state.
 - 2008-12-04 Fixed bug#[3360](http://bugs.otrs.org/show_bug.cgi?id=3360) - Service list formating broken after AJAX reload.
 - 2008-12-02 Fixed bug#[3495](http://bugs.otrs.org/show_bug.cgi?id=3495) - No unbind in LDAP-CustomerDataBackend.
 - 2008-12-01 Fixed bug#[3493](http://bugs.otrs.org/show_bug.cgi?id=3493) - CloseParentAfterClosedChilds.pm does not work.
 - 2008-11-26 Fixed bug#[2582](http://bugs.otrs.org/show_bug.cgi?id=2582) - Ticket print and config option
     Ticket::Frontend::ZoomExpandSort gets not recognized.
 - 2008-11-16 Fixed bug#[3452](http://bugs.otrs.org/show_bug.cgi?id=3452) - "permission denied" after moving tickets into
    a queue with no permissions.
 - 2008-11-16 Fixed bug#[3461](http://bugs.otrs.org/show_bug.cgi?id=3461) - It's not possible to past an email into a
    note screen, only 70 signs are possible for each line, it should be
    increased to 78.
 - 2008-11-14 Fixed bug#[3459](http://bugs.otrs.org/show_bug.cgi?id=3459) - Ticket in state "pending" are not escalating
    but shown in escalation overview with incorect timestamp calculation
    (34512 days).
 - 2008-11-10 Fixed bug#[3213](http://bugs.otrs.org/show_bug.cgi?id=3213) - Make rpc.pl work when using ModPerl.
 - 2008-11-10 Fixed bug#[3442](http://bugs.otrs.org/show_bug.cgi?id=3442) - HTML2Ascii is ignoring spaces on email
    processing.
 - 2008-11-07 Fixed bug#[2730](http://bugs.otrs.org/show_bug.cgi?id=2730) - Sending mails to MS Exchange Server 2007
    fails sometimes with "Bad file descriptor!".
 - 2008-11-01 Fixed bug#[3207](http://bugs.otrs.org/show_bug.cgi?id=3207) - Expanded articles in wrong order.
 - 2008-10-30 Fixed bug#[2071](http://bugs.otrs.org/show_bug.cgi?id=2071) - Dead link to online documentation in admin
    interface (AdminState).
 - 2008-10-29 Fixed bug#[3244](http://bugs.otrs.org/show_bug.cgi?id=3244) - "Defination"-Typo in Defaults.pm.
 - 2008-10-29 Fixed bug#[2736](http://bugs.otrs.org/show_bug.cgi?id=2736) - AdminUser&Subaction=Change - Valid is
    automatically changed
 - 2008-10-29 Fixed bug#[2710](http://bugs.otrs.org/show_bug.cgi?id=2710) - Error: Module 'Kernel::Modules::' not found!
 - 2008-10-28 Fixed bug#[3402](http://bugs.otrs.org/show_bug.cgi?id=3402) - AgentLinkObject crashes with "Got no
    UserLanguage" if browser sends exotic language.
 - 2008-10-28 Fixed bug#[3405](http://bugs.otrs.org/show_bug.cgi?id=3405) - Input field agent-email-address too short.
 - 2008-10-28 Fixed bug#[1719](http://bugs.otrs.org/show_bug.cgi?id=1719) - psql -u deprecated.
 - 2008-10-28 Fixed bug#[3366](http://bugs.otrs.org/show_bug.cgi?id=3366) - TicketEvent ArticleFreeTextSet does not know
    ArticleID.
 - 2008-10-28 Fixed bug#[3346](http://bugs.otrs.org/show_bug.cgi?id=3346) - improved error logging of new postmaster
    tickets for invalid priority names.
 - 2008-10-28 Fixed bug#[3376](http://bugs.otrs.org/show_bug.cgi?id=3376) - GenericAgent: A warning like "you have to set
    schedule times" would be helpful.
 - 2008-10-20 Fixed bug#[3391](http://bugs.otrs.org/show_bug.cgi?id=3391) - Filter out hazardous characters from redirects.
 - 2008-10-16 Fixed bug#[2415](http://bugs.otrs.org/show_bug.cgi?id=2415) - Wrong info after editing salutation.
 - 2008-10-15 Fixed bug#[3379](http://bugs.otrs.org/show_bug.cgi?id=3379) - Documentation of packages got not shown in
    admin package manager.
 - 2008-10-15 Updated Chinese translation, thanks to Never Min!
 - 2008-10-13 Fixed bug#[3373](http://bugs.otrs.org/show_bug.cgi?id=3373) - Postmaster match filter is losing [\*\*\*] on
    second time.
 - 2008-10-13 Fixed bug#[3367](http://bugs.otrs.org/show_bug.cgi?id=3367) - Escalation of first response gets not changed
    on note-external (which was working in OTRS 2.2.x).
 - 2008-10-09 Fixed bug#[3358](http://bugs.otrs.org/show_bug.cgi?id=3358) - Removed useless error warning in stats module.

# 2.3.3 2008-10-02
 - 2009-01-13 Fixed bug#[3542](http://bugs.otrs.org/show_bug.cgi?id=3542) - Static Stats lose associated perlmodule after
    editing.
 - 2008-09-30 Fixed bug#[3335](http://bugs.otrs.org/show_bug.cgi?id=3335) - No user name in pdf - print of stats-report
 - 2008-09-29 Updated Italian translation, thanks to Remo Catelotti!
 - 2008-09-29 Fixed bug#[3315](http://bugs.otrs.org/show_bug.cgi?id=3315) - GenericAgent does not work with pending time
    reached for x units.
 - 2008-09-29 Fixed bug#[3314](http://bugs.otrs.org/show_bug.cgi?id=3314) - Escalation time not updated correctly, e. g.
    ticket get's not escalated if one escalation time got solved.
 - 2008-09-25 Updated Chinese translation, thanks to Never Min!
 - 2008-09-24 Fixed bug#[3322](http://bugs.otrs.org/show_bug.cgi?id=3322) - After updating SysConfig I get: Can't use
    string ("0") as a HASH ref while "strict refs" in use at
    Kernel/System/Config.pm line 716.
 - 2008-09-24 Fixed bug#[3321](http://bugs.otrs.org/show_bug.cgi?id=3321) - "(" or ")" in user name is breaking ldap query
    for agent and customer auth.
 - 2008-09-13 Fixed bug#[3289](http://bugs.otrs.org/show_bug.cgi?id=3289) - Error when trying to delete an answer (with
    std attachment) in admin interface.
 - 2008-09-12 Fixed bug#[3292](http://bugs.otrs.org/show_bug.cgi?id=3292) - Missing entries in the generic agent mask if
    a freetext field is configured as pull down menu.
 - 2008-09-11 Fixed bug#[3275](http://bugs.otrs.org/show_bug.cgi?id=3275) - Kernel::System::EmailParser::CheckMessageBody
    uses undefined $Param{URL}.
 - 2008-09-11 Fixed bug#[3284](http://bugs.otrs.org/show_bug.cgi?id=3284) - Missing entries in the stats mask if a
    freetext field is configured as pull down menu.
 - 2008-09-10 Fixed bug#[3287](http://bugs.otrs.org/show_bug.cgi?id=3287) - Possible CSS on login page, in
    AgentTicketMailbox and CustomerTicketOverView.
 - 2008-09-08 Fixed bug#[3158](http://bugs.otrs.org/show_bug.cgi?id=3158) - Ticket has a "pending" state --\> the
    escalation time is not set out.
 - 2008-09-08 Fixed bug#[3266](http://bugs.otrs.org/show_bug.cgi?id=3266) - backup.pl calls "mysqldump5" not "mysqldump".
 - 2008-09-08 Fixed bug#[3251](http://bugs.otrs.org/show_bug.cgi?id=3251) - Error retrieving pop3s email from gmail
    or MS Exchange.
 - 2008-09-08 Fixed bug#[3247](http://bugs.otrs.org/show_bug.cgi?id=3247) - GenericAgent is running also without time
    settings.
 - 2008-09-08 Fixed bug#[3261](http://bugs.otrs.org/show_bug.cgi?id=3261) - Escalation also for ro tickets (normally just
    rw tickets).
 - 2008-08-30 Fixed bug#[2862](http://bugs.otrs.org/show_bug.cgi?id=2862) - Wrong summary in GenericAgent webinterface
    after adding a new job. Max. shown 10,000 affected tickets.
 - 2008-08-30 Fixed bug#[3053](http://bugs.otrs.org/show_bug.cgi?id=3053) - AJAX functionality without cookies is not
    working.
 - 2008-08-29 Fixed bug#[3152](http://bugs.otrs.org/show_bug.cgi?id=3152) - German wording in link tables within english
    environment.
 - 2008-08-21 Fixed bug#[3227](http://bugs.otrs.org/show_bug.cgi?id=3227) - Link delete doesn't work if the key includes
    double colons.

# 2.3.2 2008-08-25
 - 2008-08-21 Fixed bug#[3076](http://bugs.otrs.org/show_bug.cgi?id=3076) - Ticket Eskalation of update time is not
    working correctly.
 - 2008-08-21 Fixed bug#[3064](http://bugs.otrs.org/show_bug.cgi?id=3064) - Java Script Error if I use
    "Internet Explorer 7".
 - 2008-08-21 Fixed bug#[3198](http://bugs.otrs.org/show_bug.cgi?id=3198) - ACL is not working for services in Customer
    Panel for creating new tickets.
 - 2008-08-21 Fixed bug#[3214](http://bugs.otrs.org/show_bug.cgi?id=3214) - PostMasterFilter - Its not possible to
    filter for "Return-Path".
 - 2008-08-21 Fixed bug#[3216](http://bugs.otrs.org/show_bug.cgi?id=3216) - CustomerTicketSearch returns links to
    internal articles.
 - 2008-08-21 Fixed bug#[3219](http://bugs.otrs.org/show_bug.cgi?id=3219) - Bogus 7bit check in the file cache backend.
 - 2008-08-21 Implemented display of ticket search profiles in Agent
    Interface for immediate access (disabled by default).
 - 2008-08-18 Fixed bug#[3199](http://bugs.otrs.org/show_bug.cgi?id=3199) - Queue lists - The queue tree has problems
    with disabled queues.
 - 2008-08-18 Fixed bug#[3139](http://bugs.otrs.org/show_bug.cgi?id=3139) - QueueUpdate-Bug on oracle and postgres dbs.
 - 2008-08-14 Fixed bug#[3191](http://bugs.otrs.org/show_bug.cgi?id=3191) - It is hard to identify the selected page of
    a list of elements.
 - 2008-08-13 Fixed bug#[3133](http://bugs.otrs.org/show_bug.cgi?id=3133) - OTRS creates temp dirs with wrong access
    permissions.

# 2.3.1 2008-08-04
 - 2008-08-03 Fixed bug#[3096](http://bugs.otrs.org/show_bug.cgi?id=3096) - Errorlog messages from NET::DNS (Subroutine
    nxrrset redefined at ...).
 - 2008-08-03 Added http target for customer user map config options in
    position 9 (see Kernel/Config/Defaults.pm for examples).
 - 2008-08-02 Fixed bug#[3121](http://bugs.otrs.org/show_bug.cgi?id=3121) - OTRS corrupts email headers (Subject, From etc.)
    while encoding with utf-8.
 - 2008-08-01 Fixed bug#[3142](http://bugs.otrs.org/show_bug.cgi?id=3142) - The Ticket-ACL module
    CloseParentAfterClosedChilds produces errors.
 - 2008-07-31 Fixed bug#[3141](http://bugs.otrs.org/show_bug.cgi?id=3141) - The TicketSearch() function produces error on
    a DB2 database, if the argument TicketCreateTimeOlderDate is given.
 - 2008-07-31 Added function LinkCleanup() to delete forgotten temporary
    links that are older than one day. The function is called only when deleting
    a link.
 - 2008-07-30 Updated dansk language translation, thanks to Mads N. Vestergaard!
 - 2008-07-30 Updated spanish translation, thanks to Pelayo Romero Martin!
 - 2008-07-30 Updated CPAN module CGI to version 3.39.
 - 2008-07-30 Updated CPAN module MailTools to version 2.04.
 - 2008-07-27 Updated russian translation, thanks to Egor Tsilenko!
 - 2008-07-25 Fixed bug#[3122](http://bugs.otrs.org/show_bug.cgi?id=3122) - Ticket attributes in agent ticket search
    CSV export gets not translated.
 - 2008-07-25 Fixed bug#[2300](http://bugs.otrs.org/show_bug.cgi?id=2300) - Not all Notification Tags are working in
    Notifications.
 - 2008-07-21 Fixed bug#[3117](http://bugs.otrs.org/show_bug.cgi?id=3117) - Auto increment of "id" in article\_search
    table is not needed.
 - 2008-07-21 Fixed bug#[3104](http://bugs.otrs.org/show_bug.cgi?id=3104) - If new config can't get created by
    scripts/DBUpdate-to-2.3.pl, the script need to stop.

# 2.3.0 rc1 2008-07-21
 - 2008-07-20 Update persian translation, thanks to Amir Shams Parsa and
    Hooman Mesgary!
 - 2008-07-20 Fixed bug#[2712](http://bugs.otrs.org/show_bug.cgi?id=2712) - Email in POP3 or IMAP box gets deleted/lost
    also if it got not processed.
 - 2008-07-20 Added Ingres database files for Ingres 2006 R3 experimental
    support.
 - 2008-07-20 Fixed bug#[3102](http://bugs.otrs.org/show_bug.cgi?id=3102) - (Optional) group-Permissions for
    Frontend::Agent::Ticket::MenuModule(Pre).
 - 2008-07-19 Fixed bug#[3098](http://bugs.otrs.org/show_bug.cgi?id=3098) - Ticket number search in the new link mask does
    not work correctly.
 - 2008-07-19 Fixed bug#[3093](http://bugs.otrs.org/show_bug.cgi?id=3093) - Foreign Key drop does not work.
 - 2008-07-19 Fixed bug#[2826](http://bugs.otrs.org/show_bug.cgi?id=2826) - Impossible to use DEFAULT values in SOPM
    files.
 - 2008-07-18 Fixed bug#[2893](http://bugs.otrs.org/show_bug.cgi?id=2893) - Allow translation texts with new lines.
 - 2008-07-17 Integrate function StatsCleanUp().
 - 2008-07-16 Fixed bug#[3089](http://bugs.otrs.org/show_bug.cgi?id=3089) - Stats module creates an error log entry with
    message "Got no SessionID" .
 - 2008-07-16 Fixed bug#[3088](http://bugs.otrs.org/show_bug.cgi?id=3088) - Statistics module fails with
    message "Got no AccessRw" if you work with ro permissions
 - 2008-07-16 Fixed bug#[3012](http://bugs.otrs.org/show_bug.cgi?id=3012) - Statistics module fails with
    message "Got no UserLanguage"
 - 2008-07-15 Moved config option PostMasterMaxEmailSize default 12 MB
    to 16 MB.
 - 2008-07-15 Fixed bug#[3082](http://bugs.otrs.org/show_bug.cgi?id=3082) - Wrong requirement checks and false default
    handling in function QueueAdd and QueueUpdate.
 - 2008-07-15 Updated french translation, thanks to Yann Richard!
 - 2008-07-14 Only show Company-NavBar item if CustomerCompanySupport is
    enabled for min. one CustomerUser source.
 - 2008-07-10 Fixed bug#[3066](http://bugs.otrs.org/show_bug.cgi?id=3066) - The CPAN module XML::Parser::Lite crashs after
    login if the CPAN module version is not installed.
 - 2008-07-09 Updated catalonian translation, thanks to Antonio Linde!
 - 2008-07-09 Updated finnish translation, thanks to Mikko Hynninen!
 - 2008-07-09 Fixed problem in CodeUpgrade functionallity.
    Code did not react correctly to version number in CodeUpgrade sections.
 - 2008-07-08 Updated norwegian translation, thanks to Fredrik Andersen!

# 2.3.0 beta4 2008-07-07
 - 2008-07-07 Fixed bug#[2158](http://bugs.otrs.org/show_bug.cgi?id=2158) - Trigger Definitions not allow export / import
    through oracle exp/imp tool.
 - 2008-07-06 Fixed bug#[3058](http://bugs.otrs.org/show_bug.cgi?id=3058) - Unconsistent usage of id's in
    otrs-initial\_insert.\*.sql. E. g. in case of Dual-Master MySQL 5 Replication
    is used.
 - 2008-07-06 Fixed bug#[3059](http://bugs.otrs.org/show_bug.cgi?id=3059) - article\_search table is missing in
    scripts/database/otrs-schema.\*.sql and scripts/DBUpdate-to-2.3.\*.sql.
 - 2008-07-04 Fixed bug#[3055](http://bugs.otrs.org/show_bug.cgi?id=3055) - Link migration from 2.2 -\> 2.3 is no working
    (missing TypeGet(), not shown because of disabled STDERR).
 - 2008-07-03 Fixed bug#[3053](http://bugs.otrs.org/show_bug.cgi?id=3053) - AJAX functionality without cookies is not
    working.
 - 2008-07-03 Improved OPM package CodeUpgrade by using Version attribute
    for code execurtion (like already exisitng DatabaseUpgrade). If no Version
    is used, CodeUpgrade will performed on every upgrade. For more info see
    developer manual.
 - 2008-07-02 Fixed bug#[3042](http://bugs.otrs.org/show_bug.cgi?id=3042) - QueueView Sort by Escalation unfunctional.
 - 2008-07-02 Fixed bug#[3045](http://bugs.otrs.org/show_bug.cgi?id=3045) - Hard coded permission check on merging
    tickets.
 - 2008-07-02 Fixed bug#[3048](http://bugs.otrs.org/show_bug.cgi?id=3048) - AgentLinkObject shows a wrong search result
    list, if a object cannot link with itself.
 - 2008-07-02 Added AJAX support to ticket move screen.
 - 2008-07-01 Added priority management mask to the admin interface.
 - 2008-07-01 Fixed bug#[3046](http://bugs.otrs.org/show_bug.cgi?id=3046) - Phone and Email-Ticket needs to get clicked
    twice on "create" to get created.
 - 2008-07-01 Fixed bug#[3047](http://bugs.otrs.org/show_bug.cgi?id=3047) - Not possible to reset service or sla in
    AgentTicketNote.
 - 2008-07-01 Updated CPAN module Net::POP3::SSLWrapper to version 0.02.
 - 2008-07-01 Updated CPAN module XML::Parser::Lite to version 0.710.05.
 - 2008-07-01 Updated CPAN module Authen::SASL to version 2.11.
 - 2008-07-01 Updated CPAN module MIME::Tools to version 5.427.
 - 2008-07-01 Updated CPAN module File::Temp to version 0.20.
 - 2008-06-30 Implemented options to search update-, response- and solution
    escalation time in TicketSearch().
 - 2008-06-27 Fixed bug#[2960](http://bugs.otrs.org/show_bug.cgi?id=2960) - DBUpdate-to-2.3.pl script fails.
 - 2008-06-26 Fixed bug#[3036](http://bugs.otrs.org/show_bug.cgi?id=3036) - Missing link delete checkboxes.
 - 2008-06-26 Fixed bug#[3029](http://bugs.otrs.org/show_bug.cgi?id=3029) - Search result of linkable objects is not
    sorted correctly.
 - 2008-06-26 Fixed bug#[3035](http://bugs.otrs.org/show_bug.cgi?id=3035) - Missing check to prevent creation of the same
    link with opposite direction.
 - 2008-06-26 Fixed bug#[3030](http://bugs.otrs.org/show_bug.cgi?id=3030) - Getting no error message if I link an already
    linked ticket again.
 - 2008-06-26 Fixed bug#[3034](http://bugs.otrs.org/show_bug.cgi?id=3034) - Ticket::Frontend::ZoomExpandSort is
    conflicting with new ticket Expand/Collapse feature in AgentTicketZoom, it
    get lost after clicking on Collapse.
 - 2008-06-26 Moved required permissions for ticket owner-selections to
    owner and for ticket responsible-selection to responsible (instead rw
    permissions).
 - 2008-06-23 Fixed bug#[3020](http://bugs.otrs.org/show_bug.cgi?id=3020) - New complex link table blocks output of the
    free text fields.
 - 2008-06-23 Fixed bug#[3019](http://bugs.otrs.org/show_bug.cgi?id=3019) - Wrong location of the new complex link table.

# 2.3.0 beta3 2008-06-24
 - 2008-06-23 Fixed bug#[3015](http://bugs.otrs.org/show_bug.cgi?id=3015) - Performace problem in AgentLinkObject.
 - 2008-06-23 Added CustomerUser attribute support for Ticket-ACLs. For
    Example you can use customer user attributes in ACL properties in
    this case to create an list of possible queues in the customer
    interface for creating or moving tickets.

```perl
    $Self->{TicketAcl}->{'ACL-Name-Test'} = {
        # match properties
        Properties => {
            CustomerUser => {
                UserCustomerID => ['some_customer_id'],
            },
        }
        # possible properties
        Possible => {
            Ticket => {
                Queue => ['Hotline', 'Junk'],
            },
        },
    };
```
 - 2008-06-23 Fixed bug#[3013](http://bugs.otrs.org/show_bug.cgi?id=3013) - Freetext fields show wrong on AJAX update
    in phone and email ticket when queue is changed.
 - 2008-06-23 Updated cpan module TEXT::CSV to version 1.06.
 - 2008-06-23 Moved Ticket::ResponsibleAutoSet feature to external ticket
    event module (Kernel::System::Ticket::Event::ResponsibleAutoSet).
 - 2008-06-23 Fixed bug#[2959](http://bugs.otrs.org/show_bug.cgi?id=2959) - Linking and Unlinking Tickets is not addin
    ticket history and not executing TicketEventHandlerPost() by ticket link
    backend anymore.
 - 2008-06-20 Fixed bug#[1565](http://bugs.otrs.org/show_bug.cgi?id=1565) - Responsible Agent not updated when creating
    new ticket in phone or email ticket.
 - 2008-06-20 Removed output of linked objects in customer ticket print
    (because it's not needed in the customer panel).
 - 2008-06-19 Fixed bug#[2998](http://bugs.otrs.org/show_bug.cgi?id=2998) - Highlighted selection for notification
    listbox in admin interface.
 - 2008-06-19 Fixed bug#[3005](http://bugs.otrs.org/show_bug.cgi?id=3005) - AJAX functionality is not working in phone
    and email ticket for Service and SLA.
 - 2008-06-19 Added article TimeUnit support to automatically add time
    units to ticket by using generic agent (also usable over admin
    interface).
 - 2008-06-19 Added CleanUp() to Kernel::System::Cache to clean up/remove
    all cache files.
 - 2008-06-19 Fixed bug#[2957](http://bugs.otrs.org/show_bug.cgi?id=2957) - Merged ticket not shown "canceled" in linked
    objects table.
 - 2008-06-19 Simplifed the new link mechanism.
 - 2008-06-19 Added cleanup of old cache files and cleanup of non existing
    TicketIDs in ticket\_watcher and ArticleIDs in article\_flag table (there
    was a bug, this reference entries got not deleted by deleting a ticket
    or article, e. g. by GenericAgent) to scripts/DBUpgrade-to-2.3.pl.
 - 2008-06-13 Added extra config option for "CheckMXRecord" config option
    to configure extra name servers for MX lookups.
 - 2008-06-11 Fixed bug#[2980](http://bugs.otrs.org/show_bug.cgi?id=2980) - Getting cron emails (Use of uninitialized
    value in numeric gt (\>) at) every time if IMAP and IMAPs gets executed.
 - 2008-06-11 Fixed bug#[2979](http://bugs.otrs.org/show_bug.cgi?id=2979) - Unable to work on ticket, get error message
    "no permission" even with rw permissions on the ticket. Fixed recoding
    issue.
 - 2008-06-05 Fixed bug#[2969](http://bugs.otrs.org/show_bug.cgi?id=2969) - Unable to get past login screen - undefined
    value as a HASH reference at
    Kernel/System/Ticket/IndexAccelerator/RuntimeDB.pm line 57.
 - 2008-06-05 Fixed bug#[2960](http://bugs.otrs.org/show_bug.cgi?id=2960) - DBUpdate-to-2.3.pl script possibly fails.
 - 2008-06-05 Added enhancement bug#[2964](http://bugs.otrs.org/show_bug.cgi?id=2964) - Add hash sort to data dumper
    of Kernel::System::Main::Dump to get it better readable and comparable
    (also for diff's).
 - 2008-06-05 Improved Kernel::System::Cache::File, moved cache type files
    to sub directory of tmp/ to tmp/Cache/to have it clear where the cache
    files are.

# 2.3.0 beta2 2008-06-02
 - 2008-06-02 Moved to new link mechanism.
 - 2008-06-02 Fixed bug#[2902](http://bugs.otrs.org/show_bug.cgi?id=2902) - Salutation and Signature examples in the
    admin interface are same.
 - 2008-06-02 Fixed bug#[2940](http://bugs.otrs.org/show_bug.cgi?id=2940) - Error/typo in DBUpdate-to-2.3.\*.sql,
    'escalation\_start\_time' instead of 'escalation\_update\_time' is used.
 - 2008-06-01 Fixed bug#[2956](http://bugs.otrs.org/show_bug.cgi?id=2956) - Not working ticket escalation by using SLAs.
 - 2008-06-01 Added sub sorting to Kernel::System::Ticket::TicketSearch()
    and improved unit test. Example:

```perl
    my @TicketIDs = $Self->{TicketObject}->TicketSearch(
        Result  => 'ARRAY',
        Title   => '%sort/order by test%',
        Queues  => ['Raw'],
        OrderBy => ['Down', 'Down'],
        SortBy  => ['Priority', 'Age'],
        UserID  => 1,
    );
```

 - 2008-05-28 Fixed bug#[2891](http://bugs.otrs.org/show_bug.cgi?id=2891) - Typo in Bounce Customer notification
    'information'.
 - 2008-05-22 Upgraded Mail::Tools from version 2.02 to 2.03 from CPAN.

# 2.3.0 beta1 2008-05-19
 - 2008-05-16 Updated cpan module Text::CSV to the version 1.05.
 - 2008-05-15 Added ticket search close time support to agent ticket search
    and generic agent.
 - 2008-05-15 Reimplmeented "bin/xml2sql.pl", works now with new cmd params.
    Now "-t $DatabaseType", "-n $Name", "-s $SplitInPrePostFiles" and
    "-o $OutputDir".
 - 2008-05-15 Renamed mssql reserved database table word "system\_user" to
    "users". Use scripts/DBUpdate-to-2.3.\*.sql for database upgrade.
 - 2008-05-15 If signing via SMIME fails, we now fall back to the original
     unsigned mailtext instead of sending an empty mail.
 - 2008-05-15 Fixed bug#[2844](http://bugs.otrs.org/show_bug.cgi?id=2844) - Improved robustness of RANDFILE setting for
     openssl (SMIME).
 - 2008-05-15 Refactored SMIME to work on Windows, too.
 - 2008-05-09 Added service \<-\> sla multi relation support.
 - 2008-05-09 Fixed bug#[2448](http://bugs.otrs.org/show_bug.cgi?id=2448) - Not necessary unique check of SLA name.
 - 2008-05-07 Renamed/cleanup of all config setting names for QueueView,
    StatusView and LockedTickets.
 - 2008-05-07 Improved use of existing unique-names in xml definition of
    scripts/database/otrs-schema.xml (not longer auto generated).
 - 2008-05-07 Improved oracle database backend, generation of long
    index/koreign key names, moved from NUMBER to NUMBER(12,0).
 - 2008-05-07 Added some new database indexes to increase the database
    speed (for more info see scripts/DBUpdate\*.sql).
 - 2008-05-07 Added article index support to increase speed of full text
    search up to 50% (need to be configured via SysConfig and
    bin/otrs.RebuildFulltextIndex.pl need to be executed after backend change).
 - 2008-05-07 Added ticket event support for TicketWatch\*() in
    Kernel::System::Ticket. Fixed not removed ticket watch infos after deleting
    a ticket.
 - 2008-05-07 Improved speed of ticket search screen on large installation,
    added cache for database lookup to get all unique ticket free text fields
    (tooks up to 10 sek, on lage installations).
 - 2008-05-02 Deleted textarea wrap in perl code and set browser wrap in dtl files.
 - 2007-04-29 Added X-OTRS-TicketTime and X-OTRS-FollowUp-TicketTime email
    header support as additional attributes like already existing X-OTRS-Header
    (for more info see doc/X-OTRS-Headers.txt).
 - 2007-04-29 Added Format attribute (default html, optional plain) for "Intro\*"
    tags in .sopm files. Format="html" will work as default and it's possible to
    put every html into the intro message. Format="plain" will add automatically
    \<pre\>\</pre\> to intro messages, so new lines and spaces are shown 1:1 in intro
    messages (for more info see developer manual).
 - 2007-04-29 TicketFreeTime, TicketFreeFields and Article Attachments now are
    taken over on ticket split.
 - 2007-04-29 Updated cpan module CGI to version 3.37.
 - 2007-04-25 Added create and drop of index and unique in xml TableAlter tag
    (for more info see developer manual).
 - 2008-04-20 Changed GenericAgent default limit of matching ticket for each
    run of a job from 2000 to 4000.
 - 2008-04-18 Let FrontendOutputFilters have access to LayoutObject and TemplateFile.
 - 2008-04-18 Added Title-Attribute (for Tooltips) to BuildSelection.
 - 2008-04-14 Increased db2 BLOB size from 20M to 30M in
    scripts/database/otrs-schema.db2.sql.
 - 2008-04-14 Improved admin interface, show only links with own permissions.
    So it's possible/easy to create sub admins for part administration
    (Fixed bug#[2535](http://bugs.otrs.org/show_bug.cgi?id=2535) - User is able to access admin menu).
 - 2008-04-14 Improved .opm packages to definde pre and post Code\* and
    Database\* tags to define time point of execution. For more info how to use
    it see developer manual.
 - 2008-04-14 Renamed .opm package tags for intro messages
    Intro(Install|Upgrade|Unintall)(Pre|Post) from \<IntroInstallPost\> to new
    format like \<IntroInstall Type="post"\>. For more info see developer manual.
    Note: Old tags still usable, will be converted by OTRS automatically.
 - 2008-04-10 Added global Search-Condition-Feature (AND/OR/()/!/+) to ticket
    search backend, customer search backend and faq.
 - 2008-04-10 Added support to ticket print to print selected article only.
 - 2008-04-10 Fixed bug#[2159](http://bugs.otrs.org/show_bug.cgi?id=2159) - added ticket close time search option (works
    like ticket create time search option) to agent ticket search screen.
 - 2008-04-10 Updated cpan module CGI to version 3.35.
 - 2008-04-02 Moved from default password 'crypt' method to 'md5'. All new
    changed passwords are stored with md5-password method. Old stored passwords
    still usable.
 - 2008-04-02 Fixed bug#[1952](http://bugs.otrs.org/show_bug.cgi?id=1952) - Superfluous error messages by
   Kernel/Config/Defaults.pm in Debug mode.
 - 2008-04-02 Fixed bug#[2496](http://bugs.otrs.org/show_bug.cgi?id=2496) - HTML formatting in the customer ticket zoom is
    wrong.
 - 2008-04-02 Fixed bug#[1116](http://bugs.otrs.org/show_bug.cgi?id=1116) - Made uses of \<br\\\> and \<input\\\> comply with XHTML.
 - 2008-04-01 Fixed bug#[2575](http://bugs.otrs.org/show_bug.cgi?id=2575) - Trying to Kernel::System::PGP::Crypt()
    utf8-character-strings no longer bails, but simply auto-converts the string
    into an utf8-byte-string, such that the correct data is written into the temp
    file.
 - 2008-04-01 Added new SysLog backend config for log sock. Defaulte use is
    'unix'. On Solaris you may need to use 'stream'.
 - 2008-03-31 Added ticket free time as required field support (works like
    for already existing ticket free text fields).
 - 2008-03-31 Added missing ticket type as required check if ticket type
    feature is enabled.
 - 2008-03-31 Fixed MD5/SHA1 mixups in SMIME handling on older systems (that have
    MD5 as default, not SHA1).
 - 2008-03-27 Added OpenSearchDescription to support "quick" search for
    ticket numbers for browsers like firefox2.
 - 2008-03-26 Added POP3/POP3S/IMAP/IMAPS support for PostMaster sub system
    (new bin/PostMasterMailbox.pl is replacing old bin/PostMasterPOP3.pl).
    Thanks to Igor Stradwo for this patch!
    NOTE: table pop3\_account need to be modified - use scripts/DBUpdate-to-2.3.\*.sql
 - 2008-03-26 Added support of renaming of database tables in XML backend and
    database drivers (Kernel/System/DB/\*.pm).
    Example:

    \<TableAlter NameOld="calendar\_event" NameNew="calendar\_event\_new"/\>

 - 2008-03-25 Added enhancement for agent and customer HTTPBasicAuth to strip
    parts of REMOTE\_USER or HTTP\_REMOTE\_USER by using a regexp. Example to
    strip @example.com of login.
    [Kernel/Config.pm]

```perl
    # In case you need to replace some part of the REMOTE_USER, you can
    # use the following RegExp ($1 will be new login).
    $Self->{'AuthModule::HTTPBasicAuth::ReplaceRegExp'} = '^(.+?)@.+?$';
```
 - 2008-03-21 Added enhancement bug#[2773](http://bugs.otrs.org/show_bug.cgi?id=2773) - HTTPBasicAuth fails when only
    HTTP\_REMOTE\_USER is populated (not REMOTE\_USER).
 - 2008-03-18 Fixed mssql/sybase/freetds database problem
    "Setting of CS\_OPT\_TEXTSIZE failed. at" if a mssql customer backend
    is used. The problem is, that LongReadLen is not supported by
    dbd::sybase (this is the reason of this error message).
    So the database customer is now improved to set all database attributes
    in CustomerUser config. For example this is the solution to prevent
    the sybase error message:

```perl
    $Self->{CustomerUser} = {
        Name   => 'Database Backend',
        Module => 'Kernel::System::CustomerUser::DB',
        Params => {
            DSN       => 'DBI:sybase:yourdsn',
            User      => 'some_user',
            Password  => 'some_password',
            Table     => 'customer_user',
            Attribute => {},
        },
```
For more info see: http://www.perlmonks.org/index.pl?node_id=663835
 - 2008-03-17 Fixed bug#[2197](http://bugs.otrs.org/show_bug.cgi?id=2197) - utf8 problems with auto generated
    Kernel/Config/Files/ZZZAuto.pm and Kernel/Config/Files/ZZZAAuto.pm
    (non ascii signs and utf8 stamps).
 - 2008-03-17 Added ACL example module "CloseParentAfterClosedChilds" which
    allows you to not close parent tickets till all childs are closed (
    configuable via SysConfig -\> Ticket -\> Core::TicketACL).
 - 2008-03-17 Improved ticket zoom view, shown linked objects (only show link
    types (Normal/Child/Parent) if links are available).
 - 2008-03-16 Improved ticket zoom view, shown plain link to emails (per
    default, can be enabled via sys config) and improved shown linked/merged
    tickets.
 - 2008-03-09 Improved API of Cache core module (Kernel::System::Cache), added
    type param to define the type of cached object/data (so also a better
    storage is possible because you can manage each cache type object/data it
    self, e. g. if file system backend is used in differend sub directories).

API Example (old):
```perl
        $CacheObject->Set(
            Key   => 'SomeKey',
            Value => 'Some Value',
            TTL   => 24*60*60,     # in sec. in this case 24h
        );
```
API Example (new):
```perl
        $CacheObject->Set(
            Type  => 'ObjectName', # only A-z chars usable
            Key   => 'SomeKey',
            Value => 'Some Value',
            TTL   => 24*60*60,     # in sec. in this case 24h
        );
```
 - 2008-03-06 Fixed use of uninitialized value in Log.pm (visible when
    executed in ModPerl environment).
 - 2008-03-02 Added title of object to div tag of linked objects to have an
    preview to the content of a linked object.
 - 2008-03-01 Added missing ticket title to ticket search mask in agent
    and generic agent interface.
 - 2008-02-17 Removed not needed Encode::decode\_utf8() in core module
    Kernel::System::Encode (only set if utf-8 stamp is needed).
 - 2008-02-17 Upgraded Mail::Tools from version 1.77 to 2.02 from CPAN.
 - 2008-02-12 Fixed bug#[2670](http://bugs.otrs.org/show_bug.cgi?id=2670) - "wide character" error when login with
    russian password.
    Note: It could be on older systems, that existing passwords are not
    longer valid. Just reset the password and everything will work fine.
 - 2008-02-12 Fixed bug#[1996](http://bugs.otrs.org/show_bug.cgi?id=1996) - Replaced 'U' & 'D' with respective arrow
    icons.
 - 2008-02-12 Improved Fix for bug#[1608](http://bugs.otrs.org/show_bug.cgi?id=1608) - Badly formatted calendar popup.
    Now the table width is explicity passed into DTL from the perl module
    and the customer calendar view has been fixed, too.
 - 2008-02-11 Added queue preferences - module support like for agents and
    customer to create easier extentions/addons for queues.
    See Developer-Manual for more information.
    NOTE: table sla need to be modified - use scripts/DBUpdate-to-2.3.\*.sql
 - 2008-02-11 Added escalation warning feature. So agents will be notified
    before a ticket will escalate. This time point can be configured in the
    admin interface for queue and sla settings.
    NOTE: table queue need to be modified - use scripts/DBUpdate-to-2.3.\*.sql
 - 2008-02-04 Fixed bug#[1608](http://bugs.otrs.org/show_bug.cgi?id=1608) - Badly formatted calendar popup.
 - 2008-02-04 Fixed bug#[2657](http://bugs.otrs.org/show_bug.cgi?id=2657) - Improved regexp in RPM spec files to detect
    already existing "otrs" user (it was also matching on xxxotrsxxx names).
 - 2008-01-28 Added note permission "note" to default ticket permissions to
    manage list of inform involved agents out of the box.
 - 2008-01-24 Fixed bug#[2611](http://bugs.otrs.org/show_bug.cgi?id=2611) - PGP module not working on Windows platform.
 - 2008-01-15 Fixed bug#[2227](http://bugs.otrs.org/show_bug.cgi?id=2227) - XMLHashSearch returns no values on MS SQL in
    certain cases.
 - 2008-01-08 Added expand/collapse option to ticket zoom.
 - 2008-01-08 Added multi attachment support to ticket move screen.
 - 2008-01-08 Added AJAX support in email ticket.
 - 2008-01-03 Changed default session settings SessionMaxTime from 14h to
    16h and SessionMaxIdleTime from 5h to 6h.
 - 2008-01-02 Improved ticket zoom view, removed plain-text attachments
    of html with plain attachment emails.
 - 2008-01-02 Fixed bug#[2600](http://bugs.otrs.org/show_bug.cgi?id=2600) - MS SQL: Fulltext search in ticket body with
    mssql backend not possible (improved Kernel::System::DB API with database
    preferences option "NoLikeInLargeText").
 - 2007-12-28 Improved config file mechanism generated by SysConfig to improve
    speed in `mod_perl` is used (about 0.2%-4% speed improvement, depends
    on which shown site).
    Note: Kernel/Config/Files/ZZZAuto.pm and Kernel/Config/Files/ZZZAAuto.pm
    generated by OTRS 2.3 or higher is not longer compat. to OTRS 2.2 and
    lower. But OTRS 2.3 or higher can read config files from OTRS 2.2 and
    lower.
 - 2007-12-27 Fixed bug#[2596](http://bugs.otrs.org/show_bug.cgi?id=2596) - Problems to download file from
    Action=AdminPackageManager with IE and Safari.
 - 2007-12-27 Improved way how to reset a password. Added password reset
    via token (email which needs to be accepted by new password requester
    first).
 - 2007-12-21 Added possiblity to use options of StringClean() in GetParam()
    and GetArray() functions.
 - 2007-12-21 Add StringClean() function to improve quality of strings.
 - 2007-12-19 Improved installer description to prevent bugs like bug#[2492](http://bugs.otrs.org/show_bug.cgi?id=2492).
 - 2007-12-17 Fixed bug#[2586](http://bugs.otrs.org/show_bug.cgi?id=2586) - File download of package in
    AdminPackageManager is not delivering the whole file name anymore.
 - 2007-12-17 Fixed bug#[2539](http://bugs.otrs.org/show_bug.cgi?id=2539) - SMIME signing was broken for private keys that
    have no passphrase and when openssl is unable to write to random state file.
 - 2007-12-11 Fixed bug#[2479](http://bugs.otrs.org/show_bug.cgi?id=2479) - Unable to retrieve attachments bigger than
    3Mb (on Oracle DB). Changed default read size from 4 MB to 40 MB in
    Kernel/System/DB/oracle.pm:

```perl
    $Self->{'DB::Attribute'}      = {
        LongTruncOk => 1,
        LongReadLen => 40 * 1024 * 1024,
    };
```
 - 2007-12-10 Updated MIME::Tools to current CPAN version 5.425.
 - 2007-12-06 Fixed bug#[2568](http://bugs.otrs.org/show_bug.cgi?id=2568) - Problems with attachment downloads if the
    active element filter is enabled.
 - 2007-12-05 Fixed bug#[1399](http://bugs.otrs.org/show_bug.cgi?id=1399) - Missing Translation. Added some translation to
    customer interface.
 - 2007-12-04 Fixed bug#[2257](http://bugs.otrs.org/show_bug.cgi?id=2257) - Silent ignorance of SMTP / Sendmail errors,
    now we collect the error and log it (which in turn displays it to the user).
 - 2007-11-20 Rewrite of Kernel::System::CSV by using cpan module Text::CSV
    for parsing and generating CSV files (added Text::CSV to
    bin/otrs.checkModules to check it).
 - 2007-11-07 Changed default config of WebMaxFileUpload from 10 MB to
    16 MB.
 - 2007-11-07 Changed Kernel::System::Crypt::PGP to reject any UTF8-strings,
    as these would get autoconverted into ISO - thus garbling the result.
    Currently, only binary octets and ISO-strings are supported as input.
 - 2007-10-25 Improved Kernel::System::Crypt::PGP to return information about
    the PGP-keys that were actually used in Decrypt() and Verify().
 - 2007-10-25 Updated all cpan modules.
 - 2007-10-17 Added GroupLookup() and RoleLookup() to Group.pm and removed the
    two methods GetGroupIdByName() and GetRoleIdByName() which were already marked
    as deprecated.
 - 2007-10-08 Added support of ticket free text links in ticket view,
    configurable via SysConfig.
 - 2007-10-05 Added fist version of AJAX framework support in phone ticket.
 - 2007-10-01 Added \<ModuleRequired Version="0.01"\>SomeModule\</ModuleRequired\>
    feature to .opm format for enforcing installed CPAN modules.
 - 2007-09-25 Fixed bug#[2312](http://bugs.otrs.org/show_bug.cgi?id=2312) - Wide character error in Layout.pm if system
    runs in utf-8 mode.
 - 2007-09-18 Did some improvments in Kernel/Output/HTML/Layout.pm to
    get an better performance if the block function is used many times
    (e. g. \> 1000 times, 30% faster).
 - 2007-09-13 Fixed bug#[1186](http://bugs.otrs.org/show_bug.cgi?id=1186) - Convertion from HTML to text incomplete
    if html encoded chars like &Egrave; or &eacute; is used. Added full
    HTML to text convertion to email parser.
 - 2007-09-13 Improved report overview of perfornance log.

# 2.2.9 2010-02-08
 - 2010-06-24 Fixed bug#[5497](http://bugs.otrs.org/show_bug.cgi?id=5497) - Missing HTML quoting in stats module.
 - 2010-02-04 Fixed SQL quoting issue (see also
    http://otrs.org/advisory/OSA-2010-01-en/).

# 2.2.8 2008-08-25
 - 2008-08-12 Fixed bug#[3156](http://bugs.otrs.org/show_bug.cgi?id=3156) - When the "EMAILADDRESS:" attribute is used to
    define a specific email address, then secodary match attributes are applied
    to all mails.
 - 2008-07-20 Fixed bug#[3155](http://bugs.otrs.org/show_bug.cgi?id=3155) - Wrong header charset in lost password
    notification.
 - 2008-07-20 Fixed bug#[3103](http://bugs.otrs.org/show_bug.cgi?id=3103) - CustomerInterface: Ticket of other customers
    accessible for other customers.
 - 2008-07-18 Fixed bug#[3101](http://bugs.otrs.org/show_bug.cgi?id=3101) - Getting Queue view after adding a note with
    state "open".
 - 2008-07-18 Fixed reopend bug#[2330](http://bugs.otrs.org/show_bug.cgi?id=2330) - Cron.sh restart \<OTRS\_USER\> doesn't
    work.
 - 2008-07-16 Fixed bug#[2967](http://bugs.otrs.org/show_bug.cgi?id=2967) - Stats module, illegal division by zero at
    ../../Kernel/System/Stats.pm line 1581
 - 2008-07-16 Fixed bug#[3079](http://bugs.otrs.org/show_bug.cgi?id=3079) - Default CheckEmailInvalidAddress regexp
    rejects mail to MobileMe (me.com) accounts.
 - 2008-07-08 Fixed bug#[3062](http://bugs.otrs.org/show_bug.cgi?id=3062) - Not possible to search for Customer Company
 - 2008-06-25 Increaded max size of reformated text (reformating new lines)
    from 20,000 to 60,000 signs (this size is just a safety performance
    setting in Kernel::Output::HTML::Layout::Ascii2Html()).
 - 2008-06-20 Fixed bug#[3000](http://bugs.otrs.org/show_bug.cgi?id=3000) - Configured sender address for auto response
    get's ignored.
 - 2008-06-05 Fixed bug#[2962](http://bugs.otrs.org/show_bug.cgi?id=2962) - Freetext cache problem, old used ticket
    free text values get not added to pull down list in agent ticket search.
 - 2008-06-04 Removed not wanted email rfc check in AgentTicketPhone and
    AgentTicketEmail, it's already done by OTRS via config settings.

# 2.2.7 2008-06-04
 - 2008-05-28 Fixed bug#[2891](http://bugs.otrs.org/show_bug.cgi?id=2891) - Typo in Bounce Customer notification
    'information'.
 - 2008-05-25 Fixed bug#[2934](http://bugs.otrs.org/show_bug.cgi?id=2934) - PostmasterPOP3.pl - craches on malformed UTF-8
    character (fatal)... on incoming emails.
 - 2008-05-22 Fixed bug#[2829](http://bugs.otrs.org/show_bug.cgi?id=2829) - Added config option if Cc should be taken over
    to Cc recipients list in compose email answer screen.
    SysConfig -\> Ticket -\> Frontend::Agent::Ticket::ViewCompose -\>
    Ticket::Frontend::ComposeExcludeCcRecipients
 - 2008-05-15 Fixed bug#[2870](http://bugs.otrs.org/show_bug.cgi?id=2870) - Customer-Frontend: No Access to Company Tickets
    (CustomerIDCheck fails).
 - 2008-05-09 Added new catalonian language translation, thanks to Antonio Linde!
 - 2008-05-08 Fixed bug#[2683](http://bugs.otrs.org/show_bug.cgi?id=2683) -
 ```$QData{"OrigFrom"}``` in Reply leads to wrong
    quote in email answer if sender is agent (To of origin email is used).
 - 2008-05-08 Fixed bug#[2604](http://bugs.otrs.org/show_bug.cgi?id=2604) - Response Format - Date of Original Mail is
    missing.
 - 2008-05-07 Fixed bug#[2882](http://bugs.otrs.org/show_bug.cgi?id=2882) - The foreign key syntax in
    otrs-schema-post.mysql.sql is incorrect.
 - 2008-04-23 Fixed bug#[2907](http://bugs.otrs.org/show_bug.cgi?id=2907) - Typo in the german translation:
    "aktuallisiert".
 - 2008-04-19 Fixed not removable ticket by acl watcher link in ticket menu
    (added missing config param to Ticket.xml config file).
 - 2008-04-14 Improved speed of phone and email ticket if many queues and
    groups (150+) are used.
 - 2008-04-14 Improved load speed of ticket search screen (if free text fields
    are used).
 - 2008-04-14 Fixed bug#[2860](http://bugs.otrs.org/show_bug.cgi?id=2860) - ColumnAdd doesn't work on a DB2 database if
    Required is true.
 - 2008-04-10 Added new estonian translation, thanks to Lauri Jesmin!
 - 2008-04-07 Fixed bug#[2814](http://bugs.otrs.org/show_bug.cgi?id=2814) - BCC emails are visible to all receipiants in
    email header.
 - 2008-04-07 Fixed bug#[2829](http://bugs.otrs.org/show_bug.cgi?id=2829) - Local system email address is always set to CC
    option in compose email answer screen.
 - 2008-04-07 Fixed bug#[2833](http://bugs.otrs.org/show_bug.cgi?id=2833) - Broken email attachments if only attachment is
    in email (no mime attachments).
 - 2008-04-03 Fixed bug#[2828](http://bugs.otrs.org/show_bug.cgi?id=2828) - Strings like ftp.invalid.org are shown as http
    link in TicketZoom.
 - 2008-04-02 Fixed bug#[2756](http://bugs.otrs.org/show_bug.cgi?id=2756) - "http." in article body is displayed as
    "http://http.".
 - 2008-04-01 Fixed bug#[2822](http://bugs.otrs.org/show_bug.cgi?id=2822) - Ticket Number in subject of Bounce Notification
    to customer/sender is not shown.
 - 2008-04-01 Fixed bug#[2453](http://bugs.otrs.org/show_bug.cgi?id=2453) - syntax errors on customer search; name@host
    problems the mail address parser does not recognize the email address if it
    is not fully 2822 compilant.

# 2.2.6 2008-03-31
 - 2008-03-25 Fixed bug#[2732](http://bugs.otrs.org/show_bug.cgi?id=2732) - Service name is truncated in dropdown lists
 - 2008-03-21 Fixed bug#[2758](http://bugs.otrs.org/show_bug.cgi?id=2758) - non-latin filenames in emails get not converted
    to utf8 (e. g. koi8-r, utf8, cp1251).
 - 2008-03-21 Fixed bug#[2781](http://bugs.otrs.org/show_bug.cgi?id=2781) - Typo in Kernel::System::Ticket::MoveTicket()
   "&" instead of "&&".
 - 2008-03-20 Fixed bug#[2772](http://bugs.otrs.org/show_bug.cgi?id=2772) - Dangling links to deleted tickets (ticket
    links get not deleted after a ticket got deleted).
 - 2008-03-14 Fixed bug#[2770](http://bugs.otrs.org/show_bug.cgi?id=2770) - Internal cache mechanism of SLAs delivers
    wrong content.
 - 2008-03-14 Fixed bug#[2769](http://bugs.otrs.org/show_bug.cgi?id=2769) - Trimming of sla name input field produce
    errors.
 - 2008-03-14 Fixed bug#[954](http://bugs.otrs.org/show_bug.cgi?id=954) - ticket split should linking tickets (origin to
    new one).
 - 2008-03-13 Added new turkish translation, thanks to Necmettin Begiter!
 - 2008-03-11 Fixed bug#[2763](http://bugs.otrs.org/show_bug.cgi?id=2763) - Trimming of service name input field produce
    errors.
 - 2008-03-10 Updated vietnam translation, thanks to Nguyen Nguyet. Phuong!
 - 2008-03-10 Fixed bug#[2757](http://bugs.otrs.org/show_bug.cgi?id=2757) - Can't download statistic graph if I use
    a diagram as output format.
 - 2008-03-10 Fixed bug#[2717](http://bugs.otrs.org/show_bug.cgi?id=2717) - All column and row names will be translated
    statistics. Additional fixes for special situations.
 - 2008-03-06 Fixed bug#[2737](http://bugs.otrs.org/show_bug.cgi?id=2737) - Wrong order of the xaxis in stats output.
 - 2008-03-06 Fixed bug#[2717](http://bugs.otrs.org/show_bug.cgi?id=2717) - All column and row names will be translated.
 - 2008-03-05 Fixed bug#[2715](http://bugs.otrs.org/show_bug.cgi?id=2715) - Ascii2Html() is not quoting all links
    correctly.
 - 2008-03-03 Fixed bug#[2742](http://bugs.otrs.org/show_bug.cgi?id=2742) - Wrong content type in admin package manager
    mask.
 - 2008-02-25 Added missing german translation for required free-text fields.
 - 2008-02-25 Fixed bug#[2451](http://bugs.otrs.org/show_bug.cgi?id=2451) - Typo in openssl invocation when decrypting.
 - 2008-02-23 Fixed bug#[2275](http://bugs.otrs.org/show_bug.cgi?id=2275) - Need User or UserID! by using UnlockTickets.pl
    and PendingJobs.pl.
 - 2008-02-23 Fixed bug#[2696](http://bugs.otrs.org/show_bug.cgi?id=2696) - CustomerPanelOwnSelection and
    CustomerGroupSupport does not work together (show also queues without
    create permissions).
 - 2008-02-23 Fixed bug#[2544](http://bugs.otrs.org/show_bug.cgi?id=2544) - Customer with RO can update ticket in
    customer panel (wrong SysConfig setting).
 - 2008-02-22 Fixed bug#[2650](http://bugs.otrs.org/show_bug.cgi?id=2650) - Mails not full imported by PostmasterPOP3.pl
    (mail body is cutted off, if no content type is availabe but 8bit chars are
    used).
 - 2008-02-22 Fixed bug#[2462](http://bugs.otrs.org/show_bug.cgi?id=2462) - Permission denied when trying to print ticket
    details from customer panel (customer.pl).
 - 2008-02-21 Added sendmail dummy backend module to deactivate sending
    emails, useful for test system (Kernel::System::Email::DoNotSendEmail).
 - 2008-02-20 Fixed bug#[2644](http://bugs.otrs.org/show_bug.cgi?id=2644) - Added unit tests to find easier wrong
    configured GD-CPAN modules.
 - 2008-02-20 Fixed bug#[2706](http://bugs.otrs.org/show_bug.cgi?id=2706) - SysConfig setting LogSystemCacheSize causes
    error messages.
 - 2008-02-19 Fixed bug#[2450](http://bugs.otrs.org/show_bug.cgi?id=2450) - Auto-conversion of URLs to links fail when
    a ')' is encountered.
 - 2008-02-18 Fixed bug#[2541](http://bugs.otrs.org/show_bug.cgi?id=2541) - Missing "Ticket unlock" link for ticket the
    actions 'Phone call', 'Merge', 'Move' and 'Forward'.
 - 2008-02-18 Fixed bug#[2145](http://bugs.otrs.org/show_bug.cgi?id=2145) - $Config{"TicketFreeTimeKey22"} instant of
    $Config{"TicketFreeTimeKey2"} in AgentTicketSearchResultShort.dtl.
 - 2008-02-18 Fixed bug#[2674](http://bugs.otrs.org/show_bug.cgi?id=2674) - Spellchecker always reports 0 errors
    even SpellCheckerBin is not configured correctly.
 - 2008-02-17 Improved bin/otrs.checkModules tool for checking required
    CPAN modules.
 - 2008-02-17 Fixed bug#[2255](http://bugs.otrs.org/show_bug.cgi?id=2255) - SysConfig setting Ticket -\>
    Frontend::Customer::Ticket::ViewZoom -\>
    Ticket::Frontend::CustomerTicketZoom###State has no effect (only
    closed is shown any time).
 - 2008-02-15 Fixed non fixed font and wrong new line breaking problem on
    safari in textarea input fields (updated Kernel/Output/HTML/Standard/css.dtl
    and Kernel/Output/HTML/Standard/customer-css.dtl).
 - 2008-02-15 Fixed bug#[2694](http://bugs.otrs.org/show_bug.cgi?id=2694) - URL-to-long-error in
    AdminCustomerUserService mask on changing settings.
 - 2008-02-14 Fixed bug#[2239](http://bugs.otrs.org/show_bug.cgi?id=2239) - CustomerCompanySupport is broken when
    using external backend DB.
 - 2008-02-12 Fixed bug#[2533](http://bugs.otrs.org/show_bug.cgi?id=2533) - Wide character error when searching for a
    customer with umlaut in LDAP backend with cache option (CacheTTL) in
    CustomerUser config option.
 - 2008-02-12 Fixed bug#[2638](http://bugs.otrs.org/show_bug.cgi?id=2638) - Broken email syntax check if
    \_somebody@example.com is used.
 - 2008-02-12 Fixed bug#[1957](http://bugs.otrs.org/show_bug.cgi?id=1957) - Auto reply for new Phone-Tickets goes to
    non-existing addresses (if no email address is given in From field).
 - 2008-02-12 Fixed bug#[2363](http://bugs.otrs.org/show_bug.cgi?id=2363) - AgentTicketPhone###Body is now a text area
    instead of a string.
 - 2008-02-11 Fixed bug#[1975](http://bugs.otrs.org/show_bug.cgi?id=1975) - OTRS cannot forward tickets with .eml file
    attachments.
 - 2008-02-11 Fixed bug#[2413](http://bugs.otrs.org/show_bug.cgi?id=2413) - OTRS cannot write to BLOB column in table
    XML\_STORAGE with DB2.
 - 2008-02-06 Fixed bug#[1716](http://bugs.otrs.org/show_bug.cgi?id=1716) - Wrong escalation time calculation on
    wintertime/summertime switch.
 - 2008-02-01 Fixed ticket# 2008012242000417 - View performance problems
    if more than 1000 customer companies are in the database available.

# 2.2.5 2008-01-28
 - 2008-01-25 Fixed bug#[2645](http://bugs.otrs.org/show_bug.cgi?id=2645) - SLA selection doesn't change when customer is
    changed.
 - 2008-01-16 Fixed bug#[2157](http://bugs.otrs.org/show_bug.cgi?id=2157) - Ticket merged note not translated.
 - 2008-01-15 Fixed bug#[2392](http://bugs.otrs.org/show_bug.cgi?id=2392) - Charset problems with iso8859 and the
    xml-caching mechanism.
 - 2008-01-15 Implemented workaround for bug#[2227](http://bugs.otrs.org/show_bug.cgi?id=2227) - XMLHashSearch returns
    no values on MS SQL in certain cases.
 - 2008-01-14 Fixed bug#[2330](http://bugs.otrs.org/show_bug.cgi?id=2330) - Cron.sh start \<OTRS\_USER\> does not work.
    Thanks to Felix J. Ogris.
 - 2008-01-14 Fixed bug#[977](http://bugs.otrs.org/show_bug.cgi?id=977) - No agent notification for new ticket from
    webinterface if CustomerGroupSupport is enabled.
 - 2008-01-13 Added new vietnam translation, thanks to Nguyen Nguyet. Phuong!
 - 2008-01-13 Fixed bug#[2621](http://bugs.otrs.org/show_bug.cgi?id=2621) - Wrong order of items (Subject,Service,SLA,Body
    -\> Service,SLA,Subject,Body) in Frontend AgentTicketPhone, AgentTicketEmail
    and CustomerTicketMessage.
 - 2008-01-12 Fixed bug#[1687](http://bugs.otrs.org/show_bug.cgi?id=1687) - Wrong "New message!" hint on queue with
    "Customer State Notify" activated.
 - 2008-01-09 Fixed bug#[2613](http://bugs.otrs.org/show_bug.cgi?id=2613) - Images are broken in Lite-Theme if OTRS do
    not use the default Alias /otrs-web/.
 - 2008-01-08 Improved Kernel::System::XML::XMLParse() to prevent bugs
    like# 2612.
 - 2008-01-08 Fixed bug#[2609](http://bugs.otrs.org/show_bug.cgi?id=2609) - Temp files are not removed after process was
    finished under windows.
 - 2008-01-07 Fixed bug#[1893](http://bugs.otrs.org/show_bug.cgi?id=1893) - Attachment Storage fails with
    ArticleStorageFS in win32 with ? in filenames.
 - 2008-01-03 Fixed bug#[2491](http://bugs.otrs.org/show_bug.cgi?id=2491) - OTRS crash's after initial login on fresh
    installation on fedora 7, fedora 8, altlinux and ActiveState Perl on win32.
 - 2008-01-02 Fixed bug#[2601](http://bugs.otrs.org/show_bug.cgi?id=2601) - Only agents with rw permissions are shown in
    inform agent selection of a note screen (note permission need to be
    activated via SysConfig first). Now all agents with \_note\_ permissions are
    displayed.
 - 2008-01-02 Fixed bug#[2600](http://bugs.otrs.org/show_bug.cgi?id=2600) - MS SQL: Fulltext search in ticket body with
    mssql backend not possible (workaround, improved API for 2.3.x).
 - 2008-01-01 Fixed bug#[1120](http://bugs.otrs.org/show_bug.cgi?id=1120) - TO recipients which were sometimes dropped
    in a ticket reply.
 - 2008-01-01 Fixed bug#[2589](http://bugs.otrs.org/show_bug.cgi?id=2589) - Ticket-title not shown in ticket list of
    change customer, phone- and email ticket.
 - 2007-12-27 Fixed bug#[1148](http://bugs.otrs.org/show_bug.cgi?id=1148) - Lost of attachments when spliting ticket.
 - 2007-12-18 Fixed bug#[2295](http://bugs.otrs.org/show_bug.cgi?id=2295) - Added workaround for IE7. Tries to download
    [ Attachments ] or [ Attachments \<-\> Responses ].
 - 2007-12-17 Fixed bug#[2580](http://bugs.otrs.org/show_bug.cgi?id=2580) - Wrong quoating of semicolon if mssql is used.
 - 2007-12-17 Fixed bug#[2539](http://bugs.otrs.org/show_bug.cgi?id=2539) - SMIME signing was broken for private keys that
   have no passphrase and when openssl is unable to write to random state file.
 - 2007-12-12 Fixed bug#[2581](http://bugs.otrs.org/show_bug.cgi?id=2581) - Follow up not possible if "ticket#: xxxxxxx"
    is copied from webinterface into new email subject.
 - 2007-12-11 Fixed bug#[2479](http://bugs.otrs.org/show_bug.cgi?id=2479) - Unable to retrieve attachments bigger than
    3 MB (on Oracle DB). Changed default read size from 4 MB to 15 MB in
    Kernel/System/DB/oracle.pm:

```perl
      $Self->{'DB::Attribute'}      = {
        LongTruncOk => 1,
        LongReadLen => 15 * 1024 * 1024,
    };
```
 - 2007-12-10 Fixed bug#[1428](http://bugs.otrs.org/show_bug.cgi?id=1428) - Whitespaces remove from email subject
    (notification and new tickets creation) if utf-8 is used (specifically
    in Russian, Chinese  and Japanese).
    The problem is a bug in MIME::Tools/MIME::Words, for more info see
    CPAN-Bug# 5462: http://rt.cpan.org/Public/Bug/Display.html?id=5462
    As solution Kernel/cpan-lib/MIME/Words.pm got patched. Note: Everybody
    who is not using Kernel/cpan-lib/ need to wait till this bug is fixed
    in official MIME::Tools/MIME::Words releases.
 - 2007-12-10 Fixed bug#[2166](http://bugs.otrs.org/show_bug.cgi?id=2166) - Probem with HTML-mails sent by MS Outlook
    2003 - "&#8211;" / long dash gets not decoded.
 - 2007-12-10 Fixed bug#[2377](http://bugs.otrs.org/show_bug.cgi?id=2377) - Missing translation in
    AdminCustomerUserService mask.
 - 2007-12-03 Fixed bug#[2537](http://bugs.otrs.org/show_bug.cgi?id=2537) - Unable to set free time fields.
 - 2007-11-13 Fixed bug#[2498](http://bugs.otrs.org/show_bug.cgi?id=2498) - A wrong sum of requests was shown in the
    performance log.
 - 2007-11-07 Fixed bug#[2482](http://bugs.otrs.org/show_bug.cgi?id=2482) - IntroUpgradePre in .opm files is not working
    on upgradinging via online repository.

# 2.2.4 2007-11-06
 - 2007-11-06 Fixed bug#[2477](http://bugs.otrs.org/show_bug.cgi?id=2477) - Escalation time calculation (destination time of
    escalation) is not working if host system is running in summertime/wintertime
    mode (loops because system is changing system time from 3:00 am to 2:00 am).
 - 2007-11-05 Fixed bug#[2474](http://bugs.otrs.org/show_bug.cgi?id=2474) - Config option UserSyncLDAPAttibuteGroupsDefination
    and UserSyncLDAPAttibuteRolesDefination is not working.
 - 2007-11-05 Fixed small typo in scripts/database/otrs-initial\_insert.xml, for
    escalation notification text.
 - 2007-11-05 Fixed bug#[2473](http://bugs.otrs.org/show_bug.cgi?id=2473) - Not able to update existing cache files of
    customer user backend because of file permission problems (cache files are
    created with 644). From now on cache files are created with 664 permissions.
 - 2007-11-05 Fixed bug#[2472](http://bugs.otrs.org/show_bug.cgi?id=2472) - Emails in utf8 are not sent correctly (problem
    after upgrading Kernel/cpan-lib/MIME/\*.pm).
 - 2007-10-26 Fixed bug#[2446](http://bugs.otrs.org/show_bug.cgi?id=2446) - Subject is not quoted.
 - 2007-10-26 Fixed bug#[2442](http://bugs.otrs.org/show_bug.cgi?id=2442) - Disappearing ticket free time checkboxes in
    some ticket masks after mask reloads.
 - 2007-10-26 Fixed bug#[2436](http://bugs.otrs.org/show_bug.cgi?id=2436) - Translation bug in the frontend function
    BuildSelection().
 - 2007-10-24 Fixed bug#[2289](http://bugs.otrs.org/show_bug.cgi?id=2289) - Compress with bzip2 dont works in backup.pl.
 - 2007-10-22 Fixed bug#[2421](http://bugs.otrs.org/show_bug.cgi?id=2421) - If customer cache backend is used, sometimes
    "Need Value" appears in the log file.
 - 2007-10-19 Fixed bug#[1203](http://bugs.otrs.org/show_bug.cgi?id=1203) - Changed Redhat shm workaround to use a fixed
    IPCKey per instance, but prevent clash with IPCKey of other instances.
 - 2007-10-19 Fixed bug#[2263](http://bugs.otrs.org/show_bug.cgi?id=2263) - Problems with array refs and escaping
 - 2007-10-18 Fixed bug#[2410](http://bugs.otrs.org/show_bug.cgi?id=2410) - $/ as given is currently unsupported at
    Kernel/cpan-lib/MIME/Decoder/NBit.pm line 140. We updated the CPAN module
    MIME-tools to version 5.423 to solve the problem.
 - 2007-10-17 Fixed bug#[2404](http://bugs.otrs.org/show_bug.cgi?id=2404) - Wrong results if you use StatsTypeID as
    TicketSearch attribute.
 - 2007-10-17 Fixed bug#[2407](http://bugs.otrs.org/show_bug.cgi?id=2407) - Performance handicap because of a missing
    'if'-attribute.
 - 2007-10-16 Improved performance of module by reduce calls of
    $Self-\>{ConfigObject}-\>Get() in Kernel/Output/HTML/Layout.pm and
    Kernel/System/Encode.pm.
 - 2007-10-16 Fixed bug#[2404](http://bugs.otrs.org/show_bug.cgi?id=2404) - Problems with the time extended feature in
    stats module.
 - 2007-10-15 Fixed bug#[2398](http://bugs.otrs.org/show_bug.cgi?id=2398) - Translate the stats output.
 - 2007-10-12 Fixed bug#[2388](http://bugs.otrs.org/show_bug.cgi?id=2388) - Show the radio button of static stats files.
 - 2007-10-10 Fixed bug#[2383](http://bugs.otrs.org/show_bug.cgi?id=2383) - IntroInstallPre in .opm files is not working
    on installing via online repository.
 - 2007-10-10 Fixed bug#[2380](http://bugs.otrs.org/show_bug.cgi?id=2380) - Ignore HTMLQuote param in Layout object
    function \_BuildSelectionOptionRefCreate.
 - 2007-10-09 Fixed bug#[2375](http://bugs.otrs.org/show_bug.cgi?id=2375) - Possible race condition in generic agent
    jobs (during processing jobs). Generic agent job attributes can get
    lost.
 - 2007-10-09 Fixed bug#[2276](http://bugs.otrs.org/show_bug.cgi?id=2276) - GenericAgent with SLA-Search fails, Service
    and SLA options are missing.
 - 2007-10-05 Fixed bug#[2360](http://bugs.otrs.org/show_bug.cgi?id=2360) - No Permission in customer panel after
    selecting ticket. Reason is, sender type is customer and article
    type is email-internal which is set via a postmaster filter.
 - 2007-10-02 Fixed bug#[2346](http://bugs.otrs.org/show_bug.cgi?id=2346) - Emty entries are shown in the responsible
    option list in TicketSearch mask.
 - 2007-09-24 Fixed bug#[2321](http://bugs.otrs.org/show_bug.cgi?id=2321) - It's not possible to use ï¿½ or ï¿½ in
    description tag of .sopm file -\> leading to perl syntax error!
 - 2007-09-17 Fixed bug#[2291](http://bugs.otrs.org/show_bug.cgi?id=2291) - Only include/use PDF::API2 in
    Kernel/Modules/AgentTicketSearch.pm and Kernel/Modules/AgentStats.pm
    if needed, to increase performance.

# 2.2.3 2007-09-13
 - 2007-09-13 Fixed bug#[2285](http://bugs.otrs.org/show_bug.cgi?id=2285) - Typo in german translation
    "Aktualisierungszeit".
 - 2007-09-12 Fixed bug#[1203](http://bugs.otrs.org/show_bug.cgi?id=1203) - Redhat shm workaround should not relate to
    real shm request.
 - 2007-09-07 Fixed bug#[2265](http://bugs.otrs.org/show_bug.cgi?id=2265) - On IIS6, Package Manager is displaying a
    error after installing a package (header not complete). But package got
    installed corectly.
 - 2007-09-06 Fixed bug#[2261](http://bugs.otrs.org/show_bug.cgi?id=2261) - False params in call of ServiceLookup() and
    SLALookup() functions.
 - 2007-09-06 Fixed reopened bug#[2142](http://bugs.otrs.org/show_bug.cgi?id=2142) - Ticket history entry was wrong if
    service, sla or ticket type was changed.
 - 2007-09-03 Fixed bug#[2193](http://bugs.otrs.org/show_bug.cgi?id=2193) - Postmaster module
    Kernel::System::PostMaster::Filter::NewTicketReject is not working - need
    Charset!
 - 2007-09-03 Fixed bug#[2245](http://bugs.otrs.org/show_bug.cgi?id=2245) - Responsible / Owner Field not working for
    all users in the Email-Ticket form.
 - 2007-09-03 Improved system speed of escalation calculation if many open
    ticket (\> 2000) are there.
 - 2007-08-28 Fixed Ticket# 2007082842000477 - Problem with different customer
    sources and use CacheTTL option (namespace of cache is not uniq).
 - 2007-08-28 Fixed Ticket# 2007082842000413 - Ticket created over phone
    ticket with state closed is shown in queue view like "My Queues (1)" but
    no ticket is shown if I click on "My Queues (1)" (if
    Kernel::System::Ticket::IndexAccelerator::StaticDB is used as
    Ticket::IndexModule).
 - 2007-08-27 Fixed bug#[2230](http://bugs.otrs.org/show_bug.cgi?id=2230) - OTRS on IIS - redirect/loop problem after
    login.
 - 2007-08-27 Fixed bug#[2229](http://bugs.otrs.org/show_bug.cgi?id=2229) - Return value of "ServiceLookup" is used
    without quoting in SQL statements.
 - 2007-08-24 Fixed bug#[2207](http://bugs.otrs.org/show_bug.cgi?id=2207) - translation failure in customer preferences
    (QueueView refresh time).
 - 2007-08-24 Fixed bug#[2214](http://bugs.otrs.org/show_bug.cgi?id=2214) - .opm Package can not handle &lt;, &gt; and
    &amp; in .sopm files.
 - 2007-08-22 Improved Agent Notifications. Salutation of notfication
    recipient is now using \<OTRS\_UserFirstname\> and \<OTRS\_UserLastname\> instead
    of \<OTRS\_OWNER\_UserFirstname\> or \<OTRS\_OWNER\_UserLastname\>.
 - 2007-08-22 Fixed bug#[2203](http://bugs.otrs.org/show_bug.cgi?id=2203) - OTRS will not create/verify correct pgp
    signs if utf8 is used.
 - 2007-08-22 Fixed bug#[2202](http://bugs.otrs.org/show_bug.cgi?id=2202) - Kernel::System::Email::SMTP is sending
    "localhost.localdomain" in smtp hello, some server rejecting this ("Host
    not found").
 - 2007-08-21 Fixed bug#[2024](http://bugs.otrs.org/show_bug.cgi?id=2024) - Problem with agent authentication via LDAP
    with ADS-Groups and content of DN like "Some\, Name".
 - 2007-08-20 Fixed bug#[2094](http://bugs.otrs.org/show_bug.cgi?id=2094) and 2143 - 'Got no MainObject' warning in
    Kernel/System/Crypt.pm
 - 2007-08-20 Fixed bug#[2192](http://bugs.otrs.org/show_bug.cgi?id=2192) - Useless fragments of old escalation mechanism
    produces errors.
 - 2007-08-17 Fixed bug#[1908](http://bugs.otrs.org/show_bug.cgi?id=1908) - Removed duplicate history entry for ticket
    subscribe action.
 - 2007-08-16 Fixed bug#[1492](http://bugs.otrs.org/show_bug.cgi?id=1492) - Fixed typo in Kernel/Language.pm.
 - 2007-08-10 Fixed bug#[2160](http://bugs.otrs.org/show_bug.cgi?id=2160) - 0 was ignored in database insert by package
    building.
 - 2007-08-10 Fixed bug#[2156](http://bugs.otrs.org/show_bug.cgi?id=2156) - External customer database is not working,
    if it's configured the following error message appears
    ("Got no MainObject in Kernel/System/DB.pm line 85").
 - 2007-08-10 Fixed bug#[2155](http://bugs.otrs.org/show_bug.cgi?id=2155) - Std-Attachments are not usable in agent
    ticket compose screen (no std attachments are shown in compose screen).
 - 2007-08-07 Fixed bug#[2118](http://bugs.otrs.org/show_bug.cgi?id=2118) - Fixed typo in german translation file (
    Kernel/Language/de.pm).
 - 2007-08-07 Fixed bug#[2117](http://bugs.otrs.org/show_bug.cgi?id=2117) - Fixed small typo in initial insert files.
 - 2007-08-06 Fixed bug#[1999](http://bugs.otrs.org/show_bug.cgi?id=1999) - Service and SLA can not changed on an
    existing ticket.
 - 2007-08-06 Fixed bug#[2142](http://bugs.otrs.org/show_bug.cgi?id=2142) - If a service or a sla of a ticket was changed,
    no ticket history entry was added.
 - 2007-08-06 Fixed bug#[2135](http://bugs.otrs.org/show_bug.cgi?id=2135) - scripts/DBUpdate-to-2.2.2.sql contains wrong
    SQL. Not the queue table needs to be changed, the ticket table would be the
    right one.
 - 2007-08-03 Fixed bug#[2134](http://bugs.otrs.org/show_bug.cgi?id=2134) - PDF print is creating damaged pdf files with
    PDF::API2 0.56 or smaller.
 - 2007-08-02 Fixed bug#[940](http://bugs.otrs.org/show_bug.cgi?id=940) - After owners unlock ticket and a follow-up
    arrives the system, all agents which selected the queue of this ticket get
    and follow up message. In this follow up message the name was always the
    current owner and not the recipient of the email (which should be).
 - 2007-07-31 Fixed bug#[2001](http://bugs.otrs.org/show_bug.cgi?id=2001) - New escalation times and the responsible are
    not shown in any print views.

# 2.2.2 2007-07-31
 - 2007-07-31 Fixed bug#[2114](http://bugs.otrs.org/show_bug.cgi?id=2114) - Fixed the problems with the email object.
 - 2007-07-30 Fixed bug#[2015](http://bugs.otrs.org/show_bug.cgi?id=2015) - Improved handling to allocate customerusers
    and services. Now it's possible to define default services.
 - 2007-07-27 Fixed bug#[2053](http://bugs.otrs.org/show_bug.cgi?id=2053) - If core "System::Permission" note is used,
    not effect to the ticket note mask appears.
 - 2007-07-27 Fixed bug#[2059](http://bugs.otrs.org/show_bug.cgi?id=2059) - config setting $Self-\>{'Database::Connect'}
    is not overwriting default option used by driver.
 - 2007-07-26 Fixed bug#[2105](http://bugs.otrs.org/show_bug.cgi?id=2105) - Notification after moving a ticket to my
    queues is wrong -\> "\> OTRS\_CUSTOMER\_QUEUE\<" got not replaced in subject.
    SQL files scripts/database/otrs-initial\_insert.\*.sql got fixed.
 - 2007-07-26 Fixed bug#[2029](http://bugs.otrs.org/show_bug.cgi?id=2029) - Selected responsible agent was not taken
    over after creating a phone ticket.
 - 2007-07-26 Fixed bug#[1946](http://bugs.otrs.org/show_bug.cgi?id=1946) - Setting of service, sla or type via email
     X-OTRS-Service, X-OTRS-SLA or X-OTRS-Type header not possible.
 - 2007-07-26 Fixed bug#[2097](http://bugs.otrs.org/show_bug.cgi?id=2097) - Sometimes problems with SMTP module and utf8
    to send emails.
 - 2007-07-26 Improved system performance of escalation (bug#[2020](http://bugs.otrs.org/show_bug.cgi?id=2020) Performance
    problem after updating to 2.2.0).
    --\>Because of this fact you need to add to new column to the ticket table.\<--

```sql
    ALTER TABLE ticket ADD escalation_response_time INTEGER;
    ALTER TABLE ticket ADD escalation_solution_time INTEGER;
```
 - 2007-07-26 Fixed bug#[2061](http://bugs.otrs.org/show_bug.cgi?id=2061) - UserSyncLDAPMap does not work properly after
    upgrade to 2.2. The reason is, that we cleaned up this config option and
    the new one from Kernel/Config/Defaults.pm need to be used. We also added
    an check which log that an old config setting is used (also an compat.
    feature to still use the old option has been added).

    If you use UserSyncLDAPMap you need to reconfigure it!

Old style (till 2.1):

```perl
    $Self->{UserSyncLDAPMap} = {
        # DB -> LDAP
        Firstname => 'givenName',
        Lastname => 'sn',
        Email => 'mail',
    };
```
New style (beginning with 2.2):

```perl
    $Self->{UserSyncLDAPMap} = {
        # DB -> LDAP
        UserFirstname => 'givenName',
        UserLastname => 'sn',
        UserEmail => 'mail',
    };
```
 - 2007-07-25 Added missing OTRS 2.2 sql update scripts for mssql and maxdb
    (scripts/DBUpdate-to-2.2.maxdb.sql and scripts/DBUpdate-to-2.2.mssql.sql).
 - 2007-07-23 Fixed bug#[2068](http://bugs.otrs.org/show_bug.cgi?id=2068) - Date problem with non en installations of
    MSSQL server. Some date inserts or package installations failed. Added
    database init connect option to mssql driver ("SET DATEFORMAT ymd" /
    Kernel/System/DB/mssql.pm).
 - 2007-07-23 Because of safety reason, generic agent jobs will not longer run
    without min. one search attribute (admin interface and cmd). So if you want to
    match all ticket, you need to add an \* in the ticket number.
 - 2007-07-23 Fixed bug#[2021](http://bugs.otrs.org/show_bug.cgi?id=2021) - Errors in MSSQL post schema files.
 - 2007-07-23 Fixed bug#[2025](http://bugs.otrs.org/show_bug.cgi?id=2025) - No upgrade PostgreSQL possible, added missing
    lines in DBUpdate-to-2.2.postgresql.sql.
 - 2007-07-22 Fixed Ticket#2007072342000148 - Old OTRS (\< OTRS 2.2)
    attachments are corrupt after upgrade if file backend is used.
 - 2007-07-16 Updated portuguese translation, thanks Filipe Henriques and
    Rui Pires!
 - 2007-07-16 Updated norwegian translation, thanks to Fredrik Andersen!
 - 2007-07-16 Updated hungarian translation, thanks to Aron Ujvari!
 - 2007-07-16 Updated spanish translation, thanks to Carlos Oyarzabal!
 - 2007-07-12 Fixed bug#[2016](http://bugs.otrs.org/show_bug.cgi?id=2016) - CustomerUserUpdate: Add a function to handle
    empty values.
 - 2007-07-11 Fixed bug#[2047](http://bugs.otrs.org/show_bug.cgi?id=2047) - Add MainObject to the needed object check.
 - 2007-07-10 Fixed bug#[2045](http://bugs.otrs.org/show_bug.cgi?id=2045) - Notifications on reopen are not sent to
    owner/responsible.
 - 2007-07-03 Fixed bug#[2011](http://bugs.otrs.org/show_bug.cgi?id=2011) - Translation problems in stats module.

# 2.2.1 2007-07-01
 - 2007-06-29 Updated finnish translation, thanks to Mikko Hynninen!
 - 2007-06-29 Added some build in caches to Service, SQL, Queue and Valid
    core modules to reduce the amount of sql queries (saves ~ 10% of queries
    in the queue view).
 - 2007-06-29 Fixed bug#[1998](http://bugs.otrs.org/show_bug.cgi?id=1998) - Error with the web installer if no utf8
    database is selected.
 - 2007-06-28 Disabled only show escalated tickets in queue view because
    of already show escalation notifications.
 - 2007-06-28 Updated portuguese translation, thanks Filipe Henriques!
 - 2007-06-28 Fixed bug#[2000](http://bugs.otrs.org/show_bug.cgi?id=2000) - Typo in database update script
    DBUpdate-to-2.1.mysql.sql.
 - 2007-06-28 Reworked AdminCustomerUserService mask.
 - 2007-06-28 Fixed wildcard handling in ServiceSerarch().
 - 2007-06-27 Added option to log sql queries which take longer the 4 sek.
    and can be enabled via Kernel/Config.pm (Database::SlowLog). For more
    info see Kernel/Config/Defaults.pm.
 - 2007-06-26 Fixed not working alter table to SET or DROP NULL and NOT
    NULL via xml interface (Kernel/System/DB/postgresql.pm).
 - 2007-06-26 Updated french translation, thanks to Yann Richard and Remi Seguy!
 - 2007-06-26 Updated netherlands translation, thanks to Richard Hinkamp!
 - 2007-06-26 Updated hungarian translation, thanks to Aron Ujvari!
 - 2007-06-20 Updated russian translation, thanks to Andrey Feldman!
 - 2007-06-20 Updated greek translation, thanks to Stelios Maistros!

# 2.2.0 rc1 2007-07-19
 - 2007-06-19 Fixed bug#[1941](http://bugs.otrs.org/show_bug.cgi?id=1941) - Ticket Escalation blocks QueueView even if
    Agent has only read access.
 - 2007-06-18 Improved TicketSubjectClean() that it is also working with
    longer Ticket::SubjectRe options like "Antwort: [Ticket#: 1234] Antwort: .."
    (which was not removed on email answers).
 - 2007-06-13 Fixed bug#[1951](http://bugs.otrs.org/show_bug.cgi?id=1951) - Changed default selection of 'valid' field in
    AdminService and AdminSLA mask.
 - 2007-06-12 Added feature (bug#[1949](http://bugs.otrs.org/show_bug.cgi?id=1949) an 1950) for customer ldap backend
    for soft or hard die.
 - 2007-06-12 Added customeruser to service relation feature.
 - 2007-05-31 Improved XMLHashAdd() and XMLHashUpdate() in
    Kernel/System/XML.pm to prevent caching errors.
 - 2007-05-31 Fixed bug#[1927](http://bugs.otrs.org/show_bug.cgi?id=1927) - It is possible to uninstall a required
    package.

# 2.2.0 beta4 2007-05-29
 - 2007-05-26 Fixed bug in service and sla tables. Column comment was wrongly
    defined as required field.
 - 2007-05-24 Fixed bug#[1894](http://bugs.otrs.org/show_bug.cgi?id=1894) - otrs.addUser does not work
 - 2007-05-24 Fixed bug#[1913](http://bugs.otrs.org/show_bug.cgi?id=1913) - Added missing columns first\_response\_time,
    solution\_time and rename column escalation\_time to update\_time for table
    queue in DBUpdate-to-2.2.oracle.sql.
 - 2007-05-23 Add the ticket options Type, Service and SLA to the ticket
    print.
 - 2007-05-22 Add TicketType, Service and SLA option to stats module
    to improve flexibility of dynamic stats.
 - 2007-05-22 Remove wrong item in check needed stuff section of SLAList()
    function.
 - 2007-05-21 Update german translation.
 - 2007-05-21 Improved check of needed stuff in SLAAdd() function in
    Kernel/System/SLA.pm.
 - 2007-05-21 Sync HTML style of admin masks. No functionality changed.
    Kernel/Output/HTML/Standard/AdminAttachmentForm.dtl
    Kernel/Output/HTML/Standard/AdminAutoResponseForm.dtl
    Kernel/Output/HTML/Standard/AdminCustomerCompanyForm.dtl
    Kernel/Output/HTML/Standard/AdminCustomerUserForm.dtl
    Kernel/Output/HTML/Standard/AdminGenericAgent.dtl
    Kernel/Output/HTML/Standard/AdminGroupForm.dtl
    Kernel/Output/HTML/Standard/AdminLog.dtl
    Kernel/Output/HTML/Standard/AdminNotificationForm.dtl
    Kernel/Output/HTML/Standard/AdminPGPForm.dtl
    Kernel/Output/HTML/Standard/AdminPOP3.dtl
    Kernel/Output/HTML/Standard/AdminPackageManager.dtl
    Kernel/Output/HTML/Standard/AdminPerformanceLog.dtl
    Kernel/Output/HTML/Standard/AdminPostMasterFilter.dtl
    Kernel/Output/HTML/Standard/AdminQueueForm.dtl
    Kernel/Output/HTML/Standard/AdminResponseForm.dtl
    Kernel/Output/HTML/Standard/AdminRoleForm.dtl
    Kernel/Output/HTML/Standard/AdminSLA.dtl
    Kernel/Output/HTML/Standard/AdminSMIMEForm.dtl
    Kernel/Output/HTML/Standard/AdminSalutationForm.dtl
    Kernel/Output/HTML/Standard/AdminService.dtl
    Kernel/Output/HTML/Standard/AdminSession.dtl
    Kernel/Output/HTML/Standard/AdminSignatureForm.dtl
    Kernel/Output/HTML/Standard/AdminStateForm.dtl
    Kernel/Output/HTML/Standard/AdminSysConfig.dtl
    Kernel/Output/HTML/Standard/AdminSystemAddressForm.dtl
    Kernel/Output/HTML/Standard/AdminTypeForm.dtl
    Kernel/Output/HTML/Standard/AdminUserForm.dtl
 - 2007-05-21 Changes max shown escalated tickets in queue view to 30
    (to improved spped of escalation view in queue view).
 - 2007-05-21 Fixed double ContentType in ArticleAttachment() of attachment
    backends (Kernel/System/Ticket/ArticleStorage(DB|FS).pm).
 - 2007-05-21 Sync of all configurable frontend modules. No functionality changed.
    Kernel/Modules/AgentTicketClose.pm
    Kernel/Modules/AgentTicketFreeText.pm
    Kernel/Modules/AgentTicketNote.pm
    Kernel/Modules/AgentTicketOwner.pm
    Kernel/Modules/AgentTicketPending.pm
    Kernel/Modules/AgentTicketPriority.pm
    Kernel/Modules/AgentTicketResponsible.pm
    Kernel/Output/HTML/Standard/AgentTicketClose.dtl
    Kernel/Output/HTML/Standard/AgentTicketFreeText.dtl
    Kernel/Output/HTML/Standard/AgentTicketNote.dtl
    Kernel/Output/HTML/Standard/AgentTicketOwner.dtl
    Kernel/Output/HTML/Standard/AgentTicketPending.dtl
    Kernel/Output/HTML/Standard/AgentTicketPriority.dtl
    Kernel/Output/HTML/Standard/AgentTicketResponsible.dtl
 - 2007-05-21 Fixed bug#[1898](http://bugs.otrs.org/show_bug.cgi?id=1898) - Invalid services and slas was shown in agent
    masks.
 - 2007-05-16 Improved check of needed Charset param in Send() function to
    prevent problems like in bug#[1887](http://bugs.otrs.org/show_bug.cgi?id=1887).
 - 2007-05-14 Fixed bug#[1866](http://bugs.otrs.org/show_bug.cgi?id=1866) - Error while DB upgrade from 2.1.5 to 2.2.0
    beta3.
 - 2007-05-12 Ingresed width of html login tables from 270 to 280 because
    of new language selection.
 - 2007-05-11 Added script to convert a non utf-8 database to an utf-8
    database.
 - 2007-05-09 Fixed bug#[1825](http://bugs.otrs.org/show_bug.cgi?id=1825) - SQL ticket\_history INSERT syntax error in
    HistoryAdd().
 - 2007-05-08 Fixed bug#[1840](http://bugs.otrs.org/show_bug.cgi?id=1840) - Repeat escalation message when queue, SLA
    Solution time is shown.
 - 2007-05-07 Added DB::Encode database driver config (Kernel/System/DB/\*.pm)
    to set encoding of selected data to utf8 if needed.
 - 2007-05-07 Added cmd bin/otrs.RebuildConfig.pl to rebuild/build default
    Kernel/Config/Files/ZZZAAuto.pm based on Kernel/Config/Files/\*.xml config
    files.
 - 2007-05-07 Fixed bug#[1787](http://bugs.otrs.org/show_bug.cgi?id=1787) - Problem with cachefilenames of the stats
    module in win32.

# 2.2.0 beta3 2007-05-07
 - 2007-05-04 Fixed bug#[1788](http://bugs.otrs.org/show_bug.cgi?id=1788) - Problem with cachefile in win32.
 - 2007-05-04 Fixed bug#[1773](http://bugs.otrs.org/show_bug.cgi?id=1773) - DB-error in phone ticket if sla but no
    service is selected.
 - 2007-05-04 Fixed bug#[1035](http://bugs.otrs.org/show_bug.cgi?id=1035) - OTRS does not set encoding for the mysql
    database connection (i.e. UTF-8).
 - 2007-05-04 Fixed bug#[1778](http://bugs.otrs.org/show_bug.cgi?id=1778) - Config option Database::Connect should be
    possible.
 - 2007-05-04 Fixed bug#[1611](http://bugs.otrs.org/show_bug.cgi?id=1611) - Now the Statsmodule use the mirror db if
    configured.
 - 2007-05-02 Fixed bug#[1809](http://bugs.otrs.org/show_bug.cgi?id=1809) - Fixed typo in variable name (PrioritiesStrg -\>
    PriotitiesStrg).
 - 2007-04-27 Fixed bug#[1670](http://bugs.otrs.org/show_bug.cgi?id=1670) - If no result the generation of pie graph throws
    error.
 - 2007-04-26 Added feature to use no BaseDN (or '') for agent and customer
    authentification (see ticket# 2007030642000446).
 - 2007-04-24 Fixed bug#[1769](http://bugs.otrs.org/show_bug.cgi?id=1769) - If I change the ticket SLA, the history is
    not relfecting this change.
 - 2007-04-24 Fixed bug#[1768](http://bugs.otrs.org/show_bug.cgi?id=1768) - If I change the ticket service, the history
    is not relfecting this change.

# 2.2.0 beta2 2007-04-16
 - 2007-04-16 Fixed bug#[1448](http://bugs.otrs.org/show_bug.cgi?id=1448) - Apache::Registry in README.webserver wrong,
    mod\_perl2 is missing.
 - 2007-04-16 Fixed bug#[1286](http://bugs.otrs.org/show_bug.cgi?id=1286) - apache configuration should use
    \<IfModule mod\_perl.c\>.
 - 2007-04-16 Fixed bug#[1755](http://bugs.otrs.org/show_bug.cgi?id=1755) - Wrong permissions for some files.
 - 2007-04-16 Fixed bug#[1757](http://bugs.otrs.org/show_bug.cgi?id=1757) - Cannot install postgres db - null value in
    column "escalation\_start\_time" violates not-null constraint.
 - 2007-04-16 Fixed bug#[1745](http://bugs.otrs.org/show_bug.cgi?id=1745) - Invalid SQL-statements in AgentTicketQueue
    view.
 - 2007-04-13 Fixed bug#[1741](http://bugs.otrs.org/show_bug.cgi?id=1741) - "PostmasterFollowUpStateClosed" buggy on
    follow up actions.
 - 2007-04-12 Updated bulgarian translation, thanks to Alex Kantchev!
 - 2007-04-12 Fixed bug#[1748](http://bugs.otrs.org/show_bug.cgi?id=1748) - Session not allowed to be larger than 358400
    Bytes using IPC. Change max session size from 350k to 2 MB.
 - 2007-04-12 Fixed bug#[1744](http://bugs.otrs.org/show_bug.cgi?id=1744) - Unable to create xml\_storage table in utf8
    charset on mysql database.
 - 2007-04-12 Fixed bug#[1739](http://bugs.otrs.org/show_bug.cgi?id=1739) - Unable to insert new SLA via admin-web after
    upgrade to 2.2.0 beta1.
 - 2007-04-11 Added new Arabic (Saudi Arabia) translation, thanks to
    Mohammad Saleh!

# 2.2.0 beta1 2007-04-02
 - 2007-04-02 Added customer company feature (split of contact and company
    infos). Need to be activated in CustomerUser config (see
    Kernel/Config/Defaults.pm).
 - 2007-03-27 Added enhancement #1688 - Backreference in postmaster filter
    replaces everything, not just the matched backreferenced token.
 - 2007-03-27 Added enhancement #1600 - Adjustable encoding for mails.
 - 2007-03-21 Updated cpan module CGI to version 3.27.
 - 2007-03-20 Added support of new set ticket pending time over X-OTRS-Header
    X-OTRS-State-PendingTime and X-OTRS-FollowUp-State-PendingTime.
 - 2007-03-20 Rewrite of Kernel::System::User module (cleanup of used params
    for UserAdd() and UserUpdate()).
    If you use this API, you need to change your custom implemention!
    Note If you use UserSyncLDAPMap you need to reconfigure it!

Old:

```perl
    $Self->{UserSyncLDAPMap} = {
        # DB -> LDAP
        Firstname => 'givenName',
        Lastname => 'sn',
        Email => 'mail',
    };
```

New:
```perl
    $Self->{UserSyncLDAPMap} = {
        # DB -> LDAP
        UserFirstname => 'givenName',
        UserLastname => 'sn',
        UserEmail => 'mail',
    };
```
 - 2007-03-14 Fixed not shown optional ticket free time option fields in
    customer panel.
 - 2007-03-11 Added enhancement bug#[1102](http://bugs.otrs.org/show_bug.cgi?id=1102) - restore.pl should check for
    existing tables and stop if already one exists.
 - 2007-03-11 Added enhancement bug#[1664](http://bugs.otrs.org/show_bug.cgi?id=1664) - increase max. WebMaxFileUpload
    size.
 - 2007-03-08 Improved Prepare() of Kernel::System::DB to fetch also rows
   between 10 and 30 (with start option of result). For example:

```perl
   $DBObject->Prepare(
       SQL => "SELECT id, name FROM table",
       Start => 10,
       Limit => 20,
   );
```
 - 2007-03-08 Improved XML database database backend for \<Insert\>. Content
    in xml attribut is not longer allowed, use the content instead. Now it's
    also possible to use new lines (\n) or more lines as content.

Old style:

```xml
    <Insert Table="table_name">
        <Data Key="name_a" Value="Some Message A." Type="Quote"/>
        <Data Key="name_b" Value="Some Message B." Type="Quote"/>
    </Insert>
```
New style:

```xml
    <Insert Table="table_name">
        <Data Key="name_a" Type="Quote">Some Message A.</Data>
        <Data Key="name_b" Type="Quote">Some Message B.</Data>
    </Insert>
```
 - 2007-03-08 Moved from scripts/database/initial\_insert.sql to database depend
    initial insert files located under scripts/database/otrs-initial\_insert.\*.sql.
    This files are generated from scripts/database/otrs-initial\_insert.xml.
    Note: The scripts/database/initial\_insert.sql exists not longer, use
    scripts/database/otrs-initial\_insert.\*.sql from now on for installations.
 - 2007-03-08 Fixed bug#[1017](http://bugs.otrs.org/show_bug.cgi?id=1017) - script initial\_insert.sql, ampersand and oracle.
 - 2007-03-08 Fixed enhacement bug#[1668](http://bugs.otrs.org/show_bug.cgi?id=1668) - removed unnecessary dependency for
    fetchmail from .srpms.
 - 2007-03-07 Added Intro support for .opm format to add intros for packages.
    For example to add infos where the module can be found, if you need to add
    some groups to access the module or some other useful stuff.
    Intro(Install|Reinstall|Upgrade|Uninstall)(Pre|Post) can be used. For more
    infos see the developer manual in section "Package Spec File".
 - 2007-03-07 Fixed bug#[1398](http://bugs.otrs.org/show_bug.cgi?id=1398) - Malformed UTF-8 charaters in Admin Backend -
    System Log.
 - 2007-03-05 Added Type, Service, SLA as ticket default attribute.
    Each an be activated by a config setting over SysConfig under
    Ticket :: Core :: Ticket.
 - 2007-02-15 Improved PGP decryption of files if more the one possible
    private key exists in the system and one of it is invalid (e. g. no
    configured password).
 - 2007-02-15 Fixed bug-ticket# 2007020542000593 - Queue refresh "off"
    can't be used on oracle database.
 - 2007-02-15 Add BuildSelection(). This function replaced OptionStrgHashRef(),
    OptionElement() AgentQueueListOption().
 - 2007-02-12 Added pending time selection feature for generic agent.
 - 2007-02-07 Moved to dtl block in customer ticket zoom view.
 - 2007-02-07 Moved default WebMaxFileUpload config option from 5 MB
    to 10 MB.
 - 2007-01-31 Fixed Free Field output in AgentTicketForward and
    AgentTicketPhoneOutbound.
 - 2007-01-30 Added 4 ticket freetime fields and improved freetime function.
 - 2007-01-30 Relocated valid functionality to new Valid.pm to move it
   out from Kernel/System/DB.pm.
 - 2007-01-18 Added X-OTRS-Lock and X-OTRS-FollowUp-Lock header for
    PostMaster.
 - 2007-01-17 Relocated agent preferences button.
 - 2007-01-17 Improved freetime feature, unset freetime is now possible by
    agent and customer GUI.
 - 2007-01-03 Heavy improvement of PerformanceLog feature, show detail
    view of each frontend module now.
 - 2007-01-03 Added config option for die or log is ldap/radius auth server
    is not available.
 - 2006-12-21 Improved description of Email- and Phone-Ticket in navigation.
 - 2006-12-21 Added config option to use SystemID in follow up detection or
    not (Ticket::NumberGenerator::CheckSystemID).
 - 2006-12-21 Added config option for follow-up state of tickets which
    was was already closed (Ticket::Core::PostMaster::PostmasterFollowUpStateClosed).
 - 2006-12-19 Added config option Ticket::NumberGenerator::CheckSystemID
    to configure if SystemID is used in follow up detection.
 - 2006-12-14 Removed old compat. CreateTicketNr()/CheckTicketNr() in
    Kernel/System/Ticket.pm and Kernel/System/Ticket/Number/\*.pm - so
    old ticket number generator not longer compat. to OTRS 2.1.
 - 2006-12-13 Moved config option setting SessionMaxTime from 10h to 14h.
 - 2006-12-13 Added auth and customer password crypt backend for crypt(),
    md5() and plain().
 - 2006-12-13 Added multi auth feature of agent and customer backend.
 - 2006-12-13 Added feature to configure password crypt type of agent and
    customer auth backend modules.
 - 2006-12-13 Added feature to match only exact email addresses of incoming
    emails in PostMaster filter like "From: EMAILADDRESS:someone@example.com".
    This only will match for email addresses like 'someone@example.com',
    'aaa.someone@example.com' will not match! This was a problem if you use
    normal "From: someone@example.com" match.
 - 2006-12-13 Added config option for online agent and customer module to
    show/not show email addresses of people (SysConfig: Framework
    Frontend::Agent::ModuleNotify and Frontend::Customer::ModuleNotify).
 - 2006-12-13 Moved config option PostMasterPOP3MaxEmailSize default 6 MB
    to 12 MB.

# 2.1.9 2010-02-08
 - 2010-02-04 Fixed SQL quoting issue (see also
    http://otrs.org/advisory/OSA-2010-01-en/).
 - 2008-02-06 Fixed bug#[2491](http://bugs.otrs.org/show_bug.cgi?id=2491) - OTRS crash's after initial login on fresh
    installation on fedora 7, fedora 8, altlinux and ActiveState Perl on win32.

# 2.1.8 2008-03-31
 - 2007-08-03 Fixed bug#[2134](http://bugs.otrs.org/show_bug.cgi?id=2134) - PDF print is creating damaged pdf files with
    PDF::API2 0.56 or smaller.
 - 2007-07-26 fixed bug#[2046](http://bugs.otrs.org/show_bug.cgi?id=2046) - german Umlauts not printed in PDFs if system
    runs in utf-8 mode. The PDF::API2 corefonts (which are used as default)
    doesn't support UTF-8. Changed the used fonts from PDF::API2 corefonts to
    the DejaVu true type fonts. Add config options to use other true type fonts.
 - 2007-05-31 fixed bug#[1926](http://bugs.otrs.org/show_bug.cgi?id=1926) - package manager ignore PackageRequired tags
    in OPM files.

# 2.1.7 2007-04-05
 - 2007-04-05 fixed bug#[1551](http://bugs.otrs.org/show_bug.cgi?id=1551) - decode\_mimewords() in ArticleWriteAttachment()
    dies due to utf-8
 - 2007-03-27 updated Kernel/Language/pt\_BR.pm translation file - Thanks
    to Fabricio Luiz Machado!
 - 2007-03-14 fixed bug#[1650](http://bugs.otrs.org/show_bug.cgi?id=1650) - crypt/sign bug in AgentTicketCompose screen
 - 2007-03-14 fixed bug#[1659](http://bugs.otrs.org/show_bug.cgi?id=1659) - Uploading and Saving Pictures in MSSQL won't
    work with bigger Files (~700KB)
    ->MSSQL ONLY<- You also need to change some tables by using: ->MSSQL ONLY<-

```sql
        ALTER TABLE web_upload_cache ALTER COLUMN content TEXT NOT NULL;
        ALTER TABLE article_plain ALTER COLUMN body TEXT NOT NULL;
        ALTER TABLE article_attachment ALTER COLUMN content TEXT NOT NULL;
        ALTER TABLE article ALTER COLUMN a_body TEXT NOT NULL;
        ALTER TABLE standard_response ALTER COLUMN text TEXT NOT NULL;
        ALTER TABLE standard_attachment ALTER COLUMN content TEXT;
        ALTER TABLE sessions ALTER COLUMN session_value TEXT;
        ALTER TABLE xml_storage ALTER COLUMN xml_content_value TEXT;
        ALTER TABLE package_repository ALTER COLUMN content TEXT NOT NULL;
```
 - 2007-03-12 fixed upload cache problem in win32 .pdf files
 - 2007-03-12 fixed bug#[1228](http://bugs.otrs.org/show_bug.cgi?id=1228) - Apostrophe not valid in email address.
 - 2007-03-12 fixed bug#[1442](http://bugs.otrs.org/show_bug.cgi?id=1442) and 1559 - ArticleFreeKey and ArticleFreeText
    default selection does not work.
 - 2007-03-12 fixed ticket# 2007031242000149 - session backend fails to insert
    sessions bigger the 4k on oracle database backend
 - 2007-03-11 fixed bug#[1671](http://bugs.otrs.org/show_bug.cgi?id=1671) - restore.pl fails with "Got no LogObject"
 - 2007-03-11 fixed bug#[1115](http://bugs.otrs.org/show_bug.cgi?id=1115) - HTML error in NewTicket Customer's interface.
 - 2007-03-08 fixed bug#[1658](http://bugs.otrs.org/show_bug.cgi?id=1658) - Subqueues of Queues with brackets are not
    shown in the QueueView
 - 2007-03-08 added rpm packages for Fedora Core 4, 5 and 6 to auto build
    service
 - 2007-03-05 fixed ticket# 2007022342000586 - attachment problem with oracle
    backend if utf-8 is used
 - 2007-03-05 fixed database driver if 0 is used in begining of an xml insert

# 2.1.6 2007-03-02
 - 2007-03-02 fixed bug#[1504](http://bugs.otrs.org/show_bug.cgi?id=1504) - Ticket Creation fails with DB2 due to
    character quoting issues
 - 2007-03-02 fixed bug#[1506](http://bugs.otrs.org/show_bug.cgi?id=1506) - Error creating Tickets in DB2 due to conflict
    in string/numerical comparison
 - 2007-03-02 fixed bug#[1445](http://bugs.otrs.org/show_bug.cgi?id=1445) - OTRS is not encoding Umlauts correctly in
    Organization email header
 - 2007-03-02 fixed bug#[1548](http://bugs.otrs.org/show_bug.cgi?id=1548) - submitting AgentTicketPhone or
    AgentTicketEmail form without queueid leads to broken fields
 - 2007-02-27 fixed bug#[1581](http://bugs.otrs.org/show_bug.cgi?id=1581) - Garbled paths containing domain names
 - 2007-02-27 updated Mail::Tools from 1.60 to 1.74 - fixed bug#[1642](http://bugs.otrs.org/show_bug.cgi?id=1642) -
    Cant get mails via PostmasterPop3.pl - Unrecognised line
 - 2007-02-27 fixed bug#[1545](http://bugs.otrs.org/show_bug.cgi?id=1545) - Wrong Variableusage in $Self-\>{PageShown}
    (Kernel/Modules/AgentTicketMailbox.pm)
 - 2007-02-26 fixed bug#[1291](http://bugs.otrs.org/show_bug.cgi?id=1291) - Download link in SysConfig skips config
    options -\> now download link will be shown if no changes are done
 - 2007-02-26 fixed bug#[1097](http://bugs.otrs.org/show_bug.cgi?id=1097) - Disabling Bounce Feature via SysConfig does
    not work properly
 - 2007-02-26 fixed ticket #2007022242000293 hard line rewrap of body content
    in frontend modules
 - 2007-02-26 improved speed of SysConfig core module, added cache mechanism
    (it's about 2 times faster)
 - 2007-02-22 fixed ticket #2007022042000288 - error on creating postmaster
    filter on oracle database
 - 2007-02-20 fixed not working crypt/sign option in AgentTicketCompose mask
 - 2007-02-20 fixed bug#[980](http://bugs.otrs.org/show_bug.cgi?id=980) - Use of uninitialized value in
    Kernel/System/AuthSession/FS.pm
 - 2007-02-15 changed unlock time reset mechanism, added unlock time reset
    if a agent sends an external message to the customer (like escalation
    reset mechanism)
 - 2007-02-09 fixed bug in \_XMLHashAddAutoIncrement() - function could not
    return keys greater than '9'.
 - 2007-02-02 fixed bug#[1056](http://bugs.otrs.org/show_bug.cgi?id=1056) - UTF-8 mode of OTRS and German Umlaute within
    agent's name
 - 2007-02-02 fixed bug#[1505](http://bugs.otrs.org/show_bug.cgi?id=1505) - UserSyncLDAPMap fails with LDAP.pm version
    1.26 and up
 - 2007-01-30 fixed ticket\_watcher.user\_id datatype, moved from BIGINT to
    INTEGER
 - 2007-01-30 fixed oracle driver for xml alter table actions
 - 2007-01-30 improved \_CryptedWithKey() - private key detection of
    Kernel/System/Crypt/PGP.pm if more keys are used for crypted messages
 - 2007-01-26 fixed ArticleFreeText output in CustomerTicketZoom mask
 - 2007-01-26 fixed bug in agent- and customer-ticket print feature

# 2.1.5 2006-01-25
 - 2007-01-25 fixed ignored ticket responsible in phone ticket
 - 2007-01-18 fixed DestinationTime() if calendar feature is used
 - 2007-01-17 fixed not working freetime fields
 - 2007-01-11 fixed not working time selection if time zone feature is used
 - 2007-01-08 fixed not working email notification tags in auto response,
    agent and customer email notifications
 - 2007-01-08 fixed case sensitive of customer user login and agent user
    login in Kernel/System/User.pm and Kernel/System/CustomerUser/DB.pm if
    oracle or postgresql is used
 - 2007-01-08 fixed quoting in user selection if + is used in UserLogin in
    Kernel/Output/HTML/Standard/AdminCustomerUserForm.dtl
 - 2006-12-17 fixed bug#[1532](http://bugs.otrs.org/show_bug.cgi?id=1532) - utf-8 charsetproblems in stats
 - 2006-12-15 fixed bug#[1446](http://bugs.otrs.org/show_bug.cgi?id=1446) - No "(Ticket unlock!)" link in
    AgentTicketCompose
 - 2006-12-14 fixed customer ldap auth if system is iso-8859 and ldap server
    is running in utf-8
 - 2006-12-14 fixed not working Kernel/System/DB/db2.pm (syntax error)

# 2.1.4 2006-12-13
 - 2006-12-13 fixed not working free time selection in AgentTicketClose,
    AgentTicketNote, AgentTicketOwner, AgentTicketPending, AgentTicketPriority
    and AgentTicketResponsible
 - 2006-12-11 added config param for shown my queues/custom queues
    in preferences, default are shown all ro queues, see also
    PreferencesGroups###CustomQueue under Frontend::Agent::Preferences
 - 2006-12-11 fixed ldap sync of agents attributes - invalid agents
    are not longer synced to valid if ldap auth was successfully, the
    invalid agent will still be invalid
 - 2006-12-11 fixed bug#[1187](http://bugs.otrs.org/show_bug.cgi?id=1187) - Escalation Notifications sent to invalid agent
 - 2006-12-11 improved link quote of long links in web interface
 - 2006-12-11 fixed bug#[962](http://bugs.otrs.org/show_bug.cgi?id=962) - Broken attachments with cyrillic filenames
 - 2006-12-08 fixed bug#[1521](http://bugs.otrs.org/show_bug.cgi?id=1521) - Merge Feature
 - 2006-12-08 fixed bug#[1523](http://bugs.otrs.org/show_bug.cgi?id=1523) - update of FreetextValues 9-16 not working
 - 2006-12-08 fixed bug#[1524](http://bugs.otrs.org/show_bug.cgi?id=1524) - ticketFreeText Fields 9-16 not displayed
    at CustomerTicketPrint and CustomerTicketZoom
 - 2006-12-07 fixed bug#[1359](http://bugs.otrs.org/show_bug.cgi?id=1359) - acl problem if '' is used in properties to match
 - 2006-12-07 fixed bug#[1031](http://bugs.otrs.org/show_bug.cgi?id=1031) - scripts/backup.pl fails in mysqldump with
    encrypted database password
 - 2006-12-07 fixed bug#[1378](http://bugs.otrs.org/show_bug.cgi?id=1378) - Got no MainObject! in bin/otrs.getTicketThread
 - 2006-12-07 fixed bug#[1200](http://bugs.otrs.org/show_bug.cgi?id=1200) - not working TicketACL actions AgentTicketCompose,
    AgentTicketBounce, AgentTicketForward and AgentTicketPhoneOutbound
 - 2006-12-07 added log notice for switch to user admin feature
 - 2006-12-07 fixed bug#[1210](http://bugs.otrs.org/show_bug.cgi?id=1210) - wrong calculation of Kernel::System::Time
    WorkingTime()
 - 2006-12-06 added changes notice of generic agent jobs to log sub
    system (to keep clear who changed the job)
 - 2006-12-05 moved ticket number generator loop check from 1000 to 6000
    (Kernel/System/Ticket/Number/\*.pm)
 - 2006-11-30 fixed not working faq lookup in compose answer and forward
    screen
 - 2006-11-30 fixed double quoted "$Quote{"Cc: (%s) added database email!""}
    in compose answer screen (Kernel/Modules/AgentTicketCompose.pm)
 - 2006-11-30 fixed bug#[1498](http://bugs.otrs.org/show_bug.cgi?id=1498) - Typo in QuoteSingle, Kernel/System/DB/mssql.pm
 - 2006-11-30 moved Quote() from Kernel/System/DB.pm to db backend modules
    Kernel/System/DB/\*.pm because of needed Quote() in xml processing
 - 2006-11-23 improved handling if there are double customer users in
    the database used by search result
 - 2006-11-22 fixed PGP/SMIME bug - Can't call method "body" on an undefined
    value at Kernel/System/EmailParser.pm line 382
 - 2006-11-22 fixed bug#[1395](http://bugs.otrs.org/show_bug.cgi?id=1395) - utf-8 - ArticleStorage FS - Attachments with
    German Umlauts cant be downloaded
 - 2006-11-17 added config option Ticket::PendingNotificationOnlyToOwner
    to send reached reminder notifications of unlocked tickets only to ticket
    owner
 - 2006-11-17 fixed database driver detection/problem if a second database
    connect with different driver is used (wrong sql will not longer be
    generated) Note: old database driver files Kernel/System/DB/\*.pm
    not longer compatible
 - 2006-11-17 added config option Ticket::ResponsibleAutoSet to set owner
    automatically as responsible if no responsible is set (default is 1)

# 2.1.3 2006-11-15
 - 2006-11-15 removed not needed Reply-To of agent notifications
 - 2006-11-15 fixed missing \n on csv output of customer ticket search
 - 2006-11-15 fixed not working ticket free time option in phone ticket
 - 2006-11-15 added missing access permission pre check to show ticket menu
    items or not
 - 2006-11-15 fixed bug - not shown empty "-" selection of new onwer if on
    move if Ticket::ChangeOwnerToEveryone is set
 - 2006-11-10 update of Dansk language file, thanks to Mads N. Vestergaard
 - 2006-11-10 update of Spanish language file, thanks to Jorge Becerra
 - 2006-11-09 added AuthModule::HTTPBasicAuth::Replace and
    Customer::AuthModule::HTTPBasicAuth::Replace config option to HTTPBasicAuth
    modules to strip e. g. domains like example\_domain\user from login down to user
 - 2006-11-09 added AuthModule::LDAP::UserLowerCase to allways convert
     usernames into lower case letters
 - 2006-11-07 added set auto time zone of agent/customer based on java script
    offset feature on every login
 - 2006-11-07 fixed not working all owner/responsible selection in phone view
 - 2006-11-07 read out CustomerUserSearchListLimit correctly if LDAP customer
    backend is in use
 - 2006-10-27 fixed always shown responsible selection
 - 2006-10-27 removed not needed default free text fields from phone outbound
 - 2006-10-26 fixed agent can be customer follow up feature
 - 2006-10-26 added possible - selection for next state in phone view outbount
 - 2006-10-20 fixed LDAP problems "First bind failed! No password, did you
    mean noauth or anonymous ?"
 - 2006-10-19 fixed double agent notifications on ticket move to queue
    and also selected owner

# 2.1.2 2006-10-18
 - 2006-10-13 switched to md5 check sum for password in user\_preference table
 - 2006-10-12 fixed #1373 - RH RPM requires sendmail, but works with other MTAs
 - 2006-10-12 fixed double agent notifications on follow up if agent is
    owner and responsible
 - 2006-10-12 fixed bug#[1311](http://bugs.otrs.org/show_bug.cgi?id=1311) - Apostrophes are incorrectly displayed under
    IE 6 & IE7 but correctly displayed under Firefox 1.5.0.6  -=\>
    moved from $Text{} to $JSText{} for text translations in Java Script parts
    to have a correct quoting
 - 2006-10-11 fixed not shown follow up feature in customer panel if ticket
     is closed
 - 2006-10-09 added missing customer print feature
 - 2006-10-05 fixed bug#[1361](http://bugs.otrs.org/show_bug.cgi?id=1361) - Can't locate object method "ModGet" via
    package "Kernel::System::Config"

# 2.1.1 2006-10-05
 - 2006-10-05 fixed bug#[1213](http://bugs.otrs.org/show_bug.cgi?id=1213) - some errors not logger by LDAP backends
 - 2006-10-05 fixed bug#[1248](http://bugs.otrs.org/show_bug.cgi?id=1248) - Ticket Zoom - Article Thread - Color of auto
    responses should be yellow
 - 2006-10-05 fixed bug#[1323](http://bugs.otrs.org/show_bug.cgi?id=1323) - 2.1 DBUpgrade issue with PostgreSQL - patch
 - 2006-10-05 fixed bug#[1333](http://bugs.otrs.org/show_bug.cgi?id=1333) - No reset of escalation time after follow-up
 - 2006-10-05 fixed bug#[1345](http://bugs.otrs.org/show_bug.cgi?id=1345) - Attached binary files uploaded and saved to
    the FS are corrupted.
 - 2006-09-30 add ticketfreetext-, ticketfreetime- and articlefreetext support
    to pdf output
 - 2006-09-28 improved stats export/import with an id-name wrapper
 - 2006-09-28 fixed bug#[1353](http://bugs.otrs.org/show_bug.cgi?id=1353)/1354 changed autoreponse text
 - 2006-09-27 add transparency to some images
 - 2006-09-27 fixed bug#[1358](http://bugs.otrs.org/show_bug.cgi?id=1358) - Customer History \> All customer tickets.
    returns an incorrect number of tickets
 - 2006-09-27 fixed bug#[1293](http://bugs.otrs.org/show_bug.cgi?id=1293) - Can't use an undefined value as a HASH
    reference at /opt/otrs/bin/cgi-bin//../../Kernel/Modules/AgentTicketBulk.pm
    line 194
 - 2006-09-27 fixed bug#[1356](http://bugs.otrs.org/show_bug.cgi?id=1356) - mssql driver bug - Stats module of OTRS 2.1
    beta 2 - "Cant use string ("0")".
 - 2006-09-27 fixed bug#[1335](http://bugs.otrs.org/show_bug.cgi?id=1335) - removed "uninitialized value" warning in
    NavBarTicketWatcher.pm
 - 2006-09-22 fixed opm check do not install/upgrade packages if one file to
    install already exists in an other package
 - 2006-09-22 added "-a exportfile" feature to bin/opm.pl to export files
    of a package into a defined directory e. g. "-d /path/to/"
 - 2006-09-21 removed Re: from agent notification emails
 - 2006-09-14 added change to remove 4 not needed empty spaces after folding
    of email headers (sometimes 4 empty spaces in subject appear)
 - 2006-09-09 updated pdf-logo to ((otrs))
 - 2006-09-09 added DBUpdate-to-2.1.oracle.sql to get oracle databases up to
    date
 - 2006-09-05 fixed double sending of note notifications
 - 2006-09-05 fixed link to email and phone after adding a new customer user
 - 2006-09-01 added fix to removed leading and trailing spaces in search
    fields of object linking

# 2.1.0 beta2 2006-08-29
 - 2006-08-29 moved Frontend::ImagePath variable
   (/otrs-web/images/Standard/) from .dtl files to config option
 - 2006-08-28 added examples how to use SOAP (bin/cgi-bin/rpc.pl and
    scripts/rpc-example.pl)
 - 2006-08-27 added mulit calendar / queue support - you can use different
    time zones in different queues and each agent can select the own time zone
    NOTE: table queue need to be modified - see scripts/DBUpdate-to-2.1.\*.sql
 - 2006-08-27 fixed bug#[739](http://bugs.otrs.org/show_bug.cgi?id=739) - in the login you can type something behind the
    pass and it works / added password md5 support (required Crypt::PasswdMD5
    from CPAN or from Kernel/cpan-lib/ - via "cvs update -d")
 - 2006-08-26 fixed $Quote{""} bug in login page
 - 2006-08-25 fixed bug#[1284](http://bugs.otrs.org/show_bug.cgi?id=1284) - removed mysql dependence in
    scripts/apache-perl-startup.pl and scripts/apache2-perl-startup.sql
 - 2006-08-25 fixed bug#[1282](http://bugs.otrs.org/show_bug.cgi?id=1282) - setting up a postgresql database fails
 - 2006-08-24 added performance log feature in admin interface to monitor
    your system page load performance over different times (1h, 3h, 9h, 1d, 2d,
    3d) - its disabled per default
 - 2006-08-24 removed Re: in subject auto response emails
 - 2006-08-22 added PDF output support to AgentTicketPrint module
 - 2006-08-21 fixed bug in pdf module - redesiged Table() to fix a lot of
    infinite loops
 - 2006-08-08 fixed bug in pdf module - special control characters produces
    infinite loops
 - 2006-08-02 added ldap attribute to groups/roles sync feature, so its
    possible to use user attributes for permission handling
 - 2006-08-02 fixed bug#[1283](http://bugs.otrs.org/show_bug.cgi?id=1283) - test for modules executed in cronjobs

# 2.1.0 beta1 2006-08-02
 - 2006-07-31 added cmd option for bin/opm.pl to find package of file
    e. g. bin/opm.pl -a file -p Kernel/System/FileA.pm
 - 2006-07-31 added sleep in bin/PostMasterPOP3.pl after 10 (2 sec) and
    25 (3 sec) emails on one stream (protect server against overload)
 - 2006-07-31 added PDF output feature for stats module and ticket search results
 - 2006-07-26 updated to cpan MIME::Tools 5.420
 - 2006-07-26 changed ticket escalation method, escalation start will
    be reseted after every "new" customer message and after agent
    communication to customer
 - 2006-07-25 added new link object functions and db table link\_object changes
 - 2006-07-23 added \<OTRS\_CUSTOMER\_DATA\_\*\> tags to auto responses
 - 2006-07-23 added support of mssql database server (experimental)
 - 2006-07-18 added new feature to sync ldap groups into otrs roles
    (see more in Kernel/Config/Defaults.pm under UserSyncLDAPGroupsDefination
    and UserSyncLDAPRolesDefination)
 - 2006-07-14 new stats framework implemented :-)
 - 2006-07-14 fixed bug#[1258](http://bugs.otrs.org/show_bug.cgi?id=1258) - changed language description from Traditional Chinese
    to Simplified Chinese
 - 2006-07-04 fixed bug#[1151](http://bugs.otrs.org/show_bug.cgi?id=1151) - Error when changing customer on ticket in
 - 2006-07-11 improved performance of ticket search mask (in cases with
    over 500 Agents and over 50 Groups) by adding GroupMemberInvolvedList()
    and modify GroupMemberList(), GroupGroupMemberList(), GroupRoleMemberList()
    and GroupUserRoleMemberList() at Kernel/System/Group.pm
 - 2006-07-11 fixed bug#[1132](http://bugs.otrs.org/show_bug.cgi?id=1132) - Wrong display of escalation time
 - 2006-07-04 fixed bug#[1151](http://bugs.otrs.org/show_bug.cgi?id=1151) - Error when changing customer on ticket in
    TicketStatusView
 - 2006-06-26 added ticket watcher feature, per default it's disabled
 - 2006-06-22 fixed bug#[1240](http://bugs.otrs.org/show_bug.cgi?id=1240) - Tickets not shown in "New messages" if
    Auto Response "Reply" is active
 - 2006-06-14 fixed bug#[1206](http://bugs.otrs.org/show_bug.cgi?id=1206) - When no RELEASE file is available, no
    product and version is displaied and strange messages apear in the
    apache error log;  using standard values in this case now
 - 2006-06-13 added public frontend module to serve local repository as
    remote repository (accessable via IP authentication)
 - 2006-06-13 fixed bug#[1154](http://bugs.otrs.org/show_bug.cgi?id=1154) - Problem in displaying pending tickets
    in agent mailbox
 - 2006-06-07 improved postmaster follow up detection by scanning email
    body, attachment and/or raw email (all is disabled by default)
 - 2006-06-02 fixed bug#[1023](http://bugs.otrs.org/show_bug.cgi?id=1023) - Comma in From field creates multiple emails
    in webform.pl
 - 2006-04-27 fixed IE problem with image-buttons
    involved files: AdminSysConfigEdit.dtl and AdminSysConfig.pm
 - 2006-04-26 fixed format bug in Package Manager - PackageView
 - 2006-04-06 moved to read any language files located under
    Kernel/Language/xx\_\*.pm at each request to have any translated words
    e. g. for navigation bar available (Kernel/Language/xx\_Custom.pm is
    still used as latest source file)
 - 2006-03-28 added config option to show ticket title in main header
    of frontend (e. g. QueueView, ZoomView and Mailbox)
 - 2006-03-24 moved from "otrs" to "otrs-x.x.x" directory in
    tar.gz / tar.bz download format
 - 2006-03-22 added article free text attrubutes
 - 2006-03-21 moved from Kernel::Output::HTML::Generic to
    Kernel::Output::HTML::Layout - all sub modules localted under
    Kernel/Output/HTML/Layout\*.pm will ne loaded automatically
    at runtime
 - 2006-03-20 improved ticket zoom to shown attachments with
    html title about attachment info (name, size, ...)
 - 2006-03-20 added use of current config values in admin sysconfig
    fulltext search
 - 2006-03-11 fixed some spelling mistakes for the English original in
    language templates and language files
 - 2006-03-10 added admin init (Kernel/Modules/AdminInit.pm) to init
    config files .xml-\>.pm after a new setup (after initial root login)
 - 2006-03-04 splited Kernel::Modules::AgentTicketPhone into
    two modules Kernel::Modules::AgentTicketPhone and
    Kernel::Modules::AgentTicketPhoneOutbound (phone calls for existing
    tickets) also templates are renamed!
 - 2006-03-04 cleanup for ticket event names (added compat mode):
    TicketCreate, TicketDelete, TicketTitleUpdate, TicketUnlockTimeoutUpdate,
    TicketEscalationStartUpdate, TicketQueueUpdate (MoveTicket),
    TicketCustomerUpdate (SetCustomerData), TicketFreeTextUpdate
    (TicketFreeTextSet), TicketFreeTimeUpdate (TicketFreeTimeSet),
    TicketPendingTimeUpdate (TicketPendingTimeSet), TicketLockUpdate (LockSet),
    TicketStateUpdate (StateSet), TicketOwnerUpdate (OwnerSet),
    TicketResponsibleUpdate, TicketPriorityUpdate (PrioritySet), HistoryAdd,
    HistoryDelete, TicketAccountTime, TicketMerge, ArticleCreate,
    ArticleFreeTextUpdate (ArticleFreeTextSet), ArticleUpdate, ArticleSend,
    ArticleBounce, ArticleAgentNotification, (SendAgentNotification),
    ArticleCustomerNotification (SendCustomerNotification), ArticleAutoResponse
    (SendAutoResponse), ArticleFlagSet
 - 2006-03-04 added own X-OTRS-FollowUp-\* header if Queue, State, Priority,
    ...  should be changed with follow up emails (see: doc/X-OTRS-Headers.txt)
 - 2006-03-04 reworked "config options" and "interface" of \_all\_ agent
    ticket interfaces to get is clear
 - 2006-03-03 replaced ticket config option "Ticket::ForceUnlockAfterMove"
    with ticket event module "Ticket::EventModulePost###99-ForceUnlockOnMove"
 - 2006-03-03 replaced ticket config option "Ticket::ForceNewStateAfterLock"
    with ticket event module "Ticket::EventModulePost###99-ForceStateChangeOnLock"
 - 2006-03-03 added "responsible" ticket feature!
    (db update with scripts/DBUpdate-to-2.1.(mysql|postgres).sql)
 - 2006-03-03 added persian translation (incl. TextDirection support)
    - Thanks to Amir Shams Parsa!
 - 2006-02-16 added default ticket event module to reset ticket owner
    after move action (it's disable per default)
 - 2006-02-10 added default next state in ticket forward
 - 2006-02-10 added OTRS\_Agent\_\* tags like OTRS\_Agent\_UserFirstname and
    OTRS\_Agent\_UserLastname for salutation and signature templates
 - 2006-02-05 added update and insert via admin sql box
 - 2006-02-05 'removed old compat files' Kernel/Config/Files/Ticket.pm
    and Kernel/Config/Files/TicketPostMaster.pm
 - 2006-02-05 added 8 more ticket free text fields
    (db update with scripts/DBUpdate-to-2.1.(mysql|postgres).sql)
 - 2006-01-07 added SendNoNotification option for MoveTicket(),
    LockSet() and OwnerSet() in Kernel/System/Ticket.pm (used in
    GenericAgent to do some admin stuff).
 - 2005-12-29 added online repository access for bin/opm.pl
 - 2005-12-29 added Delete and Spam config option to
    Kernel/Config/Files/Ticket.xml for Ticket::Frontend::MenuModule
 - 2005-12-21 added column type check in xml database defination
 - 2005-12-20 added unit test system
 - 2005-12-17 improved admin view of session management
 - 2005-12-04 moved FAQ from framework to own application module
    (can be installed over opm online repository now)
 - 2005-11-27 moved otrs archive directory for download and in RPMs
    from otrs to otrs-x.x.x
 - 2005-11-20 added multi pre application module support, just
    define it like:
```
    $Self->{PreApplicationModule}->{AgentInfo} = 'Kernel::Modules::AgentInfo';
```

# 2.0.5 2007-05-22
 - 2007-05-22 fixed bug#[1842](http://bugs.otrs.org/show_bug.cgi?id=1842) - Cross-Site Scripting Vulnerability
 - 2007-01-11 fixed bug#[1515](http://bugs.otrs.org/show_bug.cgi?id=1515) - Some GenericAgent names don't work
    (e. g. names with +)
 - 2007-01-11 fixed bug#[1496](http://bugs.otrs.org/show_bug.cgi?id=1496) - GenericAgent: "Ticket created last..."
    does not work
 - 2006-07-11 fixed bug#[1132](http://bugs.otrs.org/show_bug.cgi?id=1132) - Wrong display of escalation time
 - 2006-07-11 added missing utf-8 encoding in agent and customer auth
 - 2006-07-11 added missing utf-8 encoding customer user backend
 - 2006-07-04 changed language description from Traditional Chinese to
    Simplified Chinese (bug#[1258](http://bugs.otrs.org/show_bug.cgi?id=1258))
 - 2006-07-04 fixed bug#[1151](http://bugs.otrs.org/show_bug.cgi?id=1151) - Error when changing customer on ticket in
    TicketStatusView
 - 2006-06-17 fixed bug#[1240](http://bugs.otrs.org/show_bug.cgi?id=1240) - Tickets not shown in "New messages" if
    Auto Response "Reply" is active
 - 2006-06-14 fixed bug#[1206](http://bugs.otrs.org/show_bug.cgi?id=1206) - When no RELEASE file is available, no
    product and version is displaied and strange messages apear in the
    apache error log;  using standard values in this case now
 - 2006-06-13 fixed bug#[1154](http://bugs.otrs.org/show_bug.cgi?id=1154) - Problem in displaying pending tickets
    in agent mailbox
 - 2006-06-02 fixed bug#[1023](http://bugs.otrs.org/show_bug.cgi?id=1023) - Comma in From field creates multiple emails
    in webform.pl
 - 2006-03-24 added SUSE 10.x RPM support
 - 2006-03-24 fixed bug#[925](http://bugs.otrs.org/show_bug.cgi?id=925) - Binary Attachments incorrectly utf-8
    encoded in ticket replies
 - 2006-03-23 fixed links to new phone/email ticket after a new
    customer is created via Kernel/Modules/AdminCustomerUser.pm
 - 2006-03-21 update of Portuguese language file  - Thanks to
    Manuel Menezes de Sequeira)
 - 2006-03-18 added Greek translation - Thanks to Stelios Maistros!
 - 2006-03-16 fixed bug#[991](http://bugs.otrs.org/show_bug.cgi?id=991) - changed $Data{} to $QData{} in Ticket.xml
    and Ticket.pm config files to solve problem when answering requests
    that contain HTML tags
 - 2006-03-16 updated Dutch language file - Thanks to Richard Hinkamp!
 - 2006-03-16 added Slovak translation
 - 2006-03-10 fixed/removed die in Kernel/System/AuthSession/FS.pm
    -=\> GetSessionIDData() - not wanted to die if nn SessionID is given
 - 2006-03-08 added Danish translation - Thanks to Thorsten Rossner!
 - 2006-03-08 updated Norwegian translation - Thanks to Knut Haugen
 - 2006-03-08 fixed some spelling mistakes for the English original in
    language templates and language files
 - 2006-02-12 updated Brazilian Portuguese translation -Thanks to
    Fabricio Luiz Machado!
 - 2006-02-01 fixed missing translation after new ticket was created
 - 2006-02-01 added long month translation for calendar popup
 - 2006-02-01 changed Kernel/System/Spelling.pm to work with (a|i)spell
    on Windows systems
 - 2006-01-30 added \<OTRS\_TICKET\_\*\> and \<OTRS\_CONFIG\_\*\> support to
    auto respons templates
 - 2006-01-29 fixed/removed wrong config option
    "Ticket::Frontend::QueueSortDefault", added own config option for
    StatusView of tickets
 - 2006-01-29 fixed bug#[1047](http://bugs.otrs.org/show_bug.cgi?id=1047) forward fails if " is in From
 - 2006-01-29 fixed ldap authentication if application charset is
    e. g. iso-8859-1 and not utf-8
 - 2006-01-26 fixed some spelling mistakes in
    Kernel/Config/Files/Ticket.xml and Kernel/Config/Files/Framework.xml
 - 2006-01-24 Added X-Spam-Level to config files to have the possibility
     to filter for this header with PostMasterFilter
 - 2006-01-23 fixed bug#[1069](http://bugs.otrs.org/show_bug.cgi?id=1069) - Problem when the name of a GenericAgent
    job was updated
 - 2006-01-08 fixed PostMaster filter admin interface if wrong syntax
    regexp is used (don't save invalid regexp because no email can be
    received)
 - 2006-01-07 added bin/CheckSum.pl and also ARCHIVE file to include
    md5 sum archive of current distribution
 - 2006-01-07 improved PostMaster if no article can be created
 - 2005-12-29 fixed internal server error if in sysconfig search
     is used
 - 2005-12-29 fixed "enter" submit bug in sysconfig (e. g. reset first
    item in the edit site)
 - 2005-12-29 fixed ArticleAttachmentIndex() - wrong index count in
    fs lookup - attachment icons sometimes not shown
 - 2005-12-29 added added missing class="button" in submit type="submit"
    of .dtl templates
 - 2005-12-27 fixed default note-type and default state-type in ticket
    pending mask
 - 2005-12-23 fixed stats/graph error message 'Can't call method "png"
    on an undefined value at ...'
 - 2005-12-21 fixed missing delete on time\_accounting in
    Kernel/System/Ticket/Article.pm if article got deleted
 - 2005-12-20 improved die if xml is invalid in Kernel/System/XML.pm
 - 2005-12-12 added compat config option for compose answer to
    replace original sender with current customers email address
 - 2005-11-19 updated French language file, thanks to Yann Richard
 - 2005-12-04 fixed bug#[1025](http://bugs.otrs.org/show_bug.cgi?id=1025) - ORA-01400: cannot insert NULL into ("OTRS"
    ."CUSTOMER\_USER"."COMMENTS"
 - 2005-12-04 fixed bug#[1018](http://bugs.otrs.org/show_bug.cgi?id=1018) - initial\_insert.sql, oracle error ORA-01400:
    cannot insert NULL into
 - 2005-12-03 fixed std attachment feature (no attachment after
    additional fiel upload) in agent ticket compose
 - 2005-12-01 improved database Quote() for integer, also allow +|-
    in integer
 - 2005-11-30 fixed order of create attributes (TicketCreate(), TicketFreeTime(),
    TicketFreeTime(), ArticleCreate(), ...) on customer ticket creation
 - 2005-11-29 fixed bug#[1010](http://bugs.otrs.org/show_bug.cgi?id=1010) - ORA-00972 Identifier is too long for oracle
 - 2005-11-29 fixed bug#[1011](http://bugs.otrs.org/show_bug.cgi?id=1011) - ORA-01408: such column list already indexed,
    Oracle error
 - 2005-11-24 fixed wrong follow up notification (to all agents)
    via customer panel if ticket is already closed
 - 2005-11-19 updated Dutch language file, thanks to Richard Hinkamp
 - 2005-11-15 fixed not working -r option in scripts/backup.pl
    (-r == removed backups older then -r days)
 - 2005-11-13 remove leading and trailing spaces in ldap filter for
    agent and customer authentication

# 2.0.4 2005-11-12
 - 2005-11-11 fixed bug#[695](http://bugs.otrs.org/show_bug.cgi?id=695) - From-Header missing quoting if : is used
 - 2005-11-11 fixed bug#[863](http://bugs.otrs.org/show_bug.cgi?id=863) - error after using faq in tickets
 - 2005-11-11 fixed bug#[906](http://bugs.otrs.org/show_bug.cgi?id=906) - group names are translated in admin interface
 - 2005-11-08 added missing default pending note type
 - 2005-11-05 fixed bug#[922](http://bugs.otrs.org/show_bug.cgi?id=922) - rfc quoteing for emails with sender
    like info@example.com \<info@example.com\> is now
    "info@example.com" \<info@example.com\>
 - 2005-11-05 fixed bug#[639](http://bugs.otrs.org/show_bug.cgi?id=639) - problems with german "umlaute" and
    "," in realname if OE is the sender system
 - 2005-10-31 moved to default download type as attachment (not inline)
    for a better security default setting
 - 2005-10-31 fixed bug in html mime online viewer module
    (Kernel/Modules/AgentTicketAttachment.pm)
 - 2005-10-31 added missing ContentType in ArticleAttachmentIndex() if
    fs lookup is used (Kernel/System/Ticket/ArticleStorage\*.pm)
 - 2005-10-31 improved sql quote with type (String, Integer and Number)
    to have a better security
 - 2005-10-30 removed not needed german default salutation and signature
    from scripts/database/initial\_insert.sql
 - 2005-10-30 improved oracle backend with max length of index and foreign
    key ident, fixed triger creation - removed not needed / if DBI is used.
 - 2005-10-25 improved bin/opm.pl to uninstall packages via
   -p package-verions of installed package
 - 2005-10-25 moved to default selected priority and state in
    first mask of phone and email mask
 - 2005-10-25 fixed lost of original .backup and .save files if
    packages are reinstalled
 - 2005-10-25 added html access keys for customer panel
 - 2005-10-24 moved oracle database param LongReadLen to 4\*1024\*1024 to
   store biger attachments
 - 2005-10-23 fixed small bug for WorkingTime calculation
 - 2005-10-22 fixed bug#[971](http://bugs.otrs.org/show_bug.cgi?id=971) - Invalid agents get LockTimeOut notification
 - 2005-10-21 fixed bug#[948](http://bugs.otrs.org/show_bug.cgi?id=948) - Invalid agents should not longer get follow-ups
 - 2005-10-21 fixed bug#[957](http://bugs.otrs.org/show_bug.cgi?id=957) - Got "no ArticleID" error when viewing queues
 - 2005-10-20 improved html of admin auto responses \<-\> queue relation
 - 2005-10-20 fixed unlock of closed bulk-action tickets
 - 2005-10-20 fixed calendar lookup in admin generic agent time
    selection
 - 2005-10-18 added sortfunction for hashes and array in admin interface
    -\> SysConfig
 - 2005-10-17 fixed bug#[792](http://bugs.otrs.org/show_bug.cgi?id=792) - GPG 1.4.1 is no handled correct
 - 2005-10-17 fixed missing db quoting in Kernel/System/Auth/DB.pm
 - 2005-10-15 small rework of Kernel/Language/de.pm with improved wording
 - 2005-10-15 fixed bug#[889](http://bugs.otrs.org/show_bug.cgi?id=889) - fixed QuoteSignle typo and added changed
    QuoteSingle for PostgreSQL
 - 2005-10-15 Added correct quoting in Filter.pm when deleting a
    PostMasterFilter rule
 - 2005-10-13 changed merge article type to note-external to be shown
    in the customer interface, other way the customer will get an no
    permission screen for this ticket
 - 2005-10-13 improved bin/PendingJobs.pl to send reminder notifications
    to queue subscriber if ticket is unlocked (not longer to the ticket
    owner).
 - 2005-10-13 improved html style of package view in admin interface
 - 2005-10-11 added missing SessionUseCookie config setting to SysConfig
 - 2005-10-10 fixed time (hour and minute) selection on 0x default selections
    in framework (00 selection if 0x was selected)
 - 2005-10-08 removed not longer needed uniq customer id search in
    agent interface
 - 2005-10-06 fixed input check of TimeVacationDays and
    TimeVacationDaysOneTime in admin interface (just integer values allowed)
 - 2005-10-05 fixed bug#[947](http://bugs.otrs.org/show_bug.cgi?id=947) - Admin -\> SelectBox: Insert, Delete, Update
    etc. possible
 - 2005-10-04 added MainObject as required for Kernel/Output/HTML/Generic.pm
 - 2005-10-01 fixed time (minute and hour) default selection if 01 minues
    or 01 hours are used

# 2.0.3 2005-09-28
 - 2005-09-28 fixed typo in config option name for csv search output,
    so configable csv search output is now possible
 - 2005-09-28 improved speed of Kernel::System::AgentTicketMailbox
    (added page jumper)
 - 2005-09-28 fixed not deleting var/tmp/XXXXXX.tmp files
 - 2005-09-26 fixed not working cache in Kernel::System::User-\>UserGetData()
 - 2005-09-24 fixed small oracle database driver bugs
 - 2005-09-24 added initial user groups add (UserSyncLDAPGroups) after
    initial login
 - 2005-09-19 moved ldap user sync after login from Kernel/System/User.pm
    to Kernel/System/Auth/LDAP.pm (already an existing ldap module)
 - 2005-09-19 fixed ticket search create day and month selection
    (e. g. 009) if input fields (no pull downs) are used
 - 2005-09-19 removed js from change ticket customer
 - 2005-09-19 fixed bin/mkStats.pl - no attachments are sent
 - 2005-09-18 removed auto result in object link mask (search submit
    required first!) and improved html design
 - 2005-09-17 added DefaultTheme::HostBased config option for host
    name based theme selection
 - 2005-09-14 fixed move action module in
    Kernel/Output/HTML/Standard/AgentTicketQueueTicketViewLite.dtl
 - 2005-09-13 fixed ticket search with IE if many options are selected
 - 2005-09-11 improved html style in customer panel
 - 2005-09-09 added Chinese translation, thanks to zuowei
 - 2005-09-07 added admin "su" (Switch To User) feature (it's disabled
    per default)
 - 2005-09-05 moved to german "Ihr OTRS Benachrichtigungs-Master" wording
    in default notifications
 - 2005-09-05 added missing default state and article type option to
    Kernel/Modules/AgentTicketClose.pm
 - 2005-09-04 changed max. session time from 9h to 10h
 - 2005-09-04 added missing config options in
    Kernel/Modules/AgentTicketEmail.pm and Kernel/Modules/AgentTicketPhone.pm
    for show count of customer ticket history
 - 2005-09-04 added missing Kernel::Modules::AgentLookup module registration
 - 2005-09-04 fixed ArticleGetContentPath() in Kernel/System/Ticket/Article.pm,
    removed "uninitialized value" warning if no content path is set in db'
 - 2005-09-04 fixed ArticleWriteAttachment() in
    Kernel/System/Ticket/ArticleStorageFS.pm, added ContentPath lookup
 - 2005-09-04 fixed SubGroup of Ticket::Frontend::CustomerInfo(Queue|Zoom|
    Compose), Frontend::Agent is the correct one
 - 2005-09-04 added possibe state selection in owner update screen
 - 2005-08-29 fixed bug#[905](http://bugs.otrs.org/show_bug.cgi?id=905) - fixed SuSE meta header info, try-restart
    arg, and some smaller fixes
 - 2005-08-26 added package manager deploy check in admin interface, if
    package is really deployed (compare files in filesystem and package)
 - 2005-08-26 added time accounting option to ticket move mask
 - 2005-08-26 replaced localtime(time) with Kernel::System::Time core
    module in several files
 - 2005-08-26 removed empty thai translation file
 - 2005-08-24 replaced scripts/restore.sh and scripts/backup.sh with improved
    scripts/backup.pl and scripts/restore.pl scripts
 - 2005-08-24 added SMIME and PGP environment check in admin
    interface
 - 2005-08-23 fixed bug#[891](http://bugs.otrs.org/show_bug.cgi?id=891) - typo in Login.dtl

# 2.0.2 2005-08-22
 - 2005-08-19 fixed bug#[811](http://bugs.otrs.org/show_bug.cgi?id=811) - 404 Error for role link OTRS::Admin::Role
    \<-\> User
 - 2005-08-19 Added new config parameter to include a envelope from
    header in outgoing notifications for customer and agents:
```perl
   $Self->{"SendmailNotificationEnvelopeFrom"} = '';
```
 - 2005-08-19 fixed bug#[846](http://bugs.otrs.org/show_bug.cgi?id=846) - empty envelope from on notifications
 - 2005-08-19 fixed bug#[879](http://bugs.otrs.org/show_bug.cgi?id=879) - "Wide character in subroutine" - mails with
    attachments in utf-8 mode
 - 2005-08-19 fixed bug#[871](http://bugs.otrs.org/show_bug.cgi?id=871) - Erroneous Content-Length fields are sent
    when downloading attachments
 - 2005-08-19 fixed bug#[861](http://bugs.otrs.org/show_bug.cgi?id=861) - Problems in faq attachments and postgresql
    backend
 - 2005-08-19 updated nb\_NO translation again - thanks to Espen Stefansen!
 - 2005-08-18 enabled customer PGP and SMIME preferences if PGP or
    SMIME is enabeled
 - 2005-08-18 fixed broken download of public SMIME certs
 - 2005-08-18 fixed bug#[874](http://bugs.otrs.org/show_bug.cgi?id=874) - password plaintext in UserLastPw
 - 2005-08-17 fixed bug#[872](http://bugs.otrs.org/show_bug.cgi?id=872) - CustomerCalendarSmall not working, module
    not registered
 - 2005-08-16 fixed bug#[847](http://bugs.otrs.org/show_bug.cgi?id=847) - Broken download of public PGP keys via
    customer preferences pannel
 - 2005-08-16 fixed bug#[862](http://bugs.otrs.org/show_bug.cgi?id=862) - wrong sum for time acounting
 - 2005-08-12 fixed bug#[870](http://bugs.otrs.org/show_bug.cgi?id=870) - wrong parameter order in
    Kernel::System::Ticket::Article::SendCustomerNotification routine
 - 2005-08-12 removed default selections (UserSalutation) from CustomerUser
    config
 - 2005-08-12 updated nb\_NO translation - thanks to Espen Stefansen!
 - 2005-08-10 updated pt\_BR translation - thanks to Glau Messina!
 - 2005-08-09 added config option for defaul sortby and order in ticket
    search result in customer and agent interface
 - 2005-08-09 fixed bug#[822](http://bugs.otrs.org/show_bug.cgi?id=822) - Missing FAQID in TicketZoom for linked
    FAQ article
 - 2005-08-08 fixed bug#[815](http://bugs.otrs.org/show_bug.cgi?id=815) - strange line in history
 - 2005-08-08 added add/delete option in SysConfig for NavBar
 - 2005-08-07 fixed bug#[658](http://bugs.otrs.org/show_bug.cgi?id=658) - Typo in installer.pl
 - 2005-08-06 fixed bug#[836](http://bugs.otrs.org/show_bug.cgi?id=836) - GenericAgent (GUI based) seem to ignore
    priority - added some db quote
 - 2005-08-06 changed description text of Ticket::Frontend::PendingDiffTime
    config setting
 - 2005-08-06 fixed not shown linked objects in faq zoom and print view
 - 2005-08-06 removed not needed Kernel/Modules/FAQState.pm and not
    needed config setting
 - 2005-08-06 added warning message in customer panel on account create
    if invalid email address is given
 - 2005-08-05 fixed bug#[850](http://bugs.otrs.org/show_bug.cgi?id=850) - Can't locate object method "KeySearch"
    error"
 - 2005-08-05 fixed bug#[860](http://bugs.otrs.org/show_bug.cgi?id=860) - Error in AgentTicketForward.pm, missing
    title in the warning for the owner check
 - 2005-08-04 updated it translation - thanks to Giordano Bianchi!
 - 2005-08-04 changed default state of new faq articles to 'internal (agent)'
 - 2005-08-04 fixed bug#[877](http://bugs.otrs.org/show_bug.cgi?id=877) - Error when merging tickets - Can't call
    method "LockSet" on an undefined value at Kernel/System/Ticket.pm line 3720
 - 2005-08-04 added missing merge params to Kernel/Config/Files/Ticket.xml

# 2.0.1 2005-08-01
 - 2005-07-31 fixed bug#[602](http://bugs.otrs.org/show_bug.cgi?id=602) - CustomerIDs and CustomerUserIDs are lowercased
    before being assigned to a ticket
 - 2005-07-31 fixed bug#[600](http://bugs.otrs.org/show_bug.cgi?id=600) - Wide character death in IPC.pl
 - 2005-07-31 fixed bug#[593](http://bugs.otrs.org/show_bug.cgi?id=593) - Need ID or Name in log file
 - 2005-07-31 fixed missing recover of .save files on uninstall of
    .opm packages
 - 2005-07-31 fixed DBUpdate-to-2.0.postgresql.sql - alter table
    time\_accounting - DECIMAL(10,2), fixed UPDATE ticket SET
    escalation\_start\_time
 - 2005-07-31 fixed bug#[566](http://bugs.otrs.org/show_bug.cgi?id=566) - Wide character in print, ArticleStorageFS.pm
 - 2005-07-29 fixed required time accounting option in js of phone
    and email ticket
 - 2005-07-29 fixed bug#[817](http://bugs.otrs.org/show_bug.cgi?id=817) - added missing freetime1, freetime2 in
    otrs-schema.postgresql.sql and scripts/DBUpdate-to-2.0.postgresql.sql
 - 2005-07-29 added hour and minutes in time selection in ticket search
    in admin, agent and customer interface - bug#[843](http://bugs.otrs.org/show_bug.cgi?id=817)
 - 2005-07-28 updated es tranlsation file by Jorge Becerra - Thanks!
 - 2005-07-28 updated translation files
 - 2005-07-28 fixed bug in ticket expand view
 - 2005-07-28 just framework options for web installer, removed
    ticket options
 - 2005-07-28 moved to global GetExpiredSessionIDs() for
    bin/DeleteSessionIDs.pl and Kernel/System/AuthSession.pm
 - 2005-07-24 added missing from realname on phone follow up in
    Kernel::Modules::AgentTicketPhone
 - 2005-07-24 improved scripts/tools/charset-convert.pl tool with
    get opt params and with file option
 - 2005-07-24 added block feature for system stats
 - 2005-07-24 added auto removed of expired sessions on CreateSessionID()
 - 2005-07-23 removed access of admin group to stats module (because
    of existing own stats group)
 - 2005-07-23 improved page title with ticket number of
    Kernel::Modules::AgentTicketPlain frontend module
 - 2005-07-23 moved ticket unlock after merge from frontend module to
    Kernel::System::Ticket (because it's a core function)
 - 2005-07-23 disabled PGP and SMIME in default setup (because if it's
    not configured there are many warnings in error log)

# 2.0.0 beta6 2005-07-19
 - 2005-07-18 added ticket search option for ticket free time
 - 2005-07-18 fixed not shown calendar lookup icons
 - 2005-07-18 added date-check (JavaScript)
 - 2005-07-18 added number-check for TimeUnits (JavaScript)
 - 2005-07-17 improved speed of xml parsing - also speed of SysConfig
 - 2005-07-16 fixed module permission check bug in agent handle
 - 2005-07-15 fixed bug#[821](http://bugs.otrs.org/show_bug.cgi?id=821) - Admin SysConfig (Values cannot be activated)

# 2.0.0 beta5 2005-07-14
 - 2005-07-14 removed not needed admin dtls from lite theme, because this
    standard is used as default
 - 2005-07-14 removed not needed customer dtls from lite theme, because this
    standard is used as default
 - 2005-07-13 web installer rewritten - moved to block feature
 - 2005-07-13 added check in bin/SetPermissions.sh if . files exists
 - 2005-07-09 splited big sub groups Frontend::Agent in smaller groups in
    Kernel/Config/Files/Ticket.xml
 - 2005-07-08 fixed bug with double session id bug after login
 - 2005-07-08 improved notify layer with error or notice icon
 - 2005-07-08 fixed bug in Kernel/System/Group.pm GroupMemberList() if GroupID
    is given (possible in AgentTicketOwner.pm if roles are used)
 - 2005-07-08 added postmaster follow up with X-OTRS-Header update function
 - 2005-07-08 fixed win32 binmode problem in Kernel/System/Web/UploadCache/FS.pm
 - 2005-07-08 fixed wrong named templates for customer ticket history
    in Kernel/Modules/AgentTicketEmail.pm and Kernel/Modules/AgentTicketPhone.pm
 - 2005-07-04 improved bin/otrs.addQueue with -s \<SYSTEMADDRESSID\>
    and -c \<COMMENT\> params.

# 2.0.0 beta4 2005-07-03
 - 2005-07-03 added ticket free time feature - take care, you need to
    alter the ticket table:

```mysql
    ALTER TABLE ticket ADD freetime1 DATETIME;
    ALTER TABLE ticket ADD freetime2 DATETIME;
```

new config options are:

```perl
    $Self->{"TicketFreeTimeKey1"} = 'Termin1';
    $Self->{"TicketFreeTimeDiff1"} = 0;
    $Self->{"TicketFreeTimeKey2"} = 'Termin2';
    $Self->{"TicketFreeTimeDiff2"} = 0;
```
 - 2005-07-03 fixed bug#[797](http://bugs.otrs.org/show_bug.cgi?id=797) - renamed AdminEmail to Admin Notification
    in admin interface.
 - 2005-07-03 rewritten faq customer and public area
 - 2005-07-03 fixed bug#[799](http://bugs.otrs.org/show_bug.cgi?id=799) - improved FAQ article for utf8 support
    http://faq.otrs.org/otrs/public.pl?Action=PublicFAQ&ID=3
 - 2005-07-03 added fixed/auto update for faq articles with no number
 - 2005-07-03 fixed bug#[800](http://bugs.otrs.org/show_bug.cgi?id=800) - FAQ insert overwrites response by default
 - 2005-07-03 removed CGI cpan module from dist because of incomapt.
   for mod\_perl 1.99 and mod\_perl 2.00
 - 2005-07-01 added datatype DECIMAL support for time\_accounting table
    (changed datatype of time\_unit in time\_accounting table)
 - 2005-06-29 fixed user language selection in customer panel
 - 2005-06-28 fixed default customer valid selection in admin interface
 - 2005-06-27 fixed XML::Parser::Lite backend with xml decode
 - 2005-06-27 updated to cpan CGI v3.10

# 2.0.0 beta3 2005-06-21
 - 2005-06-13 fixed bug#[759](http://bugs.otrs.org/show_bug.cgi?id=759) - error when changing default dictionary
 - 2005-06-13 fixed bug#[773](http://bugs.otrs.org/show_bug.cgi?id=773) - NotificationAgentOnline needs TimeObject
 - 2005-06-12 fixed bug#[776](http://bugs.otrs.org/show_bug.cgi?id=776) - when adding a new user I got error message
 - 2005-06-11 added XML::Parser support for Kernel::System::XML
 - 2005-06-07 fixed bug#[771](http://bugs.otrs.org/show_bug.cgi?id=771) - Customer Web Interface - Attachment
    View Error' Kernel/Modules/CustomerTicketZoom.pm
 - 2005-06-06 added experimental db2 support - thanks to Friedmar Moch!
 - 2005-06-06 removed foreign key for queue\_id in pop3\_account, fixed
    indexes for article\_flag

# 2.0.0 beta2 2005-05-16
 - 2005-05-16 fixed bug#[644](http://bugs.otrs.org/show_bug.cgi?id=644) - GenericAgent module calls should not keep
    the error msg secret :-), moved to Kernel::System::Main
 - 2005-05-16 fixed bug#[733](http://bugs.otrs.org/show_bug.cgi?id=733) - Postgres: TicketOverview doesn't work in April
 - 2005-05-14 fixed bug#[737](http://bugs.otrs.org/show_bug.cgi?id=737) - cannot add FAQ categories in 2.0 beta1
 - 2005-05-08 fr translation updated by Yann Richard - thanks!
 - 2005-05-08 fixed bug#[729](http://bugs.otrs.org/show_bug.cgi?id=729) - Problem removing example FAQ-entry from FAQ
 - 2005-05-08 fixed bug#[730](http://bugs.otrs.org/show_bug.cgi?id=730) - Problem with FAQ nav bar
 - 2005-05-08 fixed bug#[734](http://bugs.otrs.org/show_bug.cgi?id=734) - Timezone not reflected in DB Tables (ticket
    create time, etc.)
 - 2005-05-07 fixed language translation files
 - 2005-05-07 fixed bug#[647](http://bugs.otrs.org/show_bug.cgi?id=647) - Allow setting of default language for FAQs
 - 2005-05-07 fixed bug#[686](http://bugs.otrs.org/show_bug.cgi?id=686) - defect attachments on download with firefox
 - 2005-05-07 added html access keys for nav bar
```
    general:
    h = home
    l = logout
    o = overview
    n = new
    s = search
    p = preferences
    a = admin interface
    t = ticket interface
    f = faq interface
    g = formular submit

    ticket:
    o = queue view
    n = phone ticket
    e = email ticket
    k = locked ticket list
    m = new messages in locked ticket list
```
 - 2005-05-07 fixed bug#[719](http://bugs.otrs.org/show_bug.cgi?id=719) - Timezone setting (US EDT -4) causes
    "Session Timeout"
 - 2005-05-04 removed html wrap from ticket text areas
 - 2005-05-04 added ticket event module layer
 - 2006-05-04 fixed priority default selection in priority screen

# 2.0.0 beta1 2005-05-02
 - 2005-04-30 fixxed bug#[712](http://bugs.otrs.org/show_bug.cgi?id=712) - Reports ignore setting for http-type
 - 2005-04-22 added ticket merge feature
 - 2005-04-14 fixed From in article of AgentTicketPending and
    AgentTicketMove frontend module
 - 2005-04-10 added check to ticket core function Move(), send no
    ticket move info for closed tickets
 - 2005-04-08 updated CGI module to 3.07
 - 2005-02-17 Kernel/Config/Modules\*.pm not longer needed, moved
    to config filer
 - 2005-02-17 renamed \_all\_ ticket frontend modules and templates
    to AgentTicket\* (cleanup)
 - 2005-02-15 renamed \_all\_ ticket config options! and moved to
    own config files:
      - Kernel/Config/Files/Ticket.pm
      - Kernel/Config/Files/TicketPostMaster.pm
    --\>\> old ticket config setting will not longer work \<\<--
 - 2005-02-11 imporved agent ticket search with created options
    (berated by user, created in queue)
 - 2004-12-04 moved PGP and SMIME stuff to Kernel/System/Email.pm
    to be more generic
 - 2004-11-27 added config option TicketHookDivider
    [Kernel/Config.pm]

```perl
    # (the divider between TicketHook# and number)
    $Self->{TicketHookDivider} = ': ';
#    $Self->{TicketHookDivider} = '';
```
 - 2004-11-24 renamed from bin/SendStats.pl to bin/mkStats.pl and added
    fs output e. g.

```bash
    shell\> bin/mkStats.pl -m NewTickets -p 'Month=1&Year=2003' -r me@host.com -b text
    NOTICE: Email sent to 'me@host.com'
    shell\> bin/mkStats.pl -m NewTickets -p 'Month=1&Year=2003'  -o /data/dir
    NOTICE: Writing file /data/dir/NewTickets_2004-11-24_14-38.csv
    shell\>
```
 - 2004-11-24 added postmaster filter to
 - 2004-11-16 a xml 2 sql processor which is using Kernel/System/DB.pm
    and Kernel/System/DB/\*.pm' bin/xml2sql.pl to generate database based
    sql syntax
 - 2004-11-16 moved database settings from Kernel/System/DB.pm to
    Kernel/System/DB/\*.pm (mysql|postgresql|maxdb|oracle|db2)
 - 2004-11-16 added fast cgi (fcgi) handle to (bin/fcgi-bin/\*.pl)
 - 2004-11-16 splited cgi-handle to handle (bin/cgi-bin/\*.pl) and
    modules (Kernel/System/Web/Interface\*.pm)
 - 2004-11-16 renamed Kernel/System/WebUploadCache.pm to
    Kernel/System/Web/UploadCache.pm
 - 2004-11-16 renamed Kernel/System/WebRequest.pm to
    Kernel/System/Web/Request.pm
 - 2004-11-07 added LOWER() in sql like queries to search, now searches
    are case insensitive in postgresql and maxdb
 - 2004-11-04 added new feature so show ticket history reverse
    [Kernel/Config.pm]

```perl
    # Agent::HistoryOrder
    # (show history order reverse) [normal|reverse]
    $Self->{'Agent::HistoryOrder'} = 'normal';
#    $Self->{'Agent::HistoryOrder'} = 'reverse';
```
 - 2004-11-04 added "show no escalation" group feature
    [Kernel/Config.pm]

```perl
    # AgentNoEscalationGroup
    # (don't show escalated tickets in frontend for agents who are writable
    # in this group)
    $Self->{AgentNoEscalationGroup} = 'some_group';
```
 - 2004-11-04 renamed session to sessions table (oracle compat.)
 - 2004-11-04 updated to CGI 3.05
 - 2004-11-04 switched to session db module as default because
   of compat. of operating systems
 - 2004-11-04 added new dtl tag $LQData{} to quote html links
 - 2004-11-02 added ticket free text feature to agent compose
 - 2004-11-02 added ticket free text feature to agent close
 - 2004-11-01 added auto generated table-sql scripts for mysql, postgresql,
    sapdb and oracle based on scripts/database/otrs-schema.xml
 - 2004-10-31 added database foreign-keys
 - 2004-10-08 fixed 544 - Email address check with query timeout causes
     Premature end of script headers
 - 2004-10-06 reworked all agent and customer notifications in database
    (use scripts/DBUpdate-to-2.0.\*.sql)
 - 2004-10-06 added new config options for email address check
```perl
    # CheckEmailValidAddress
    # (regexp of valid email addresses)
    $Self->{CheckEmailValidAddress} = '^(root@localhost|admin@localhost)$';

    # CheckEmailInvalidAddress
    # (regexp of invalid email addresses)
    $Self->{CheckEmailInvalidAddress} = '@(anywhere|demo|example|foo)\.(..|...)$';
```
 - 2004-10-01 added global working time configuration for escalation
    and unlock calculation:
    [Kernel/Config.pm]
```perl
    # TimeWorkingHours
    # (counted hours for working time used)
    $Self->{TimeWorkingHours} = {
        Mon => [ 8,9,10,11,12,13,14,15,16,17,18,19,20 ],
        Tue => [ 8,9,10,11,12,13,14,15,16,17,18,19,20 ],
        Wed => [ 8,9,10,11,12,13,14,15,16,17,18,19,20 ],
        Thu => [ 8,9,10,11,12,13,14,15,16,17,18,19,20 ],
        Fri => [ 8,9,10,11,12,13,14,15,16,17,18,19,20 ],
        Sat => [  ],
        Sun => [  ],
    };
    # TimeVacationDays
    # adde new days with:
    # "$Self->{TimeVacationDays}->{10}->{27} = 'Some Info';"
    $Self->{TimeVacationDays} = {
        1 => {
            01 => 'New Year's Eve!',
        },
        5 => {
            1 => '1 St. May',
        },
        12 => {
            24 => 'Christmas',
            25 => 'First Christmas Day',
            26 => 'Second Christmas Day',
            31 => 'Silvester',
        },
    };
    # TimeVacationDaysOneTime
    # adde new own days with:
    # "$Self->{TimeVacationDaysOneTime}->{1977}-{10}->{27} = 'Some Info';"
    $Self->{TimeVacationDaysOneTime} = {
        2004 => {
          6 => {
              07 => 'Some Day',
          },
          12 => {
              24 => 'Some A Day',
              31 => 'Some B Day',
          },
        },
    };
```
 - 2004-10-01 improved ticket escalation, added new ticket table col.
    use scripts/DBUpdate-to-2.0.\*.sql
 - 2004-09-29 fixed bug#[310](http://bugs.otrs.org/show_bug.cgi?id=310) - System-ID "09" is not working
 - 2004-09-27 replaced dtl env LastScreenQueue with LastScreenOverview
    and LastScreen with LastScreenView.
 - 2004-09-16 added frontend module registry, so no frontend module
    will be longer accessable till the module is registry. For example
    a registered frontend module with navigation icon in Agent nav bar
    (navigation bar will be build automatically, based on permissions):
    [Kernel/Config.pm]
```perl
    $Self->{'Frontend::Module'}->{'AgentPhone'} = {
        Group => ['users', 'admin'],
        Description => 'Create new Phone Ticket',
        NavBar => [{
            Description => 'Create new Phone Ticket',
            Name => 'Phone-Ticket',
            Image => 'new.png',
            Link => 'Action=AgentPhone',
            NavBar => 'Agent',
            Prio => 20,
         },
       ],
    };
```
 - 2004-09-16 added Kernel::System::PID to start bin/PostMaster.pl just
    once (new table, process\_id is needed)
 - 2004-09-15 added date check on set pending time, don't set pending
    time to past!
 - 2004-09-11 added support of object link
 - 2004-09-10 changed the agent notification to all subscriped agents
    if there is an follow up from the customer and the ticket is unlocked.
    This is different to OTRS \<= 1.3. So if you don't want this, you can
    use the following config option to disable this (link in OTRS 1.3)
    [Kernel/Config.pm]

```perl
     $Self->{PostmasterFollowUpOnUnlockAgentNotifyOnlyToOwner} = 1;
```
 - 2004-09-10 added Kernel::System::SearchProfile to manage object
    search profiles
 - 2004-09-09 added role/profile feature
 - 2004-09-09 added ticket title support

# 1.3.3 2005-10-20
 - 2005-10-20 moved to default download type as attachment (not inline)
    for a better security default setting
 - 2005-10-17 added security bugfix for missing SQL quote
 - 2005-07-08 fixed win32 binmode problem in Kernel/System/WebUploadCache.pm
 - 2005-07-01 fixed missing date in TicketForward.dtl
 - 2005-07-01 fixed bug#[808](http://bugs.otrs.org/show_bug.cgi?id=808) - Stats: StopMonth in Ticket.pm
 - 2005-07-01 fixed bug#[810](http://bugs.otrs.org/show_bug.cgi?id=810) - single quote in comment field generates errors
 - 2005-02-15 updated to cpan MIME::Tools 5.417
 - 2005-02-10 fixed generic agent - was not able to set new owner
 - 2005-01-19 fixed bug#[666](http://bugs.otrs.org/show_bug.cgi?id=666) - INSERTs into 'ticket\_history' fail sometimes
 - 2005-01-07 fixed bug#[659](http://bugs.otrs.org/show_bug.cgi?id=659) - Escalation Notification Sent to Wrong Users
 - 2004-11-26 fixed remove of ticket link if just one exists
 - 2004-11-24 fixed new owner list in Kernel/Modules/AgentMove.pm
    (show just user with rw permission to selected queue)
 - 2004-11-07 fixed utf8-problem with postgres and non utf-8 emails in
    article\_plain
 - 2004-11-05 updated Kernel/Language/hu.pm Thanks to Czakï¿½ Krisztiï¿½n!
 - 2004-11-04 fixed loop if now theme directory is found
 - 2004-11-04 fixed upper queue rename with () or + chars
 - 2004-11-04 fixed bug#[604](http://bugs.otrs.org/show_bug.cgi?id=604) - Typo in AgentStatusView.pm
 - 2004-10-29 spell check rewritten
 - 2004-10-26 added unlock option to bulk feature
 - 2004-10-18 fixed bug#[551](http://bugs.otrs.org/show_bug.cgi?id=551) - FAQ on Email new only takes over the
    subject and not the text

# 1.3.2 2004-10-15
 - 2004-10-14 fixed bug#[570](http://bugs.otrs.org/show_bug.cgi?id=570) - Stat generation script fails under postgres
 - 2004-10-14 fixed bug#[573](http://bugs.otrs.org/show_bug.cgi?id=573) - Clicked link to check ticket status and here's
    what I got
 - 2004-10-12 replaced COUNTER with DATA in Kernel/System/Ticket/Number/\*.pm
    (because of win32 systems and use strict mode)
 - 2004-10-12 fixed agent can be customer modus
 - 2004-10-10 fixed wrong lable attachments in db backend
 - 2004-10-07 fixed bug#[562](http://bugs.otrs.org/show_bug.cgi?id=562) Content-Transfer-Encoding: 7bit and german umlaut
 - 2004-10-07 fixed bug#[565](http://bugs.otrs.org/show_bug.cgi?id=565) HighlightColor\* in AgentMailbox
 - 2004-10-06 fixed link quote of https links
 - 2004-10-06 added application log error message if bin/PostMaster.pl fails
 - 2004-10-01 fixed bug#[547](http://bugs.otrs.org/show_bug.cgi?id=547) - uninitialized value in string eq at
    Kernel/System/Ticket/Article.pm line 1387
 - 2004-09-29 fixed english "New ticket notification!", replaced
    OTRS\_CURRENT\_USERFIRSTNAME with OTRS\_USERFIRSTNAME
 - 2004-09-29 removed not existing jp language translation
 - 2004-09-29 fixed bug#[554](http://bugs.otrs.org/show_bug.cgi?id=554) - "Thursday" twice in AdminGenericAgent.pm
 - 2004-09-27 fixed bug#[548](http://bugs.otrs.org/show_bug.cgi?id=548) - german spelling mistakes in agent
    notifications
 - 2004-09-23 fixed ticket free text selection in Kernel/Modules/CustomerMessag.pm
 - 2004-09-23 fixed not sended agent notification after created Email-Ticket
 - 2004-09-23 fixed ticket zoom in customer panel if no customer article
   exists

# 1.3.1 2004-09-20
 - 2004-09-16 fixed bug#[513](http://bugs.otrs.org/show_bug.cgi?id=513) - distinct customers must have distinct email
 - 2004-09-16 fixed bug#[519](http://bugs.otrs.org/show_bug.cgi?id=519) - PostMaster.pl bounces mail if database
    is down
 - 2004-09-16 fixed bug#[521](http://bugs.otrs.org/show_bug.cgi?id=521) - buggy utf8 content transfer encoding
 - 2004-09-11 fixed bug if somebody clicks on customer management
 - 2004-09-09 added address book and spell checker to agent forward
 - 2004-09-08 updated spanish translation - Thanks to Jorge Becerra!
 - 2004-09-08 fixed bug#[500](http://bugs.otrs.org/show_bug.cgi?id=500) - js error

# 1.3.0 beta4 2004-09-08
 - 2004-09-08 fixed bug#[514](http://bugs.otrs.org/show_bug.cgi?id=514) - Use of uninitialized value in addition (+) at
    bin/DeleteSessionIDs.pl line 93.
 - 2004-09-08 fixed bug#[517](http://bugs.otrs.org/show_bug.cgi?id=517) - fixed bug 517 - DBUpdate-to-1.3 scripts
    don't correctly rename system\_queue\_id
 - 2004-09-08 fixed bug#[516](http://bugs.otrs.org/show_bug.cgi?id=516) - initial\_insert.sql violates ticket\_history
    "NOT NULL" contraints
 - 2004-09-05 fixed bug#[380](http://bugs.otrs.org/show_bug.cgi?id=380) - Does not allow change of customer login
 - 2004-09-04 fixed bug#[502](http://bugs.otrs.org/show_bug.cgi?id=502) - Email bouncing does not work
 - 2004-09-04 fixed bug#[503](http://bugs.otrs.org/show_bug.cgi?id=503) - Move Ticket into queue not possible
 - 2004-09-04 fixed bug#[504](http://bugs.otrs.org/show_bug.cgi?id=504) - $Text{"0"} in DTLs does not produce any output
 - 2004-09-04 added delete option for pop3 accounts in admin interface
 - 2004-09-04 improved generic agent web interface
 - 2004-08-30 fixed '' selection on ticket free text search
 - 2004-08-30 support of sub dtl blocks
 - 2004-08-28 fixed call customer via phone (set state was ignored)
 - 2004-08-26 fixed multi customer id support and added docu

# 1.3.0 beta3 2004-08-25
 - 2004-08-25 fixed german translation (replaced wrong words)
 - 2004-08-24 fixed time schedule for generic agent

# 1.3.0 beta2 2004-08-24
 - 2004-08-24 fixed ticket\_history table update script

# 1.3.0 beta1 2004-08-18
 - 2004-08-11 added feature to send fulltext reqests to a
    mirror database
    [Kernel/Config.pm]

```perl
    # AgentUtil::DB::*
    # (if you want to use a mirror database for agent ticket fulltext search)
    $Self->{'AgentUtil::DB::DSN'} = "DBI:mysql:database=mirrordb;host=mirrordbhost";
    $Self->{'AgentUtil::DB::User'} = "some_user";
    $Self->{'AgentUtil::DB::Password'} = "some_password";
```
 - 2004-08-10 added Radius auth modules for agent and customer
    interface
 - 2004-08-10 improved Kernel::System::CustomerAuth::DB to use
    an external database
 - 2004-08-10 added email 1:1 download option in AgentPlain
 - 2004-08-08 added owner\_id, priority\_id and state\_id to
    ticket\_history table.
 - 2004-08-04 moved customer notifications from Kernel/Config.pm to
    database and added multi language support
 - 2004-08-02 fixed bug#[466](http://bugs.otrs.org/show_bug.cgi?id=466) - Error in managing very long Message-IDs
 - 2004-08-01 improved Kernel::System::Log::SysLog with log charset
    config option in case syslog can't work with utf-8
 - 2004-08-01 improved Kernel::System::Email backends
 - 2004-08-01 fixed bug#[429](http://bugs.otrs.org/show_bug.cgi?id=429) - Attachment file names with spaces do
    not save properly
 - 2004-08-01 fixed bug#[450](http://bugs.otrs.org/show_bug.cgi?id=450) - Spelling mistake in default FAQ entry
 - 2004-08-01 fixed bug#[460](http://bugs.otrs.org/show_bug.cgi?id=460) - Patch to add params hash to LDAP bind
    in Kernel/System/User.pm.
 - 2004-07-30 added references, in-reply-to follow up check
    [Kernel/Config.pm]

```perl
    # PostmasterFollowUpSearchInReferences
    # (If no ticket number in subject, otrs also looks in In-Reply-To
    # and References for follow up checks)
    $Self->{PostmasterFollowUpSearchInReferences} = 0;
```
 - 2004-07-17 fixed generic agent Schedule web interface
 - 2004-07-16 added multi attachment support for attachments
 - 2004-06-28 improved Kernel/Modules/AdminSelectBox.pm module
 - 2004-06-27 added Block() feature to dtl files (removed a lot
    of no longer needed templates)
 - 2004-06-27 improved web handle (bin/cgi-bin/index.pl and
    bin/cgi-bin/customer.pl) to show module syntax errors.
 - 2004-06-22 improved postmaster filter to use matched value as [\*\*\*]
    in "Set =\>" option.
 - 2004-06-22 added support for crypted database passwords (use
    bin/CryptPassword.pl to crypt passwords).
 - 2004-06-10 added generic agent web interface
 - 2004-06-03 improved language translation with custom translation
    files:
    Kernel/Language/$Locale.pm (default)
    Kernel/Language/$Locale\_$Action.pm (translation for otrs modules like
     file manager, calendar, ...)
    Kernel/Language/$Locale\_Custom.pm (own changes,updates)
 - 2004-05-18 added html application output filter option, e. g. to
    filter java script of the application or to manipulate the html
    output of the application.
    (see also Kernel/Config/Defaults.pm -\> Frontend::Output::PostFilter)
 - 2004-05-04 added ticket history log on ticket link update and
    notification info if link ticket number doesn't exists.
 - 2004-05-03 added PreApplicationModule examples to Kernel/Config.pm
 - 2004-04-30 added multi customer id support to Kernel/System/CustomerUser.pm,
    Kernel/System/CustomerUser/DB.pm and Kernel/System/CustomerUser/LDAP.pm.
    So one customer can have more than one customer id.
 - 2004-04-22 added notification module for customer panel
    (customer.pl) like for existing agent (index.pl)
 - 2004-04-20 added PreApplicationModule (index.pl) and
    CustomerPanelPreApplicationModule (customer.pl) This interface
    use useful to check some user options or to redirect not accept
    new application news.
 - 2004-04-19 added MaxSessionIdleTime for session managment
    to check/delete idle sessions
 - 2004-04-15 added file size info to article attachments
    (DBUpdate-to-1.3.\*.sql is required!).
 - 2004-04-14 ticket history rewritten and added i18n feature
 - 2004-04-14 reworked/renamed Kernel::System::Ticket::Article
    and sub module functions and added added pod docu, see
    http://dev.otrs.org/
    Note: Kernel::System::Ticket are not longer compat. to OTRS 1.2
     or lower!
 - 2004-04-07 added config option SessionUseCookieAfterBrowserClose
    for session config stuff to keep cookies in browser (after closing
    the browser) till expiration of session (default is 0).
 - 2004-04-06 added missing priority options in TicketSeatch()
    of Kernel::System::Ticket.
 - 2004-04-05 reworked/renamed Kernel::System::Ticket functions and
    added added pod docu, see http://dev.otrs.org/
 - 2004-04-04 added auto convert of html only emails to text/plain,
    text/html will be attached as attachment (Kernel/System/EmailParser.pm)
 - 2004-04-01 fixed some html quote bugs
 - 2004-03-30 added ability to reverse the Queue sorting (added
    AgentQueueSort setting)
 - 2004-03-12 added customer panel MyTickets and CompanyTickets
    feature.
 - 2004-03-11 added mulit serach options to customer serach e. g.
    "name+phone" in customer search
 - 2004-03-11 added customer search prefix (default '') and suffix
    (default '\*') to CustomerUser as config options.
 - 2004-03-11 added \<OTRS\_CUSTOMER\_\*\> tags for salutatuion, signateure
    and std. responses
 - 2004-03-08 added TimeZone feature - e. g. config option
    "$Self-\>{TimeZone} = +5;" in Kernel/Config.pm
 - 2004-03-05 added Include function to dtl tags - Thanks to Bozhin Zafirov!
    - moved to central css dtl file (Kernel/Output/HTML/\*/css.dtl and
      Kernel/Output/HTML/\*/customer-css.dtl)
 - 2004-02-29 improved database handling of large objects (use DBI
    bind values now / saves memory)
 - 2004-02-27 replaced "CustomQueue" with "My Queues" in agent frontend
 - 2004-02-27 fixed possible owner selection in AgentPhone/AgentEmail
 - 2004-02-23 improved FreeText feature look if just one key is
    defined.
 - 2004-02-23 improved otrs LDAP modules with AlwaysFilter and
    Charset options (see online documentation)
 - 2004-02-23 updated to CGI 3.04

# 1.2.4 2004-07-07
 - 2004-06-29 fixed bug#[456](http://bugs.otrs.org/show_bug.cgi?id=456) not existing queue\_auto\_response
    references in scripts/database/initial\_insert.sql
 - 2004-06-11 added Hungarian translation. Thanks to Gï¿½ncs Gï¿½bor!
 - 2004-04-10 fixed not shown "this message is written in an
    other charset as your own" link in agent zoom
 - 2004-04-08 fixed performance problem in Kernel::Language
    module (get ~5% more performance of the webinterface)
 - 2004-04-06 added missing priority options in SearchTicket()
    of Kernel::System::Ticket.

# 1.2.3 2004-04-02
 - 2004-03-29 fixed some html quote bugs
 - 2004-03-28 fixed bug#[365](http://bugs.otrs.org/show_bug.cgi?id=365) - null attachment kills pop import script
 - 2005-03-25 updated pl language translation, Thanks to Tomasz Melissa!
 - 2004-03-25 fixed quote bug in AgentPhoneView, AgentEmail and
    AgentCompose.
 - 2004-03-08 fixed bug#[341](http://bugs.otrs.org/show_bug.cgi?id=341) Wrong results searching for time ranges
    http://bugs.otrs.org/show_bug.cgi?id=341
 - 2004-02-29 fixed language quoting in customer login screen
 - 2004-02-27 fixed missing "internal (agent)" agent search faq
 - 2004-02-27 fixed possible owner selection in AgentPhone/AgentEmaill

# 1.2.2 2004-02-23
 - 2004-02-17 changed screen after moved ticket (like OTRS 1.1)
 - 2004-02-17 added null option to search options
    http://bugs.otrs.org/show_bug.cgi?id=321
 - 2004-02-17 fixed double quote bug in GetIdOfArticle()/CreateArticle()
    http://bugs.otrs.org/show_bug.cgi?id=319
 - 2004-02-17 fixed bug#[317](http://bugs.otrs.org/show_bug.cgi?id=317) - Return Path set to invalid email
    http://bugs.otrs.org/show_bug.cgi?id=317

# 1.2.1 2004-02-14
 - 2004-02-14 fixed escalation bug#[290](http://bugs.otrs.org/show_bug.cgi?id=290) -
    http://bugs.otrs.org/show_bug.cgi?id=290
 - 2004-02-14 updated spanish translation. Thanks to Jorge Becerra!
 - 2004-02-14 updated czech translation. Thanks to Petr Ocasek
    (BENETA.cz, s.r.o.)!
 - 2004-02-14 added Norwegian language translation (bokmï¿½l)
    Thanks to Arne Georg Gleditsch!
 - 2004-02-12 fixed security bugs ins SQL quote()
 - 2004-02-12 fixed bin/PendingJobs.pl bug (Need User)
 - 2004-02-10 fixed CustomerUserAdd, added Source default map if
    no Source name is given
 - 2004-02-10 fixed missing translation in agent and customer
    preferences option selections.

# 1.2.0 beta3 2004-02-09
 - 2004-02-09 fixed bug#[249](http://bugs.otrs.org/show_bug.cgi?id=249) Editing system email addresses with
    quotations in name field - http://bugs.otrs.org/show_bug.cgi?id=249
 - 2004-02-09 added contact customer (create ticket) feature
 - 2004-02-08 added multi customer map/source support
 - 2004-02-08 added GenericAgent module support
 - 2004-02-05 fixed bug in X-OTRS-Queue option if bin/PostMasterPOP3.pl
    is used.
 - 2004-02-04 fixed bug in customer interface (empty To selection)
 - 2004-02-03 fixed typo in template (wrong $Data{} for Field6)
    Kernel/Output/HTML/Standard/FAQArticleForm.dtl

# 1.2.0 beta2 2004-02-02
 - 2004-02-02 replaced column "comment" to "comments" of each table to
    be oracle compat.
 - 2004-02-02 added ticket link feature
 - 2004-02-01 fixed uncounted unlocktime calcualtion in bin/UnlockTickets.pl
 - 2004-01-27 added Bcc field for agent address book and agent compose
 - 2004-01-24 fixed bug#[280](http://bugs.otrs.org/show_bug.cgi?id=280) - group\_customer\_user table
    (http://bugs.otrs.org/show_bug.cgi?id=280)
 - 2004-01-23 fixed bug#[219](http://bugs.otrs.org/show_bug.cgi?id=219) - GenericAgent and adding notes
    (http://bugs.otrs.org/show_bug.cgi?id=219)
 - 2004-01-23 fixed bug#[215](http://bugs.otrs.org/show_bug.cgi?id=215) - Bug in search URL - wrong link to next page
    (http://bugs.otrs.org/show_bug.cgi?id=215)
 - 2004-01-23 fixed bug#[213](http://bugs.otrs.org/show_bug.cgi?id=213) - Does not update replies with the correct name
    (http://bugs.otrs.org/show_bug.cgi?id=213)
 - 2004-01-23 fixed bug#[192](http://bugs.otrs.org/show_bug.cgi?id=192) - rename queue with Sub-queue
    (http://bugs.otrs.org/show_bug.cgi?id=192)
 - 2004-01-23 fixed customer-user \<-\> group problem added the following
    to Kernel/Config.pm

```perl
    # CustomerGroupSupport (0 = compat. to OTRS 1.1 or lower)
    # (if this is 1, the you need to set the group \<-\> customer user
    # relations! http://host/otrs/index.pl?Action=AdminCustomerUserGroup
    # otherway, each user is ro/rw in each group!)
    $Self->{CustomerGroupSupport} = 0;

    # CustomerGroupAlwaysGroups
    # (if CustomerGroupSupport is true and you don't want to manage
    # each customer user for this groups, then put the groups
    # for all customer user in there)
    $Self->{CustomerGroupAlwaysGroups} = ['users', 'info'];
```
 - 2004-01-23 changed Kernel::System::Ticket-\>SearchTicket() to
    return false if on param (e. g. Queue or State) doesn't exist
    (problem was, that if a queue name dosn't exist, then the
    GenericAgent gets tickets from all queues!).

# 1.2.0 beta1 2004-01-22
 - 2004-01-22 internationalization of agent notification messages
    configurable over admin interface (attention, agent notificatins
    are not be longer stored as article, now just a history entry will
    be created, old articles will be removed/delete by update script!)
 - 2004-01-19 improve ticket search with date/time options
 - 2004-01-14 added X-OTRS-SenderType and X-OTRS-ArticleType to
    possible email headers (see doc/X-OTRS-Headers.txt).
 - 2004-01-14 Updated Mail::Tools from 1.51 to 1.60.
 - 2004-01-12 added config option to send no pending notification in
    defined hours (SendNoPendingNotificationTime).
 - 2004-01-10 improved TicketStorageModule, now it's possible to
    switch from one to the other backend on the fly.
 - 2004-01-09 improved GenericAgent.pl to work also with more ticket
    properties see also for all options:
    http://doc.otrs.org/cvs/en/html/generic-agent-example.html
 - 2004-01-09 removed charset selection from perferences (agent and
    customer interface). Take the charset form translation file.
 - 2004-01-09 added utf-8 support for mail frontend (min. Perl 5.8.0
    required)
 - 2004-01-08 added address book feature on compose answer
    screen.
 - 2004-01-07 added OTRS\_CUSTOMER\_DATA\_\* tags for info of
    existing customer in CustomerMap in Kernel/Config.pm in
    Agent notification config options.
 - 2003-12-23 added lock/unlock option to phone view / create
    ticket.
 - 2003-12-15 changed recipients of customer notifications
    (change queue, update owner, update state, ...) to current
    customer user, based on customer user source.
 - 2003-12-15 added customer user cc by creating a new ticket
    with different sender email addresses.
 - 2003-12-11 added more ticket free text options for tickets
    now we have 8 (not only 2) - improved also GenericAgent and
    Web-Frontend!
 - 2003-12-07 added SUSE 9.0 support and added RPM spec file
    for SUSE 9.0.
 - 2003-12-07 moved Kernel/Output/HTML/Agent|Admin|Customer.pm
    stuff to Kernel/Modules/\*.pm modules.
 - 2003-12-07 removed config option CustomerViewableTickets and
    added customer preferences option (15|20|25|30).
 - 2003-12-07 removed config option ViewableTickets and added
    agent preferences option (5|10|15|20|25).
 - 2003-12-03 added QueueListType config option [tree|list] to
    show the QueueSelection in a tree (default) or just in a list

```
 Example:  Tree:        List:
              QueueA       QueueA
                Queue1     QueueA::Queue1
                Queue2     QueueA::Queue2
                Queue3     QueueA::Queue3
              QueueB       QueueB
                Queue1     QueueB::Queue1
                Queue2     QueueB::Queue2
```
 - 2003-12-02 added remove of session cookie after closing the
    browser in agent interface
 - 2003-11-27 added modules for agent notifications
    Kernel/Output/HTML/NotificationCharsetCheck.pm
    Kernel/Output/HTML/NotificationUIDCheck.pm
    are default modules to configure over Kernel/Config.pm

```perl
    $Self->{'Frontend::NotifyModule'}->{'1-CharsetCheck'} = {
        Module => 'Kernel::Output::HTML::NotificationCharsetCheck',
    };
    $Self->{'Frontend::NotifyModule'}->{'2-UID-Check'} = {
        Module => 'Kernel::Output::HTML::NotificationUIDCheck',
    };
```
So it's also possible to create your own agent notifications
    like motd or escalation infos.
 - 2003-11-26 added group \<-\> customer user support - so it's
    possible that you can define the customer queues for new tickets
 - 2003-11-26 added modules for ticket permission checks
    Kernel/System/Ticket/Permission/OwnerCheck.pm
    Kernel/System/Ticket/Permission/GroupCheck.pm
    Kernel/System/Ticket/CustomerPermission/CustomerIDCheck.pm
    Kernel/System/Ticket/CustomerPermission/GroupCheck.pm
    So it's possible to write own perission check modules!
    Example: Don't allow agents to change the priority if the state
    of the ticket is 'open' and in a specific queue.
    Example of Kernel/Config.pm:

```perl
    # Module Name: 1-OwnerCheck
    # (if the current owner is already the user, grant access)
    $Self->{'Ticket::Permission'}->{'1-OwnerCheck'} = {
        Module => 'Kernel::System::Ticket::Permission::OwnerCheck',
        Required => 0,
    };
    # Module Name: 2-GroupCheck
    # (if the user is in this group with type ro|rw|..., grant access)
    $Self->{'Ticket::Permission'}->{'2-GroupCheck'} = {
        Module => 'Kernel::System::Ticket::Permission::GroupCheck',
        Required => 0,
    };
```
 - 2003-11-19 improved group sub system, added create, move\_into, owner
    and priority permissions to groups (DBUpdate-to-1.2.\*.sql is required!).
 - 2003-11-05 added agent preferences option "Screen after new phone
    ticket". So you can select the next screen after creating a new
    phone ticket.
 - 2003-11-02 improved GenericAgent.pl to work also with ticket
    priorities (search and change).
    Example for Kernel/Config/GenericAgent.pm:

```perl
    # ---
    # [name of job] -\> move all tickets from abc to experts and change priority
    # ---
    'move all abc priority "3 normal" tickets to experts and change priority'=\> {
      # get all tickets with these properties
      Queue => 'abc',
      Priorities => ['3 normal'],
      # new ticket properties
      New => {
        Queue => 'experts',
        Priority => '4 high',
      },
    },
```
 - 2003-11-02 added delete option to Admin-\>StdAttachment menu
 - 2003-11-01 added PostMaster(POP3).pl filter options like procmail.
    Example for Kernel/Config.pm:

```perl
    # Job Name: 1-Match
    # (block/ignore all spam email with From: noreply@)
    $Self->{'PostMaster::PreFilterModule'}->{'1-Match'} = {
        Module => 'Kernel::System::PostMaster::Filter::Match',
        Match => {
            From => 'noreply@',
        },
        Set => {
            'X-OTRS-Ignore' => 'yes',
        },
    };
```
Available modules are Kernel::System::PostMaster::Filter::Match
    and Kernel::System::PostMaster::Filter::CMD. See more to use it
    on http://doc.otrs.org/.
 - 2003-10-29 added bin/CleanUp.pl to clean up of all tmp data
    like ipc, database or fs session and log stuff (added CleanUp()
    to Kernel::System::AuthSession::\* and Kernel::System::Log).
 - 2003-10-27 added "-c Kernel::Config::GenericAgentJobModule"
    option to GenericAgent.pl to use it with more than one
    (Kernel::Config::GenericAgent) job file. For example you will be
    able to have Kernel::Config::Delete and Kernel::Config::Move or
    other job files to execute it on different times.
 - 2003-10-14 changed phone default settings:
    * new tickets are unlocked (not locked)
    * subject and body is empty as default
 - 2003-09-28 improved next screen management after closing tickts
 - 2003-09-28 added \<OTRS\_TICKET\_STATE\> to agent compose answer screen
    as variable for new ticket state in composed message.
 - 2003-08-28 improved GenericAgent to use From, To, Cc, Subject and
    Body for ticket selection - example:

```perl
   'delete all tickets with subject "VIRUS 32" in queue abc' => {
      # get all tickets with this properties
      Queue => 'abc',
      Subject => '%VIRUS%',
      # new ticket properties
      New => {
        # DELETE!
        Delete => 1,
      },
   },
```
 - 2003-07-31 added "Show closed Ticket/Don't show closed Ticket" link
    to customer panel show my tickets overview
 - 2003-07-14 added last owner selection to Kernel/Modules/AgentOwner.pm
 - 2003-07-13 add "single sign on" (pre-authentication) option for
    http-basic-auth (Kernel::System::Auth::HTTPBasicAuth and
    Kernel::System::CustomerAuth::HTTPBasicAuth). Thanks to Phil Davis!
 - 2003-07-12 fixed bug#[155](http://bugs.otrs.org/show_bug.cgi?id=155) - in multiple page ticket view, start value
    might be too high
 - 2003-07-12 improved ticket search, added also search profile option
 - 2003-07-05 improved module permission options, now it's possible
    to add more the one group
 - 2003-06-26 improved ticket search and added new search preferences
    table (db update with scripts/DBUpdate-to-1.2.(mysql|postgres).sql)
    required!
 - 2003-05-29 added utf-8 support for webfrontends (min. Perl 5.8.0
    required)
 - 2003-05-20 added array for source queue selection to bin/GenericAgent.pl
    for example, use this job for more queues:

```perl
    'move tickets from tricky to experts' => {
      # get all tickets with this properties
      Queue => ['tricky', 'tricky1'],
      States => ['new', 'open'],
      Locks => ['unlock'],
```
 - 2003-05-13 removed UNIQUE (not needed!) in pop3\_account table

# 1.1.3 2003-07-12
 - 2003-07-12 fixed bug#[182](http://bugs.otrs.org/show_bug.cgi?id=182) - Error when modify an queue without a queue-name
 - 2003-07-12 removed "PerlInitHandler Apache::StatINC" (Reload %INC files
     perl modules) from scripts/apache-httpd.include.conf because of many error
      message in apache error log
    -=\> apache reload is still needed when perl modules changed on disk \<=-
 - 2003-07-12 improved performance of Kernel/System/Ticket/ArticleStorageDB.pm
    with large objects
 - 2003-07-10 fixed bug#[171](http://bugs.otrs.org/show_bug.cgi?id=171) - No lock check if two Agents try to lock
    ticket at same time (or later)
 - 2003-07-06 fixed bug#[168](http://bugs.otrs.org/show_bug.cgi?id=168) - The install script for POSTGRES contains wrong
    datatypes (DATETIME instead of TIMESTAMP)
 - 2003-07-06 fixed bug#[165](http://bugs.otrs.org/show_bug.cgi?id=165) - Pop3 change - does not show the queue
 - 2003-07-03 fixed bug#[178](http://bugs.otrs.org/show_bug.cgi?id=178) - Authenticated customer LDAP requests don't work
 - 2003-07-02 updated Finnish translation, thanks to Antti Kï¿½mï¿½rï¿½inen
 - 2003-07-01 added SMTP module port patch of Jeroen Boomgaardt
 - 2003-06-22 fixed bug#[144](http://bugs.otrs.org/show_bug.cgi?id=144) - PostMasterPOP3.pl is exiting
    "Attached .eml file causes bug in EmailParser.pm"
    http://bugs.otrs.org/show_bug.cgi?id=144
 - 2003-06-04 fixed legend colors of stats pics

# 1.1.2 2003-05-31
 - 2003-06-01 improved Kernel/System/Ticket/Number/\*.pm (ticket number
    generator modules) to work with non existing var/log/TicketCounter.log.
     -=\> So var/log/TicketCounter.log will be removed from the CVS and
     tar.gz updates will be much easier! (TicketCounter.log will not be
     reseted on tar-update of OTRS update)
 - 2003-06-01 added Resent-To email header check for queue sorting of
    new ticket - http://lists.otrs.org/pipermail/otrs/2003-May/001845.html
 - 2003-05-30 added "PerlInitHandler Apache::Reload" (Reload %INC files
     perl modules) to scripts/apache2-httpd.include.conf
    -=\> no apache reload is needed when perl modules is updated on disk \<=-
 - 2003-05-30 added "PerlInitHandler Apache::StatINC" (Reload %INC files
     perl modules) to scripts/apache-httpd.include.conf
    -=\> no apache reload is needed when perl modules is updated on disk \<=-
 - 2003-05-29 fixed create ticket (without priority selection) via
    customer panel and changed priority names.
 - 2003-05-26 fixed pic.pl bug - http://bugs.otrs.org/show_bug.cgi?id=149
 - 2003-05-19 improved text formatting of "long" messages in QueueView
    TicketZoom, TicketPlain and TicketSearch
 - 2003-05-18 fixed small logic bugs in Kernel/System/PostMaster\*
    improved debug options for bin/PostMaster.pl and bin/PostMasterPOP3.pl
     -=\> just used -d1 (1-3) for debug level of Kernel/System/PostMaster\*
 - 2003-05-18 added customer data lookup for PostMaster\*.pl based on
    senders email address (set customer id and customer user)
 - 2003-05-13 fixed unwanted ticket unlock on move
 - 2003-05-13 added russian translation! Thanks to Serg V Kravchenko!
 - 2003-05-13 added config options for shown customer info size

```perl
    $Self->{ShowCustomerInfo(Zoom|Queue|Phone)MaxSize}
```
 - 2003-05-08 fixed ignored user comment in admin area
 - 2003-05-04 added missing StateUpdate (table ticket\_history\_type)
    to scripts/DBUpdate-to-1.1.postgresql.sql
 - 2003-05-02 removed unique option for the pop3\_account column
    login! To be able to have more pop3 accounts with the same
    login name.
 - 2003-05-01 fixed bug#[134](http://bugs.otrs.org/show_bug.cgi?id=134) - Title shows "Select box" instead
    of "Admin Log" - http://bugs.otrs.org/show_bug.cgi?id=134
 - 2003-05-01 fixed Kernel/System/AuthSession/\*.pm to be able
    to store 0 values

# 1.1.1 2003-05-01
 - 2003-04-30 removed agent notify about new note because new
    owner got ticket assigned to you notify!
 - 2003-04-29 fixed bug#[131](http://bugs.otrs.org/show_bug.cgi?id=131) - QueueView shows wrong queue in
    drop-downs - http://bugs.otrs.org/show_bug.cgi?id=131
 - 2003-04-29 added min. counter size option (default 5) for
    Kernel::System::Ticket::Number::AutoIncrement module.
 - 2003-04-25 removed shown customer id in 'MyTickets' from
    customer interface - added customer id to user name line

# 1.1 rc2 2003-04-24
 - 2003-04-24 added refresh time to AgentMailbox screen (refresh
    time still exists for QueueView)
 - 2003-04-24 fixed "show closed tickets" in customer interface
    (http://lists.otrs.org/pipermail/otrs/2003-April/001508.html)
 - 2003-04-24 fixed max shown tickets in QueueView (default now 1200)
    (http://lists.otrs.org/pipermail/otrs/2003-April/001505.html)
 - 2003-04-23 fixed missing filename (default index.pl) for download
    of attachments using Kernel/System/Ticket/ArticleStorageFS.pm
    (http://lists.otrs.org/pipermail/otrs/2003-April/001491.html)
 - 2003-04-22 fixed bug#[123](http://bugs.otrs.org/show_bug.cgi?id=123) - Email address with simple quote
    http://bugs.otrs.org/show_bug.cgi?id=123
 - 2003-04-18 added RH8 IPC (shm id 0) workaround (create dummy shm)
 - 2003-04-17 fixed AgentStatusView (1st ticket is actually the 2nd)
 - 2003-04-17 added Firstname/Lastname of agents to ticket history

# 1.1 rc1 2003-04-15
 - 2003-04-15 added Italian translation - Thanks to Remo Catelotti
 - 2003-04-14 improved performance of MIME parser (PostMaster)
 - 2003-04-13 added config option DefaultNoteTypes (used note
    types) default is just note-internal because note-external and
    note-report is confusing.
 - 2003-04-11 added check if ticket state type is closed or
    removed then send not 'auto reply' to customer.
    http://lists.otrs.org/pipermail/otrs/2003-April/001401.html
 - 2003-04-11 added check for quotable messages in auto response
 - 2003-04-11 added check and html2ascii convert for html only
    emails on std. responses, forwards or splits
 - 2003-04-11 added Page Navigator for AgentQueueView -
    http://lists.otrs.org/pipermail/otrs/2003-February/000881.html
 - 2003-04-09 improved AdminEmail feature with group recipient
 - 2003-04-08 added ticket split option in article zoom.
 - 2003-04-08 fixed bug#[109](http://bugs.otrs.org/show_bug.cgi?id=109) - Attachments not being forwarded on
    http://bugs.otrs.org/show_bug.cgi?id=109
 - 2003-04-08 fixed bug#[111](http://bugs.otrs.org/show_bug.cgi?id=111) - Inability to forward on anything from:
    'agent email(external)' - http://bugs.otrs.org/show_bug.cgi?id=110
 - 2003-03-24 improved user-auth and customer-auth ldap interface
    with 'UserAttr' (UID for posixGroups objectclass and DN for non
    posixGroups objectclass) on group access check. Config options now:

```perl
    $Self->{'AuthModule::LDAP::GroupDN'} = 'cn=otrsallow,ou=posixGroups,dc=example,dc=com';
    $Self->{'AuthModule::LDAP::AccessAttr'} = 'memberUid';
    # for ldap posixGroups objectclass (just uid)
    $Self->{'AuthModule::LDAP::UserAttr'} = 'UID';
    # for non ldap posixGroups objectclass (with full user dn)
    $Self->{'AuthModule::LDAP::UserAttr'} = 'DN';
```
 - 2003-03-24 added agent feature to be also customer of one ticket
 - 2003-03-24 added UncountedUnlockTime config options - e.g. don't
    count Fri 16:00 - Mon 8:00 as unlock time.
 - 2003-03-23 added generic module/group permission concept for
    Kernel/Modules/\*.pm modules.
    -=\> add "$Self-\>{'Module::Permission'}-\>{'module'} = 'group';"
    to Kernel/Config.pm like
     "$Self-\>{'Module::Permission'}-\>{'AdminAutoResponse'} = 'users';"
    to let the users groups able to change the auto responses.
 - 2003-03-13 improved create customer account - send account login
    via email to requester (added config text for email)
 - 2003-03-13 added SendNoAutoResponseRegExp config option to send no
    auto responses if regexp is matching. (Default is
    '(MAILER-DAEMON|postmaster|abuse)@.+?\..+?')
 - 2003-02-11 improved ticket search (merged fulltext and ticket number
    rearch)
 - 2003-03-10 added customer email notification on move, state update
    or owner update (config option for each queue). Use
    "scripts/DBUpdate-to-1.1.(mysql|postgresql).sql".
    http://lists.otrs.org/pipermail/dev/2002-June/000005.html
 - 2003-03-06 added ro/rw to group object. So the agent is able to search,
    zoom, ... in tickets but can't edit the tickets - added also new config
    option 'QueueViewAllPossibleTickets' to show the ro queues in the queue
    (default 0 -=\> not shown).
    Use "scripts/DBUpdate-to-1.1.(mysql|postgresql).sql".
 - 2003-03-05 added sendmail backends (Kernel::System::Email::Sendmail
    and Kernel::System::Email::SMTP) - for win32 user. New config options:

```perl
      $Self->{'SendmailModule'} = 'Kernel::System::Email::Sendmail';
      $Self->{'SendmailModule::CMD'} = '/usr/sbin/sendmail -t -i -f ';

      $Self->{'SendmailModule'} = 'Kernel::System::Email::SMTP';
      $Self->{'SendmailModule::Host'} = 'mail.example.com';
      $Self->{'SendmailModule::AuthUser'} = '';
      $Self->{'SendmailModule::AuthPassword'} = '';
```
 - 2003-03-05 added "view all articles" config option for ticket zoom
    view (TicketZoomExpand default is 0) - new dtl templates for ticket
    zoom Kernel/Output/HTML/\*/AgentZoom\*.dtl (removed TicketZoom\*.dtl)
    http://lists.otrs.org/pipermail/otrs/2003-January/000784.html
 - 2003-03-03 new ticket state implementation (added ticket\_state\_type
    table). Use "scripts/DBUpdate-to-1.1.(mysql|postgresql).sql".
    State name is now free settable (because of the ticket state name).
    Added ticket state documentation.
 - 2003-02-25 rewrote scripts/backup.sh, update your cronjobs!
    http://lists.otrs.org/pipermail/dev/2003-February/000112.html
 - 2003-02-23 added sub-queue support
    http://lists.otrs.org/pipermail/otrs/2002-June/000065.html
 - 2003-02-17 added allowing the client to close a ticket via customer
    panel - http://lists.otrs.org/pipermail/otrs/2003-February/000891.html
 - 2003-02-15 fixed hanging login problem with mod\_perl2
 - 2003-02-15 added mod\_perl2 support for web installer
 - 2003-02-15 unfortunately there is a mod\_perl2 bug on RH8 - added
    check if crypt() is working correctly
 - 2003-02-14 fixed default Spelling Dictionary selection and added
    a preferences option
 - 2003-02-13 added PendingDiffTime config option (add this time to
    shown (selected) pending time) -
    http://lists.otrs.org/pipermail/otrs/2003-February/000899.html
 - 2003-02-09 updated priotity options with number prefix for sort of
    html select fields - e. g. "normal" is "3 normal" and "high" is
    "4 high" - use "scripts/DBUpdate-to-1.1.(mysql|postgresql).sql"
 - 2003-02-09 added ShowCustomerInfo(Queue|Zoom|Phone) config options
    for shown CustomerInfo (e. g. company-name, phone, ...) on
    AgentQueueView, AgentZoom and AgentPhone.
 - 2003-02-08 improved fulltext search with queue and priority option
 - 2003-02-08 added html color highlighting for ticket article type
    e. g. to highlight internal and external notes in TicketZoom -=\>
    article tree.
 - 2003-02-08 added html color highlighting for ticket priority
 - 2003-02-08 moved to 100% CSS support for Standard and Lite theme
 - 2003-02-08 improved VERSION regex for 1.x.x.x cvs revision
 - 2003-02-08 changed database script location from install/database
    to scripts/database

# 1.0.2 2003-03-09
 - 2003-03-09 fixed http redirect problem with mod_perl2
 - 2003-03-09 fixed pic.pl and show html email problem with IE -
    http://lists.otrs.org/pipermail/otrs/2003-March/001104.html
 - 2003-03-08 fixed spell check problem -
    http://lists.otrs.org/pipermail/otrs/2003-March/001077.html
 - 2003-02-26 added missing ResponseFormat config option to
    Kernel/Config/Defaults.pm
 - 2003-02-14 fixed default Spelling Dictionary selection and added
    a preferences option
 - 2003-02-13 added PendingDiffTime config option (add this time to
    shown (selected) pending time) -
    http://lists.otrs.org/pipermail/otrs/2003-February/000899.html

# 1.0.1 2003-02-10
 - 2003-02-10 Released 1.0 rc3 as OTRS 1.0.1

# 1.0 rc3 2003-02-03
 - 2003-02-03 added customer user info on TicketView, TicketZoom and PhoneView
     dtl template (if wanted, uncomment it).
 - 2003-02-03 fixed java script stuff for Spell Check
 - 2003-02-03 added customer user serach to PhoneView
 - 2003-02-02 added pending ticket notification - Thanks to Andreas Haase!
     http://lists.otrs.org/pipermail/otrs/2003-January/000839.html
 - 2003-01-27 fixed some doc typos - Thanks to Eddie Urenda!
 - 2003-01-27 added die string -=\> better to find webserver user file
    write permission problems (var/log/TicketCounter.log)!
    Kernel/System/Ticket/Number/\*.pm
 - 2003-01-23 added Brazilian Portuguese translation! Thanks to Gilberto
    Cezar de Almeida!

# 1.0 rc2 2003-01-19
 - 2003-01-19 added CustomerUser LDAP backend - Thanks to Wiktor Wodecki!
 - 2003-01-19 fixed CustomerUser backend (config options)
 - 2003-01-18 fixed bug#[61](http://bugs.otrs.org/show_bug.cgi?id=61) (ArticleStorageInit error ) -
    http://bugs.otrs.org/show_bug.cgi?id=61
 - 2003-01-17 fixed bug#[68](http://bugs.otrs.org/show_bug.cgi?id=68) on FreeBSD 4.7 (trying to "compose email" from
    the agent interface) - http://bugs.otrs.org/show_bug.cgi?id=68
 - 2003-01-16 fixed bug#[62](http://bugs.otrs.org/show_bug.cgi?id=62) (not working command line utilitity) -
    http://bugs.otrs.org/show_bug.cgi?id=62
 - 2003-01-16 added bin/otrs.checkModules to check installed and
    required cpan modules
 - 2003-01-15 updated finnish translation! Thanks to Antti Kï¿½mï¿½rï¿½inen!
 - 2003-01-15 added CheckMXRecord option to webinstaller
 - 2003-01-14 fixed typos "preferneces != preferences typo"
    http://lists.otrs.org/pipermail/dev/2003-January/000074.html
    Thanks to Wiktor Wodecki!
 - 2003-01-14 fixed bug#[59](http://bugs.otrs.org/show_bug.cgi?id=59) (Bug in SELECT statement on empty search form) -
    http://bugs.otrs.org/show_bug.cgi?id=59
 - 2003-01-14 updated french translation! Thanks to Nicolas Goralski!
 - 2003-01-12 added spanisch translation! Thanks to Jorge Becerra!
 - 2003-01-11 fixed AgentPhone bug of Time() in subject -
    Time(DateFormatLong) was shown

# 1.0 rc1 2003-01-09
 - 2003-01-09 added AgentTicketPrint (Ticket Print View)
 - 2003-01-09 improved Kernel::System::Ticket::IndexAccelerator::RuntimeDB
    and StaticDB (for locked tickets).
 - 2003-01-09 removed Kernel::System::Ticket::IndexAccelerator::FS
    because RuntimeDB and StaticDB is enough
 - 2003-01-05 improved fulltext search (added ticket state search option)
 - 2003-01-05 added CMD option to bin/GenericAgent.pl (so you can
    execute own programs on GenericAgent.pl actions - e. g. send
    special admin emails)
 - 2003-01-02 added attachments support for std. responses
 - 2002-12-27 added filters (All, Open, New, Pending, Reminder) to
    AgentMailbox (locked-ticket-view)
 - 2002-12-24 added pending feature for tickets
 - 2002-12-20 added Kernel::System::Ticket::ArticleStorage\* modules
    for attachments in database or fs (needs to update the database
    (scripts/DBUpdate.(mysql|postgesql).sql)! The main reason is a lot
    of people have problems with the file permissions of the local otrs
    and webserver user (often incoming emails are shown some times again).
    TicketStorageModule in Kernel/Config.pm.
     * Kernel::System::Ticket::ArticleStorageDB -\> (default)
     * Kernel::System::Ticket::ArticleStorageFS -\> (faster but webserver
        user should be the otrs user - use it for larger setups!)
 - 2002-12-19 attachment support (send and view) for customer panel!
 - 2002-12-18 added config option CheckEmailAddresses and CheckMXRecord.
    CheckMXRecord is useful for pre checks of valid/invalid senders (
    reduce Postmaster emails). Disable CheckEmailAddresses if you work
    with customers which don't have email addresses or your otrs system is
    in your lan!
 - 2002-12-18 added more error handling to AgentPhone
 - 2002-12-15 added bin/PostMasterPOP3.pl and AdminPOP3 interface for
    fetching emails without procmail, fetchmail and MDA
 - 2002-12-12 added finnish translation - Thanks to Antti Kï¿½mï¿½rï¿½inen!
 - 2002-12-08 added working PostMasterDaemon.pl and PostMasterClient.pl,
    alternative to PostMaster.pl. How it works: If the PostMasterDaemon.pl
    is running, pipe email through PostMasterClient.pl like (PostMaster.pl)
    (e. g. "cat /tmp/some.box | bin/PostMasterClient.pl"). Pro: Speed, Contra
    needs more memory.
 - 2002-12-07 added customer-user-backend Kernel/System/CustomerUser/DB.pm.
 - 2002-12-07 added preferences-backend module for user and customer user
    (Kernel/System/ (User/Preferences/DB.pm and CustomerUser/Preferences/DB.pm)
 - 2002-12-04 moved from Date::Calc (Perl and C) to Date::Pcalc (Perl only)
    and added Date::Pcalc to Kernel/cpan-lib/ (OS independent!).
 - 2002-12-01 moved GenericAgent.pm to GenericAgent.pm.dist to have tarball
    updates easier.
 - 2002-12-01 moved finally to new config file Kernel/Config.pm.dist! Learn
    more -=\> INSTALL -=\> "Demo config files"!
 - 2002-12-01 added "enchant LDAP auth" patch from Wiktor Wodecki for
    Kernel/System/Auth/LDAP.pm and Kernel/System/CustomerAuth/LDAP.pm -
    http://lists.otrs.org/pipermail/dev/2002-November/000043.html.
    Thanks Wiktor!
 - 2002-11-28 fixed bug#[39](http://bugs.otrs.org/show_bug.cgi?id=39) - added mime encode for attachment file names
    http://bugs.otrs.org/show_bug.cgi?id=39 - Thanks to Christoph Kaulich!
 - 2002-11-27 added backend modules for loop protection of PostMaster.pl
    "LoopProtectionModule" in Kernel/Config.pm (default is DB) -
    Kernel::System::PostMaster::LoopProtection::(DB|FS).
 - 2002-11-24 added delete ticket feature for GenericAgent.pl (removes tickets
    from db and fs) - http://lists.otrs.org/pipermail/dev/2002-October/000037.html.
 - 2002-11-23 removed Kernel::Modules::AdminLanguage! Moved used languages
    to config file (Kernel/Config.pm - DefaultUsedLanguages). Moved translation
    files from long language names to short names like en, de, bg, nl, ...
    (e. g. Kernel/Language/bg.pm). Updated docu.
 - 2002-11-21 moved var/cron/\* to var/cron/\*.dist (.dist is not used) to make
    updates easier! Thanks to Bryan Fullerton!
 - 2002-11-15 moved %doc/install/\* to /opt/OpenTRS/install in RPM-specs.
    because the web-installer needs this stuff in this location. %doc isn't
    consistent on different linux distributions!
 - 2002-11-15 fixed bug#[48](http://bugs.otrs.org/show_bug.cgi?id=48) custom modules don't work/load -
    http://bugs.otrs.org/show_bug.cgi?id=48
 - 2002-11-15 added Dutch translation! Thanks to Fred van Dijk!
 - 2002-11-14 added Bulgarian translation! Thanks to Vladimir Gerdjikov!
 - 2002-11-11 added new config file as Kernel/Config.pm.dist (will be used
    for \>= OTRS 5.0 Beta9) if you want to test it with 0.5, use Kernel/Config.pm.dist
    as Kernel/Config.pm (cp Kernel/Config.pm.dist Kernel/Config.pm)!
    Kernel/Config/Defaults.pm is the config file with all defaults. If you want
    to change this settings, add the needed entry to Kernel/Config.pm(.dist)
    and the Kernel/Config/Defaults.pm will be overwrite. Updates will be much
    easier! - http://lists.otrs.org/pipermail/otrs/2002-October/000315.html
 - 2002-11-11 added spell ckecker for agent interface (Kernel::Modules::AgentSpelling).
 - 2002-11-11 added browser window.status info for Standard Theme (Agent
    and Customer frontend).
 - 2002-11-11 added some CPAN modules to Kernel/cpan-lib/ (CGI 2.89,
    MIME-tools-5.411 and MailTools-1.51).
 - 2002-11-09 fixed attachment filename for IE (not the whole path like
    c:\Documents\test.jpg) Kernel/Modules/AgentCompose.pm.
 - 2002-11-09 fixed bug in Kernel/System/EmailParser.pm if email headers
    are longer then 64 characters. Thanks to Phil Davis!
 - 2002-11-01 added file permission check for PostMaster.pl on startup!
    -=\> Will help to get setup faster working!
 - 2002-10-31 added email valid check (incl. mx) on CreateAccount (customer
    panel) -=\> Config option: $Self-\>{CheckMXRecord}!

# 0.5 beta8 2002-10-25
 - 2002-10-24 improved web installer - added system settings
 - 2002-10-22 added notify mail to agent by ticket move - configurable via preferences
 - 2002-10-22 added Lite QueueView - configurable via preferences
 - 2002-10-20 added customer web frontend (bin/cgi-bin/customer.pl,
     Kernel/Modules/Customer\*.pm and Kernel/Output/HTML/\*/Customer.dtl)
 - 2002-10-20 added lost password feature
 - added config support for AgentPreferences module (Kernel/Config/Preferences.pm)
 - added AgentStatusView module (overview of all open tickets) - (Thanks to Phil Davis)!
 - added support of generic session id name (e. g. SessionID, OTRS, ...)
 - added more flexibility for option string in Kernel::Modules::AgentPhone
    [Kernel::Config::Phone]

```perl
      # PhoneViewASP -> useful for ASP
      # (Possible to create in all queue? Not only queue which
      # the own groups) [0|1]
      $Self->{PhoneViewASP} = 1;
      # PhoneViewSelectionType
      # (To: section type. Queue => show all queues, SystemAddress => show all system
      # addresses;) [Queue|SystemAddress]
       $Self->{PhoneViewSelectionType} = 'SystemAddress';
      # PhoneViewSelectionString
      # (String for To: selection.)
      $Self->{PhoneViewSelectionString} = '<Realname> <<Email>> - Queue: <Queue> - <QueueComment>';
      # PhoneViewOwnSelection
      # (If this is in use, "just this selection is valid" for the PhoneView.)
      $Self->{PhoneViewOwnSelection} = {
        # QueueID => String
        '1' => 'First Queue!',
        '2' => 'Second Queue!',
      };
```
 - added attachment support for agent compose answer
 - added Kernel::Modules::AdminEmail feature - a admin can send (via admin
    interface) info to one or more agents.
 - added /etc/sysconfig/otrs file for rcscripts
 - added rpm for Red Hat Linux 7.3
 - added email notify on ownership change feature - see
    http://lists.otrs.org/pipermail/otrs/2002-September/000213.html
 - added ReplyTo patch for PostMaster.pl of Phil Davis - Thanks Phil!
    - http://lists.otrs.org/pipermail/otrs/2002-September/000203.html
 - created config file (Kernel/Config/GenericAgent.pm) for bin/GenericAgent.pl
 - splited Kernel/Config.pm info Kernel/Config.pm, Kernel/Config/Postmaster.pm
    Kernel/Config/Phone.pm and Kernel/Config/Notification.pm and renamed some
    config variables to get a better overview.
 - added new/current french translation - Thanks to Bernard Choppy!
 - added module support for log (Kernel/Config.pm --\> $Self-\>{LogModule})
     * "Kernel::System::Log::SysLog" for syslogd (default)
     * "Kernel::System::Log::File" for log file
 - added alternate login and logout URL feature (Kernel/Config.pm --\>
    $Self-\>{LoginURL}, $Self-\>{LogoutURL}) and added two example alternate
    login pages scripts/login.pl (Perl) and scripts/login.php (PHP)
 - added backup and restore script (scripts/(backup|restore).sh)
 - moved Kernel::System::Article to Kernel::System::Ticket::Article! The
    ArticleObject exists not longer in Kernel::Modules::\*, use TicketObject.
 - fixed bug#[25](http://bugs.otrs.org/show_bug.cgi?id=25) Error on bounce of ticket - http://bugs.otrs.org/show_bug.cgi?id=25
 - fixed bug#[27](http://bugs.otrs.org/show_bug.cgi?id=27) Let the fields "new message" and "Locked tickets" be more visible -
    http://bugs.otrs.org/show_bug.cgi?id=27
 - fixed bug#[23](http://bugs.otrs.org/show_bug.cgi?id=23) little menu logic mistake - http://bugs.otrs.org/show_bug.cgi?id=23
 - fixed bug#[30](http://bugs.otrs.org/show_bug.cgi?id=30) Kernel/System/DB.pm - DB quoting http://bugs.otrs.org/show_bug.cgi?id=30
    Thanks to Marc Scheuffler!
 - fixed bug#[28](http://bugs.otrs.org/show_bug.cgi?id=28) Base64 Encoded mail fails - http://bugs.otrs.org/show_bug.cgi?id=28
    Thanks to Christoph Kaulich!
 - fixed rpm bug for SuSE Linux 7.3 (Installer) - Thanks to Schirott Frank!

# 0.5 beta7 2002-08-06
 - improved screen session management (next screen, last screen) added back
    buttons
 - improved ticket and article lib functions (Kernel::System::Ticket::\* and
    Kernel::System::Article)
 - improved fulltext search
 - added time accounting for tickets (added new database table - time\_accounting!
    use scripts/DBUpdate.(mysql|postgresql).sql for database updates!)
 - added notify feature for ticket lock timeout by system
 - added user preferences item email (so login and email can be different)
 - added "Std. Response on creating a queue" feature
    (http://lists.otrs.org/pipermail/otrs/2002-July/000114.html)
 - added module support for auth. (Kernel/Config.pm --\> $Self-\>{AuthModule})
     * "Kernel::System::Auth::DB" against OTRS DB (default)
     * "Kernel::System::Auth::LDAP" against a LDAP directory
 - added "ChangeOwnerToEveryone" feature fot AgentOwner (useful for ASP)
    Kernel/Config.pm -\> $Self-\>{ChangeOwnerToEveryone} = [0|1]
 - added AgentCustomer module (set a customer id to a ticket and get a customer
    history)
 - added a GenericAgent.pl! This program can do some generic actions on tickets
    (like SetLock, MoveTicket, AddNote, SetOwner and SetState). It was developed
    to close (automatically via cron job) ticket in a specific queue, e. g. all
    tickets in the queue 'spam'. (Thanks to Gay Gilmore for the idea)
 - added a simple webform (scripts/webform.pl) to generate emails with X-OTRS-Header
    to dispatch it with procmail (used for feedback forms)
 - added content\_type col. to article table to handle differen charsets correctly
    (use script/DBUpdate.(mysql|postgresql).sql to upgrate existing databases).
 - added generic session storage management (Kernel/Config.pm --\> $Self-\>{SessionModule})
     * "Kernel::System::AuthSession::DB" (default) --\> db storage
     * "Kernel::System::AuthSession::FS" --\> filesystem storage
     * "Kernel::System::AuthSession::IPC" --\> ram storage
 - added http cookie support for session management - it's more comfortable to
    send links -==\> if you have a valid session, you don't have to login again -
    If the client browser disabled html cookies, otrs will work as usual, append
    SessionID to links! (Kernel/Config.pm --\> $Self-\>{SessionUseCookie})
 - added generic ticket number generator (Kernel/Config.pm --\> $Self-\>{TicketNumberGenerator})
     * "Kernel::System::Ticket::Number::AutoIncrement" (default) --\> auto increment
        ticket numbers "SystemID.Counter" like 1010138 and 1010139.
     * "Kernel::System::Ticket::Number::Date" --\> ticket numbers with date
        "Year.Month.Day.SystemID.Counter" like 200206231010138 and 200206231010139.
     * "Kernel::System::Ticket::Number::DateChecksum" --\> ticket numbers with date and
        check sum and the counter will be rotated daily like 2002070110101520 and 2002070110101535.
     * "Kernel::System::Ticket::Number::Random" --\> random ticket numbers "SystemID.Random"
         like 100057866352 and 103745394596.
 - added UPGRADING file
 - updated redhat init script (Thanks to Pablo Ruiz Garcia)
 - fixed bug#[21](http://bugs.otrs.org/show_bug.cgi?id=21) " in email addresses are missing - http://bugs.otrs.org/show_bug.cgi?id=21
    (Thanks to Christoph Kaulich)
 - fixed bug#[19](http://bugs.otrs.org/show_bug.cgi?id=19) Responses sort randomly - http://bugs.otrs.org/show_bug.cgi?id=19
 - fixed SetPermissions.sh (permission for var/log/TicketCounter.log) (Thanks to
    Pablo Ruiz Garcia)
 - fixed bug#[16](http://bugs.otrs.org/show_bug.cgi?id=16) Attachment download - http://bugs.otrs.org/show_bug.cgi?id=16
    (Thanks to Christoph Kaulich)
 - fixed bug#[15](http://bugs.otrs.org/show_bug.cgi?id=15) typo in suse-rcotrs (redhat-rcotrs is not affected) -
    http://bugs.otrs.org/show_bug.cgi?id=15

# 0.5 beta6 2002-06-17
 - added AgentBounce module
 - moved from Unix::Syslog to Sys::Syslog (Kernel::System::Log) because Sys::Syslog
    comes with Perl (not an additional CPAN module)!
 - added redhat-rcotrs script (thanks to Pablo Ruiz Garcia)
 - added OTRS cronjobs var/cron/[aaa\_base|fetchmail|postmaster|session|unlock]
     * aaa\_base -\> cronjob settings like MAILTO="root@localhost"
     * fetchmail -\> cronjob for fetchmail
     * postmaster -\> cleanup for not processed email
     * session -\> cleanup for old sessions
     * unlock -\> ticket unlock
 - added OTRS cronjobs support (start/stop) to scripts/suse-rcotrs
 - moved all OTRS application required modules to two new files,
     * Kernel/Config/Modules.pm (all used OTRS modules)
     * Kernel/Config/ModulesCustom.pm (all add-on application modules, written by
        someone else, e. g. customer db or accounting system)
    to be release independently with Third Party modules for OTRS.
 - added $Env{"Product"} $Env{"Version"} (e. g. OTRS 0.5 Beta6) as dtl environment
    variable. Source is $OTRS\_HOME/RELEASE.
 - added display support for HTML-only emails
 - added generic database and webserver to scripts/suse-rcotrs script
 - added PostgreSQL (7.2 or higher) support (use OpenTRS-schema.postgresql.sql)
 - fixed bug#[12](http://bugs.otrs.org/show_bug.cgi?id=12) fetchmail lock problem - http://bugs.otrs.org/show_bug.cgi?id=12
 - fixed bug#[11](http://bugs.otrs.org/show_bug.cgi?id=11) typos - http://bugs.otrs.org/show_bug.cgi?id=11
 - fixed bug#[10](http://bugs.otrs.org/show_bug.cgi?id=10) user\_preferences table  - http://bugs.otrs.org/show_bug.cgi?id=10
 - fixed bug#[9](http://bugs.otrs.org/show_bug.cgi?id=9) LoopProtection!!! Can't open'/opt/OpenTRS/var/log/LoopProtection-xyz.log':
    No such file or directory! - http://bugs.otrs.org/show_bug.cgi?id=9
 - fixed HTML table bug in AdminArea::Queue (just with Netscape)
 - fixed SQL table preferences bug (use script/DBUpdate.mysql.sql)

# 0.5 beta5 2002-05-27
 - added ticket escalation - if a ticket is to old, only this ticket will be shown
    till somebody is working on it
     * added new row (ticket\_answered) to ticket table
     * updated Kernel/Output/HTML/\<THEME\>/AdminQueueForm.dtl
 - added auto ticket unlock for locked old not answered tickets
     * added new row (ticket\_answered) to ticket table
     * modified Kernel::System::Ticket::Lock::SetLock()
     * added bin/UnlockTickets.pl with --timeout and --all options
 - added command line tool (bin/DeleteSessionIDs.pl) to delete expired or all session
    ids via command line or cron - options are --help, --expired and --all
 - fixed bug#[7](http://bugs.otrs.org/show_bug.cgi?id=7) - space in Installer.pm
    lets creating of database otrs in MySQL fail) by Stefan Schmidt.
 - added URL (screen) recovery after session timeout and possibility to send
    links without session id. Example: Shows you the ticket after OTRS
    login - http://host.example.com/otrs/index.pl?AgentZoom&TicketID=9
 - added http://bugs.otrs.org/ link to the Error.dtl template, to get an easier
    bug reporting
 - added NoPermission.dtl screen
 - added phone tool - Kernel::Modules::AgentPhone.pm
 - added french translation (thanks to Martin Scherbaum)
 - added 'Send follow up notification' and 'Send new ticket notification' to agent
    feature
     * added new values to initial\_insert.sql for agent notifications, table:
       ticket\_history\_type, value: SendAgentNotification
     * modified Kernel/Output/HTML/\<THEME\>/AgentPreferencesForm.dtl
     * required "new" options in Kernel::Config.pm!
 - fixed suse-rcotrs script (thanks to Martin Scherbaum)
     * added "INIT INFO"
     * just check httpd and mysqld - no restart
     * added stop-force|start-force option to restart httpd and mysqld
 - added help texts to the admin screens

# 0.5 beta4 2002-05-07
 - changed login screen and added motd feature (Kernel/Output/HTML/Standard/Motd.dtl
   the motd file)
 - added Kernel::Modules::AdminCharsets.pm
 - added Kernel::Modules::AdminStatus.pm
 - added Kernel::Modules::AdminLanguages.pm
 - added mod\_perl stuff to README.webserver and scripts/suse-httpd.include.conf
 - fixed bug#[6](http://bugs.otrs.org/show_bug.cgi?id=6) - user is a reserved word in
    SQL) reported by Charles Wimmer. Added some variables for table names and columns
    to Kernel/Config.pm. Important: For existing installations you have to change the
    Config.pm or to rename the "user" table to "system\_user"!
 - added "kill all sessions" function to Kernel::Modules::AdminSession.pm
 - added old subject ("subject snip") and old email ("body snip") to auto reply
 - added stats support Kernel::Modules::SystemStats and bin/mkStats.pl (with GD)
 - fixed missing html quoting in Kernel::Output::HTML::Agent-\>AgentHistory
 - update of html in AgentTicketView.dtl and AgentZoom.dtl
 - added MoveInToAllQueues [1|0] to Config.pm (allow to choose the move queues for
    ticket view and zoom [all|own])

# 0.5 beta3 2002-04-17
 - added AgentOwner Module
 - added AgentForward Module
 - added auto session delete functions if remote ip or session time is invalid.
 - added mail (show-)attachment function
 - added permission check functions for AgentZoom, AgentPlain and AgentAttachments
 - added README.application-module

# 0.5 beta2 2002-04-11
 - html (\*.dtl) beautified
 - added session driver (sql|fs)

# 0.5 beta1 2002-03-11
 - first official release
