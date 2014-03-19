#!/usr/bin/perl
#===============================================================================
#
#         FILE:  lspack.pl
#
#        USAGE:  ./lspack.pl  [-v|-h|-d|-s|-V] pattern
#
#   DESCRIPTION:  Lists installed packages match to the pattern. Currently Works only on Archlinux, Debian
#
#      OPTIONS:  [-v|-h|-d|-s|-V]
# REQUIREMENTS:  perl
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Piotr Rogoża (piecia), rogoza.piotr@gmail.com
#      COMPANY:  dracoRP
#      VERSION:  1.4
#      CREATED:  27.05.2011 17:46:13
# 	  MODIFIED:  06.06.2011 09:18:21
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
require 5.001;

use Carp;
use Getopt::Long;
Getopt::Long::Configure('bundling');
use feature qw(say);

#use encoding 'utf8';
use Linux::Distribution qw(distribution_name);
use English '-no_match_vars';
use Readonly;
use Term::ANSIColor;

my $NAME        = 'lspack';
my $AUTHOR      = 'Piotr Rogoża';
our $VERSION    = 1.4.1;

# Don't modify below variables!!! {{{
#---------------------------------------------------------------------------
# untainted PATH
local $ENV{PATH} = '/usr/bin';

# Startup parameters
my %option;
GetOptions(
    'a'                 => \$option{architecture},
    'v'                 => \$option{version},
    'd'                 => \$option{description},
    's'                 => \$option{search},
    'nocolor|no-color'  => \$option{nocolor},
    'color'             => \$option{color},
    'h'                 => \&help,
    'about'             => \&about,
);

# indexes for array
Readonly my $PROGRAM_VERS => 0;
Readonly my $PROGRAM_DESC => 1;
Readonly my $PROGRAM_ARCH => 2;

# Global read-only variables
Readonly my $SPACE => q{ };
Readonly my $TAB   => qq{\t};

my $distr_command = q{};                        # command for specified distribution

#}}}
#{{{ Functions
sub about {    #{{{
    print q{Search for installed packages that match the pattern}, "\n";
    exit 0;
}    # ----------  end of subroutine about  ----------}}}

sub version { #{{{
    print "$NAME $VERSION\nAuthor $AUTHOR\n";
    exit 0;
} ## --- end of sub version }}}

sub help {    #{{{
    print <<ENDHELP;
Usage: $NAME 'pattern' [-v|-h|-d|-s|-V]
    -a - show a architecture
    -v - show versions of packages
    -d - show descriptions of packages
    -s - search in package's description

    --color     - use color
    --nocolor, --no-color - don't use color
    --about     - about the program
    --version   - about version the program
    -h          - show this help;
ENDHELP
    exit 0;
}    # ----------  end of subroutine usage  ----------}}}

sub max_length_str { #{{{
    my ($array_ref) = @_;
    my $max_length = 0;
    foreach my $string ( @{$array_ref} ){
        if ( length $string > $max_length ){
            $max_length = length $string;
        }
    }
    return $max_length;
} ## --- end of sub max_length_str }}}

sub print_programs {    #{{{

    #===  FUNCTION  ================================================================
    #         NAME:  print_programs
    #   PARAMETERS:  ref to hash
    #  DESCRIPTION:  Prints hash %programs which contains found programs, thei versions and descriptions
    #===============================================================================
    my ($list_programs_ref, $pattern) = @_;
    if ( ref $list_programs_ref ne 'HASH' ) {
        croak q{Error while call sub, expected ref to hash as the first  parameter};
    }
    if (!$pattern){
        croak q{Pattern not specified};
    }

    my $max_length_programname          = 0;
    my $max_length_with_program_desc    = 0;
    my $max_length_version              = 0;
    my $max_length_desc                 = 0;

    foreach my $program ( keys %{$list_programs_ref} ) {
        if ($program =~ m/$pattern/xms) {
            if ( length $program > $max_length_programname ) {
                $max_length_programname = length $program;
            }
        }
        # ustalenie maksymalnej długości programu przy wyszukiwaniu w opisach
        if ( length $program > $max_length_with_program_desc ) {
            $max_length_with_program_desc = length $program;
        }
        # ustalenie maksymalnej długości wersji
        if ( length $list_programs_ref->{$program}->[$PROGRAM_VERS] > $max_length_version ) {
            $max_length_version = length ${$list_programs_ref}{$program}[$PROGRAM_VERS];
        }
        #ustalenie maksymalnej długości opisu
        if ( length $list_programs_ref->{$program}->[$PROGRAM_DESC] > $max_length_desc ) {
            $max_length_desc = length ${$list_programs_ref}{$program}[$PROGRAM_DESC];
        }
    }
    $max_length_programname++;    # dodanie odstępu 1 spacji
    $max_length_with_program_desc++;
    $max_length_version++;

    # print program, version and description
    foreach my $program ( sort keys %{$list_programs_ref} ) {
        print color 'bold white' if $option{color};
        if ($option{search}) {       #search in description
            if ( !$option{version} && !$option{description} ){
                print "$program";
            }
            else {
                printf "%-$max_length_with_program_desc" . 's', "$program";
            }
        }
        else {               #don't search in description, default option
            if ( $program =~ m/$pattern/xms ) {
                if ( !$option{version} &&  !$option{description} ){
                    print "$program";
                }
                else {
                    printf "%-$max_length_programname" . 's', "$program";
                }
            }
            else {
                next
                    ; # jeśli nazwa pakietu nie pasuje do wyszukiwanego wzorca to przejdź do następnego kroku w pętli
            }
        }
        print color 'reset' if $option{color};
        if ( $option{version} ) {
            print color 'green' if $option{color};
            printf "%-$max_length_version" . 's', "$list_programs_ref->{$program}->[$PROGRAM_VERS]";
            print color 'reset' if $option{color};
        }
        if ( $option{description} ) {
#            print " $list_programs_ref->{$program}->[$PROGRAM_DESC]";
            printf "%-$max_length_desc" . 's', "$list_programs_ref->{$program}->[$PROGRAM_DESC]";
        }
        if ( $option{architecture} ){
            print " $list_programs_ref->{$program}->[$PROGRAM_ARCH]";
        }
        print "\n";
    }
    return;
}    # ----------  end of subroutine print_programs  ----------}}}

sub find_package_arch {    #{{{

    #===  FUNCTION  ================================================================
    #         NAME:  archlinux
    #   PARAMETERS:  ref to hash
    #  DESCRIPTION:  store founded programs matched to pattern, their versions and descriptions into hash
    #===============================================================================
    my ($pattern) = @_;
    use strict;
    if ( !$pattern){
        croak q{Pattern not specified},"\n";
    }

    # ref to HASH, program as key, array of version, description, architecture as value
    my $list_programs_ref = {};
    my @data =  ();
    $distr_command = q{/usr/bin/pacman -Qs};
    my $command_info = q{LC_ALL=C /usr/bin/pacman -Qi};

    open my ($fh), q{-|}, qq{$distr_command '} . $pattern . q{'; true}
        or croak q{Cann't fork the program }, $ERRNO;
    @data = <$fh>;
    close $fh
        or croak q{Cann't close fork: },$ERRNO;
    if (@data == 0){
        print {*STDERR} q{No packages found matching }, $pattern, ".\n";
        exit;
    }
    my $count    = 1;
    my $key;

    #rewrite array to hash
    #name of program is the key, the first value is the version number and the second description
    foreach my $line (@data) {
        chomp $line;
        if ( $count % 2 ) {
            my $desc;
            if (($key, $desc )
                = $line =~ m{
                    ^local/
                    ([\S]+)                     # nazwa programu
                    \s
                    ([\S]+)                     # opis
			    }xms
                )
            {
                $list_programs_ref->{$key}->[$PROGRAM_VERS] = $desc;
                # pobieranie informacji o pakiecie tylko jeśli już znamy wersję programu
                if ( $option{architecture} ){
                    my $arch;
                    my $file = qq{/var/lib/pacman/local/$key-$desc/desc};
                    open my ($fh), q{<}, "$file"
                        or croak q{Cann't open the file: $file }, $ERRNO;
                    local $RS = "";
                    my @data = <$fh>;
                    close $fh
                        or croak q{Cann't close the file: $file },$ERRNO;
                    my %info;
                    foreach my $line ( @data ){
                        my @field = split /\n/,$line;
                        $field[0] =~ s{\%}{}g;
                        $info{ $field[0] } = join q{ }, @field[1 .. $#field];
                    }
                    $list_programs_ref->{$key}->[$PROGRAM_ARCH] = $info{ARCH};
                }

            }
        }
        else {
#            chomp $line;
            $line =~ s/^\s+//xms;
            $list_programs_ref->{$key}->[$PROGRAM_DESC] = $line;
        }
        $count++;
    }
    return $list_programs_ref;
}    # ----------  end of subroutine archlinux  ----------}}}

sub find_package_debian {    #{{{

    #===  FUNCTION  ================================================================
    #         NAME:  debian
    #   PARAMETERS:  ref to hash
    #  DESCRIPTION:  store founded programs matched to pattern, their versions and descriptions into hash
    #===============================================================================
    my ($pattern) = @_;
    use strict;
    if ( !$pattern){
        croak q{Pattern not specified},"\n";
    }

    # ref to HASH, program as key, array of version and description as value
    my $list_programs_ref = {};
    my @data =  ();
    $distr_command = q{/usr/bin/dpkg -l};
    $pattern =~ s{(.*)}{*$1*}xms;

    open my ($fh), q{-|}, qq{$distr_command '} . $pattern . q{'; true}
        or croak q{Cann't fork the program: }, $ERRNO;
    @data = <$fh>;
    close $fh
        or croak q{Cann't close fork: }, $ERRNO;

    if (@data == 0){
#        print {*STDERR} q{Nothing found}, "\n";
        exit;
    }

    #	my %programs;
    foreach my $line (@data) {
        chomp $line;
        my ($version, $desc, $package);
        if ( ($package, $version, $desc) = $line =~ m{
                ^[ih]i                          # installed|hold
				\s+
				(\S+)                           # package
				\s+
				(\S+)                           # version
				\s+
				(.*$)                           # description
			}xms
            )
        {
            $list_programs_ref->{$package}->[$PROGRAM_VERS] = $version;
            $list_programs_ref->{$package}->[$PROGRAM_DESC] = $desc;
        }
    }
    return $list_programs_ref;
}    # ----------  end of subroutine debian  ----------}}}

#}}}
#---------------------------------------------------------------------------
#  Main program
#---------------------------------------------------------------------------
my ($pattern, $rawpattern);
$rawpattern = $ARGV[0];
if ($rawpattern){
    ($pattern) = $rawpattern =~ m{^[\w\d._^\$-]+}gxms;
}
if ( not defined $pattern ) {
    print {*STDERR} "Pattern is not defined, try $NAME -h";
    exit 0;
}
my $distribution_name = distribution_name;
if (!$distribution_name){
    print q{I don't know this system}, "\n";
    exit;
}
my $distribution_sub =  'find_package_' . $distribution_name;
my $list_programs = {};
if ( exists &{$distribution_sub} ){
    {
        no strict 'refs';
        $list_programs = &{$distribution_sub}($pattern);
    }
}
else {
    print q{I'm sorry but this system isn't supported}, "\n";
    exit;
}
print_programs($list_programs, $pattern);

__END__

=pod

=encoding utf8

=head1 NAME

lspack - szukaj pakietu pasującego do wzorca wśród zainstalowanych w systemie

=head1 USAGE

lspack wzorzec [opcje]

=head1 OPTIONS

I<-v> pokaż wersję znalezionych pakietów

I<-d> pokaż opisy znalezionych pakietów

I<-s> szukaj także w opisach 

I<-h> pokaż pomoc

I<-V> o programie 

=head1 DESCRIPTION

Program wyszukuje pakiety pasujące do wzorca wśród zainstalowanych w systemie. Wyszukiwać można po nazwie lub opisie. Skrypt ten jest nakładką na domyślne programy zainstalowane w systemie.
Domyślnie program wyszukuje pakiety pasujące tylko do nazwy i wyświetla tylko ich nazwy. Można to zmienić opcją I<-s> wówczas będzie również dopasowywał do opisu. Opcja I<-d> wyświetla dodatkowo opis pakietu a I<-v> wersję.
Parametry można łączyć.
Opcja I<-h> wyświetla krótką pomoc a I<-V> krótką informację o wersji skryptu i autorze.

=head1 AUTHOR

Piotr Rogoża rogoza.piotr@gmail.com

=head1 LICENSE AND COPYRIGHT

Program  jest  dystrybuowany  na  zasadach  licencji  GNU  General  Public License.

=cut
