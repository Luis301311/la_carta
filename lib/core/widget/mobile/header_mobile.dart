import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/widget/mobile/panel_information.dart';
import 'package:get/get.dart';
class HeaderMobile extends StatelessWidget {
  const HeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final RestaurantController companyController = Get.find<RestaurantController>();
    final screenSize =MediaQuery.of(context).size; 
    final screenWidth = screenSize.width; 
    return Container(
      width: double.infinity,
      height: screenWidth * 0.9,
      decoration: BoxDecoration(
        color: CustomColorBasic.white1
      ),
      child: Stack(
        children: [
          //ESTADO
          Positioned(
            top: screenWidth * 0.5,
            left: 5,
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.003),
              height: screenWidth * 0.09,
              width: screenWidth * 0.22,
              decoration: BoxDecoration(
                color: CustomColorBasic.white2,
                borderRadius: BorderRadius.circular(10)
              ),
              child:
              Obx(
                () {
                  return Row(
                    children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                              height: screenWidth * 0.1,
                              width: screenWidth * 0.02,
                              decoration: BoxDecoration(
                                color: companyController.isOpen.value ? CustomColorBasic.green1 : CustomColorBasic.grey1,
                                shape: BoxShape.circle
                              ),
                          ),
                        ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(companyController.isOpen.value ? "Abierto" : "Cerrado", style: TextStyle( fontSize: screenWidth * 0.033, fontWeight: FontWeight.w400), )
                    ],
                  );
                }
              )
            ),
          ),


          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //lOGO
                Container(
                  height: 250,
                  width: 240,
                  decoration: BoxDecoration(
                    color: CustomColorBasic.white1,
                    shape: BoxShape.circle
                  ),
                  child: 
                    ClipOval(
                      child: 
                      Obx((){
                        final logo = companyController.company.value?.logoUrl ?? "";
                        if (logo.isEmpty) {
                          return const Icon(Icons.storefront, size: 90, color: Colors.grey);
                        }
                        return Image.network(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.storefront, size: 90, color: Colors.grey),
                        );
                      })
                    )
                ),
                SizedBox(height: 10,),

                //NOMBRE
                Obx((){
                  return Text(companyController.company.value?.name ?? "MI EMPRESA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),);
                }), 
                SizedBox(height: 10,),

                //INFORMACION
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return FractionallySizedBox(
                          heightFactor: 0.8,
                          child: 
                          Obx((){
                            final company = companyController.company.value;

                            if (company == null) {
                              return const CircularProgressIndicator();
                            }
                            return PanelInformation(company:  company, );
                          
                          })
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                    decoration: BoxDecoration(
                      color: CustomColorBasic.white2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CustomColorBasic.grey1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text("Información"),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}