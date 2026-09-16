import time
from datetime import datetime, timezone

import requests
import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522

# ─── Configuracion — completar antes de correr ─────────────
SUPABASE_URL = "PEGAR_ACA_LA_SUPABASE_URL_DEL_.ENV"
SUPABASE_SERVICE_ROLE_KEY = "PEGAR_ACA_LA_SERVICE_ROLE_KEY_DEL_DASHBOARD"
CAMPO_ID = "PEGAR_ACA_EL_UUID_DEL_CAMPO"
TIEMPO_IGNORAR = 5  # segundos para ignorar relecturas del mismo tag
# ────────────────────────────────────────────────────────────

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
}

lector = SimpleMFRC522()
ultimas_lecturas = {}


def ya_fue_leida_recientemente(uid):
    uid_str = str(uid)
    ahora = time.time()
    if uid_str in ultimas_lecturas and ahora - ultimas_lecturas[uid_str] < TIEMPO_IGNORAR:
        return True
    ultimas_lecturas[uid_str] = ahora
    return False


def mandar_lectura(uid):
    url = f"{SUPABASE_URL}/rest/v1/datos_lectura"
    payload = {
        "rfid_uid": str(uid),
        "campo_id": CAMPO_ID,
        "fecha_hora": datetime.now(timezone.utc).isoformat(),
    }
    try:
        respuesta = requests.post(url, json=payload, headers=headers, timeout=5)
        if respuesta.status_code in (200, 201):
            print(f"OK - Lectura guardada: {uid}")
        else:
            print(f"ERROR de Supabase ({respuesta.status_code}): {respuesta.text}")
    except requests.exceptions.RequestException as e:
        print(f"ERROR de red: {e}")


def bucle_principal():
    print("Lista. Acerca un tag al lector...\n")
    try:
        while True:
            try:
                uid, _texto = lector.read()
            except Exception as e:
                print(f"Error leyendo tag: {e}")
                time.sleep(1)
                continue

            if not ya_fue_leida_recientemente(uid):
                print(f"Tag leido: {uid}")
                mandar_lectura(uid)

            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nDetenido manualmente")
    finally:
        GPIO.cleanup()


if __name__ == "__main__":
    bucle_principal()
