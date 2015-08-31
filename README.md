resin-image-config
------------------

[![npm version](https://badge.fury.io/js/resin-image-config.svg)](http://badge.fury.io/js/resin-image-config)
[![dependencies](https://david-dm.org/resin-io/resin-image-config.png)](https://david-dm.org/resin-io/resin-image-config.png)
[![Build Status](https://travis-ci.org/resin-io/resin-image-config.svg?branch=master)](https://travis-ci.org/resin-io/resin-image-config)
[![Build status](https://ci.appveyor.com/api/projects/status/s5lom6mul8pxlr80?svg=true)](https://ci.appveyor.com/project/jviotti/resin-image-config)

**DEPRECATED in favor of https://github.com/resin-io/resin-image-fs**

Resin.io image FAT configuration.

Installation
------------

Install `resin-image-config` by running:

```sh
$ npm install --save resin-image-config
```

Documentation
-------------

### config.write(String image, Object files, Function callback)

Write files to an image FAT partitions.

The `files` object contains [Partition Definitions](https://github.com/resin-io/resin-image-config#partition-definition) properties, which contain the files and contents to write.

The callback gets passed one argument: `(error)`.

Example:

```coffee
inject.write 'path/to/rpi.img',
	'4:1':
		'config.json': JSON.stringify(hello: 'world')
	'1':
		'foo.bar': 'Foo bar'
, (error) ->
	throw error if error?
```

### inject.read(String image, Object files, Function callback)

Read files from a image FAT partitions.

The `files` object contains [Partition Definitions](https://github.com/resin-io/resin-image-config#partition-definition) keys, which contain array of files to read.

The callback gets passed two arguments: `(error, results)`.

Example:

```coffee
inject.read 'path/to/rpi.img',
	'4:1': [ 'config.json' ]
, (error, results) ->
	throw error if error?
	console.log(JSON.parse(results['4:1']['config.json']))
```

Partition Definition
--------------------

A partition definition is a number or string representing the primary partition number, or an extended partition number along with a logical partition number.

Notice that this definition is device dependent. Refer to specific device bundles for this information.

Examples:

- `4` is the primary partition number four.
- `3:1` is the first logical partition of the third primary extended partition.

Tests
-----

Run the test suite by doing:

```sh
$ gulp test
```

Contribute
----------

- Issue Tracker: [github.com/resin-io/resin-image-config/issues](https://github.com/resin-io/resin-image-config/issues)
- Source Code: [github.com/resin-io/resin-image-config](https://github.com/resin-io/resin-image-config)

Before submitting a PR, please make sure that you include tests, and that [coffeelint](http://www.coffeelint.org/) runs without any warning:

```sh
$ gulp lint
```

Support
-------

If you're having any problem, please [raise an issue](https://github.com/resin-io/resin-image-config/issues/new) on GitHub.

License
-------

The project is licensed under the MIT license.
