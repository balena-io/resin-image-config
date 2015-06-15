Promise = require('bluebird')
_ = require('lodash')
fs = require('fs')
mockFs = require('mock-fs')
chai = require('chai')
expect = chai.expect
sinon = require('sinon')
chai.use(require('sinon-chai'))
chai.use(require('chai-as-promised'))
bootRecord = require('../../lib/partition/boot-record')

# Dumped MBR from real images downloaded from dashboard.resin.io
rpiMBR = fs.readFileSync('./tests/partition/mbr/rpi.data')
rpi2MBR = fs.readFileSync('./tests/partition/mbr/rpi2.data')
bbbMBR = fs.readFileSync('./tests/partition/mbr/bbb.data')

describe 'Boot Record:', ->

	describe '.read()', ->

		describe 'given a mocked file', ->

			it 'should get the first 512 bytes from the file', (done) ->
				buffer = new Buffer(512)
				buffer.fill(1)

				nullBuffer = new Buffer(1024)
				nullBuffer.fill(0)

				mockFs
					'/my/file': Buffer.concat([ buffer, nullBuffer ])

				bootRecord.read('/my/file').then (data) ->
					mockFs.restore()
					expect(data).to.deep.equal(buffer)
					done()

	describe '.parse()', ->

		describe 'given a non valid MBR', ->

			beforeEach ->
				@mbr = new Buffer(512)
				@mbr.fill(0)

			it 'should throw an error', ->
				expect =>
					bootRecord.parse(@mbr)
				.to.throw(Error)

		describe 'given a rpi MBR', ->

			beforeEach ->
				@mbr = rpiMBR

			it 'should have a partitions array', ->
				result = bootRecord.parse(@mbr)
				expect(_.isArray(result.partitions)).to.be.true

		describe 'given a rpi2 MBR', ->

			beforeEach ->
				@mbr = rpi2MBR

			it 'should have a partitions array', ->
				result = bootRecord.parse(@mbr)
				expect(_.isArray(result.partitions)).to.be.true

		describe 'given a bbb MBR', ->

			beforeEach ->
				@mbr = bbbMBR

			it 'should have a partitions array', ->
				result = bootRecord.parse(@mbr)
				expect(_.isArray(result.partitions)).to.be.true

	describe '.getExtended()', ->

		describe 'given a non ebr is read', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.resolve(new Buffer(512)))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return undefined', ->
				expect(bootRecord.getExtended('image', 512)).to.eventually.equal(undefined)

		describe 'given a valid ebr is read', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.resolve(rpiMBR))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return a parsed boot record', (done) ->
				bootRecord.getExtended('image', 512).then (ebr) ->
					expect(ebr).to.exist
					expect(ebr.partitions).to.be.an.instanceof(Array)
					done()

		describe 'given there was an error reading the ebr', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.reject(new Error('read error')))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return the error', ->
				expect(bootRecord.getExtended('image', 512)).to.be.rejected

	describe '.getMaster()', ->

		describe 'given an invalid mbr is read', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.resolve(new Buffer(512)))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return an error', ->
				expect(bootRecord.getMaster('image')).to.be.rejected

		describe 'given a valid mbr is read', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.resolve(rpiMBR))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return a parsed boot record', (done) ->
				bootRecord.getMaster('image').then (mbr) ->
					expect(mbr).to.exist
					expect(mbr.partitions).to.be.an.instanceof(Array)
					done()

		describe 'given there was an error reading the ebr', ->

			beforeEach ->
				@bootRecordReadStub = sinon.stub(bootRecord, 'read')
				@bootRecordReadStub.returns(Promise.reject(new Error('read error')))

			afterEach ->
				@bootRecordReadStub.restore()

			it 'should return the error', ->
				expect(bootRecord.getMaster('image')).to.be.rejected
