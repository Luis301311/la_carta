import 'package:get/instance_manager.dart';
import 'package:lacarta/controller/category_controller.dart';
import 'package:lacarta/controller/product_controller.dart';
import 'package:lacarta/models/category.dart';
import 'package:lacarta/models/extra_group.dart';
import 'package:lacarta/models/extra_option.dart';
import 'package:lacarta/models/producto.dart';

final ProductController productController = Get.put(ProductController());
final CategoryController categoryController = Get.put(CategoryController());


final List<Product> products = [

  Product(
    id: "burger_1",
    name: "Hamburguesa Especial",
    description: "Carne 100% res con queso y tocino",
    basePrice: 18000,
    categoryId: "burgers",
    imageUrl: "https://res.cloudinary.com/dkxiwcgla/image/upload/v1770496861/OIP_ubiul4.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "extras_burger_1",
        title: "Extras",
        isRequired: false,
        minSelection: 0,
        maxSelection: 3,
        options: [
          ExtraOption(
            id: "extra_cheese",
            name: "Queso Extra",
            price: 2000,
          ),
          ExtraOption(
            id: "extra_bacon",
            name: "Tocino",
            price: 3000,
          ),
        ],
      ),
    ],
  ),

  Product(
    id: "burger_2",
    name: "Hamburguesa Doble",
    description: "Doble carne 100% res con queso cheddar",
    basePrice: 22000,
    categoryId: "burgers",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/hamburguesa_doble.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "extras_burger_2",
        title: "Extras",
        isRequired: false,
        minSelection: 0,
        maxSelection: 3,
        options: [
          ExtraOption(
            id: "extra_cheddar",
            name: "Queso Cheddar Extra",
            price: 2500,
          ),
          ExtraOption(
            id: "extra_upgrade_fries",
            name: "Agrandar Papas",
            price: 4000,
          ),
        ],
      ),
    ],
  ),

  Product(
    id: "pizza_1",
    name: "Pizza Pepperoni",
    description: "Pizza artesanal con salsa napolitana y pepperoni",
    basePrice: 28000,
    categoryId: "pizzas",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/pizza_pepperoni.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "extras_pizza_1",
        title: "Personaliza tu pizza",
        isRequired: false,
        minSelection: 0,
        maxSelection: 2,
        options: [
          ExtraOption(
            id: "stuffed_crust",
            name: "Borde Relleno",
            price: 5000,
          ),
          ExtraOption(
            id: "extra_cheese_pizza",
            name: "Extra Queso",
            price: 3000,
          ),
        ],
      ),
    ],
  ),

  Product(
    id: "hotdog_1",
    name: "Perro Especial",
    description: "Salchicha premium con papas, queso y salsas",
    basePrice: 15000,
    categoryId: "combos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/perro_especial.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "extras_hotdog",
        title: "Extras",
        isRequired: false,
        minSelection: 0,
        maxSelection: 2,
        options: [
          ExtraOption(
            id: "bacon_hotdog",
            name: "Tocineta",
            price: 2000,
          ),
          ExtraOption(
            id: "egg_hotdog",
            name: "Huevo",
            price: 1500,
          ),
        ],
      ),
    ],
  ),

  Product(
    id: "combo_1",
    name: "Combo Hamburguesa",
    description: "Hamburguesa sencilla con papas y bebida",
    basePrice: 25000,
    categoryId: "combos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/combo_burger.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "drink_selection",
        title: "Seleccionar Bebida",
        isRequired: true,
        minSelection: 1,
        maxSelection: 1,
        options: [
          ExtraOption(
            id: "coke",
            name: "Coca-Cola",
            price: 0,
          ),
          ExtraOption(
            id: "sprite",
            name: "Sprite",
            price: 0,
          ),
          ExtraOption(
            id: "water",
            name: "Agua",
            price: 0,
          ),
        ],
      ),
      ExtraGroup(
        id: "upgrade_combo",
        title: "Agrandar Combo",
        isRequired: false,
        minSelection: 0,
        maxSelection: 1,
        options: [
          ExtraOption(
            id: "upgrade_large",
            name: "Agrandar Combo",
            price: 5000,
          ),
        ],
      ),
    ],
  ),

  Product(
    id: "dessert_1",
    name: "Cheesecake",
    description: "Cheesecake artesanal con salsa de frutos rojos",
    basePrice: 12000,
    categoryId: "postres",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/cheesecake.webp",
    isAvailable: true,
    extras: [
      ExtraGroup(
        id: "extras_dessert",
        title: "Acompañamientos",
        isRequired: false,
        minSelection: 0,
        maxSelection: 1,
        options: [
          ExtraOption(
            id: "vanilla_icecream",
            name: "Helado de Vainilla",
            price: 3000,
          ),
        ],
      ),
    ],
  ),

];
final List<ProductCategory> categories = [

  ProductCategory(
    id: "burgers",
    name: "Hamburguesas",
    description: "Deliciosas hamburguesas artesanales",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/burgers_category.webp",
    order: 1,
    isActive: true,
    createdAt: null,
  ),

  ProductCategory(
    id: "pizzas",
    name: "Pizzas",
    description: "Pizzas artesanales al horno",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/pizzas_category.webp",
    order: 2,
    isActive: true,
    createdAt: null,
  ),

  ProductCategory(
    id: "combos",
    name: "Combos",
    description: "Combos especiales con bebida y acompañamientos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/combos_category.webp",
    order: 3,
    isActive: true,
    createdAt: null,
  ),

  ProductCategory(
    id: "postres",
    name: "Postres",
    description: "El toque dulce perfecto",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/desserts_category.webp",
    order: 4,
    isActive: true,
    createdAt: null,
  ),

];

void  addProductss() {
  for(ProductCategory item in categories){
    categoryController.createCategory(item); 
  }  

  for (Product item in products){
    productController.createProduct(item);
  }
}