from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()
from api.auth import auth_bp
from api.user import user_bp
from api.payment import payment_bp
from api.transaction import transaction_bp
from api.test import test_bp

app = Flask(__name__)
# Enable CORS for Flutter/Web clients
CORS(app)

# Register Blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(user_bp, url_prefix='/user')
app.register_blueprint(payment_bp)
app.register_blueprint(transaction_bp, url_prefix='/transactions')
app.register_blueprint(test_bp)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
