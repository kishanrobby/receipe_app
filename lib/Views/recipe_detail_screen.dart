import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_complete_app/Provider/favorite_provider.dart';
import 'package:flutter_complete_app/Provider/quantity.dart';
import 'package:flutter_complete_app/Utils/constants.dart';
import 'package:flutter_complete_app/Widget/my_icon_button.dart';
import 'package:flutter_complete_app/Widget/quantity_increment_decrement.dart';
import 'package:flutter_complete_app/Views/rating_popup.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;
  const RecipeDetailScreen({super.key, required this.documentSnapshot});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _hasRated = false;
  bool _isCheckingRating = true; // Add this to track loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      List<double> baseAmounts = widget.documentSnapshot['ingredientsAmount']
          .map<double>((amount) => double.parse(amount.toString()))
          .toList();
      Provider.of<QuantityProvider>(context, listen: false)
          .setBaseIngredientAmounts(baseAmounts);

      // Check if user has already rated this recipe
      _checkUserRating();
    });
  }

// Add this method to check if the user has already rated this recipe
  Future<void> _checkUserRating() async {
    setState(() {
      _isCheckingRating = true;
    });

    try {
      // Get current user email from active session
      final QuerySnapshot sessionQuery = await FirebaseFirestore.instance
          .collection('sessions')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isNotEmpty) {
        final String userEmail = sessionQuery.docs.first['email'];

        // Check if this user has already rated this recipe
        final QuerySnapshot ratingQuery = await FirebaseFirestore.instance
            .collection('userRatings')
            .where('userEmail', isEqualTo: userEmail)
            .where('recipeId', isEqualTo: widget.documentSnapshot.id)
            .limit(1)
            .get();

        if (ratingQuery.docs.isNotEmpty) {
          // User has already rated this recipe
          setState(() {
            _hasRated = true;
          });
        }
      }
    } catch (e) {
      print('Error checking user rating: $e');
    } finally {
      setState(() {
        _isCheckingRating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);
    final quantityProvider = Provider.of<QuantityProvider>(context);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: startCookingAndFavoriteButton(provider),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 2.1,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        widget.documentSnapshot['image'],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      MyIconButton(
                          icon: Icons.arrow_back_ios_new,
                          pressed: () {
                            Navigator.pop(context);
                          }),
                      const Spacer(),
                      MyIconButton(
                        icon: Iconsax.notification,
                        pressed: () {},
                      )
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.width,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.documentSnapshot['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.flash_1,
                        size: 20,
                        color: Colors.grey,
                      ),
                      Text(
                        "${widget.documentSnapshot['cal']} Cal",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Text(
                        " · ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(
                        Iconsax.clock,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.documentSnapshot['time']} Min",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.documentSnapshot['rate'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text("/5"),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.documentSnapshot['reviews'.toString()]} Reviews",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          _hasRated ? Colors.grey : kprimaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isCheckingRating || _hasRated
                            ? null
                            : () {
                          showDialog(
                            context: context,
                            builder: (context) => RatingDialog(
                              recipeTitle:
                              widget.documentSnapshot['name'],
                              onRatingSubmitted: (rating) async {
                                // Get current user email
                                final QuerySnapshot sessionQuery = await FirebaseFirestore.instance
                                    .collection('sessions')
                                    .where('isActive', isEqualTo: true)
                                    .limit(1)
                                    .get();

                                if (sessionQuery.docs.isEmpty) return;

                                final String userEmail = sessionQuery.docs.first['email'];

                                final currentRate = double.parse(
                                    widget.documentSnapshot['rate']
                                        .toString());
                                final currentReviews = int.parse(
                                    widget.documentSnapshot['reviews']
                                        .toString());

                                final newReviews = currentReviews + 1;
                                final newRate =
                                    ((currentRate * currentReviews) +
                                        rating) /
                                        newReviews;

                                // Update recipe rating
                                await FirebaseFirestore.instance
                                    .collection('recipes')
                                    .doc(widget.documentSnapshot.id)
                                    .update({
                                  'rate': newRate.toStringAsFixed(1),
                                  'reviews': newReviews.toString(),
                                });

                                // Store user rating
                                await FirebaseFirestore.instance
                                    .collection('userRatings')
                                    .add({
                                  'userEmail': userEmail,
                                  'recipeId': widget.documentSnapshot.id,
                                  'rating': rating,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                setState(() {
                                  _hasRated = true;
                                });
                              },
                            ),
                          );
                        },
                        child: _isCheckingRating
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _hasRated ? "Already rated" : "Rate this recipe",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Infredients",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "How many servings?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      QuantityIncrementDecrement(
                        currentNumber: quantityProvider.currentNumber,
                        onAdd: () => quantityProvider.increaseQuantity(),
                        onRemov: () => quantityProvider.decreaseQuanity(),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: widget
                                .documentSnapshot['ingredientsImage']
                                .map<Widget>(
                                  (imageUrl) => Container(
                                height: 60,
                                width: 60,
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      imageUrl,
                                    ),
                                  ),
                                ),
                              ),
                            )
                                .toList(),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget
                                .documentSnapshot['ingredientsName']
                                .map<Widget>((ingredient) => Container(
                              height: 60,
                              margin: const EdgeInsets.only(bottom: 15),
                              child: Center(
                                child: Text(
                                  ingredient,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: quantityProvider.updateIngredientAmounts
                                .map<Widget>((amount) => Container(
                              height: 60,
                              margin: const EdgeInsets.only(bottom: 15),
                              child: Center(
                                child: Text(
                                  "${amount}gm",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton startCookingAndFavoriteButton(
      FavoriteProvider provider) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () {},
      label: Row(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
              padding:
              const EdgeInsets.symmetric(horizontal: 100, vertical: 13),
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            child: const Text(
              "Start Cooking",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            style: IconButton.styleFrom(
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
            onPressed: () {
              provider.toggleFavorite(widget.documentSnapshot);
            },
            icon: Icon(
              provider.isExist(widget.documentSnapshot)
                  ? Iconsax.heart5
                  : Iconsax.heart,
              color: provider.isExist(widget.documentSnapshot)
                  ? Colors.red
                  : Colors.black,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
