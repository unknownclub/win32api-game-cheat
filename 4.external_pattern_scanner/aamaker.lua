--[[

new Feature from git-flow

						CE Lua Plugin: "AA Maker"
							 Version 2.4.2
								 
	[EN]
	Technical support :
		http://forum.cheatengine.org/viewtopic.php?p=5645967
								 
	[RU]
	Техническая поддержка:
		http://forum.gamehacklab.ru/index.php?/topic/1415-plugin-aa-maker-создание-аа-скриптов
		
Authors: SnedS91, MasterGH, ++METHOS

	Many thanks to "cheatengine.org": Dark Byte,  mgr.inz.Player,	++METHOS and all others
	Many thanks to "Gamehacklab[RU]": Xipho,  NullAlex, SER[G]ANT, SnedS91 and all others

Our friends:
	Cheat Engine
		http://cheatengine.org/
		http://forum.cheatengine.org/
	Gamehacklab[RU]
		http://gamehacklab.ru/
		
		
Date: 01.02.2016 
]]--


------------------------------------------------------
local pluginVersion = '2.4.2'

local stringSpaceBeforeinstruction = '	' 	-- If you wish, add more characters


SimpleCodeTemplate = [[
{ Game   : {$ProcessName}
  Version: 1.0
  Date   : {$Date}
  Author : [edit aamaker.lua and paste Author]

  This script does blah blah blah
  
  Made by AA Maker Lua plugin ;)
}

[ENABLE]

{$AddressInjection}:
{$CheatCode}

[DISABLE]

{$AddressInjection}:
{$OriginalCode}

{$PrintLog}
]]

AACodeTemplate = [[
{ Game   : {$ProcessName}
  Version: 1.0
  Date   : {$Date}
  Author : [open aamaker.lua and paste Author]

  This script does blah blah blah
  
  Made by AA Maker Lua plugin ;)
}

[ENABLE]

alloc(newMem, 2048)
label(returnHere)

newMem:
{$CheatCode}
]]..stringSpaceBeforeinstruction..[[jmp returnHere

{$AddressInjection}:
]]..stringSpaceBeforeinstruction..[[jmp newMem
{$Nops}

returnHere:

[DISABLE]
	
{$AddressInjection}:
{$OriginalCode}

dealloc(newMem)

{$PrintLog}
]]

AOBSCANModuleCodeTemplate = [[
{ Game   : {$ProcessName}
  Version: 1.0
  Date   : {$Date}
  Author : [open aamaker.lua and paste Author]

  This script does blah blah blah
  
  Made by AA Maker Lua plugin ;)
}

[ENABLE]

aobscanmodule(INJECT,{$AddressInjection},{$ArrayOfbyte})
alloc(newmem,$1000)

label(code)
label(return)
registersymbol(INJECT)

newmem:

code:
{$CheatCode}
]]..stringSpaceBeforeinstruction..[[jmp return

INJECT:
]]..stringSpaceBeforeinstruction..[[jmp code
{$Nops}

return:


[DISABLE]

INJECT:
{$OriginalCode}

unregistersymbol(INJECT)
dealloc(newmem)

{$PrintLog}
]]


AOBSCANModuleStealthCodeTemplate = [[
{ Game   : {$ProcessName}
  Version: 1.0
  Date   : {$Date}
  Author : [open aamaker.lua and paste Author]

  This script does blah blah blah
  
  Make by aamaker Lua plugin ;)
  
  Download stealthedit:
  http://www.cheatengine.org/temp/stealthedit2.4.zip
}

[ENABLE]

aobscanmodule(INJECT,{$AddressInjection},{$ArrayOfbyte})
alloc(newmem,2048,{$AddressInjection})
stealtheditex(stealth,INJECT,1)

label(originalcode)
label(returnhere)
label(stealthedit)

registersymbol(stealthedit)

//======================================================

newmem:

{$CheatCode}
originalcode:

]]..stringSpaceBeforeinstruction..[[jmp returnhere

//enable:
//db 0

//======================================================

stealth:
stealthedit:
]]..stringSpaceBeforeinstruction..[[jmp newmem
{$Nops}

returnhere:

[DISABLE]

stealthedit:
{$OriginalCode}

unregistersymbol(stealthedit)
dealloc(newmem)

{$PrintLog}
]]
------------------------------------------------------
PATTERN = {
['inc']	 = 'mov{$Type}[x],{$Value}',
['mov']  = 'mov{$Type}[x],{$Value}\r\n{$OriginalCode}',
['fld']	 = 'mov{$Type}[x],{$Value}\r\n{$OriginalCode}',
['fstp'] = '{$OriginalCode}\r\n'..'mov{$Type}[x],{$Value}'
}
------CODE--SECTION-----------------------------------
local captionForm = 'AA Maker '.. pluginVersion
local scriptName = ''
local cheatType = ''
local cheatName = ''
local cheatValueType = ''
local patternInjectAsmCode = ''
local cheatCode = ''
local originalCode = ''
local originalBytes = ''
local nops = ''
local strSignature = ''
local cheatValue = 0
local testBytes = 0
local origCodeType = 0
scriptCount = 0
------------------------------------------------------
local form = createForm(false) form.centerScreen() form.setSize(181,223) form.Name = 'fmAdvCheat' form.Caption = captionForm setProperty(form,'BorderIcons','[biSystemMenu]')	form.onClose = form_hide(form)
local edCheatName = createEdit(form) edCheatName.setSize(168,23) edCheatName.setPosition(7,19) edCheatName.Name ='edCheatName' edCheatName.Text = ''
local labelCheatName = createLabel(form) labelCheatName.setPosition(16,2) labelCheatName.Caption = 'Cheat name [optional]:'
local groupBox = createGroupBox(form) groupBox.setSize(172,96) groupBox.setPosition(4,45) groupBox.Caption = 'Cheat type'
local cmbCheatType = createComboBox(groupBox) cmbCheatType.Name = 'cmbCheatType' cmbCheatType.setSize(160,23) cmbCheatType.setPosition(4,1)
local items = cmbCheatType.getItems() items.add('Simple') items.add('Injection') items.add('Nops') items.add('AOBScanModule') items.add('AOBScanModuleStealth') items.add('Disable CALL') setProperty(cmbCheatType, 'ReadOnly', true) cmbCheatType.setItemIndex(0)
local cbTestingBytes = createCheckBox(groupBox) cbTestingBytes.Name = 'cbTestingBytes' cbTestingBytes.setSize(90,19) cbTestingBytes.setPosition(3,30) cbTestingBytes.Caption = 'Testing bytes' cbTestingBytes.Enabled = false
local cbOrigCodeType = createCheckBox(groupBox) cbOrigCodeType.Name = 'cbOrigCodeType' cbOrigCodeType.setSize(135,19) cbOrigCodeType.setPosition(3,54) cbOrigCodeType.Caption = 'Original code in bytes'
local edValue = createEdit(form) edValue.setSize(68,23) edValue.setPosition(7,166) edValue.Name = 'edValue' edValue.Text = '100'
local labelValue = createLabel(form) labelValue.setPosition(7,146) labelValue.Caption = 'Value:'
local cmbType = createComboBox(form) cmbType.Name = 'cmbType' cmbType.setSize(96,23) cmbType.setPosition(77,166) setProperty(cmbType, 'ReadOnly', true)
local typevalitems = cmbType.Items typevalitems.add('hexadecimal') typevalitems.add('decimal') typevalitems.add('float') cmbType.setItemIndex(1)
local labelTypeValue = createLabel(form) labelTypeValue.setPosition(77,146) labelTypeValue.Caption = 'Type of value:'
local btnOk = createButton(form) btnOk.Name = 'btnOk' btnOk.Caption = 'Create Script' btnOk.setSize(176,24) btnOk.setPosition ( 3,195) setProperty(btnOk, 'Default', true)
------------------------------------------------------
function checkPattern()
	local address = getNameFromAddress(dv_address1)
	local _,opcode = splitDisassembledString(disassemble(address))
	local choose = getProperty(cmbCheatType,"Text")
	if choose == 'Injection' or choose == 'AOBScanModule' then
		for key,value in pairs(PATTERN) do
			if string.find(opcode,key) ~= nil then
				local _,_,x = string.find(opcode, '%[(.*)%]')
				if x ~= nil then
					patternInjectAsmCode = value
					return true
				end
			end
		end
	end
	patternInjectAsmCode = '{$OriginalCode}'
	return false
end

function getCheatCode(address, value, valueType)
	local _,opcode = splitDisassembledString(disassemble(address))
	opcode = getAddressFromOpcode(opcode)
	
	local newCode = ''
	local opType = ' '
	
	if checkPattern() then
		if string.find(opcode, " .* ptr ") ~= nil then
			opType = string.sub(opcode, string.find(opcode, ' .* ptr '))
		end

		local _,_,x = string.find(opcode, '%[(.*)%]')
		if x ~= nil then		
			newCode = string.gsub(patternInjectAsmCode,'{$Type}',opType)
			newCode = string.gsub(newCode,'%[x%]','['..x..']')
			newCode = string.gsub(newCode,'{$Value}',valueType..value)
			if string.find(opcode, '%],') ~= nil then
				if string.find(originalCode, '^.*\r?\n') ~= nil then
					newCode = string.gsub(newCode,'{$OriginalCode}',originalCode:gsub('^.*\r?\n',''))
				else newCode = string.gsub(newCode,'\r?\n*{$OriginalCode}','') end
			else
				newCode = string.gsub(newCode,'{$OriginalCode}',originalCode)
			end		
		end
	else newCode = '\r\n'..originalCode end
	return stringSpaceBeforeinstruction..newCode
end

function getOriginalCodeString(strAddress, length, typeNops)
	local sumBytes = 0
	local nopsCount = 0
	local originalCodeString = ''
	local originalBytesString = ''
	local nopsString = ''
	local address = strAddress
	
	repeat
		local InstructionSize = getInstructionSize(address)
		_,opcode,bytes,address = splitDisassembledString(disassemble(address))
		opcode = getAddressFromOpcode(opcode)
		sumBytes = sumBytes + InstructionSize
		address = address..'+'..InstructionSize
		_,_,_,address = splitDisassembledString(disassemble(address))
		if sumBytes >= length then 
			originalCodeString = originalCodeString..stringSpaceBeforeinstruction..opcode	
		else 
			originalCodeString = originalCodeString..stringSpaceBeforeinstruction..opcode..'\r\n' 
		end
		
		originalCodeString = originalCodeString
		originalBytesString = originalBytesString..bytes
	until (sumBytes >= length)

	if typeNops then nopsCount = sumBytes - length else nopsCount = length end
	if nopsCount > 0 then
		if nopsCount < 3 then
			for i = 1, nopsCount do
				if i == nopsCount then 
					nopsString = nopsString..stringSpaceBeforeinstruction.."nop"
				else 
					nopsString = nopsString..stringSpaceBeforeinstruction.."nop\r\n" 
				end
			end
		else
			nopsString = stringSpaceBeforeinstruction..'db '	
			for i = 1, nopsCount do
				if i == nopsCount then 
					nopsString = nopsString.."90"
				else 
					nopsString = nopsString.."90 "	
				end
			end
		end
	end
	originalBytesString = stringSpaceBeforeinstruction..'db'..string.gsub(originalBytesString:gsub(' ',''),'(%x)(%x)',' %1%2')
	
	return originalCodeString, nopsString, originalBytesString
end

function getAddressFromOpcode(opcode)
	local strRet = ''
	local namedAddr = ''
	local base = ''
	local offset = ''
	
	for addr in string.gmatch(opcode, "%x+") do
		if addr ~= nil and #addr > 5 then
			namedAddr = getNameFromAddress(addr)
			if namedAddr == addr then strRet = opcode
			else		
				offset = string.match(namedAddr, "%x+$")
				base = string.gsub(namedAddr, "+"..offset, "")

				if string.find(base, "%s") ~= nil then
					strRet = string.gsub(opcode,addr,"\"" .. base .. "\"+" .. offset)
				else strRet = string.gsub(opcode,addr,base .. "+" .. offset) end
			end
		else strRet = opcode end
	end
	
	if strRet == '' then strRet = opcode end
	return strRet
end

function getReturnFromCall(strAddress)
	local address = strAddress
	local retnStr = ''
	local _,opcode = splitDisassembledString(disassemble(address))
	if string.match(opcode, "%a+") ~= 'call' then
		messageDialog("This isn't CALL-function!\r\nPlease choose another instruction!",mtWarning,mbOK)
		return false
	end

	address = string.match(opcode, "%x+")
	if address ~= nil then
		if (string.find(opcode, "%x+%p$") ~= nil) then
			address = string.format('%X',readInteger(address))
		end
		
		local _address = address
		repeat
			local countBytes = getInstructionSize(_address)
			_address = _address..'+'..countBytes
			_,opcode,_,_address = splitDisassembledString(disassemble(_address))
			local currentInstr = string.match(opcode, "%a+")
			if currentInstr == 'ret' then retnStr = opcode end
		until (retnStr ~= '') 
		
		local sizeRet = getInstructionSize(_address)
		
		originalCode, nops, originalBytes = getOriginalCodeString(address, sizeRet, true)
		cheatCode = retnStr..'\r\n'..nops
		return true,address
	else
		messageDialog("Address not found!\r\nPlease choose another instruction!",mtWarning,mbOK)
		return false
	end
end

function getFullSignature(startAddress, stopAddress)
	local addr = startAddress
	local stop = stopAddress
	local str = ''
	local _str = ''
	local count = -1
	local result = ''
	local num = 2
	local minNum = 4
	
	if testBytes then num = 8 minNum = 12 end
	str,addr = getBytesForAOB(addr, stop, stop)
	
	
	if #str > minNum then
		result = AOBScan(str, '+X-C-W')
		
		if result == nil then
			print("Error! Your signature is not located in a section of code. Nothing Found! You need a privilege '+ X-C-W'")
			return ''
		end
		
		count = result.Count
		result.destroy(result)
	end

	while count ~= 1 do
		str = str.._str	
		_str,addr = getBytesForAOB(addr, num)
		result = AOBScan(str.._str, '+X-C-W')
		count = result.Count
		result.destroy()	
	end
	

	local numOflast = #string.gsub(_str,'x','')/2
	
	while (numOflast > 1) do
		local nL = math.floor(numOflast/2)
		local nR = numOflast - nL
		local _strL, _strR
		if testBytes then
			_strL = string.match(_str,string.rep('x*%x+x+',nL))
			_strR = string.match(_str,string.rep('%x+x*',nR),#_strL)
		else
			_strL = string.sub(_str,1,2*nL)
			_strR = string.sub(_str,2*nL+1)
		end
		if AOBScan(str.._strL, '+X-C-W').Count == 1 then
			_str = _strL
			numOflast = nL
		else
			str = str.._strL
			_str = _strR
			numOflast = nR
		end		
	end 

	str = str.._str
	if testBytes then str = string.lower(str)
	else str = str:gsub('(.)(.)', '%1%2 ') end
	str = str:gsub('x*%s*$','')
	
	return str
end

function getBytesForAOB(startAddress, num, stop)
	local addr = startAddress
	local str = ''
	
	for i = 1,num do 	
		local sizeInstruction = getInstructionSize(addr)
		local _,_,bytes = splitDisassembledString(disassemble(addr))
		local fstBt, othBt = string.match(bytes,'^%x+'),string.match(bytes,' .+$')
		if testBytes then
			if othBt ~= nil then
				othBt = string.gsub(string.gsub(othBt,'%s',''),'%x','x')
				str = str..fstBt..othBt
			else 
				str = str..string.gsub(fstBt,'%x','x')
			end
		else
			str = str..string.gsub(bytes,'%s','')
		end
		if addr == stop then addr = addr + sizeInstruction break end
		addr = addr + sizeInstruction
	end		
	
	return str,addr
end
------------------------------------------------------
function AddAARecord(script, sciptName) 
	local addresslist = getAddressList()
	newTableEntry = addresslist.createMemoryRecord(addresslist)
	newTableEntry.setDescription(sciptName)
	newTableEntry.setType(vtAutoAssembler)
	newTableEntry.setScript(newTableEntry, script)	
	return newTableEntry
end

function OpenAAEditor(newTableEntry)
   local addresslist = getAddressList()
   addresslist.setSelectedRecord(newTableEntry)
   addresslist.doValueChange()
end
-------Add Item Menu in Disassembler------------------
function OnSelectionTracker(disassemblerviewLine, address, address2)
	dv_address1 = address
	dv_address2 = address2
		
	if checkPattern() then
		edValue.Enabled = true
		cmbType.Enabled = true
	else
		edValue.Enabled = false
		cmbType.Enabled = false
	end
end

function AddItemMenuInMemoryViewForm(nameItemMenu, shortcut, functionItemClick, functionSelectiontracker)
	local mv = getMemoryViewForm()
	local dv = mv.DisassemblerView
	

	--bug with dv.OnSelectionChange = functionSelectiontracker
	disassemblerview_onSelectionChange(dv, functionSelectiontracker)
	
	
	dv_address1 = dv.SelectedAddress
	dv_address2 = dv.SelectedAddress2

	popupmenu = dv.PopupMenu
	mi = createMenuItem(popupmenu)
	mi.Caption = nameItemMenu
	
	mi.onClick = functionItemClick
	mi.Shortcut = shortcut

	popupmenu.Items.add(mi)
end

function AddItemMenu(menuItem, nameItemMenu, shortcut, functionItemClick)
	local mi = createMenuItem(popupmenu)
	mi.Caption = nameItemMenu
	mi.Shortcut = shortcut
	mi.onClick = functionItemClick
	menuItem.add(mi)
end

function AddItemWithSubMenusInMemoryViewForm(nameItemMenu, functionSelectiontracker)
	local mv = getMemoryViewForm()
	local dv = mv.DisassemblerView

	--bug with dv.OnSelectionChange = functionSelectiontracker
	disassemblerview_onSelectionChange(dv, functionSelectiontracker)

	dv_address1 = dv.SelectedAddress
	dv_address2 = dv.SelectedAddress2

	popupmenu = dv.PopupMenu
	mmenu_items = popupmenu.Items
	
	mi = createMenuItem(popupmenu)
	mi.Caption = nameItemMenu
	popupmenu.Items.add(mi)
	
	AddItemMenu(mi, 'Create AA Simple', 'Ctrl+1', OnGenerateAASimpleClick)
	AddItemMenu(mi, 'Create AA Injection', 'Ctrl+2', OnGenerateAAInjectionClick)
	AddItemMenu(mi, 'Create AA Nop', 'Ctrl+3', OnGenerateAANopClick)
	AddItemMenu(mi, 'Disable CALL', 'Ctrl+5', OnGenerateAADisableCallClick)
	AddItemMenu(mi, 'Create AA AOBScanModule', 'Ctrl+6', OnGenerateAAAobScanModuleClick)
	AddItemMenu(mi, 'Create AA AOBScanModuleStealth', 'Ctrl+7', OnGenerateAAAobScanModuleStealthClick)
	
end

function AddItemMenuSeparatorInMemoryViewForm(functionSelectiontracker)
	local mv = getMemoryViewForm()
	local dv = mv.DisassemblerView

	--bug with dv.OnSelectionChange = functionSelectiontracker
	disassemblerview_onSelectionChange(dv, functionSelectiontracker)
	
	popupmenu = dv.PopupMenu
	mi = createMenuItem(popupmenu)
	mi.Caption = '-'
	popupmenu.Items.add(mi)
end
------------------------------------------------------
function generateAA(typeofcheat)
	setProperty(cmbCheatType,"Text", typeofcheat)
	cmbCheatTypeChange()
	btnOkClick()
end

function OnItemMenuCreateCheatClick(sender)	form_show(form) end
function OnGenerateAASimpleClick(sender) generateAA('Simple') end
function OnGenerateAAInjectionClick(sender) generateAA('Injection') end
function OnGenerateAANopClick(sender) generateAA('Nops') end
function OnGenerateAADisableCallClick(sender) generateAA('Disable CALL') end
function OnGenerateAAAobScanModuleClick(sender) generateAA('AOBScanModule') end
function OnGenerateAAAobScanModuleStealthClick(sender) generateAA('AOBScanModuleStealth') end

function OnItemMenuGetSignatureInfoClick(sender)
	print('--START--')
	local address = math.min(dv_address1, dv_address2)
	print('Address: '..getNameFromAddress(address)..' or '.. string.format('%08x', address))
	local stop = math.max(dv_address1, dv_address2)
	local length = stop + getInstructionSize(stop) - address
	local bytestring = readBytes(address, length, true)
	local strSignature = ''	
	local result
	local count = -1
	
	a2 = getPreviousOpcode(address)
	a1 = getPreviousOpcode(a2)
	a4 = address + getInstructionSize(address)
	a5 = a4 + getInstructionSize(a4)
	print('')
	print('Original view code:')
	print('   ' .. disassemble(a1))
	print('   ' .. disassemble(a2))
	print('   ' .. disassemble(address) .. '<<<')
	print('   ' .. disassemble(a4))
	print('   ' .. disassemble(a5))
	print('')

	if length <= 5  then
		print('Sorry. You must selected more 5 bytes')
		return
	end
	
	for i=1, length do strSignature = strSignature .. string.format('%02X ', bytestring[i]) end
	
	print('Start  AOBScan with : '.. strSignature)
	
	result = AOBScan(strSignature, '+X-C-W')
	
	if result == nil then
		print('   ' ..'Error! Your signature is not located in a section of code. Nothing Found! You need a privilege "+ X-C-W"')
		 
	else
		count = result.Count
		result.destroy()
		print('')
		if (count == 1) then print('   ' ..'Signature is unique. Good! :) ')
		else print('   ' ..string.format('Sorry. Signature is not unique. :( Found addresses = %s', count))	end
		print('')
		strSignature = getBytesForAOB(address,length,stop)
		print('Testing bytes string :  ' .. strSignature)
		print('')
	end
				
	print('Thank you for using this lua-plagin, GameHackLab[RU], 2009-2013(C)')		
	print('--END--')
end
------------------------------------------------------
function btnOkClick()
	local script = ''
	local address = math.min(dv_address1, dv_address2)
	local stop = math.max(dv_address1, dv_address2)
	local length = stop + getInstructionSize(stop) - address
	
	cheatType = getProperty(cmbCheatType,"Text")
	cheatName = getProperty(edCheatName,"Text")
	cheatValue = getProperty(edValue,"Text")
	cheatValueType = getProperty(cmbType,"Text")
	testBytes = getProperty(cbTestingBytes,"Checked")
	origCodeType = getProperty(cbOrigCodeType,"Checked")
	

	if cheatValueType == 'decimal' then cheatValueType = '#'
	elseif cheatValueType == 'float' then cheatValueType = '(float)'
	else cheatValueType = '' end
	

	if cheatType == 'Simple' then
		script = SimpleCodeTemplate
		originalCode,_,originalBytes = getOriginalCodeString(address, length)
		cheatCode = originalCode
	elseif cheatType == 'Injection' then
		script = AACodeTemplate
		originalCode, nops, originalBytes = getOriginalCodeString(address, 5, true)
		length = 5
		cheatCode = getCheatCode(address, cheatValue,cheatValueType)
	elseif cheatType == 'Nops' then
		script = SimpleCodeTemplate
		originalCode,cheatCode,originalBytes = getOriginalCodeString(address, length)
	elseif cheatType == 'AOBScanModule' then
		script = AOBSCANModuleCodeTemplate
		strSignature = getFullSignature(address, stop)
		if(strSignature == '') then
			return
		end
		originalCode, nops, originalBytes = getOriginalCodeString(address, 5, true)
		length = 5
		cheatCode = getCheatCode(address, cheatValue,cheatValueType)
	elseif cheatType == 'AOBScanModuleStealth' then
		script = AOBSCANModuleStealthCodeTemplate
		strSignature = getFullSignature(address, stop)
		if(strSignature == '') then
			return
		end
		originalCode, nops, originalBytes = getOriginalCodeString(address, 5, true)
		length = 5
		cheatCode = getCheatCode(address, cheatValue,cheatValueType)
	elseif cheatType == 'Disable CALL' then
		local ret = false
		script = SimpleCodeTemplate
		ret,address = getReturnFromCall(address)
		if ret == false then script = '' end	
	end
	
	if script ~= '' then
		script = string.gsub(script,"{$ArrayOfbyte}", strSignature)
		script = string.gsub(script,"{$AddressInjection}", getNameFromAddress(address))
		script = string.gsub(script,"{$CheatCode}", cheatCode)
		script = string.gsub(script,"{$NscriptCount}", scriptCount)
		
		if origCodeType == true then script = string.gsub(script,"{$OriginalCode}", originalBytes)
		else script = string.gsub(script,"{$OriginalCode}", originalCode) end
		
		if nops ~= '' then script = string.gsub(script,"{$Nops}", nops)
		else script = string.gsub(script,'\n?{$Nops}', '') end
	
		if cheatName ~= '' then
			scriptName = cheatName
			if string.find(cheatName, '^%d') ~= nil then
			cheatName = '_'..cheatName end
		else
			scriptName = 'New Script '..scriptCount
			cheatName = 'address'..scriptCount
			scriptCount = scriptCount + 1
		end
		
		script = string.gsub(script,'{$Date}', string.gsub(os.date('%x'),'/','-'))
		script = string.gsub(script,'{$ProcessName}', process)
		script = string.gsub(script,'{$PrintLog}', GetLog(getNameFromAddress(address), getNameFromAddress(length + address)))
		
		local newTableEntry = AddAARecord(script,scriptName)
		OpenAAEditor(newTableEntry)
	end
	form_hide(form)
end

function GetLine(address)
  local rez = disassemble(address)
  mAddress, opcode, bytes, extrafield = splitDisassembledString(rez)
  rez = string.format("%s: %s - %s", getNameFromAddress(address), bytes, opcode)
  return rez
end

function GetLog(addressStart, addressEnd)
	local logCode = [[
{
// ORIGINAL CODE - INJECTION POINT: {$INJECTPOINT}

{$TOP}
// ---------- INJECTING HERE ----------
{$MIDDLE}
// ---------- DONE INJECTING  ----------
{$BOTTOM}
}]]
    local top = ''
    local midle = ''
    local bottom = ''

    local prevAddress = addressStart

	for i = 1,10 do prevAddress = getPreviousOpcode(prevAddress) end

	for i = 1,10 do
       if(i < 10) then
          top = top..GetLine(prevAddress)..'\r\n'
       else
          top = top..GetLine(prevAddress)
       end
       prevAddress  = prevAddress + getInstructionSize(prevAddress)
	end


    local storyPrevAddress = prevAddress
	
    local andAddressDigit = getAddress(addressEnd)
    local countInstruction = 0
	for i = 1,100 do
        if(prevAddress >= andAddressDigit) then
            break
        end
        countInstruction = countInstruction + 1
        prevAddress  = prevAddress + getInstructionSize(prevAddress)
	end


    prevAddress = storyPrevAddress
    for i = 1,countInstruction do
       if(i < countInstruction) then
          midle = midle..GetLine(prevAddress)..'\r\n'
       else
          midle = midle..GetLine(prevAddress)
       end
       prevAddress  = prevAddress + getInstructionSize(prevAddress)
    end



    for i = 1,10 do
       if(i < 10) then
          bottom = bottom..GetLine(prevAddress)..'\r\n'
       else
          bottom = bottom..GetLine(prevAddress)
       end
       prevAddress = prevAddress + getInstructionSize(prevAddress)
	end

	logCode = string.gsub(logCode,'{$INJECTPOINT}', getNameFromAddress(addressStart))
	logCode = string.gsub(logCode,'{$TOP}', top)
	logCode = string.gsub(logCode,'{$MIDDLE}', midle)
	logCode = string.gsub(logCode,'{$BOTTOM}', bottom)

	return logCode
end

function cmbCheatTypeChange(sender)
	cheatType = getProperty(cmbCheatType,"Text")
	if cheatType == 'Nops' or cheatType == 'Disable CALL' then
		edValue.Enabled = false
		cmbType.Enabled = false
	else
		if checkPattern() then
			edValue.Enabled = true
			cmbType.Enabled = true
		end
	end
	if cheatType == 'AOBScanModule' or cheatType == 'AOBScanModuleStealth' then
		cbTestingBytes.Enabled = true
	else
		cbTestingBytes.Enabled = false
	end
end

function cbTestingBytesChange(sender)
	-------------------
end
------------------------------------------------------
setMethodProperty(cmbCheatType, 'OnChange', cmbCheatTypeChange)
--setMethodProperty(cbTestingBytes, 'OnChange', cbTestingBytesChange)
--btnOk.setOnClick(btnOkClick)
btnOk.OnClick = btnOkClick
------------------------------------------------------
AddItemMenuSeparatorInMemoryViewForm(OnSelectionTracker)
AddItemWithSubMenusInMemoryViewForm('* Quick AA Maker', OnSelectionTracker)
AddItemMenuInMemoryViewForm('* AA Maker Window', 'Ctrl+Z', OnItemMenuCreateCheatClick, OnSelectionTracker)
AddItemMenuInMemoryViewForm('* Get signature info (AA Maker)', 'Ctrl+Shift+I', OnItemMenuGetSignatureInfoClick, OnSelectionTracker)
