return {
PlaceObj('ModItemCode', {
	'name', "mmgga",
	'CodeFileName', "Code/mmgga.lua",
}),
PlaceObj('ModItemGameRuleDef', {
	display_name = T(563068096310, --[[ModItemGameRuleDef mmgga_rules display_name]] "MMGGA Game Rules"),
	id = "mmgga_rules",
	init_as_active = true,
	msg_reactions = {
		PlaceObj('MsgReaction', {
			Event = "OnAttack",
			Handler = function (self, attacker, action, target, results, attack_args)
				if IsMerc(attacker) and attack_args.opportunity_attack
						and attack_args.opportunity_attack_type == "Overwatch"
						and MMGGA:NeedNotify(attacker)
				then
					MMGGA:OverwatchAttack(attacker, action, target, results, attack_args);
				end
			end,
			HandlerCode = function (self, attacker, action, target, results, attack_args)
				if IsMerc(attacker) and attack_args.opportunity_attack
						and attack_args.opportunity_attack_type == "Overwatch"
						and MMGGA:NeedNotify(attacker)
				then
					MMGGA:OverwatchAttack(attacker, action, target, results, attack_args);
				end
			end,
			param_bindings = false,
		}),
		PlaceObj('MsgReaction', {
			Event = "DamageTaken",
			Handler = function (self, attacker, target, dmg, hit_descr)
				if MMGGA:NeedNotify(target) then
					MMGGA:UnitDamaged(target, dmg, hit_descr)
				end
			end,
			HandlerCode = function (self, attacker, target, dmg, hit_descr)
				if MMGGA:NeedNotify(target) then
					MMGGA:UnitDamaged(target, dmg, hit_descr)
				end
			end,
			param_bindings = false,
		}),
		PlaceObj('MsgReaction', {
			Event = "TurnStart",
			Handler = function (self, team)
				if g_Teams[team].player_team then
					MMGGA:PlayerTurnStart(team)
				end
			end,
			HandlerCode = function (self, team)
				if g_Teams[team].player_team then
					MMGGA:PlayerTurnStart(team)
				end
			end,
			param_bindings = false,
		}),
		PlaceObj('MsgReaction', {
			Event = "TurnEnded",
			Handler = function (self, teamEnded)
				if g_Teams[teamEnded].player_team then
					MMGGA:PlayerTurnEnd(teamEnded)
				end
			end,
			HandlerCode = function (self, teamEnded)
				if g_Teams[teamEnded].player_team then
					MMGGA:PlayerTurnEnd(teamEnded)
				end
			end,
			param_bindings = false,
		}),
		PlaceObj('MsgReaction', {
			Event = "CombatEnd",
			Handler = function (self, test_combat, combat, anyEnemies)
				MMGGA:CombatEnd()
			end,
			HandlerCode = function (self, test_combat, combat, anyEnemies)
				MMGGA:CombatEnd()
			end,
			param_bindings = false,
		}),
		PlaceObj('MsgReaction', {
			Event = "StatusEffectAdded",
			Handler = function (self, obj, id, stacks)
				if MMGGA:NeedNotify(obj) then
					MMGGA:StatusEffectAdded(obj, id, stacks)
				end
			end,
			HandlerCode = function (self, obj, id, stacks)
				if MMGGA:NeedNotify(obj) then
					MMGGA:StatusEffectAdded(obj, id, stacks)
				end
			end,
			param_bindings = false,
		}),
	},
}),
}
