Promise = require('bluebird')
_ = require('lodash')
partition = require('./partition')
strategy = require('./strategies/fat')

###*
# @summary Write files to an image
# @public
# @function
#
# @param {String} image - image path
# @param {Object} data - files data
# @returns Promise<undefined>
#
# @example
#	config.write 'path/to/rpi.img',
#		'4:1':
#			'config.json': JSON.stringify(hello: 'world')
###
exports.write = (imagePath, data, callback) ->
	writePromises = _.map _.pairs(data), (partitionData) ->
		definition = partition.parse(_.first(partitionData))
		return partition.getPosition(imagePath, definition).then (position) ->
			strategy.write(imagePath, _.last(partitionData), position, definition)

	return Promise.all(writePromises).return().nodeify(callback)

###*
# @summary Read files from an image
# @public
# @function
#
# @param {String} image - image path
# @param {Object} data - files data
# @returns Promise<Object>
#
# @example
#	config.read 'path/to/rpi.img',
#		'4:1': [ 'config.json' ]
#	.then (results) ->
#		console.log(results['4:1']['config.json'])
###
exports.read = (imagePath, data, callback) ->
	readPromises = _.map _.pairs(data), (partitionData) ->
		definition = partition.parse(_.first(partitionData))
		return partition.getPosition(imagePath, definition).then (position) ->
			strategy.read(imagePath, _.last(partitionData), position, definition)

	return Promise.all(readPromises).then (results) ->
		return _.object(_.zip(_.keys(data), results))
	.nodeify(callback)
