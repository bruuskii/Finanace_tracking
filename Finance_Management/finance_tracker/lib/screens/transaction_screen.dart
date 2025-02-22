import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _transactionType = 'pay';
  final _searchController = TextEditingController();
  List<Transaction> _searchResults = [];

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _transactionType,
                items: const [
                  DropdownMenuItem(value: 'pay', child: Text('Pay')),
                  DropdownMenuItem(value: 'deposit', child: Text('Deposit')),
                ],
                onChanged: (value) {
                  setState(() {
                    _transactionType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await Provider.of<AccountProvider>(context, listen: false)
                    .addTransaction(
                  _titleController.text,
                  _descriptionController.text,
                  double.parse(_amountController.text),
                  _transactionType,
                );
                _titleController.clear();
                _descriptionController.clear();
                _amountController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = await Provider.of<AccountProvider>(context, listen: false)
        .searchTransactions(query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<AccountProvider>(context).selectedAccount?.name ?? '',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search transactions',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _performSearch,
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        final transactions = provider.transactions;
        if (transactions.isEmpty) {
          return const Center(
            child: Text('No transactions yet'),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionTile(transaction);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final transaction = _searchResults[index];
        return _buildTransactionTile(transaction);
      },
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isDeposit = transaction.type == 'deposit';
    final amountColor = isDeposit ? Colors.green : Colors.red;
    final amountPrefix = isDeposit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(transaction.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description.isNotEmpty)
              Text(transaction.description),
            Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
