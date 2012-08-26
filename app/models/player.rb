class Player
    attr_accessor :id, :actions, :key, :position, :color, :orientation

    def initialize()
    end

    def as_json(opts)
        {:id => id, :actions => actions, :position => position,
            :color => color, :orientation => orientation
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
        x = position[:x]
        y = position[:y]
        @board[x][y].delete self

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

        position[:x] = x
        position[:y] = y
        @board[x][y] << self
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
