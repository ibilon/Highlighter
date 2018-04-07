package highlighter;

import highlighter.VscodeTextmate;

class CSS
{
	public static function generateStyle (registry:Registry) : String
	{
		var style = [];

		style.push('.highlighted { font-family: "Droid Sans Mono", "monospace", monospace, "Droid Sans Fallback"; font-size: 14; }');
		style.push(generateTokensCSSForColorMap(registry.getColorMap()));

		return style.join("\n");
	}

	// From https://github.com/Microsoft/vscode/blob/bdad49679a74feeedde2b1f5e3634d6b7aad0425/src/vs/editor/common/modes/supports/tokenization.ts#L386 (MIT License)
	static function generateTokensCSSForColorMap (colorMap:Array<String>) : String
	{
		var rules = [];

		for (i in 1...colorMap.length)
		{
			rules.push('.highlighted .mtk${i} { color: ${colorMap[i]}; }');
		}

		rules.push('.highlighted .mtki { font-style: italic; }');
		rules.push('.highlighted .mtkb { font-weight: bold; }');
		rules.push('.highlighted .mtku { text-decoration: underline; }');

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
