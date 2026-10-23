import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/home_entity.dart';

class PromoBanner extends StatelessWidget {
	const PromoBanner({
		super.key,
		required this.data,
		required this.onButtonTap,
	});

	final BannerEntity data;
	final VoidCallback onButtonTap;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(
				horizontal: AppConstants.horizontalPadding,
				vertical: 20,
			),
			child: ClipRRect(
				borderRadius: BorderRadius.circular(18),
				child: SizedBox(
					height: 170,
					child: Stack(
						fit: StackFit.expand,
						children: [
							CachedNetworkImage(
								imageUrl: data.image,
								fit: BoxFit.cover,
								errorWidget: (_, _, _) =>
										const ColoredBox(color: AppConstants.black),
							),
							DecoratedBox(
								decoration: BoxDecoration(
									gradient: LinearGradient(
										begin: Alignment.centerLeft,
										end: Alignment.centerRight,
										colors: [
											Colors.black.withValues(alpha: .88),
											Colors.transparent,
										],
									),
								),
							),
							PositionedDirectional(
								start: 18,
								top: 0,
								bottom: 0,
								child: SizedBox(
									width: 225,
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text(
												'MM STORE',
												style: TextStyle(
													color: AppConstants.gold,
													letterSpacing: 2,
													fontSize: 10,
													fontWeight: FontWeight.w800,
												),
											),
											const SizedBox(height: 5),
											Text(
												data.title,
												maxLines: 2,
												overflow: TextOverflow.ellipsis,
												style: const TextStyle(
													color: Colors.white,
													fontSize: 20,
													height: 1.25,
													fontWeight: FontWeight.w900,
												),
											),
											const SizedBox(height: 9),
											FilledButton(
												onPressed: onButtonTap,
												style: FilledButton.styleFrom(
													backgroundColor: AppConstants.gold,
													foregroundColor: AppConstants.black,
													minimumSize: const Size(0, 38),
													padding: const EdgeInsets.symmetric(
														horizontal: 13,
														vertical: 6,
													),
												),
												child: Text(
													data.button,
													style: const TextStyle(
														fontSize: 11,
														fontWeight: FontWeight.w800,
													),
												),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}
}
