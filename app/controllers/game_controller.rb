class GameController < WebsocketRails::BaseController
    N = 100
    NETWORK_SPEED = 10 # times per second
    COLORS = ['red','blue','teal','purple','orange','brown','white', 'yellow']

    def initialize_session
        # setup game?
        @board = Array.new(N, Array.new(N,[]))
        @players = {}
        @running = true

        @t = Thread.start do
            while @running do
                process_actions()
                sleep 1.0 / NETWORK_SPEED #(1 / NETWORK_SPEED)
            end
        end
    end

    def process_actions
        actions = {}
        @players.each do |id,player|
            actions[id] = player.actions if player.actions
            begin
                player.perform_actions @board  if player.actions
            rescue => e
                puts e.message
                puts e.backtrace
            end
            player.actions = nil
        end

        broadcast_message :actions, actions if @_event
    end

    def new_player
        p = Player.new
        p.id = SecureRandom.base64(16)
        p.key = SecureRandom.base64(16)
        p.position = {x: 5, y: 5}
        p.color = COLORS[@players.length % COLORS.length]
        p.orientation = 0

        @players[p.id] = p
        data_store[:player] = p
        send_message :welcome, :players => @players, :player => p
        broadcast_message :new_player, p
    end

    def player_disconnected
    end

    def act
        p = @players[data_store[:player].id]
        p.actions = message
    end
end
