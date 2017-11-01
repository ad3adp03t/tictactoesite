require 'rubygems'
require 'sinatra'
require 'pg'
require_relative 'board.rb'
require_relative 'unbeatable_app.rb'
require_relative 'classes_app.rb'
enable :sessions
load './local_env.rb' if File.exists?('./local_env.rb')


db_params = {
	host: ENV['host'],
	port: ENV['port'],
	dbname: ENV['dbname'],
	user: ENV['user'],
	password: ENV['password']
}

db = PG::Connection.new(db_params)

get '/' do

	session[:board] = Board.new
	tictactoe = db.exec("Select * From tictactoe");
	
	erb :welcome, :locals => {board: session[:board]}

end

post '/select_players' do
	
	session[:player1_type] = params[:player1]
	session[:player2_type] = params[:player2]
	session[:human1] = 'no'
	session[:human2] = 'no'
	session[:pname1] = params[:name1]
	session[:pname2] = params[:name2]
	if session[:player1_type] == 'Human'
		session[:player1] = Human.new('X')
		session[:human1] = 'yes'

	elsif session[:player1_type] == 'Easy'
		session[:player1] = Sequential.new('X')
		session[:pname1] = 'Easy AI'
	elsif session[:player1_type] == 'Medium'
		session[:player1] = RandomAI.new('X')
		session[:pname1] = 'Medium AI'
	elsif session[:player1_type] == 'Impossible'
		session[:player1] = UnbeatableAI.new('X')
		session[:pname1] = 'Impossible AI'
	end

	if session[:player2_type] == 'Human'
		session[:player2] = Human.new('O')
		session[:human2] = 'yes'

	elsif session[:player2_type] == 'Easy'
		session[:player2] = Sequential.new('O')
		session[:pname2] = 'Easy AI'

	elsif session[:player2_type] == 'Medium'
		session[:player2] = RandomAI.new('O')
		session[:pname2] = 'Medium AI'

	elsif session[:player2_type] == 'Impossible!'
		session[:player2] = UnbeatableAI.new('O')
		session[:pname2] = 'Impossible AI'
	end

	session[:active_player] = session[:player1] 
	if session[:human1] == 'yes'
		redirect '/board'
	else
		redirect '/make_move'
	end
end

get '/board' do
	erb :board, :locals => {pname1: session[:pname1], pname2: session[:pname2], player1: session[:player1], player2: session[:player2], active_player: session[:active_player].marker, board: session[:board]}
end

get '/make_move' do
	move = session[:active_player].get_move(session[:board].ttt_board)
	session[:board].update_position(move, session[:active_player].marker)
	redirect '/check_game_state'
end

post '/human_move' do
	move = params[:choice].to_i - 1
	if session[:board].valid_position?(move)
		puts move
		session[:board].update_position(move, session[:active_player].marker)
		redirect '/check_game_state'
	else
		puts move
	 	redirect '/board'
	end
end

get '/check_game_state' do
	if session[:board].winner?(session[:active_player].marker)
		message = "#{session[:active_player].marker} Won!"
		player1 = session[:player1]
		player2 = session[:player2]
		winner = session[:active_player].marker
		db.exec("INSERT INTO tictactoe(x, o, result, time) VALUES('#{session[:pname1]}', '#{session[:pname2]}',  '#{message}', '#{Time.now}')")
		erb :game_over, :locals => {board: session[:board], message: message}
	elsif session[:board].full_board?
		message = 'Its a tie'
	
		db.exec("INSERT INTO tictactoe(x, o, result, time) VALUES('#{session[:pname1]}', '#{session[:pname2]}',  '#{message}', '#{Time.now}')")
		erb :game_over, :locals => {board: session[:board], message: message}
	else
		if session[:active_player] == session[:player1]
			session[:active_player] = session[:player2]
		else
			session[:active_player] = session[:player1]
		end

		if session[:active_player] == session[:player1] && session[:human1] == 'yes' || session[:active_player] == session[:player2] && session[:human2] == 'yes'
			redirect '/board'
		else
			redirect '/make_move'
		end
	end
end	
get '/new_game' do
	session[:board] = nil
	session[:active_player] = nil
	session[:human1] = nil
	session[:human2] = nil
	session[:player1_type] = nil
	session[:player2_type] = nil
	redirect '/'
end
get '/results' do
	tictactoe = db.exec("Select * From tictactoe");
	erb :results, locals: {tictactoe: tictactoe}
end
