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
			languageID: cast (meta & EncodedTokenDataConsts.LANGUAGEID_MASK) >> EncodedTokenDataConsts.LANGUAGEID_OFFSET,
			tokenType: cast (meta & EncodedTokenDataConsts.TOKEN_TYPE_MASK) >> EncodedTokenDataConsts.TOKEN_TYPE_OFFSET,
			fontStyle: cast (meta & EncodedTokenDataConsts.FONT_STYLE_MASK) >> EncodedTokenDataConsts.FONT_STYLE_OFFSET,
			forground: (meta & EncodedTokenDataConsts.FOREGROUND_MASK) >> EncodedTokenDataConsts.FOREGROUND_OFFSET,
			background: (meta & EncodedTokenDataConsts.BACKGROUND_MASK) >> EncodedTokenDataConsts.BACKGROUND_OFFSET,
		}
	}
}
