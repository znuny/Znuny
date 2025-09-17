# --
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::CustomerTicketProcessCategory;

use strict;
use warnings;
use utf8;

use MIME::Base64;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless $Self, $Type;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ProcessObject        = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject         = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');
    my $WebUploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # List only Active processes by default
    my @ProcessStates = ('Active');

    # Get the list of processes that customer can start
    my $ProcessList = $ProcessObject->ProcessList(
        ProcessState => \@ProcessStates,
        Interface    => ['CustomerInterface'],
    );

    if ( !IsHashRefWithData($ProcessList) ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => Translatable('No Process configured!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # Prepare process list for ACLs, use only entities instead of names, convert from
    # P1 => Name to P1 => P1. As ACLs should work only against entities
    my %ProcessListACL = map { $_ => $_ } sort keys %{$ProcessList};

    # Validate the ProcessList with stored ACLs
    my $ACL = $TicketObject->TicketAcl(
        ReturnType     => 'Process',
        ReturnSubType  => '-',
        Data           => \%ProcessListACL,
        Action         => $Self->{Action},
        CustomerUserID => $Self->{UserID},
    );

    if ( IsHashRefWithData($ProcessList) && $ACL ) {

        # Get ACL results
        my %ACLData = $TicketObject->TicketAclData();

        # Recover process names
        my %ReducedProcessList = map { $_ => $ProcessList->{$_} } sort keys %ACLData;

        # Replace original process list with the reduced one
        $ProcessList = \%ReducedProcessList;
    }

    $Self->{FormID} = $ParamObject->GetParam( Param => 'FormID' );

    # Create form id
    if ( !$Self->{FormID} ) {
        $Self->{FormID} = $WebUploadCacheObject->FormIDCreate();
    }

    # To display the process list is mandatory to have processes that customer can start
    if ( !IsHashRefWithData($ProcessList) ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => Translatable('No Process configured!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    return $Self->_DisplayProcessCategory(
        %Param,
        ProcessList => $ProcessList,
    );
}

sub _DisplayProcessCategory {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessObject      = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $JSONObject         = $Kernel::OM->Get('Kernel::System::JSON');

    my $Config             = $ConfigObject->Get('Ticket::Frontend::CustomerTicketProcessCategory');
    my $ProcessPreferences = $ConfigObject->Get('ProcessPreferences');

    my %UserPreferences = $CustomerUserObject->GetPreferences(
        UserID => $Self->{UserID},
    );

    my $Favourites = $JSONObject->Decode(
        Data => $UserPreferences{TicketProcessCategoryFavourites},
    ) || [];

    my $CategoryData = $ProcessPreferences->{'001-TicketProcessCategory-Category'}->{Data} || {};
    my %CategoryCount;
    my @Process;

    PROCESSENTITY:
    for my $ProcessEntityID ( sort keys %{ $Param{ProcessList} } ) {

        my $ProcessData = $ProcessObject->ProcessGet(
            EntityID => $ProcessEntityID,
            UserID   => $Self->{UserID} || $LayoutObject->{UserID},
        );

        next PROCESSENTITY if !$ProcessData;
        next PROCESSENTITY if !$ProcessData->{Category};
        push @Process, $ProcessData;
    }

    for my $ProcessData (@Process) {

        my %Icon;

        # Use the Icon from the Process if it is set (ProcessPreferences)
        if ( IsHashRefWithData( $ProcessData->{Icon}->[0] ) ) {
            %Icon = $Self->_GetIcon(
                %{ $ProcessData->{Icon}->[0] }
            );
        }

        # Set the LinkTarget from the Process if it is set (ProcessPreferences) or
        # from the `Ticket::Frontend::CustomerTicketProcessCategory` Config
        my $LinkTarget = $ProcessData->{LinkTarget} || $Config->{LinkTarget} || '_self';
        my $Link;
        my $LinkCSS;

        # Set the Link to the ActivityDialog in new Popup
        if ( $LinkTarget eq 'AsPopup' ) {
            $LinkCSS = 'AsPopup';

            $Link = $LayoutObject->{Baselink}
                . "Action=CustomerTicketProcess;Subaction=DisplayActivityDialog;ProcessEntityID="
                . $ProcessData->{EntityID}
                . ";ActivityDialogEntityID="
                . $ProcessData->{Config}->{StartActivityDialog};
        }

        # Set the Link to the Process and the StartActivityDialog
        else {
            $Link = $LayoutObject->{Baselink}
                . "Action=CustomerTicketProcess"
                . ";ID=" . $ProcessData->{EntityID}
                . ";ActivityDialogEntityID=" . $ProcessData->{Config}->{StartActivityDialog};
        }

        # Use the Link from the Process if it is set (ProcessPreferences)
        if ( $ProcessData->{Link} ) {
            $Link = $ProcessData->{Link};
        }

        my $Category;
        if ( IsArrayRefWithData( $ProcessData->{Category} ) ) {
            CATEGORYID:
            for my $CategoryID ( @{ $ProcessData->{Category} } ) {
                next CATEGORYID if !$CategoryData->{$CategoryID};

                $CategoryCount{$CategoryID}++;
                my @CategoryStructure = split /::/, $CategoryData->{$CategoryID};

                $Category .= ', ' if IsStringWithData($Category);

                my $CategoryTranslation
                    = $LayoutObject->{LanguageObject}->Translate( $CategoryStructure[-1] ) || $CategoryStructure[-1];

                $Category .= $CategoryTranslation;
            }
        }
        else {
            my $CategoryID = $ProcessData->{Category};
            $CategoryCount{$CategoryID}++;

            my @CategoryStructure = split /::/, $CategoryData->{$CategoryID};
            $Category .= ', ' if IsStringWithData($Category);

            my $CategoryTranslation
                = $LayoutObject->{LanguageObject}->Translate( $CategoryStructure[-1] ) || $CategoryStructure[-1];
            $Category .= $CategoryTranslation;
        }

        my $IsFavourite = grep { $_ eq $ProcessData->{ID} } @{$Favourites};

        $LayoutObject->Block(
            Name => 'Process',
            Data => {
                %{$ProcessData},
                IsFavourite => $IsFavourite,
                Description => $ProcessData->{Config}->{Description},
                Category    => $Category,
                ProcessID   => $ProcessData->{EntityID},
                Link        => $Link,
                LinkCSS     => $LinkCSS,
                LinkTarget  => $LinkTarget,
                Icon        => \%Icon,
            },
        );
    }

    CATEGORY:
    for my $CategoryID ( sort keys %{$CategoryData} ) {
        my @CategoryStructure = split /::/, $CategoryData->{$CategoryID};
        my $Placeholder;
        my $SubCategoriesClass;

        my $Level;
        SUBCATEGORIES:
        for my $SubCategories (@CategoryStructure) {
            $Level++;

            if ( $SubCategories eq $CategoryStructure[-1] ) {
                $SubCategoriesClass .= 'Level-' . $Level;
            }
            next SUBCATEGORIES if $Level <= 1;
            $Placeholder .= '-';
        }

        my $CategoryCount = $CategoryCount{$CategoryID};
        my $Category      = $CategoryStructure[-1];

        # Check if this category or its subcategories contain items
        next CATEGORY if !$Self->_HasCategoryItemsOrChildItems(
            CategoryID    => $CategoryID,
            CategoryData  => $CategoryData,
            CategoryCount => \%CategoryCount,
        );

        $LayoutObject->Block(
            Name => 'Category',
            Data => {
                Name               => $Category,
                Count              => $CategoryCount || 0,
                Placeholder        => $Placeholder,
                SubCategoriesClass => $SubCategoriesClass,
            },
        );
    }

    my $Output = $LayoutObject->CustomerHeader();
    $Output .= $LayoutObject->CustomerNavigationBar();

    $LayoutObject->AddJSData(
        Key   => 'Favourites',
        Value => $Favourites,
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerTicketProcessCategory',
        Data         => {
            %Param,
            Favourites => $Favourites,
        },
    );

    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

sub _GetIcon {
    my ( $Self, %Param ) = @_;

    my $ContentBase64 = encode_base64( ${ $Param{Content} } );

    my %Icon = (
        ContentType => $Param{Preferences}->{ContentType} || 'image/png',
        Filename    => $Param{Preferences}->{Filename}    || 'logo.png',
        Content     => $ContentBase64,
        Width       => '100%',
        Height      => '100%',
    );

    return %Icon;

}

# Check if a category or any of its subcategories contain items
sub _HasCategoryItemsOrChildItems {
    my ( $Self, %Param ) = @_;

    my $CategoryID    = $Param{CategoryID};
    my $CategoryData  = $Param{CategoryData};
    my $CategoryCount = $Param{CategoryCount};

    # Direct items in this category
    return 1 if $CategoryCount->{$CategoryID};

    # Check all subcategories
    for my $ChildCategoryID ( sort keys %{$CategoryData} ) {
        my $ChildCategoryPath      = $CategoryData->{$ChildCategoryID};
        my @ChildCategoryStructure = split /::/, $ChildCategoryPath;

        # If this category is a parent of the child category
        if ( scalar @ChildCategoryStructure > 1 ) {
            my $ParentPath = join '::', @ChildCategoryStructure[ 0 .. $#ChildCategoryStructure - 1 ];
            if ( $ParentPath eq $CategoryData->{$CategoryID} ) {

                # Recursively check if the child category has items
                return 1 if $Self->_HasCategoryItemsOrChildItems(
                    CategoryID    => $ChildCategoryID,
                    CategoryData  => $CategoryData,
                    CategoryCount => $CategoryCount,
                );
            }
        }
    }

    return 0;
}

1;
