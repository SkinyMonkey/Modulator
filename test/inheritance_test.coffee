_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Modulator = require '../'

client = null
ATestResource = null

class TestRoute extends Modulator.Route

describe 'Modulator Inheritance', ->

  before (done) ->
    Modulator.Reset ->
      class ATestResource extends Modulator.Resource 'atest', {abstract: true}
        FetchByName: (name, done) ->
          @table.FindWhere '*', {name: name}, (err, blob) =>
            throw new Error err if err?

            @resource.Deserialize blob, done

      assert ATestResource?
      ATestResource.Init()

      client = new Client Modulator.app
      done()

  it 'should have Extend function', (done) ->
    assert ATestResource.Extend
    done()

  it 'should have test1 inherited', (done) ->
    class TestResource extends ATestResource.Extend 'test', TestRoute

    assert TestResource.prototype.FetchByName
    done()
