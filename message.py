import sys 
import requests
import urllib
from urllib.parse import urlencode, quote_plus
import urllib.parse

def get_credentials(file_path):
    f = open(file_path)
    return f.readline().strip()

def main():
    bot_message = " ".join(sys.argv[1:])
    bot_token = get_credentials("/code/telegram.token")
    bot_chatID = get_credentials("/code/chat.id")
    encoded_message =  urllib.parse.quote(bot_message)
    send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + bot_chatID + '&parse_mode=Markdown&text=' + encoded_message
    response = requests.get(send_text)
    print(response.json())

if __name__ == "__main__":
    main()
