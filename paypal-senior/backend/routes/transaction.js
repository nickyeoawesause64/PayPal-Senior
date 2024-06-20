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
