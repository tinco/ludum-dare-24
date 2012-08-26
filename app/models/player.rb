class Player
    attr_accessor :id, :actions, :key, :position, :color, :orientation,
                  :hitpoints, :level, :experience

    def initialize
        @hitpoints = 3
        @level = 1
    end

    def damage
        level * 2
    end

    def as_json(opts)
        {:id => id, :actions => actions, :position => position,
            :color => color, :orientation => orientation,
            :hitpoints => hitpoints, :level => level, :experience => experience
        }
    end

    def perform_actions(board)
        @board = board
        actions.each do |action, parameters|
            case action
            when "move"
                move(parameters)
            when "look"
                look(parameters)
            when "attack"
                attack(parameters)
            end
        end
    end

    def attack(parameters)
    end

    def move(direction)
        x = old_x = position[:x]
        y = old_y = position[:y]

        up = direction["up"]
        left = direction["left"]
        down = direction["down"]
        right = direction["right"]

        if up
            y -= 1
            if left && y.odd?
                x -= 1
            end
            if right && y.even?
                x += 1
            end
        elsif down
            y += 1
            if left && y.odd?
                x -= 1
            end
            if right && y.even?
                x += 1
            end
        elsif left
            x -= 1
        elsif right
            x += 1
        end

        return if x < 0 || y < 0 || x == @board.length || y == @board.length
        return if @board[x][y].any? {|t| t.is_a? Player}

        @board[old_x][old_y].delete self
        @board[x][y] << self

        position[:x] = x
        position[:y] = y
    end

    def look(direction)
        t = orientation

        up = direction["up"]
        left = direction["left"]
        down = direction["down"]
        right = direction["right"]

        if left && up
            t = -0.25
        elsif left && down
            t = -0.75
        elsif right && up
            t = 0.25
        elsif right && down
            t = 0.75
        elsif left
            if t > 0
                t *= -1
            else
                t = -0.5
            end
        elsif right
            if t < 0
                t *= -1
            else
                t = 0.5
            end
        elsif up
            if t > 0
                t = 0.25
            else
                t = -0.25
            end
        elsif down
            if t > 0
                t = 0.75
            else
                t = -0.75
            end
        end

        @orientation = t
    end
end
