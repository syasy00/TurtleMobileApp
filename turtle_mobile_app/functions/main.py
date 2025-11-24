from firebase_functions import db_fn, options
from firebase_admin import initialize_app, db, messaging
import time

# 1. Initialize
initialize_app()

# 2. Region (your RTDB is asia-southeast1)
options.set_global_options(region="asia-southeast1")

# Thresholds
MIN_TEMP = 29.0
MAX_TEMP = 32.0
MIN_HUM = 65.0
MAX_HUM = 75.0

@db_fn.on_value_updated(
    reference="/nests/{uid}/{nest_id}",
    instance="smartshell-ad097-default-rtdb"
)
def monitor_nest_conditions(event: db_fn.Event[db_fn.Change]):
    """
    Runs whenever a nest is updated.
    Writes to /alerts/{uid} AND sends an FCM push to that user.
    """
    change = event.data
    after = change.after

    if after is None:
        print("No data in 'after' snapshot, skipping.")
        return

    current_temp = after.get("temperature")
    current_hum  = after.get("humidity")

    if current_temp is None or current_hum is None:
        print("Missing temperature/humidity, skipping.")
        return

    print(f"New data → temp={current_temp}, hum={current_hum}")

    title = ""
    body = ""
    is_alert = False

    # Temperature checks
    if current_temp > MAX_TEMP:
        title = "Temperature Alert! 🌡️"
        body  = f"Your shell is too hot ({current_temp}°C). Cool it down!"
        is_alert = True
    elif current_temp < MIN_TEMP:
        title = "Low Temperature ❄️"
        body  = f"Your shell is too cold ({current_temp}°C)."
        is_alert = True

    # Humidity checks (only if no temp alert)
    if not is_alert:
        if current_hum < MIN_HUM:
            title = "Low Humidity 💧"
            body  = f"Humidity dropped to {current_hum}%."
            is_alert = True
        elif current_hum > MAX_HUM:
            title = "High Humidity 🌧️"
            body  = f"Humidity is too high ({current_hum}%)."
            is_alert = True

    if not is_alert:
        print("Values within range, no alert.")
        return

    uid      = event.params["uid"]
    nest_id  = event.params["nest_id"]
    nest_name = after.get("name", "Smart Shell")

    # A) Write to /alerts for in-app notifications
    alerts_ref = db.reference(f"alerts/{uid}")
    new_alert_ref = alerts_ref.push()
    alert_payload = {
        "nestId": nest_id,
        "nestName": nest_name,
        "title": title,
        "body": body,
        "level": "critical",
        "createdAt": int(time.time() * 1000),
        "read": False,
    }
    new_alert_ref.set(alert_payload)
    print(f"✅ Alert written under alerts/{uid}: {alert_payload}")

    # B) Send FCM push
    token_ref = db.reference(f"users/{uid}/fcmToken")
    fcm_token = token_ref.get()

    if not fcm_token:
        print(f"❌ No fcmToken for user {uid}, skipping push.")
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "nestId": nest_id,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        token=fcm_token,
    )

    try:
        resp = messaging.send(message)
        print(f"✅ Push sent successfully: {resp}")
    except Exception as e:
        print(f"❌ Error sending FCM push: {e}")
