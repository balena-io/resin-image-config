var Promise, SECTOR_SIZE, SEPARATOR, bootRecord, errors, fileslice, _;

Promise = require('bluebird');

_ = require('lodash');

_.str = require('underscore.string');

errors = require('resin-errors');

fileslice = Promise.promisifyAll(require('fileslice'));

bootRecord = require('./boot-record');

SEPARATOR = ':';

SECTOR_SIZE = 512;


/**
 * @summary Parse a partition definition
 * @protected
 * @function
 *
 * @param {String} input - input definition
 * @returns {Object} parsed definition
 *
 * @example
 * result = partition.parse('4:1')
 * console.log(result)
 * > { primary: 4, logical: 1 }
 */

exports.parse = function(input) {
  var logical, parsedLogical, parsedPrimary, primary, result, _ref;
  if (_.isString(input) && _.isEmpty(input)) {
    throw new errors.ResinInvalidParameter('input', input, 'empty string');
  }
  if (_.str.count(input, SEPARATOR) > 1) {
    throw new errors.ResinInvalidParameter('input', input, 'multiple separators');
  }
  _ref = String(input).split(SEPARATOR), primary = _ref[0], logical = _ref[1];
  result = {};
  parsedPrimary = _.parseInt(primary);
  if (_.isNaN(parsedPrimary)) {
    throw new Error("Invalid primary partition: " + primary + ".");
  }
  if (parsedPrimary != null) {
    result.primary = parsedPrimary;
  }
  if (logical != null) {
    parsedLogical = _.parseInt(logical);
    if (_.isNaN(parsedLogical)) {
      throw new Error("Invalid logical partition: " + logical + ".");
    }
    if (parsedLogical != null) {
      result.logical = parsedLogical;
    }
  }
  return result;
};


/**
 * @summary Get a partition from a boot record
 * @protected
 * @function
 *
 * @param {Object} record - boot record
 * @param {Number} number - partition number
 * @returns {Object} partition
 *
 * @example
 * result = partition.getPartition(mbr, 1)
 */

exports.getPartition = function(record, number) {
  var result;
  result = record.partitions[number - 1];
  if (result == null) {
    throw new Error("Partition not found: " + number + ".");
  }
  return result;
};


/**
 * @summary Get a partition offset
 * @protected
 * @function
 *
 * @param {Object} partition - partition
 * @returns {Number} partition offset
 *
 * @example
 * offset = partition.getPartitionOffset(myPartition)
 */

exports.getPartitionOffset = function(partition) {
  return partition.firstLBA * SECTOR_SIZE;
};


/**
 * @summary Get the partition size in bytes
 * @protected
 * @function
 *
 * @param {Object} partition - partition
 * @returns {Number} partition size
 *
 * @example
 * size = partition.getPartitionSize(myPartition)
 */

exports.getPartitionSize = function(partition) {
  return partition.sectors * SECTOR_SIZE;
};


/**
 * @summary Get a partition object from a definition
 * @protected
 * @function
 *
 * @param {String} image - image path
 * @param {Object} definition - parition definition
 * @returns Promise<Object>
 *
 * @example
 * partition.getPartitionFromDefinition('image.img', partition.parse('4:1')).then (partition) ->
 *		console.log(partition)
 */

exports.getPartitionFromDefinition = function(image, definition) {
  return bootRecord.getMaster(image).then(function(mbr) {
    var primaryPartition, primaryPartitionOffset;
    primaryPartition = exports.getPartition(mbr, definition.primary);
    if ((definition.logical == null) || definition.logical === 0) {
      return primaryPartition;
    }
    primaryPartitionOffset = exports.getPartitionOffset(primaryPartition);
    return bootRecord.getExtended(image, primaryPartitionOffset).then(function(ebr) {
      var logicalPartition;
      if (ebr == null) {
        throw new Error("Not an extended partition: " + definition.primary + ".");
      }
      logicalPartition = exports.getPartition(ebr, definition.logical);
      logicalPartition.firstLBA += primaryPartition.firstLBA;
      return logicalPartition;
    });
  });
};


/**
 * @summary Get a partition position
 * @protected
 * @function
 *
 * @param {String} image - image path
 * @param {Object} definition - parition definition
 * @returns Promise<Number>
 *
 * @example
 * partition.getPosition('image.img', partition.parse('4:1')).then (position) ->
 *		console.log(position)
 */

exports.getPosition = function(image, definition) {
  return exports.getPartitionFromDefinition(image, definition).then(exports.getPartitionOffset);
};


/**
 * @summary Copy a partition to a separate file
 * @protected
 * @function
 *
 * @param {String} image - image path
 * @param {Object} definition - parition definition
 * @param {String} output - output path
 * @returns Promise<String>
 *
 * @example
 * partition.copyPartition('image.img', partition.parse('4:1'), 'output').then (output) ->
 *		console.log(output)
 */

exports.copyPartition = function(image, definition, output) {
  return exports.getPartitionFromDefinition(image, definition).then(function(partition) {
    var end, start;
    start = exports.getPartitionOffset(partition);
    end = start + exports.getPartitionSize(partition);
    return fileslice.copyAsync(image, output, {
      start: start,
      end: end
    });
  });
};
