import 'package:get/instance_manager.dart';
import 'package:lacarta/controller/category_controller.dart';
import 'package:lacarta/controller/product_controller.dart';
import 'package:lacarta/models/category.dart';
import 'package:lacarta/models/extra.dart';
import 'package:lacarta/models/producto.dart';

final ProductController productController = Get.put(ProductController());
final CategoryController categoryController = Get.put(CategoryController());
final List<Product> products = [

  Product(
    name: "Hamburguesa Especial",
    description: "Carne 100% res con queso y tocino",
    basePrice: 18000,
    categoryId: "burgers",
    imageUrl: "https://res.cloudinary.com/dkxiwcgla/image/upload/v1770496861/OIP_ubiul4.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Queso Extra",
        price: 2000,
        isRequired: false,
        isActive: true,
      ),
      Extra(
        name: "Tocino",
        price: 3000,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

  Product(
    name: "Hamburguesa Doble",
    description: "Doble carne 100% res con queso cheddar",
    basePrice: 22000,
    categoryId: "burgers",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/hamburguesa_doble.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Queso Cheddar Extra",
        price: 2500,
        isRequired: false,
        isActive: true,
      ),
      Extra(
        name: "Agrandar Papas",
        price: 4000,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

  Product(
    name: "Pizza Pepperoni",
    description: "Pizza artesanal con salsa napolitana y pepperoni",
    basePrice: 28000,
    categoryId: "pizzas",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/pizza_pepperoni.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Borde Relleno",
        price: 5000,
        isRequired: false,
        isActive: true,
      ),
      Extra(
        name: "Extra Queso",
        price: 3000,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

  Product(
    name: "Perro Especial",
    description: "Salchicha premium con papas, queso y salsas",
    basePrice: 15000,
    categoryId: "combos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/perro_especial.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Tocineta",
        price: 2000,
        isRequired: false,
        isActive: true,
      ),
      Extra(
        name: "Huevo",
        price: 1500,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

  Product(
    name: "Combo Hamburguesa",
    description: "Hamburguesa sencilla con papas y bebida",
    basePrice: 25000,
    categoryId: "combos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/combo_burger.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Seleccionar Bebida",
        price: 0,
        isRequired: true,
        isActive: true,
      ),
      Extra(
        name: "Agrandar Combo",
        price: 5000,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

  Product(
    name: "Cheesecake",
    description: "Cheesecake artesanal con salsa de frutos rojos",
    basePrice: 12000,
    categoryId: "combos",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/cheesecake.webp",
    isAvailable: true,
    extras: [
      Extra(
        name: "Helado de Vainilla",
        price: 3000,
        isRequired: false,
        isActive: true,
      ),
    ],
  ),

];
final List<ProductCategory> categories = [

  ProductCategory(
    id: "burgers",
    name: "Hamburguesas",
    description: "Jugosas hamburguesas artesanales",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/burgers.webp",
    order: 1,
  ),

  ProductCategory(
    id: "pizzas",
    name: "Pizzas",
    description: "Pizzas artesanales al horno",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/pizzas.webp",
    order: 2,
  ),

  ProductCategory(
    id: "combos",
    name: "Combos",
    description: "Combos especiales con bebida y papas",
    imageUrl: "https://res.cloudinary.com/demo/image/upload/combos.webp",
    order: 3,
  ),

];

void  addProducts() {
  for(ProductCategory item in categories){
    categoryController.createCategory(item); 
  }  

  for (Product item in products){
    productController.createProduct(item);
  }
}