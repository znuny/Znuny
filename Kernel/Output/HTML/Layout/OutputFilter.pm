# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Layout::OutputFilter;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::OutputFilter

=head1 DESCRIPTION

All valid functions.

=head1 PUBLIC INTERFACE

=head2 _OutputFilterHookShift()

modifies content and uses output filter hooks to get hook content

    my $Data = $LayoutObject->_OutputFilterHookShift(
        Name => 'DynamicField',
        All  => 1,
        %Param,
    );

Returns:

    my $Data = '.... html ...';

=cut

sub _OutputFilterHookShift {
    my ( $Self, %Param ) = @_;

    my $Name = $Param{Name};
    my $All  = $Param{All};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Return    = '';
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;
    my $Counter   = 0;

    # http://stackoverflow.com/questions/7374107/infinite-while-loop-in-perl
    HOOK:
    for my $Content ( ${ $Param{Data} } =~ m{$HookRegex}g ) {

        $Return .= $Content;

        ${ $Param{Data} } =~ s{\Q$Content\E}{};
        $Counter++;

        last HOOK if $Counter > 1000;
        last HOOK if !$All;
    }

    return $Return;
}

=head2 _OutputFilterHookReplace()

modifies content and uses output filter hooks to get hook content

    my $Success = $LayoutObject->_OutputFilterHookReplace(
        Name    => 'DynamicField',
        All     => 1,
        Replace => sub {
            my ( %Param ) = @_;

            my $Content = $Param{Content};

            $Content =~ s{test}{test2};

            return $Content;
        },
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookReplace {
    my ( $Self, %Param ) = @_;

    my $All     = $Param{All};
    my $Name    = $Param{Name};
    my $Replace = $Param{Replace};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Success;
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> (.+?) <\!-- \s* HookEnd$Name \s* --> }xmsi;
    my $Counter   = 0;

    # http://stackoverflow.com/questions/7374107/infinite-while-loop-in-perl
    HOOK:
    for my $Content ( ${ $Param{Data} } =~ m{$HookRegex}g ) {

        my $ContentNew = $Replace->(
            %Param,
            Content => $Content,
        );

        next HOOK if !defined $ContentNew;
        next HOOK if $Content eq $ContentNew;

        ${ $Param{Data} } =~ s{\Q$Content\E}{$ContentNew};
        $Success = 1;
        $Counter++;

        last HOOK if $Counter > 1000;
        last HOOK if !$All;
    }

    return $Success;
}

=head2 _OutputFilterHookExists()

modifies content and uses output filter hooks to check if a hook exists

    my $Exists = $LayoutObject->_OutputFilterHookExists(
        Name => 'DynamicField',
        %Param,
    );

Returns:

    my $Exists = 1;

=cut

sub _OutputFilterHookExists {
    my ( $Self, %Param ) = @_;

    my $Name = $Param{Name};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Return    = '';
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;

    return if ${ $Param{Data} } !~ $HookRegex;
    return 1;
}

=head2 _OutputFilterHookInsertAfter()

modifies content and uses output filter hooks to add content after hook.

    my $Success = $LayoutObject->_OutputFilterHookInsertAfter(
        Name    => 'DynamicField',
        Content => '... html ...',
        All     => 1,                 # to insert after the last found hook e.g. to insert after the last dynamic field
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookInsertAfter {
    my ( $Self, %Param ) = @_;

    my $All     = $Param{All};
    my $Name    = $Param{Name};
    my $Content = $Param{Content};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    return if !$Self->_OutputFilterHookExists(%Param);

    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;
    if ($All) {
        $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+ <\!-- \s* HookEnd$Name \s* --> }xmsi;
    }

    ${ $Param{Data} } =~ s{$HookRegex}{ $& $Content }xmsig;

    return 1;
}

=head2 _OutputFilterHookInsertBefore()

modifies content and uses output filter hooks to add content before hook.

    my $Success = $LayoutObject->_OutputFilterHookInsertBefore(
        Name    => 'DynamicField',
        Content => '... html ...',
        All     => 1,                 # to insert before the first found hook e.g. to insert before the first dynamic field
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookInsertBefore {
    my ( $Self, %Param ) = @_;

    my $All     = $Param{All};
    my $Name    = $Param{Name};
    my $Content = $Param{Content};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    return if !$Self->_OutputFilterHookExists(%Param);

    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;
    if ($All) {
        $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+ <\!-- \s* HookEnd$Name \s* --> }xmsi;
    }

    ${ $Param{Data} } =~ s{$HookRegex}{ $Content $& }xmsig;

    return 1;
}

1;
