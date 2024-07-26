package highlighter;

class CSS
{
	public static function generateStyle (colorMap:Array<String>) : String
	{
		var style = [];

		style.push('.highlighted { font-family: "Droid Sans Mono", "monospace", monospace, "Droid Sans Fallback"; font-size: 14px; }');
		style.push(generateTokensCSSForColorMap(colorMap));

		return style.join("\n");
	}

	// From https://github.com/microsoft/vscode/blob/70ffbbae97485ba914dd4a7cd19f9f7d8af125cd/src/vs/editor/common/languages/supports/tokenization.ts#L412 (MIT License)
	static function generateTokensCSSForColorMap (colorMap:Array<String>) : String
	{
		var rules = [];

		for (i in 1...colorMap.length)
		{
			rules.push('.highlighted .mtk${i} { color: ${colorMap[i]}; }');
		}

		rules.push('.highlighted .mtki { font-style: italic; }');
		rules.push('.highlighted .mtkb { font-weight: bold; }');
		rules.push('.highlighted .mtku { text-decoration: underline; text-underline-position: under; }');
		rules.push('.highlighted .mtks { text-decoration: line-through; }');
		rules.push('.highlighted .mtks.mtku { text-decoration: underline line-through; text-underline-position: under; }');

		return rules.join('\n');
	}

	public static function getClass (token:Token.TokenData) : String
	{
		var classes = [];

		classes.push('mtk${token.forground}');

		switch (token.fontStyle)
		{
			case NotSet, None:

			case Italic:
				classes.push("mkti");

			case Bold:
				classes.push("mktb");

			case Underline:
				classes.push("mktu");
		}

		return classes.join(" ");
	}
}
