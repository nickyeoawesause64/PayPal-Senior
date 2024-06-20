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
