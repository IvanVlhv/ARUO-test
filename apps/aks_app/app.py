from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify({
        "message": "AKS sample is running",
        "path_hint": "/aks",
        "storage_account": os.getenv("STORAGE_ACCOUNT_NAME", "not-set"),
        "key_vault": os.getenv("KEY_VAULT_NAME", "not-set")
    })

@app.get("/healthz")
def healthz():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
