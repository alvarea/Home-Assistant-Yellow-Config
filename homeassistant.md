# CODIGO TEMPORAL EXCLUIDO


# REGLA: ALARMA MODO TRANSICION PENDING

- id: A2_alarma_disarmed_pending
  alias: 'A2 Alarma Armando'
  trigger:
    - platform: state
      entity_id: alarm_control_panel.ha
      from: 'disarmed'
      to: 'pending'
  action:
     # Aviso sonoro con Xiaomi GW
    - service: xiaomi_aqara.stop_ringtone
      data:
        gw_mac: !secret xiaomi_gateway
    - service: xiaomi_aqara.play_ringtone
      data_template:
        gw_mac: !secret xiaomi_gateway
        ringtone_id: 10005
        ringtone_vol: >-
            {{ states('input_number.xiaomi_volume_alarm_disarmed') | int }}

- id: A3_alarma_armed_pending
  alias: 'A3 Alarma Desarmando'
  trigger:
    - platform: state
      entity_id: alarm_control_panel.ha
      from: 'armed_away'
      to: 'pending'
    - platform: state
      entity_id: alarm_control_panel.ha
      from: 'armed_home'
      to: 'pending'
  action:
    - service: xiaomi_aqara.stop_ringtone
      data:
        gw_mac: !secret xiaomi_gateway
    - service: xiaomi_aqara.play_ringtone
      data_template:
        gw_mac: !secret xiaomi_gateway
        ringtone_id: 10004
        ringtone_vol: >-
            {{ states('input_number.xiaomi_volume_alarm_armed') | int }}


- id: L09_luces_on_estudio_on_sensor
  alias: 'L09 Luces On Estudio Según Sensor'
  trigger:
    - platform: state
      entity_id: binary_sensor.motion_sensor_158d0001e464a6
      to: 'on'
  condition:
    condition: or  # 'when dark' condition: either after sunset or before sunrise
    conditions:
      - condition: sun
        after: sunset
        after_offset: "-0:15:00"
      - condition: sun
        before: sunrise
        before_offset: "1:30:00"
  action:
    - service: light.turn_on
      entity_id: light.luz_estudio
      data:
        brightness: 180
        rgb_color: [255, 187, 106]


- id: A8_alarma_sirenas_off_on
  alias: 'A8 Alarma Boton Panico On'
  trigger:
    platform: state
    entity_id: input_boolean.panic_button
    from: 'off'
    to: 'on'
    #value_template: "{{ states('input_number.panic_button_code') | int = 2309 }}"
  action:
    # Aviso ALARMA con Xiaomi Sirena
    - service: script.turn_on
      entity_id: script.sirena_alarma
    # Notifica Telegram
    - service: script.turn_on
      #entity_id: script.notifica_alarma CAMBIAR GO LIVE
      entity_id: script.notifica_evento
      data:
        variables:
          title: '*ALARMA HOMY*'
          message: >
            >>> URGENTE: BOTON PANICO ACTIVADO