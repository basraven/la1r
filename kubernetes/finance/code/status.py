from datetime import datetime

def get_timestamp():
    return datetime.now().strftime(("%Y-%m-%d %H:%M:%S"))

# Create a handler for our read (GET) people
def read():
    return {
        "peerberry" : "online",
        "envestio"  : "online"
    }