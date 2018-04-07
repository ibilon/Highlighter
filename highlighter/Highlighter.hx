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

enum RunData
{
	Style;
	StdinContent;
	FileContent(path:String);
	DataContent(content:String);
}

class Highlighter
{
	static function println (output:Output, message:String)
	{
		output.writeString(message);
		output.writeString("\n");
	}

	static function usage (output:Output)
	{
		println(output, "node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=style|content [--input=stdin|file] [--file=/path/to/file]");
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
		else if (args.length < 3)
		{
			println(cerr, "Some argument(s) are missing");
			usage(cerr);
			exit(1);
		}

		var grammar = "";
		var theme = "";
		var output = "";
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

				case "output":
					if (value == "style" || value == "content")
					{
						output = value;
					}
					else
					{
						println(cerr, 'Unknown value for output "${value}", should be either style or content');
						exit(1);
					}

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
		if (!FileSystem.exists(grammar))
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

		if (output == "content" && input == "")
		{
			println(cerr, "You need to specify an input mode when outputing content");
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

		if (output == "style")
		{
			cout.writeString(h.run(Style));
		}
		else if (input == "stdin")
		{
			cout.writeString(h.run(StdinContent));
		}
		else
		{
			cout.writeString(h.run(FileContent(file)));
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
	public function new (grammar:String, theme:String)
	{
		this.registry = new Registry();
		this.grammar = registry.loadGrammarFromPathSync(grammar);

		this.theme = Theme.load(theme);
		this.registry.setTheme({ name: this.theme.name, settings: this.theme.tokenColors });
	}

	/**
	Run the highlighter.

	@param data The data to run the highlighter on.
	**/
	public function run (data:RunData) : String
	{
		var cout = new BytesOutput();
		var input : Input = null;

		switch (data)
		{
			case Style:
				println(cout, CSS.generateStyle(registry));

			case FileContent(path):
				input = File.read(path, false);

			case DataContent(content):
				input = new BytesInput(Bytes.ofString(content));

			case StdinContent:
				input = new BytesInput(Bytes.ofString(NodeUtils.readAllStdin()));
		}

		if (data != Style)
		{
			println(cout, Code.generateHighlighted(grammar, input));
			input.close();
		}

		return cout.getBytes().toString();
	}
}
