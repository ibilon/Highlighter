package highlighter;

import haxe.Json;
import highlighter.VscodeTextmate;
import sys.FileSystem;
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
		var data : ThemeData = Json.parse(getThemeContent(path.normalize()));

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

	static function getThemeContent (path:String) : String
	{
		if (FileSystem.exists(path))
		{
			return File.getContent(path);
		}

		return switch (path)
		{
			case "light_defaults.json":
				CompileTime.readFile("highlighter/themes/light_defaults.json");

			case "light", "light_plus.json":
				CompileTime.readFile("highlighter/themes/light_plus.json");

			case "light_vs.json":
				CompileTime.readFile("highlighter/themes/light_vs.json");

			case "dark_defaults.json":
				CompileTime.readFile("highlighter/themes/dark_defaults.json");

			case "dark", "dark_plus.json":
				CompileTime.readFile("highlighter/themes/dark_plus.json");

			case "dark_vs.json":
				CompileTime.readFile("highlighter/themes/dark_vs.json");

			default:
				throw 'File "${path}" doesn\'t exist';
		}
	}
}
