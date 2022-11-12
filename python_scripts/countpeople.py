home = 0
for entity_id in hass.states.entity_ids('binary_sensor'):
    state = hass.states.get(entity_id)
    if state.object_id in ['family_home_mfc','family_home_aac','family_home_paf','family_home_aaf'] and state.state == 'on':
        home = home + 1

hass.states.set('sensor.family_home', home, {
    'unit_of_measurement': 'personas',
    'friendly_name': '¿Cuántos?', # en Casa?'
    'icon': 'mdi:account-switch'
})


#if home == 1
#    hass.states.set('sensor.family_home', home, {'icon': 'mdi:account'})
#else if home == 2
#    hass.states.set('sensor.family_home', home, {'icon': 'mdi:account-multiple'})
#else if home == 3
#    hass.states.set('sensor.family_home', home, {'icon': 'mdi:account-group'})
#else if home == 4
#    hass.states.set('sensor.family_home', home, {'icon': 'mdi:account-multiple-check'})


sleep = 0
for entity_id in hass.states.entity_ids('input_boolean'):
    state = hass.states.get(entity_id)
    if state.object_id in ['family_sleep_home_mfc','family_sleep_home_aac',
                           'family_sleep_home_paf','family_sleep_home_aaf'] and state.state == 'on':
        sleep = sleep + 1

hass.states.set('sensor.family_sleep_home', sleep, {
    'unit_of_measurement': 'personas',
    'friendly_name': '¿Duermen?', # Duermen en Casa?'
    'icon': 'mdi:sleep'
})
