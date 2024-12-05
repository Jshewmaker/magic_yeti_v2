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
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 50),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(l10n.searchButtonText),
                  onPressed: () => context.read<PlayerCustomizationBloc>().add(
                        CardListRequested(
                          cardName: textController.text,
                        ),
                      ),
                ),
              ),
            ),
            controller: textController,
          ),
          BlocBuilder<PlayerCustomizationBloc, PlayerCustomizationState>(
            builder: (context, state) {
              if (state.status == PlayerCustomizationStatus.success) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: state.cardList?.data.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () =>
                            context.read<PlayerCustomizationBloc>().add(
                                  UpdatePlayerPicture(
                                    imageUrl: state.cardList?.data[index]
                                            .imageUris?.artCrop ??
                                        '',
                                  ),
                                ),
                        child: Card(
                          color: Colors.black.withOpacity(0.9),
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
                return Column(
                  children: [
                    const SizedBox(
                      height: 40,
                    ),
                    Text(
                      'Search your commander.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 20,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
