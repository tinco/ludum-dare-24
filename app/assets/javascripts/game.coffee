@global = this
N = 100

$ ->
  initializeBoard()
  drawScreen()
  installGameKeys()
  global.players = {}
  connectGame()

@initializeBoard = ->
    global.board = (([] for i in [1..N]) for j in [1..N])

@connectGame = ->
    @dispatcher = new WebSocketRails('tinco.nl:3000/websocket')
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

    dispatcher.bind 'player_disconnected', (player) ->
        p = players[player.id]
        delete players[player.id]
        board[p.position.x][p.position.y] = []
        dieAnimation(p)

    dispatcher.bind 'actions', (playerActions) ->
        for id, actions of playerActions
            player = players[id]
            for action, params of actions
                executeAction(player,action, params)
        dispatchActions()

    dispatcher.bind 'victor', (victors) ->
        alert 'A team was victorious. Congratulations if it was yours. Reload the browser to play again.'

    dispatcher.bind 'new_round', (newPlayers) ->
        initializeBoard()
        for id,player of players
            player.graphics.hide()
        global.players = newPlayers
        global.thePlayer = newPlayers[thePlayer.id]
        for id,p of players
            addPlayer(p)
        console.log 'new round!'

    dispatcher.bind 'game_started', (newPlayers) ->
        initializeBoard()
        for id,player of players
            player.graphics.hide()
        global.players = newPlayers
        global.thePlayer = newPlayers[thePlayer.id]
        for id,p of players
            addPlayer(p)
        console.log 'game started!'


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
    return if player.status == 'dead'
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
  return if player.status == 'dead'
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
    if p.color? && p.team != player.team
        p.hitpoints -= (2 * player.level)
        if p.hitpoints < 1
            @handleKill player, p
        #p.color = if p.color != 'green' then 'green' else 'blue'
        # p.graphics.setFill p.color

@handleKill = (player, opponent) ->
    console.log(opponent.color + ' died')
    opponent.status = 'dead'
    @board[opponent.position.x][opponent.position.y] = []
    opponent.position = {x: -10, y: -10}
    @dieAnimation(opponent)
    increaseExperience player

@increaseExperience = (player) ->
    player.experience += 1

    if player.experience >= 40
        player.level = 5
    else if player.experience >= 20
        player.level = 4
    else if player.experience >= 10
        player.level = 3
    else if player.experience >= 5
        player.level = 2
    else
        player.level = 1

@dieAnimation = (player) ->
    player.graphics.transitionTo
        opacity: 0
        x: player.position.x
        y: player.position.y
        duration: .2

@dropFromArray = (array, element) ->
    n = []
    for e in array
        n.push e if e.id != element.id
    n

@move = (player, direction) ->
  x = oldX = player.position.x
  y = oldY = player.position.y
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

  return if x < 0 || y < 0 || x == N || y == N 
  return if @board[x][y][0]? # TODO fix in future

  player.position.x = x
  player.position.y = y
  @board[oldX][oldY] = dropFromArray(@board[oldX][oldY], player)
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
    width: $(window).width()
    height: $(window).height()

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
