-- Monitores Dell S2421HN: HDMI à esquerda, DVI à direita
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "DVI-D-1",
    mode     = "preferred",
    position = "1920x0",
    scale    = 1,
})

-- Teclado ABNT2 (português brasileiro)
hl.config({
    input = {
        kb_layout  = "br",
        kb_variant = "abnt2",
    },
})

-- Teclado sem fio (layout físico americano): inglês internacional.
-- Acentos por tecla morta: ' + c = ç, ~ + a = ã; ' + espaço sai o próprio '.
-- O receptor expõe as teclas por mais de um dispositivo; todos precisam do layout.
for _, name in ipairs({
    "compx-2.4g-wireless-receiver",
    "compx-2.4g-wireless-receiver-keyboard",
}) do
    hl.device({
        name       = name,
        kb_layout  = "us",
        kb_variant = "intl",
    })
end

-- SUPER + Ctrl direito abre o menu de contexto no elemento focado (Shift+F10).
-- Espera soltar as teclas: com SUPER ainda pressionado, o app receberia SUPER + Shift + F10.
hl.bind("SUPER + Control_R", hl.dsp.exec_cmd("sleep 0.25 && ydotool key 42:1 68:1 68:0 42:0"), { release = true })

-- Serviços desta máquina que não vão para o repo: ~/.config/caelestia/hypr-local.lua,
-- que devolve { on_start = function() ... end }.
local has_local, machine = pcall(require, "hypr-local")

hl.on("hyprland.start", function()
    if has_local and type(machine) == "table" and machine.on_start then
        machine.on_start()
    end
    -- Terminal com tmux; ao subir, o tmux restaura as sessões salvas.
    -- Sem o fish no meio, ninguém manda as cores do tema ao foot e o fundo fica o escuro padrão.
    hl.exec_cmd("foot -e sh -c 'cat ~/.local/state/caelestia/sequences.txt 2>/dev/null; tmux attach-session 2>/dev/null || exec tmux'")
end)

-- Plugin dynamic-cursors (build manual em ~/.local/src/hypr-dynamic-cursors)
hl.plugin.load(os.getenv("HOME") .. "/.local/lib/hyprland-plugins/dynamic-cursors.so")

if hl.plugin.dynamic_cursors then
    hl.config({ plugin = { dynamic_cursors = {
        enabled = true,
        mode    = "tilt",
        tilt = {
            limit      = 5000,
            activation = "negative_quadratic",
            full       = 60,
        },
        shake = {
            enabled   = true,
            threshold = 6.0,
            base      = 4.0,
            speed     = 4.0,
            timeout   = 2000,
        },
    }}})
end

-- Layout gerado pelo nwg-displays
pcall(require, "monitors")
