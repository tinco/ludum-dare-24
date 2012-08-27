class GameController < WebsocketRails::BaseController
    NETWORK_SPEED = 10 # times per second

    attr_accessor :game

    def initialize_session
        @game = Game.new
        @running = true

        @t = Thread.start do
            while @running do
                begin
                actions = game.process_actions
                broadcast_message :actions, actions if @_event
                if victor = game.victor?
                    puts "a team was victorious"
                    broadcast_message :victor, victor
                    @game = Game.new
                elsif game.new_round?
                    puts "time for a new round"
                    game.new_round
                    broadcast_message :new_round, game.players
                end
                rescue => e
                    puts e.message
                    puts e.backtrace
                end
                sleep 1.0 / NETWORK_SPEED
            end
        end
    end

    def new_player
        begin
        p = game.add_player
        rescue => e
            puts e.message
            puts e.backtrace
        end
        data_store[:player] = p
        send_message :welcome, :players => game.players, :player => p
        if game.valid? and not game.started?
            game.start
            broadcast_message :game_started, game.players
        else
            broadcast_message :new_player, p
        end
        puts "#{p} joined"
    end

    def player_disconnected
        p = fetch_player
        if p.nil?
            puts "p was nil in disconnection"
        end
        game.remove_player p
        broadcast_message :player_disconnected, p
        puts "#{p} left"
    end

    def act
        p = fetch_player
        p.actions = message
    end

    private
    def fetch_player
        game.players[data_store[:player].id]
    end
end
