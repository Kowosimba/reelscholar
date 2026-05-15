// lib/screens/hackathons/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class HackLeaderboardScreen extends StatefulWidget {
  final String hackId;
  const HackLeaderboardScreen({super.key, required this.hackId});

  @override
  State<HackLeaderboardScreen> createState() =>
      _HackLeaderboardScreenState();
}

class _HackLeaderboardScreenState extends State<HackLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<HackathonProvider>();
      p.loadLeaderboard(widget.hackId);
      p.loadVoteStatus(widget.hackId);
    });
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
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<HackathonProvider>(
        builder: (_, p, _) {
          if (p.lbLoading && p.leaderboard.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary));
          }

          final vs = p.voteStatus;
          final canVote = vs?.canVote == true;
          final hasVoted = vs?.hasVoted == true;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: p.leaderboard.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                // Vote status banner
                if (vs == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasVoted
                        ? AppColors.primarySubtle
                        : canVote
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        hasVoted
                            ? '✅'
                            : canVote
                                ? '🗳️'
                                : '🔒',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasVoted
                              ? 'You\'ve cast your vote!'
                              : canVote
                                  ? 'Voting is open — tap a team to vote'
                                  : vs.reason,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasVoted
                                ? AppColors.primary
                                : canVote
                                    ? const Color(0xFF92400E)
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final entry = p.leaderboard[i - 1];
              final rank = i;
              final isVotedFor = vs?.votedFor == entry.teamId;

              return _LeaderboardCard(
                entry: entry,
                rank: rank,
                canVote: canVote && !hasVoted,
                isVotedFor: isVotedFor,
                onVote: () async {
                  try {
                    await p.castVote(widget.hackId, entry.teamId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final HackLeaderboardEntry entry;
  final int rank;
  final bool canVote;
  final bool isVotedFor;
  final VoidCallback onVote;

  const _LeaderboardCard({
    required this.entry,
    required this.rank,
    required this.canVote,
    required this.isVotedFor,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVotedFor
            ? AppColors.primarySubtle
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVotedFor ? AppColors.primary : AppColors.border,
          width: isVotedFor ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: medal != null
                    ? Text(medal,
                        style: const TextStyle(fontSize: 20))
                    : Text(
                        '#$rank',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.teamName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.projectName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (entry.finalScore != null)
                    Text(
                      entry.finalScore!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_rounded,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.peerVotes}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (canVote && !isVotedFor) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onVote,
                icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                label: const Text(
                  'Vote for this team',
                  style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          if (isVotedFor)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Your vote',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
