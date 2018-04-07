import VscodeTextmate;
import haxe.Json;
import sys.io.File;

using haxe.io.Path;

typedef ThemeData = {
	name : String,
	?include : String,
	?tokenColors : Array<IRawThemeSetting>
}

class Theme
{
	public static function load (path:String) : ThemeData
	{
		var data : ThemeData = Json.parse(File.getContent(path));

		if (data.tokenColors == null)
		{
			data.tokenColors = [];
		}

		if (data.include != null)
		{
			var dir = path.directory();

			if (dir == "")
			{
				dir = ".";
			}

			var sub = load(dir + "/" + data.include);
			data.tokenColors = sub.tokenColors.concat(data.tokenColors);
		}

		return data;
	}
}
