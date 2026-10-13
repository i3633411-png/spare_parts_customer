from flask import Flask, request, jsonify
import os

app = Flask(__name__)

SIGNAL_FILE = r"C:\Users\WIN 11 PRO\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Files\Signal.txt"

@app.route('/webhook', methods=['POST'])
def webhook():
    try:
        raw_data = request.data.decode('utf-8').strip()
        print(f"RAW RECEIVED: {raw_data}")

        if not raw_data:
            return jsonify({"status": "error", "message": "Empty body"}), 400

        parts = [p.strip() for p in raw_data.split(',')]
        if len(parts) != 2:
            return jsonify({"status": "error", "message": "Invalid format"}), 400

        symbol, action = parts[0], parts[1].upper()

        if not symbol.endswith("m"):
            symbol = symbol + "m"

        # 🛑 إذا كانت الإشارة SELL تحول إلى CLOSE لحماية الحساب من فتح بيع
        if action == "SELL":
            formatted_signal = f"{symbol},CLOSE"
            print(f"🔻 SELL RECEIVED -> CONVERTED TO CLOSE FILE SIGNAL: {formatted_signal}")
        else:
            formatted_signal = f"{symbol},{action}"

        with open(SIGNAL_FILE, "w", encoding="utf-8") as f:
            f.write(formatted_signal)

        print(f"✅ WRITTEN TO FILE: {formatted_signal}")
        return jsonify({"status": "success", "signal": formatted_signal}), 200

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    os.makedirs(os.path.dirname(SIGNAL_FILE), exist_ok=True)
    app.run(host='0.0.0.0', port=5000)