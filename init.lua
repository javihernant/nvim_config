vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.wo.number = true
vim.o.clipboard = 'unnamedplus'
vim.o.termguicolors = true

-- Restore cursor position
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
	pattern = { "*" },
	callback = function()
		vim.api.nvim_exec('silent! normal! g`"zv', false)
	end,
})


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		-- Theme inspired by Atom
		'navarasu/onedark.nvim',
		priority = 1000,
		lazy = false,
		config = function()
			require('onedark').setup {
				-- Set a style preset. 'dark' is default.
				style = 'darker', -- dark, darker, cool, deep, warm, warmer, light
			}
			require('onedark').load()
		end,
	},
	{
		-- Set lualine as statusline
		'nvim-lualine/lualine.nvim',
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = false,
				theme = '16color',
				component_separators = '|',
				section_separators = '',
			},
		},
	},
	-- Git related
	{
		'tpope/vim-fugitive',
		'tpope/vim-rhubarb',
		'lewis6991/gitsigns.nvim',
	},

	-- Fuzzy Finder (files, lsp, etc)
	{
		'nvim-telescope/telescope.nvim',
		branch = '0.1.x',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{
				'nvim-telescope/telescope-fzf-native.nvim',
				build =
				'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
			},
		},
	},

	-- "gc" to comment visual regions/lines
	{ 'numToStr/Comment.nvim', opts = {} },

	-- LSP plugins
	{
		-- 'williamboman/mason.nvim',
		-- 'williamboman/mason-lspconfig.nvim',
		'neovim/nvim-lspconfig', -- Collection of configurations for built-in LSP client
		'hrsh7th/nvim-cmp', -- Autocompletion plugin
		'hrsh7th/cmp-nvim-lsp', -- LSP source for nvim-cmp
		'saadparwaiz1/cmp_luasnip', -- Snippets source for nvim-cmp
		'L3MON4D3/LuaSnip', -- Snippets plugin
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
	}


}, {})

-- [[ Configure Telescope ]]
require('telescope').setup {
	defaults = {
		prompt_prefix = '$ ',
		mappings = {
			i = {
				['<C-u>'] = false,
				['<C-d>'] = false,
			},
		},
	},
}

-- See `:help telescope.builtin`

local function telescope_live_grep_open_files()
	require('telescope.builtin').live_grep {
		grep_open_files = true,
		prompt_title = 'Live Grep in Open Files',
	}
end

vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
	require('telescope.builtin').current_buffer_fuzzy_find()
end, { desc = '[/] Fuzzily search in current buffer' })

-- vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files, { desc = '[S]earch [/] in Open Files' })

require('telescope').load_extension('fzf')


-- [[ Configure code completion ]]

local lspconfig = require('lspconfig')

-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'lua_ls', 'rust_analyzer', 'pyright', 'denols', 'tsserver' }
local on_attach = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format { async = true }
			end,
		})
	end
end

for _, lsp in ipairs(servers) do
	if lsp == "tsserver" then
		lspconfig.tsserver.setup {
			capabilities = capabilities,
			root_dir = lspconfig.util.root_pattern("package.json"),
			single_file_support = false
		}
	elseif lsp == "denols" then
		lspconfig.denols.setup {
			on_attach = on_attach,
			capabilities = capabilities,
			root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
		}
	else
		lspconfig[lsp].setup {
			-- on_attach = my_custom_on_attach,
			capabilities = capabilities,
		}
	end
end

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
		['<C-d>'] = cmp.mapping.scroll_docs(4), -- Down
		-- C-b (back) C-f (forward) for snippet placeholder navigation.
		['<C-Space>'] = cmp.mapping.complete(),
		['<CR>'] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		},
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { 'i', 's' }),
		['<S-Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { 'i', 's' }),
	}),
	sources = {
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
	},
}

-- [[ Configure LSP related stuff ]]

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		local telescope = require 'telescope.builtin'
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }

		vim.keymap.set('n', '<leader>ss', telescope.lsp_document_symbols, opts)
		vim.keymap.set('n', '<leader>sS', telescope.lsp_workspace_symbols, opts)
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
		vim.keymap.set('n', 'gd', telescope.lsp_definitions, opts)
		vim.keymap.set('n', 'gt', telescope.lsp_type_definitions, opts)
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
		vim.keymap.set('n', 'gi', telescope.lsp_implementations, opts)
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
		vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
		vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
		vim.keymap.set('n', '<space>wl', function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, opts)
		vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
		vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
		vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
		vim.keymap.set('n', 'gr', telescope.lsp_references, opts)
		vim.keymap.set('n', '<space>f', function()
			vim.lsp.buf.format { async = true }
		end, opts)
	end,
})



-- [[ Configure Treesiter ]]


-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
require('nvim-treesitter.configs').setup {
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html", "rust", "typescript" },
	sync_install = false,
	highlight = {
		enable = true,
		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "gnn", -- set to `false` to disable one of the mappings
			node_incremental = "grn",
			scope_incremental = "grc",
			node_decremental = "grm",
		},
	},
	textobjects = {
		select = {
			enable = true,

			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,

			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				-- You can optionally set descriptions to the mappings (used in the desc parameter of
				-- nvim_buf_set_keymap) which plugins like which-key display
				["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
				-- You can also use captures from other query groups like `locals.scm`
				["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
			},
			-- You can choose the select mode (default is charwise 'v')
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * method: eg 'v' or 'o'
			-- and should return the mode ('v', 'V', or '<c-v>') or a table
			-- mapping query_strings to modes.
			selection_modes = {
				['@parameter.outer'] = 'v', -- charwise
				['@function.outer'] = 'V', -- linewise
				['@class.outer'] = '<c-v>', -- blockwise
			},
			-- If you set this to `true` (default is `false`) then any textobject is
			-- extended to include preceding or succeeding whitespace. Succeeding
			-- whitespace has priority in order to act similarly to eg the built-in
			-- `ap`.
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * selection_mode: eg 'v'
			-- and should return true of false
			include_surrounding_whitespace = true,
		},
	},
}
-- setup ufo (fold code)
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
require('ufo').setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { 'treesitter', 'indent' }
	end
})
--Git-signs
require('gitsigns').setup()
