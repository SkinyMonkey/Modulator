Modulator = require './'
request = require 'superagent'
async = require 'async'

class WeaponRoute extends Modulator.Route.DefaultRoute

class WeaponResource extends Modulator.Resource('weapon', WeaponRoute)
  # XXX : could be removed by new description system
  @FetchByUserId: (userId, done) ->
    @table.FindWhere '*', {userId: userId}, (err, blob) =>
      return done err if err?

      @Deserialize blob, done

  @FetchByMonsterId: (monsterId, done) ->
    @table.FindWhere '*', {monsterId: monsterId}, (err, blob) =>
      return done err if err?

      @Deserialize blob, done

WeaponResource.Init()

class UnitRoute extends Modulator.Route.DefaultRoute
  Config: ->
    super()

    @Add 'put', '/:id/levelUp', (req, res) =>
      req[@resource.lname].LevelUp (err) =>
        return res.status(500).send err if err?

        res.status(200).send req[@resource.lname].ToJSON()

    @Add 'put', '/:id/attack/:targetId', (req, res) =>
      TargetResource = MonsterResource if @name is 'players'
      TargetResource = PlayerResource if @name is 'monsters'

      TargetResource.Fetch req.params.targetId, (err, target) =>
        return res.status(500) if err?

        req[@resource.lname].Attack target, (err) ->
          return res.status(500) if err?

          res.status(200).send target.ToJSON()

class UnitResource extends Modulator.Resource('unit', {abstract: true})
  constructor: (blob, @weapon) ->
    super blob

  Attack: (target, done) ->
    target.life -= @weapon.hitpoints if @weapon?
    target.Save done

  LevelUp: (done) ->
    @level++
    @Save done

UnitResource.Init()

class PlayerRoute extends UnitRoute

class PlayerResource extends UnitResource.Extend('player', PlayerRoute)
  # XXX : could be removed with description
  @Deserialize: (blob, done) ->
    if !(blob.id?)
      return super blob, done

    WeaponResource.FetchByUserId blob.id, (err, weapon) =>
      res = @
      done null, new res blob, weapon

PlayerResource.Init()

class MonsterRoute extends UnitRoute

class MonsterResource extends UnitResource.Extend('monster', MonsterRoute)
  # XXX : could be removed with description
  @Deserialize: (blob, done) ->
    if !(blob.id?)
      return super blob, done

    WeaponResource.FetchByMonsterId blob.id, (err, weapon) =>
      res = @
      done null, new res blob, weapon

MonsterResource.Init()

class TestResource extends UnitResource.Extend('test', {abstract: true})

TestResource.Init()

class TataRoute extends UnitRoute
  Config: ->
    super()

    @Add 'get', '/:id/test', (req, res) ->
      req.tata.LevelUp (err) ->
        res.status(200).send req.tata.ToJSON() if not err?

class TataResource extends TestResource.Extend('tata', TataRoute)
  Test: (done) ->
    done()

TataResource.Init()

Client = require './test/common/client'
client = new Client Modulator.app

async.series
  addPlayer: (done) ->
    client.Post '/api/1/players', {level: 1, life: 10}, (err, res) -> done err, res.body

  testGet: (done) ->
    client.Get '/api/1/players', (err, res) -> done err, res.body

  levelUp: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  levelUp2: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  addMonster: (done) ->
    client.Post '/api/1/monsters', {level: 1, life: 20}, (err, res) -> done err, res.body

  testGetMonster: (done) ->
    client.Get '/api/1/monsters', (err, res) -> done err, res.body

  levelUpMonster: (done) ->
    client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  levelUpMonster2: (done) ->
    client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  addPlayerWeapon: (done) ->
    client.Post '/api/1/weapons', {hitpoints: 1, userId: 1}, (err, res) -> done err, res.body

  addMonsterWeapon: (done) ->
    client.Post '/api/1/weapons', {hitpoints: 3, monsterId: 1}, (err, res) -> done err, res.body

  playerAttack: (done) ->
    client.Put '/api/1/players/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack: (done) ->
    client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  test2: (done) ->
    client.Post '/api/1/tatas', {level: 1, life: 30}, (err, res) -> done err, res.body

  test3: (done) ->
    client.Get '/api/1/tatas/1/test', (err, res) -> done err, res.body


, (err, results) ->
  console.log err, results
