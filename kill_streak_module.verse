kill_streak_module<public> := module:
    using { /Fortnite.com/Devices }
    using { /Verse.org/Simulation }

    kill_streak_device<public> := class(creative_device):
        @editable
        Elimination_Manager<private>:elimination_manager_device = elimination_manager_device{}

        @editable
        Gold_Granter<private>:item_granter_device = item_granter_device{}

        @editable
        Goals<private>:[]goal_settings = array{}

        var GoalRewardLookup<private>:[int]goal_settings = map{}
        var PlayerStreakLookup<private>:[player]int = map{}

        OnBegin<override>()<suspends>:void =
            for (Goal : Goals):
                option{set GoalRewardLookup[Goal.Eliminations_Goal] = Goal}
            Elimination_Manager.EliminationEvent.Subscribe(OnElimination)
            Elimination_Manager.EliminatedEvent.Subscribe(OnEliminated)
            Playspace := GetPlayspace()
            Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)
            Players := Playspace.GetPlayers()
            for (Player : Players):
                OnPlayerAdded(Player)

        OnPlayerAdded<private>(Player:player):void =
            option{set PlayerStreakLookup[Player] = 0}

        OnElimination<private>(MaybeAgent:?agent):void =
            if:
                Player := player[MaybeAgent?]
                CurrentStreak := PlayerStreakLookup[Player] + 1
                set PlayerStreakLookup[Player] = CurrentStreak
            then:
                if (Goal := GoalRewardLookup[CurrentStreak]):
                    for (I := 1..Goal.Completion_Gold):
                        Gold_Granter.GrantItem(Player)
                    Goal.Message.Activate(Player)

        OnEliminated<private>(Agent:agent):void =
            if (Player := player[Agent]):
                option{set PlayerStreakLookup[Player] = 0}
    
    goal_settings<internal> := struct<concrete>:
        @editable_number(int):
            MinValue := option{0}
        Eliminations_Goal:int = 0
                
        @editable_number(int):
            MinValue := option{0}
        Completion_Gold:int = 0

        @editable
        Message:elimination_feed_device = elimination_feed_device{}
