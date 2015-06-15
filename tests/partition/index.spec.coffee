Promise = require('bluebird')
_ = require('lodash')
chai = require('chai')
expect = chai.expect
sinon = require('sinon')
chai.use(require('sinon-chai'))
chai.use(require('chai-as-promised'))
errors = require('resin-errors')
partition = require('../../lib/partition/index')
bootRecord = require('../../lib/partition/boot-record')

describe 'Partition:', ->

	describe '.parse()', ->

		describe 'given a single primary partition', ->

			describe 'given is described as a number', ->

				beforeEach ->
					@partition = 4

				it 'should return the correct representation', ->
					expect(partition.parse(@partition)).to.deep.equal
						primary: 4

			describe 'given is described as a string', ->

				beforeEach ->
					@partition = '4'

				it 'should return the correct representation', ->
					expect(partition.parse(@partition)).to.deep.equal
						primary: 4

		describe 'given a primary and logical partition', ->

			beforeEach ->
				@partition = '3:1'

			it 'should return the correct representation', ->
				expect(partition.parse(@partition)).to.deep.equal
					primary: 3
					logical: 1

		describe 'given non parseable primary number', ->

			beforeEach ->
				@partition = 'hello'

			it 'should throw an error', ->
				expect =>
					partition.parse(@partition)
				.to.throw('Invalid primary partition: hello.')

		describe 'given non parseable logical number', ->

			beforeEach ->
				@partition = '1:hello'

			it 'should throw an error', ->
				expect =>
					partition.parse(@partition)
				.to.throw('Invalid logical partition: hello.')

		describe 'given an empty string', ->

			beforeEach ->
				@partition = ''

			it 'should throw an error', ->
				expect =>
					partition.parse(@partition)
				.to.throw(errors.ResinInvalidParameter)

		describe 'given multiple separators', ->

			beforeEach ->
				@partition = '3::1'

			it 'should throw an error', ->
				expect =>
					partition.parse(@partition)
				.to.throw(errors.ResinInvalidParameter)

	describe '.getPartition()', ->

		describe 'given a record with partitions', ->

			beforeEach ->
				@record =
					partitions: [
						{ info: 'first' }
						{ info: 'second' }
					]

			it 'should retrieve an existing partition', ->
				result = partition.getPartition(@record, 1)
				expect(result.info).to.equal('first')

			it 'should throw if partition does not exist', ->
				expect =>
					partition.getPartition(@record, 5)
				.to.throw('Partition not found: 5.')

	describe '.getPartitionOffset()', ->

		it 'should multiply firstLBA with 512', ->
			result = partition.getPartitionOffset(firstLBA: 512)
			expect(result).to.equal(262144)

	describe '.getPartitionSize()', ->

		describe 'given a raspberry pi 1 config partition', ->

			beforeEach ->
				@partition =
					sectors: 8192

			it 'should return the correct byte size', ->
				expect(partition.getPartitionSize(@partition)).to.equal(4194304)

	describe '.getPartitionFromDefinition()', ->

		describe 'given an invalid primary partition', ->

			beforeEach ->
				@bootRecordGetMasterStub = sinon.stub(bootRecord, 'getMaster')
				@bootRecordGetMasterStub.returns Promise.resolve
					partitions: [
						{ firstLBA: 256, info: 'first' }
						{ firstLBA: 512, info: 'second' }
					]

			afterEach ->
				@bootRecordGetMasterStub.restore()

			it 'should return an error', ->
				expect(partition.getPartitionFromDefinition('image', primary: 5)).to.be.rejectedWith('Partition not found: 5.')

		describe 'given a valid primary partition', ->

			beforeEach ->
				@bootRecordGetMasterStub = sinon.stub(bootRecord, 'getMaster')
				@bootRecordGetMasterStub.returns Promise.resolve
					partitions: [
						{ firstLBA: 256, info: 'first' }
						{ firstLBA: 512, info: 'second' }
					]

			afterEach ->
				@bootRecordGetMasterStub.restore()

			it 'should return the primary partition if no logical partition', ->
				promise = partition.getPartitionFromDefinition('image', { primary: 1 })
				expect(promise).to.become
					firstLBA: 256
					info: 'first'

			it 'should return the primary partition if logical partition is zero', ->
				promise = partition.getPartitionFromDefinition('image', { primary: 1, logical: 0 })
				expect(promise).to.become
					firstLBA: 256
					info: 'first'

			describe 'given partition is not extended', ->

				beforeEach ->
					@bootRecordGetExtendedStub = sinon.stub(bootRecord, 'getExtended')
					@bootRecordGetExtendedStub.returns(Promise.resolve(undefined))

				afterEach ->
					@bootRecordGetExtendedStub.restore()

				it 'should return an error', ->
					promise = partition.getPartitionFromDefinition('image', { primary: 1, logical: 2 })
					expect(promise).to.be.rejectedWith('Not an extended partition: 1.')

			describe 'given partition is extended', ->

				beforeEach ->
					@bootRecordGetExtendedStub = sinon.stub(bootRecord, 'getExtended')
					@bootRecordGetExtendedStub.returns Promise.resolve
						partitions: [
							{ firstLBA: 1024, info: 'third' }
							{ firstLBA: 2048, info: 'fourth' }
						]

				afterEach ->
					@bootRecordGetExtendedStub.restore()

				it 'should return an error if partition was not found', ->
					promise = partition.getPartitionFromDefinition('image', { primary: 1, logical: 3 })
					expect(promise).to.be.rejectedWith('Partition not found: 3.')

				it 'should return the logical partition', ->
					promise = partition.getPartitionFromDefinition('image', { primary: 1, logical: 2 })
					expect(promise).to.become
						firstLBA: 2304
						info: 'fourth'

	describe '.getPosition()', ->

		describe 'given a partition was found', ->

			beforeEach ->
				@partitionGetPartitionFromDefinitionStub = sinon.stub(partition, 'getPartitionFromDefinition')
				@partitionGetPartitionFromDefinitionStub.returns(Promise.resolve(firstLBA: 512))

			afterEach ->
				@partitionGetPartitionFromDefinitionStub.restore()

			it 'should return the correct position', ->
				promise = partition.getPosition('image.img', { primary: 3, logical: 1 })
				expect(promise).to.eventually.equal(512 * 512)

		describe 'given a partition was not found', ->

			beforeEach ->
				@partitionGetPartitionFromDefinitionStub = sinon.stub(partition, 'getPartitionFromDefinition')
				@partitionGetPartitionFromDefinitionStub.returns(Promise.reject(new Error('Partition not found: 3.')))

			afterEach ->
				@partitionGetPartitionFromDefinitionStub.restore()

			it 'should return an error', ->
				promise = partition.getPosition('image.img', { primary: 3, logical: 1 })
				expect(promise).to.be.rejectedWith('Partition not found: 3.')

	describe '.copyPartition()', ->

		describe 'given a partition not was found', ->

			beforeEach ->
				@partitionGetPartitionFromDefinitionStub = sinon.stub(partition, 'getPartitionFromDefinition')
				@partitionGetPartitionFromDefinitionStub.returns(Promise.reject(new Error('Partition not found: 3.')))

			afterEach ->
				@partitionGetPartitionFromDefinitionStub.restore()

			it 'should return an error', ->
				promise = partition.copyPartition('image', { primary: 3, logical: 1 }, 'output')
				expect(promise).to.be.rejectedWith('Partition not found: 3.')
