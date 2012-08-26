class Player
    attr_accessor :id, :actions, :key, :position, :color, :orientation,
                  :hitpoints, :level, :experience, :status

    def initialize
        @hitpoints = 3
        @level = 1
        @status = :alive
    end

    def alive?
        @status != :dead
    end

    def damage
        level * 2
    end

    def as_json(opts)
        {:id => id, :actions => actions, :position => position,
            :color => color, :orientation => orientation,
            :hitpoints => hitpoints, :level => level,
            :experience => experience, :status => status
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
      p = position
      o = orientation
      y = p[:y]
      dx = dy = 0
      if o == -0.25 || o == 0.25
        dy -= 1
        if o == -0.25 && y.odd?
            dx -= 1
        end
        if o == 0.25 && y.even?
            dx += 1
        end
      elsif o == -0.75 || o == 0.75
        dy += 1
        if o == -0.75 && y.odd?
            dx -= 1
        end
        if o == 0.75 && y.even?
            dx += 1
        end
      elsif o == -0.5
        dx -= 1
      elsif o == 0.5
        dx += 1
      end

      opponents = @board[p[:x] + dx][p[:y] + dy] # TODO fix in future
      puts "opponents: #{opponents}"
      if opponent = opponents.first
          result = opponent.take_damage damage
          if result == :dead
              add_experience
          end
          puts "#{color} attacked: #{opponent.color} for #{damage} damage"
      end
    end

    def add_experience
        @experience += 1

        old_level = @level

        if @experience >= 40
            @level = 5
        elsif @experience >= 20
            @level = 4
        elsif @experience >= 10
            @level = 3
        elsif @experience >= 5
            @level = 2
        else
            @level = 1
        end

        if @level > old_level
            puts "#{self} leveled up to #{@level}"
        end
    end

    def inspect
        "<Player: #{id},#{color}>"
    end

    def to_s
        "#{color}"
    end

    def take_damage(amount)
        @hitpoints -= amount
        if @hitpoints < 1
            die
        end
        @status
    end

    def die
        @board[position[:x]][position[:y]] = []
        position[:x] = -100
        position[:y] = -100
        @status = :dead
        puts "#{color} died."
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
        return if not @board[x][y].empty?

        @board[old_x][old_y] = []
        @board[x][y] = [self]

        position[:x] = x
        position[:y] = y

        puts "#{self} moved to #{x},#{y} from #{old_x}, #{old_y}"
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
