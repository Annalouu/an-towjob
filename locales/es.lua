local Translations = {
    error = {
        finish_your_work = "Primero termina tu trabajo",
        not_right_vehicle = "Este no es el vehículo correcto",
        failed = "Falló",
        must_be_towing_vehicle = "Debes estar en un vehículo que remolque primero",
        no_work_done = "Todavía no has hecho ningún trabajo",
        closest_vehicle_not_delivery_truck = "El vehículo más cercano no es un camión de envío",
        no_vehicle_nearby = "No hay vehículo cerca",
        not_enough_money_deposit = "No tienes suficiente dinero, el depósito es $%{price}",
    },
    success = {
        take_vehicle_hayes_depot = "Lleva el vehículo a Hayes Depot",
        vehicle_towed = "Vehículo remolcado",
        vehicle_taken_off = "Vehículo removido de la grúa",
        vehicle_stored = "Vehículo almacenado",
        deposit_of_paid = "Tienes el depósito de $%{price}, - pagado",
        you_have_paid = "Has pagado el depósito de $%{price}",
        you_got_back = "Recibiste $%{price} de vuelta del depósito",
        you_got_paid = "Te han pagado $%{payment}, gracias por tu servicio",
    },
    info = {
        take_out_flatbed = "Sacar la Flatbed",
        store_the_flatbed = "Guardar la Flatbed",
        collect_payslip = "Recolectar el pago",
        tow = "Remolcar",
        current_task = "TAREA ACTUAL",
        available_trucks = "Camiones disponibles",
        close_menu = "⬅ Cerrar menú",
        someone_called_tow = "Alguien pidio una grúa, ver a la ubicación",
        hoisting_vehicle = "Remolcando el vehículo...",
        take_vehicle_impound_lot = "Lleva el vehículo al depósito de vehículos",
        removing_vehicle = "Removiendo vehículo...",
        vehicle_delivered = "Has entregado un vehículo, espera",
        new_vehicle_for_pickup = "Un nuevo vehículo puede ser recojido",
        toggle_npc_job = "Comenzar/terminar trabajo con NPCs",
    },
    email = {
        sender = "Floyd",
        subject = "Trabajo de grúa",
    }
}

if GetConvar('qb_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
