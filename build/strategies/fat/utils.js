var Promise, fs, _;

Promise = require('bluebird');

_ = require('lodash');

fs = require('fs');


/**
 * @summary Check if a number is divisible by another number
 * @protected
 * @function
 *
 * @param {Number} x - x
 * @param {Number} y - y
 *
 * @throws If either x or y are zero.
 *
 * @example
 * utils.isDivisibleBy(4, 2)
 */

exports.isDivisibleBy = function(x, y) {
  if (x === 0 || y === 0) {
    throw new Error('Numbers can\'t be zero');
  }
  return !(x % y);
};


/**
 * @summary Copy a file to specific start point of another file
 * @protected
 * @function
 *
 * @description It uses streams.
 *
 * @param {String} file - input file path
 * @param {String} output - output file path
 * @param {Number} start - byte start
 * @returns Promise<String>
 *
 * @example
 * utils.streamFileToPosition('input/file', 'output/file', 1024).then (output) ->
 *		console.log(output)
 */

exports.streamFileToPosition = function(file, output, start, callback) {
  return Promise["try"](function() {
    var inputStream, outputStream;
    inputStream = fs.createReadStream(file);
    outputStream = fs.createWriteStream(output, {
      start: start,
      flags: 'r+'
    });
    inputStream.on('error', Promise.reject);
    outputStream.on('error', Promise.reject);
    outputStream.on('close', function() {
      return Promise.resolve(output);
    });
    return inputStream.pipe(outputStream);
  });
};
