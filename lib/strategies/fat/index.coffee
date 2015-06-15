Promise = require('bluebird')
_ = require('lodash')
tmp = Promise.promisifyAll(require('tmp'))
fatDriver = require('./driver')
utils = require('./utils')
partition = require('../../partition')

tmp.setGracefulCleanup()

performOnFATPartition = (imagePath, definition) ->
	tmp.fileAsync(prefix: 'resin-').spread (path, fd, cleanupCallback) ->
		partition.copyPartition(imagePath, definition, path).then ->
			return fatDriver.createDriverFromFile(path)
		.then (driver) ->
			return [ driver, path, cleanupCallback ]

###*
# @summary Read a config object from an image
# @protected
# @function
#
# @param {String} imagePath - image path
# @param {String[]} files - file names
# @param {Number} position - config partition position
# @param {Object} definition - partition definition
# @returns Promise<Object>
#
# @todo Test this function
#
# @example
# strategy.read 'my/image.img', [ 'config.json' ], 2048,
#		primary: 4
#		logical: 1
#	.then (results) ->
#		console.log(results['config.json'])
###
exports.read = (imagePath, files, position, definition) ->
	performOnFATPartition(imagePath, definition).spread (driver, path, cleanupCallback) ->

		filesPromises = _.map files, (file) ->
			return Promise.fromNode (callback) ->
				driver.readFile(file, encoding: 'utf8', callback)
			.catch (error) ->
				if error.code is 'NOENT'
					return Promise.resolve(undefined)
				return Promise.reject(error)

		Promise.all(filesPromises).then (contents) ->
			cleanupCallback()
			return _.object(_.zip(files, contents))

###*
# @summary Write a config object to an image
# @protected
# @function
#
# @param {String} imagePath - image path
# @param {Object} data - file data
# @param {Number} position - config partition position
# @param {Object} definition - partition definition
# @returns Promise<undefined>
#
# @todo Test this function
#
# @example
# strategy.write 'my/image.img',
#		'config.json': JSON.stringify(hello: 'world')
#	, 2048,
#		primary: 4
#		logical: 1
###
exports.write = (imagePath, files, position, definition) ->
	performOnFATPartition(imagePath, definition).spread (driver, path, cleanupCallback) ->

		filesPromises = _.map _.pairs(files), (file) ->
			return Promise.fromNode (callback) ->
				return driver.writeFile(_.first(file), _.last(file), callback)

		Promise.all(filesPromises).then ->
			return utils.streamFileToPosition(path, imagePath, position)
		.then ->
			cleanupCallback()
