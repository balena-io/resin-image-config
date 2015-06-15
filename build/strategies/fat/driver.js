var Promise, SECTOR_SIZE, fatfs, fs, utils;

Promise = require('bluebird');

fs = Promise.promisifyAll(require('fs'));

fatfs = require('fatfs');

utils = require('./utils');

SECTOR_SIZE = 512;


/**
 * @summary Get a fatfs driver given a file descriptor
 * @protected
 * @function
 *
 * @param {Object} fd - file descriptor
 * @param {Number} size - size of the image
 * @param {Number} sectorSize - sector size
 * @returns {Object} the fatfs driver
 *
 * @example
 * fatDriver = driver.getDriver(fd, 2048, 512)
 */

exports.getDriver = function(fd, size, sectorSize) {
  return {
    sectorSize: sectorSize,
    numSectors: size / sectorSize,
    readSectors: function(sector, dest, callback) {
      var destLength;
      destLength = dest.length;
      if (!utils.isDivisibleBy(destLength, sectorSize)) {
        throw Error('Unexpected buffer length!');
      }
      return fs.read(fd, dest, 0, destLength, sector * sectorSize, function(error, bytesRead, buffer) {
        return callback(error, buffer);
      });
    },
    writeSectors: function(sector, data, callback) {
      var dataLength;
      dataLength = data.length;
      if (!utils.isDivisibleBy(dataLength, sectorSize)) {
        throw Error('Unexpected buffer length!');
      }
      return fs.write(fd, data, 0, dataLength, sector * sectorSize, callback);
    }
  };
};


/**
 * @summary Get a fatfs driver from a file
 * @protected
 * @function
 *
 * @param {String} file - file path
 * @returns Promise<Object>
 *
 * @todo Test this.
 *
 * @example
 * driver.createDriverFromFile('my/file').then (driver) ->
 *		console.log(driver)
 */

exports.createDriverFromFile = function(file, callback) {
  return fs.openAsync(file, 'r+').then(function(fd) {
    return fs.fstatAsync(fd).then(function(stats) {
      var driver;
      driver = exports.getDriver(fd, stats.size, SECTOR_SIZE);
      return fatfs.createFileSystem(driver);
    });
  });
};
