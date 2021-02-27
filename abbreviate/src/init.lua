local DEFAULT_SUFFIX_TABLE = {
	'k',
	'M',
	'B',
	'T',
	'Qd',
	'Qn',
	'Sx',
	'Sp',
	'O',
	'N',
	'De',
	'Ud',
	'DD',
	'tdD',
	'QnD',
	'SxD',
	'SpD',
	'OcD',
	'NvD',
	'VgN',
	'UvG',
	'DvG',
	'TvG',
	'QtV',
	'QnV',
	'SeV',
	'SpG',
	'OvG',
	'NvG',
	'TgN',
	'UtG',
	'DtG',
	'TsTg',
	'QtTg',
	'QnTg',
	'SsTg',
	'SpTg',
	'OcTg',
	'NoTg',
	'QdDr',
	'UnAg',
	'DuAg',
	'TeAg',
	'QdAg',
	'QnAG',
	'SxAg',
	'SpAg',
	'OcAg',
	'NvAg',
	'CT'
}

return function()

	local module = {}

	module._suffixTable = DEFAULT_SUFFIX_TABLE
	module._decimalPlaces = 2

	function module:setSetting(settingName, settingValue)
		if not (settingName and settingValue and type(settingName) == 'string') then
			error('setSetting had invalid parameters.\nP1 - settingName: string\nP2 - settingValue: unknown', 2)
		end
		local realSetting = '_' .. settingName

		if module[realSetting] and type(module[realSetting]) ~= 'function' then
			module[realSetting] = settingValue
		else
			if module[realSetting] then
				error('Attempt to index setting ' ..settingName..' which is not an editable field.');
			else
				error('Attempt to index setting ' ..settingName..' which is not a valid setting!');
			end
		end
	end

	function module:numberToString(number, roundDown)
		if type(number) ~= "number" then
			error('numberToString invalid parameter #1, expected number, got "nil"', 2)
		end

		if number < 1000 and number > -1000 then
			-- special case: we must manually abbreviate numbers between -1000 and 1000
			return ("%."..module._decimalPlaces.."f"):format(number)
		end

		if roundDown == nil then
			roundDown = true
		end

		local negative = number < 0
		number = math.abs(math.floor(number))

		for index = #module._suffixTable, 1, -1 do
			local unit = module._suffixTable[index]
			local size = 10 ^ (index * 3)

			if size <= number then
				if roundDown then
					number = math.floor(number * 10^module._decimalPlaces / size) / 10^module._decimalPlaces
				else
					number = math.floor((number * 10^module._decimalPlaces / size) + 0.5) / 10^module._decimalPlaces
				end

				if number == 1000 and index < #module._suffixTable[index] then
					number = 1
					unit = module._suffixTable[index][index + 1]
				end

				number = ("%."..module._decimalPlaces.."f"):format(number) .. unit
				break
			end
		end

		if negative then
			return "-" .. number
		else
			return tostring(number)
		end
	end

	-- Credits to Coreccii for this method
	local hexToBin = {
		["0"] = "0000",
		["1"] = "0001",
		["2"] = "0010",
		["3"] = "0011",
		["4"] = "0100",
		["5"] = "0101",
		["6"] = "0110",
		["7"] = "0111",
		["8"] = "1000",
		["9"] = "1001",
		["A"] = "1010",
		["B"] = "1011",
		["C"] = "1100",
		["D"] = "1101",
		["E"] = "1110",
		["F"] = "1111",
	}

	local binToUnicodeAscending = table.create(16)
	local binToUnicodeDescending = table.create(16)

	for hex, bin in pairs(hexToBin) do
		binToUnicodeAscending[hex] = bin.gsub(bin, ".", {["0"] = "\u{200B}", ["1"] = "\u{2060}"})
		binToUnicodeDescending[hex] = bin.gsub(bin, ".", {["1"] = "\u{200B}", ["0"] = "\u{2060}"})
	end

	-- Usage: getSortablePrefix(sortOrder: number, maximumSortOrder: number, descending?: false): string
	local function getSortablePrefix(num, maxNum, descending)
		local maxSize = math.ceil(math.log(maxNum) / math.log(16))
		local maxSizeString = string.format("%d", maxSize)

		local numHex = string.format("%0" .. maxSizeString .. "X", num)
		return (string.gsub(numHex, ".", descending and binToUnicodeDescending or binToUnicodeAscending))
	end

	function module:numbersToSortedString(numbers)
		if not (numbers and type(numbers) == 'table') then
			error('numbersToSortedString had invalid parameters.\nP1 - numbers: Array<number>', 2)
		end

		local numbersSize = #numbers

		local sortedNumbers = table.create(numbersSize)

		-- Validate and create the numbers
		for index, number in ipairs(numbers) do
			if type(number) ~= 'number' then
				error('numbersToSortedString had invalid parameters.\nP1 - numbers: Array<number>', 2)
			end

			table.insert(sortedNumbers, {
				initialIndex = index,
				value = number
			})
		end

		-- Sort
		table.sort(sortedNumbers, function(a, b)
			return a.value < b.value
		end)

		-- Make return result
		local returnResult = table.create(numbersSize)
		for sortedIndex, numberData in ipairs(sortedNumbers) do
			if numberData.value < 1000 then
				returnResult[numberData.initialIndex] = string.format('%.'..module._decimalPlaces..'f', numberData.value)
			end

			for index = #module._suffixTable, 1, -1 do
				local shortenedNumber = 10 ^ (index * 3)

				if numberData.value >= shortenedNumber then
					local suffix = module._suffixTable[index]

					local prefixed = string.format('%.'..module._decimalPlaces..'f'..suffix, numberData.value / shortenedNumber)

					returnResult[numberData.initialIndex] = getSortablePrefix(sortedIndex, numbersSize, false)..prefixed
					break
				end
			end

		end

		return returnResult
	end

	function module:stringToNumber(str)
		if not (str and type(str) == 'string') then
			error('stringToNumber had invalid parameters.\nP1 - string: string', 2)
		end

		local totalMagnitude = 1

		for key, suffix in pairs(module._suffixTable) do
			str = string.gsub(str, suffix, function()
				totalMagnitude = totalMagnitude * (10 ^ (key * 3))
				return ''
			end)
		end

		-- validate that user passed an actual string that we can convert to number
		if not tonumber(str) then
			error('stringToNumber invalid parameter #1: Expected a string which could be converted to a number, got "'..str..'"', 2)
		end

		return totalMagnitude * str
	end

	function module:commify(number)
		assert(type(number) == 'number', 'Attempt to commify a non-number value')

		local formatted = tostring(number)
		while true do
			local newFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			formatted = newFormatted
			if k == 0 then
				break
			end
		end
		return formatted
	end

	return module
end