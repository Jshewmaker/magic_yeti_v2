import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

class SelectCommanderWidget extends StatefulWidget {
  const SelectCommanderWidget({
    required this.player,
    required this.scrollController,
    super.key,
  });
  final Player player;
  final ScrollController scrollController;

  @override
  State<SelectCommanderWidget> createState() => _SelectCommanderWidgetState();
}

class _SelectCommanderWidgetState extends State<SelectCommanderWidget> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for your commander',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                controller: textController,
                autocorrect: false,
                onTap: () {
                  widget.scrollController.animateTo(
                    450,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: Text(l10n.searchButtonText),
              onPressed: () => context.read<PlayerCustomizationBloc>().add(
                    CardListRequested(
                      cardName: textController.text,
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
          builder: (context, state) {
            if (state.status == PlayerCustomizationStatus.loading) {
              return const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              );
            }
            if (state.status == PlayerCustomizationStatus.success) {
              return SizedBox(
                height: 400,
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.xs,
                  ),
                  itemCount: state.cardList?.data.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => context.read<PlayerCustomizationBloc>().add(
                            UpdatePlayerCommander(
                              commander: Commander(
                                name: state.cardList?.data[index].name ?? '',
                                artist:
                                    state.cardList?.data[index].artist ?? '',
                                colors:
                                    state.cardList?.data[index].colors ?? [],
                                cardType:
                                    state.cardList?.data[index].typeLine ?? '',
                                imageUrl: state.cardList?.data[index].imageUris
                                        ?.artCrop ??
                                    '',
                                manaCost:
                                    state.cardList?.data[index].manaCost ?? '',
                                oracleText:
                                    state.cardList?.data[index].oracleText ??
                                        '',
                                power: state.cardList?.data[index].power,
                                toughness:
                                    state.cardList?.data[index].toughness,
                              ),
                            ),
                          ),
                      child: Card(
                        elevation: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                state.cardList?.data[index].imageUris?.normal ??
                                    '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(
                                  color: AppColors.neutral60,
                                  child: Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Text(
                                state.cardList?.data[index].artist ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.white,
                                    ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox(
              height: 400,
            );
          },
        ),
      ],
    );
  }
}
