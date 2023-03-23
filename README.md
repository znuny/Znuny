
<a href="https://www.znuny.org"><img align="center" src="var/httpd/htdocs/skins/Agent/default/img/logo.png"></a>

<p align="center">
    <a href="https://download.znuny.org/releases/znuny-latest.tar.gz"><img src="https://img.shields.io/github/v/tag/znuny/Znuny?sort=semver&label=latest%20release&color=ff9b00"></a>
    <br>
    <a href="https://github.com/znuny/Znuny/actions"><img src="https://img.shields.io/github/actions/workflow/status/znuny/Znuny/ci.yaml?label=CI"></a>
    <a href="https://github.com/znuny/Znuny/actions"><img src="https://badge.proxy.znuny.com/Znuny/rel-6_5"></a>
    <a href="https://translations.znuny.org/engage/znuny/"><img src="https://translations.znuny.org/widgets/znuny/-/znuny/svg-badge.svg" alt="Translation status"></a>
    <br>
    <a href="https://github.com/znuny/Znuny/issues"><img src="https://img.shields.io/github/issues-raw/znuny/Znuny?"></a>
    <a href="https://github.com/znuny/Znuny/issues?q=is%3Aissue+is%3Aclosed"><img src="https://img.shields.io/github/issues-closed-raw/znuny/Znuny?color=#44CC44"></a>
    <a href="https://github.com/znuny/Znuny/pulls"><img src="https://img.shields.io/github/issues-pr-raw/znuny/Znuny?"></a>
    <a href="https://github.com/znuny/Znuny/pulls?q=is%3Apr+is%3Aclosed"><img src="https://img.shields.io/github/issues-pr-closed-raw/znuny/Znuny?color=brightgreen"></a>
    <br>
    <a href="https://github.com/znuny/Znuny"><img src="https://img.shields.io/github/languages/count/znuny/Znuny?style=flat&label=language&color=brightgreen"></a>
    <a href="https://github.com/znuny/Znuny/graphs/contributors"><img src="https://img.shields.io/github/contributors/znuny/Znuny?"></a>
    <a href="https://discord.gg/XTud3WWZTs"><img src="https://img.shields.io/discord/836533233885773825?style=flat"></a>
</p>
<hr>

# Znuny 7 Preview

This project is a preview of the upcoming release branch Znuny 7. It is branched from the current [Znuny 6.5](https://github.com/znuny/Znuny/tree/rel-6_5).

## License

The project is distributed under the GNU General Public License (GPL v3) - see the accompanying COPYING file for general license information.
If you need more details, you can have a look [here](https://snyk.io/learn/what-is-gpl-license-gplv3-explained/).

## Intended Use

This project is intended for use by developers to jump start your integration into the new interface.

**NOT FOR PRODUCTION USE!**

❌ Do not migrate current versions to this project \
❌ Do not use in a production system \
✔️ Do enjoy the preview of new features and front-end changes \
✔️ Do report issues you experience \
✔️ Do port your modules, so they will be ready on launch date

### Feature Testing

We have included new features in this....usage issues that you may experience.

- Activity
- Administration Module Related Settings
- ColorPicker (States and Priorities)
- Dashboard Widget Expand
- Dashboard Summary Counter
- Dropdown Filters
- Search Toolbar
- Customer Ticket Zoom


## Issue Reporting

Generally speaking, you may find issues which need fixing. These will be cosmetic in nature. To report issues found in the release, please use the issue reporting function from GitHub. [Create an Issue](https://github.com/znuny/znuny7-preview/issues/new).

## Known Issues

We are aware of the following areas, which are incomplete and will have issues. So, you must not report any issues on:

- Administration Area

This area works in general, but has not passed QA yet.

## Developer Resource

The following, shows a list of changes of which a developer must be aware.

### Flexbox Implementation Information

#### Color Picker

We have now added a Color Picker to add color to your system for any element you choose.

- Kernel/Output/HTML/Layout/ColorPicker.pm
- Kernel/Output/HTML/Templates/Standard/FormElements/ColorPicker.tt



#### Toolbar Search

ToolBarSearch

These toolbar modules are now all displayed under the block ``ToolBarSearch``:

```
    <Setting Name="Frontend::ToolBarModule###220-Ticket::TicketSearchFulltext" UserPreferencesGroup="Advanced" UserModificationPossible="1" Required="0" Valid="1">
        <Description Translatable="1">Agent interface module to access fulltext search via nav bar. Additional access control to show or not show this link can be done by using Key "Group" and Content like "rw:group1;move_into:group2".</Description>
        <Navigation>Frontend::Agent::ToolBar</Navigation>
        <Value>
            <Hash>
                <Item Key="Module">Kernel::Output::HTML::ToolBar::Generic</Item>
                <Item Key="Name" Translatable="1">Fulltext</Item>
                <Item Key="Description" Translatable="1">Fulltext search</Item>
                <Item Key="Block">ToolBarSearch</Item>
                <Item Key="Priority">1990010</Item>
            </Hash>
        </Value>
    </Setting>
```

#### CSS Structure

All the new CSS has been included in the previously used files, and additional CSS files have been added to increase flexibility and ease of reconfiguration.

Added new CSS files:
```
Core.Vars.css
Core.Reset.Forwwward.css
Core.Overview.css
Core.Components.css
Core.FlexboxModel.css
Core.Typography.css
```

#### Dashboard Summary Counter

A new counter has been added:

- Kernel/Output/HTML/Dashboard/TicketGeneric.pm


#### Toolbar Modules

For toolbar modules, we have added new areas (blocks). To have toolbar modules correctly shown, use one of these blocks:

``<Item Key="Block">ToolBarPersonalViews</Item>``

- ToolBarOverviews
- ToolBarActions
- ToolBarPersonalViews
- ToolBarSearch

#### Input Fields

We have changed the behavior of the `Core.UI.InputFields.js`. Now, no fields are automatically enlarged or reduced.
Affected files: `var/httpd/htdocs/js/Core.UI.InputFields.js`

#### New Modal Sizes

We added new DialogClasses for modal content. The inner width of the modal contents determines automatically the size of the modal which will be displayed Look at the following chart to see the sizing:
```
modal-sm upto 499
modal-md upto 799
modal-lg largen 800
```

#### Dates and Date/Times

``<div>`` Tags must be used around date/time elements now.


### Breadcrumbs

BreadcrumbPath
Moved all Breadcrumbs into the Content / ContentColumn div block.\
https://docs.google.com/document/d/1AHWJ_npkxCq6PMfKtJRKkZoSQqj_v9vX_RBvuLGm9vQ/edit

### CSS

Added Base module to add additional inline CSS and also added a Layout->ColorPicker.
Affected files:

```
Kernel/Output/CSS/Base.pm
Kernel/Output/HTML/Layout/CSS.pm
Kernel/Output/HTML/Layout/Loader.pm
Kernel/Output/HTML/Layout.pm
```

### Structure

Many files in the standard output library have been restructured to include multiple div tags and classes, et cetera. Please look at the following list to see if you have modified these files within your packages and make the appropriate changes.

```
Kernel/Output/HTML/Templates/Standard/AgentTicketZoom/TicketInformation.tt
Kernel/Output/HTML/Templates/Standard/CustomerCompany/TicketCustomerIDSelection.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom/ArticleRender/MIMEBase.tt
Kernel/Output/HTML/Templates/Standard/FormElements/AttachmentList.tt
Kernel/Output/HTML/Templates/Standard/FormElements/DraftButtons.tt
Kernel/Output/HTML/Templates/Standard/LastViews/Agent/Avatar.tt
Kernel/Output/HTML/Templates/Standard/LastViews/Agent/MenuBar.tt
Kernel/Output/HTML/Templates/Standard/LastViews/Agent/ToolBar.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/ActivityDialogFooter.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/ActivityDialogHeader.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Article.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Attachment.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Customer.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/CustomerActivityDialogFooter.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/CustomerActivityDialogHeader.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/DynamicField.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Lock.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Owner.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/PendingTime.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/PendingTime.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Queue.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Responsible.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/SLA.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Service.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/State.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Title.tt
Kernel/Output/HTML/Templates/Standard/ProcessManagement/Title.tt
Kernel/Output/HTML/Templates/Standard/Statistics/GeneralSpecificationsWidget.tt
Kernel/Output/HTML/Templates/Standard/Statistics/RestrictionsWidget.tt
Kernel/Output/HTML/Templates/Standard/Statistics/StatsParamsWidget.tt
Kernel/Output/HTML/Templates/Standard/Statistics/XAxisWidget.tt
Kernel/Output/HTML/Templates/Standard/Statistics/YAxisWidget.tt
Kernel/Output/HTML/Templates/Standard/Ticket/TimeUnits.tt
Kernel/Output/HTML/Templates/Standard/AdminACL.tt
Kernel/Output/HTML/Templates/Standard/AdminACLEdit.tt
Kernel/Output/HTML/Templates/Standard/AdminACLNew.tt
Kernel/Output/HTML/Templates/Standard/AdminAppointmentCalendarManage.tt
Kernel/Output/HTML/Templates/Standard/AdminAppointmentImport.tt
Kernel/Output/HTML/Templates/Standard/AdminAppointmentNotificationEvent.tt
Kernel/Output/HTML/Templates/Standard/AdminAttachment.tt
Kernel/Output/HTML/Templates/Standard/AdminAutoResponse.tt
Kernel/Output/HTML/Templates/Standard/AdminCommunicationLog.tt
Kernel/Output/HTML/Templates/Standard/AdminCommunicationLogAccounts.tt
Kernel/Output/HTML/Templates/Standard/AdminCommunicationLogZoom.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerCompany.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerUser.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerUserCustomer.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerUserGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminCustomerUserService.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicField.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldCheckbox.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldConfigurationImportExport.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldDateTime.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldDropdown.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldMultiselect.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldScreenConfiguration.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldText.tt
Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldWebservice.tt
Kernel/Output/HTML/Templates/Standard/AdminEmail.tt
Kernel/Output/HTML/Templates/Standard/AdminGenericAgent.tt
Kernel/Output/HTML/Templates/Standard/AdminGenericInterfaceDebugger.tt
Kernel/Output/HTML/Templates/Standard/AdminGenericInterfaceWebservice.tt
Kernel/Output/HTML/Templates/Standard/AdminGenericInterfaceWebserviceHistory.tt
Kernel/Output/HTML/Templates/Standard/AdminGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminLog.tt
Kernel/Output/HTML/Templates/Standard/AdminMailAccount.tt
Kernel/Output/HTML/Templates/Standard/AdminNavigationBar.tt
Kernel/Output/HTML/Templates/Standard/AdminNotificationEvent.tt
Kernel/Output/HTML/Templates/Standard/AdminPGP.tt
Kernel/Output/HTML/Templates/Standard/AdminPackageManager.tt
Kernel/Output/HTML/Templates/Standard/AdminPerformanceLog.tt
Kernel/Output/HTML/Templates/Standard/AdminPostMasterFilter.tt
Kernel/Output/HTML/Templates/Standard/AdminPriority.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagement.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementActivity.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementActivityDialog.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementPath.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementProcessAccordion.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementProcessEdit.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementProcessNew.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementProcessPrint.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementTransition.tt
Kernel/Output/HTML/Templates/Standard/AdminProcessManagementTransitionAction.tt
Kernel/Output/HTML/Templates/Standard/AdminQueue.tt
Kernel/Output/HTML/Templates/Standard/AdminQueueAutoResponse.tt
Kernel/Output/HTML/Templates/Standard/AdminQueueTemplates.tt
Kernel/Output/HTML/Templates/Standard/AdminRole.tt
Kernel/Output/HTML/Templates/Standard/AdminRoleGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminRoleUser.tt
Kernel/Output/HTML/Templates/Standard/AdminSLA.tt
Kernel/Output/HTML/Templates/Standard/AdminSMIME.tt
Kernel/Output/HTML/Templates/Standard/AdminSalutation.tt
Kernel/Output/HTML/Templates/Standard/AdminSelectBox.tt
Kernel/Output/HTML/Templates/Standard/AdminService.tt
Kernel/Output/HTML/Templates/Standard/AdminSession.tt
Kernel/Output/HTML/Templates/Standard/AdminSignature.tt
Kernel/Output/HTML/Templates/Standard/AdminState.tt
Kernel/Output/HTML/Templates/Standard/AdminSupportDataCollector.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemAddress.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfiguration.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationDeployment.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationImportExport.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationSearch.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationSpecialGroup.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemConfigurationView.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemMaintenance.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemMaintenanceEdit.tt
Kernel/Output/HTML/Templates/Standard/AdminSystemMaintenanceNew.tt
Kernel/Output/HTML/Templates/Standard/AdminTemplate.tt
Kernel/Output/HTML/Templates/Standard/AdminTemplateAttachment.tt
Kernel/Output/HTML/Templates/Standard/AdminTicketAttributeRelations.tt
Kernel/Output/HTML/Templates/Standard/AdminType.tt
Kernel/Output/HTML/Templates/Standard/AdminUser.tt
Kernel/Output/HTML/Templates/Standard/AdminUserGroup.tt
var/httpd/htdocs/js/Znuny.Form.Input.js
Kernel/Output/HTML/Templates/Standard/AgentAppointmentAgendaOverview.tt
Kernel/Output/HTML/Templates/Standard/AgentAppointmentCalendarOverview.tt
Kernel/Output/HTML/Templates/Standard/AgentAppointmentEdit.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerInformationCenter.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerInformationCenterSearch.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerTableView.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerUserAddressBook.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerUserAddressBookOverview.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerUserAddressBookOverviewNavBar.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerUserInformationCenter.tt
Kernel/Output/HTML/Templates/Standard/AgentCustomerUserInformationCenterSearch.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboard.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardAppointmentCalendar.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCommon.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCustomerCompanyInformation.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCustomerIDList.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCustomerIDStatus.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCustomerUserInformation.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardCustomerUserList.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardTicketGeneric.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardUserOnline.tt
Kernel/Output/HTML/Templates/Standard/AgentDashboardUserOutOfOffice.tt
Kernel/Output/HTML/Templates/Standard/AgentLinkObject.tt
Kernel/Output/HTML/Templates/Standard/AgentNavigationBar.tt
Kernel/Output/HTML/Templates/Standard/AgentPreferences.tt
Kernel/Output/HTML/Templates/Standard/AgentPreferencesOverview.tt
Kernel/Output/HTML/Templates/Standard/AgentSplitSelection.tt
Kernel/Output/HTML/Templates/Standard/AgentStatisticsAdd.tt
Kernel/Output/HTML/Templates/Standard/AgentStatisticsEdit.tt
Kernel/Output/HTML/Templates/Standard/AgentStatisticsImport.tt
Kernel/Output/HTML/Templates/Standard/AgentStatisticsOverview.tt
Kernel/Output/HTML/Templates/Standard/AgentStatisticsView.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketActionCommon.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketBounce.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketBulk.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketCompose.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketCustomer.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketEmail.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketEmailOutbound.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketForward.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketHistory.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketMerge.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketMove.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketOverviewMedium.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketOverviewNavBar.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketOverviewPreview.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketOverviewSmall.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketPhone.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketPhoneCommon.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketPlain.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketProcess.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketProcessSmall.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketQueue.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketSearch.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketService.tt
Kernel/Output/HTML/Templates/Standard/AgentTicketZoom.tt
Kernel/Output/HTML/Templates/Standard/ArticleActionMenu.tt
Kernel/Output/HTML/Templates/Standard/AttachmentBlocker.tt
Kernel/Output/HTML/Templates/Standard/Breadcrumb.tt
Kernel/Output/HTML/Templates/Standard/Chat.tt
Kernel/Output/HTML/Templates/Standard/CustomerHTMLHead.tt
Kernel/Output/HTML/Templates/Standard/CustomerHeader.tt
Kernel/Output/HTML/Templates/Standard/CustomerLogin.tt
Kernel/Output/HTML/Templates/Standard/CustomerNavigationBar.tt
Kernel/Output/HTML/Templates/Standard/CustomerPreferences.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketMessage.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketOverview.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketProcess.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketSearch.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketSearchResultShort.tt
Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt
Kernel/Output/HTML/Templates/Standard/Footer.tt
Kernel/Output/HTML/Templates/Standard/HTMLHead.tt
Kernel/Output/HTML/Templates/Standard/Header.tt
Kernel/Output/HTML/Templates/Standard/LinkObject.tt
Kernel/Output/HTML/Templates/Standard/Login.tt
Kernel/Output/HTML/Templates/Standard/Notify.tt
Kernel/Output/HTML/Templates/Standard/Pagination.tt
```

<hr>

<hr>

<hr>

<a href="https://www.znuny.org"><img align="center" src="var/httpd/htdocs/skins/Agent/default/img/logo.png"></a>

Znuny
=======
Znuny is a continuation of the ((OTRS)) Community Edition (version 6.0.30) which was declared end of life (EOL) at the end of December 2020.

The primary goal for this project is to provide a maintained and stable version of the well known ticket system and improve it with new features.

The second goal is to reestablish a connection to the community.

License
=======
The project is distributed under the GNU General Public License (GPL v3) - see the accompanying [COPYING](COPYING) file for general license information.
If you need more details you can have a look [here](https://snyk.io/learn/what-is-gpl-license-gplv3-explained/).

Documentation
=============
You can find documentation [here](https://doc.znuny.org/).
The source code of Znuny is publicly available on [GitHub](https://github.com/znuny/znuny).

You want to get in touch?
- [Project website](https://www.znuny.org)
- [Community forum](https://community.znuny.org)
- [Discord Server](https://discord.gg/XTud3WWZTs)
- [Commercial services](https://www.znuny.com)

Software requirements
=====================
Operating system
- Linux (Debian or Red Hat preferred)
- Perl 5.16.0 or higher

Web server
- Apache 2 + mod_perl2 or higher (recommended)
- Web server with CGI support (CGI is not recommended)

Databases
- MySQL 5.0 or higher
- MariaDB
- PostgreSQL 9.2 or higher
- Oracle 10g or higher

Browsers
- These browsers are NOT supported:
  - Internet Explorer before version 11
  - Firefox before version 31
  - Safari before version 6

Vendor
=======
This project is mainly funded by Znuny GmbH, Berlin.
If you need professional support or consulting, feel free to contact us.

[Znuny Website](https://www.znuny.com)
