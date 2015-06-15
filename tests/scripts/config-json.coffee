assert = require('assert')
imageConfig = require('../../lib/config')

# Config injection test.
# Meant to be run with images that have the
# config partition as the 5th partition, such
# as the Raspberry Pi and BeagleBone Black.

image = process.argv[2]

if not image?
	console.error('Missing device image')
	process.exit(1)

imageConfig.read image,
	'4:1': [ 'config.json' ]
.then (results) ->
	config = JSON.parse(results['4:1']['config.json'])
	assert(typeof config is 'object', 'config is an object')
	console.info(config)
	assert(not config.foo?, 'foo does not exist')
	config.foo = 'bar'

	return imageConfig.write image,
		'4:1':
			'config.json': JSON.stringify(config)

.then ->
	return imageConfig.read image,
		'4:1': [ 'config.json' ]

.then (results) ->
	config = JSON.parse(results['4:1']['config.json'])
	console.info(config)
	assert.equal(config.foo, 'bar', 'foo is equal to "bar"')
	delete config.foo
	return imageConfig.write image,
		'4:1':
			'config.json': JSON.stringify(config)

.then ->
	return imageConfig.read image,
		'4:1': [ 'config.json' ]

.then (results) ->
	config = JSON.parse(results['4:1']['config.json'])
	console.info(config)
	assert(not config.foo?, 'foo does not exist')

.then ->
	console.log('SUCCESS')
	process.exit(0)

.catch (error) ->
	console.error("ERROR: #{error.message}")
	process.exit(1)
