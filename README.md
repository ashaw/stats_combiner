# StatsCombiner

StatsCombiner is a ruby gem for generating most viewed widgets based on the Chartbeat API. Unlike most analytics systems, Chartbeat doesn't give you cumulative visitor counts. Rather, they take snapshots of people sitting on pages at a given time. StatsCombiner asks Chartbeat what these numbers are n times during a given `ttl` and combines visitor counts where it finds matching `<title>`s allowing popular stories to bubble up the list. When `ttl` expires, it will publish out a static HTML file with your top ten list, dump the database and start collecting again.

## Installation

`gem install stats_combiner`

## Usage

## Author

Al Shaw

## License (MIT)

Copyright (c) 2010 TPM Media LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.