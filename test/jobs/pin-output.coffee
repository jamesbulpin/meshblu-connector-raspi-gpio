{job} = require '../../jobs/pin-output'
debug = require('debug')('meshblu-connector-raspi-gpio:test')
simple = require('simple-mock')

class MockConnector
  writePin: (name, value) =>
    debug 'mocking the connector writePin', name, value

describe 'PinOutput', ->
  context 'when given a valid message', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message =
        data:
          pinname: 'testname'
          value: '1'
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        done()

    it 'should not error', ->
      expect(@error).not.to.exist

  context 'when given an invalid message', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message = {}
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        done()

    it 'should error', ->
      expect(@error).to.exist
