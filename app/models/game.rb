class Game
    N = 100
    COLORS = ['red','blue','teal','purple','orange','brown','white', 'yellow']
    TEAM_A_COLORS = COLORS[0..3]
    TEAM_B_COLORS = COLORS[4..7]

    POSITIONS ={a: [[2,3],[2,6],[2,9],[2,12]],
                b: [[20,3],[20,6],[20,9],[20,12]]}

    attr_accessor :board, :players, :teams

    def initialize
        @started = false

        @board = (1..N).map {|n| (1..N).map {|m| [] }}
        
        @players = {}

        @teams = {a: [], b: []}

        @colors = {a: TEAM_A_COLORS.dup, b: TEAM_B_COLORS.dup}
    end

    def started?
        @started
    end

    def add_player
        p = Player.new
        p.id = SecureRandom.base64(16)
        p.key = SecureRandom.base64(16)
        p.game = self
        add_to_team(p)
        position_player p
        @players[p.id] = p
        p
    end

    def position_player(p)
        p.orientation = p.team == :a ? 0.5 : -0.5
        pos = POSITIONS[p.team][teams[p.team].index p]
        p.position = {x: pos.first, y: pos.second}
        @board[pos.first][pos.second] << p # has bug
    end

    def remove_player(p)
        @players.delete p.id
        @board[p.position[:x]][p.position[:y]] = []
        remove_from_team p
    end

    def add_to_team(player)
        team = @teams[:a].length <= @teams[:b].length ? :a : :b
        colors = @colors[team]
        player.color = colors.pop
        player.team = team
        @teams[team] << player
    end

    def remove_from_team(player)
        @colors[player.team].push player.color
        @teams[player.team].delete player 
    end

    def process_actions
        actions = {}
        @players.each do |id,player|
            actions[id] = player.actions if player.actions
            begin
                player.perform_actions if player.actions
            rescue => e
                puts e.message
                puts e.backtrace
            end
            player.actions = nil
        end
        actions
    end

    def valid?
        teams.all? {|k,team| team.length > 1 }
    end

    def start
        @started = true
        new_round
        players.each do |id,p|
            p.experience = 0
            p.level = 1
        end
    end

    def victor?
        return false if not valid?
        for k,team in teams
            return team if team.all? {|p| p.level >= 3}
        end
        false
    end

    def new_round?
        return false if players.length < 2
        for k,team in teams
            return true if team.all? { |p| not p.alive? }
        end
        false
    end

    def new_round
        for id,player in players
            player.status = 'alive' 
            position_player player
        end
    end
end
