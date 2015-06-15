_ = require('lodash')
chai = require('chai')
expect = chai.expect
errors = require('resin-errors')
driver = require('../../../lib/strategies/fat/driver')

describe 'FAT Driver:', ->

	describe '.getDriver()', ->

		describe 'given a valid driver', ->

			beforeEach ->
				@driver = driver.getDriver({}, 2048, 512)

			it 'should have .sectorSize', ->
				expect(@driver.sectorSize).to.equal(512)

			it 'should have .numSectors', ->
				expect(@driver.numSectors).to.equal(4)
