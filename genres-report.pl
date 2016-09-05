#!/usr/bin/perl -w

use strict;
use warnings;

use utf8;
use DBI;
use Encode;
use HTML::Entities;
use URI::Escape qw/uri_escape_utf8/;
use POSIX qw/strftime/;

my $DBNAME = 'gcd';
my $DBHOST = 'localhost';
my $DBUSER = 'gcd';
my $DBPASS = 'gcd_pass';
my $SITE = 'www.comics.org';

if (defined($ARGV[0]) and $ARGV[0] eq 'beta') {
    $DBNAME = 'gcd_beta';
    $DBHOST = 'localhost';
    $DBUSER = 'beta';
    $DBPASS = 'beta_pass';
    $SITE = 'beta.comics.org';
}

my @official_genres = (
    'adventure',
    'advocacy',
    'animal',
    'anthropomorphic-funny animals',
    'aviation',
    'biography',
    'car',
    'children',
    'crime',
    'detective-mystery',
    'domestic',
    'drama',
    'erotica',
    'fantasy-supernatural',
    'fashion',
    'historical',
    'history',
    'horror-suspense',
    'humor',
    'jungle',
    'martial arts',
    'math & science',
    'medical',
    'military',
    'nature',
    'non-fiction',
    'religious',
    'romance',
    'satire-parody',
    'science fiction',
    'sports',
    'spy',
    'superhero',
    'sword and sorcery',
    'teen',
    'war',
    'western-frontier',
);

my %map = (
    'abenteuer' => 'adventure',
    'adaptation' => [ undef, 'adaptation' ],
    'advice' => [ undef, 'advice' ],
    'adult' => [ undef, 'adult' ],
    'adventure (action)' => 'adventure',
    'american football' => [ 'sports', 'american football' ],
    'animales' => 'animal',
    'animali' => 'animal',
    'animals' => 'animal',
    'anthropomorphic' => 'anthropomorphic-funny animals',
    'aventura' => 'adventure',
    'aventuras' => 'adventure',
    'aventureiro' => 'adventure',
    'avontuur' => 'adventure',
    'avventuroso' => 'adventure',
    'ação' => 'adventure',
    'belico' => 'war',
    'biografico' => 'biography',
    'biografía' => 'biography',
    'biographical' => 'biography',
    'bélico' => 'war',
    'cars' => 'car',
    'childrens' => 'children',
    'ciencia ficción' => 'science fiction',
    'ciencia-ficción' => 'science fiction',
    'comedy' => 'humor',
    'crianças' => 'children',
    'crime fiction' => 'crime',
    'crimen' => 'crime',
    'criminal' => 'crime or detective-mystery ?',
    'del oeste' => 'western-frontier',
    'deportes' => 'sports',
    'detectiv' => 'detective-mystery',
    'detektiv' => 'detective-mystery',
    'djungle' => 'jungle',
    'documentale' => 'non-fiction',
    'dramma' => 'drama',
    'dschungel' => 'jungle',
    'dschungelabenteuer' => 'jungle; adventure',
    'dschungelabenteur' => 'jungle; adventure',
    'erotic' => 'erotica',
    'erotico' => 'erotica',
    'erotik' => 'erotica',
    'espionage' => 'spy',
    'espionaje' => 'spy',
    'facts' => 'non-fiction',
    'fantasy' => 'fantasy-supernatural',
    'fantaisy' => 'fantasy-supernatural',
    'fantasia' => 'fantasy-supernatural',
    'fantastico' => 'fantasy-supernatural',
    'fantasía' => 'fantasy-supernatural',
    'feit' => 'non-fiction',
    'ficção científica' => 'science fiction',
    'ficção' => 'drama',
    'football' => [ 'sports', 'football' ],
    'frontier' => 'western-frontier',
    'funny' => 'humor',
    'games' => [ undef, 'games' ],
    'geschichte' => 'historical',
    'giallo' => [ 'detective-mystery; horror-suspense', 'giallo' ],
    'giungla' => 'jungle',
    'go' => [ 'sports', 'go' ],
    'guerra' => 'war',
    'herói formidável' => 'superhero',
    'historical fiction' => 'historical',
    'historical' => 'historical',
    'historie' => 'historical',
    'histórico' => 'historical',
    'horreur' => 'horror-suspense',
    'horror-suspenso' => 'horror-suspense',
    'human drama' => 'drama',
    'humor (comedy)' => 'humor',
    'infantil' => 'children',
    'jokes' => [ 'humor', 'jokes' ],
    'joven' => 'teen',
    'jungle adventure' => 'jungle; adventure',
    'juvenil' => 'teen',
    'kinder' => 'children',
    'krimi' => 'crime',
    'kung fu' => 'martial arts',
    'literary adaptation' => [ undef, 'literary adaptation' ],
    'magia' => 'fantasy-supernatural',
    'misterio' => 'detective-mystery',
    'mistero' => 'detective-mystery',
    'movie adaptation' => [ undef, 'movie adaptation' ],
    'nero' => 'crime',
    'nonfiction' => 'non-fiction',
    'oeste' => 'western-frontier',
    'orrore' => 'horror-suspense',
    'parodia' => 'satire-parody',
    'parodie' => 'satire-parody',
    'parody-satire' => 'satire-parody',
    'phantastik' => 'fantasy-supernatural',
    'policiaco' => 'detective-mystery',
    'political' => [ 'advocacy', 'political' ],
    'poliziesco' => 'detective-mystery',
    'propaganda' => 'advocacy',
    'puzzle page' => [ undef, 'puzzle page' ],
    'puzzle' => [ undef, 'puzzle' ],
    'religion' => 'religious',
    'religione' => 'religious',
    'religioso' => 'religious',
    'romantico' => 'romance',
    'romantiek' => 'romance',
    'satira' => 'satire-parody',
    'satira-parodia' => 'satire-parody',
    'sci-fi' => 'science fiction',
    'science ficiton' => 'science fiction',
    'naturwissenschaft' => 'math & science',
    'science' => 'math & science',
    'science-fiction' => 'science fiction',
    'scienza' => 'math & science',
    'sentimentale' => 'romance',
    'sf' => 'science fiction',
    'slice of life' => [ 'drama', 'slice of life' ],
    'soap opera' => [ 'drama', 'soap opera' ],
    'sobrenatural' => 'horror-suspense',
    'soccer' => [ 'sports', 'soccer' ],
    'spenning' => 'horror-suspense',
    'spionaggio' => 'spy',
    'sportivo' => 'sports',
    'storico' => 'historical',
    'super eroe' => 'superhero',
    'super hero' => 'superhero',
    'super héroes' => 'superhero',
    'super-heroes' => 'superhero',
    'super-heros' => 'superhero',
    'super-herói' => 'superhero',
    'super-héroes' => 'superhero',
    'superhelden' => 'superhero',
    'superheroe' => 'superhero',
    'superheroes' => 'superhero',
    'superhéroe' => 'superhero',
    'suspense' => 'horror-suspense',
    'sword & sorcery' => 'sword and sorcery',
    'szuperhos' => 'superhero',
    'teen humor' => 'teen; humor',
    'television adaptation' => [ undef, 'television adaptation' ],
    'tennis' => [ 'sports', 'tennis' ],
    'tv based' => [ undef, 'TV based' ],
    'tv tie-in' => [ undef, 'TV tie-in' ],
    'action' => 'adventure',
    'advice column' => [ undef, 'advice column' ],
    'autobio' => [ 'biography', 'autobiography' ],
    'autobiographical' => [ 'biography', 'autobiography' ],
    'autobiography' => [ 'biography', 'autobiography' ],
    'avventura' => 'adventure',
    'bio' => 'biography',
    'detective' => 'detective-mystery',
    'fact' => 'non-fiction',
    'family' => 'domestic',
    'fantascienza' => 'science fiction',
    'funny animal' => 'anthropomorphic-funny animals',
    'funny animals' => 'anthropomorphic-funny animals',
    'gag' => 'humor',
    'gags' => 'humor',
    'horror' => 'horror-suspense',
    'humour' => 'humor',
    'mystery' => 'detective-mystery',
    'parody' => 'satire-parody',
    'period' => 'historical',
    'satire' => 'satire-parody',
    'satire' => 'satire-parody',
    'soap' => [ 'drama', 'soap' ],
    'sport' => 'sports',
    'super-hero' => 'superhero',
    'supereroi' => 'superhero',
    'umoristico' => 'humor',
    'western' => 'western-frontier',
);

my $dbh = DBI->connect("dbi:mysql:$DBNAME:$DBHOST", $DBUSER, $DBPASS,
                { PrintError => 1, mysql_enable_utf8 => 1 });
$dbh->do(qq{SET NAMES 'utf8';});
my $q = $dbh->selectall_arrayref("SELECT genre FROM gcd_story
                                         WHERE deleted = 0 AND
                                               genre <> '' AND
                                               genre IS NOT NULL");
my %genre_count;
foreach my $row (@$q) {
    foreach my $genre (split /\s*;\s*/, lc $row->[0]) {
        $genre =~ tr/\n\r\f\t / /s;
        $genre =~ s/^\s+//;
        $genre =~ s/\s+$//;
        $genre_count{$genre}++ if $genre;
    }
}

my %official = map { $_ => 1 } @official_genres;

$ENV{TZ} = 'UTC';
my $timestamp = strftime('%Y-%m-%d %R %Z', localtime);

binmode STDOUT, ":utf8";

print "<!DOCTYPE html>
<html>
<head>
 <meta http-equiv='Content-Type' content='text/html; charset=UTF-8' />
 <title>GCD Genres Report ($SITE)</title>
 <link rel='stylesheet' href='style.css' type='text/css'>
 <link rel='stylesheet' href='themes/blue/style.css' type='text/css'>
 <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'></script>
 <script type='text/javascript' src='jquery.tablesorter.min.js'></script>
 <script>
   \$(document).ready(function() { \$('table').tablesorter({ widgets: ['zebra'] }); } ); 
 </script>
<body>
<h1>GCD Genres Report ($SITE)</h1>
<p>Updated: $timestamp</p>
<table class=tablesorter>
<thead>
<tr><th>Count</th><th>Genre</th><th>Comments</th></tr>
</thead>
<tbody>\n";

sub by_count {
    $genre_count{$b} <=> $genre_count{$a};
}

sub control_caret {
    my $s = shift;
    $s =~ s/([\000-\037])/"^".chr(64+ord($1))/ge;
    return $s;
}

my $search = encode_entities('http://' . $SITE . '/search/advanced/process/?target=sequence&method=icontains&logic=False&order1=series&order2=date&genre=');
for my $genre (sort by_count keys %genre_count) {
    my $status;
    my $new_genre;
    if (defined $official{$genre}) {
        $status = 'official';
    } elsif (defined $map{$genre})  {
        if (ref $map{$genre}) {
            $new_genre = shift @{$map{$genre}};
            if (defined $new_genre) {
                $status = "mapped to: <i>$new_genre</i>, with keywords: ";
            } else {
                $status = "mapped to keywords: ";
            }
            $status .= join(', ', map { "<i>$_</i>" } @{$map{$genre}});
        } else {
            $status = "mapped to: <i>$map{$genre}</i>";
        }
    } else {
        $status = '&nbsp;';
    }
    my $class = ($status =~ /\?/)? ' class="ambig"': '';
    my $genre_enc = encode_entities control_caret($genre);
    my $url = $search . uri_escape_utf8($genre, "^A-Za-z0-9\-\._~");
    print "<tr><td>$genre_count{$genre}</td><td><a href='$url'>$genre_enc</a></td><td$class>$status</td></tr>\n";
}
print "</tbody></table>\n";
