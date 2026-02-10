import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';
import 'package:lacarta/widget/panel_information.dart';

class HeaderMobile extends StatelessWidget {
  const HeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize =MediaQuery.of(context).size; 
    final screenWidth = screenSize.width; 
    bool isOpen = false; 
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
              child: Row(
                children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                          height: screenWidth * 0.1,
                          width: screenWidth * 0.02,
                          decoration: BoxDecoration(
                            color: isOpen ? CustomColorBasic.green1 : CustomColorBasic.grey1,
                            shape: BoxShape.circle
                          ),
                      ),
                    ),
                  SizedBox(width: screenWidth * 0.03),
                  Text(isOpen ? "Abierto" : "Cerrado", style: TextStyle( fontSize: screenWidth * 0.033, fontWeight: FontWeight.w400), )
                ],
              ),
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
                      child: Image.network(
                        "https://res.cloudinary.com/dkxiwcgla/image/upload/v1729003658/logo_yyorlv.png", 
                        fit: BoxFit.contain,
                    ))
                ),
                SizedBox(height: 10,),

                //NOMBRE
                Text("NOMBRE DEL RESTAURANTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),),
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
                          child: PanelInformation());
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