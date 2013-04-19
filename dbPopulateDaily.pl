#! /usr/bin/perl
 
# This script is made freely available for non-commerical use by Mike Fast
# September 2011
# http://fastballs.wordpress.com/
# Attribution is appreciated but not required.
#
# This script uses portions of Joseph Adler's code from hack_28_parser.pl
# as published by O'Reilly Media in the book Baseball Hacks, copyright 2006
# ISBN 0-596-00942-9, available at http://www.oreilly.com/catalog/baseballhks/
# used under the terms set forth in the book on Page xvi, as follows:
# "In general, you may use the code in this book in your programs and documentation.
# You do not need to contact us for permission unless you're reproducing a significant
# portion of the code.  For example, writing a program that uses several chunks of code
# from this book does not require permission."
#
# Some code portions are by Joseph Adler
# and the rest of the code is largely or completely by Mike Fast
 
use Switch;
 
# MySQL database connection statement
use DBI;
$dbh = DBI->connect("DBI:mysql:database=pitchfx2;host=localhost", 'root', 'passPASS!!') 
or die $DBI::errstr;
 
# Define XML objects
use XML::Simple;
$boxparser= new XML::Simple(ForceArray => 1,
                KeepRoot => 1,
                KeyAttr => 'boxscore');
$inningparser= new XML::Simple(ForceArray => 1,
                   KeepRoot => 1,
                   KeyAttr => 'inning');
$hitsparser= new XML::Simple(ForceArray => 1,
                 KeepRoot => 1,
                 KeyAttr => 'hitchart');
$playerparser= new XML::Simple(ForceArray => 1,
                 KeepRoot => 1,
                 KeyAttr => 'game');
$gameparser= new XML::Simple(ForceArray => 1,
                   KeepRoot => 1,
                   KeyAttr => 'game');
 
sub extract_date($) {
    my($in) = @_;
    my $gmyr = substr($in,0,4);
    my $gmmn = substr($in,5,2);
    my $gmdy = substr($in,8,2);
    my $gamedate = '\'' . $gmyr . '-' . $gmmn . '-' . $gmdy . '\'';
    return $gamedate;
}
 
sub extract_info($) {
    # This subroutine parses game information from the boxscore.xml file
    my ($box) = @_;
    my $home = $box->{boxscore}->[0]->{home_team_code};
    my $away = $box->{boxscore}->[0]->{away_team_code};
    my $gameid = "'" . $box->{boxscore}->[0]->{game_id} . "'";
    my $gamedate = extract_date($box->{boxscore}->[0]->{game_id});
    my $gameinfo = "'" . $box->{boxscore}->[0]->{game_info}->[0] . "'";
    my $away_team_runs = $box->{boxscore}->[0]->{linescore}->[0]->{away_team_runs};
    my $home_team_runs = $box->{boxscore}->[0]->{linescore}->[0]->{home_team_runs};
    return ($home, $away, $gameid, $gamedate, $gameinfo, $away_team_runs, $home_team_runs);
}

# gwyn - to get the gametype
sub extract_game_info($) {
   # extracts the game type (S=Spring Training)
   my ($game) = @_;
   my $gametype =  "'" . $game->{game}->[0]->{type} . "'";
   return ($gametype);
}
 
# Get the list of months from the base year directory
my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time() - 24*60*60);
$year=$year+1900;
++$mon;
 $mday = (length($mday) == 1) ? "0$mday" : $mday;
 $mon = (length($mon) == 1) ? "0$mon" : $mon;
$basedir="/opt/data/pitchfx/year_".$year;
$mondir="month_".$mon;
$daydir="day_".$mday;

print "$basedir-$mondir - $daydir\n";
#opendir MDIR, $basedir;
#@monthdirs = readdir MDIR;
#print "the months in $basedir:";
#print @monthdirs;
#closedir MDIR;
 
#foreach $mondir (@monthdirs) {
    if ($mondir =~ /month/) {
    opendir DDIR, "$basedir/$mondir";
    my @daydirs = readdir DDIR;
    closedir DDIR;
    #foreach $daydir (@daydirs) {
        if ($daydir =~ /day/) {
	print "opening $basedir/$mondir/$daydir\n";
        opendir GDIR, "$basedir/$mondir/$daydir";
        my @gamedirs = readdir GDIR;
        closedir GDIR;
        foreach $gamedir (@gamedirs) {
            if ($gamedir =~ /gid_/ and 
            (-e "$basedir/$mondir/$daydir/$gamedir/inning/inning_hit.xml")) {
            $fulldir = "$basedir/$mondir/$daydir/$gamedir";
            $box = $boxparser->XMLin(
                "$fulldir/boxscore.xml");
            $game = $gameparser->XMLin(
		"$fulldir/game.xml");
            my ($home, $away, $gameid, $gamedate, $gameinfo, $away_team_runs, $home_team_runs) = extract_info($box);
           # gwyn
	   my ($gametype) = extract_game_info($game);
            # Game number = 1, unless the 2nd game of a doubleheader when game number = 2
            $game_number = substr($gameid, -2, 1);
            if ($gameinfo =~ /<br\/><b>Weather<\/b>: (\d+) degrees,.*<br\/><b>Wind<\/b>: (\d+) mph, ([\w\s]+).<br\/>/) {
                #gwyn
		#this temperature assignment gets a NULL sometimes so give it a zero instead
		if ($1 eq "") {
		$temperature = 0;
		} else {
		$temperature = $1;
		}

                $wind = $2;
                $wind_dir = "'" . $3 . "'";
            } else {
                # Domed stadiums may list wind speed as "Indoors"
                $gameinfo =~ /<br\/><b>Weather<\/b>: (\d+) degrees,.*<br\/><b>Wind<\/b>: Indoors.<br\/>/;
		# gwyn - as above
		if ($1 eq "") {
                $temperature = 0;
                } else {
                $temperature = $1;
                }
                $wind = 0;
                $wind_dir = "'Indoors'";
		print "temp=$temperature\n";
            }
            $home = $dbh->quote($home);
            $away = $dbh->quote($away);
 
            foreach $batter (@{$box->{boxscore}->[0]->{batting}->[0]->{batter}}) {
                $id = $batter->{id};
                $pos = $batter->{pos};
                @pos_array = split(/-/, $pos);
                $pos = $pos_array[0];    
                $bo = $batter->{bo};
                if ($bo==(int($bo/100)*100) && !("P" eq $pos) && !("DH" eq $pos)) {
#                print "id: $id, pos: $pos, bo:$bo.\n";
                switch($pos) {
                    case "C"  {$hdef2 = $id;}
                    case "1B" {$hdef3 = $id;}
                    case "2B" {$hdef4 = $id;}
                    case "3B" {$hdef5 = $id;}
                    case "SS" {$hdef6 = $id;}
                    case "LF" {$hdef7 = $id;}
                    case "CF" {$hdef8 = $id;}
                    case "RF" {$hdef9 = $id;}
                    open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                    print FIELDRECORD "WARNING: game $select_game_id - Found $id at non P/DH batting order $pos $bo without defensive position.\n";
                    close FIELDRECORD;
                }
                } else {
#                print "not a starter $bo.\n";
                }
            }
 
            foreach $batter (@{$box->{boxscore}->[0]->{batting}->[1]->{batter}}) {
                $id = $batter->{id};
                $pos = $batter->{pos};
                @pos_array = split(/-/, $pos);
                $pos = $pos_array[0];    
                $bo = $batter->{bo};
                if ($bo==(int($bo/100)*100) && !("P" eq $pos) && !("DH" eq $pos)) {
#                print "id: $id, pos: $pos, bo:$bo.\n";
                switch($pos) {
                    case "C"  {$adef2 = $id;}
                    case "1B" {$adef3 = $id;}
                    case "2B" {$adef4 = $id;}
                    case "3B" {$adef5 = $id;}
                    case "SS" {$adef6 = $id;}
                    case "LF" {$adef7 = $id;}
                    case "CF" {$adef8 = $id;}
                    case "RF" {$adef9 = $id;}
                    open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                    print FIELDRECORD "WARNING: game $select_game_id - Found $id at non P/DH batting order $pos $bo without defensive position.\n";
                    close FIELDRECORD;
                }
                } else {
#                print "not a starter $bo.\n";
                }
            }
 
#print "Home fielders: C $hdef2, 1B $hdef3, 2B $hdef4, 3B $hdef5, SS $hdef6, LF $hdef7, CF $hdef8, RF $hdef9.\n";
#print "Away fielders: C $adef2, 1B $adef3, 2B $adef4, 3B $adef5, SS $adef6, LF $adef7, CF $adef8, RF $adef9.\n";
 
 
            $game = $gameparser->XMLin(
                "$fulldir/game.xml");
            $game_time = $game->{game}->[0]->{local_game_time};
            $game_time = $dbh->quote($game_time);
 
            # Input the game info into the database
            $no_duplicate_query = 'SELECT game_id FROM games WHERE (date = ' . $gamedate
            . ' AND home = ' . $home . ' AND away = ' . $away . ' AND game = ' . $game_number . ')';
            $sth= $dbh->prepare($no_duplicate_query) or die $DBI::errstr;
            $sth->execute();
            my $numRows = $sth->rows;
            $sth->finish();
            if ($numRows) {
                # don't insert duplicate game entry into games table
            } else {
		#gwyn changed to add gametype
                $game_query = 'INSERT INTO games (date, home, away, game, wind, wind_dir, temp, type, runs_home, runs_away , local_time) VALUES (' . $gamedate . ', '. $home . ', ' . $away
                . ', ' . $game_number . ', ' . $wind . ', ' . $wind_dir . ', ' . $temperature . ', '
                . $gametype . ', ' . $home_team_runs . ', ' . $away_team_runs . ', ' . $game_time . ')';
		#print "$game_query\n";
                $sth= $dbh->prepare($game_query) or die $DBI::errstr;
                $sth->execute();
                $sth->finish();
#print "\n$game_query\n";
            }
 
            # Check for new players in the players.xml file and input them into the database    
            $players = $playerparser->XMLin(
                "$fulldir/players.xml");
            foreach $team (@{$players->{game}->[0]->{team}}) {
                foreach $player (@{$team->{player}}) {
                $id = $player->{id};
                $first = $dbh->quote($player->{first});
                $last = $dbh->quote($player->{last});
                $throws = $dbh->quote($player->{rl});
                $no_duplicate_query = 'SELECT eliasid FROM players WHERE eliasid = ' . $id;
                $sth= $dbh->prepare($no_duplicate_query) or die $DBI::errstr;
                $sth->execute();
                my $numRows = $sth->rows;
                $sth->finish();
                if ($numRows) {
                    # don't insert duplicate player entry into players table
                } else {
                    $player_query = 'INSERT INTO players (eliasid, first, last, throws) '
                    . 'VALUES (' . $id . ', '. $first . ', ' . $last . ', ' . $throws . ')';
                    $sth= $dbh->prepare($player_query) or die $DBI::errstr;
                    $sth->execute();
                    $sth->finish();
                }
                }
            }
 
            # Check if game info has been input before inputting umpire, at bat, and pitch info
            $game_id_query = 'SELECT game_id FROM games WHERE (date = ' . $gamedate
            . ' AND home = ' . $home . ' AND away = ' . $away . ' AND game = ' . $game_number . ')';
            $sth= $dbh->prepare($game_id_query) or die $DBI::errstr;
            $sth->execute();
            my $numRows = $sth->rows;
            if (1==$numRows) {
                $select_game_id = $sth->fetchrow_array();
                print "\nParsing game number $select_game_id ($gamedir).\n";
            } else {
                die "duplicate game entry $select_game_id in database or game not found.\n";
            }
            $sth->finish();
 
            # Find the home plate umpire and input him into the database    
            foreach $umpire (@{$players->{game}->[0]->{umpires}->[0]->{umpire}}) {
                $umpire_name = $umpire->{name};
                ($umpire_first, $umpire_last) = split(/\s/, $umpire_name);
                $umpire_first = $dbh->quote($umpire_first);
                $umpire_last = $dbh->quote($umpire_last);
                $position = $umpire->{position};
                if ('home' eq $position) {
                $no_duplicate_query = 'SELECT ump_id FROM umpires WHERE first = ' . $umpire_first
                . ' AND last = ' . $umpire_last;
                $sth= $dbh->prepare($no_duplicate_query) or die $DBI::errstr;
                $sth->execute();
                my $numRows = $sth->rows;
                if ($numRows) {
                    # don't insert duplicate umpire entry into umpires table
                    # get umpire id
                    $select_ump_id = $sth->fetchrow_array();
                    $sth->finish();
                } else {
                    $sth->finish();
                    $umpire_query = 'INSERT INTO umpires (first, last) '
                    . 'VALUES (' . $umpire_first . ', ' . $umpire_last . ')';
                    $sth= $dbh->prepare($umpire_query) or die $DBI::errstr;
                    $sth->execute();
                    $sth->finish();
                    # get umpire id
                    $umpire_id_query = 'SELECT ump_id FROM umpires WHERE first = ' . $umpire_first
                    . ' AND last = ' . $umpire_last;
                    $sth= $dbh->prepare($umpire_id_query) or die $DBI::errstr;
                    $sth->execute();
                    my $numRows = $sth->rows;
                    if (1==$numRows) {
                    $select_ump_id = $sth->fetchrow_array();
                    $sth->finish();
                    } else {
                    die "numrows=$numRows, duplicate umpire entry $umpire_first $umpire_last in database or umpire not found.\n";
                    }
                }
                } else {
                # ignore base umpires
                }
            }
            # update game record with umpire id
            $umpire_update_query = 'UPDATE games SET umpire = ' . $select_ump_id. ' WHERE game_id = ' . $select_game_id;
            $sth= $dbh->prepare($umpire_update_query) or die $DBI::errstr;
            $sth->execute();
 
            # Parse the at bats and pitches from each inning_?.xml file
            opendir IDIR, "$fulldir/inning";
            my @inningfiles = readdir IDIR;
            closedir IDIR;
            my @innings = ();
            foreach $inningfn (@inningfiles) {
                if ($inningfn =~ /inning_(\d+)\.xml/) {
                $inning_num = $1;
 
                # Pre-process the inning_?.xml file
                $inning = $inningparser->XMLin(
                    "$fulldir/inning/$inningfn");
                @innings[$inning_num] = $inning;
 
                foreach $action (@{$inning->{inning}->[0]->{top}->[0]->{action}}) {
                    $act_event = $action->{event};
                    $act_des = $action->{des};
                    $act_player = $action->{player};
                    $substitution_flag = 0;
                    if ("Defensive Sub" eq $act_event) {
                    $substitution_flag = 1;
                    if ($act_des =~ / playing ([\w\s]+)./) {
                        $new_position = $1;
                    } elsif ($act_des =~ / as the ([\w\s]+)./) {
                        $new_position = $1;
                    } else {
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Could not identify new position for $act_player, inn $inning_num.\n";
                        close FIELDRECORD;
                    }
#                    print "Defensive player change at $new_position in inning $inning_num.\n";
                    } elsif ("Defensive Switch" eq $act_event) {
                    $substitution_flag = 1;
                    if ($act_des =~ / as the ([\w\s]+)./) {
                        $new_position = $1;
                    } elsif ($act_des =~ / to ([\w\s]+) for /) {
                        $new_position = $1;
                    } else {
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Could not identify new position for $act_player, inn $inning_num.\n";
                        close FIELDRECORD;
                    }
#                    print "Defensive player change at $new_position in inning $inning_num.\n";
                    }
                    if ($substitution_flag) {
                    $new_position =~ s/ baseman/ base/;
                    $new_position =~ s/ fielder/ field/;
                    switch($new_position) {
                        case "catcher"  {$hdef2 = $act_player;}
                        case "first base"  {$hdef3 = $act_player;}
                        case "second base"  {$hdef4 = $act_player;}
                        case "third base"  {$hdef5 = $act_player;}
                        case "shortstop"  {$hdef6 = $act_player;}
                        case "left field"  {$hdef7 = $act_player;}
                        case "center field"  {$hdef8 = $act_player;}
                        case "right field"  {$hdef9 = $act_player;}
                        case "designated hitter"  {}
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Found $act_player in a defensive substitution without defensive position ($new_position).\n";
                        close FIELDRECORD;
                    }
#print "Home fielders: C $hdef2, 1B $hdef3, 2B $hdef4, 3B $hdef5, SS $hdef6, LF $hdef7, CF $hdef8, RF $hdef9.\n";
                    }
                }
 
                # Parse the at-bat and pitch data for the top and bottom halves of each inning
                foreach $atbat (@{$inning->{inning}->[0]->{top}->[0]->{atbat}}) {
                    $half = 1;
                    parse_at_bats_and_pitches($atbat, $dbh, $select_game_id, $inning_num, $half, $hdef2, $hdef3, $hdef4, $hdef5, $hdef6, $hdef7, $hdef8, $hdef9);
                }
 
                foreach $action (@{$inning->{inning}->[0]->{bottom}->[0]->{action}}) {
                    $act_event = $action->{event};
                    $act_des = $action->{des};
                    $act_player = $action->{player};
                    $substitution_flag = 0;
                    if ("Defensive Sub" eq $act_event) {
                    $substitution_flag = 1;
                    if ($act_des =~ / playing ([\w\s]+)./) {
                        $new_position = $1;
                    } elsif ($act_des =~ / as the ([\w\s]+)./) {
                        $new_position = $1;
                    } else {
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Could not identify new position for $act_player, inn $inning_num.\n";
                        close FIELDRECORD;
                    }
#                    print "Defensive player change at $new_position in inning $inning_num.\n";
                    } elsif ("Defensive Switch" eq $act_event) {
                    $substitution_flag = 1;
                    if ($act_des =~ / as the ([\w\s]+)./) {
                        $new_position = $1;
                    } elsif ($act_des =~ / to ([\w\s]+) for /) {
                        $new_position = $1;
                    } else {
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Could not identify new position for $act_player, inn $inning_num.\n";
                        close FIELDRECORD;
                    }
#                    print "Defensive player change at $new_position in inning $inning_num.\n";
                    }
                    if ($substitution_flag) {
                    $new_position =~ s/ baseman/ base/;
                    $new_position =~ s/ fielder/ field/;
                    switch($new_position) {
                        case "catcher"  {$adef2 = $act_player;}
                        case "first base"  {$adef3 = $act_player;}
                        case "second base"  {$adef4 = $act_player;}
                        case "third base"  {$adef5 = $act_player;}
                        case "shortstop"  {$adef6 = $act_player;}
                        case "left field"  {$adef7 = $act_player;}
                        case "center field"  {$adef8 = $act_player;}
                        case "right field"  {$adef9 = $act_player;}
                        case "designated hitter"  {}
                        open (FIELDRECORD, ">> fielder_record.txt") || die "sorry, system can't open fieldrecord";
                        print FIELDRECORD "WARNING: game $select_game_id - Found $act_player in a defensive substitution without defensive position ($new_position).\n";
                        close FIELDRECORD;
                    }
#print "Away fielders: C $adef2, 1B $adef3, 2B $adef4, 3B $adef5, SS $adef6, LF $adef7, CF $adef8, RF $adef9.\n";
                    }
                }
 
                foreach $atbat (@{$inning->{inning}->[0]->{bottom}->[0]->{atbat}}) {
                    $half = 2;
                    parse_at_bats_and_pitches($atbat, $dbh, $select_game_id, $inning_num, $half, $adef2, $adef3, $adef4, $adef5, $adef6, $adef7, $adef8, $adef9);
                }
                }
            }
 
            $hits = $hitsparser->XMLin(
                "$fulldir/inning/inning_hit.xml");
            # When a ball in play and an error are recorded on the same play, 
            # the error may be the first play listed in inning_hit.xml or the second play.
            # Currently the first play is recorded in the database, and 
            # the second play is not recorded in the database but is saved to a text file
            # for later manual review.  Some cases of batting around in one inning may
            # also be saved to the text file.
            # This section of code could be improved by automating the manual review process.
            open (HITRECORD, ">> hit_record.txt") || die "sorry, system can't open hitrecord";
            foreach $hip (@{$hits->{hitchart}->[0]->{hip}}) {
                $hit_des = $hip->{des};
                $hit_x = $hip->{x};
                $hit_y = $hip->{y};
                $hit_type = $dbh->quote($hip->{type});
                $hit_batter = $hip->{batter};
                $hit_pitcher = $hip->{pitcher};
                $hit_inning = $hip->{inning};
                # find the at bat that matches the ball in play
                $find_ab_id_query = 'SELECT ab_id, hit_x, event FROM atbats WHERE (game_id = ' . $select_game_id
                . ' AND inning = ' . $hit_inning . ' AND batter = ' . $hit_batter . ' AND pitcher = '
                . $hit_pitcher . ')';
                $sth= $dbh->prepare($find_ab_id_query) or die $DBI::errstr;
                $sth->execute();
                my $numRows = $sth->rows;
                if (1==$numRows) {
                # for one matching at bat, check if hit data already entered in database
                ($select_ab_id, $select_hit_x, $select_event) = $sth->fetchrow_array();
                # update atbats table with hit info for each matching at_bat
                if (0<$select_hit_x) {
                    # already entered into database
                    print HITRECORD "game $select_game_id:1.1 This hit $hit_batter - $hit_pitcher - $hit_inning already recorded in database.\n";
                } else {
                    update_hit_info($hit_x, $hit_y, $hit_type, $select_ab_id);
                }
                }
                elsif (2==$numRows) {
                # if the batter has batted twice in the inning against the same pitcher
                ($select_ab_id, $select_hit_x, $select_event) = $sth->fetchrow_array();
                # if the first ball in play is already recorded, don't update it
                if ($hit_x==$select_hit_x && $select_event eq $hit_des) {
                    print HITRECORD "game $select_game_id:2.1 This hit $hit_batter - $hit_pitcher - $hit_inning already recorded in database.\n";
                } elsif (0<$select_hit_x) {
                    # select the info for the second ball in play from the database
                    ($select_ab_id, $select_hit_x, $select_event) = $sth->fetchrow_array();
                    # if the second ball in play is already recorded, don't update it
                    if ($hit_x==$select_hit_x && $select_event eq $hit_des) {
                    print HITRECORD "game $select_game_id:2.2 This hit $hit_batter - $hit_pitcher - $hit_inning already recorded in database.\n";
                    } else {
                    # if the second ball in play hasn't been recorded, update the db
                    update_hit_info($hit_x, $hit_y, $hit_type, $select_ab_id);
                    }
                } else {
                    # if the first ball in play hasn't been recorded, update the db
                    update_hit_info($hit_x, $hit_y, $hit_type, $select_ab_id);
                }
                } else {
                print "numrows=$numRows, no matching at bat found for hit $hit_batter - $hit_pitcher - $hit_inning.\n";
                }
            }
            close HITRECORD;
 
# This is a debug section if you want to look at contents of the XML file
# in an easier-to-read format 
#            use Data::Dumper;
#            open (OUTFILE, "> debug_parser_innings.txt") || die "sorry, system can't open outfile";
#            print OUTFILE Dumper($hits); 
#            print OUTFILE Dumper($players);
#            print OUTFILE Dumper($names);
#            print OUTFILE Dumper($box);
#            print OUTFILE Dumper(@innings);
#            close OUTFILE;
            }
        }
        }
    #}
    }
#}
 
sub update_hit_info($hit_x, $hit_y, $hit_type, $select_ab_id) {
    # update at bat record with hit info
    $hit_query = 'UPDATE atbats SET hit_x = ' . $hit_x . ', hit_y = ' . $hit_y
    . ', hit_type = ' . $hit_type . ' WHERE ab_id = ' . $select_ab_id;
    $sth= $dbh->prepare($hit_query) or die $DBI::errstr;
    $sth->execute();
    $sth->finish();
}
 
sub parse_at_bats_and_pitches() {
    my $atbat = shift;
    my $dbh = shift;
    my $select_game_id = shift;
    my $inning_num = shift;
    my $half = shift;
    my $def2 = shift;
    my $def3 = shift;
    my $def4 = shift;
    my $def5 = shift;
    my $def6 = shift;
    my $def7 = shift;
    my $def8 = shift;
    my $def9 = shift;
 
    $event = $dbh->quote($atbat->{event});
    $event_num = $atbat->{num};
    $ball = $atbat->{b};
    $strike = $atbat->{s};
    $out = $atbat->{o};
    $pitcher_id = $atbat->{pitcher};
    $batter_id = $atbat->{batter};
    $stand = $dbh->quote($atbat->{stand});
    $des = $dbh->quote($atbat->{des});
 
    $no_duplicate_query = 'SELECT ab_id FROM atbats WHERE (game_id = ' . $select_game_id
    . ' AND num = ' . $event_num . ')';
    $sth= $dbh->prepare($no_duplicate_query) or die $DBI::errstr;
    $sth->execute();
    my $numRows = $sth->rows;
    $sth->finish();
    if ($numRows) {
    # don't insert duplicate at bat entry into atbats table
    print "$select_game_id, $inning_num, $event_num: That's a duplicate at bat to one in the database already.\n";
    } else {
    # insert a new record in the database for this at bat
    $ab_query = 'INSERT INTO atbats (game_id, inning, num, ball, strike, outs,'
    . ' batter, pitcher, stand, des, event, half, def2, def3, def4, def5, def6, def7, def8, def9) '
    . 'VALUES (' . $select_game_id . ', ' . $inning_num . ', ' . $event_num 
    . ', ' . $ball . ', ' . $strike . ', ' . $out . ', ' . $batter_id 
    . ', ' . $pitcher_id . ', ' . $stand . ', ' . $des . ', ' . $event . ', ' . $half
    . ', ' . $def2 . ', ' . $def3 . ', ' . $def4 . ', ' . $def5 . ', ' . $def6
    . ', ' . $def7 . ', ' . $def8 . ', ' . $def9 . ')';
    $sth= $dbh->prepare($ab_query) or die $DBI::errstr;
#     print "SQL: $ab_query\n";
    $sth->execute();
    $sth->finish();
    }
    # get the at bat id from the database to use when inputting the pitch data
    $ab_id_query = 'SELECT ab_id FROM atbats WHERE (game_id = ' . $select_game_id
    . ' AND num = ' . $event_num . ')';
    $sth= $dbh->prepare($ab_id_query) or die $DBI::errstr;
    $sth->execute();
    my $numRows = $sth->rows;
    if (1==$numRows) {
    $select_ab_id = $sth->fetchrow_array();
	#gwyn
    #print " ab#$select_ab_id,";
    $sth->finish();
    } else {
    print "numrows=$numRows, duplicate at bat entry $select_ab_id in database or game not found.\n";
    }
 
    foreach $pitch (@{$atbat->{pitch}}) {
    # these fields are common to pitch-f/x and non-pfx data
    $pitch_des = $dbh->quote($pitch->{des});
    $pitch_id = $pitch->{id};
    $result_type = $dbh->quote($pitch->{type});
    $pitch_x = $pitch->{x};
    $pitch_y = $pitch->{y};
    $start_speed = $pitch->{start_speed};
    $on_1b = $dbh->quote($pitch->{on_1b});
    $on_2b = $dbh->quote($pitch->{on_2b});
    $on_3b = $dbh->quote($pitch->{on_3b});
    # determine if the data for this pitch includes pitch-f/x fields
print "Pitch_id is $pitch_id. Start Speed is $start_speed\n";
    $pitchfx = 0;
    if (0 < $start_speed) {
        $pitchfx = 1;
        $end_speed = $pitch->{end_speed};
        $sz_top = $pitch->{sz_top};
        $sz_bot = $pitch->{sz_bot};
        $pfx_x = $pitch->{pfx_x};
        $pfx_z = $pitch->{pfx_z};
        $px = $pitch->{px};
        $pz = $pitch->{pz};
        $x0 = $pitch->{x0};
        $y0 = $pitch->{y0};
        $z0 = $pitch->{z0};
        $vx0 = $pitch->{vx0};
        $vy0 = $pitch->{vy0};
        $vz0 = $pitch->{vz0};
        $ax = $pitch->{ax};
        $ay = $pitch->{ay};
        $az = $pitch->{az};
        $break_y = $pitch->{break_y};
        $break_angle = $pitch->{break_angle};
        $break_length = $pitch->{break_length};
        $sv_id = $dbh->quote($pitch->{sv_id});
        $pitch_type = $dbh->quote($pitch->{pitch_type});
        $type_confidence = $pitch->{type_confidence};
        $nasty = $pitch->{nasty};
        $cc = $dbh->quote($pitch->{cc});
	#gwyn - nasty doesnt always get set so give it a zero if its NULL
	if ($nasty eq "") {
		$nasty=0;
	}
	if ($cc eq "") {
		$cc=0;
	}
    }
    $no_duplicate_query = 'SELECT pitch_id FROM pitches WHERE (ab_id = ' . $select_ab_id
    . ' AND id = ' . $pitch_id . ')';
    $sth= $dbh->prepare($no_duplicate_query) or die $DBI::errstr;
    $sth->execute();
    my $numRows = $sth->rows;
    $sth->finish();
    if ($numRows) {
        # don't insert duplicate pitch entry into pitches table
        print "$select_ab_id, $pitch_id: That's a duplicate pitch to one in the database already.\n";
    } else {
        # insert a new record in the database for this pitch
        if ($pitchfx) {
	print "pitchfx=$pitchfx\n";
        $pitch_query = 'INSERT INTO pitches (ab_id, des, type, id, x, y, start_speed,'
        . ' end_speed, sz_top, sz_bot, pfx_x, pfx_z, px, pz, x0, y0, z0, vx0, vy0,'
        . ' vz0, ax, ay, az, break_y, break_angle, break_length, sv_id, pitch_type,'
        . ' type_confidence, on_1b, on_2b, on_3b, nasty, cc) '
        . 'VALUES (' . join(', ', ($select_ab_id, $pitch_des, $result_type, $pitch_id, 
        $pitch_x, $pitch_y, $start_speed, $end_speed, $sz_top, $sz_bot, $pfx_x, $pfx_z, 
        $px, $pz, $x0, $y0, $z0, $vx0, $vy0, $vz0, $ax, $ay, $az, $break_y, $break_angle, 
        $break_length, $sv_id, $pitch_type, $type_confidence, $on_1b, $on_2b, $on_3b, $nasty, $cc)) . ')';
        } else {
		print "pitchfx=$pitchfx\n";
            $pitch_query = 'INSERT INTO pitches (ab_id, des, type, id, x, y, on_1b, on_2b, on_3b)'
        . ' VALUES (' . join(', ', ($select_ab_id, $pitch_des, $result_type, $pitch_id,
        $pitch_x, $pitch_y, $on_1b, $on_2b, $on_3b)) . ')';
        }
         print "SQL: $pitch_query\n";
        #$sth= $dbh->prepare($pitch_query);
        $sth= $dbh->prepare($pitch_query);
        $sth->execute();
    }
    }
}
