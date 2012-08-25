$ ->
  player = initializePlayer()
  drawScreen()
  installGameKeys()
  addPlayer(player)
  window.thePlayer = player

@initializePlayer = () ->
  position:
    x: 5
    y: 5

@addPlayer = (player) ->
  @drawPlayer(player)

@currentDirection = {}
@intendMove = (direction) ->
  @currentDirection = {}
  @currentDirection[direction] = true
  @move(@currentDirection)

@move = (direction) ->
  x = 0
  y = 0
  if direction.up
    y-=1
  if direction.down
    y+=1
  if direction.left
    x -= 1
  if direction.right
    x += 1

  @thePlayer.position.x += x
  @thePlayer.position.y += y
  @moveAnimation @thePlayer


@installGameKeys = ->
  key 'w', => @intendMove('up')
  key 's', => @intendMove('down')
  key 'a', => @intendMove('left')
  key 'd', => @intendMove('right')

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
    x: position.x * 20
    y: position.y * 20
    

@drawPlayer = (player) ->
  position = @calculateScreenPosition(player.position)
  player.graphics = new Kinetic.RegularPolygon
          x: position.x
          y: position.y
          sides: 6
          radius: 24
          fill: "red"
          stroke: "black"
          strokeWidth: 1
  @playerLayer.add player.graphics
  @playerLayer.draw()
