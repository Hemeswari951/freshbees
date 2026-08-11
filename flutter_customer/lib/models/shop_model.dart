class ShopModel {
  final int id;
  final String shopName;
  final String image;
  final double rating;
  final double distance;

  const ShopModel({
    required this.id,
    required this.shopName,
    required this.image,
    required this.rating,
    required this.distance,
  });

  
}
final shops = [

ShopModel(
id:1,
shopName:"Lakshmi Boutique",
image:"",
rating:4.8,
distance:1.2,
),

ShopModel(
id:2,
shopName:"Fashion Hub",
image:"",
rating:4.6,
distance:2.4,
),

ShopModel(
id:3,
shopName:"Silk Palace",
image:"",
rating:4.9,
distance:0.9,
),

];