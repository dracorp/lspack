#!/usr/bin/perl
#===============================================================================
#       AUTHOR: Piotr Rogoza piotr dot r dot public at gmail dot com
#         DATE: $Date$
#     REVISION: $Revision$
#           ID: $Id$
#===============================================================================

use strict;
use warnings;

use Carp;
use Getopt::Long;
Getopt::Long::Configure('bundling');

use English '-no_match_vars';
use Readonly;
use Term::ANSIColor;

my $NAME        = 'lspack.pl';
our $VERSION    = 1.4.2;

# Startup parameters
my %option;
GetOptions(
    'a|print-arch'      => \$option{architecture},
    'v|print-version'   => \$option{version},
    'd|print-desc'      => \$option{description},
    's|search'          => \$option{search_in_desc},
    'c|color'           => \$option{color},
    'h|help'            => \$option{help},
    'o|os=s'            => \$option{os},
) or die "Error in command line arguments. Try \`$NAME --help\`";

if( !$option{os} ){
    require Linux::Distribution;
    Linux::Distribution->import( qw(distribution_name) );
}
sub usage { #{{{
    system "pod2usage $PROGRAM_NAME";
} # end of sub usage }}}
sub help { #{{{
    system "pod2text $PROGRAM_NAME";
} # end of sub help }}}
if ( $option{help} ){
    help;
    exit;
}
unless (@ARGV){
    usage;
    exit;
}
# indexes for array
Readonly my $PROGRAM_VERS => 0;
Readonly my $PROGRAM_DESC => 1;
Readonly my $PROGRAM_ARCH => 2;

# Global read-only variables
Readonly my $SPACE => q{ };
Readonly my $TAB   => qq{\t};

sub print_programs { #{{{
#===  FUNCTION  ================================================================
#         NAME: print_programs
#      PURPOSE:
#   PARAMETERS: ref to HASH, pattern
#      RETURNS: ????
#  DESCRIPTION: Prints hash %programs which contains found programs, their versions and descriptions
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: n/a
#===============================================================================
    my ( $list_programs_ref, $pattern ) = @_;
    if ( ref $list_programs_ref ne 'HASH' ) {
        croak q{Error while call sub, expected ref to hash as the first parameter};
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
        if ($option{search_in_desc}) {       #search in description
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
} # end of sub print_programs }}}
sub find_package_arch { #{{{
#===  FUNCTION  ================================================================
#         NAME: find_package_arch
#      PURPOSE:
#   PARAMETERS: pattern to search
#      RETURNS: ref to hash
#  DESCRIPTION: store found programs matched to pattern, their versions and descriptions into hash
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: n/a
#===============================================================================
    my ( $pattern ) = @_;
    if ( !$pattern ){
        croak q{Pattern not specified},"\n";
    }

    # ref to HASH, program as key, array of version, description, architecture as value
    my $list_programs_ref = {};
    my @data =  ();
    my $distr_command = q{/usr/bin/pacman -Qs};
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
                    ([\S]+)                     # program name
                    \s
                    ([\S]+)                     # description
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
} # end of sub find_package_arch }}}
sub find_package_debian { #{{{
#===  FUNCTION  ================================================================
#         NAME: find_package_debian
#      PURPOSE:
#   PARAMETERS: pattern
#      RETURNS: ref to hash
#  DESCRIPTION: ????
#  DESCRIPTION: store found programs matched to pattern, their versions and descriptions into hash
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: n/a
#===============================================================================
    my ( $pattern ) = @_;
    if ( !$pattern){
        croak q{Pattern not specified},"\n";
    }

    # ref to HASH, program as key, array of version and description as value
    my $list_programs_ref = {};
    my @data =  ();
    my $distr_command = q{/usr/bin/dpkg -l};
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

    foreach my $line (@data) {
        chomp $line;
        my ($version, $desc, $package);
        if ( ($package, $version, $desc) = $line =~ m{
                ^[ih]i                          # installed|hold
				\s+
				(\S+)           # package
				\s+
				(\S+)           # version
				\s+
				(.*$)           # description
			}xms
            )
        {
            $list_programs_ref->{$package}->[$PROGRAM_VERS] = $version;
            $list_programs_ref->{$package}->[$PROGRAM_DESC] = $desc;
        }
    }
    return $list_programs_ref;
} # end of sub find_package_debian  }}}
sub find_package_linuxmint { #{{{
#===  FUNCTION  ================================================================
#         NAME: find_package_linuxmint
#      PURPOSE:
#   PARAMETERS: pattern
#      RETURNS: ref to hash
#  DESCRIPTION: ????
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: find_package_debian
#===============================================================================
    &find_package_debian;
} # end of sub find_package_linuxmint }}}
#
#  Main program
#
my ($pattern, $rawpattern);
$rawpattern = $ARGV[0];
if ($rawpattern){
    ($pattern) = $rawpattern =~ m{^[\w\d._^\$-]+}gxms;
}
if ( not defined $pattern ) {
    print {*STDERR} "Pattern is not defined, try $NAME -h";
    exit 0;
}

# Take distribution name from command line
my $distribution_name;
# sub from Linux::Distribution
my $distribution_sub = \&{'distribution_name'};
if ( $option{os} ){
    $distribution_name = lc $option{os};
}
# or find
elsif ( exists &$distribution_sub ){
    $distribution_name = &$distribution_sub;
}

if (!$distribution_name){
    print q{I don't know this system}, "\n";
    exit;
}
$distribution_sub =  'find_package_' . $distribution_name;
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

lspack - search in installed packages which match to pattern

=head1 USAGE

lspack.pl [pattern] [-vdshV]

=head1 OPTIONS

=over 4

=item I<-v, --print-version>
Show version of package

=item I<-d, --print-desc>
Show description of package

=item I<-a, --print-arch>
Show architecture of package

=item I<-s, --search>
Search in description too

=item I<-o name, --os name>
Name of Operataing System or detect by Linux::Distribution module

=item I<-h, --help>
Show help

=item I<-c, --color>
Print in colors

=back

=head1 DESCRIPTION

Program search a program among all installed packages which match to pattern. Pattern may be compared with name or description of packages.

=head1 AUTHOR

Piotr Rogoza E<lt>piotr.r.public@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

as-is

=cut
