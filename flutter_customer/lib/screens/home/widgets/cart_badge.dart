import 'package:flutter/material.dart';

class CartBadge extends StatelessWidget {

final int count;

const CartBadge({

super.key,

required this.count,

});

@override
Widget build(BuildContext context){

return Stack(

children:[

const Icon(

Icons.shopping_bag_outlined,

),

if(count>0)

Positioned(

right:0,

top:0,

child: Container(

padding:const EdgeInsets.all(3),

decoration:const BoxDecoration(

color:Colors.red,

shape:BoxShape.circle,

),

child: Text(

count.toString(),

style:const TextStyle(

fontSize:10,

color:Colors.white,

),

),

),

),

],

);

}

}