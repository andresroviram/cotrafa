import 'package:flutter/material.dart';

class UsersWeb extends StatelessWidget {
  const UsersWeb({super.key, required this.body, required this.onRefresh});

  final Widget body;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SizedBox(
          width: 960,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'Lista de usuarios',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Actualizar usuarios',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    ),
  );
}
