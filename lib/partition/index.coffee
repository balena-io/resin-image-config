Promise = require('bluebird')
_ = require('lodash')
_.str = require('underscore.string')
errors = require('resin-errors')
fileslice = Promise.promisifyAll(require('fileslice'))
bootRecord = require('./boot-record')

SEPARATOR = ':'
SECTOR_SIZE = 512

###*
# @summary Parse a partition definition
# @protected
# @function
#
# @param {String} input - input definition
# @returns {Object} parsed definition
#
# @example
# result = partition.parse('4:1')
# console.log(result)
# > { primary: 4, logical: 1 }
###
exports.parse = (input) ->

	if _.isString(input) and _.isEmpty(input)
		throw new errors.ResinInvalidParameter('input', input, 'empty string')

	if _.str.count(input, SEPARATOR) > 1
		throw new errors.ResinInvalidParameter('input', input, 'multiple separators')

	[ primary, logical ] = String(input).split(SEPARATOR)

	result = {}

	parsedPrimary = _.parseInt(primary)

	if _.isNaN(parsedPrimary)
		throw new Error("Invalid primary partition: #{primary}.")

	result.primary = parsedPrimary if parsedPrimary?

	if logical?
		parsedLogical = _.parseInt(logical)

		if _.isNaN(parsedLogical)
			throw new Error("Invalid logical partition: #{logical}.")

		result.logical = parsedLogical if parsedLogical?

	return result

###*
# @summary Get a partition from a boot record
# @protected
# @function
#
# @param {Object} record - boot record
# @param {Number} number - partition number
# @returns {Object} partition
#
# @example
# result = partition.getPartition(mbr, 1)
###
exports.getPartition = (record, number) ->
	result = record.partitions[number - 1]

	if not result?
		throw new Error("Partition not found: #{number}.")

	return result

###*
# @summary Get a partition offset
# @protected
# @function
#
# @param {Object} partition - partition
# @returns {Number} partition offset
#
# @example
# offset = partition.getPartitionOffset(myPartition)
###
exports.getPartitionOffset = (partition) ->
	return partition.firstLBA * SECTOR_SIZE

###*
# @summary Get the partition size in bytes
# @protected
# @function
#
# @param {Object} partition - partition
# @returns {Number} partition size
#
# @example
# size = partition.getPartitionSize(myPartition)
###
exports.getPartitionSize = (partition) ->
	return partition.sectors * SECTOR_SIZE

###*
# @summary Get a partition object from a definition
# @protected
# @function
#
# @param {String} image - image path
# @param {Object} definition - parition definition
# @returns Promise<Object>
#
# @example
# partition.getPartitionFromDefinition('image.img', partition.parse('4:1')).then (partition) ->
#		console.log(partition)
###
exports.getPartitionFromDefinition = (image, definition) ->
	bootRecord.getMaster(image).then (mbr) ->
		primaryPartition = exports.getPartition(mbr, definition.primary)

		if not definition.logical? or definition.logical is 0
			return primaryPartition

		primaryPartitionOffset = exports.getPartitionOffset(primaryPartition)

		bootRecord.getExtended(image, primaryPartitionOffset).then (ebr) ->

			if not ebr?
				throw new Error("Not an extended partition: #{definition.primary}.")

			logicalPartition = exports.getPartition(ebr, definition.logical)
			logicalPartition.firstLBA += primaryPartition.firstLBA
			return logicalPartition

###*
# @summary Get a partition position
# @protected
# @function
#
# @param {String} image - image path
# @param {Object} definition - parition definition
# @returns Promise<Number>
#
# @example
# partition.getPosition('image.img', partition.parse('4:1')).then (position) ->
#		console.log(position)
###
exports.getPosition = (image, definition) ->
	exports.getPartitionFromDefinition(image, definition)
	.then(exports.getPartitionOffset)

###*
# @summary Copy a partition to a separate file
# @protected
# @function
#
# @param {String} image - image path
# @param {Object} definition - parition definition
# @param {String} output - output path
# @returns Promise<String>
#
# @example
# partition.copyPartition('image.img', partition.parse('4:1'), 'output').then (output) ->
#		console.log(output)
###
exports.copyPartition = (image, definition, output) ->
	exports.getPartitionFromDefinition(image, definition).then (partition) ->
		start = exports.getPartitionOffset(partition)
		end = start + exports.getPartitionSize(partition)
		fileslice.copyAsync(image, output, { start, end })
