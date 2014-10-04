#!/usr/bin/perl
use JSON::Parse 'parse_json';
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::FormatText::WithLinks;
use HTML::Form;
use HTML::TokeParser;
use XML::Simple;
use Data::Dumper;
use URI::Escape;

my $host = "http://localhost";
my $port = 0;
my $get = "";
my %post;
my $format = "text";
my $res = "/";
my $xauth = "";
my $cookiefile = "cookies.txt";
my $noencode = 0;
my $outfile = "";
my $useragent = "Mozilla/5.0";
my $tab = "";
my @basicauth;
my $oauth = "OAuth ";
my @cusheader;
my $inputfile = "";
my $showlinks = 0;
my $customcontent = "";
my $method = "";
my $ignoreerrors = 0;

print "APItest v1.5 by Patrick Lambert - http://dendory.net\n\n";

if($#ARGV == -1 || $#ARGV == 0) # usage
{
	print "APItest is a powerful engine used to test web APIs.\n\nUsage: $0 [-host <host>] [-port <port>] [-get <key>=<value>] [-post <key>=<value>] [-format html|xml|text|json|form] [-xauth <value>] [-oauth <key>=<value>] [-basicauth <name> <passwd>] [-cookies <file>] [-res <folder>] [-proxy <host>:<port>] [-useragent <text>] [-output <file>] [-input <file>] [-parse <keywords>] [-contenttype <content-type>] [-header <header>:<value>] [-content <text>] [-method head|get|post|put] [-noencode] [-showlinks] [-ignoreerrors]\n\n";
	printf("%-32s%0s\n\n", "-host <host>", "Host or IP to connect to, should start with http or https. Default is localhost.");
	printf("%-32s%0s\n\n", "-port <port>", "Port to use, default is 80 for http, 443 for https.");
	printf("%-32s%0s\n\n", "-get <key>=<value>", "One GET parameter. You can add multiple. You can use variables to pair with -input. Will be escaped unless -noencode is specified.");
	printf("%-32s%0s\n\n", "-post <key>=<value>", "One POST parameter. You can add multiple. You can use variables to pair with -input.");
	printf("%-32s%0s\n\n", "-format html|text|json|xml|form", "How to format the result.");
	printf("%-32s%0s\n\n", "-xauth <value>", "Use an Xauth header.");
	printf("%-32s%0s\n\n", "-oauth <key>=<value>", "An Oauth parameter. You can add multiple.");
	printf("%-32s%0s\n\n", "-basicauth <name> <passwd>", "Use basic authentication.");
	printf("%-32s%0s\n\n", "-cookies <file>", "Where to store and fetch cookies. Default is cookies.txt.");
	printf("%-32s%0s\n\n", "-res <folder>", "The API resource or web folder to use. Default is /.");
	printf("%-32s%0s\n\n", "-proxy <host>:<port>", "Use an http proxy.");
	printf("%-32s%0s\n\n", "-useragent <text>", "Specify a user agent to use.");
	printf("%-32s%0s\n\n", "-output <file>", "Where to store the results. Default is the screen.");
	printf("%-32s%0s\n\n", "-input <file>", "Read from a file produced by the -output and -parse flags, then replace variables in -get and -post.");
	printf("%-32s%0s\n\n", "-parse <keywords>", "Format the results to show only fields matching exactly these key words.");
	printf("%-32s%0s\n\n", "-contenttype <content-type>", "Overwrite Content-Type.");
	printf("%-32s%0s\n\n", "-header <header>:<value>", "Add a custom header.");
	printf("%-32s%0s\n\n", "-content <text>", "Add content to the request.");
	printf("%-32s%0s\n\n", "-method head|get|post|put", "Overwrite default method.");
	printf("%-32s%0s\n\n", "-noencode", "Don't escape -get values. Required if you use -input and -get variables.");
	printf("%-32s%0s\n\n", "-showlinks", "Show all links at the bottom of the page. Only usable with -format html.");
	printf("%-32s%0s\n\n", "-ignoreerrors", "Parse results even when receiving an error.");
	print "\nVariables: Use the -input flag to import a file produced by the -output and -parse flags, then use variables in -get and -post to replace with values from the file. You can use line number variables like \$0, \$1, etc, or specify exact keys from the input file like \$id, \$title, etc.\n\n\nExample 1: $0 -host http://reddit.com -res /r/funny/.rss -format xml -parse \"title\"\n\nExample 2: $0 -host http://www.imdb.com -res /xml/find -get tt=on -get json=1 -get \"q=The walking dead\" -format json -output films.json\n\nExample 3: $0 -host http://google.com -format form -parse \"name value type\"\n\n";
	exit;
}

while(@ARGV) # check arguments for options
{
	if($ARGV[0] eq "-host")
	{
		shift(@ARGV);
		$host = $ARGV[0];
		if(substr($host, 0, 7) ne "http://" && substr($host, 0, 8) ne "https://") { $host = "http://" . $host; }
	}
	elsif($ARGV[0] eq "-oauth")
	{
		shift(@ARGV);
		if(index($ARGV[0], "=") < 0) { die("Error: OAuth entry must be key=value in: $ARGV[0]\n"); }
		if($oauth ne "OAuth ") { $oauth = $oauth . ", "; }
		$oauth = $oauth . $ARGV[0];
	}
	elsif($ARGV[0] eq "-showlinks")
	{
		$showlinks = 1;
	}
	elsif($ARGV[0] eq "-ignoreerrors")
	{
		$ignoreerrors = 1;
	}
	elsif($ARGV[0] eq "-xauth")
	{
		shift(@ARGV);
		$xauth = $ARGV[0];
		if(!$xauth) { die("Error: Xauth must have a value.\n"); }
	}
	elsif($ARGV[0] eq "-input")
	{
		shift(@ARGV);
		$inputfile = $ARGV[0];
		if(!$inputfile) { die("Error: Input must be a valid file.\n"); }
	}
	elsif($ARGV[0] eq "-basicauth")
	{
		shift(@ARGV);
		$basicauth[0] = $ARGV[0];
		shift(@ARGV);
		$basicauth[1] = $ARGV[0];
		if(!$basicauth[1]) { die("Error: Basic Auth must have a name and password.\n"); }
	}
	elsif($ARGV[0] eq "-parse")
	{
		shift(@ARGV);
		$tab = $ARGV[0];
		if(!$tab) { die("Error: Parse must have value.\n"); }
	}
	elsif($ARGV[0] eq "-content")
	{
		shift(@ARGV);
		$customcontent = $ARGV[0];
		if(!$customcontent) { die("Error: Content must have value.\n"); }
	}
	elsif($ARGV[0] eq "-contenttype")
	{
		shift(@ARGV);
		$customtype = $ARGV[0];
		if(!$customtype) { die("Error: Content-Type must have value.\n"); }
	}
	elsif($ARGV[0] eq "-method")
	{
		shift(@ARGV);
		$method = uc($ARGV[0]);
		if($method ne "POST" && $method ne "GET" && $method ne "HEAD" && $method ne "PUT") { die("Error: Method must be GET, PUT, POST or HEAD.\n"); }
	}
	elsif($ARGV[0] eq "-header")
	{
		shift(@ARGV);
		if(index($ARGV[0], ":") < 0) { die("Error: Header must be header:value in: $ARGV[0]\n"); }
		@cusheader = split(":", $ARGV[0], 2);
	}
	elsif($ARGV[0] eq "-proxy")
	{
		shift(@ARGV);
		$proxy = $ARGV[0];
		if(!$proxy) { die("Error: Proxy must have a value: $proxy\n"); }
		if(substr($proxy, 0, 7) ne "http://" && substr($proxy, 0, 8) ne "https://") { $proxy = "http://" . $proxy; }
	}
	elsif($ARGV[0] eq "-cookies")
	{
		shift(@ARGV);
		$cookiefile = $ARGV[0];
		if(!$cookiefile) { die("Error: Cookies must list a valid file.\n"); }
	}
	elsif($ARGV[0] eq "-useragent")
	{
		shift(@ARGV);
		$useragent = $ARGV[0];
		if(!$useragent) { die("Error: Useragent must contain a value.\n"); }
	}
	elsif($ARGV[0] eq "-output")
	{
		shift(@ARGV);
		$outfile = $ARGV[0];
		if(!$outfile) { die("Error: Output must be a valid file.\n"); }
	}
	elsif($ARGV[0] eq "-noencode")
	{
		$noencode = 1;
		$get = uri_unescape($get);
	}
	elsif($ARGV[0] eq "-res")
	{
		shift(@ARGV);
		$res = $ARGV[0];
		if(substr($res, 0, 1) ne "/") { die("Error: Resource must start with / in: $res\n"); }
	}
	elsif($ARGV[0] eq "-format")
	{
		shift(@ARGV);
		if($ARGV[0] ne "json" && $ARGV[0] ne "xml" && $ARGV[0] ne "form" && $ARGV[0] ne "html" && $ARGV[0] ne "text") { die("Error: Format must be text, json, html, xml or form in: $ARGV[0]\n"); }
		else { $format = $ARGV[0]; }
	}
	elsif($ARGV[0] eq "-port")
	{
		shift(@ARGV);
		$port = int($ARGV[0]);
		if($port < 1 || $port > 65535) { die("Error: Invalid port number: $port\n"); }
	}
	elsif($ARGV[0] eq "-get")
	{
		shift(@ARGV);
		if(index($ARGV[0], "=") < 0) { die("Error: Get entry must be key=value in: $ARGV[0]\n"); }
		if($get ne "") { $get = $get . "&"; }
		my @tmp = split("=", $ARGV[0], 2);
		if($noencode) { $get = $get . $tmp[0] . "=" . $tmp[1]; }
		else { $get = $get . $tmp[0] . "=" . uri_escape($tmp[1]) . ""; }
	}
	elsif($ARGV[0] eq "-post")
	{
		shift(@ARGV);
		if(index($ARGV[0], "=") < 0) { die("Error: Post entry must be key=value in: $ARGV[0]\n"); }
		my @tmp = split("=", $ARGV[0], 2);
		$post{$tmp[0]} = $tmp[1];
	}
	else
	{
		print "Unknown option: $ARGV[0]\n\n";
	}
	shift(@ARGV);
}

# restrictions
if($showlinks && $format ne "html") { die("Error: Showlinks can only be used with format html.\n"); }

# replace variables if input
if($inputfile)
{
	open($IF, $inputfile) or die("Error: Cannot read $inputfile\n");
	my $lnum = 0;
	my @linearr;
	while ($line = <$IF>)
	{
		chomp($line);
		@linearr = split(" => ", $line, 2);
		keys %post;      
		while(my ($k, $v) = each %post)
		{
			$v =~ s/\$$linearr[0]/$linearr[1]/g;    # replacing direct strings in post
			$v =~ s/\$$lnum/$linearr[1]/g;          # replacing line numbers in post
			$post{$k} = $v;
		}
		$get =~ s/\$$linearr[0]/$linearr[1]/g;          # replacing direct strings in get
		$get =~ s/\$$lnum/$linearr[1]/g;        	# replacing line numbers in get
		$lnum++;
	}
	close($IF);
}

# showing final options
if($port > 0) { print "Endpoint: $host:$port$res\n"; }
else { print "Endpoint: $host$res\n"; }
if($get) { print "GET options: $get\n"; }
if(%post) { print "POST options: ...\n"; }
print "Cookies: $cookiefile\n";
print "Format: $format\n";
if(@cusheader) { print "$cusheader[0]: $cusheader[1]\n"; }
if($customcontent) { print "Content: $customcontent\n"; }
if($customtype) { print "Content-Type: $customtype\n"; }
if($proxy) { print "Proxy: $proxy\n"; }
if($xauth) { print "XAuth: $xauth\n"; }
if($outfile) { print "Output file: $outfile\n"; }
if(@basicauth) { print "Basic Auth: { $basicauth[0], $basicauth[1] }\n"; }
if($oauth ne "OAuth ") { print $oauth . "\n"; }
if($tab) { print "Parse: $tab\n"; }
if($noencode) { print "No encode: On\n"; }
if($showlinks) { print "Show links: On\n"; }
print "\nConnecting...\n\n";

# crafting endpoint URI
my $server_endpoint;
if($port > 0)
{
	if($get) { $server_endpoint = "$host:$port$res?$get"; }
	else { $server_endpoint = "$host:$port$res"; }
}
else
{
	if($get) { $server_endpoint = "$host$res?$get"; }
	else { $server_endpoint = "$host$res"; }
}

# cookie file
my $cookie_jar = HTTP::Cookies->new(file => $cookiefile, autosave => 1, ignore_discard => 1);
my $ua = LWP::UserAgent->new(cookie_jar => $cookie_jar);

# set http proxy if present
if($proxy) { $ua->proxy(["http", "https"], $proxy); }

# set user agent
$ua->agent($useragent);

# ignore SSL certificate errors
$ua->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00); 

# create request
my $req;
if(%post) { $req = HTTP::Request->new(POST => $server_endpoint) or die("Error: Could not open socket.\n"); }
else { $req = HTTP::Request->new(GET => $server_endpoint) or die("Error: Could not open socket.\n"); }

if(!$customtype) { $req->header('Content-Type' => "text/" . $format . "; charset=utf-8"); }
else { $req->header('Content-Type' => $customtype); }

# authorizations
if(@cusheader) { $req->header($cusheader[0] => $cusheader[1]); }
if($xauth) { $req->header('x-auth-token' => $xauth); }
if(@basicauth) { $req->authorization_basic($basicauth[0], $basicauth[1]); }
if($oauth ne "OAuth ") { $req->header('Authorization' => $oauth); }

if($customcontent) { $req->content($customcontent); }
if($method) { $req->method($method); }

# fetch page
my $result;
if(!%post) { $result = $ua->request($req) or die("Error: Could not connect to remote host.\n"); }
else { $result = $ua->post($server_endpoint, \%post ) or die("Error: Could not connect to remote host.\n"); }

if($result->is_success)
{
	print "Success: [" . $result->code . "]\n\n";
}
else
{
	print "Error: [" . $result->code . "] " . $result->message . "\n\n";
	if(!$ignoreerrors) { exit(1); }
}

if($format eq "html")
{
	if(!$tab)
	{
		if($showlinks) { $parsed = HTML::FormatText::WithLinks->new(before_link=>'', after_link=>'', footnote=>'[%n] %l'); }
		else { $parsed = HTML::FormatText::WithLinks->new(before_link=>'', after_link=>'', footnote=>''); }
		if (!$outfile) { print $parsed->parse($result->decoded_content); }
		else { printfile($parsed->parse($result->decoded_content)); }
	}
	else # parse
	{
		my $buf = "";
		my $p;
		@words = split(' ', $tab);
		foreach my $word (@words)
		{
			$p = HTML::TokeParser->new(\$result->decoded_content);
			while (my $tag = $p->get_tag($word))
			{
				if($word eq "img") { $key = $tag->[1]{src}; }
				else { $key = $p->get_trimmed_text; }
				if($key) { $buf = $buf . $word . " => " . $key . "\n"; }
				if($word eq "a") { $buf = $buf . "href => " . $tag->[1]{href} . "\n";  }
			}
		}
		if (!$outfile) { print $buf; }
		else { printfile($buf); }
	}
}
elsif($format eq "form")
{
	my $form = HTML::Form->parse($result->decoded_content, base => $result->base, charset => $result->content_charset) or die("Error: Can't parse form data.\n");
	if(!$tab)
	{
		if (!$outfile) { print Dumper($form); }
		else { printfile(Dumper($form)); }
	}
	else # parse
	{
		my $h = Dumper($form);
		my $buf = "";
		@keys = split(/\n/, $h);
		foreach my $key (@keys)
		{
			$key =~ s/[\n\t]//g; # remove new lines
			$key =~ s/^\s+//; # remove front spaces
			$key =~ s/\s+$//; # remove trailing spaces
			$key =~ s/,+$//; # remove trailing commas
			$key =~ s/\"//g; # remove single quotes
			$key =~ s/\'//g; # remove double quotes
			@k = split(' => ', $key);
			if(index(lc($tab), lc($k[0])) != -1) { $buf = $buf . $key . "\n"; }
		}
		if (!$outfile) { print $buf; }
		else { printfile($buf); }
	}
}
elsif($format eq "json")
{
	if(!$tab)
	{
		if (!$outfile) { print Dumper(parse_json($result->decoded_content)); }
		else { printfile(Dumper(parse_json($result->decoded_content))); }
	}
	else # parse
	{
		my $h = Dumper(parse_json($result->decoded_content));
		my $buf = "";
		@keys = split(/\n/, $h);
		foreach my $key (@keys)
		{
			$key =~ s/[\n\t]//g; # remove new lines
			$key =~ s/^\s+//; # remove front spaces
			$key =~ s/\s+$//; # remove trailing spaces
			$key =~ s/,+$//; # remove trailing commas
			$key =~ s/\"//g; # remove single quotes
			$key =~ s/\'//g; # remove double quotes
			@k = split(' => ', $key);
			if(index(lc($tab), lc($k[0])) != -1) { $buf = $buf . $key . "\n"; }
		}
		if (!$outfile) { print $buf; }
		else { printfile($buf); }
	}
}
elsif($format eq "xml")
{
	$xml = new XML::Simple;
	$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
	if(!$tab)
	{
		if (!$outfile) { print Dumper($xml->XMLin($result->decoded_content)); }
		else { printfile(Dumper($xml->XMLin($result->decoded_content))); }
	}
	else # parse
	{
		my $h = Dumper($xml->XMLin($result->decoded_content));
		my $buf = "";
		@keys = split(/\n/, $h);
		foreach my $key (@keys)
		{
			$key =~ s/[\n\t]//g; # remove new lines
			$key =~ s/^\s+//; # remove front spaces
			$key =~ s/\s+$//; # remove trailing spaces
			$key =~ s/,+$//; # remove trailing commas
			$key =~ s/\"//g; # remove single quotes
			$key =~ s/\'//g; # remove double quotes
			@k = split(' => ', $key);
			if(index(lc($tab), lc($k[0])) != -1) { $buf = $buf . $key . "\n"; }
		}
		if (!$outfile) { print $buf; }
		else { printfile($buf); }
	}
}
else # text
{
	if(!$tab)
	{
		if (!$outfile) { print $result->decoded_content;  }
		else { printfile($result->decoded_content); }
	}
	else # parse
	{
		my $buf = "";
		my @lines = split('\n', $result->decoded_content);
		my @words = split (' ', $tab);
		foreach my $line (@lines)
		{
			chomp($line);
			foreach my $word (@words)
			{
				if(index($line, $word) != -1) { $buf = $buf . $word . " => " . $line . "\n"; }
			}
		}
		if (!$outfile) { print $buf;  }
		else { printfile($buf); }
	}
}

sub printfile # used if -ouput provided
{
	my ($data) = @_;
	open ($OF, ">" . $outfile) or die("Error: Could not open $outfile.\n");
	say $OF $data;
	close($OF);
	print "\nSaved $outfile.\n";
}