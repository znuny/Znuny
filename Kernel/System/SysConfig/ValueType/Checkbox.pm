# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SysConfig::ValueType::Checkbox;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::SysConfig::BaseValueType);

our @ObjectDependencies = (
    'Kernel::Language',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::SysConfig::ValueType::Checkbox - System configuration check-box value type backed.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ValueTypeObject = $Kernel::OM->Get('Kernel::System::SysConfig::ValueType::Checkbox');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 SettingEffectiveValueCheck()

Check if provided EffectiveValue matches structure defined in XMLContentParsed.

    my %Result = $ValueTypeObject->SettingEffectiveValueCheck(
        XMLContentParsed => {
            Value => [
                {
                    'Item' => [
                        {
                            'Content'   => '1',
                            'ValueType' => 'Checkbox',
                        },
                    ],
                },
            ],
        },
        EffectiveValue => '1',
    );

Result:
    %Result = (
        EffectiveValue => 'open',    # Note for Checkbox ValueTypes EffectiveValue is not changed.
        Success => 1,
        Error   => undef,
    );

=cut

sub SettingEffectiveValueCheck {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(XMLContentParsed)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );

            return;
        }
    }

    my %Result = (
        Success => 0,
    );

    # Data should be scalar.
    if ( ref $Param{EffectiveValue} ) {
        $Result{Error} = 'EffectiveValue for Checkbox must be a scalar!';
        return %Result;
    }

    if ( $Param{EffectiveValue} && $Param{EffectiveValue} ne '1' ) {
        $Result{Error} = 'EffectiveValue must be 0 or 1 for Checkbox!';
        return %Result;
    }

    $Result{Success}        = 1;
    $Result{EffectiveValue} = $Param{EffectiveValue};

    return %Result;
}

=head2 SettingRender()

Extracts the effective value from a XML parsed setting.

    my $SettingHTML = $ValueTypeObject->SettingRender(
        Name           => 'SettingName',
        DefaultID      =>  123,             # (required)
        EffectiveValue => 'Product 6',
        DefaultValue   => 'Product 5',      # (optional)
        Class          => 'My class'        # (optional)
        RW             => 1,                # (optional) Allow editing. Default 0.
        Item           => [                 # (optional) XML parsed item
            {
                'ValueType' => 'Checkbox',
                'Content' => '1',
                'ValueRegex' => '',
            },
        ],
        IsArray => 1,                       # (optional) Item is part of the array
        IsHash  => 1,                       # (optional) Item is part of the hash
        IDSuffix => 1,                      # (optional) Suffix will be added to the element ID
        SkipEffectiveValueCheck => 1,       # (optional) If enabled, system will not perform effective value check.
                                            #            Default: 1.
    );

Returns:

    $SettingHTML = '<div class "Field"...</div>';

=cut

sub SettingRender {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Name EffectiveValue)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed",
            );
            return;
        }
    }

    $Param{Class}        //= '';
    $Param{DefaultValue} //= '';

    my $IDSuffix = $Param{IDSuffix} || '';

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    my $EffectiveValue = $Param{EffectiveValue};

    if (
        !defined $Param{EffectiveValue}
        && $Param{Item}->[0]->{Content}
        )
    {
        $EffectiveValue = $Param{Item}->[0]->{Content};
    }

    my %EffectiveValueCheck = (
        Success => 1,
    );

    if ( !$Param{SkipEffectiveValueCheck} ) {
        %EffectiveValueCheck = $Self->SettingEffectiveValueCheck(
            EffectiveValue   => $EffectiveValue,
            XMLContentParsed => {
                Value => [
                    {
                        Item => $Param{Item},
                    },
                ],
            },
        );
    }

    my $HTML = "<div class='SettingContent'>\n";
    $HTML
        .= "<input class=\"$Param{Class}\" type=\"checkbox\" id=\"Checkbox_$Param{Name}$IDSuffix\" ";
    $HTML .= "value=\"1\" ";

    if ($EffectiveValue) {
        $HTML .= "checked='checked' ";
    }

    if ( !$Param{RW} ) {
        $HTML .= "disabled='disabled' ";
    }
    $HTML .= ">";

    # Add hidden input field with checkbox value
    $HTML .= "<input type='hidden' name='$Param{Name}' id=\"$Param{Name}$IDSuffix\" ";
    if ($EffectiveValue) {
        $HTML .= "value='1' ";
    }
    else {
        $HTML .= "value='0' ";
    }
    $HTML .= "/>\n";

    $HTML .= "<label for='Checkbox_$Param{Name}$IDSuffix' class='CheckboxLabel'>"
        . $LanguageObject->Translate('Enabled')
        . "</label>\n";

    if ( !$EffectiveValueCheck{Success} ) {
        my $Message = $LanguageObject->Translate("Value is not correct! Please, consider updating this field.");

        $HTML .= $Param{IsValid} ? "<div class='BadEffectiveValue'>\n" : "<div>\n";
        $HTML .= "<p>* $Message</p>\n";
        $HTML .= "</div>\n";
    }

    $HTML .= "</div>\n";

    if ( !$Param{IsArray} && !$Param{IsHash} ) {
        my $DefaultText      = $Kernel::OM->Get('Kernel::Language')->Translate('Default');
        my $DefaultValueText = $Param{DefaultValue}
            ?
            $LanguageObject->Translate('Enabled')
            :
            $LanguageObject->Translate('Disabled');

        $HTML .= <<"EOF";
                                <div class=\"WidgetMessage Bottom\">
                                    $DefaultText: $DefaultValueText
                                </div>
EOF
    }

    return $HTML;
}

sub EffectiveValueCalculate {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Name)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Result = '0';

    if ( $Param{ $Param{Name} } ) {
        $Result = $Param{ $Param{Name} };
    }

    return $Result;
}

=head2 AddItem()

Generate HTML for new array/hash item.

    my $HTML = $ValueTypeObject->AddItem(
        Name           => 'SettingName',    (required) Name
        DefaultItem    => {                 (optional) DefaultItem hash, if available
            Content => 'Value',
            ValueType => 'Checkbox',
        },
        IDSuffix       => '_Array1',        (optional) IDSuffix is needed for arrays and hashes.
    );

Returns:

    $HTML = "<input type="checkbox" checked="checked" name="SettingName" value="1" id="SettingName_Array1">
        <input type="hidden" value="1" name="SettingName">
        <label for="SettingName_Array1" class='CheckboxLabel'>
            Enabled
        </label>";

=cut

sub AddItem {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Name)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $IDSuffix = $Param{IDSuffix} || '';
    my $Checked;
    if ( $Param{DefaultItem} ) {
        $Checked = $Param{DefaultItem}->{Content};
    }

    my $Enabled = $Kernel::OM->Get('Kernel::Language')->Translate('Enabled');

    my $Result = "<input type=\"checkbox\" id=\"Checkbox_$Param{Name}$IDSuffix\" value=\"1\" ";

    if ($Checked) {
        $Result .= "checked='checked' ";
    }

    $Result .= "/><input type=\"hidden\" class=\"Entry\" id=\"$Param{Name}$IDSuffix\" name=\"$Param{Name}\" value=\"";

    if ($Checked) {
        $Result .= "1";
    }
    else {
        $Result .= "0";
    }

    $Result .= "\" /><label for='Checkbox_$Param{Name}$IDSuffix' class='CheckboxLabel'>$Enabled</label>";

    return $Result;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
