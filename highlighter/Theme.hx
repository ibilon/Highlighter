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
	public static function load (path:String) : IRawTheme
	{
		var currentPath : Null<String> = path;
		final themeData = [];

		while (currentPath != null) {
			final data : ThemeData = Json.parse(getThemeContent(currentPath.normalize()));
			themeData.push(data);

			currentPath = switch data.include {
				case null: null;
				case filename:
					final directory = currentPath.directory();
					currentPath = if (directory == "") './$filename' else '$directory/$filename';
			};
		}

		return {
			name: themeData[0].name,
			settings: Lambda.flatMap(themeData, function(item) {
				return item.tokenColors != null ? item.tokenColors : [];
			})
		};
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
		};
	}
}
