
import 'package:flutter/material.dart';
import 'package:lacarta/constant/custom_colors.dart';

class HomePages extends StatelessWidget {
  const HomePages({super.key});

  @override
  Widget build(BuildContext context) {
    final  screenSize = MediaQuery.of(context).size;
    final  screenWidth = screenSize.width; 
    bool isOpen = true;
    return Scaffold(
      body: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [

            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: CustomColorBasic.white1
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          height: 50,
                          decoration: BoxDecoration(
                            color: CustomColorBasic.white2,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  height: 13,
                                  width: 13,
                                  decoration: BoxDecoration(
                                    color: isOpen ? CustomColorBasic.green1 : CustomColorBasic.grey1,
                                    shape: BoxShape.circle
                                  ),
                                ),
                              ),
                              Text(isOpen ? "Abierto" : "Cerrado", )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.1),
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: CustomColorBasic.blue1,
                            shape: BoxShape.circle
                          ),
                          child: 
                          Image.network("https://res.cloudinary.com/dkxiwcgla/image/upload/v1729003658/logo_yyorlv.png")),
                      )
                    ],
                  ),
                  Text("sda"),
                ],
              ),
            )
          ],
        ),
      
      ),
    );
  }
}