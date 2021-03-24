import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop/models/http_exceptions.dart';

import './product.dart';

class Products with ChangeNotifier {
  List<Product> _lists = [
    // F
  ];

  // var _showFavoritesOnly = false;

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  final String authToken;
  final String userId;
  Products(this.authToken, this.userId, this._lists);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _lists.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._lists];
  }

  List<Product> get showFavorite {
    return _lists.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _lists.firstWhere((prod) => prod.id == id);
  }

//'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json?auth=$token';

  Future<void> fetchAndSetProduct([bool filterUser = false]) async {
    var filtereString =
        filterUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';

    var url =
        'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filtereString';

    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(url);
      final favoriteExtractedData = json.decode(favoriteResponse.body);

      final List<Product> loadedProduct = [];

      extractedData.forEach((prodId, prodData) {
        loadedProduct.add(
          Product(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            imageUrl: prodData['imageUrl'],
            price: prodData['price'],
            isFavorite: favoriteExtractedData == null
                ? false
                : favoriteExtractedData[prodId] ?? false,
          ),
        );
      });
      _lists = loadedProduct;
      notifyListeners();

      print(response);
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': userId,
          }));
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
      );
      _lists.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error.toString());
      print('From Products catch error');

      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _lists.indexWhere((prod) => prod.id == id);

    if (prodIndex >= 0) {
      final url =
          'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl,
          }));
      _lists[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('....');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://my-shop-flutter-87dd9-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';

    final productIndex = _lists.indexWhere((prod) => prod.id == id);
    var existingProduct = _lists[productIndex];

    _lists.removeAt(productIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _lists.insert(productIndex, existingProduct);
      notifyListeners();
      throw HttpExceptions('Couldn\'t delete this product!');
    }

    existingProduct = null;
  }
}
