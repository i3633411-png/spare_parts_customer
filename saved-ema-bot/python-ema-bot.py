
import imaplib
import email
import re
import time

# ?? »Ì«‰« ﬂ (⁄œ¯·Â«)
EMAIL = "u24820922@gmail.com"
PASSWORD = "xvalpupoospxtfid"

#FILE_PATH = r"C:\Users\WIN 11 PRO\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Files\Signal.txt"
# „”«— «·„·› („Â„ Ãœ«)

FILE_PATH = r"C:\Users\WIN 11 PRO\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Files\Signal.txt"

last_email_id = None

def extract_signal(text):
    match = re.search(r'([A-Z]{6,10}),(BUY|SELL)', text)
    if match:
        return match.group(1) + "," + match.group(2)
    return None

def write_signal(signal):
    with open(FILE_PATH, "w", encoding="utf-8") as f:
        f.write("")  # „”Õ «·„·›
    with open(FILE_PATH, "w", encoding="utf-8") as f:
        f.write(signal.strip())
    print("?? Saved:", signal)

def check_email():
    global last_email_id

    try:
        mail = imaplib.IMAP4_SSL("imap.gmail.com")
        mail.login(EMAIL, PASSWORD)
        mail.select("inbox")

        result, data = mail.search(None, "ALL")
        mail_ids = data[0].split()

        if not mail_ids:
            return

        latest_email_id = mail_ids[-1]

        # ?? „‰⁄ «· ﬂ—«—
        if latest_email_id == last_email_id:
            mail.logout()
            return

        last_email_id = latest_email_id

        result, data = mail.fetch(latest_email_id, "(RFC822)")
        raw_email = data[0][1]

        msg = email.message_from_bytes(raw_email)

        text = ""

        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    text = part.get_payload(decode=True).decode(errors="ignore")
        else:
            text = msg.get_payload(decode=True).decode(errors="ignore")

        signal = extract_signal(text)

        if signal:
            print("?? NEW SIGNAL:", signal)
            write_signal(signal)

        mail.logout()

    except Exception as e:
        print("? Error:", e)

#  ‘€Ì· „” „—
while True:
    print("?? Checking email...")
    check_email()
    time.sleep(5)