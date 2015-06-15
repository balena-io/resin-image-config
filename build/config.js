var Promise, partition, strategy, _;

Promise = require('bluebird');

_ = require('lodash');

partition = require('./partition');

strategy = require('./strategies/fat');


/**
 * @summary Write files to an image
 * @public
 * @function
 *
 * @param {String} image - image path
 * @param {Object} data - files data
 * @returns Promise<undefined>
 *
 * @example
 *	config.write 'path/to/rpi.img',
 *		'4:1':
 *			'config.json': JSON.stringify(hello: 'world')
 */

exports.write = function(imagePath, data, callback) {
  var writePromises;
  writePromises = _.map(_.pairs(data), function(partitionData) {
    var definition;
    definition = partition.parse(_.first(partitionData));
    return partition.getPosition(imagePath, definition).then(function(position) {
      return strategy.write(imagePath, _.last(partitionData), position, definition);
    });
  });
  return Promise.all(writePromises)["return"]().nodeify(callback);
};


/**
 * @summary Read files from an image
 * @public
 * @function
 *
 * @param {String} image - image path
 * @param {Object} data - files data
 * @returns Promise<Object>
 *
 * @example
 *	config.read 'path/to/rpi.img',
 *		'4:1': [ 'config.json' ]
 *	.then (results) ->
 *		console.log(results['4:1']['config.json'])
 */

exports.read = function(imagePath, data, callback) {
  var readPromises;
  readPromises = _.map(_.pairs(data), function(partitionData) {
    var definition;
    definition = partition.parse(_.first(partitionData));
    return partition.getPosition(imagePath, definition).then(function(position) {
      return strategy.read(imagePath, _.last(partitionData), position, definition);
    });
  });
  return Promise.all(readPromises).then(function(results) {
    return _.object(_.zip(_.keys(data), results));
  }).nodeify(callback);
};
