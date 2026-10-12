extends Node3D

const SAVE_PATH := "user://mi_mundo_save.json"

var player_name := ""
var player_gender := "niña"
var coins := 0
var stars := 0
var completed := 0
var active_screen := "welcome"
var activity := "sumas"
var question := {}
var question_history: Array[String] = []
var spelling_index := 0
var room_unlocked := {"Dormitorio": true, "Baño": false, "Living": false, "Cocina": false, "Patio": false}
var inventory: Array[String] = []
var player: CharacterBody3D
var cat: Node3D
var ui: CanvasLayer
var main_panel: PanelContainer
var status_label: Label
var answer_edit: LineEdit
var question_label: Label
var feedback_label: Label
var coin_label: Label
var room_label: Label
var move_vector := Vector2.ZERO
var cat_phase := 0.0

var spelling_words := [
    {"wrong":"bentana", "right":"ventana", "hint":"«Ventana» se escribe con V."},
    {"wrong":"jirafa", "right":"jirafa", "hint":"¡Correcto! Jirafa se escribe con J."},
    {"wrong":"uevo", "right":"huevo", "hint":"«Huevo» lleva H al principio."},
    {"wrong":"cansión", "right":"canción", "hint":"«Canción» lleva C y tilde en la O."},
    {"wrong":"yuvia", "right":"lluvia", "hint":"«Lluvia» se escribe con LL."},
    {"wrong":"seresa", "right":"cereza", "hint":"«Cereza» se escribe con C y Z."},
    {"wrong":"berde", "right":"verde", "hint":"«Verde» se escribe con V."},
    {"wrong":"guitarra", "right":"guitarra", "hint":"¡Muy bien! Guitarra se escribe con G y doble R."}
]

func _ready() -> void:
    _build_world()
    _build_ui()
    _load_progress()
    _show_welcome()

func _build_world() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.22, 0.42, 0.78)
    sky_mat.sky_horizon_color = Color(0.78, 0.85, 0.98)
    sky_mat.ground_bottom_color = Color(0.24, 0.27, 0.34)
    sky_mat.ground_horizon_color = Color(0.68, 0.72, 0.80)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.78, 0.82, 1.0)
    env.ambient_light_energy = 0.7
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.25
    add_child(sun)

    _add_box("Floor", Vector3(0, -0.15, 0), Vector3(12, 0.3, 12), Color(0.82, 0.68, 0.54))
    _add_box("BackWall", Vector3(0, 2.0, -6), Vector3(12, 4, 0.25), Color(0.91, 0.75, 0.88))
    _add_box("LeftWall", Vector3(-6, 2.0, 0), Vector3(0.25, 4, 12), Color(0.72, 0.83, 0.98))
    _add_box("Rug", Vector3(0, 0.03, 0.4), Vector3(4.3, 0.08, 3.0), Color(0.68, 0.48, 0.88))
    _add_box("BedBase", Vector3(-2.8, 0.38, -2.7), Vector3(2.5, 0.6, 2.0), Color(0.92, 0.45, 0.68))
    _add_box("Mattress", Vector3(-2.8, 0.75, -2.7), Vector3(2.35, 0.18, 1.85), Color(1.0, 0.91, 0.96))
    _add_box("Pillow", Vector3(-2.8, 0.9, -3.35), Vector3(0.95, 0.18, 0.6), Color(0.78, 0.84, 1.0))
    _add_box("Desk", Vector3(3.4, 0.85, -3.6), Vector3(2.0, 0.14, 1.0), Color(0.60, 0.38, 0.25))
    _add_box("DeskLeg1", Vector3(2.65, 0.4, -3.25), Vector3(0.12, 0.8, 0.12), Color(0.45, 0.28, 0.18))
    _add_box("DeskLeg2", Vector3(4.15, 0.4, -3.25), Vector3(0.12, 0.8, 0.12), Color(0.45, 0.28, 0.18))
    _add_box("Window", Vector3(0.6, 2.5, -5.82), Vector3(2.1, 1.5, 0.08), Color(0.48, 0.80, 0.98))
    _add_box("WindowFrameTop", Vector3(0.6, 3.28, -5.75), Vector3(2.3, 0.1, 0.12), Color(1, 1, 1))
    _add_box("WindowFrameBottom", Vector3(0.6, 1.72, -5.75), Vector3(2.3, 0.1, 0.12), Color(1, 1, 1))
    _add_box("WindowFrameMid", Vector3(0.6, 2.5, -5.74), Vector3(0.1, 1.6, 0.12), Color(1, 1, 1))
    _add_box("Wardrobe", Vector3(4.6, 1.25, -1.5), Vector3(1.5, 2.5, 0.8), Color(0.78, 0.54, 0.73))
    _create_player()
    _create_cat()

    var camera := Camera3D.new()
    camera.position = Vector3(0, 8.7, 12.8)
    camera.rotation_degrees = Vector3(-28, 0, 0)
    camera.current = true
    add_child(camera)

func _add_box(n: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = n
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    mesh.material_override = mat
    add_child(mesh)
    return mesh

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.05, 1.8)
    add_child(player)
    _add_player_part(player, "Body", Vector3(0, 1.0, 0), Vector3(0.58, 0.82, 0.34), Color(0.96, 0.43, 0.69), "box")
    _add_player_part(player, "Head", Vector3(0, 1.72, 0), Vector3(0.72, 0.72, 0.72), Color(1.0, 0.79, 0.64), "sphere")
    _add_player_part(player, "Hair", Vector3(0, 2.0, -0.02), Vector3(0.74, 0.28, 0.72), Color(0.30, 0.16, 0.09), "sphere")
    _add_player_part(player, "LeftLeg", Vector3(-0.17, 0.42, 0), Vector3(0.18, 0.5, 0.2), Color(0.28, 0.44, 0.82), "box")
    _add_player_part(player, "RightLeg", Vector3(0.17, 0.42, 0), Vector3(0.18, 0.5, 0.2), Color(0.28, 0.44, 0.82), "box")
    _add_player_part(player, "LeftEye", Vector3(-0.14, 1.77, 0.31), Vector3(0.09, 0.11, 0.06), Color(0.12, 0.08, 0.07), "sphere")
    _add_player_part(player, "RightEye", Vector3(0.14, 1.77, 0.31), Vector3(0.09, 0.11, 0.06), Color(0.12, 0.08, 0.07), "sphere")

func _add_player_part(parent: Node3D, n: String, pos: Vector3, size: Vector3, color: Color, shape: String) -> void:
    var part := MeshInstance3D.new()
    part.name = n
    if shape == "sphere":
        var m := SphereMesh.new()
        m.radius = 0.5
        m.height = 1.0
        part.mesh = m
    else:
        var m := BoxMesh.new()
        m.size = Vector3.ONE
        part.mesh = m
    part.position = pos
    part.scale = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    part.material_override = mat
    parent.add_child(part)

func _create_cat() -> void:
    cat = Node3D.new()
    cat.name = "Kitten"
    cat.position = Vector3(1.7, 0.05, 1.4)
    add_child(cat)
    _add_player_part(cat, "CatBody", Vector3(0, 0.28, 0), Vector3(0.62, 0.42, 0.42), Color(0.96, 0.91, 0.78), "sphere")
    _add_player_part(cat, "CatHead", Vector3(0, 0.55, 0.25), Vector3(0.42, 0.4, 0.4), Color(0.98, 0.94, 0.84), "sphere")
    _add_player_part(cat, "EarL", Vector3(-0.14, 0.78, 0.22), Vector3(0.12, 0.22, 0.12), Color(0.98, 0.72, 0.79), "sphere")
    _add_player_part(cat, "EarR", Vector3(0.14, 0.78, 0.22), Vector3(0.12, 0.22, 0.12), Color(0.98, 0.72, 0.79), "sphere")
    _add_player_part(cat, "EyeL", Vector3(-0.09, 0.58, 0.43), Vector3(0.045, 0.055, 0.03), Color(0.12, 0.10, 0.08), "sphere")
    _add_player_part(cat, "EyeR", Vector3(0.09, 0.58, 0.43), Vector3(0.045, 0.055, 0.03), Color(0.12, 0.10, 0.08), "sphere")

func _build_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    main_panel = PanelContainer.new()
    main_panel.position = Vector2(20, 18)
    main_panel.size = Vector2(390, 675)
    ui.add_child(main_panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.98, 0.97, 1.0, 0.96)
    style.set_corner_radius_all(22)
    style.set_border_width_all(2)
    style.border_color = Color(0.79, 0.65, 0.94)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    main_panel.add_theme_stylebox_override("panel", style)

func _clear_panel() -> VBoxContainer:
    for child in main_panel.get_children():
        child.queue_free()
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 10)
    main_panel.add_child(v)
    return v

func _label(text: String, size := 22) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(0.20, 0.15, 0.35))
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(text: String, callback: Callable, color := Color(0.42, 0.75, 0.46)) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 48)
    b.add_theme_font_size_override("font_size", 19)
    var st := StyleBoxFlat.new()
    st.bg_color = color
    st.set_corner_radius_all(14)
    st.content_margin_left = 10
    st.content_margin_right = 10
    b.add_theme_stylebox_override("normal", st)
    var hover := st.duplicate()
    hover.bg_color = color.lightened(0.12)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_color_override("font_color", Color.WHITE)
    b.pressed.connect(callback)
    return b

func _show_welcome() -> void:
    active_screen = "welcome"
    var v := _clear_panel()
    v.add_child(_label("🌈 Mi Mundo de Aventuras", 28))
    v.add_child(_label("¡Crea tu personaje y comienza a aprender!", 17))
    v.add_child(_label("¿Cómo te llamas?", 20))
    var name_input := LineEdit.new()
    name_input.name = "NameInput"
    name_input.placeholder_text = "Escribe tu nombre aquí"
    name_input.custom_minimum_size.y = 48
    name_input.add_theme_font_size_override("font_size", 19)
    v.add_child(name_input)
    v.add_child(_label("Elige tu personaje:", 20))
    var gender_row := HBoxContainer.new()
    var girl := _button("👧 Niña", func(): _set_gender("niña"), Color(0.85, 0.36, 0.69))
    var boy := _button("👦 Niño", func(): _set_gender("niño"), Color(0.30, 0.57, 0.88))
    girl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    boy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    gender_row.add_child(girl)
    gender_row.add_child(boy)
    v.add_child(gender_row)
    status_label = _label("Seleccionado: niña", 16)
    v.add_child(status_label)
    v.add_child(_button("✨ Crear mi mundo", func():
        player_name = name_input.text.strip_edges()
        if player_name.is_empty():
            status_label.text = "Escribe tu nombre para continuar 😊"
            return
        _apply_gender()
        _save_progress()
        _show_home()
    ))
    v.add_child(_label("Demo inicial · Las funciones y el arte se irán ampliando.", 13))

func _set_gender(g: String) -> void:
    player_gender = g
    if is_instance_valid(status_label):
        status_label.text = "Seleccionado: " + ("niña 👧" if g == "niña" else "niño 👦")

func _apply_gender() -> void:
    var body := player.get_node_or_null("Body") as MeshInstance3D
    if body:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.96, 0.43, 0.69) if player_gender == "niña" else Color(0.25, 0.56, 0.91)
        body.material_override = mat

func _show_home() -> void:
    active_screen = "home"
    var v := _clear_panel()
    v.add_child(_label("¡Hola, %s! ⭐" % player_name, 27))
    coin_label = _label("🪙 Monedas: %d     ⭐ Estrellas: %d" % [coins, stars], 17)
    v.add_child(coin_label)
    v.add_child(_label("Tu habitación 3D", 20))
    v.add_child(_label("Muévete con WASD/flechas o con los controles de abajo. El gato pasea por la habitación.", 15))
    v.add_child(_button("🧮 Academia de matemáticas", func(): _show_math_menu(), Color(0.27, 0.62, 0.91)))
    v.add_child(_button("✏️ Laboratorio de ortografía", func(): _start_activity("ortografia"), Color(0.62, 0.42, 0.86)))
    v.add_child(_button("👕 Vestidor y recompensas", func(): _show_rewards(), Color(0.88, 0.46, 0.69)))
    v.add_child(_button("🏠 Casa y zonas", func(): _show_rooms(), Color(0.92, 0.59, 0.28)))
    v.add_child(_button("🐱 Jugar con el gato", func(): _play_cat(), Color(0.32, 0.68, 0.55)))
    v.add_child(_button("💾 Guardar progreso", func(): _save_progress(), Color(0.45, 0.52, 0.67)))

func _show_math_menu() -> void:
    active_screen = "math_menu"
    var v := _clear_panel()
    v.add_child(_label("🧮 Academia de matemáticas", 25))
    v.add_child(_label("Elige qué quieres practicar. Las preguntas cambiarán cada vez.", 16))
    v.add_child(_button("➕ Sumas", func(): _start_activity("sumas"), Color(0.29, 0.68, 0.42)))
    v.add_child(_button("➖ Restas", func(): _start_activity("restas"), Color(0.91, 0.57, 0.23)))
    v.add_child(_button("✖ Multiplicaciones", func(): _start_activity("multiplicaciones"), Color(0.54, 0.39, 0.86)))
    v.add_child(_button("⬅ Volver a mi mundo", func(): _show_home(), Color(0.42, 0.54, 0.69)))

func _start_activity(which: String) -> void:
    activity = which
    active_screen = "activity"
    _new_question()
    _show_question()

func _new_question() -> void:
    if activity == "ortografia":
        var idx := randi_range(0, spelling_words.size() - 1)
        question = spelling_words[idx].duplicate(true)
        question["kind"] = "spelling"
        question["key"] = "spelling_%d" % idx
        return

    var max_n := 10
    if completed >= 12: max_n = 20
    if completed >= 35: max_n = 50
    if completed >= 70: max_n = 100
    var format_kind := randi_range(0, 2)
    var a := 0
    var b := 0
    var result := 0
    var text := ""
    var missing := "result"
    if activity == "sumas":
        a = randi_range(0, max_n)
        b = randi_range(0, max_n)
        result = a + b
        if format_kind == 0:
            text = "□ + □ = %d" % result
            missing = "both"
        elif format_kind == 1:
            text = "%d + %d = □" % [a, b]
            missing = "result"
        else:
            text = "%d + □ = %d" % [a, result]
            missing = "second"
    elif activity == "restas":
        a = randi_range(0, max_n)
        b = randi_range(0, a)
        result = a - b
        if format_kind == 0:
            text = "□ − □ = %d" % result
            missing = "both"
        elif format_kind == 1:
            text = "%d − %d = □" % [a, b]
            missing = "result"
        else:
            text = "%d − □ = %d" % [a, result]
            missing = "second"
    else:
        var max_factor := 5 if completed < 20 else 10
        a = randi_range(0, max_factor)
        b = randi_range(0, max_factor)
        result = a * b
        if format_kind == 0:
            text = "□ × □ = %d" % result
            missing = "both"
        elif format_kind == 1:
            text = "%d × %d = □" % [a, b]
            missing = "result"
        else:
            text = "%d × □ = %d" % [a, result]
            missing = "second"

    var key := "%s|%s|%d|%d|%d" % [activity, missing, a, b, result]
    var tries := 0
    while key in question_history and tries < 30:
        a = randi_range(0, max_n)
        b = randi_range(0, max_n)
        if activity == "restas":
            if b > a:
                var tmp = a
                a = b
                b = tmp
            result = a - b
        elif activity == "multiplicaciones":
            var mf := 5 if completed < 20 else 10
            a = randi_range(0, mf)
            b = randi_range(0, mf)
            result = a * b
        else:
            result = a + b
        format_kind = randi_range(0, 2)
        if format_kind == 0:
            text = "□ + □ = %d" % result if activity == "sumas" else ("□ − □ = %d" % result if activity == "restas" else "□ × □ = %d" % result)
            missing = "both"
        elif format_kind == 1:
            text = "%d %s %d = □" % [a, ("+" if activity == "sumas" else "−" if activity == "restas" else "×"), b]
            missing = "result"
        else:
            text = "%d %s □ = %d" % [a, ("+" if activity == "sumas" else "−" if activity == "restas" else "×"), result]
            missing = "second"
        key = "%s|%s|%d|%d|%d" % [activity, missing, a, b, result]
        tries += 1
    question_history.append(key)
    if question_history.size() > 100:
        question_history.pop_front()
    question = {"kind":"math", "a":a, "b":b, "result":result, "text":text, "missing":missing, "key":key}

func _show_question() -> void:
    var v := _clear_panel()
    var title := "✏️ Laboratorio de ortografía" if activity == "ortografia" else "🧮 " + activity.capitalize()
    v.add_child(_label(title, 25))
    v.add_child(_label("Ronda %d · Responde a tu ritmo" % (completed + 1), 15))
    question_label = _label("", 30)
    question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    question_label.custom_minimum_size.y = 100
    if question.get("kind") == "spelling":
        question_label.text = "Escribe correctamente:\n" + str(question["wrong"])
    else:
        question_label.text = str(question["text"])
    v.add_child(question_label)
    answer_edit = LineEdit.new()
    answer_edit.placeholder_text = "Escribe tu respuesta aquí"
    answer_edit.custom_minimum_size.y = 48
    answer_edit.add_theme_font_size_override("font_size", 21)
    answer_edit.text_submitted.connect(func(_t): _check_answer())
    v.add_child(answer_edit)
    feedback_label = _label("¡Tú puedes! 💪", 17)
    v.add_child(feedback_label)
    v.add_child(_button("Comprobar respuesta", func(): _check_answer(), Color(0.28, 0.70, 0.43)))
    v.add_child(_button("🎲 Otra pregunta", func(): _new_question(); _show_question(), Color(0.30, 0.58, 0.88)))
    v.add_child(_button("⬅ Volver a la academia", func(): _show_math_menu() if activity != "ortografia" else _show_home(), Color(0.55, 0.51, 0.68)))

func _check_answer() -> void:
    if not is_instance_valid(answer_edit) or answer_edit.text.strip_edges().is_empty():
        feedback_label.text = "Escribe una respuesta primero 😊"
        return
    var raw := answer_edit.text.strip_edges().to_lower()
    var correct := false
    var explanation := ""
    if question.get("kind") == "spelling":
        correct = raw == str(question["right"]).to_lower()
        explanation = str(question["hint"])
    else:
        var nums := raw.split(",", false)
        var n1 := int(nums[0].strip_edges()) if nums.size() > 0 and nums[0].strip_edges().is_valid_int() else 999999
        var n2 := int(nums[1].strip_edges()) if nums.size() > 1 and nums[1].strip_edges().is_valid_int() else 999999
        match question["missing"]:
            "result":
                correct = n1 == int(question["result"])
            "second":
                correct = n1 == int(question["b"])
            "both":
                var a := int(question["a"])
                var b := int(question["b"])
                var r := int(question["result"])
                if activity == "sumas":
                    correct = nums.size() >= 2 and n1 + n2 == r
                elif activity == "restas":
                    correct = nums.size() >= 2 and n1 - n2 == r
                else:
                    correct = nums.size() >= 2 and n1 * n2 == r
        explanation = "La respuesta correcta es %d." % int(question["result"])
    if correct:
        coins += 10
        stars += 1
        completed += 1
        feedback_label.text = "¡Excelente! ⭐ +10 monedas. " + explanation
        _update_coin_label()
        _save_progress()
        if completed % 5 == 0:
            feedback_label.text += "\n¡Completaste 5 retos! Hay nuevas recompensas."
        _new_question_deferred()
    else:
        feedback_label.text = "¡Buen intento! 💜 " + explanation + " Puedes volver a intentarlo."
        answer_edit.grab_focus()

func _new_question_deferred() -> void:
    # No cambia la pregunta de inmediato; la niña puede leer el refuerzo y pulsar "Otra pregunta".
    pass

func _update_coin_label() -> void:
    if is_instance_valid(coin_label):
        coin_label.text = "🪙 Monedas: %d     ⭐ Estrellas: %d" % [coins, stars]

func _show_rewards() -> void:
    active_screen = "rewards"
    var v := _clear_panel()
    v.add_child(_label("👗 Vestidor y recompensas", 25))
    v.add_child(_label("Monedas disponibles: %d" % coins, 18))
    v.add_child(_label("Compra objetos de prueba. El arte final se añadirá después.", 15))
    var items := [
        {"name":"Peinado brillante", "cost":20},
        {"name":"Zapatillas arcoíris", "cost":30},
        {"name":"Camiseta de estrellas", "cost":25},
        {"name":"Alfombra mágica", "cost":40},
        {"name":"Cama de princesa", "cost":60},
        {"name":"Pelota para el gato", "cost":15}
    ]
    for item in items:
        var nm: String = item["name"]
        var cost: int = item["cost"]
        v.add_child(_button("%s · 🪙 %d" % [nm, cost], func(): _buy_item(nm, cost), Color(0.79, 0.46, 0.79)))
    v.add_child(_button("⬅ Volver", func(): _show_home(), Color(0.45, 0.54, 0.68)))

func _buy_item(nm: String, cost: int) -> void:
    if nm in inventory:
        _show_notice("¡Ya tienes este objeto! 😊", func(): _show_rewards())
    elif coins < cost:
        _show_notice("Te faltan monedas. ¡Sigue practicando!", func(): _show_rewards())
    else:
        coins -= cost
        inventory.append(nm)
        _save_progress()
        _show_notice("¡Desbloqueaste %s! 🎉" % nm, func(): _show_rewards())

func _show_rooms() -> void:
    active_screen = "rooms"
    var v := _clear_panel()
    v.add_child(_label("🏡 Tu casa", 25))
    v.add_child(_label("Las otras zonas se desbloquearán con tu progreso.", 16))
    var rooms := ["Dormitorio", "Baño", "Living", "Cocina", "Patio"]
    for i in range(rooms.size()):
        var room: String = rooms[i]
        var unlocked: bool = room_unlocked.get(room, false)
        var cost := [0, 30, 60, 90, 120][i]
        if unlocked:
            v.add_child(_button("✅ " + room + " · Entrar", func(): _show_notice("La zona %s estará disponible en una fase posterior del demo." % room, func(): _show_rooms()), Color(0.31, 0.68, 0.50)))
        else:
            v.add_child(_button("🔒 %s · Desbloquear (%d monedas)" % [room, cost], func(): _unlock_room(room, cost), Color(0.61, 0.57, 0.70)))
    v.add_child(_button("⬅ Volver", func(): _show_home(), Color(0.45, 0.54, 0.68)))

func _unlock_room(room: String, cost: int) -> void:
    if coins < cost:
        _show_notice("Necesitas más monedas. ¡Vamos a practicar!", func(): _show_rooms())
        return
    coins -= cost
    room_unlocked[room] = true
    _save_progress()
    _show_notice("¡Has desbloqueado %s! En la siguiente fase tendrá su propio espacio 3D." % room, func(): _show_rooms())

func _play_cat() -> void:
    if is_instance_valid(cat):
        cat.position.x += randf_range(-0.8, 0.8)
        cat.position.z += randf_range(-0.8, 0.8)
        cat.position.x = clampf(cat.position.x, -4.5, 4.5)
        cat.position.z = clampf(cat.position.z, -4.5, 4.5)
        coins += 1
        _save_progress()
    _show_notice("¡Miau! 🐱 El gatito jugó contigo. ¡Ganaste una monedita!", func(): _show_home())

func _show_notice(msg: String, callback: Callable) -> void:
    active_screen = "notice"
    var v := _clear_panel()
    v.add_child(_label(msg, 22))
    v.add_child(_button("Continuar", callback, Color(0.31, 0.68, 0.50)))

func _process(delta: float) -> void:
    if is_instance_valid(cat) and is_instance_valid(player):
        cat_phase += delta
        cat.position.y = 0.05 + abs(sin(cat_phase * 3.0)) * 0.07
        if randf() < delta * 0.3:
            cat.position.x = clampf(cat.position.x + randf_range(-0.25, 0.25), -4.5, 4.5)
            cat.position.z = clampf(cat.position.z + randf_range(-0.25, 0.25), -4.5, 4.5)
    if is_instance_valid(player) and active_screen != "welcome":
        var dir := Vector3.ZERO
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.z -= 1
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.z += 1
        if move_vector.length() > 0.1:
            dir.x += move_vector.x
            dir.z += move_vector.y
        if dir.length() > 0.1:
            dir = dir.normalized()
            player.position.x = clampf(player.position.x + dir.x * delta * 3.2, -4.8, 4.8)
            player.position.z = clampf(player.position.z + dir.z * delta * 3.2, -4.8, 4.8)
            player.rotation.y = atan2(dir.x, dir.z)

func _save_progress() -> void:
    var data := {
        "player_name": player_name,
        "player_gender": player_gender,
        "coins": coins,
        "stars": stars,
        "completed": completed,
        "room_unlocked": room_unlocked,
        "inventory": inventory,
        "question_history": question_history
    }
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f:
        return
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    player_name = str(parsed.get("player_name", ""))
    player_gender = str(parsed.get("player_gender", "niña"))
    coins = int(parsed.get("coins", 0))
    stars = int(parsed.get("stars", 0))
    completed = int(parsed.get("completed", 0))
    room_unlocked = parsed.get("room_unlocked", room_unlocked)
    inventory = parsed.get("inventory", [])
    question_history.assign(parsed.get("question_history", []))
    _apply_gender()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        # Táctil: deslizar hacia una dirección mueve al personaje durante el gesto.
        if event.pressed:
            _touch_start = event.position
        else:
            var delta_pos: Vector2 = event.position - _touch_start
            if delta_pos.length() > 35:
                move_vector = Vector2(sign(delta_pos.x), sign(delta_pos.y))
                get_tree().create_timer(0.18).timeout.connect(func(): move_vector = Vector2.ZERO)
    if event is InputEventScreenDrag:
        var rel: Vector2 = event.relative
        if rel.length() > 5:
            move_vector = Vector2(sign(rel.x), sign(rel.y))
            get_tree().create_timer(0.12).timeout.connect(func(): move_vector = Vector2.ZERO)

var _touch_start := Vector2.ZERO
