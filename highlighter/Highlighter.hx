package highlighter;

import Sys.exit;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Output;
import highlighter.VscodeTextmate;
import sys.FileSystem;
import sys.io.File;

class Highlighter
{
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
		var theme = "light";
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
		var h = new Highlighter(grammar, theme);

		if (command == "css")
		{
			cout.writeString(h.runCss());
		}
		else if (input == "stdin")
		{
			cout.writeString(h.runStdin());
		}
		else
		{
			cout.writeString(h.runFile(file));
		}
	}

	var registry : Registry;
	var grammar : IGrammar;
	var theme : Theme.ThemeData;

	/**
	Create a highlighter.

	@param grammar The path to the grammar file.
	@param theme The path to the theme.
	**/
	public function new (grammar:String, theme:String = "light")
	{
		this.registry = new Registry();

		if (grammar != "")
		{
			this.grammar = registry.loadGrammarFromPathSync(grammar);
		}

		this.theme = Theme.load(theme);
		this.registry.setTheme({ name: this.theme.name, settings: this.theme.tokenColors });
	}

	/**
	Get the CSS for the theme.
	**/
	public function runCss () : String
	{
		var cout = new BytesOutput();
		println(cout, CSS.generateStyle(registry));
		return cout.getBytes().toString();
	}

	function run (input:Input) : String
	{
		var cout = new BytesOutput();

		println(cout, Code.generateHighlighted(grammar, input));
		input.close();
		return cout.getBytes().toString();
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
}
