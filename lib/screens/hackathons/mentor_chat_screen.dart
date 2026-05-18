// lib/screens/hackathons/mentor_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class MentorChatScreen extends StatefulWidget {
  final String hackId;
  final String teamId;

  const MentorChatScreen(
      {super.key, required this.hackId, required this.teamId});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<HackathonProvider>()
          .loadMentorChat(widget.hackId, widget.teamId);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      await context.read<HackathonProvider>().sendMentorMessage(
            widget.hackId,
            widget.teamId,
            text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mentor Chat',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Private channel with your mentor',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<HackathonProvider>(
              builder: (_, p, _) {
                if (p.mentorChatLoading && p.mentorMessages.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                if (p.mentorMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Start a conversation with your mentor',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: p.mentorMessages.length,
                  itemBuilder: (_, i) =>
                      _MentorMsgBubble(msg: p.mentorMessages[i]),
                );
              },
            ),
          ),

          // Input
          SafeArea(
            top: false,
            child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message your mentor…',
                        hintStyle: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _sending
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorMsgBubble extends StatelessWidget {
  final MentorMessage msg;
  const _MentorMsgBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd compare msg.senderId with current user ID
    // For now, we'll assume mentor messages have a specific sender name or ID pattern if possible
    // but without AuthProvider access here easily, we'll just check if it's NOT the mentor
    // Actually, let's just make it look consistent.
    final isMentor = msg.senderName.toLowerCase().contains('mentor'); 
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMentor ? 0 : 48,
        right: isMentor ? 48 : 0,
      ),
      child: Column(
        crossAxisAlignment: isMentor
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            msg.senderName,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isMentor
                  ? Colors.white
                  : AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMentor ? 4 : 14),
                bottomRight: Radius.circular(isMentor ? 14 : 4),
              ),
              border: isMentor
                  ? Border.all(color: AppColors.border)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              msg.body,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: isMentor ? AppColors.textPrimary : Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
