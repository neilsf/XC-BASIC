#!/usr/bin/perl

$warnings = 0;
$errors = 0;

#
# Welcome message
#

print "**** XC=BASIC INSTALLER ****\n";
$version = `cat ./VERSION`;
$HOME = `echo \$HOME`; chomp $HOME;
print "This script installs XC=BASIC $version on your system.\n";
print "---------------\n";
print "[1] Install into the current user's home ($HOME/xcbasic64)\n";
print "[2] Install system-wide (/opt/xcbasic64) - requires root access\n";
print "[3] Specify the installation path yourself\n"; 
print "[4] Exit without installing\n";
do {
    print "Please choose an option: ";
    $choice = <>;
    chomp $choice;
    $valid = 1;
        if($choice eq "1") {
            $target = "$HOME";
        }
        elsif($choice eq "2") {
            $target = "/opt";
        }
        elsif($choice eq "3") {
            print "Enter absolute path, for example '/home/lessie/programs': ";
            $target = <>;
            chomp $target;
            $target = $1 if($target=~/(.*)\/$/);
        }
        elsif($choice eq "4") {
            print "You make me sad. So be it.\n";
            exit 0;
        }
        else {
            $valid = 0; 
        }
}
until($valid eq 1);

#
# Check for previous installations
#

$prev_bin = `whereis xcbasic64`;
chomp $prev_bin;
$prev_bin =~ s/xcbasic64://ig;
if ($prev_bin ne "") {
  print "** WARNING ** It seems like another installation already exists in$prev_bin. You may want to manually remove it to avoid confusions.\n";
  $warnings++;
}

if(not -d $target) {
    print "ERROR: the directory $target does not exist.\n";
    exit 1;
}

if(-d "$target/xcbasic64") {
    print "ERROR: the directory $target/xcbasic64 already exist. Please remove or choose another directory.\n";
    exit 1;
}

if(not -w $target) {
    print "ERROR: the directory $target is not writeable. Please run again with appropriate permissions.\n";
    exit 1;
}

`mkdir $target/xcbasic64`;
`cp -r ./* $target/xcbasic64/`;
`rm $target/xcbasic64/install.pl`;
`chmod +x $target/xcbasic64/xcbasic64`;
`chmod +x $target/xcbasic64/dasm/dasm.Linux.x86`;
if($choice eq "1" or $choice eq "3") {
    `PATH="${PATH:+"$PATH:"}$target/xcbasic64"`;
    print "NOTE: the directory $target/xcbasic64 has been added to PATH. You may want to make this permanent by editing ~/.bashrc\n";
}
else {
    $cmd = `ln -sf $target/xcbasic64/xcbasic64 /usr/local/bin/xcbasic64`;
    if($cmd ne "") {
        $warnings++;
    }
}

#
# End report
#

if($warnings > 0) {
  print "Installation succesful with warnings. Please read the above output for details.\n";
  exit 0;
}

print "Installation successful. Type 'xcbasic64 -h' for help.\n";
exit 0;
