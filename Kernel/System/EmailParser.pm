# --
# Kernel/System/EmailParser.pm - the global email parser module
# Copyright (C) 2001-2002 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: EmailParser.pm,v 1.4 2002-07-17 22:31:06 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::EmailParser;

use strict;
use Mail::Internet;
use MIME::Parser;

use vars qw($VERSION);
$VERSION = '$Revision: 1.4 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

# --
sub new {
    my $Type = shift;
    my %Param = @_;

    my $Self = {}; # allocate new hash for object
    bless ($Self, $Type);

    $Self->{Debug} = 0;

    $Self->{OrigEmail} = $Param{OrigEmail};
    $Self->{Email} = new Mail::Internet($Param{Email});
    return $Self;
}
# --
sub GetParam {
    my $Self = shift;
    my %Param = @_;
    my $What = $Param{WHAT} || return;

    my $Header = $Self->GetHeader();
    $Header->combine($What);
    my $Line = $Header->get($What) || '';
    chomp ($Line);
    return $Line;
}
# --
sub GetEmailAddress {
    my $Self = shift;
    my %Param = @_;
    my $TestAddress = $Param{Email};
    my $RealAddress = $TestAddress;

    $TestAddress =~ s/\(.*?\)//g;

    if ($TestAddress =~ /<(.*?)>/) {
        $RealAddress= $1;
    }
    $RealAddress =~ s/ //g;
    return $RealAddress;
}
# --
sub SplitAddressLine {
    my $Self = shift;
    my %Param = @_;
    my $Line = $Param{Line};
    my @GetParam = split(/,/, $Line);
    return @GetParam;
}
# --
sub GetHeader {
    my $Self = shift;
    my %Param = @_;
    if (!exists $Self->{Header}) {
        $Self->{Header} = $Self->{Email}->head();
    }
    return $Self->{Header};
}
# --
sub GetBody {
    my $Self = shift;
    my %Param = @_;
    if (!exists $Self->{Body}) {
        $Self->{Body} = $Self->{Email}->body();
    }
    return $Self->{Body};
}
# --
sub GetContentType {
    my $Self = shift;
    my $ContentType = shift || '';
    if ($Self->{ContentType}) {
        return $Self->{ContentType};
    }
    else {
        return $ContentType;
    }
}
# --
sub GetMessageBody {
    my $Self = shift;
    my %Param = @_;
    my $Email = $Self->{OrigEmail}; 
    my @EmailTmp = @$Email;
    my $Parser = new MIME::Parser;
    $Parser->output_to_core("ALL");
    my $Data; 
    my $Strg = join('', @EmailTmp);
    eval { $Data = $Parser->parse_data($Strg) };
    my $PartCounter = 0;

    if ($Data->parts() == 0) {
        if ($Self->{Debug} > 0) {
            print STDERR 'No Mime Email' . "\n";
        }
        my $Body = $Self->GetBody();
        my @BodyTmp = @$Body;
        my $BodyStrg = join('', @BodyTmp);
        return $BodyStrg;
    }
    else {
        if ($Self->{Debug} > 0) {
            print STDERR 'Mime Email' . "\n";
        }
        $Self->GetTheFirstAtm(Part => $Data);
        return $Self->{MailBody};
    }
    return
}
# --
sub GetTheFirstAtm {
    my $Self = shift;
    my %Param = @_;
    my $Part = $Param{Part};
    my $PartCounter = $Param{PartCounter} || 0;
    my $SubPartCounter = $Param{SubPartCounter} || 0;
    if ($Part->parts() > 0) {
	    $PartCounter++;
	    foreach ($Part->parts()) {
		    $SubPartCounter++;
                    if ($Self->{Debug} > 0) {
 		        print STDERR "Sub part($PartCounter/$SubPartCounter)!\n";
                    }
		    $Self->GetTheFirstAtm(Part => $_, PartCounter => $PartCounter);
	    }
    }
    else {
	    my $Filename = $Part->head()->recommended_filename() || "file-$PartCounter.$SubPartCounter";
	    if ($Self->{Debug} > 0) {
		    print STDERR '->GotArticle::Atm->Filename:' . $Filename . "\n";
	    }
        if (!$Self->{ContentType}) {
            $Self->{ContentType} = $Part->head()->mime_type()."; charset=";
            $Self->{ContentType} .= $Part->head()->mime_attr('content-type.charset');
        }
        if (!exists $Self->{MailBody}) {
            $Self->{MailBody} = $Part->bodyhandle()->as_string();
        }
    }
}
# --

1;
