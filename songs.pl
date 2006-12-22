#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use File::Find qw();
use Term::ReadKey qw(ReadMode ReadKey);
use Data::Dumper;

use constant MP3ROOT => '../music';

print "Finding MP3 files ...\n";
my $mp3s = find_all_mp3s();

my %tracks;
while (local $_ = <DATA>) {
	last if $_ eq '__END__';
	if (/^\s*(.+?)\s+-\s+(.+?)\s*$/) {
		$tracks{$1}->{$2} = find_mp3($mp3s,$1,$2) || undef;
	}
}

for my $artist (sort keys %tracks) {
	while (my ($track,$files) = each %{$tracks{$artist}}) {
		my $file = @{$files} > 1 ? select_mp3($artist,$track,
									$tracks{$artist}->{$track})
					: @{$files} ? $files->[0] : '';
		if ($file) {
			print "$artist - $track => '$file'\n";
			my $symlink = "$artist - $track.mp3";
			unlink $symlink if -l $symlink;
			symlink $file, $symlink;
		} else {
			warn sprintf("$artist - $track => %d matches\n",0);
		}
	}
}

exit;

sub select_mp3 {
	my ($artist,$track,$mp3s) = @_;

	$| = 1;
	local $Data::Dumper::Terse = 1;

	my $mp3 = '';
	do {
		print "$artist - $track => ";
		print "\n\t[s] Skip";
		print "\n\t[q] Quit";
		for (my $i = 0; $i < @{$mp3s}; $i++) {
			print "\n\t[$i] $mp3s->[$i]";
		}
		print " ..?";

		ReadMode 4; # Turn off controls keys
		my $key = ReadKey(0);
		ReadMode 0; # Reset tty mode before exiting
		last if defined $key && $key eq 's' || $key eq 'S';
		exit if defined $key && $key eq 'q' || $key eq 'Q';

		if (defined $key && $key =~ /^\s*(\d+)\s*$/) {
			$key = $1;
			$mp3 = $mp3s->[$key] if $key >= 0 && $key < @{$mp3s};
		}
	} until grep($mp3 eq $_, @{$mp3s});


	return $mp3;
}

sub find_all_mp3s {
	local @main::files;
	File::Find::find({wanted => sub {
			my ($dev,$ino,$mode,$nlink,$uid,$gid);
			(($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
			-f _ &&
			/\.(mp3)\z/is &&
			(push @main::files,$File::Find::name);
		}, no_chdir => 1}, MP3ROOT);
	return \@main::files;
}

sub find_mp3 {
	my ($mp3s,$artist,$track) = @_;

	(my $az = $artist) =~ s/^\s*the\s*[^0-9a-z]*//i;
	$az = lc(substr($az,0,1));
	$az = '0' if $az =~ /\d/;

	my $artist_regex = regexise($artist);
	my $track_regex = regexise($track);
	my $track_num = '([0-9]{1,2}[^a-z0-9]*)';
	my $regex = "\\/$az\\/(.*\\/)?$track_num?(${artist_regex}[^\\/]*)?$track_num?${track_regex}[^\\/]*\$";

	return [grep(/$regex/i,@{$mp3s})];
}

sub regexise {
	my $regex = shift;

	$regex =~ s/&/and/gi;
	$regex =~ s/[^a-z0-9]/[^a-z\/]*/gi;
	$regex =~ s/^\s*(the)\b/($1)?/i;
	$regex =~ s/\b(and)\b/(and|&)/i;

	return $regex;
}

__DATA__
4 Non Blondes - What's Up
Ah Ha - Take On Me
Ash - Girl From Mars
B-52's - Loveshack
Backstreet Boys - Everybody
Backstreet Boys - Quit Playing Games (With My Heart)
Bananarama - Venus
Belle & Sebastian - Get Me Away From Here, I'm Dying
Belle & Sebastian - I Fought In A War
Belle & Sebastian - I'm A Cuckoo
Belle & Sebastian - The Boy With An Arab Strap
Blink 182 - All The Small Things
Blink 182 - What's My Age Again?
Blues Traveler - Hook
Blues Traveler - Just Wait
Blues Traveler - Run-Around
Bon Jovi - Lovin' On A Prayer
Bon Jovi - You Give Love A Bad Name
Boys 2 Men - I Swear
Boyzone - Picture Of You
Brian Ferry & Roxy Music - Avalon
Brian Ferry & Roxy Music - Slave To Love
Britney Spears - Oops I Did It Again
Britney Spears - (You Drive Me) Crazy
Carole King - Care Bears Movie Title
Carole King - Forever Young
Cher - Believe
Chris Rea - 
Chris Rea - The Road To Hell (Part II)
Chumbawamba - Tub Thumping
Cindy Lauper - Girls Just Want To Have Fun
Coldplay - Yellow
Cornershop - Brimful Of Asha
Corinne Bailey Rae - Put Your Records On
Corrs - So Young
Counting Crows - Mr Jones
Cyndi Lauper - Time After Time
Daniel Powter - Bad Day
Depeche Mode - Just Can't Get Enough
Dire Straits - Brothers In Arms
Dire Straits - Money For Nothing
Dire Straits - Private Investigations
Dire Straits - Romeo And Juliet
Dire Straits - So Far Away
Dire Straits - Sultans Of Swing
Dire Straits - Telegraph Road
Dire Straits - Tunnel Of Love
Don McLean - American Pie
Duran Duran - Girls On Film
Duran Duran - Rio
Duran Duran - Save A Prayer
Echobelly - King Of The Kerb
Edie Brickell - Good Times
Elton John - 
Elton John - Tiny Dancer
Enya - Orinoco Flow Sail Away
Erasure - Oh L'Amour
Fine Young Cannibals - Good Thing
Fine Young Cannibals - She Drives Me Crazy
Garbage - Stupid Girl
Hanson - Mmmbop
Hazel O'Conner - Will You
Howard Goodall - Red Dwarf End Theme
Howard Shore - Concerning Hobbits
Huey Lewis & The News - Back In Time
Huey Lewis & The News - Hip To Be Square
Huey Lewis & The News - Johnny Be Good
Huey Lewis & The News - The Power Of Love
Iggy Pop - Lust For Life
Jamiroquai - Cosmic Girl
Joan Armatrading - I Wanna Hold You
Joe Cocker - Have A Little Faith In Me
Joe Cocker - Highway Highway
Joe Cocker - Soul Time
Joe Cocker - Summer In The City
Joe Cocker - The Simple Things
John Williams - Star Wars Main Title
John Williams - Superman Main Title
John Williams - The Empire Strikes Back: The Imperial March
Joishua Kadison - Jessie
Kylie Minogue - Can't Get You Out Of My Head
Kylie Minogue - Fever
Kylie Minogue - I Should Be So Lucky
Kylie Minogue - Spinnig Around
Lemonheads - Being Around
Lemonheads - Big Gay Heart
Lemonheads - Down About It
Lemonheads - It's About Time
Lemonheads - You Can Take It With you
Letters To Cleo - I Want You To Want Me
Levellers - What A Beautiful Day
Lighthouse Family - High
Lightning Seeds - Change
Lightning Seeds - Lucky You
Lightning Seeds - Pure
Lily Allen - Smile
Lush - Ladykillers
Lynard Skynyrd - Sweet Home Alabama
Mark Knopfler - Darling Pretty
Mark Knopfler - Golden Heart
Michael Jackson - Bad
Michael Jackson - History
Michael Jackson - Liberian Girl
Michael Jackson - Thriller
Mike Oldfield - Dark Star
Moby - Porcelain
Moby - Run On
Monty Python's Flying Circus - Always Look On The Bright Side
Monty Python's Flying Circus - Galaxy Song
Natalie Imbruglia - Torn
Oasis - She's Electric
Oasis - Wonderwall
Paul Oakenfold - Starry Eyed Surprise
Paul Simon - Under African Skies
Paul Simon - You Can Call Me Al
Phil Collins - Another Day In Paradise
Placebo - Bionic
Placebo - Nancy Boy
Proclaimers - I'm Gonna Be (500 Miles)
Procul Harum - A Whiter Shade Of Pale
Pulp - Common People
Pulp - Disco 2000
Queen - Good Old-Fashioned Lover Boy
Queen - You're My Best Friend
Reef - Place Your Hands
R.E.M. - Loosing My Religion
R.E.M. - Shiny Happy People
Richard Marx - Hazard
Robbie Williams - Angels
Robbie Williams & Kylie Minogue - Kids
Rob Dougan - One And The Same (Coda)
Simply Red - For Your Babies
Simply Red - Something Got Me Started
Simply Red - Stars
Skunk Anansie - Weak
Smash Mouth - All Star
Snow Patrol - Run
Soulyard - Pigeon Street Title
Spice Girls - 
Steps - Tragedy
Supergrass - Pumping On Your Stereo
Take That - Back For Good
Texas - 0.34
Texas - Black Eyed Boy
Texas - Halo
The Cardigans - Lovefool
The Divine Comedy - Everybody Knows (Except You)
The Divine Comedy - National Express
The Feeling - Fill My Little World
The Feeling - Love It When You Call
The Feeling - Never Be Lonely
The Feeling - Sewn
The Jam - A Town Called Malice
The Kooks - She Moves In Her Own Way
The London Session Orchestra - Ball
The Offspring - Original Prankster
The Offspring - Pretty Fly
The Police - De Do Do Do, De Da Da Da
The Pretenders - Don't Get Me Wrong
Tom Jones - Sexbomb
Toploader - Dancing In The Moonlight
Van Morrison - Brown Eyed Girl
Venice - Always
Venice - Mary On My Mind
Venice - One Quiet Day
Venice - Poor You Poor Me Poor Love
Venice - The Man You Think I Am
Venice - The Road To Where You Are
Weezer - Buddy Holly
Wet Wet Wet - Love Is All Around
Wheatus - Teenage Dirtbag
Wigfield - Saturday Night
Will Smith - Men In Black
Wonder Stuff - Size Of A Cow
Yello - The Race
__END__

