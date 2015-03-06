require 'net/http'
require 'open-uri'
require 'json'

class Match


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
		uri=URI("http://cdn.pulselive.com/dynamic/data/core/cricket/2012/cwc-2015/cwc-2015-28/scoring.js");
		data_from_site=Net::HTTP.get(uri);
		@match_data=JSON.parse(data_from_site[10..-3])
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

	def print_current_players(batsmen1_id,batsmen2_id,bowler_id)
		print "\n\t#{get_player_name(batsmen1_id)} - #{get_batsmen_score(batsmen1_id)})"
		print "\t\t#{get_player_name(bowler_id)} - #{get_bowler_wicket(bowler_id)}"
		print "\n\t#{get_player_name(batsmen2_id)} - #{get_batsmen_score(batsmen2_id)})"
	end

	def show_scorecard

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

				print "RequiredRun-Rate is ", @match_data["currentState"]["requiredRunRate"]
			end
		end	
		print "\n"
		print "-"*78

		puts @match_status
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