-- Monitores Dell S2421HN: DVI à esquerda, HDMI à direita
hl.monitor({
    output   = "DVI-D-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-1",
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

hl.on("hyprland.start", function()
end)
