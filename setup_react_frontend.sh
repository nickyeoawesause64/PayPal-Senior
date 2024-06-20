#!/bin/bash

# Function to create file with content
create_file() {
    local file_path=$1
    shift
    local file_content="$@"
    echo "$file_content" > "$file_path"
}

# Create React App
npx create-react-app frontend
cd frontend || exit

# Install Axios
npm install axios

# Create components directory
mkdir -p src/components

# Create Login.js component
create_file src/components/Login.js \
"import React, { useState } from 'react';
import axios from 'axios';

const Login = ({ setToken }) => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('http://localhost:3000/api/auth/login', { email, password });
            setToken(response.data.token);
            localStorage.setItem('token', response.data.token);
        } catch (error) {
            alert('Invalid login credentials');
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            <label>Email:</label>
            <input type=\"email\" value={email} onChange={(e) => setEmail(e.target.value)} required />
            <label>Password:</label>
            <input type=\"password\" value={password} onChange={(e) => setPassword(e.target.value)} required />
            <button type=\"submit\">Login</button>
        </form>
    );
};

export default Login;"

# Create Transactions.js component
create_file src/components/Transactions.js \
"import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Transactions = () => {
    const [transactions, setTransactions] = useState([]);
    const [transactionDetails, setTransactionDetails] = useState('');

    useEffect(() => {
        const fetchTransactions = async () => {
            const token = localStorage.getItem('token');
            const response = await axios.get('http://localhost:3000/api/transactions', {
                headers: { Authorization: token },
            });
            setTransactions(response.data);
        };

        fetchTransactions();
    }, []);

    const handleNewTransaction = async () => {
        const transactionAmount = parseFloat(prompt('Enter transaction amount:'));
        const isOfficial = confirm('Is this an official transaction? (OK for Yes, Cancel for No)');
        if (transactionDetails) {
            const token = localStorage.getItem('token');
            const response = await axios.post('http://localhost:3000/api/verify-transaction', {
                transaction_amount: transactionAmount,
                is_official: isOfficial ? 1 : 0,
            }, {
                headers: { Authorization: token },
            });

            if (response.data.is_phishing) {
                alert('High-risk transaction detected!');
                // Add alert to alerts component
            } else {
                await axios.post('http://localhost:3000/api/transactions', {
                    details: transactionDetails,
                    transaction_amount: transactionAmount,
                    is_official,
                }, {
                    headers: { Authorization: token },
                });
                setTransactions([...transactions, { details: transactionDetails, transaction_amount: transactionAmount, is_official }]);
            }
        }
    };

    return (
        <div>
            <h2>Transactions</h2>
            <button onClick={handleNewTransaction}>New Transaction</button>
            <ul>
                {transactions.map((transaction, index) => (
                    <li key={index}>{transaction.details}</li>
                ))}
            </ul>
        </div>
    );
};

export default Transactions;"

# Create Alerts.js component
create_file src/components/Alerts.js \
"import React, { useState, useEffect } from 'react';

const Alerts = () => {
    const [alerts, setAlerts] = useState([]);

    // Mock function to simulate adding alerts
    useEffect(() => {
        const mockAlerts = ['High-risk transaction detected.', 'Family member approval required.'];
        setAlerts(mockAlerts);
    }, []);

    return (
        <div>
            <h2>Alerts</h2>
            <ul>
                {alerts.map((alert, index) => (
                    <li key={index}>{alert}</li>
                ))}
            </ul>
        </div>
    );
};

export default Alerts;"

# Update App.js
create_file src/App.js \
"import React, { useState } from 'react';
import Login from './components/Login';
import Transactions from './components/Transactions';
import Alerts from './components/Alerts';
import './App.css';

function App() {
    const [token, setToken] = useState(localStorage.getItem('token'));

    if (!token) {
        return <Login setToken={setToken} />;
    }

    return (
        <div className=\"App\">
            <header>
                <h1>PayPal Senior</h1>
            </header>
            <main>
                <Transactions />
                <Alerts />
            </main>
        </div>
    );
}

export default App;"

# Update index.js
create_file src/index.js \
"import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';

ReactDOM.render(
    <React.StrictMode>
        <App />
    </React.StrictMode>,
    document.getElementById('root')
);"

# Update App.css
create_file src/App.css \
"body {
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
}"

# Start the React application
echo "Setup complete! Starting the React application..."
npm start
