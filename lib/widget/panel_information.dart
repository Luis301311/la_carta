import 'package:flutter/material.dart';
class PanelInformation extends StatelessWidget {
  const PanelInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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

        /* for(int i = 0; i< 2 ; i++) */
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
}