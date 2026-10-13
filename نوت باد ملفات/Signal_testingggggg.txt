import imaplib
import email
import time

# بياناتك
EMAIL = "u24820922@gmail.com"
PASSWORD = "xvalpupoospxtfid"

# نفس المسار بالضبط
file_path = r"C:\Users\WIN 11 PRO\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Files\Signal.txt"

# الاتصال
mail = imaplib.IMAP4_SSL("imap.gmail.com")
mail.login(EMAIL, PASSWORD)

last_signal = ""

def extract_signal(text):
    text = text.upper()

    if "BUY" in text or "LONG" in text:
        return "BUY"
    elif "SELL" in text or "SHORT" in text:
        return "SELL"

    return ""

while True:
    try:
        mail.select("inbox")

        result, data = mail.search(None, "ALL")
        ids = data[0].split()

        if ids:
            latest_id = ids[-1]

            result, msg_data = mail.fetch(latest_id, "(RFC822)")
            raw_email = msg_data[0][1]

            msg = email.message_from_bytes(raw_email)

            subject = msg["subject"] if msg["subject"] else ""
            body = ""

            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() == "text/plain":
                        body = part.get_payload(decode=True).decode(errors="ignore")
                        break
            else:
                body = msg.get_payload(decode=True).decode(errors="ignore")

            full_text = subject + " " + body

            signal = extract_signal(full_text)

            if signal != "" and signal != last_signal:

                # نكتب من جديد كل مرة
                with open(file_path, "w") as f:
                    symbol = "BTCUSD"  # أو استخرجه من الإيميل
                    f.write(symbol + "," + signal)

                print("🔥 NEW SIGNAL:", signal)

                last_signal = signal
            else:
                print("No new signal")

        time.sleep(5)

    except Exception as e:
        print("ERROR:", e)
        time.sleep(5)