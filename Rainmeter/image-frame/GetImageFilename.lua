function GetImageFilename(fullpath)
        return SplitPath(fullpath, 'FILE')
end

function SplitPath(pathArg, pathBit)
	path, file, ext = string.match(pathArg, '(.-)([^\\/]-%.?([^%.\\/]*))$')

	if string.upper(pathBit) == 'PATH' then
		return path
	elseif string.upper(pathBit) == 'FILE' then
		return file
	elseif string.upper(pathBit) == 'EXT' then
		return ext
	else
		return 'Invalid component'		
	end

end

function GetNextUpdateInterval(currentinterval)
	if currentinterval == -1 then
		return 20
	end

	return -1
end

function IncScaleFactor(current)
	return GetNextScaleFactor(current, true)
end

function DecScaleFactor(current)
	return GetNextScaleFactor(current, false)
end

function GetNextScaleFactor(current, direction)
	if direction and current < 4.0 then
		return current * 2.0
	elseif not direction and current > 0.5 then
		return current / 2.0

	end

	return current
end
