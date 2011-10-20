class TicTacToe
  def initialize
    @board = [nil] * 9
    @turn = :player1

    puts "What's your name, Player 1?"
    @player1 = gets.chomp

    puts "What's your name, Player 2?"
    @player2 = gets.chomp
  end

  def run
    puts "#{@player1} is Xs. #{@player2} is Os. Go!"
    next_turn until winning_player || board_full?
    board_full? ? puts "Cats game!" : puts "#{winning_player} wins!"
  end

  private

  def current_player
    @turn == :player1 ? @player1 : @player2
  end

  def current_symbol
    @turn == :player1 ? :x : :o
  end

  def next_turn
    display_prompt
    first_attempt = true
    move = nil

    while move.nil? || @board[move]
      puts "Please enter an unmarked square." unless first_attempt
      move = prompt_for_move
      first_attempt = false
    end

    @board[move] = current_symbol
    flip_turn
  end

  def display_prompt
    @board.chunk
  end

  def board_full?
    @board.none? { |square| square.nil? }
  end

  def winning_player
    symbol = winning_symbol
    return @player1 if symbol == :x
    return @player2 if symbol == :o
    nil
  end

  def winning_symbol
    [
      select_squares(0, 1, 2),
      select_squares(3, 4, 5),
      select_squares(6, 7, 8),
      select_squares(0, 3, 6),
      select_squares(1, 4, 7),
      select_squares(2, 5, 8),
      select_squares(0, 4, 8),
      select_squares(6, 4, 2)
    ].find { |l| symbol_in_line(l) }
  end

  def prompt_for_move
    puts "Your move, #{current_player}"
    gets.to_i
  end

  def select_squares(*squares)
    squares.map { |s| @board[s] }
  end

  def symbol_in_line(line)
    symbol = line[0]
    [symbol] * 3 == line ? symbol : nil
  end

  def flip_turn
    if @turn == :player1
      @turn = :player2
    else
      @turn = :player1
    end
  end
end

TicTacToe.new.run
