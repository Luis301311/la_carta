import 'package:flutter/material.dart';
import 'package:lacarta/core/models/company/company.dart';
class PanelInformation extends StatelessWidget {
  final Company company; 
  const PanelInformation({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    // Con scroll: en pantallas bajas los 7 días del horario no cabían
    return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
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
          "Información adicional",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 15),

        Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[700]),
            SizedBox(width: 8),
            Text(
              "Horarios",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        ...company.businessHours.map((item) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.closed
                      ? "Cerrado"
                      : "${item.openTime} - ${item.closeTime}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Icon(Icons.location_on),
            SizedBox(width: 10),
            Expanded(child: Text("Dirección: ${company.location.address}")),
          ],
        ),

        SizedBox(height: 10),

        Row(
          children: [
            Icon(Icons.phone),
            SizedBox(width: 10),
            Text("Teléfono: ${company.phone}"),
          ],
        ),

        SizedBox(height: 30),
      ],
    ),
  );
 }
}