package highlighter;

import highlighter.VscodeTextmate;

#if haxe4
import js.lib.Uint32Array;
#else
import js.html.Uint32Array;
#end

typedef TokenData = {
	startIndex : Int,
	endIndex : Int,
	languageID : LanguageId,
	tokenType : StandardTokenType,
	fontStyle : FontStyle,
	forground : Int,
	background : Int,
}

class Token
{
	public static function process (raw_tokens:Uint32Array, line_length:Int) : Array<TokenData>
	{
		var tokens : Array<TokenData> = [];
		var i = 0;

		while (i < raw_tokens.length)
		{
			var start = raw_tokens[i++];
			var meta = raw_tokens[i++];

			tokens.push(make(start, meta));
		}

		for (i in 0...tokens.length - 1)
		{
			tokens[i].endIndex = tokens[i + 1].startIndex;
		}
		tokens[tokens.length - 1].endIndex = line_length;

		return tokens;
	}

	static function make (start:UInt, meta:UInt) : TokenData
	{
		return {
			startIndex: start,
			endIndex: 0,
			languageID: cast (meta & MetadataConsts.LANGUAGEID_MASK) >> MetadataConsts.LANGUAGEID_OFFSET,
			tokenType: cast (meta & MetadataConsts.TOKEN_TYPE_MASK) >> MetadataConsts.TOKEN_TYPE_OFFSET,
			fontStyle: cast (meta & MetadataConsts.FONT_STYLE_MASK) >> MetadataConsts.FONT_STYLE_OFFSET,
			forground: (meta & MetadataConsts.FOREGROUND_MASK) >> MetadataConsts.FOREGROUND_OFFSET,
			background: (meta & MetadataConsts.BACKGROUND_MASK) >> MetadataConsts.BACKGROUND_OFFSET,
		}
	}
}
