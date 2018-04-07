package highlighter;

import haxe.io.Eof;
import haxe.io.Input;
import highlighter.VscodeTextmate;

using StringTools;

class Code
{
	public static function generateHighlighted (grammar:IGrammar, input:Input) : String
	{
		var result = [];
		result.push('<pre class="highlighted">\n');

		var ruleStack = null;
		var line;

		while (true)
		{
			try
			{
				line = input.readLine();
			}
			catch (e:Eof)
			{
				break;
			}

			if (line == "")
			{
				result.push("\n");
				continue;
			}

			var r = grammar.tokenizeLine2(line, ruleStack);
			var tokens = Token.process(r.tokens, line.length);

			for (token in tokens)
			{
				var text = line.substring(token.startIndex, token.endIndex);

				text = text.htmlEscape(true);
				text = text.replace("\t", "    ");

				result.push('<span class="${CSS.getClass(token)}">${text}</span>');
			}

			ruleStack = r.ruleStack;
			result.push("\n");
		}

		result.push("</pre>");
		return result.join("");
	}
}
