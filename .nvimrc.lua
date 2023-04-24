local servers = { "rust_analyzer" }
            local caps = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities());
            for _, lsp in ipairs(servers) do
              require("lspconfig")[lsp].setup {capabilities = caps}
            end

            vim.cmd("LspStart");
