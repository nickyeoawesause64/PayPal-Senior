#!/bin/bash

# Create project directory
mkdir paypal-senior
cd paypal-senior || exit

# Create backend directory and subdirectories
mkdir -p backend/models backend/routes backend/middleware

# Create .env file
cat <<EOL >backend/.env
MONGO_URI=your_mongo_db_connection_string
PORT=3000
JWT_SECRET=your_jwt_secret
EOL

# Create server.js
cat <<EOL >backend/server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const axios = require('axios');

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.log(err));

const authRoutes = require('./routes/auth');
const transactionRoutes = require('./routes/transaction');

app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);

app.post('/api/verify-transaction', async (req, res) => {
    try {
        const { transaction_amount, is_official } = req.body;
        const response = await axios.post('http://localhost:5000/predict', {
            transaction_amount,
            is_official
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).send('Server error');
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(\`Server running on http://localhost:\${PORT}\`);
});
EOL

# Create User model
cat <<EOL >backend/models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
});

UserSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

UserSchema.methods.comparePassword = async function (password) {
    return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', UserSchema);
EOL

# Create Transaction model
cat <<EOL >backend/models/Transaction.js
const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    details: { type: String, required: true },
    transaction_amount: { type: Number, required: true },
    is_official: { type: Boolean, required: true },
    date: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Transaction', TransactionSchema);
EOL

# Create auth route
cat <<EOL >backend/routes/auth.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');

router.post('/register', async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = new User({ email, password });
        await user.save();
        res.status(201).send('User registered');
    } catch (error) {
        res.status(500).send('Server error');
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email });
        if (!user) return res.status(400).send('Invalid credentials');
        const isMatch = await user.comparePassword(password);
        if (!isMatch) return res.status(400).send('Invalid credentials');
        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
        res.json({ token });
    } catch (error) {
        res.status(500).send('Server error');
    }
});

module.exports = router;
EOL

# Create transaction route
cat <<EOL >backend/routes/transaction.js
const express = require('express');
const router = express.Router();
const Transaction = require('../models/Transaction');
const auth = require('../middleware/auth');

router.post('/', auth, async (req, res) => {
    try {
        const transaction = new Transaction({ ...req.body, user: req.user.id });
        await transaction.save();
        res.status(201).send('Transaction created');
    } catch (error) {
        res.status(500).send('Server error');
    }
});

router.get('/', auth, async (req, res) => {
    try {
        const transactions = await Transaction.find({ user: req.user.id });
        res.json(transactions);
    } catch (error) {
        res.status(500).send('Server error');
    }
});

module.exports = router;
EOL

# Create auth middleware
cat <<EOL >backend/middleware/auth.js
const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
    const token = req.header('Authorization');
    if (!token) return res.status(401).send('Access denied');

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(400).send('Invalid token');
    }
};
EOL

# Initialize npm and install packages in backend
cd backend || exit
npm init -y
npm install express mongoose bcryptjs jsonwebtoken cors dotenv axios
npm install --save-dev nodemon
cd ..

# Create frontend directory and files
mkdir frontend
cat <<EOL >frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PayPal Senior</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>PayPal Senior</h1>
    </header>
    <main>
        <section id="login-section">
            <h2>Login</h2>
            <form id="login-form">
                <label for="email">Email:</label>
                <input type="email" id="email" name="email" required>
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
                <button type="submit">Login</button>
            </form>
        </section>
        <section id="transaction-section" class="hidden">
            <h2>Transactions</h2>
            <button id="new-transaction">New Transaction</button>
            <ul id="transaction-list">
                <!-- Transactions will be listed here -->
            </ul>
        </section>
        <section id="alerts-section" class="hidden">
            <h2>Alerts</h2>
            <ul id="alert-list">
                <!-- Alerts will be listed here -->
            </ul>
        </section>
    </main>
    <script src="app.js"></script>
</body>
</html>
EOL

cat <<EOL >frontend/styles.css
body {
    font-family: Arial, sans-serif;
    background-color: #f4f4f4;
    margin: 0;
    padding: 0;
}

header {
    background-color: #0070ba;
    color: white;
    text-align: center;
    padding: 1rem 0;
}

main {
    padding: 1rem;
}

.hidden {
    display: none;
}

form {
    display: flex;
    flex-direction: column;
    max-width: 300px;
    margin: 0 auto;
}

label {
    margin-bottom: 0.5rem;
}

input {
    margin-bottom: 1rem;
    padding: 0.5rem;
    font-size: 1rem;
}

button {
    background-color: #0070ba;
    color: white;
    border: none;
    padding: 0.75rem;
    font-size: 1rem;
    cursor: pointer;
}

button:hover {
    background-color: #005a9c;
}
EOL

cat <<EOL >frontend/app.js
document.getElementById('login-form').addEventListener('submit', function (event) {
    event.preventDefault();
    login();
});

function login() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    fetch('http://localhost:3000/api/auth/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password })
    })
        .then(response => response.json())
        .then(data => {
            if (data.token) {
                localStorage.setItem('token', data.token);
                document.getElementById('login-section').classList.add('hidden');
                document.getElementById('transaction-section').classList.remove('hidden');
                document.getElementById('alerts-section').classList.remove('hidden');
            } else {
                alert('Invalid login credentials');
            }
        });
}

document.getElementById('new-transaction').addEventListener('click', async function () {
    const transactionDetails = prompt('Enter transaction details:');
    const transactionAmount = parseFloat(prompt('Enter transaction amount:'));
    const isOfficial = confirm('Is this an official transaction? (OK for Yes, Cancel for No)');
    if (transactionDetails) {
        const isPhishing = await checkTransaction(transactionAmount, isOfficial);
        if (isPhishing) {
            alert('High-risk transaction detected!');
            addAlert('High-risk transaction detected.');
        } else {
            addTransaction(transactionDetails);
        }
    }
});

async function checkTransaction(transactionAmount, isOfficial) {
    try {
        const response = await fetch('http://localhost:3000/api/verify-transaction', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': localStorage.getItem('token')
            },
            body: JSON.stringify({ transaction_amount: transactionAmount, is_official: isOfficial ? 1 : 0 })
        });
        const data = await response.json();
        return data.is_phishing;
    } catch (error) {
        console.error('Error checking transaction', error);
        return false;
    }
}

function addTransaction(transaction) {
    const transactionList = document.getElementById('transaction-list');
    const listItem = document.createElement('li');
    listItem.textContent = transaction;
    transactionList.appendChild(listItem);
}

function addAlert(alert) {
    const alertList = document.getElementById('alert-list');
    const listItem = document.createElement('li');
    listItem.textContent = alert;
    alertList.appendChild(listItem);
}
EOL

# Create AI directory and files
mkdir ai
cat <<EOL >ai/app.py
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
EOL

cat <<EOL >ai/train_model.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import pickle

# Simulate data
data = {
    'transaction_amount': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    'is_official': [0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
    'is_phishing': [0, 0, 1, 0, 1, 0, 1, 0, 1, 0]
}

# Create DataFrame
df = pd.DataFrame(data)

# Split data
X = df[['transaction_amount', 'is_official']]
y = df['is_phishing']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Save model
with open('phishing_model.pkl', 'wb') as f:
    pickle.dump(model, f)
EOL

# Initialize Python virtual environment and install dependencies
cd ai || exit
python3 -m venv venv
source venv/bin/activate
pip install flask scikit-learn pandas numpy

# Train the model
python train_model.py

echo "Setup complete! Now you can start your servers."

echo "To start the backend server, run: cd backend && npm start"
echo "To start the AI server, run: cd ai && source venv/bin/activate && python app.py"
