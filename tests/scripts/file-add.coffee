assert = require('assert')
crypto = require('crypto')
imageConfig = require('../../lib/config')

# File addition test.
# It adds new files to the boot and config
# partitions.
# Meant to be run with images that have the
# config partition as the 5th partition and
# images that have a 1st boot FAT partition.

image = process.argv[2]

if not image?
	console.error('Missing device image')
	process.exit(1)

getRandomFileName = ->
	return "_temp#{crypto.randomBytes(4).readUInt32LE(0)}"

FILENAME1 = getRandomFileName()
FILENAME2 = getRandomFileName()

writeFiles =
	'4:1': {}
	'1': {}

writeFiles['4:1'][FILENAME1] = 'Filename 1'
writeFiles['1'][FILENAME2] = 'Filename 2'

imageConfig.read image,
	'4:1': [ FILENAME1 ]
	'1': [ FILENAME2 ]
.then (results) ->
	assert.equal(results['4:1'][FILENAME1], undefined, 'Filename 1 does not exist')
	assert.equal(results['1'][FILENAME2], undefined, 'Filename 2 does not exist')

	return imageConfig.write(image, writeFiles).then ->
		return imageConfig.read image,
			'4:1': [ FILENAME1 ]
			'1': [ FILENAME2 ]
.then (results) ->
	assert.equal(results['4:1'][FILENAME1], 'Filename 1', 'Filename 1 was created')
	assert.equal(results['1'][FILENAME2], 'Filename 2', 'Filename 2 was created')

.then ->
	console.log('SUCCESS')
	process.exit(0)

.catch (error) ->
	console.error("ERROR: #{error.message}")
	process.exit(1)
