var Promise, fatDriver, partition, performOnFATPartition, tmp, utils, _;

Promise = require('bluebird');

_ = require('lodash');

tmp = Promise.promisifyAll(require('tmp'));

fatDriver = require('./driver');

utils = require('./utils');

partition = require('../../partition');

tmp.setGracefulCleanup();

performOnFATPartition = function(imagePath, definition) {
  return tmp.fileAsync({
    prefix: 'resin-'
  }).spread(function(path, fd, cleanupCallback) {
    return partition.copyPartition(imagePath, definition, path).then(function() {
      return fatDriver.createDriverFromFile(path);
    }).then(function(driver) {
      return [driver, path, cleanupCallback];
    });
  });
};


/**
 * @summary Read a config object from an image
 * @protected
 * @function
 *
 * @param {String} imagePath - image path
 * @param {String[]} files - file names
 * @param {Number} position - config partition position
 * @param {Object} definition - partition definition
 * @returns Promise<Object>
 *
 * @todo Test this function
 *
 * @example
 * strategy.read 'my/image.img', [ 'config.json' ], 2048,
 *		primary: 4
 *		logical: 1
 *	.then (results) ->
 *		console.log(results['config.json'])
 */

exports.read = function(imagePath, files, position, definition) {
  return performOnFATPartition(imagePath, definition).spread(function(driver, path, cleanupCallback) {
    var filesPromises;
    filesPromises = _.map(files, function(file) {
      return Promise.fromNode(function(callback) {
        return driver.readFile(file, {
          encoding: 'utf8'
        }, callback);
      })["catch"](function(error) {
        if (error.code === 'NOENT') {
          return Promise.resolve(void 0);
        }
        return Promise.reject(error);
      });
    });
    return Promise.all(filesPromises).then(function(contents) {
      cleanupCallback();
      return _.object(_.zip(files, contents));
    });
  });
};


/**
 * @summary Write a config object to an image
 * @protected
 * @function
 *
 * @param {String} imagePath - image path
 * @param {Object} data - file data
 * @param {Number} position - config partition position
 * @param {Object} definition - partition definition
 * @returns Promise<undefined>
 *
 * @todo Test this function
 *
 * @example
 * strategy.write 'my/image.img',
 *		'config.json': JSON.stringify(hello: 'world')
 *	, 2048,
 *		primary: 4
 *		logical: 1
 */

exports.write = function(imagePath, files, position, definition) {
  return performOnFATPartition(imagePath, definition).spread(function(driver, path, cleanupCallback) {
    var filesPromises;
    filesPromises = _.map(_.pairs(files), function(file) {
      return Promise.fromNode(function(callback) {
        return driver.writeFile(_.first(file), _.last(file), callback);
      });
    });
    return Promise.all(filesPromises).then(function() {
      return utils.streamFileToPosition(path, imagePath, position);
    }).then(function() {
      return cleanupCallback();
    });
  });
};
