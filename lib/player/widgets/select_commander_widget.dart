import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magic_yeti/l10n/l10n.dart';
import 'package:magic_yeti/player/view/bloc/player_customization_bloc.dart';
import 'package:player_repository/player_repository.dart';

class SelectCommanderWidget extends StatefulWidget {
  const SelectCommanderWidget({required this.player, super.key});
  final Player player;
  @override
  State<SelectCommanderWidget> createState() => _SelectCommanderWidgetState();
}

class _SelectCommanderWidgetState extends State<SelectCommanderWidget> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Expanded(
      child: Column(
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
          BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
            builder: (context, state) {
              if (state.status == PlayerCustomizationStatus.success) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: state.cardList?.data.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => context
                            .read<PlayerCustomizationBloc>()
                            .add(
                              UpdatePlayerCommander(
                                commander: Commander(
                                  name: state.cardList?.data[index].name ?? '',
                                  artist:
                                      state.cardList?.data[index].artist ?? '',
                                  colors:
                                      state.cardList?.data[index].colors ?? [],
                                  cardType:
                                      state.cardList?.data[index].typeLine ??
                                          '',
                                  imageUrl: state.cardList?.data[index]
                                          .imageUris?.artCrop ??
                                      '',
                                  manaCost:
                                      state.cardList?.data[index].manaCost ??
                                          '',
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
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Image.network(
                                  state.cardList?.data[index].imageUris
                                          ?.borderCrop ??
                                      '',
                                  scale: 4,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(),
                                ),
                                const SizedBox(
                                  width: AppSpacing.md,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.cardList?.data[index].name ?? '',
                                      style: const TextStyle(fontSize: 36)
                                          .copyWith(color: AppColors.white),
                                    ),
                                    Text(
                                      state.cardList?.data[index].setName ?? '',
                                      style: const TextStyle(fontSize: 24)
                                          .copyWith(color: AppColors.white),
                                    ),
                                    Text(
                                      state.cardList?.data[index].artist ?? '',
                                      style: const TextStyle(fontSize: 24)
                                          .copyWith(color: AppColors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              if (state.status == PlayerCustomizationStatus.loading) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
