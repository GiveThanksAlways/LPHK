import threading
import time
import colorsys
import window
import lp_colors

# --- Effect Settings ---
WAVE_SPEED = 2  # How many seconds it takes for the wave to cross the pad
WAVE_ANGLE = 45 # Angle of the wave in degrees
SATURATION = 1  # Color saturation (0.0 to 1.0)
BRIGHTNESS = 1  # Color brightness (0.0 to 1.0)
# -----------------------

_thread = None
_stop_event = None

def _art_thread(lp_object):
    """
    This function runs in a separate thread and continuously updates the Launchpad LEDs.
    """
    global _stop_event
    if not _stop_event:
        _stop_event = threading.Event()

    import math
    rad = WAVE_ANGLE * (math.pi / 180.0)
    sin_val = math.sin(rad)
    cos_val = math.cos(rad)

    while not _stop_event.is_set():
        if not window.lp_connected or window.app.button_mode != "art":
            break

        start_time = time.time()
        for x in range(9):
            for y in range(9):
                if _stop_event.is_set():
                    break
                
                # Calculate the position in the wave
                pos = (x * cos_val + y * sin_val) / (9 * (abs(cos_val) + abs(sin_val)))
                
                # Get the hue from the current time and position
                hue = (start_time / WAVE_SPEED + pos) % 1.0
                
                # Convert HSV to RGB
                rgb = colorsys.hsv_to_rgb(hue, SATURATION, BRIGHTNESS)
                
                # Scale RGB to 0-255 and set the LED
                color = [int(c * 255) for c in rgb]
                
                if window.lp_mode == "Mk1":
                     lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
                else:
                    lp_object.LedCtrlXYByRGB(x, y, color)

        time.sleep(0.01) # Small delay to prevent high CPU usage

    # Turn off all LEDs when the thread stops
    if lp_object and window.lp_connected:
        lp_colors.raw_clear()


def start(lp_object):
    """
    Starts the art mode thread.
    """
    global _thread, _stop_event
    if _thread and _thread.is_alive():
        return

    _stop_event = threading.Event()
    _thread = threading.Thread(target=_art_thread, args=(lp_object,))
    _thread.daemon = True
    _thread.start()
    print("[art_mode] Art mode started.")


def stop():
    """
    Stops the art mode thread.
    """
    global _thread, _stop_event
    if _stop_event:
        _stop_event.set()
    if _thread:
        _thread.join(timeout=1)
        _thread = None
    print("[art_mode] Art mode stopped.")