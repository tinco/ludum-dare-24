@global = this
N = 100

$ ->
  global.board = (([] for i in [1..N]) for j in [1..N])
  #player = initializePlayer()
  #otherPlayer = initializePlayer()
  #otherPlayer.position.x += 0
  #otherPlayer.color = 'blue'
  drawScreen()
  installGameKeys()
  #addPlayer(player)
  #addPlayer(otherPlayer)
  #global.thePlayer = player
  #global.players = [player,otherPlayer]
  global.players = {}
  connectGame()

@connectGame = ->
    @dispatcher = new WebSocketRails('localhost:3000/websocket')
    dispatcher.on_open = (data) ->
        console.log "Connected"
    dispatcher.bind 'welcome', (data) ->
        global.players = data.players
        global.thePlayer = data.player

        for id,p of players
            addPlayer(p)

    dispatcher.bind 'new_player', (player) ->
        if player.id != thePlayer.id
            players[player.id] = player
            addPlayer player

    dispatcher.bind 'actions', (playerActions) ->
        for id, actions of playerActions
            player = players[id]
            for action, params of actions
                executeAction(player,action, params)
        dispatchActions()

@isObjectEmpty = (o) -> for k,v of o
                            return false
                        true
@dispatchActions = ->
    currentActions = {}
    if currentDirection?
        currentActions['move'] = currentDirection
        global.currentDirection = undefined
    if currentOrientation?
        currentActions['look'] = currentOrientation
        global.currentOrientation = undefined
    if attacking?
        currentActions['attack'] = attacking
        global.attacking = undefined

    if !isObjectEmpty currentActions
        dispatcher.trigger 'act', currentActions

@executeAction = (player, action, params) ->
    switch action
        when 'move'
            move(player, params)
        when 'look'
            look(player, params)
        when 'attack'
            attack(player, params)
    @playerLayer.draw()

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

@addPlayer = (player) ->
  p = player.position
  @board[p.x][p.y] = @board[p.x][p.y].concat(player)
  @drawPlayer(player)

@intendMove = (direction) ->
  if !@currentDirection?
      @currentDirection = {}
  @currentDirection[direction] = true

@intendLook = (direction) ->
  if !@currentOrientation
      @currentOrientation = {}
  @currentOrientation[direction] = true

@intendAttack = (type,target) ->
  @attacking = true

@attack = (player, type, target)->
  p = player.position
  o = player.orientation
  dx = dy = 0
  even = p.y % 2 == 0
  odd = p.y % 2 == 1
  if o == -.25 || o == .25
    dy -= 1
    if o == -.25 && odd
        dx -= 1
    if o == .25 && even
        dx += 1
  else if o == -.75 || o == .75
    dy += 1
    if o == -.75 && odd
        dx -= 1
    if o == .75 && even
        dx += 1
  else if o == -.5
    dx -= 1
  else if o == .5
    dx += 1
  for p in @board[p.x + dx][p.y + dy]
    if p.color?
      p.color = if p.color != 'green' then 'green' else 'blue'
      p.graphics.setFill p.color

@dropFromArray = (array, element) ->
    n = []
    for e in array
        n.push e if e != element
    n

@move = (player, direction) ->
  x = player.position.x
  y = player.position.y
  @board[x][y] = dropFromArray(@board[x][y], player)
  even = y % 2 == 0
  odd = y % 2 == 1
  if direction.up
    y -= 1
    if direction.left && odd
        x -= 1
    if direction.right && even
        x += 1
  else if direction.down
    y += 1
    if direction.left && odd
        x -= 1
    if direction.right && even
        x += 1
  else if direction.left
    x -= 1
  else if direction.right
    x += 1
  else if direction.x
    x = direction.x
  else if direction.y
    y = direction.y

  player.position.x = x
  player.position.y = y
  @board[x][y].push(player)
  @moveAnimation player

@look = (player, direction) ->
  t = player.orientation
  if direction.left && direction.up
      t = -.25
  else if direction.left && direction.down
      t = -.75
  else if direction.right && direction.up
      t = .25
  else if direction.right && direction.down
      t = .75
  else if direction.left
    if t > 0
        t *= -1
    else
        t = -.5
  else if direction.right
    if t < 0
        t *= -1
    else
        t = .5
  else if direction.up
    if t > 0
     t = .25
    else
      t = -.25
  else if direction.down
    if t > 0
      t = .75
    else
      t = -.75

  player.orientation = t
  player.graphics.setRotation(t)


@sendLook = (direction) ->
    @addAction('look', direction: direction)

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
