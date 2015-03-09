APItest
=======

Command line test utility for web APIs. A compiled binary for Windows and Linux is available in the `bin` folder.

### Usage
    APItest v1.2 by Patrick Lambert - http://dendory.net
     
    APItest is a powerful engine used to test web APIs.
    
    Usage: apitest [-host <host>] [-port <port>] [-get <key>=<value>] [-post <key>=<value>] [-format htm
    l|xml|text|json|form] [-xauth <value>] [-oauth <key>=<value>] [-basicauth <name> <passwd>] [-cookies
     <file>] [-res <folder>] [-proxy <host>:<port>] [-useragent <text>] [-output <file>] [-input <file>]
     [-parse <keywords>] [-contenttype <content-type>] [-header <header>:<value>] [-content <text>] [-me
    thod <method>] [-noencode] [-showlinks] [-ignoreerrors]
    
    -host <host>                    Host or IP to connect to, should start with http or https. Default i
    s localhost.
    
    -port <port>                    Port to use, default is 80 for http, 443 for https.
    
    -get <key>=<value>              One GET parameter. You can add multiple. You can use variables to pa
    ir with -input. Will be escaped unless -noencode is specified.
    
    -post <key>=<value>             One POST parameter. You can add multiple. You can use variables to p
    air with -input.
    
    -format html|text|json|xml|form How to format the result.
    
    -xauth <value>                  Use an Xauth header.
    
    -oauth <key>=<value>            An Oauth parameter. You can add multiple.
    
    -basicauth <name> <passwd>      Use basic authentication.
    
    -cookies <file>                 Where to store and fetch cookies. Default is cookies.txt.
    
    -res <folder>                   The API resource or web folder to use. Default is /.
    
    -proxy <host>:<port>            Use an http proxy.
    
    -useragent <text>               Specify a user agent to use.
    
    -output <file>                  Where to store the results. Default is the screen.
    
    -input <file>                   Read from a file produced by the -output and -parse flags, then repl
    ace variables in -get and -post.
    
    -parse <keywords>               Format the results to show only fields matching exactly these key wo
    rds.
    
    -contenttype <content-type>     Overwrite Content-Type.
    
    -header <header>:<value>        Add a custom header.
    
    -content <text>                 Add content to the request.
    
    -method <method>                Overwrite method to POST, GET, PUT or HEAD.
    
    -noencode                       Don't escape -get values. Required if you use -input and -get variab
    les.
    
    -showlinks                      Show all links at the bottom of the page. Only usable with -format h
    tml.
    
    -ignoreerrors                   Parse results even when receiving an error.
    
    
    Variables: Use the -input flag to import a file produced by the -output and -parse flags, then use v
    ariables in -get and -post to replace with values from the file. You can use line number variables l
    ike $0, $1, etc, or specify exact keys from the input file like $id, $title, etc.
    
    
    Example 1: apitest -host http://reddit.com -res /r/funny/.rss -format xml -parse "title"
    
    Example 2: apitest -host http://www.imdb.com -res /xml/find -get tt=on -get json=1 -get "q=The walki
    ng dead" -format json -output films.json
    
    Example 3: apitest -host http://google.com -format form -parse "name value type"
