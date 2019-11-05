from flask import render_template
# Source: https://realpython.com/flask-connexion-rest-api/
import connexion
import logging
import hashlib
from os import urandom

def createNewAdminToken(db):
    cursor = db.cursor()
    adminToken = str(hashlib.sha512(urandom(60)).hexdigest())
    cursor.execute("INSERT INTO `finance`.`tokens` (`provider`, `token`) VALUES('admin', '"+ adminToken +"') ;")
    db.commit()

def prepAdminToken(db):
    cursor = db.cursor()
    cursor.execute("CREATE SCHEMA IF NOT EXISTS `finance` DEFAULT CHARACTER SET utf8 ;")
    cursor.execute("USE `finance`")
    cursor.execute("SHOW TABLES LIKE 'tokens'")
    if cursor.fetchone():
        logging.info("Tokens table exists")
        cursor.execute("SELECT `token` FROM `finance`.`tokens` WHERE `provider` = 'admin' LIMIT 1 ;")
        if cursor.fetchone():
            logging.info("Admin token present")    
        else:
            logging.info("Admin token not present, creating new one")
            createNewAdminToken(db)
    else:
        logging.info("Tokens table does not exists, creating table")
        cursor.execute("CREATE TABLE tokens( `provider` VARCHAR(120) PRIMARY KEY NOT NULL, `token` CHAR(128) NOT NULL )")
        createNewAdminToken(db)
    cursor.execute("SELECT `token` FROM `finance`.`tokens` WHERE `provider` = 'admin' LIMIT 1 ;")
    adminToken = cursor.fetchone()
    if adminToken:
        print("\n######\n Admin Token: %s \n######\n" % adminToken)
    else:
        raise ValueError
    
    return adminToken
    
        
        




# Create the application instance
app = connexion.App(__name__, specification_dir='./specifications')

# Read the swagger.yml file to configure the endpoints
app.add_api('./swagger.yml')


if __name__ == '__main__':

    import mysql.connector

    db = mysql.connector.connect(
        host="localhost",
        port=3306,
        user="admin",
        passwd="admin"
    )

    adminToken = prepAdminToken(db)
    
    db.cursor().close()
    # app.run(host='0.0.0.0', port=5000, debug=True)