#!/usr/bin/env node

const yargsInteractive = require('yargs-interactive')

const options = {
	name: {
		type: 'input',
		default: 'nano',
		describe: 'Enter your name'
	},
	likesPizza: {
		type: 'confirm',
		default: false,
		describe: 'Do you like pizza?'
	},
	interactive: {default: true}
}

yargsInteractive()
	.usage('$0 <command> [args]')
	.interactive(options)
	.then(result => {
		// The tool will prompt questions and will output your answers.
		// TODO: Do something with the result (e.g result.name)
		console.log(result)
	})
