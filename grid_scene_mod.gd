extends Control

# Game state
var semana = 1
var anio = 1
var caja = 100.0

# Warehouse state
var cap_almacen_total = 200
var stock_almacen = {"miel": 50, "papel": 50}
var stock_tienda = {"miel": 20, "papel": 20}
var cap_tienda = {"miel": 100, "papel": 100}

# Costs
const COST_COMPRA = {"miel": 2.0, "papel": 0.5}
const COST_TRANSPORTE = {"miel": 0.2, "papel": 0.1}
const COST_HOLDING = {"miel": 0.01, "papel": 0.005}
const COST_PUBLICIDAD_BLOQUE = 0.5
const COST_IMPRESION_PAPEL = 0.2
const COST_EXPANDIR_ALMACEN = 1.0
const COST_EXPANDIR_TIENDA = {"miel": 0.8, "papel": 0.6}

# Demand config
const MEDIA_MIEL = {1: 50.0, 2: 150.0, 3: 350.0, 4: 350.0}
const SIGMA_MIEL = {1: 15.0, 2: 20.0, 3: 25.0, 4: 25.0}
const MEDIA_PAPEL = {1: 80.0, 2: 160.0, 3: 300.0, 4: 300.0}
const SIGMA_PAPEL = {1: 20.0, 2: 25.0, 3: 30.0, 4: 30.0}

const MULT_ESTACION_MIEL = [1.0, 1.10, 1.20, 0.90]
const MULT_ESTACION_PAPEL = [1.0, 1.05, 1.10, 0.95]
const ESTACIONES = ["Primavera", "Verano", "Otoño", "Invierno"]

const ALPHA_PRECIO = {"miel": 0.02, "papel": 0.01}
const TENDENCIA_POR_SEMANA = 200.0 / 60.0

# Shop state
var tienda_actual = ""
var nivel_calidad = {"miel": 1, "papel": 1}
var precio_actual = {"miel": 10.0, "papel": 2.0}
var sem_tendencia = {"miel": 0, "papel": 0}

# Weekly decisions
var pedidos_guardados = {"miel": 0, "papel": 0}
var envios_guardados = {"miel": 0, "papel": 0}
var precios_guardados = {"miel": null, "papel": null}
var expansion_alm_guardada = 0
var expansion_tienda_guardada = {"miel": 0, "papel": 0}
var publi_guardada = 0

# Lock state
var almacen_bloqueado = false
var tiendas_bloqueadas = {"miel": false, "papel": false}

# Events
var eventos_diferidos = []
var historial = []

# Dynamic widgets
var row_widgets = {}

# Node references
onready var two_panel_layout = $TwoPanelLayout
onready var window = $TwoPanelLayout/HBox/GenericWindow
onready var label_titulo = $TwoPanelLayout/HBox/GenericWindow/Root/WindowTitle
onready var caja_label = $TwoPanelLayout/HBox/GenericWindow/Root/CajaLabel
onready var columnas = $TwoPanelLayout/HBox/GenericWindow/Root/Columns
onready var bottom_controls = $TwoPanelLayout/HBox/GenericWindow/Root/Bottom

onready var save_toggle = $TwoPanelLayout/HBox/GenericWindow/Root/SaveToggle
onready var btn_guardar = $TwoPanelLayout/HBox/GenericWindow/Root/SaveToggle/BtnGuardar
onready var btn_modificar = $TwoPanelLayout/HBox/GenericWindow/Root/SaveToggle/BtnModificar
onready var shop_save_toggle = $TwoPanelLayout/HBox/GenericWindow/Root/ShopSaveToggle

onready var shop_controls = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls
onready var rows_container = $TwoPanelLayout/HBox/GenericWindow/Root/Columns/Left/LeftPad/LeftVBox/Rows
onready var storage_grid = $TwoPanelLayout/HBox/GenericWindow/Root/Columns/Right/RightPad/StorageScroll/StorageGrid

onready var input_precio = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/PrecioHBox/InputPrecio
onready var input_envio = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixEnvio/InputEnvio
onready var lbl_coste_envio = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixEnvio/CosteEnvio
onready var input_publi = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixPubli/InputPubli
onready var lbl_coste_publi = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixPubli/CostePubli
onready var lbl_nivel = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MejoraHBox/InfoNivel
onready var lbl_tienda_stock = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/InfoTienda
onready var input_expand_tienda = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixExpandTienda/InputExpandTienda
onready var lbl_coste_expand_tienda = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixExpandTienda/CosteExpandTienda
onready var store_grid = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/StoreVisualVBox/StoreGridScroll/StoreGrid
onready var store_percent_label = $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/StoreVisualVBox/StorePercentLabel

onready var expandir_input = $TwoPanelLayout/HBox/GenericWindow/Root/Bottom/MatrixExpandAlmacen/ExpandirInput
onready var lbl_coste_expand_alm = $TwoPanelLayout/HBox/GenericWindow/Root/Bottom/MatrixExpandAlmacen/CosteExpandAlm
onready var lbl_capacidad = $TwoPanelLayout/HBox/GenericWindow/Root/Bottom/CapacidadLabel
onready var almacen_percent_label = $TwoPanelLayout/HBox/GenericWindow/Root/Bottom/AlmacenPercentLabel

onready var status_caja = $Layout/MainContent/StatusPanel/VBox/CajaValue
onready var status_semana = $Layout/MainContent/StatusPanel/VBox/SemanaValue
onready var status_reporte = $Layout/MainContent/StatusPanel/VBox/GastosReport

onready var dev_window = $VentanaDesarrollo
onready var dev_text = $VentanaDesarrollo/Panel/VBox/InfoText


func _ready():
    randomize()
    two_panel_layout.hide()
    dev_window.hide()
    shop_save_toggle.hide()
    _conectar_senales()
    _crear_filas_almacen()
    _actualizar_ui()


func _conectar_senales():
    _connect_if_needed(btn_guardar, "pressed", "_on_BtnGuardar_pressed")
    _connect_if_needed(btn_modificar, "pressed", "_on_BtnModificar_pressed")
    _connect_if_needed(input_publi, "value_changed", "_on_publi_value_changed")


func _connect_if_needed(node, signal_name, method_name):
    if node == null:
        return
    if not node.is_connected(signal_name, self, method_name):
        node.connect(signal_name, self, method_name)


func _crear_filas_almacen():
    for child in rows_container.get_children():
        child.queue_free()

    for prod in ["miel", "papel"]:
        var row = HBoxContainer.new()

        var label = Label.new()
        label.text = "Miel" if prod == "miel" else "Periódicos"
        label.rect_min_size = Vector2(120, 0)

        var actual = Label.new()
        actual.rect_min_size = Vector2(90, 0)
        actual.align = Label.ALIGN_CENTER

        var pedido = SpinBox.new()
        pedido.max_value = 10000
        pedido.value = pedidos_guardados[prod]
        pedido.size_flags_horizontal = SIZE_EXPAND_FILL

        row.add_child(label)
        row.add_child(actual)
        row.add_child(pedido)
        rows_container.add_child(row)

        row_widgets[prod] = {"actual": actual, "pedido": pedido}


func _abrir_ventana(titulo, es_almacen):
    two_panel_layout.show()
    window.show()

    label_titulo.text = titulo
    caja_label.visible = es_almacen
    columnas.visible = es_almacen
    bottom_controls.visible = es_almacen
    shop_controls.visible = not es_almacen

    save_toggle.visible = true
    shop_save_toggle.visible = false

    if not es_almacen:
        _configurar_ventana_tienda()

    _actualizar_ui()


func _configurar_ventana_tienda():
    if tienda_actual == "":
        return

    var p = tienda_actual

    input_precio.value = precio_actual[p]
    input_envio.value = envios_guardados[p]
    input_expand_tienda.value = expansion_tienda_guardada[p]

    if p == "papel":
        input_publi.value = publi_guardada
    else:
        input_publi.value = 0

    $TwoPanelLayout/HBox/GenericWindow/Root/ShopControls/MatrixPubli.visible = p == "papel" and nivel_calidad["papel"] >= 2

    _actualizar_labels_tienda()
    _actualizar_costes_visuales()
    _dibujar_tienda_visual()


func _actualizar_ui():
    status_caja.text = "Caja: %.2f €" % caja
    status_semana.text = "Semana: %d | Año: %d" % [semana, anio]
    caja_label.text = "Caja disponible: %.2f € | Semana: %d" % [caja, semana]

    var ocupado = stock_almacen["miel"] + stock_almacen["papel"]
    var libre = cap_almacen_total - ocupado
    lbl_capacidad.text = "Total: %d | Ocupado: %d | Libre: %d" % [cap_almacen_total, ocupado, libre]

    var pct_alm = 0.0
    if cap_almacen_total > 0:
        pct_alm = float(ocupado) / float(cap_almacen_total) * 100.0
    almacen_percent_label.text = "Ocupación: %.1f%%" % pct_alm

    if row_widgets.has("miel"):
        row_widgets["miel"]["actual"].text = str(stock_almacen["miel"])
        row_widgets["miel"]["pedido"].editable = not almacen_bloqueado

    if row_widgets.has("papel"):
        row_widgets["papel"]["actual"].text = str(stock_almacen["papel"])
        row_widgets["papel"]["pedido"].editable = not almacen_bloqueado

    expandir_input.editable = tienda_actual == "" and not almacen_bloqueado

    if tienda_actual != "":
        _actualizar_labels_tienda()
        _actualizar_inputs_tienda()
        _dibujar_tienda_visual()

    _actualizar_botones_guardado()
    _dibujar_almacen_visual()


func _actualizar_labels_tienda():
    if tienda_actual == "":
        return

    var p = tienda_actual
    var coste_mejora = 50.0 * nivel_calidad[p]

    if nivel_calidad[p] >= 4:
        lbl_nivel.text = "Nivel de Calidad: %d (MAX)" % nivel_calidad[p]
    else:
        lbl_nivel.text = "Nivel de Calidad: %d | Mejora: %.2f €" % [nivel_calidad[p], coste_mejora]

    lbl_tienda_stock.text = "Stock en tienda: %d / %d" % [stock_tienda[p], cap_tienda[p]]

    var pct_tienda = 0.0
    if cap_tienda[p] > 0:
        pct_tienda = float(stock_tienda[p]) / float(cap_tienda[p]) * 100.0
    store_percent_label.text = "Ocupación Tienda: %.1f%%" % pct_tienda


func _actualizar_inputs_tienda():
    if tienda_actual == "":
        return

    var p = tienda_actual
    var bloqueada = tiendas_bloqueadas[p]

    input_envio.editable = not bloqueada
    input_expand_tienda.editable = not bloqueada

    if p == "miel":
        input_precio.editable = nivel_calidad[p] >= 4 and not bloqueada
        input_publi.editable = false
    else:
        input_precio.editable = nivel_calidad[p] >= 4 and not bloqueada
        input_publi.editable = nivel_calidad[p] >= 2 and not bloqueada


func _actualizar_costes_visuales():
    _on_envio_value_changed(input_envio.value)
    _on_expand_tienda_value_changed(input_expand_tienda.value)
    _on_publi_value_changed(input_publi.value)
    _on_expand_alm_value_changed(expandir_input.value)


func _actualizar_botones_guardado():
    var bloqueado = almacen_bloqueado if tienda_actual == "" else tiendas_bloqueadas[tienda_actual]

    btn_guardar.disabled = bloqueado
    btn_modificar.disabled = not bloqueado

    btn_guardar.size_flags_horizontal = SIZE_EXPAND_FILL
    btn_modificar.size_flags_horizontal = SIZE_EXPAND_FILL

    btn_guardar.size_flags_stretch_ratio = 0.2 if bloqueado else 0.8
    btn_modificar.size_flags_stretch_ratio = 0.8 if bloqueado else 0.2

    btn_guardar.text = "Guardado" if bloqueado else "Guardar cambios"
    btn_modificar.text = "Modificar"


func _dibujar_almacen_visual():
    for child in storage_grid.get_children():
        child.queue_free()

    for i in range(cap_almacen_total):
        var rect = ColorRect.new()
        rect.rect_min_size = Vector2(10, 10)

        if i < stock_almacen["miel"]:
            rect.color = Color("f5b041")
        elif i < stock_almacen["miel"] + stock_almacen["papel"]:
            rect.color = Color("5dade2")
        else:
            rect.color = Color("d5dbdb")

        storage_grid.add_child(rect)


func _dibujar_tienda_visual():
    for child in store_grid.get_children():
        child.queue_free()

    if tienda_actual == "":
        return

    var stock = stock_tienda[tienda_actual]
    var cap = cap_tienda[tienda_actual]
    var color = Color("f5b041") if tienda_actual == "miel" else Color("5dade2")

    for i in range(cap):
        var rect = ColorRect.new()
        rect.rect_min_size = Vector2(10, 10)
        rect.color = color if i < stock else Color("d5dbdb")
        store_grid.add_child(rect)


func _capacidad_ocupada():
    return stock_almacen["miel"] + stock_almacen["papel"]


func _capacidad_libre():
    return max(0, cap_almacen_total - _capacidad_ocupada())


func _estacion_idx():
    var semana_en_anio = ((semana - 1) % 60) + 1
    return int(floor(float(semana_en_anio - 1) / 15.0))


func _gauss(media, sigma):
    var u1 = randf()
    var u2 = randf()
    if u1 <= 0.0001:
        u1 = 0.0001
    var z = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
    return media + sigma * z


func _evento_publicidad_activo(prod):
    var mult = 1.0
    for ev in eventos_diferidos:
        if ev["semana"] == semana and ev["producto"] == prod:
            mult *= ev["multiplicador"]
    return mult


func _calcular_demanda(prod):
    var nivel = nivel_calidad[prod]
    var media = MEDIA_MIEL[nivel] if prod == "miel" else MEDIA_PAPEL[nivel]
    var sigma = SIGMA_MIEL[nivel] if prod == "miel" else SIGMA_PAPEL[nivel]

    var base = max(0.0, _gauss(media, sigma))
    var idx = _estacion_idx()
    var mult_est = MULT_ESTACION_MIEL[idx] if prod == "miel" else MULT_ESTACION_PAPEL[idx]
    var demanda = base * mult_est

    if prod == "miel" and semana >= 10 and semana <= 14:
        demanda *= 1.30

    demanda *= _evento_publicidad_activo(prod)

    if nivel >= 4:
        demanda += TENDENCIA_POR_SEMANA * sem_tendencia[prod]
        sem_tendencia[prod] += 1

    demanda *= exp(-ALPHA_PRECIO[prod] * precio_actual[prod])
    return max(0, int(round(demanda)))


func _generar_publicidad_diferida():
    if nivel_calidad["papel"] < 2:
        return

    var b = max(0, int(publi_guardada))
    if b <= 0:
        return

    var logistic_raw = 1.0 / (1.0 + exp(-0.03 * b))
    var logistic_scaled = (logistic_raw - 0.5) / 0.5
    logistic_scaled = clamp(logistic_scaled, 0.0, 1.0)

    var multiplicador = 1.0 + logistic_scaled

    eventos_diferidos.append({
        "nombre": "Publicidad diferida",
        "semana": semana + 1,
        "duracion": 1,
        "multiplicador": multiplicador,
        "producto": "miel"
    })


func _limpiar_eventos_pasados():
    var nuevos = []
    for ev in eventos_diferidos:
        if ev["semana"] >= semana:
            nuevos.append(ev)
    eventos_diferidos = nuevos


func _on_Almacen_pressed():
    tienda_actual = ""
    _abrir_ventana("Gestión de Almacén", true)


func _on_Miel_pressed():
    tienda_actual = "miel"
    _abrir_ventana("Gestión de Miel", false)


func _on_Periodicos_pressed():
    tienda_actual = "papel"
    _abrir_ventana("Gestión de Periódicos", false)


func _on_Confirmar_pressed():
    two_panel_layout.hide()


func _on_BtnGuardar_pressed():
    if tienda_actual == "":
        var pedido_miel = int(row_widgets["miel"]["pedido"].value)
        var pedido_papel = int(row_widgets["papel"]["pedido"].value)
        var pedido_total = pedido_miel + pedido_papel

        if pedido_total > _capacidad_libre():
            status_reporte.text = "Pedido inválido: no cabe en el almacén."
            return

        pedidos_guardados["miel"] = pedido_miel
        pedidos_guardados["papel"] = pedido_papel
        expansion_alm_guardada = int(expandir_input.value)
        almacen_bloqueado = true
    else:
        var p = tienda_actual

        envios_guardados[p] = int(input_envio.value)
        expansion_tienda_guardada[p] = int(input_expand_tienda.value)

        if p == "miel":
            if nivel_calidad[p] >= 4:
                precios_guardados[p] = float(input_precio.value)
            else:
                precios_guardados[p] = null
        else:
            if nivel_calidad[p] >= 4:
                precios_guardados[p] = float(input_precio.value)
            else:
                precios_guardados[p] = null

            if nivel_calidad[p] >= 2:
                publi_guardada = int(input_publi.value)
            else:
                publi_guardada = 0

        tiendas_bloqueadas[p] = true

    _actualizar_ui()


func _on_BtnModificar_pressed():
    if tienda_actual == "":
        almacen_bloqueado = false
    else:
        tiendas_bloqueadas[tienda_actual] = false

    _actualizar_ui()


func _on_AvanzarSemana_pressed():
    var reporte = ""
    var semana_reportada = semana

    if precios_guardados["miel"] != null and nivel_calidad["miel"] >= 4:
        precio_actual["miel"] = precios_guardados["miel"]

    if precios_guardados["papel"] != null and nivel_calidad["papel"] >= 4:
        precio_actual["papel"] = precios_guardados["papel"]

    var ped_miel = max(0, int(pedidos_guardados["miel"]))
    var ped_papel = max(0, int(pedidos_guardados["papel"]))

    var pedido_total = ped_miel + ped_papel
    if pedido_total > _capacidad_libre():
        reporte += "Pedidos cancelados: no caben en almacén.\n"
        ped_miel = 0
        ped_papel = 0

    var coste_compra = ped_miel * COST_COMPRA["miel"] + ped_papel * COST_COMPRA["papel"]
    if coste_compra > caja:
        reporte += "Pedidos cancelados: caja insuficiente.\n"
        ped_miel = 0
        ped_papel = 0
        coste_compra = 0.0

    caja -= coste_compra
    stock_almacen["miel"] += ped_miel
    stock_almacen["papel"] += ped_papel

    var coste_exp_alm = expansion_alm_guardada * COST_EXPANDIR_ALMACEN
    if coste_exp_alm <= caja:
        caja -= coste_exp_alm
        cap_almacen_total += expansion_alm_guardada
    else:
        reporte += "Expansión de almacén cancelada: caja insuficiente.\n"

    var coste_transporte = 0.0
    var env_real = {"miel": 0, "papel": 0}
    var coste_exp_tiendas = {"miel": 0.0, "papel": 0.0}

    for prod in ["miel", "papel"]:
        var extra = max(0, int(expansion_tienda_guardada[prod]))
        var coste_extra = extra * COST_EXPANDIR_TIENDA[prod]

        if coste_extra <= caja:
            caja -= coste_extra
            cap_tienda[prod] += extra
            coste_exp_tiendas[prod] = coste_extra
        else:
            reporte += "Expansión tienda %s cancelada.\n" % prod

        var solicitado = max(0, int(envios_guardados[prod]))
        var espacio = max(0, cap_tienda[prod] - stock_tienda[prod])
        var real = min(solicitado, min(stock_almacen[prod], espacio))
        var coste_envio = real * COST_TRANSPORTE[prod]

        if coste_envio <= caja:
            caja -= coste_envio
            stock_almacen[prod] -= real
            stock_tienda[prod] += real
            coste_transporte += coste_envio
            env_real[prod] = real
        else:
            reporte += "Envío %s cancelado: caja insuficiente.\n" % prod

    var demanda_miel = _calcular_demanda("miel")
    var demanda_papel = _calcular_demanda("papel")

    var ventas_miel = min(demanda_miel, stock_tienda["miel"])
    var ventas_papel = min(demanda_papel, stock_tienda["papel"])

    stock_tienda["miel"] -= ventas_miel
    stock_tienda["papel"] -= ventas_papel

    var ingresos_miel = ventas_miel * precio_actual["miel"]
    var ingresos_papel = ventas_papel * precio_actual["papel"]
    var ingresos_totales = ingresos_miel + ingresos_papel

    caja += ingresos_totales

    var coste_hold_miel = stock_tienda["miel"] * COST_HOLDING["miel"]
    var coste_hold_papel = stock_tienda["papel"] * COST_HOLDING["papel"]
    var coste_impresion = ventas_papel * COST_IMPRESION_PAPEL
    var coste_publicidad = publi_guardada * COST_PUBLICIDAD_BLOQUE if nivel_calidad["papel"] >= 2 else 0.0

    var costes_extra = coste_hold_miel + coste_hold_papel + coste_impresion + coste_publicidad

    caja -= costes_extra

    _generar_publicidad_diferida()

    stock_tienda["papel"] = 0

    var profit_miel = ingresos_miel - (ped_miel * COST_COMPRA["miel"]) - (env_real["miel"] * COST_TRANSPORTE["miel"]) - coste_hold_miel
    var profit_papel = ingresos_papel - (ped_papel * COST_COMPRA["papel"]) - (env_real["papel"] * COST_TRANSPORTE["papel"]) - coste_hold_papel - coste_impresion - coste_publicidad
    var profit_total = profit_miel + profit_papel

    historial.append({
        "semana": semana_reportada,
        "anio": anio,
        "miel": profit_miel,
        "papel": profit_papel,
        "total": profit_total,
        "caja": caja
    })

    reporte += "SEMANA %d | AÑO %d\n" % [semana_reportada, anio]
    reporte += "Estación: %s\n\n" % ESTACIONES[_estacion_idx()]
    reporte += "COMPRAS:\n"
    reporte += "- Miel: %d uds | %.2f €\n" % [ped_miel, ped_miel * COST_COMPRA["miel"]]
    reporte += "- Periódicos: %d uds | %.2f €\n\n" % [ped_papel, ped_papel * COST_COMPRA["papel"]]
    reporte += "ENVÍOS:\n"
    reporte += "- Miel: %d uds\n" % env_real["miel"]
    reporte += "- Periódicos: %d uds\n\n" % env_real["papel"]
    reporte += "VENTAS:\n"
    reporte += "- Miel: %d / demanda %d | %.2f €\n" % [ventas_miel, demanda_miel, ingresos_miel]
    reporte += "- Periódicos: %d / demanda %d | %.2f €\n\n" % [ventas_papel, demanda_papel, ingresos_papel]
    reporte += "COSTES:\n"
    reporte += "- Compra: %.2f €\n" % coste_compra
    reporte += "- Transporte: %.2f €\n" % coste_transporte
    reporte += "- Holding: %.2f €\n" % (coste_hold_miel + coste_hold_papel)
    reporte += "- Impresión periódicos: %.2f €\n" % coste_impresion
    reporte += "- Publicidad: %.2f €\n\n" % coste_publicidad
    reporte += "BENEFICIO:\n"
    reporte += "- Miel: %.2f €\n" % profit_miel
    reporte += "- Periódicos: %.2f €\n" % profit_papel
    reporte += "- Total: %.2f €\n" % profit_total
    reporte += "\nCaja final: %.2f €" % caja

    semana += 1
    if semana > 60:
        semana = 1
        anio += 1

    _limpiar_eventos_pasados()
    _reset_decisiones_semana()
    status_reporte.text = reporte
    _actualizar_ui()


func _reset_decisiones_semana():
    pedidos_guardados = {"miel": 0, "papel": 0}
    envios_guardados = {"miel": 0, "papel": 0}
    precios_guardados = {"miel": null, "papel": null}
    expansion_alm_guardada = 0
    expansion_tienda_guardada = {"miel": 0, "papel": 0}
    publi_guardada = 0

    almacen_bloqueado = false
    tiendas_bloqueadas = {"miel": false, "papel": false}

    if row_widgets.has("miel"):
        row_widgets["miel"]["pedido"].value = 0
    if row_widgets.has("papel"):
        row_widgets["papel"]["pedido"].value = 0

    input_envio.value = 0
    input_expand_tienda.value = 0
    expandir_input.value = 0
    input_publi.value = 0


func _on_BtnMejorar_pressed():
    if tienda_actual == "":
        return

    var p = tienda_actual
    var coste = 50.0 * nivel_calidad[p]

    if nivel_calidad[p] >= 4:
        status_reporte.text = "La tienda ya está al nivel máximo."
        return

    if caja < coste:
        status_reporte.text = "No hay caja suficiente para mejorar."
        return

    caja -= coste
    nivel_calidad[p] += 1

    _configurar_ventana_tienda()
    _actualizar_ui()


func _on_Desarrollo_pressed():
    var txt = ""
    txt += "ESTADO GLOBAL\n"
    txt += "Semana: %d | Año: %d\n" % [semana, anio]
    txt += "Caja: %.2f €\n" % caja
    txt += "Estación: %s\n\n" % ESTACIONES[_estacion_idx()]
    txt += "ALMACÉN\n"
    txt += "Capacidad total: %d\n" % cap_almacen_total
    txt += "Stock almacén: %s\n" % str(stock_almacen)
    txt += "Stock tienda: %s\n" % str(stock_tienda)
    txt += "Capacidad tienda: %s\n\n" % str(cap_tienda)
    txt += "TIENDAS\n"
    txt += "Niveles: %s\n" % str(nivel_calidad)
    txt += "Precios: %s\n" % str(precio_actual)
    txt += "Eventos diferidos: %s\n\n" % str(eventos_diferidos)
    txt += "DECISIONES GUARDADAS\n"
    txt += "Pedidos: %s\n" % str(pedidos_guardados)
    txt += "Envíos: %s\n" % str(envios_guardados)
    txt += "Expansión almacén: %d\n" % expansion_alm_guardada
    txt += "Expansión tienda: %s\n" % str(expansion_tienda_guardada)
    txt += "Publicidad: %d\n" % publi_guardada

    dev_text.bbcode_text = txt
    dev_window.show()


func _on_ConfirmarDesarrollo_pressed():
    dev_window.hide()


func _on_envio_value_changed(value):
    if tienda_actual == "":
        return

    var unit = COST_TRANSPORTE[tienda_actual]
    lbl_coste_envio.text = "%.1f€ -> %.1f€" % [unit, value * unit]


func _on_publi_value_changed(value):
    lbl_coste_publi.text = "%.1f€ -> %.1f€" % [COST_PUBLICIDAD_BLOQUE, value * COST_PUBLICIDAD_BLOQUE]


func _on_expand_alm_value_changed(value):
    lbl_coste_expand_alm.text = "%.1f€" % (value * COST_EXPANDIR_ALMACEN)


func _on_expand_tienda_value_changed(value):
    if tienda_actual == "":
        return

    var unit = COST_EXPANDIR_TIENDA[tienda_actual]
    lbl_coste_expand_tienda.text = "%.1f€ -> %.1f€" % [unit, value * unit]