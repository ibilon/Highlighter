# Highlighter

Tool used to highlight text according to a textmate tmLanguage file.

Output CSS and HTML code.

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

## Usage

```
node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=style|content [--input=stdin|file] [--file=/path/to/file]
```

To output the css styling:
`node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=style`

To output the highlighted content:
`node bin/highlighter.js --grammar=/path/to/file --theme=light|dark|/path/to/file --output=content --input=file --file=/path/to/file`

The built-in themes are from [VSCode](https://github.com/Microsoft/vscode).

## License

[MIT](LICENSE.md)
