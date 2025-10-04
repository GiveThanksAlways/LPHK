import threading
import time
import colorsys
import random
import math
import window
import lp_colors

# --- Global Settings ---
WAVE_SPEED = 2  # Seconds for wave to cross the pad
BREATHE_SPEED = 2  # Seconds for full breathe cycle
SPECTRUM_SPEED = 3  # Seconds for full spectrum cycle
RIPPLE_SPEED = 0.5  # Seconds for ripple to spread
STARLIGHT_DENSITY = 0.05  # Chance per button per frame for starlight
SATURATION = 1.0
BRIGHTNESS = 1.0
PASTEL_SATURATION = 0.8
PASTEL_BRIGHTNESS = 0.05
STATIC_COLOR = [0, 255, 255]  # Cyan for static mode
# -----------------------

_thread = None
_stop_event = None
_current_mode = None
_pressed_buttons = set()  # For reactive/ripple modes
is_rgb_active = False

def _rgb_thread(lp_object, mode):
    """
    Main thread for RGB effects. Runs the selected mode continuously.
    """
    global _stop_event, _current_mode
    if not _stop_event:
        _stop_event = threading.Event()
    _current_mode = mode

    while not _stop_event.is_set():
        if not window.lp_connected or window.app.button_mode != f"rgb_{mode}":
            break

        if mode == "static":
            _static_effect(lp_object)
        elif mode == "breathing":
            _breathing_effect(lp_object)
        elif mode == "wave":
            _wave_effect(lp_object)
        elif mode == "wave2":
            _wave2_effect(lp_object)
        elif mode == "spectrum":
            _spectrum_effect(lp_object)
        elif mode == "reactive":
            _reactive_effect(lp_object)
        elif mode == "ripple":
            _ripple_effect(lp_object)
        elif mode == "starlight":
            _starlight_effect(lp_object)

        time.sleep(0.01)  # ~100 FPS

    # Clear LEDs on stop
    if lp_object and window.lp_connected:
        lp_colors.raw_clear()

def _static_effect(lp_object):
    """All buttons set to a static color."""
    for x in range(9):
        for y in range(9):
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, STATIC_COLOR[0] // 64, STATIC_COLOR[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, STATIC_COLOR)

def _breathing_effect(lp_object):
    """Fade all buttons in and out."""
    t = time.time() % BREATHE_SPEED
    intensity = (1 + math.sin(2 * math.pi * t / BREATHE_SPEED)) / 2  # 0 to 1
    color = [int(c * intensity) for c in STATIC_COLOR]
    for x in range(9):
        for y in range(9):
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, color)

def _wave_effect(lp_object):
    """Rainbow wave across the grid."""
    rad = 45 * (math.pi / 180.0)
    sin_val = math.sin(rad)
    cos_val = math.cos(rad)
    start_time = time.time()
    for x in range(9):
        for y in range(9):
            pos = (x * cos_val + y * sin_val) / (9 * (abs(cos_val) + abs(sin_val)))
            hue = (start_time / WAVE_SPEED + pos) % 1.0
            rgb = colorsys.hsv_to_rgb(hue, SATURATION, BRIGHTNESS)
            color = [int(c * 255) for c in rgb]
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, color)

def _spectrum_effect(lp_object):
    """Full spectrum color shift across all buttons."""
    hue = (time.time() / SPECTRUM_SPEED) % 1.0
    rgb = colorsys.hsv_to_rgb(hue, SATURATION, BRIGHTNESS)
    color = [int(c * 255) for c in rgb]
    for x in range(9):
        for y in range(9):
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, color)

def _reactive_effect(lp_object):
    """Buttons light up briefly when pressed."""
    global _pressed_buttons
    for x, y in _pressed_buttons.copy():
        hue = random.random()  # Random color on press
        rgb = colorsys.hsv_to_rgb(hue, SATURATION, BRIGHTNESS)
        color = [int(c * 255) for c in rgb]
        if window.lp_mode == "Mk1":
            lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
        else:
            lp_object.LedCtrlXYByRGB(x, y, color)
        _pressed_buttons.discard((x, y))  # Fade after one frame

def _ripple_effect(lp_object):
    """Ripple effect from pressed buttons."""
    global _pressed_buttons
    ripples = []
    for x, y in _pressed_buttons:
        ripples.append((x, y, time.time()))
    _pressed_buttons.clear()

    for x in range(9):
        for y in range(9):
            max_intensity = 0
            for rx, ry, start in ripples:
                dist = abs(x - rx) + abs(y - ry)  # Manhattan distance for vertical/horizontal waves
                age = time.time() - start
                if dist <= age * RIPPLE_SPEED:
                    intensity = 1 - (dist / (age * RIPPLE_SPEED))
                    max_intensity = max(max_intensity, intensity)
            color = [int(c * max_intensity) for c in STATIC_COLOR]
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, color)

def _starlight_effect(lp_object):
    """Random twinkling stars."""
    for x in range(9):
        for y in range(9):
            if random.random() < STARLIGHT_DENSITY:
                hue = random.random()
                rgb = colorsys.hsv_to_rgb(hue, SATURATION, BRIGHTNESS)
                color = [int(c * 255) for c in rgb]
                if window.lp_mode == "Mk1":
                    lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
                else:
                    lp_object.LedCtrlXYByRGB(x, y, color)
            else:
                # Dim or off
                if window.lp_mode == "Mk1":
                    lp_object.LedCtrlXY(x, y, 0, 0)
                else:
                    lp_object.LedCtrlXYByRGB(x, y, [0, 0, 0])

def _wave2_effect(lp_object):
    """Pastel rainbow wave across the grid."""
    rad = 45 * (math.pi / 180.0)
    sin_val = math.sin(rad)
    cos_val = math.cos(rad)
    start_time = time.time()
    for x in range(9):
        for y in range(9):
            pos = (x * cos_val + y * sin_val) / (9 * (abs(cos_val) + abs(sin_val)))
            hue = (start_time / WAVE_SPEED + pos) % 1.0
            rgb = colorsys.hsv_to_rgb(hue, PASTEL_SATURATION, PASTEL_BRIGHTNESS)  # Lower saturation and brightness for better visibility
            color = [int(c * 255) for c in rgb]
            if window.lp_mode == "Mk1":
                lp_object.LedCtrlXY(x, y, color[0] // 64, color[1] // 64)
            else:
                lp_object.LedCtrlXYByRGB(x, y, color)

def start(mode, lp_object):
    """Start the specified RGB mode."""
    global _thread, _stop_event, is_rgb_active
    if _thread and _thread.is_alive():
        stop()
    is_rgb_active = True
    _stop_event = threading.Event()
    _thread = threading.Thread(target=_rgb_thread, args=(lp_object, mode))
    _thread.daemon = True
    _thread.start()
    print(f"[rgb_modes] Started {mode} mode.")

def stop():
    """Stop the current RGB mode."""
    global _thread, _stop_event, _current_mode, is_rgb_active
    if _stop_event:
        _stop_event.set()
    if _thread:
        _thread.join(timeout=1)
        _thread = None
    _current_mode = None
    is_rgb_active = False
    print("[rgb_modes] Stopped RGB mode.")

def on_press(x, y):
    """Callback for reactive/ripple modes."""
    global _pressed_buttons
    if _current_mode in ["reactive", "ripple"]:
        _pressed_buttons.add((x, y))

def increase_brightness():
    global BRIGHTNESS
    BRIGHTNESS = min(1.0, BRIGHTNESS + 0.1)
    lp_colors.set_brightness(BRIGHTNESS)
    lp_colors.update_all()
    print(f"[rgb_modes] Brightness increased to {BRIGHTNESS}")

def decrease_brightness():
    global BRIGHTNESS
    BRIGHTNESS = max(0.01, BRIGHTNESS - 0.1)
    lp_colors.set_brightness(BRIGHTNESS)
    lp_colors.update_all()
    print(f"[rgb_modes] Brightness decreased to {BRIGHTNESS}")

def increase_brightness_large():
    global BRIGHTNESS
    BRIGHTNESS = min(1.0, BRIGHTNESS + 0.4)
    lp_colors.set_brightness(BRIGHTNESS)
    lp_colors.update_all()
    print(f"[rgb_modes] Brightness increased to {BRIGHTNESS}")

def decrease_brightness_large():
    global BRIGHTNESS
    BRIGHTNESS = max(0.01, BRIGHTNESS - 0.4)
    lp_colors.set_brightness(BRIGHTNESS)
    lp_colors.update_all()
    print(f"[rgb_modes] Brightness decreased to {BRIGHTNESS}")