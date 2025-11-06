import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/coin_service.dart';
import '../providers/auth_provider.dart';

class CoinBalanceWidget extends StatefulWidget {
  final bool showIcon;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const CoinBalanceWidget({
    Key? key,
    this.showIcon = true,
    this.textStyle,
    this.onTap,
  }) : super(key: key);

  @override
  State<CoinBalanceWidget> createState() => _CoinBalanceWidgetState();
}

class _CoinBalanceWidgetState extends State<CoinBalanceWidget> {
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to authentication changes and refresh balance when user changes
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      _loadBalance();
    }
  }

  Future<void> _loadBalance() async {
    try {
      print('DEBUG: CoinBalanceWidget._loadBalance called');
      final balanceData = await CoinService.getBalance();
      print('DEBUG: CoinBalanceWidget received balance data: $balanceData');
      if (mounted) {
        setState(() {
          _balance = (balanceData['balance'] ?? 0.0).toDouble();
          _isLoading = false;
        });
        print('DEBUG: CoinBalanceWidget updated balance to: $_balance');
      }
    } catch (e) {
      print('DEBUG: CoinBalanceWidget error loading balance: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void refreshBalance() {
    setState(() {
      _isLoading = true;
    });
    _loadBalance();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showIcon) ...[
              Icon(
                Icons.monetization_on,
                color: Colors.blue.shade700,
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade700,
                ),
              )
            else
              Text(
                '${_balance.toStringAsFixed(2)} coins',
                style: widget.textStyle ?? TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
