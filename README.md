# vim-autoprettier

This plugin will automatically process the current buffer using [prettier](https://prettier.io) when saving.

Prettier will only be used if `prettier --find-config-path` returns a config file for the file being edited _and_ if the current file is of a prettifiable type. By default only 'typescript' and 'javascript' files are processed. This can be configured by setting `g:autoprettier_types` to a list of filetypes that should be processed.

```vim
let g:autoprettier_types = [
	\ 'typescript',
	\ 'javascript',
	\ 'json'
	\ ]
```

If prettier fails, the buffer will not be changed and any errors will be reported as vim error messages.
