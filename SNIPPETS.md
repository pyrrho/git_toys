Running these demos and learning a thing should be easy. As should reading the
actual scripts, that should be easy too. You know what else should be easy?
Writing the damn things.

To make writing the damn things a little bit easier, have some VS Code snippets
that you can use to make sure you don't mess up the HEREdocs that we're
liberally ~abusing~ using.

To apply them, simply hit `ctrl+shift+p` (`cmd+shift+p` for osx), type in
`Preferences: Configure User Snippets`, type in `shellscript.json`, and paste
this goodness into the file that VS Code opened up for you.

```
{
	"Title Block": {
		"prefix": "title",
		"body": [
			"stitle 3<<EOM",
			"${1:Title Text}",
			"EOM",
			""
		],
		"description": "Open a new Title block (correctly) (and then close it, too)"
	},
	"Message Block": {
		"prefix": "msg",
		"body": [
			"smsg 3<<EOM",
			"${1:Message text}",
			"EOM",
			""
		],
		"description": "Open a new Message block (correctly) (and then close it, too)"
	},
	"Wait Message Block": {
		"prefix": "wsg",
		"body": [
			"swsg 3<<EOM",
			"${1:Message text}",
			"EOM",
			""
		],
		"description": "Open a new Wait Message block (correctly) (and then close it, too)"
	},
	"Show Commands Block": {
		"prefix": "showcmd",
		"body": [
			"showcmd \"${1:Header}\" 3<<'SCRIPT'",
			"    ${2:echo \"Hello World\"}",
			"SCRIPT",
			"$0"
		],
		"description": "Open a new Show Commands block (correctly) (and then close it, too)"
	},
	"Show Single Command": {
		"prefix": "show_single_cmd",
		"body": [
			"show_single_cmd ${0:echo \"Hello World\"}"
		],
		"description": "Execute the Show Single Command fuction (correctly)"
	},
	"Start Logging": {
		"prefix": "log",
		"body": [ "{ set -x; } 2>/dev/null"],
		"description": "Start logging commands without printing the start logging commands command"
	},
	"Stop Logging": {
		"prefix": "nolog",
		"body": [ "{ set +x; } 2>/dev/null"],
		"description": "Stop logging commands without printing the stop logging commands command"
	},
	"Exit On Errors": {
		"prefix": "err",
		"body": [ "{ set -e; } 2>/dev/null"],
		"description": "Configure the shell to exit whenever a non-zero exit code is returned by a command, without printing the command to make that happen."
	},
	"Continue On Errors": {
		"prefix": "noerr",
		"body": [ "{ set +e; } 2>/dev/null"],
		"description": "Configure the shell to continue whenever a non-zero exit code is returned by a command, without printing the command to make that happen."
	}
}
