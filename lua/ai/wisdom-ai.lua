--[[
	技能：倨傲
	描述：出牌阶段，你可以选择两张手牌背面向上移出游戏，指定一名角色，被指定的角色到下个回合开始阶段时，跳过摸牌阶段，得到你所移出游戏的两张牌。每阶段限一次 
]]--
local juao_skill={}
juao_skill.name = "juao"
table.insert(sgs.ai_skills, juao_skill)
juao_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("JuaoCard") and self.player:getHandcardNum() > 1 then
		local card_id = self:getCardRandomly(self.player, "h")
		return sgs.Card_Parse("@JuaoCard=" .. card_id)
	end
end

sgs.ai_skill_use_func.JuaoCard = function(card, use, self)
	local givecard = {}
	local cards = self.player:getHandcards()
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() == 1 then --队友快死了
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("Analeptic") or hcard:isKindOf("Peach") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then 
						use.to:append(friend) 
						self.player:speak("顶住，你的快递马上就到了。")
					end
					return
				end
			end
		end
		if friend:hasSkill("jizhi") then --队友有集智
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("TrickCard") and not hcard:isKindOf("DelayedTrick") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
		if friend:hasSkill("leiji") then --队友有雷击
			for _, hcard in sgs.qlist(cards) do
				if hcard:getSuit() == sgs.Card_Spade or hcard:isKindOf("Jink") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then 
						use.to:append(friend) 
						self.player:speak("我知道你有什么牌，哼哼。")
					end
					return
				end
			end
		end
		if friend:hasSkill("xiaoji") or friend:hasSkill("xuanfeng") then --队友有枭姬（旋风）
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("EquipCard") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
	givecard = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 then --敌人快死了
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("Disaster") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() and
					not hcard:isKindOf("Peach") and not hcard:isKindOf("TrickCard") then
					table.insert(givecard, hcard:getId())
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then use.to:append(enemy) end
					return
				elseif #givecard == 2 then
					use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
					if use.to then 
						use.to:append(enemy) 
						self.player:speak("咱最擅长落井下石了。")
					end
					return
				else
				end
			end
		end
		if enemy:hasSkill("yongsi") then --敌人有庸肆
			local players = self.room:getAlivePlayers()
			local extra = self:KingdomsCount(players) --额外摸牌的数目
			if enemy:getCardCount(true) <= extra then --如果敌人快裸奔了
				for _,hcard in sgs.qlist(cards) do
					if hcard:isKindOf("Disaster") then
						table.insert(givecard, hcard:getId())
					end
					if #givecard == 1 and givecard[1] ~= hcard:getId() then
						if not hcard:isKindOf("Peach") and not hcard:isKindOf("ExNihilo") then
							table.insert(givecard, hcard:getId())
							use.card = sgs.Card_Parse("@JuaoCard="..table.concat(givecard, "+"))
							if use.to then
								use.to:append(enemy)
							end
							return 
						end
					end
					if #givecard == 2 then
						use.card = sgs.Card_Parse("@JuaoCard="..table.concat(givecard, "+"))
						if use.to then
							use.to:append(enemy)
							enemy:speak("你给我等着！")
						end
						return 
					end
				end
			end
		end
	end
	if #givecard < 2 then
		for _, hcard in sgs.qlist(cards) do
			if hcard:isKindOf("Disaster") then
				table.insert(givecard, hcard:getId())
			end
			if #givecard == 2 then
				use.card = sgs.Card_Parse("@JuaoCard=" .. table.concat(givecard, "+"))
				if use.to then use.to:append(self.enemies[1]) end
				return
			end
		end
	end
end
--[[
	技能：贪婪
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌 
]]--
sgs.ai_skill_invoke.tanlan = function(self, data)
	local damage = data:toDamage()
	local max_card = self:getMaxCard()
	if not max_card or self:isFriend(damage.from) then return end
	if max_card:getNumber() > 10 or
		(self.player:getHp() > 2 and self.player:getHandcardNum() > 2 and max_card:getNumber() > 4) or
		(self.player:getHp() > 1 and self.player:getHandcardNum() > 1 and max_card:getNumber() > 7) or
		(damage.from:getHandcardNum() <= 2 and max_card:getNumber() > 2) then
		return true
	end
end
--[[
	技能：异才
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】 
]]--
sgs.ai_skill_invoke.yicai = function(self, data)
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, nil, true) then
			if self:getCardsNum("Slash") > 0 then 
				return true 
			end
		end
	end
end
--[[
	技能：北伐（锁定技）
	描述：当你失去最后一张手牌时，视为对攻击范围内的一名角色使用了一张【杀】
]]--
sgs.ai_skill_playerchosen.beifa = function(self, targets)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	local targetlist = {}
	for _,p in sgs.qlist(targets) do
		if not self:slashProhibit(slash, p) then
			table.insert(targetlist, p)
		end
	end
	self:sort(targetlist, "defenseSlash")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) then
			if self:slashIsEffective(slash, target) then
				if sgs.isGoodTarget(target, targetlist) then
					self.player:speak("嘿！没想到吧？")
					return target
				end
			end
		end
	end
	for i=#targetlist, 1, -1 do
		if sgs.isGoodTarget(targetlist[i], targetlist) then
			return targetlist[i]
		end
	end
	return targetlist[#targetlist]
end

sgs.ai_chaofeng.wisjiangwei = 2
--[[
	技能：后援
	描述：出牌阶段，你可以弃置两张手牌，指定一名其他角色摸两张牌，每阶段限一次 
]]--
local houyuan_skill={}
houyuan_skill.name="houyuan"
table.insert(sgs.ai_skills,houyuan_skill)
houyuan_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("HouyuanCard") and self.player:getHandcardNum() > 1 then
		local givecard = {}
		local index = 0
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			table.insert(givecard, fcard:getId())
			index = index + 1
			if index == 2 then break end
		end
		if index < 2 then return end
		return sgs.Card_Parse("@HouyuanCard=" .. table.concat(givecard, "+"))
	end
end

sgs.ai_skill_use_func.HouyuanCard = function(card, use, self)
	if #self.friends == 1 then return end
	local target
	local max_x = 20
	for _, friend in ipairs(self.friends_noself) do
		if not friend:hasSkill("manjuan") then --不能对漫卷队友发动
			local x = friend:getHandcardNum()
			if x < max_x then
				max_x = x
				target = friend
			end
		end
	end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local usecards = {cards[1]:getId(), cards[2]:getId()}
	if not cards[1]:isKindOf("ExNihilo") then
		if use.to and target then
			use.to:append(target)
		end
		use.card = sgs.Card_Parse("@HouyuanCard=" .. table.concat(usecards, "+"))
		if use.card then
			self.player:speak("有你这样出远门不带粮食的么？接好了！")
		end
	end
	return 
end

sgs.ai_card_intention.HouyuanCard = -70

sgs.ai_chaofeng.wisjiangwan = 6
--[[
	技能：霸王
	描述：当你使用的【杀】被【闪】响应时，你可以和对方拼点：若你赢，可以选择最多两个目标角色，视为对其分别使用了一张【杀】
]]--
sgs.ai_skill_invoke.bawang = function(self, data)
	local effect = data:toSlashEffect()
	local max_card = self:getMaxCard()
	if max_card and max_card:getNumber() > 10 then
		return self:isEnemy(effect.to)
	end
end

sgs.ai_skill_use["@@bawang"] = function(self, prompt)
	local first_index, second_index
	for i=1, #self.enemies do
		if not (self.enemies[i]:hasSkill("kongcheng") and self.enemies[i]:isKongcheng()) then
			if not first_index then
				first_index = i
			else
				second_index = i
			end
		end
		if second_index then break end
	end
	if not first_index then return "." end
	local first = self.enemies[first_index]:objectName()
	if not second_index then
		return ("@BawangCard=.->%s"):format(first)
	else
		local second = self.enemies[second_index]:objectName()
		return ("@BawangCard=.->%s+%s"):format(first, second)
	end
end

sgs.ai_card_intention.BawangCard = sgs.ai_card_intention.ShensuCard
--[[
	技能：危殆（主公技）
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止 
]]--
sgs.ai_skill_use["@@weidai"] = function(self, prompt)
	return "@WeidaiCard=.->."
end

sgs.ai_skill_use_func.WeidaiCard = function(card, use, self)
	use.card = card
end

sgs.ai_card_intention.WeidaiCard = sgs.ai_card_intention.Peach

sgs.ai_skill_cardask["@weidai-analeptic"] = function(self, data)
	local who = data:toPlayer()
	if self:isEnemy(who) then return "." end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _, fcard in ipairs(cards) do
		if fcard:getSuit() == sgs.Card_Spade and fcard:getNumber() > 1 and fcard:getNumber() < 10 then
			return fcard:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_chaofeng.wissunce = 1
--[[
	技能：笼络
	描述：回合结束阶段开始时，你可以选择一名其他角色摸取与你弃牌阶段弃牌数量相同的牌 
]]--
sgs.ai_skill_playerchosen.longluo = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if self:isFriend(player) and player:getHp() > player:getHandcardNum() then
			if not player:hasSkill("manjuan") then --对漫卷队友无效
				return player
			end
		end
	end
	return self.friends_noself[1]
end

sgs.ai_playerchosen_intention.longluo = -60

sgs.ai_skill_invoke.longluo = function(self, data)
	return #self.friends > 1
end
--[[
	技能：辅佐
	描述：当有角色拼点时，你可以打出一张点数小于8的手牌，让其中一名角色的拼点牌加上这张牌点数的二分之一（向下取整）
]]--
sgs.ai_skill_choice.fuzuo = function(self , choices)
	--排除不能发动技能的情形
	if self.player:isKongcheng() then
		self.player:speak("空城看好戏，呵呵。")
		return "cancel"
	end
	local flag = true
	local handcards = self.player:getHandcards()
	for _,card in sgs.qlist(handcards) do
		local point = card:getNumber()
		if point > 1 and point < 8 then --因为是向下取整，所以可用范围是2～7。
			flag = false
			break
		end
	end
	if flag then --没有点数小于8的手牌
		self.player:speak("别看我，手里是真没货……")
		return "cancel"
	end
	--现在choices应该是"nameA+nameB+cancel"形式的，下面开始获取具体选项
	local nameA = ""
	local nameB = ""
	local fromPosA = -1
	local toPosA = -1
	local fromPosB = -1
	local toPosB = -1
	fromPosA, toPosA = string.find(choices, "+")
	if fromPosA > 1 and toPosA == fromPosA then
		nameA = string.sub(choices, 1, fromPosA-1)
		fromPosB, toPosB = string.find(choices, "+", toPosA+1)
		if fromPosB > toPosA and toPosB == fromPosB then
			nameB = string.sub(choices, toPosA+1, toPosB-1)
		else
			self.player:speak("呼叫程序员！我的AI又出错了！")
			return "cancel"
		end
	else
		self.player:speak("呼叫程序员！我的AI又出错了！")
		return "cancel"
	end
	--现在选项内容已经确定为nameA和nameB，可以判断进行辅佐的目标了
	for _,p in pairs(self.friends) do
		if p:getGeneralName() == nameA then
			return nameA
		end
		if p:getGeneralName() == nameB then
			return nameB
		end
	end
	self.player:speak("你们爱谁赢谁赢。")
	return "cancel"
end
sgs.ai_skill_cardask["@fuzuo_card"] = function(self, data, pattern, target)
	local handcards = self.player:getHandcards()
	local cards = {}
	for _,card in sgs.qlist(handcards) do
		local point = card:getNumber()
		if point > 1 and point < 8 then
			table.insert(cards, card)
		end
	end
	self:sortByKeepValue(cards)
	local fzcard = cards[1]
	return fzcard:getEffectiveId()
end
--[[
	技能：尽瘁
	描述：当你死亡时，可令一名角色摸取或者弃置三张牌 
]]--
sgs.ai_skill_invoke.jincui = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.jincui = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if self:isFriend(player) and player:getHp() - player:getHandcardNum() > 1 then
			return player
		end
	end
	if #self.friends > 1 then return self.friends_noself[1] end
	sgs.jincui_discard = true
	return self.enemies[1]
end

sgs.ai_skill_choice.jincui = function(self, choices)
	if sgs.jincui_discard then return "throw" else return "draw" end
end

sgs.ai_chaofeng.wiszhangzhao = -1
--[[
	技能：霸刀
	描述：当你成为黑色的【杀】目标时，你可以对你攻击范围内的一名其他角色使用一张【杀】 
]]--
sgs.ai_skill_invoke.badao = function(self, data)
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, nil, true) and self:getCardsNum("Slash") > 0 then return true end
	end
end
--[[
	技能：识破
	描述：任意角色判定阶段判定前，你可以弃置两张牌，获得该角色判定区里的所有牌 
]]--
sgs.ai_skill_invoke.shipo = function(self, data)
	local target = data:toPlayer()
	if ((target:containsTrick("supply_shortage") and target:getHp() > target:getHandcardNum()) or
		(target:containsTrick("indulgence") and target:getHandcardNum() > target:getHp()-1)) then
		return self:isFriend(target)
	end
end

sgs.ai_chaofeng.tianfeng = -3
--[[
	技能：授业
	描述：出牌阶段，你可以弃置一张红色手牌，指定最多两名其他角色各摸一张牌 
]]--
local shouye_skill={}
shouye_skill.name = "shouye"
table.insert(sgs.ai_skills, shouye_skill)
shouye_skill.getTurnUseCard=function(self)
	if #self.friends_noself == 0 then return end
	if self.player:getHandcardNum() > 0 then
		local n = self.player:getMark("shouyeonce")
		if n > 0 and self.player:hasUsed("ShouyeCard") then return end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, hcard in ipairs(cards) do
			if hcard:isRed() then
				return sgs.Card_Parse("@ShouyeCard=" .. hcard:getId())
			end
		end
	end
end

sgs.ai_skill_use_func.ShouyeCard = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	if self.friends_noself[1] then
		if use.to then use.to:append(self.friends_noself[1]) end
	end
	if self.friends_noself[2] then
		if use.to then use.to:append(self.friends_noself[2]) end
	end
	use.card = card
	return
end

sgs.ai_card_intention.ShouyeCard = -70
--[[
	技能：师恩
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
]]--
sgs.ai_skill_invoke.shien = function(self, data)
	local target = data:toPlayer()
	if target and target:isAlive() then 
		return self:isFriend(target)
	end
	return false
end

sgs.ai_chaofeng.wisshuijing = 5
