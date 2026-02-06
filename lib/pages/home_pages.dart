

import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';

class HomePages extends StatelessWidget {
  const HomePages({super.key});

  @override
  Widget build(BuildContext context) {
    final  screenSize = MediaQuery.of(context).size;
    final  screenWidth = screenSize.width; 
    bool isOpen = false;
    return Scaffold(
      body:  ListView(
          scrollDirection: Axis.vertical,
          children: [
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: CustomColorBasic.white1
              ),
              child: Stack(
                children: [
                  
                  //ESTADO
                  Positioned(
                    top: 150,
                    left: 20,
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
                                  child: _panelInformacion());
                              },
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            )
          ],
        ),
      
    );
  }
}











Widget _panelInformacion() {
  return Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        SizedBox(height: 20),

        Text(
          "Información del restaurante",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 15),

        Row(
          children: [
            Icon(Icons.access_time),
            SizedBox(width: 10),
            Text("Horario: 8:00 AM - 10:00 PM"),
          ],
        ),

        SizedBox(height: 10),

        Row(
          children: [
            Icon(Icons.location_on),
            SizedBox(width: 10),
            Text("Dirección: Calle 123 #45-67"),
          ],
        ),

        SizedBox(height: 10),

        Row(
          children: [
            Icon(Icons.phone),
            SizedBox(width: 10),
            Text("Teléfono: +57 300 000 0000"),
          ],
        ),

        SizedBox(height: 30),
      ],
    ),
  );
}
