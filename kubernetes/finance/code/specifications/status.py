from datetime import datetime

# Create a handler for our read (GET) people
def read():
    return {
        "peerberry" : "online",
        "envestio"  : "online"
    }