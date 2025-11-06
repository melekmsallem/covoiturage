import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/coin_service.dart';

class CoinPurchaseScreen extends StatefulWidget {
  const CoinPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<CoinPurchaseScreen> createState() => _CoinPurchaseScreenState();
}

class _CoinPurchaseScreenState extends State<CoinPurchaseScreen> {
  double _selectedAmount = 10.0;
  bool _isLoading = false;
  double _currentBalance = 0.0;

  final List<double> _coinPackages = [5.0, 10.0, 20.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balanceData = await CoinService.getBalance();
      setState(() {
        _currentBalance = (balanceData['balance'] ?? 0.0).toDouble();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load balance: $e')),
        );
      }
    }
  }

  Future<void> _purchaseCoins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CoinService.purchaseCoins(_selectedAmount);
      final checkoutUrl = result['url'];
      
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        
        try {
          // Try different launch modes for better compatibility
          bool launched = false;
          
          // First try with external application
          try {
            if (await canLaunchUrl(uri)) {
              launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            debugPrint('External application launch failed: $e');
          }
          
          // If external failed, try with platform default
          if (!launched) {
            try {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
            } catch (e) {
              debugPrint('Platform default launch failed: $e');
            }
          }
          
          // If both failed, try with in-app web view
          if (!launched) {
            try {
              launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
            } catch (e) {
              debugPrint('In-app web view launch failed: $e');
            }
          }
          
          if (launched && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to payment...'),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (mounted) {
            // Show the URL to user as fallback
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Payment Link'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Please copy and open this link in your browser:'),
                    const SizedBox(height: 8),
                    SelectableText(
                      checkoutUrl,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          throw Exception('Could not launch payment URL: $e');
        }
      } else {
        throw Exception('No payment URL received');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Coins'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Balance:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_currentBalance.toStringAsFixed(2)} coins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Select Coin Package:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Coin Package Options
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: _coinPackages.length,
                itemBuilder: (context, index) {
                  final amount = _coinPackages[index];
                  final isSelected = _selectedAmount == amount;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue.shade700 : Colors.black87,
                            ),
                          ),
                          Text(
                            'coins',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Purchase Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _purchaseCoins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Purchase ${_selectedAmount.toStringAsFixed(0)} Coins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Coins are used to pay for trip bookings. After purchase, you will be redirected to our secure payment processor.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
