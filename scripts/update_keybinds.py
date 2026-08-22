import json
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FILE_PATH = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "data", "keybinds.json"))

def load_data():
    if not os.path.exists(FILE_PATH):
        return {"categories": []}
    with open(FILE_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_data(data):
    with open(FILE_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def handle_shortcut(action_type, cat_id, sc_id, new_key="", action_name="", cmd=""):
    data = load_data()
    found = False
    
    for cat in data.get('categories', []):
        if cat['id'] == cat_id:
            if action_type == "update":
                for sc in cat['shortcuts']:
                    if sc['id'] == sc_id:
                        sc['key'] = new_key
                        found = True
                        break
            elif action_type == "add":
                new_entry = {
                    "id": sc_id,
                    "key": new_key,
                    "action": action_name,
                    "type": "exec_cmd",
                    "args": [cmd] if cmd else [],
                    "locked": False
                }
                cat['shortcuts'].append(new_entry)
                found = True
            elif action_type == "delete":
                # Lọc bỏ shortcut có id cần xoá
                cat['shortcuts'] = [sc for sc in cat['shortcuts'] if sc['id'] != sc_id]
                found = True
            break
            
    if found:
        save_data(data)
        # Gọi reload NGAY SAU KHI ghi file xong hẳn -> đảm bảo keybind_loader.lua
        # luôn đọc đúng bản JSON mới nhất, không bị race với reload gọi từ QML
        # (QML có thể trigger reload trước khi write này kịp chạy xong).
        try:
            subprocess.run(["hyprctl", "reload"], check=False)
        except FileNotFoundError:
            print("WARNING: hyprctl not found, skipped reload")
        print("SUCCESS")
    else:
        print("ERROR: Category not found")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 update_keybinds.py [update|add|delete] [cat_id] [sc_id] [key] [action_name] [cmd]")
        sys.exit(1)
        
    act = sys.argv[1]
    c_id = sys.argv[2]
    s_id = sys.argv[3]
    
    if act == "update" and len(sys.argv) >= 5:
        handle_shortcut("update", c_id, s_id, sys.argv[4])
    elif act == "add" and len(sys.argv) >= 7:
        handle_shortcut("add", c_id, s_id, sys.argv[4], sys.argv[5], sys.argv[6])
    elif act == "delete":
        handle_shortcut("delete", c_id, s_id)