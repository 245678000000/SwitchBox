#!/usr/bin/env python3
"""Extract localizable keys from Sources and write Resources/<lang>.lproj/Localizable.strings.
Simplified Chinese is the source language; English and French come from translations.py;
Traditional Chinese is converted automatically with macOS ICU (Hans-Hant)."""
import re, glob, os, subprocess, sys, json
sys.path.insert(0, os.path.dirname(__file__))
from translations import T

INT_EXPRS = {"n", "disks", "minutes", "minutes / 60", "minutes % 60", "count"}
CJK = re.compile(r'[一-鿿]')
LIT = re.compile(r'"((?:[^"\\\n]|\\\((?:[^()]|\([^()]*\))*\)|\\.)*)"')
INTERP = re.compile(r'\\\(((?:[^()]|\([^()]*\))*)\)')
SKIP = {"SwitchBox 保持亮屏"}

keys = []
for f in sorted(glob.glob('Sources/SwitchBox/*.swift')):
    for line in open(f, encoding='utf-8'):
        if line.strip().startswith('//') or 'NSLog' in line:
            continue
        for m in LIT.finditer(line.split(' //')[0]):
            body = m.group(1)
            if not CJK.search(body) or 'do shell script' in body:
                continue
            key = INTERP.sub(lambda e: '%lld' if e.group(1).strip() in INT_EXPRS else '%@', body)
            if key not in SKIP and key not in keys:
                keys.append(key)

missing = [k for k in keys if k not in T]
if missing:
    print("Missing translations:\n  " + "\n  ".join(missing)); sys.exit(1)

def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"')

# Traditional Chinese via ICU
swift = 'import Foundation\nlet d = FileHandle.standardInput.readDataToEndOfFile()\nlet a = try! JSONSerialization.jsonObject(with: d) as! [String]\nlet o = a.map { $0.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? $0 }\nFileHandle.standardOutput.write(try! JSONSerialization.data(withJSONObject: o))\n'
open('/tmp/hant.swift', 'w').write(swift)
hant = json.loads(subprocess.run(['swift', '/tmp/hant.swift'], input=json.dumps(keys).encode(), capture_output=True, check=True).stdout)
fix = {"软": "軟"}  # extra fixes if ICU misses any

tables = {
    'zh-Hans': {k: k for k in keys},
    'zh-Hant': dict(zip(keys, hant)),
    'en': {k: T[k][0] for k in keys},
    'fr': {k: T[k][1] for k in keys},
}
# Traditional terms used by Apple
tw = {"退出": "結束", "菜單欄": "選單列", "程序塢": "Dock", "訪達": "Finder", "屏幕": "螢幕", "顯示器": "顯示器", "文件": "檔案",
      "設置": "設定", "默認": "預設", "應用": "App", "權限": "權限", "磁盤": "磁碟", "快捷鍵": "快速鍵", "剪貼板": "剪貼簿",
      "廢紙簍": "垃圾桶", "藍牙": "藍牙", "信息": "資訊", "鍵盤": "鍵盤", "視頻": "影片", "緩存": "快取", "啟動": "啟動",
      "推出": "退出", "自定義": "自訂", "窗口": "視窗", "麥克風": "麥克風", "原彩顯示": "原彩顯示", "低電量模式": "低耗電模式",
      "屏保": "螢幕保護程式", "夜覽": "夜覽", "登錄": "登入", "支持": "支援", "反饋": "意見回饋"}
for k, v in tables['zh-Hant'].items():
    for a, b in tw.items():
        v = v.replace(a, b)
    v = v.replace("啓", "啟").replace("界面", "介面").replace("添加", "加入").replace("發送意見回饋", "傳送意見回饋").replace("裏", "裡")
    v = re.sub(r'([\u4e00-\u9fff])(Dock|App|Finder)', r'\1 \2', v)
    v = re.sub(r'(Dock|App|Finder)([\u4e00-\u9fff])', r'\1 \2', v)
    tables['zh-Hant'][k] = v

for lang, t in tables.items():
    d = f'Resources/{lang}.lproj'
    os.makedirs(d, exist_ok=True)
    with open(f'{d}/Localizable.strings', 'w', encoding='utf-8') as fh:
        for k in keys:
            fh.write(f'"{esc(k)}" = "{esc(t[k])}";\n')
print(f"✅ {len(keys)} keys × {len(tables)} languages")
