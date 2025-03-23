--- STEAMODDED HEADER
--- MOD_NAME: Balatro: CE
--- MOD_ID: BalatroCE
--- MOD_AUTHOR: [TheDiBZ]
--- MOD_DESCRIPTION: Jokers made by YOU

----------------------------------------------
------------MOD CODE -------------------------

local jokers = {
    unluckycat = {
        name = "Unlucky Cat",
        text = {
            "Gains {C:chips}+13{} chips each",
            "time a {C:attention}Lucky{} card",
            "doesn't trigger",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
        },
        config = {extra = {chips = 0, chip_mod = 13}},
        pos = {x = 0, y = 0},
        rarity = 3,
        cost = 8,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        effect = "",
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            -- upgrade step
            if context.individual and context.cardarea == G.play then
                if context.other_card.ability.effect == 'Lucky Card' and not context.other_card.lucky_trigger and not context.blueprint then
                    self.ability.extra.chips = self.ability.extra.chips + self.ability.extra.chip_mod

                    return {
                        extra = {focus = self, message = localize('k_upgrade_ex')},
                        card = self,
                        colour = G.C.CHIPS,
                        chip_mod = self.ability.extra.chips
                    }
                end
            end

            -- joker calculation step
            if SMODS.end_calculate_context(context) and self.ability.extra.chips ~= 0 then
                return {
                    chip_mod = self.ability.extra.chips,
                    card = self,
                    message = localize { type = 'variable', key = 'a_chips', vars = {self.ability.extra.chips}}
                }
            end
        end,

        loc_def = function(self) --defines variables to use in the UI. you can use #1# for example to show the mult variable, and #2# for x_mult
            return {self.ability.extra.chips, self.ability.extra.chip_mod}
        end,
    },

    cosmonaut = {
        name = "The Cosmonaut",
        text = {
            "{C:red}Decreases{} level of",
            "played {C:attention}poker hand{} and",
            "earn {C:money}$#1#{}"
        },
        config = {extra = {money = 8}},
        pos = {x = 0, y = 0},
        rarity = 3,
        cost = 8,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        effect = "",
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.cardarea == G.jokers and context.before then  
                local handname = context.scoring_name
                if G.GAME.hands[handname].level > 1 then
                    level_up_hand(context.blueprint_card or self, handname, nil, -1) -- level down hand
                    ease_dollars(self.ability.extra.money) -- give money
                    return {
                        message = localize('$')..self.ability.extra.money,
                        colour = G.C.MONEY,
                        card = self
                    }
                end
            end
        end,

        loc_def = function(self) --defines variables to use in the UI. you can use #1# for example to show the mult variable, and #2# for x_mult
            return {self.ability.extra.money}
        end,
    },

    manvsbear = {
        name = "Man vs. Bear",
        text = {
            "This Joker destroys played {C:attention}Kings{}",
            "and {C:attention}Jacks{} and gains {X:mult,C:white} X#1#{} Mult",
            "per card destroyed this way",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)"
        },
        config = {extra = {x_mult = 1, xmult_mod = 0.2, cards_to_destroy = {}}},
        pos = {x = 0, y = 0},
        rarity = 2,
        cost = 5,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        effect = "Mult",
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play then
                if (context.other_card:get_id() == 11 or context.other_card:get_id() == 13) and not context.blueprint and self.ability.extra.cards_to_destroy[#self.ability.extra.cards_to_destroy] ~= context.other_card then
                    -- don't add duplicates (only have to check most recently added element)
                    -- add king/jack to destroy list
                    self.ability.extra.cards_to_destroy[#self.ability.extra.cards_to_destroy + 1] = context.other_card
                end
            end

            if context.cardarea == G.jokers and self.ability.extra.cards_to_destroy and not context.blueprint then
                if type(self.ability.extra.cards_to_destroy) == "table" then
                    for i = 1, #self.ability.extra.cards_to_destroy do
                        local card = self.ability.extra.cards_to_destroy[i]  
                        if card then
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    card:start_dissolve()
                                    return true
                                end
                            }))

                            card.destroyed = true -- ensures cards are removed from deck properly
                            self.ability.extra.x_mult = self.ability.extra.x_mult + self.ability.extra.xmult_mod -- upgrade
                        end
                    end

                    if #self.ability.extra.cards_to_destroy ~= 0 then
                        self.ability.extra.cards_to_destroy = {}  -- just in case
                    end
                end
            end
            

            if SMODS.end_calculate_context(context) and self.ability.extra.x_mult ~= 1 then
                self.ability.extra.cards_to_destroy = {}  -- reset
                return {
                    x_mult = self.ability.extra.x_mult,
                    card = self,
                    colour = G.C.RED
                }
            end
        end,

        loc_def = function(self)
            return {self.ability.extra.xmult_mod, self.ability.extra.x_mult}
        end
    },

    matroyshka = {
        name = "Matroyshka Dolls",
        text = {
            "If hand contains a {C:attention}Straight{},",
            "add the {C:attention}lowest{} and",
            "{C:attention}highest{} rank to Mult"
        },
        config = {},
        pos = {x = 0, y = 0},
        rarity = 1,
        cost = 5,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        effect = "",
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play and (next(context.poker_hands['Straight']) or next(context.poker_hands['Straight Flush'])) then
                local full_hand_ranks = {}
                for i = 1, #context.full_hand do
                    full_hand_ranks[i] = context.full_hand[i]:get_id()
                end

                if context.other_card:get_id() == math.min(unpack(full_hand_ranks)) or context.other_card:get_id() == math.max(unpack(full_hand_ranks)) then
                    if context.other_card.debuff then
                        return {
                            message = localize('k_debuffed'),
                            colour = G.C.RED,
                            card = self
                        }
                    end

                    return {
                        mult = context.other_card.base.nominal,
                        colour = G.C.RED,
                        card = self
                    }
                end
            end
        end
    }
}

function SMODS.INIT.BBBalatro()
    --localization for the info queue key
    G.localization.descriptions.Other["your_key"] = {
        name = "Example", --tooltip name
        text = {
            "TEXT L1",   --tooltip text.		
            "TEXT L2",   --you can add as many lines as you want
            "TEXT L3"    --more than 5 lines look odd
        }
    }
    init_localization()

    --Create and register jokers
    for k, v in pairs(jokers) do --for every object in 'jokers'
        local joker = SMODS.Joker:new(v.name, k, v.config, v.pos, { name = v.name, text = v.text }, v.rarity, v.cost,
            v.unlocked, v.discovered, v.blueprint_compat, v.eternal_compat, v.effect, v.atlas, v.soul_pos)
        joker:register()

        if not v.atlas then --if atlas=nil then use single sprites. In this case you have to save your sprite as slug.png (for example j_examplejoker.png)
            SMODS.Sprite:new("j_" .. k, SMODS.findModByID("BalatroCE").path, "j_" .. k .. ".png", 69, 93, "asset_atli")
                :register()
        end

        --add jokers calculate function:
        SMODS.Jokers[joker.slug].calculate = v.calculate
        --add jokers loc_def:
        SMODS.Jokers[joker.slug].loc_def = v.loc_def
        --if tooltip is present, add jokers tooltip
        if (v.tooltip ~= nil) then
            SMODS.Jokers[joker.slug].tooltip = v.tooltip
        end
    end
    --Create sprite atlas
    SMODS.Sprite:new("TheDiBZ", SMODS.findModByID("BalatroCE").path, "atlasone.png", 69, 93, "asset_atli")
        :register()
end

----------------------------------------------
------------MOD CODE END----------------------
