import telegram
import sys 

CHAT_ID="1094536138"

def get_credentials(file_path):
    f = open(file_path)
    return f.readline().strip()

def main():
    cred = get_credentials("/code/telegram.token")
    message = " ".join(sys.argv[1:])
    bot = telegram.Bot(token=cred)
    #chat_id = bot.get_updates()[-1].message.chat_id
    bot.send_message(chat_id=CHAT_ID, text=message)

if __name__ == "__main__":
    main()