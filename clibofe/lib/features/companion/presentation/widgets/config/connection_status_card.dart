import 'package:flutter/material.dart';

class ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final String backendUrl;

  const ConnectionStatusCard({
    super.key,
    required this.isConnected,
    required this.backendUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        border: Border.all(color: isConnected ? Colors.green : Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConnected
                  ? "Backend is reachable and ONLINE!"
                  : "Cannot connect to backend at $backendUrl. Check server logs and IP address.",
              style: TextStyle(
                color: isConnected ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
