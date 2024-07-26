package highlighter;

import js.lib.Promise;
import Sys.exit;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Output;
import haxe.io.Path;
import haxe.xml.Parser.XmlParserException;
import highlighter.VscodeTextmate;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Highlighter
{
	private static inline var DEFAULT_THEME = "light";

	static function println (output:Output, message:String)
	{
		output.writeString(message);
		output.writeString("\n");
	}

	static function usage (output:Output)
	{
		println(output, "node bin/highlighter.js css [--theme=light|dark|/path/to/file]");
		println(output, "node bin/highlighter.js highlight --grammar=/path/to/file --input=stdin|file [--file=/path/to/file] [--theme=light|dark|/path/to/file]");
	}

	public static function main ()
	{
		// Process args
		var args = Sys.args();
		var cout = Sys.stdout();
		var cerr = Sys.stderr();

		if (args.length == 0)
		{
			usage(cout);
			exit(0);
		}
		else if (args.length < 1)
		{
			println(cerr, "Missing command");
			usage(cerr);
			exit(1);
		}

		var command = args.shift();

		if (command != "css" && command != "highlight")
		{
			println(cerr, 'Unknown command "${command}"');
			usage(cerr);
			exit(1);
		}

		var grammar = "";
		var theme = DEFAULT_THEME;
		var input = "";
		var file = "";

		for (arg in args)
		{
			var cut = arg.indexOf("=");

			if (cut == -1)
			{
				println(cerr, 'Unknown argument: "${arg}"');
				exit(1);
			}

			var name = arg.substring(2, cut);
			var value = arg.substr(cut + 1);

			switch (name)
			{
				case "grammar":
					grammar = value;

				case "theme":
					theme = value;

				case "input":
					if (value == "stdin" || value == "file")
					{
						input = value;
					}
					else
					{
						println(cerr, 'Unknown value for input "${value}", should be either stdin or file');
						exit(1);
					}

				case "file":
					file = value;

				default:
					println(cerr, 'Unknown argument "${name}"');
					exit(1);
			}
		}

		// Validate args
		if (command == "highlight" && input == "")
		{
			println(cerr, "You need to specify an input mode when highlighting");
			exit(1);
		}

		if (command == "highlight" && grammar == "")
		{
			println(cerr, "You need to specify a grammar when highlighting");
			exit(1);
		}

		if (command == "highlight" && !FileSystem.exists(grammar))
		{
			println(cerr, 'Grammar file "${grammar}" doesn\'t exist');
			exit(1);
		}

		if (theme == "light")
		{
			theme = "light_plus.json";
		}

		if (theme == "dark")
		{
			theme = "dark_plus.json";
		}

		if (theme != "light_plus.json" && theme != "dark_plus.json" && !FileSystem.exists(theme))
		{
			println(cerr, 'Theme file "${theme}" doesn\'t exist');
			exit(1);
		}

		if (input == "file" && file == "")
		{
			println(cerr, "You need to specify a file");
			exit(1);
		}

		if (input == "file" && !FileSystem.exists(file))
		{
			println(cerr, 'Input file "${file}" doesn\'t exist');
			exit(1);
		}

		// Run it
		loadHighlighter(grammar, theme, (highlighter) -> {
			cout.writeString(
				if (command == "css") {
					highlighter.runCss();
				} else if (input == "stdin") {
					highlighter.runStdin();
				} else {
					highlighter.runFile(file);
				}
			);
		});
	}

	private static function loadOnigLib () {
		return VscodeOniguruma.loadWASM(js.node.Fs.readFileSync('./node_modules/vscode-oniguruma/release/onig.wasm')).then((Void) -> {
			return {
				createOnigScanner: function(patterns)
				{
					return new VscodeOniguruma.OnigScanner(patterns);
				},
				createOnigString: function(s)
				{
					return new VscodeOniguruma.OnigString(s);
				}
			};
		});
	}

	public static function loadHighlighter (filePath:String, themeName:String = DEFAULT_THEME, callback:Highlighter->Void) {
		final theme = Theme.load(themeName);
		final vscodeOnigurumaLib = loadOnigLib();
		final registry = new Registry({theme: theme, onigLib: vscodeOnigurumaLib});
		registry.addGrammar(VscodeTextmate.parseRawGrammar(sys.io.File.getContent(filePath), filePath)).then(
			function(grammar) {
				callback(new Highlighter(registry, grammar));
			}
		);
	}

	public static function loadHighlighters (grammarFiles:Map<String, String>, themeName:String = DEFAULT_THEME, callback:Map<String, Highlighter>->Void) {
		final theme = Theme.load(themeName);
		final promises = [];
		final vscodeOnigurumaLib = loadOnigLib();

		for (path in grammarFiles) {
			final registry = new Registry({theme: theme, onigLib: vscodeOnigurumaLib });
			final rawGrammar = VscodeTextmate.parseRawGrammar(sys.io.File.getContent(path), path);
			promises.push(registry.addGrammar(rawGrammar)
				.then(g -> {path: path, registry: registry, grammar: g}));
		}

		Promise.allSettled(promises).then(
			function(grammars) {
				final highlighersByPath = new Map<String, Highlighter>();
				for (grammar in grammars) {
					if (grammar.status == Fulfilled) {
						highlighersByPath[grammar.value.path] = new Highlighter(grammar.value.registry, grammar.value.grammar);
					}
				}
				final highlightersByName = new Map<String, Highlighter>();

				for (name => path in grammarFiles) {
					highlightersByName[name] = highlighersByPath[path];
				}

				callback(highlightersByName);
			}
		);
	}

	final grammar : IGrammar;
	final registry : Registry;

	/**
		Create a highlighter.

		@param registry The registry object where the grammar has been loaded.
		@param grammar The grammar object.
	**/
	private function new (registry:Registry, grammar:IGrammar)
	{
		this.registry = registry;
		this.grammar = grammar;
	}

	/**
	Get the CSS for the theme.
	**/
	public function runCss () : String
	{
		return CSS.generateStyle(registry.getColorMap());
	}

	/**
	Run the highlighter on the stdin.
	**/
	public function runStdin () : String
	{
		var input = new BytesInput(Bytes.ofString(NodeUtils.readAllStdin()));
		return Code.generateHighlighted(grammar, input);
	}

	/**
	Run the highlighter on some content.

	@param content The content to highlight.
	**/
	public function runContent (content:String) : String
	{
		var input = new BytesInput(Bytes.ofString(content));
		return Code.generateHighlighted(grammar, input);
	}

	/**
	Run the highlighter on some file.

	@param content The content to highlight.
	**/
	public function runFile (path:String) : String
	{
		var input = File.read(path, false);
		return Code.generateHighlighted(grammar, input);
	}

	/**
	Patch the code blocks of a HTML file.

	@param path The path of the file to patch.
	@param grammars The available grammars.
	@param getLang A function used to go from css class list to grammar name.
	**/
	public static function patchFile (path:String, grammars:Map<String, Highlighter>, getLang:String->String) : Array<String>
	{
		try
		{
			var xml = Xml.parse(File.getContent(path));
			var missing = new Map<String, Bool>();

			processNode(grammars, getLang, xml, missing);

			var result = ~/&amp;([a-z]+;)/g.replace(xml.toString(), "&$1");
			File.saveContent(path, result);

			var a = [];
			for (k in missing.keys())
			{
				if (k != "")
				{
					a.push(k);
				}
			}
			return a;
		}
		catch (e:Dynamic)
		{
			if (Std.is(e, XmlParserException))
			{
				var e = cast(e, XmlParserException);
				Sys.println('${e.message} at line ${e.lineNumber} char ${e.positionAtLine}');
				Sys.println(e.xml.substr(e.position - 20, 40));
			}
			else
			{
				Sys.println(e);
			}

			Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			throw('Error when parsing "$path"');
		}
	}

	/**
	Patch the code blocks of HTML files in a directory.

	@param path The path of the directory to patch.
	@param grammars The available grammars.
	@param getLang A function used to go from css class list to grammar name.
	@param recursive If the patching should enter the subdirectories.
	**/
	public static function patchFolder (path:String, grammars:Map<String, Highlighter>, getLang:String->String, recursive:Bool = true) : Array<String>
	{
		var missing = new Map<String, Bool>();

		for (entry in FileSystem.readDirectory(path))
		{
			var entry_path = Path.join([path, entry]);

			if (FileSystem.isDirectory(entry_path))
			{
				if (recursive)
				{
					var folder_missing = patchFolder(entry_path, grammars, getLang, true);

					for (k in folder_missing)
					{
						missing.set(k, true);
					}
				}
			}
			else if (Path.extension(entry_path) == "html")
			{
				var file_missing = patchFile(entry_path, grammars, getLang);

				for (k in file_missing)
				{
					missing.set(k, true);
				}
			}
		}

		var a = [];
		for (k in missing.keys())
		{
			if (k != "")
			{
				a.push(k);
			}
		}
		return a;
	}

	static function processNode (grammars:Map<String, Highlighter>, getLang:String->String, xml:Xml, missingGrammars:Map<String, Bool>)
	{
		if (xml.nodeType == Xml.Element)
		{
			switch (xml.nodeName)
			{
				case "pre":
					var code = xml.firstChild();

					if (code.nodeType != Xml.Element)
					{
						return;
					}

					var lang = code.exists("class") ? getLang(code.get("class")) : "";

					if (grammars.exists(lang))
					{
						var original = code.firstChild().toString().htmlUnescape();
						var highlighted = grammars.get(lang).runContent(original);
						var new_xml = Xml.parse(highlighted);
						var siblings = [for (n in xml.parent) n];
						xml.parent.insertChild(new_xml, siblings.indexOf(xml));
						xml.parent.removeChild(xml);
					}
					else
					{
						missingGrammars.set(lang, true);
					}

				default:
					processChildren(grammars, getLang, xml, missingGrammars);
			}
		}

		if (xml.nodeType == Xml.Document)
		{
			processChildren(grammars, getLang, xml, missingGrammars);
		}
	}

	static function processChildren (grammars:Map<String, Highlighter>, getLang:String->String, xml:Xml, missingGrammars:Map<String, Bool>)
	{
		var children = [for (n in xml) n];

		for (element in children)
		{
			processNode(grammars, getLang, element, missingGrammars);
		}
	}
}
