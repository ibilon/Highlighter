package highlighter;

import js.node.Buffer;
import js.node.Fs;

class NodeUtils
{
	/**
	From https://stackoverflow.com/a/16048083 thanks!
	**/
	public static function readAllStdin () : String
	{
		var BUFSIZE = 256;
		var buf = new Buffer(BUFSIZE);
		var bytesRead;

		var fullBuf = new StringBuf();
		var fd = Fs.openSync("/dev/stdin", "rs");

		while (true)
		{
			bytesRead = 0;

			try
			{
				bytesRead = Fs.readSync(fd, buf, 0, BUFSIZE, null);
			}
			catch (e:Dynamic)
			{
				if (e.code == 'EAGAIN')
				{
					throw 'ERROR: interactive stdin input not supported.';
				}
				else if (e.code == 'EOF')
				{
					break;
				}

				throw e;
			}

			if (bytesRead == 0)
			{
				break;
			}

			fullBuf.add(buf.toString());
		}

		return fullBuf.toString();
	}
}
