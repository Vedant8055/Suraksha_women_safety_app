import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';
import 'package:suraksha_women_safety_app/features/ai_assistant/ai_service.dart';
import 'package:animate_do/animate_do.dart';

class POSHChatScreen extends StatefulWidget {
  const POSHChatScreen({super.key});

  @override
  State<POSHChatScreen> createState() => _POSHChatScreenState();
}

class _POSHChatScreenState extends State<POSHChatScreen> {
  final List<Map<String, String>> _messages = [
    {"role": "ai", "text": "Hello! I am your POSH Legal Assistant. How can I help you today regarding workplace safety or women's rights?"}
  ];
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add({"role": "user", "text": userText});
      _isLoading = true;
    });
    _controller.clear();

    final response = await _aiService.getSafetyAdvice(userText);
    setState(() {
      _messages.add({"role": "ai", "text": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POSH AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAI = msg['role'] == 'ai';
                return FadeInUp(
                  child: Align(
                    alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isAI ? AppTheme.cardColor : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomLeft: isAI ? Radius.zero : const Radius.circular(20),
                          bottomRight: isAI ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Text(
                        msg['text']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type your question...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
