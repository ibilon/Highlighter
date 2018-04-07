# Highlighter

Tool used to highlight text according to a textmate tmLanguage file.

Output CSS and HTML code.

The built-in themes are from [VSCode](https://github.com/Microsoft/vscode).

## Compilation

Get the required dependencies with:
```
npm install
haxelib install build.hxml
```

Then compile with:
```
haxe build.hxml
```

## Usage as a tool

```
node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=style|content [--input=stdin|file] [--file=/path/to/file]
```

To output the css styling:
`node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=style`

To output the highlighted content:
`node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=content --input=file --file=/path/to/file`

## Usage as a lib

You need to target nodejs, add `-lib highlighter` to your command.

First create a highlighter:
```haxe
var h = new highlighter.Highlighter("grammar/someGrammar.tmLanguage", "light");
```

Then you can use it to highlight:
```haxe
var s = h.run(DataContent("class C { }")); // Highlight a string

var s = h.run(FileContent("test/some.file")); // Highlight a file

var s = h.run(StdinContent); // Highlight the content of stdin, if you pipe a file
```

To get the css rules for the style you are using:
```haxe
var s = h.run(Style);
```

## License

[MIT](LICENSE.md)
