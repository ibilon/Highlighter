package highlighter;

@:jsRequire("vscode-oniguruma", "OnigScanner")
extern class OnigScanner {
	function new(patterns:Array<String>);
}

@:jsRequire("vscode-oniguruma", "OnigString")
extern class OnigString {
	function new(content:String);
}

@:jsRequire("vscode-oniguruma")
extern class VscodeOniguruma {
	static function loadWASM(path:js.lib.ArrayBufferView):js.lib.Promise<Void>;
}
