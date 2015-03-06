require 'net/http'
require 'open-uri'
require 'json'

class Match

	def initialize
		print "Enter Match Number: "
		@match_num = gets.chomp
		@match_num = "0"+@match_num if @match_num.to_i < 10 || 	@match_num.length < 2

		load_match_data

		@team = []
		@team << @match_data["matchInfo"]["teams"][0]["team"]["fullName"]
		@team << @match_data["matchInfo"]["teams"][1]["team"]["fullName"]

		@venue = @match_data["matchInfo"]["venue"]["fullName"]<<","<<@match_data["matchInfo"]["venue"]["city"]<<","<<@match_data["matchInfo"]["venue"]["country"]
	end

#######  Helper Functions #######

	def top_batsmen(batsmen)
		a = batsmen.sort{|a,b| b['r'] <=> a['r']}
		return a[0..1]
	end

	def top_bowler(bowlers)
		a = bowlers.sort{|a,b| b['w'] <=> a['w']}
		return a[0..1]
	end

	def get_batsmen_score(playerId)
		if playerId==-1
			return '*'
		end
		@match_data["innings"].each do |inning|
			inning["scorecard"]["battingStats"].each do |each_player|
				if each_player["playerId"]==playerId
					return each_player["r"].to_s+"("+each_player["b"].to_s+")" 
				end
			end
		end
	end

	def get_bowler_wicket(playerId)
		if playerId==-1
			return '*'
		end
		@match_data["innings"].each do |inning|
			inning["scorecard"]["bowlingStats"].each do |each_player|
				if each_player["playerId"]==playerId
					return each_player["ov"].to_s+"-"+each_player["maid"].to_s+"-"+each_player["r"].to_s+"-"+each_player["w"].to_s
				end
			end
		end
	end

	def start_match
		if @match_data["matchInfo"]["matchState"]=="C"
			completed_case	
		elsif @match_data["matchInfo"]["matchState"]=="L"
			current_case
		else
			future_case
		end
	end

	def get_player_name(playerId)
		if playerId==-1
			return '*'
		else
			return @player_detail[playerId]
		end
	end

	def get_match_status
		unless @match_data["matchInfo"]["matchStatus"].nil?
			@match_status=@match_data["matchInfo"]["matchStatus"]["text"]
		end
		@match_summary=@match_data["matchInfo"]["matchSummary"]
	end
	

	def get_player_detail_hash
		@player_detail={}
		@match_data["matchInfo"]["teams"].each do |team|
			unless team["players"].nil?
				team["players"].each do |player|
					@player_detail[player["id"]]=player["names"][0]
				end
			end
		end
		return @player_detail
	end

	def load_match_data
		@url = URI("https://cdn.pulselive.com/dynamic/data/core/cricket/2012/cwc-2015/cwc-2015-"<<@match_num<<"/scoring.js")
		@json = Net::HTTP.get(@url)
		@match_data = JSON.parse(@json[10..-3])
	end

	def show_details
		system "clear"
		print "\t\t\t#{@team[0]}\t vs \t#{@team[1]}\n "
		puts "*"*78
		date = DateTime.parse(@match_data['matchInfo']['matchDate']).strftime("%d/%m/%Y")
		print "\n\t\t\t\t#{date}\n"
		print "\t\t\t      Match Number: #{@match_num}"
		print "\n\t\t\t    At #{@venue}\n\t\t"
		print "Toss Winner: #{@toss_winner_status}\n" unless @toss_winner_status.nil?
	end

	def print_top_players(batsmen,bowler)
		print "\n\t#{get_player_name(batsmen[0]["playerId"])} - #{batsmen[0]['r']}(#{batsmen[0]['b']})"
		print "\t\t#{get_player_name(bowler[0]["playerId"])} - #{bowler[0]['ov']}-#{bowler[0]['maid']}-#{bowler[0]['r']}-#{bowler[0]['w']}"
		print "\n\t#{get_player_name(batsmen[1]["playerId"])} - #{batsmen[1]['r']}(#{batsmen[1]['b']})"
		print "\t\t#{get_player_name(bowler[1]["playerId"])} - #{bowler[1]['ov']}-#{bowler[1]['maid']}-#{bowler[1]['r']}-#{bowler[1]['w']}"
	end

	def print_match_status
		print "\n\n\t#{@match_data["matchInfo"]["matchStatus"]["text"]}\tMOM: #{@match_data["matchInfo"]["additionalInfo"]["result.playerofthematch"]}\n\n"
		print "~"*78
		print "\n"
	end

	def print_current_players(batsmen1_id,batsmen2_id,bowler_id)
		print "\n\t#{get_player_name(batsmen1_id)} - #{get_batsmen_score(batsmen1_id)}"
		print "\t\t#{get_player_name(bowler_id)} - #{get_bowler_wicket(bowler_id)}"
		print "\n\t#{get_player_name(batsmen2_id)} - #{get_batsmen_score(batsmen2_id)}"
	end

######### End of helpers ##############


	

	def get_score_card

		@current_state=@match_data["currentState"]
		@co=@current_state["recentOvers"]

		
		@striker_id=@current_state["facingBatsman"]
		@non_striker_id=@current_state["nonFacingBatsman"]
		@bowler_id=@current_state["currentBowler"]
		
		unless @co.nil?
			@current_over=@co[@co.length-1]["ovNo"]
			@current_over_detail=@co[@co.length-1]["ovBalls"]
		end
		unless @match_data["innings"].nil?
			@innings=@match_data["innings"]
			unless @innings[0].nil?
				@inning1score=@innings[0]["scorecard"]["runs"]
				@inning1wicket=@innings[0]["scorecard"]["wkts"]
				@inning1over=@innings[0]["overProgress"]
				@inning1runrate=@innings[0]["runRate"]
			end

			unless @innings[1].nil?
				@top_batsmen=top_batsmen(@innings[0]["scorecard"]["battingStats"])
				@top_bowler=top_bowler(@innings[0]["scorecard"]["bowlingStats"])

				@inning2score=@innings[1]["scorecard"]["runs"]
				@inning2wicket=@innings[1]["scorecard"]["wkts"]
				@inning2over=@innings[1]["overProgress"]
				@inning2runrate=@innings[1]["runRate"]
			end
		end
	end


	def show_scorecard

		@toss_winner_status = @match_data["matchInfo"]["additionalInfo"]["toss.elected"] 
		@first_inning = @match_data["matchInfo"]["battingOrder"][0]
		@second_inning = @match_data["matchInfo"]["battingOrder"][1]

		show_details

		print "\n"
		print "-"*78

		unless @match_data["innings"].nil?
			if @match_data["innings"][1].nil?
				print "\n\t#{@team[@first_inning]} batting first \n\t\t"
				print "score: #{@inning1score}/#{@inning1wicket}"
				print " in #{@inning1over} overs"
				print " (RR: #{@inning1runrate})"

				print "\n"

				print_current_players(@striker_id,@non_striker_id,@bowler_id)

				print "\n"
				print "-"*78
				print "\n"

				print "Current over:",@current_over
				print "  "*5
				print "Current over Detail",@current_over_detail
				print "\n"

			else
					
				print "\n"
				print "-"*78

				print "\n\t#{@team[@first_inning]} batted first \n\t\t"
				print "score: #{@inning1score}/#{@inning1wicket}"
				print " in #{@inning1over} overs"
				print " (RR: #{@inning1runrate})"

				print_top_players(@innings[0]["scorecard"]["battingStats"],@innings[0]["scorecard"]["bowlingStats"])

				print "\n"
				print "-"*78

				print "\n\t#{@team[@second_inning]} batting second \n\t\t"
				print "score: #{@inning2score}/#{@inning2wicket}"
				print " in #{@inning2over} overs"
				print " (RR: #{@inning2runrate})  "

				print_current_players(@striker_id,@non_striker_id,@bowler_id)

				print "\n"
				print "-"*78

				print "Current over:",@current_over
				print "  "*5
				print "Current over Detail",@current_over_detail
				print "\n"

				if @inning2over.include?(".")
					rem_balls=(50-(@inning2over.split(".")[0].to_i+1))*6+(6-@inning2over.split(".")[1].to_i)
				else
					rem_balls=(50-(@inning2over.to_i))*6
				end
				print "\n"
				print "-"*78
				print "\n"

				print (@inning1score.to_i-@inning2score.to_i+1)," Runs required off ",rem_balls," Balls"
				print "\n"


				print "RequiredRun-Rate is ", @match_data["currentState"]["requiredRunRate"]
			end
		end	
		print "\n"
		print "-"*78

		puts @match_status
	end

	def completed_case
		
		get_player_detail_hash
		
		@toss_winner_status = @match_data["matchInfo"]["additionalInfo"]["toss.elected"] 
		@first_inning = @match_data["matchInfo"]["battingOrder"][0]
		@second_inning = @match_data["matchInfo"]["battingOrder"][1]

		show_details

		innings = @match_data["innings"]
		inning1score = innings[0]["scorecard"]
		inning2score = innings[1]["scorecard"]
		inning1batsmen = inning1score["battingStats"]
		inning2batsmen = inning2score["battingStats"]
		inning1bowler = inning1score["bowlingStats"]
		inning2bowler = inning2score["bowlingStats"]

		inning1topB = top_batsmen(inning1batsmen)
		inning1topBw = top_bowler(inning1bowler)
		inning2topB = top_batsmen(inning2batsmen)
		inning2topBw = top_bowler(inning2bowler)

		print "\n"
		print "-"*78

		print "\n\t#{@team[@first_inning]} batted first \n\t\t"
		print "score: #{inning1score['runs']}/#{inning1score['wkts']}"
		print " in #{innings[0]['overProgress']} overs"
		print " (RR: #{innings[0]['runRate']})"

		print_top_players(inning1topB,inning1topBw)

		print "\n"
		print "-"*78

		print "\n\t#{@team[@second_inning]} batted second \n\t\t"
		print "score: #{inning2score['runs']}/#{inning2score['wkts']}"
		print " in #{innings[1]['overProgress']} overs"
		print " (RR: #{innings[1]['runRate']})  "

		print_top_players(inning2topB,inning2topBw)

		print "\n"
		print "-"*78

		print_match_status
	end

	def future_case
		show_details
		print "\n\n\t\tMatch Yet to be started! Stay tuned for live updates!\n"
	end
	
	

	def current_case
		
		while true
			load_match_data
			if @player_detail.nil?
				get_player_detail_hash
			end	
			get_score_card
			get_match_status
			show_scorecard
			sleep(20)
			system "clear"
		end
	end


	
end

m=Match.new
m.load_match_data
m.start_match