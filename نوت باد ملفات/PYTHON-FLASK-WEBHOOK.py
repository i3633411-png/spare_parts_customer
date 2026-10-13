from flask import Flask, request

app = Flask(__name__)

FILE_PATH = r"C:\Users\WIN 11 PRO\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Files\Signal.txt"

SYMBOL = "BTCUSD"  # 👈 ثابت

@app.route('/webhook', methods=['POST'])
def webhook():
    try:
        # 🔥 قراءة كل أنواع البيانات
        if request.data:
            raw = request.data.decode('utf-8')
        elif request.form:
            raw = str(request.form)
        elif request.json:
            raw = str(request.json)
        else:
            raw = ""

        raw = raw.upper()

        print("==============================")
        print("📩 RAW:", raw)

        # 🔥 استخراج BUY / SELL فقط
        if "BUY" in raw:
            action = "BUY"
        elif "SELL" in raw:
            action = "SELL"
        else:
            print("❌ NO SIGNAL FOUND")
            return "OK"

        # 🔥 كتابة إشارة نظيفة
        final_signal = f"{SYMBOL},{action}"

        with open(FILE_PATH, "w") as f:
            f.write(final_signal)

        print("🔥 FINAL:", final_signal)

    except Exception as e:
        print("❌ ERROR:", e)

    return "OK"


app.run(host="0.0.0.0", port=5000)