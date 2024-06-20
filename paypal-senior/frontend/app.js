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
