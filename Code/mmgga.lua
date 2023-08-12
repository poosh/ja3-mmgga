MMGGA = {
    debug = false,

    BreakingStatusEffects = {
        Burning = true,
        Suppressed = true,
    },
    HealthExplosiveResistance = 15,  -- receiving >15% exp damage dismounts MG

    TurnData = {},

    GetAimParams = function (self, unit, weapon)
        local params = CombatActions.Overwatch.GetAimParams(self, unit, weapon)
        -- STR 80 provides the default cone angle.
        params.cone_angle = weapon.OverwatchAngle * Max(unit.Strength, 20) / 80
        return params;
    end,

    GetMinAimRange = function (action, unit, weapon)
        return weapon.WeaponRange / 2
    end,

    GetMaxAimRange = function (action, unit, weapon)
        return weapon.WeaponRange * Max(unit.Marksmanship, 50) / 100
    end
}

function MMGGA:dbg(...)
    if (MMGGA.debug) then
        print('MGGGA', ...)
    end
end

function MMGGA:NeedNotify(unit)
    return g_Overwatch[unit] and g_Overwatch[unit].permanent
end

function MMGGA:GetTurnData(unit)
    local td = self.TurnData[unit]
    if not td then
        td = {
            ap_deposit = unit:GetUIActionPoints() or 0
        }
        self.TurnData[unit] = td;
    end
    return td
end

function MMGGA:OverwatchAttack(attacker, action, target, results, attack_args)
    local ow = g_Overwatch[attacker]

    -- print('target_hit', results.target_hit)
    local attack_ap = CombatActions[attack_args.action_id]:GetAPCost(attacker);
    local turnData = self:GetTurnData(attacker)
    turnData.ap_deposit = turnData.ap_deposit - attack_ap;
    self:dbg(attacker.session_id, 'AP deposit', turnData.ap_deposit / const.Scale.AP)
end

function MMGGA:PlayerTurnStart(teamIndex)
    -- local team = g_Teams[teamIndex]
    for unit, data in pairs(self.TurnData) do
        if data.ap_deposit < 0 then
            self:dbg(unit.session_id, 'Reduce AP from', unit:GetUIActionPoints() / const.Scale.AP,
                    'by', data.ap_deposit / const.Scale.AP)
            unit:ConsumeAP(-data.ap_deposit)
        end
        data.ap_deposit = 0
    end
end

function MMGGA:PlayerTurnEnd(teamIndex)
    local team = g_Teams[teamIndex]
    self.TurnData = {}
    for _, unit in pairs(team.units) do
        local ow = g_Overwatch[unit]
        if ow and ow.permanent then
            local td = self:GetTurnData(unit)
            self:dbg(unit.session_id, 'AP deposit', td.ap_deposit / const.Scale.AP)
        end
    end
end

function MMGGA:CombatEnd()
    self:dbg("Combat End");
    self.TurnData = {}
end

function MMGGA:Dismount(unit, reason)
    self:dbg(unit.session_id, 'breaks MG OW -', reason);
    local cmdid = unit:HasStatusEffect("ManningEmplacement") and 'MGLeave' or 'MGPack'
    NetStartCombatAction(cmdid, unit, 0)
end

function MMGGA:StatusEffectAdded(unit, effect, stacks)
    if (self.BreakingStatusEffects[effect]) then
        self:Dismount(unit, effect)
    end
end

function MMGGA:UnitDamaged(unit, dmg, hit_descr)
    if hit_descr.explosion and dmg >  unit.Health * self.HealthExplosiveResistance / 100 then
        self:Dismount(unit, string.format('took %d explosive damage', dmg))
    end
end

function MMGGA:init()
    MMGGA:dbg('>>> MMGGA Init')

    const.Combat.MGFreeInterruptAttacks = 100

    -- Presets.InventoryItemCompositeDef['Firearm - MG'].HK21

    FNMinimi.MagazineSize = 80
    FNMinimi.ReloadAP = 6 * const.Scale.AP

    HK21.MagazineSize = 60
    HK21.ReloadAP = 6 * const.Scale.AP

    MG42.ReloadAP = 7 * const.Scale.AP

    RPK74.MagazineSize = 50
    RPK74.ReloadAP = 4 * const.Scale.AP

    -- Allow adjusting overwatch range from effective to max range
    -- STR affects cone angle
    -- MRK affects max range
    CombatActions.MGSetup.GetAimParams = MMGGA.GetAimParams
    CombatActions.MGSetup.GetMinAimRange = MMGGA.GetMinAimRange
    CombatActions.MGSetup.GetMaxAimRange = MMGGA.GetMaxAimRange

    CombatActions.MGRotate.GetAimParams = MMGGA.GetAimParams
    CombatActions.MGRotate.GetMinAimRange = MMGGA.GetMinAimRange
    CombatActions.MGRotate.GetMaxAimRange = MMGGA.GetMaxAimRange

    CombatActions.MGPack.ActionPoints = 0

    ForEachPreset('CharacterEffectCompositeDef', function(p)
        if p.id == 'OpportunisticKillerBuff' then
            p.msg_reactions = { PlaceObj("MsgReaction", {
                Event = "UnitBeginTurn",
                Handler = function(self, unit)
                    local reaction_idx = table.find(self.msg_reactions or empty_table, "Event", "UnitBeginTurn")
                    if not reaction_idx then
                        return
                    end

                    local exec = function(self, unit)
                        local weapon1, weapon2 = unit:GetActiveWeapons()
                        if IsKindOf(weapon1, "Firearm") then
                            if IsKindOf(weapon1, "MachineGun") then
                                MMGGA:dbg(unit.session_id, 'Prevent MG Auto Reload')
                            else
                                unit:ReloadWeapon(weapon1)
                            end
                        end
                        if IsKindOf(weapon2, "Firearm") then
                            if IsKindOf(weapon2, "MachineGun") then
                                MMGGA:dbg(unit.session_id, 'Prevent MG Auto Reload')
                            else
                                unit:ReloadWeapon(weapon2)
                            end
                        end
                        unit:RemoveStatusEffect(self.id)
                    end

                    local id = GetCharacterEffectId(self)
                    if id then
                        if IsKindOf(unit, "StatusEffectObject") and unit:HasStatusEffect(id) then
                            exec(self, unit)
                        end
                    else
                        exec(self, unit)
                    end
                end,
                param_bindings = false
            }) }

            ReloadMsgReactions()
            MMGGA:dbg('OpportunisticKillerBuff replaced')
        end
      end)

    MMGGA:dbg('<<< MMGGA Init Done')
end

-- FIXME: Remove before release!
-- PlaceItemInInventoryCheat('FNMinimi')
-- PlaceItemInInventoryCheat('HK21')
-- PlaceItemInInventoryCheat('MG42')
-- PlaceItemInInventoryCheat('RPK74')
-- MMGGA.debug = true

MMGGA:init()

