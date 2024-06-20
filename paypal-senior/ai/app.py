from flask import Flask, request, jsonify
import pickle
import numpy as np

app = Flask(__name__)

with open('phishing_model.pkl', 'rb') as f:
    model = pickle.load(f)

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    transaction_amount = data['transaction_amount']
    is_official = data['is_official']
    features = np.array([[transaction_amount, is_official]])
    prediction = model.predict(features)
    return jsonify({'is_phishing': int(prediction[0])})

if __name__ == '__main__':
    app.run(debug=True)
