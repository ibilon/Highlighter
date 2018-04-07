import js.html.Uint32Array;

@:jsRequire("vscode-textmate", "Registry")
extern class Registry {
    function new();
	function setTheme(theme:IRawTheme):Void;
    function loadGrammarFromPathSync(path:String):IGrammar;
	function getColorMap():Array<String>;
}

typedef IRawTheme = {
	?name:String,
	settings:Array<IRawThemeSetting>,
}

typedef IRawThemeSetting = {
	?name:String,
	?scope:haxe.extern.EitherType<String, Array<String>>,
	settings:{
		?fontStyle:String,
		?foreground:String,
		?background:String
	},
}

typedef IGrammar = {
    function tokenizeLine(lineText:String, ?prevState:StackElement):ITokenizeLineResult;
	function tokenizeLine2(lineText:String, ?prevState:StackElement):ITokenizeLineResult2;
}

typedef ITokenizeLineResult = {
    var tokens(default,null):Array<IToken>;
    var ruleStack(default,null):StackElement;
}

typedef IToken = {
    var startIndex:Int;
    var endIndex(default,null):Int;
    var scopes(default,null):Array<String>;
}

@:enum abstract StandardTokenType(Int) {
	var Other = 0;
	var Comment = 1;
	var String = 2;
	var RegEx = 4;
}

typedef ITokenizeLineResult2 = {
	var tokens(default, null):Uint32Array;
	var ruleStack(default, null):StackElement;
}

class MetadataConsts {
	public static inline var LANGUAGEID_MASK : UInt = 255;
	public static inline var TOKEN_TYPE_MASK : UInt = 1792;
	public static inline var FONT_STYLE_MASK : UInt = 14336;
	public static inline var FOREGROUND_MASK : UInt = 8372224;
	public static inline var BACKGROUND_MASK : UInt = cast 4286578688;

	public static inline var LANGUAGEID_OFFSET = 0;
	public static inline var TOKEN_TYPE_OFFSET = 8;
	public static inline var FONT_STYLE_OFFSET = 11;
	public static inline var FOREGROUND_OFFSET = 14;
	public static inline var BACKGROUND_OFFSET = 23;
}

@:enum abstract LanguageId(Int) {
	var Null = 0;
	var PlainText = 1;
}

@:enum abstract FontStyle(Int) {
	var NotSet = -1;
	var None = 0;
	var Italic = 1;
	var Bold = 2;
	var Underline = 4;
}

typedef StackElement = {
}
