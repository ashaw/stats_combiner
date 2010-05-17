module StatsCombiner

  class Filterer 
    
    # Initialize a filters object
    # e = Filters.new
    #
    def initialize()
      @filters ||= []
      #clear
    end 
    
    
    # Add a filter that StatsCombiner can use to manipulate paths and titles it
    # gets from Chartbeat.
    # 
    # options:                  Pattern: http://[prefix].[host]/[path][suffix]
    #
    #  prefix => nil            Filter on a prefix
    #  suffix => nil            Filter on a suffix
    #  title_regex => nil       Filter on a title pattern
    #  path_regex=> nil         Filter on a path pattern
    #
    #  modify_title => true     Modify the title inline via the regex
    #  modify_path => true      Modify the path inline via the regex
    #  append_to_path => true   Append suffix to path rather than modifying it
    #  exclude => true          Exclude this pattern from the top ten list
    def add(options={})   
      { :prefix => nil,
        :suffix => nil,
        :title_regex => nil,
        :path_regex => nil,
        :modify_title => false, 
        :exclude => false,
      }.merge!(options)
      
      filter = {}
      filter[:rule] = {}.merge!(options)
            
      @filters << filter
    end
  
    
    def list_filters
      @filters.each do |filter|
        filter
        p filter[:rule]
      end
    end
    
    # a datum comes in from chartbeat data, and is manipulated
    # with the apply_filters method
    #
    # Internal Usage:
    #  f.apply_filters({
    #   :title => Title
    #   :path => path
    #  })
    #
    def apply_filters!(datum={})
      
      datum = { 
        :title => nil,
        :path => nil,
        :prefix => nil
      }.merge!(datum)
      
      @filters.each do |filter|
  
              
        if filter[:rule][:prefix] && filter[:rule][:title_regex]
          if datum[:title].match(filter[:rule][:title_regex])
            datum[:prefix] = filter[:rule][:prefix]
          end
        end
        
        if filter[:rule][:suffix] && filter[:rule][:path_regex]
          if datum[:path].match(filter[:rule][:path_regex])
            if filter[:rule][:modify_path]
              datum[:path].gsub!(filter[:rule][:path_regex],filter[:rule][:suffix])
            elsif filter[:rule][:append_to_path]
              datum[:path] = datum[:path] + filter[:rule][:suffix]       
            end
          end
        end
  
        if filter[:rule][:modify_title]
          datum[:title].gsub!(filter[:rule][:title_regex], '')
          datum[:title].strip!
        end
    
        if datum[:prefix].nil?
          datum[:prefix] = 'www'
        end
        
      
      end
    
      datum
    
    end
  
  
  end

end


# TEST_DATA = [{:visitors=>3090, :created_at=>nil, :path=>"/", :id=>1, :title=>"Talking Points Memo | Breaking News and Analysis"}, {:visitors=>410, :created_at=>nil, :path=>"/2010/05/top_cuccinelli_contributors_mysterious_charity_bei.php", :id=>2, :title=>"Top Cuccinelli Contributor's Mysterious 'Charity' Under Scrutiny | TPMMuckraker"}, {:visitors=>366, :created_at=>nil, :path=>"/2010/05/with-specter-suffering-white-house-and-gop-looking-at-surging-sestak.php", :id=>3, :title=>"With Specter Suffering, White House And GOP Looking At Surging Sestak | TPMDC"}, {:visitors=>316, :created_at=>nil, :path=>"/archives/2010/05/crisis_of_legitimacy.php", :id=>4, :title=>"Crisis of Legitimacy | Talking Points Memo"}, {:visitors=>282, :created_at=>nil, :path=>"/2010/05/neocon-pundit-whats-with-all-these-muslims-winning-beauty-pageants.php", :id=>5, :title=>"Neocon Pundit: What's With All These Muslims Winning Beauty Pageants? | TPM LiveWire"}, {:visitors=>178, :created_at=>nil, :path=>"/2010/05/tx_textbooks_proposal_students_must_discuss_guttin.php", :id=>6, :title=>"TX Textbooks Proposal: Students Must Discuss Gutting Social Security, Explain How U.N. Undermines U.S. | TPMMuckraker"}, {:visitors=>114, :created_at=>nil, :path=>"/2010/05/orly-taitz-and-michele-bachmann-appear-at-lunch-together-picture.php", :id=>7, :title=>"Orly Taitz And Michele Bachmann Appear At Lunch Together (PICTURE) | TPM LiveWire"}, {:visitors=>74, :created_at=>nil, :path=>"/archives/2010/05/collaborative_big_think_pt_2.php", :id=>8, :title=>"Collaborative Big Think, Pt. 2 | Talking Points Memo"}, {:visitors=>100, :created_at=>nil, :path=>"/news/2010/05/court_sexually_dangerous_can_be_kept_in_prison_1.php", :id=>9, :title=>"Court: Sexually dangerous can be kept in prison  | TPM News Pages"}, {:visitors=>70, :created_at=>nil, :path=>"/2010/05/races-to-watch-tomorrow-its-not-just-the-big-senate-primaries.php", :id=>10, :title=>"Races To Watch Tomorrow: It's Not Just The Big Senate Primaries | TPMDC"}, {:visitors=>58, :created_at=>nil, :path=>"/2010/05/rifle-toting-republicans-ad-ill-name-names-and-take-no-prisoners.php", :id=>11, :title=>"Rifle-Toting Republican's Ad: 'I'll Name Names And Take No Prisoners' (VIDEO) | TPM LiveWire"}, {:visitors=>56, :created_at=>nil, :path=>"/2010/05/report_meek_sought_earmarks_for_developer_who_paid.php", :id=>12, :title=>"Report: Meek Sought Earmarks For Developer Who Paid His Staffer, Hired His Mom | TPMMuckraker"}, {:visitors=>40, :created_at=>nil, :path=>"/2010/05/tea-party-call-to-repeal-the-17th-amendment-causing-problems-for-gop-candidates.php", :id=>13, :title=>"Tea Party-Backed Repeal Of The 17th Amendment Gets Republicans Into Trouble | TPMDC"}, {:visitors=>40, :created_at=>nil, :path=>"/2010/05/mission_impossible_obama_taps_crack_team_of_scient.php", :id=>14, :title=>"Mission Impossible: Obama Taps Crack Team Of Scientists To Do The Job BP Can't  | TPMMuckraker"}, {:visitors=>34, :created_at=>nil, :path=>"/archives/2010/05/wheres_the_hijabs_when_we_need_them.php", :id=>15, :title=>"Where's the Hijabs When We Need Them!?!?! | Talking Points Memo"}, {:visitors=>32, :created_at=>nil, :path=>"/archives/2010/05/collaborative_big_think.php", :id=>16, :title=>"Collaborative Big Think  | Talking Points Memo"}, {:visitors=>28, :created_at=>nil, :path=>"/2010/05/pat-buchanan-there-are-too-many-jews-on-the-supreme-court.php", :id=>17, :title=>"Pat Buchanan: There Are Too Many Jews On The Supreme Court! | TPM LiveWire"}, {:visitors=>28, :created_at=>nil, :path=>"/2010/05/gop-kills-science-jobs-bill-by-forcing-dems-to-vote-for-porn.php", :id=>18, :title=>"GOP Kills Science Jobs Bill By Forcing Dems To Vote For Porn | TPMDC"}, {:visitors=>24, :created_at=>nil, :path=>"/2010/05/ma-gov-candidate-blows-cash-on-jousting-arena-photo-booth-mechanical-bull.php", :id=>19, :title=>"MA-Gov Candidate Blows Cash On Jousting Arena, Photo Booth, Mechanical Bull | TPM LiveWire"}, {:visitors=>22, :created_at=>nil, :path=>"/2010/05/gop-senators-dirty-little-secret.php", :id=>20, :title=>"Their Dirty Little Secret: GOP Senators Say Bailouts Worked -- Just Please Don't Tell Anyone! | TPMDC"}, {:visitors=>18, :created_at=>nil, :path=>"/2010/05/television-spots-fuel-sestak-surge-in-final-days-of-pa-sen-race.php", :id=>21, :title=>"If Sestak Beats Specter He'll Have Bush To Thank | TPMDC"}, {:visitors=>16, :created_at=>nil, :path=>"/2010/05/poll-rubio-takes-lead-in-fl-sen.php", :id=>22, :title=>"Poll: Rubio Takes Lead In FL-SEN | TPMDC"}, {:visitors=>14, :created_at=>nil, :path=>"/2010/05/the-primary-looming-blanche-lincoln-calls-out-democratic-left.php", :id=>23, :title=>"The Primary Looming, Blanche Lincoln Calls Out Democratic Left | TPMDC"}, {:visitors=>14, :created_at=>nil, :path=>"/2010/05/cable-news-wonders-if-a-scotus-nominee-plays-softball-is-she-gay.php", :id=>24, :title=>"Cable News Wonders: If A SCOTUS Nominee Plays Softball ... Is She Gay? | TPM LiveWire"}, {:visitors=>12, :created_at=>nil, :path=>"/2010/05/murkowski_oil_lobby_block_effort_to_make_industry.php", :id=>25, :title=>"Murkowski, Oil Lobby Block Effort To Make Industry Fully Pay For Spills | TPMMuckraker"}, {:visitors=>12, :created_at=>nil, :path=>"/2010/05/sestak-hits-specter-with-ad-tying-him-to-bush-palin-video.php", :id=>26, :title=>"Sestak Hits Specter With Ad Tying Him To Bush, Palin (VIDEO) | TPMDC"}, {:visitors=>10, :created_at=>nil, :path=>"/news/2010/05/thai_troops_close_in_on_protest_encampment_2.php", :id=>27, :title=>"Thai troops close in on protest encampment  | TPM News Pages"}, {:visitors=>10, :created_at=>nil, :path=>"/2010/05/gingrich-calls-on-senate-not-confirm-kagan-video.php", :id=>28, :title=>"Gingrich To Senate: Just Say No To Elena Kagan (VIDEO) | TPMDC"}, {:visitors=>8, :created_at=>nil, :path=>"/news/2010/05/study_bp_refineries_account_for_most_violations.php", :id=>29, :title=>"Study: BP refineries account for most violations | TPM News Pages"}, {:visitors=>6, :created_at=>nil, :path=>"/news/2010/05/supreme_court_bars_some_life_terms_for_juveniles.php", :id=>30, :title=>"Supreme Court bars some life terms for juveniles  | TPM News Pages"}, {:visitors=>6, :created_at=>nil, :path=>"/talk/blogs/a/m/americandad/2010/03/an-open-letter-to-conservative.php/", :id=>31, :title=>"An open letter to conservatives | AmericanDad's Blog"}, {:visitors=>6, :created_at=>nil, :path=>"/2010/05/man_behind_arizonas_no_ethnic_studies_law.php", :id=>32, :title=>"The Man Behind Arizona's Anti-Ethnic Studies Law | TPMMuckraker"}, {:visitors=>6, :created_at=>nil, :path=>"/2010/05/bp_ceo_gulf_coast_oil_spill_is_relatively_tiny_com.php", :id=>33, :title=>"BP CEO: Gulf Coast Oil Spill Is Relatively 'Tiny' Compared To 'Very Big Ocean' | TPMMuckraker"}, {:visitors=>6, :created_at=>nil, :path=>"/2010/05/the-daily-show-glenn-beck-has-nazi-tourettes-video.php", :id=>34, :title=>"The Daily Show: 'Glenn Beck Has Nazi Tourette's' (VIDEO) | TPM LiveWire"}, {:visitors=>6, :created_at=>nil, :path=>"/news/2010/05/thai_red_shirt_offers_ceasefire_as_deadline_passes.php", :id=>35, :title=>"Thai Red Shirt offers ceasefire as deadline passes | TPM News Pages"}, {:visitors=>6, :created_at=>nil, :path=>"/2010/05/cuccinelli_probe_of_climate_scientist_blasted_as_w.php", :id=>36, :title=>"Cuccinelli Probe Of Climate Scientist Blasted As 'Witch Hunt' | TPMMuckraker"}, {:visitors=>6, :created_at=>nil, :path=>"/contests/us-approval-obama?ref=fpb", :id=>37, :title=>"US-Approval - Obama | TPM PollTracker"}, {:visitors=>6, :created_at=>nil, :path=>"/2010/05/mcconnell-establishment-not-on-the-ballot-in-kentucky-senate-primary.php", :id=>38, :title=>"McConnell: GOP Establishment Not On The Ballot In Kentucky Senate Primary | TPMDC"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/senate-dems-to-battle-over-strength-of-wall-street-reform-bill.php", :id=>39, :title=>"TPMDC Morning Roundup | TPMDC"}, {:visitors=>4, :created_at=>nil, :path=>"/archives/2010/05/its_getting_better_all_the_time.php", :id=>40, :title=>"It's Getting Better All The Time | Talking Points Memo"}, {:visitors=>4, :created_at=>nil, :path=>"/talk/blogs/p/u/purple_state/2010/05/bp-asserts-its-sovereignty-in.php", :id=>41, :title=>"BP Asserts Its Sovereignty in the Gulf; Federal Government Defers | Purple State's Blog"}, {:visitors=>4, :created_at=>nil, :path=>"/archives/2010/05/together_at_last.php", :id=>42, :title=>"Together At Last | Talking Points Memo"}, {:visitors=>4, :created_at=>nil, :path=>"/archives/2010/05/the_real_muslim_threat.php", :id=>43, :title=>"The Real Muslim Threat | Talking Points Memo"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/sestak-specter-make-closing-arguments-on-cnn.php", :id=>44, :title=>"Sestak, Specter Make Closing Arguments On CNN | TPMDC"}, {:visitors=>4, :created_at=>nil, :path=>"/news/2010/05/grayson_says_tea_party_wont_be_big_voting_bloc.php", :id=>45, :title=>"Grayson says tea party won't be big voting bloc | TPM News Pages"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/17/bp_stands_for_bad_petroleum/", :id=>46, :title=>"BP Stands for Bad Petroleum | TPMCafe"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/schwarzenegger-i-was-going-to-speak-in-az-but-i-was-afraid-theyd-deport-me.php", :id=>47, :title=>"Schwarzenegger: I Was Going To Speak In AZ, But I Was Afraid They'd Deport Me | TPM LiveWire"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/could_much-maligned_bailout_be_more_like_a_stunnin.php", :id=>48, :title=>"Bailout: Best Program Evaaah? | TPMMuckraker"}, {:visitors=>4, :created_at=>nil, :path=>"/2010/05/how-democrats-saved-steve-poizners-bacon-and-maybe-cooked-meg-whitmans-goose.php", :id=>49, :title=>"How Democrats Saved Steve Poizner's Bacon And (Maybe) Cooked Meg Whitman's Goose | TPMDC"}]
# HOST = 'talkingpointsmemo.com'
# 
# 
# e = StatsCombiner::Filters.new()
# 
# e.add :prefix => 'tpmdc', :title_regex => /\| TPMDC/, :modify_title => true
# e.add :prefix => 'tpmmuckraker', :title_regex => /\| TPMMuckraker/, :modify_title => true
# e.add :prefix => 'tpmtv', :title_regex => /\| TPMTV/, :modify_title => true
# e.add :prefix => 'tpmcafe', :title_regex => /\| TPMCafe/, :modify_title => true
# e.add :prefix => 'tpmlivewire', :title_regex => /\| TPM LiveWire/, :modify_title => true
# e.add :prefix => 'tpmpolltracker', :title_regex => /\| TPM PollTracker/, :modify_title => true
# 
# 
# e.add :prefix => 'www', :title_regex => /\|.*$/, :modify_title => true
# e.add :path_regex => /(\?ref=.*$|\&ref=.*$|)/, :suffix => '', :modify_path => true
# 
# e.add :path_regex => /(\/$|\/index.php$)/, :exclude => true
# e.add :path_regex => /(\?id=.*$|\?page=.*$|\?img=.*$)/, :suffix => '&ref=mp', :append_to_path => true
# 
# e.list_filters
# 
# TEST_DATA.each do |story|
#   e.apply_filters!({
#       :title => story[:title],
#       :path => story[:path],  
#   })
# end


###

