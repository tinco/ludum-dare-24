@global = this
N = 100

$ ->
  global.board = (([] for i in [1..N]) for j in [1..N])
  player = initializePlayer()
  otherPlayer = initializePlayer()
  otherPlayer.position.x += 0
  otherPlayer.color = 'blue'
  drawScreen()
  installGameKeys()
  addPlayer(player)
  addPlayer(otherPlayer)
  global.thePlayer = player
  global.players = [player,otherPlayer]

@neighbours = (player) ->
    p = player.position
    x = p.x
    y = p.y
    b = board
    ns = []
    .concat(b[x+1]?[y])
    .concat(b[x-1]?[y])
    .concat(b[x+1]?[y+1])
    .concat(b[x]?[y+1])
    .concat(b[x+1]?[y-1])
    .concat(b[x]?[y-1])
    ns

@initializePlayer = () ->
  position:
    x: 5
    y: 5
  orientation: 0
  color: 'red'

@addPlayer = (player) ->
  p = player.position
  @board[p.x][p.y] = @board[p.x][p.y].concat(player)
  @drawPlayer(player)

@currentDirection = {}
@currentOrientation = {}

@intendMove = (direction) ->
  @currentDirection = {}
  @currentDirection[direction] = true
  @move(@currentDirection)

@intendLook = (direction) ->
  @currentOrientation = {}
  @currentOrientation[direction] = true
  @look(@currentOrientation)

@intendAttack = (type,target) ->
  @attack(type, target)

@attack = (type, target)->
  p = @thePlayer.position
  o = @thePlayer.orientation
  dx = dy = 0
  if o == 0
      dy = 1
  if o == 1
      dy = -1
  if o == .5
      dx = 1
  if o == 1.5
      dx = -1
  for p in @board[p.x + dx][p.y + dy]
    if p.color?
      p.color = if p.color != 'green' then 'green' else 'blue'
      p.graphics.setFill p.color
      @playerLayer.draw()

@dropFromArray = (array, element) ->
    n = []
    for e in array
        n.push e if e != element
    n

@move = (direction) ->
  x = @thePlayer.position.x
  y = @thePlayer.position.y
  @board[x][y] = dropFromArray(@board[x][y], @thePlayer)
  if direction.up
    y -= 1
  if direction.down
    y += 1
  if direction.left
    x -= 1
  if direction.right
    x += 1
  if direction.x
    x = direction.x
  if direction.y
    y = direction.y

  @thePlayer.position.x = x
  @thePlayer.position.y = y
  @board[x][y].push(@thePlayer)
  @moveAnimation @thePlayer

@look = (direction) ->
  t = 0
  if direction.up
    t = 0
  if direction.down
    t = 1
  if direction.left
    t = 1.5
  if direction.right
    t = .5

  @thePlayer.orientation = t
  @thePlayer.graphics.setRotation(t)
  @playerLayer.draw()


@installGameKeys = ->
  key 'w', => @intendMove('up')
  key 's', => @intendMove('down')
  key 'a', => @intendMove('left')
  key 'd', => @intendMove('right')

  key 'up', => @intendLook('up')
  key 'down', => @intendLook('down')
  key 'left', => @intendLook('left')
  key 'right', => @intendLook('right')
  
  key 'space', => @intendAttack()

@drawScreen = () ->
  @stage = new Kinetic.Stage
    container: 'screen'
    width: 640
    height: 480

  stage.viewport =
    x: 0
    y: 0

  @playerLayer = new Kinetic.Layer()
       
  stage.add @playerLayer

@moveAnimation = (object) ->
    newPosition = @calculateScreenPosition object.position
    transition =
        x: newPosition.x
        y: newPosition.y
        duration: .2
        easing: 'ease-in-out'
    object.graphics.transitionTo transition

@calculateScreenPosition = (position) ->
    result =
        x: position.x * 40 
        y: position.y * 40
    if position.y % 2 == 0
        result.x += 20
    result
        

@drawPlayer = (player) ->
  position = @calculateScreenPosition(player.position)
  player.graphics = new Kinetic.RegularPolygon
          x: position.x
          y: position.y
          sides: 6
          radius: 24
          fill: player.color
          stroke: "black"
          strokeWidth: 1
          rotation: player.orientation

  @playerLayer.add player.graphics
  @playerLayer.draw()
