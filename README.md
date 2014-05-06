Charge
------

[![npm](http://img.shields.io/npm/v/charge.svg?style=flat)](https://badge.fury.io/js/charge) [![tests](http://img.shields.io/travis/carrot/charge/master.svg?style=flat)](https://travis-ci.org/carrot/charge) [![dependencies](http://img.shields.io/gemnasium/carrot/charge.svg?style=flat)](https://david-dm.org/carrot/charge)

A collection of useful middleware and tools for serving static sites.

> **Note:** This project is in early development, and versioning is a little different. [Read this](http://markup.im/#q4_cRZ1Q) for more details.

### Why should you care?

If you are serving a static site through node, we all know you can use [connect]() or [express]()'s static serving capabilities. In both cases, this is actually the [serve-static]() module behind the scenes. And while this does a wonderful job of quickly serving up a directory, for those heavily using static sites in production, there are many other utilities still to be desired. For example, imagine if:

- You didn't have to use '.html' at the end of each url
- You could add in custom routes and redirects (very handy for SPA)
- You could slot in a custom error page if there was a 404
- You could easily add http basic auth for a site in staging mode
- You could tightly control browser cacheing
- You could make certain files are inaccessible via the server, but still exist in the project
- You could inject a piece of markup or a script into any page before it's served

All of these things would be great, but are conveniences you usually expect from a dynamic, not a static site. These are just some of the capabilities of charge, a server for those who are serious about static sites.

### Installation

`npm install charge -g`

### Usage

Charge was built from the ground up to be as flexible as possible. At its core, charge is simply a collection of middleware packages, each of which is available as its own module as well. You can access each of these packages on the `Charge` class itself if you'd like to use and configure them entirely on your own:

```js
var Charge = require('charge');

Charge.hygienist // (clean urls) https://github.com/carrot/hygienist-middleware
Charge.apologist // (custom error pages) https://github.com/carrot/apologist-middleware
Charge.escapist // (ignore files) https://github.com/carrot/escapist-middleware
Charge.archivist // (cache control) https://github.com/carrot/archivist-middleware
Charge.pathologist // (custom routes) https://github.com/carrot/pathologist-middleware
Charge.publicist // (basic auth) https://github.com/visionmedia/node-basic-auth
Charge.journalist // (inject content) https://github.com/samccone/infestor
```

Each of these expose a function that accepts the `root` of the site you are serving as the first argument, and an options object as the second, and returns a middleware function (compatible with [connect](http://www.senchalabs.org/connect/), [express](http://expressjs.com/4x/api.html#middleware) and similar middleware stacks). See the individual repos for details on the options.

You can also instantiate the `Charge` class, which creates a `connect` instance with all the middleware described previously already added. The constructor takes a `root` path and an options object which represents options for each of the middleware merged together. As is the case with any connect object, you can pass this to `http.createServer` to create a server:

```js
var Charge = require('charge'),
    http = require('http');

// a charge instance is just a connect instance, so you can add more middleware
// or do anything else you would with a connect server here if you want
var app = new Charge('./public', { option: 'value' });
app.use(some_other_middleware);

http.createServer(app).listen(1111);
```

#### Middleware Stack

- `Charge.hygienist` (clean urls)  
https://github.com/carrot/hygienist-middleware

- `Charge.apologist` (custom error pages)   https://github.com/carrot/apologist-middleware

- `Charge.escapist` (ignore files)  
https://github.com/carrot/escapist-middleware

- `Charge.archivist` (cache control)  
https://github.com/carrot/archivist-middleware

- `Charge.pathologist` (custom routes)  
https://github.com/carrot/pathologist-middleware

- `Charge.publicist` (basic auth)  
https://github.com/visionmedia/node-basic-auth

- `Charge.journalist` (inject content)  
https://github.com/samccone/infestor


#### Options

Charge accepts options for each piece of middleware that it unifies (which is a bunch). Since this can end up being a large options object, you can alternately structure your options in a json file that you pass as a string.

```js
{
  "clean_urls": true,
  "error_page": "error.html",
  "auth": "username:password"
}
```

```js
var app = new Charge('./public', '/path/to/config.json' );
```

We've done our best to make these options interoperable with [divshot.io's configuration interface](http://docs.divshot.com/guides/configuration) so that it can be seamlessly deployed to their wonderful static hosting environment.

For the most up-to-date reference of options for each middleware be sure to check out their [individual project repos](#middleware-stack).

#### Methods

##### start(opts)
Accepts `port`, which defaults to `1111`, and returns a promise for the instantiated server.

##### stop()
Closes the server and stops it from running.

##### send(message)
Sends a string or object of your choice via websockets. If you pass an object, it will be stringified, so you'll want to run it through `JSON.parse` on the other end. You can add a websocket listener at `ws://host/path/ws` (or `wss://` if https) to recieve these messages. If you have multiple windows or devices open to the same page, charge keeps track of all sockets and sends messages to all of them.

You can use any of these methods on the `server` object returned by the promise from calling `app.start()`.

### Using Websockets

Getting websockets set up can be a little confusing if you've never done it before. Luckily, charge abstracts away as much as is possible -- it's simple to send any message you need to any number of connected sockets using the `send` method seen above. All you need to do is configure your client-side javascript to recieve the messages. You can see an example of this [here](#).

Charge can create a server for you that is enhanced with utilities for interacting with the page via websockets. This is a great way to make a static page more dynamic by receiving information from the server and handling it with javascript. For example:

```js
var Charge = require('charge'),
    http = require('http');

var app = new Charge('./public', { option: 'value' });

app.start({ port: 1111 }).then(function(server){
  // the `server` object is just a node http server, decorated with a few extra
  // methods as demonstrated below
  server.send('hello from the server!');
});
```

### Command Line Interface

Using charge from the command line will use all the default settings and fire up a server in either the current working directory or a path if provided as a positional argument. For example:

```
$ charge # starts a server in `pwd`
$ charge /path/to/project # starts a server at the provided path
```

Since charge has the ability to take a lot of options, it might be best to utilize the [configuration file option](#options) when running from the command line.

Charge, of course, also plays nicely with [Foreman](https://github.com/ddollar/foreman) (and it's equivalents). For example, your `Procfile` might look something like this:

```
# Procfile
web:   charge public -c server.json
redis: redis-server
```

##### CLI Options

```
--config, -c: path to a configuration file
--port, -p: port to start the server on, default 1111
```

### License & Contributing

- Details on the license [can be found here](LICENSE.md)
- Details on running tests and contributing [can be found here](contributing.md)