fs = require('fs')
_ = require('lodash')
chai = require('chai')
expect = chai.expect
sinon = require('sinon')
chai.use(require('sinon-chai'))
utils = require('../../../lib/strategies/fat/utils')

describe 'Utils:', ->

	describe '.isDivisibleBy()', ->

		it 'should return true if the number is divisible', ->
			expect(utils.isDivisibleBy(4, 2)).to.be.true
			expect(utils.isDivisibleBy(6, 3)).to.be.true
			expect(utils.isDivisibleBy(1, 1)).to.be.true

		it 'should return false if the number is not divisible', ->
			expect(utils.isDivisibleBy(4, 3)).to.be.false
			expect(utils.isDivisibleBy(6, 4)).to.be.false
			expect(utils.isDivisibleBy(1, 5)).to.be.false

		it 'should throw if any number is zero', ->
			expect ->
				utils.isDivisibleBy(0, 2)
			.to.throw('Numbers can\'t be zero')

			expect ->
				utils.isDivisibleBy(2, 0)
			.to.throw('Numbers can\'t be zero')
