local project_type = vim.fn.getenv("NVIM_PROJECT_TYPE")
-- supported options:
-- 1. personal
-- 2. work
-- 3. server
-- 4. leetcode

local ensure_installed = {}

if project_type == "work" then
	ensure_installed = { "gopls", "lua_ls", "pyright", "tsserver", "eslint" }
elseif project_type == "server" then
	-- no lsps
elseif project_type == "leetcode" then
	-- no lsps
else
	-- personal and default
	ensure_installed = { "gopls", "lua_ls" }
end


local declaration_keymap = 'gD'                    -- GD key for finding the variable declarations
local definition_keymap = 'gd'                     -- GD key for finding the variable definitions
local hover_keymap = 'K'                           -- K key to display hover documentations
local implementation_keymap = 'gi'                 -- GI for implementation of interfaces
local signature_help_keymap = '<C-k>'              -- Control K to view function signature help
local add_workspace_folder_keymap = '<space>wa'    -- Space wa to add workspace folder
local remove_workspace_folder_keymap = '<space>wr' -- Space wr to remove workspace folder
local list_workspace_folders_keymap = '<space>wl'  -- Space wl to list workspace folder
local type_definition_keymap = '<space>D'          -- Space D to go to type definitions of selected variable
local rename_keymap = '<space>rn'                  -- Space rn to rename symbol or variable
local code_action_keymap = '<space>ca'             -- Space ca executes code actions
local references_keymap = 'gr'                     -- GR to find reference of variable or symbol in scope
local formatting_keymap = '<space>f'               -- Space f to format the document


local lsp_zero = require('lsp-zero')
lsp_zero.set_server_config({
	on_init = function(client)
		client.server_capabilities.semanticTokensProvider = nil -- this prevents lsps from trying to format on top of my existing treesitter color scheme
	end,
})


-- Mason setup
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = ensure_installed,
	automatic_installation = true,
	handlers = {
		lsp_zero.default_setup,
		lua_ls = function()
			local lua_opts = lsp_zero.nvim_lua_ls()
			require('lspconfig').lua_ls.setup(lua_opts)
		end,
		gopls = function() -- Custom handler for gopls
			local gopls_opts = {
				settings = {
					gopls = {
						analyses = {
							-- ref: https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
							unusedparams = true,
							shadow = true,
							unusedvariable = true,
							unusedwrite = true,
							useany = true,
						},
						completeUnimported = true,
						usePlaceholders = false, -- disabling because it is not working properly
						staticcheck = true, -- ref: https://github.com/dominikh/go-tools?tab=readme-ov-file
					},
				},
			}
			-- Use lspconfig to setup gopls with the defined options
			require('lspconfig').gopls.setup(gopls_opts)
		end,
	}
})


lsp_zero.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
	vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
	vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
	vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
	vim.keymap.set('n', '[d',
		function()
			vim.diagnostic.goto_next({ popup_opts = { focusable = false } }); vim.cmd("normal! zz")
		end, opts)
	vim.keymap.set('n', ']d',
		function()
			vim.diagnostic.goto_prev({ popup_opts = { focusable = false } }); vim.cmd("normal! zz")
		end, opts)
	vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
	vim.keymap.set('n', references_keymap, function() vim.lsp.buf.references() end, opts)
	vim.keymap.set('n', rename_keymap, function() vim.lsp.buf.rename() end, opts)
	vim.keymap.set('i', '<C-k>', function() vim.lsp.buf.signature_help() end, opts)
	vim.keymap.set('n', formatting_keymap, function() vim.lsp.buf.format() end, opts)
end)

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
	sources = {
		{ name = 'path' },
		{ name = 'nvim_lsp' },
		{ name = 'nvim_lua' },
		{ name = 'luasnip', keyword_length = 2 },
		{ name = 'buffer',  keyword_length = 3 },
	},
	formatting = lsp_zero.cmp_format({ details = false }),
	mapping = cmp.mapping.preset.insert({
		['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
		['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
		['<Tab>'] = cmp.mapping.confirm({ select = true }),
		['<C-Space>'] = cmp.mapping.complete(),
	}),
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
})


-- Configure Pyright for Python
-- lspconfig.pyright.setup({
--     on_attach = on_attach
-- })

-- Configure lua_ls for Lua
-- lspconfig.lua_ls.setup({
--     settings = {
--         Lua = {
--             runtime = {
--                 version = 'LuaJIT',  -- If you're working with Neovim, LuaJIT is the default
--             },
--             diagnostics = {
--                 globals = {'vim'},  -- Recognize 'vim' as a global variable, crucial for Neovim config
--             },
--             workspace = {
--                 library = vim.api.nvim_get_runtime_file("", true),  -- Make the server aware of Neovim runtime files
--             },
--             telemetry = {
--                 enable = false,  -- Disable telemetry for privacy
--             },
--         },
--     },
--     on_attach = on_attach
-- })
--
--

function PrintLSPConfig()
	local clients = vim.lsp.get_active_clients()
	if #clients == 0 then
		print("ARRGGGH!! No active LSP clients.")
		return
	end
	for _, client in ipairs(clients) do
		print("LSP client:", client.name)
		print(vim.inspect(client.config.settings))
	end
end

vim.cmd([[ command! PrintLSPConfig lua PrintLSPConfig() ]])
