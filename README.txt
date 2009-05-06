= ApacheLookup

* http://github.com/illuminerdi/apache_lookup

== DESCRIPTION:

A command line tool for changing an Apache log so that IP Addresses are replaced with fully resolved domain names.

== FEATURES/PROBLEMS:

* Command line tool safely modifies files.
* IP Address at beginning of line for log file is changed.
* Multithreaded! (Default of 5 threads.)
* Maintains log order.
* Caches name lookups across invocations.
* Cached name lookups expire after 1 day.
* Pure standard library!

== SYNOPSIS:

  # Pretty simple, just point the application at your log file:
  $ apache_lookup my_logs.log
  
  # Or you can specify a number of threads for the process:
  $ apache_lookup -t 100 my_logs.log

== REQUIREMENTS:

* ruby 1.8.6+
* Flexmock 0.8.5 (for the testings)

== INSTALL:

* grab source and DIY! :P (not ready for rubygemage)

== LICENSE:

(The MIT License)

Copyright (c) 2009 Joshua Clingenpeel

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
