class GameController < WebsocketRails::BaseController
    N = 100
    NETWORK_SPEED = 10 # times per second
    COLORS = ['red','blue','teal','purple','orange','brown','white', 'yellow']
    TEAM_A_COLORS = COLORS[0..3]
    TEAM_B_COLORS = COLORS[4..7]

    def initialize_session
        # setup game?
        @board = (1..N).map {|n| (1..N).map {|m| [] }}
        
        @players = {}
        @running = true

        @team_a = []
        @team_b = []
        @team_a_colors = TEAM_A_COLORS.dup
        @team_b_colors = TEAM_B_COLORS.dup

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
        p.orientation = 0

        @board[5][5] << p

        data_store[:player] = p
        @players[p.id] = p

        begin
            add_to_team(p)
        rescue => e
            puts e.message
            puts e.backtrace
        end

        send_message :welcome, :players => @players, :player => p
        broadcast_message :new_player, p
        puts "#{p} joined"
    end

    def add_to_team(player)
        team = @team_a.length <= @team_b.length ? @team_a : @team_b
        colors = team == @team_a ? @team_a_colors : @team_b_colors
        player.color = colors.pop
        player.team = team == @team_a ? 'a' : 'b'
        @team_a << player
    end

    def remove_from_team(player)
        team = player.team == 'a' ? @team_a : @team_b
        colors = team == @team_a ? @team_a_colors : @team_b_colors
        colors.push player.color
        team.delete player 
    end

    def player_disconnected
        p = @players[data_store[:player].id]
        return if p.nil?
        @players.delete p.id
        @board[p.position[:x]][p.position[:y]] = []
        remove_from_team p
        broadcast_message :player_disconnected, p
        puts "#{p} left"
    end

    def act
        p = @players[data_store[:player].id]
        p.actions = message
    end
end
