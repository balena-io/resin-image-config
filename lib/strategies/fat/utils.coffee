Promise = require('bluebird')
_ = require('lodash')
fs = require('fs')

###*
# @summary Check if a number is divisible by another number
# @protected
# @function
#
# @param {Number} x - x
# @param {Number} y - y
#
# @throws If either x or y are zero.
#
# @example
# utils.isDivisibleBy(4, 2)
###
exports.isDivisibleBy = (x, y) ->
	if x is 0 or y is 0
		throw new Error('Numbers can\'t be zero')

	return not (x % y)

###*
# @summary Copy a file to specific start point of another file
# @protected
# @function
#
# @description It uses streams.
#
# @param {String} file - input file path
# @param {String} output - output file path
# @param {Number} start - byte start
# @returns Promise<String>
#
# @example
# utils.streamFileToPosition('input/file', 'output/file', 1024).then (output) ->
#		console.log(output)
###
exports.streamFileToPosition = (file, output, start, callback) ->
	Promise.try ->
		inputStream = fs.createReadStream(file)
		outputStream = fs.createWriteStream output,
			start: start

			# The default flag is 'w', which replaces the whole file
			flags: 'r+'

		inputStream.on('error', Promise.reject)
		outputStream.on('error', Promise.reject)

		outputStream.on 'close', ->
			Promise.resolve(output)

		inputStream.pipe(outputStream)
