import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RestaurantController>();
    
    return Obx(() {
      final company = controller.company.value;

      if (company == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        children: [

          //  MAPA (solo si el restaurante tiene coordenadas)
          if (company.location.hasCoordinates)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    company.location.lat!,
                    company.location.lng!,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          company.location.lat!,
                          company.location.lng!,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // INFO EMPRESA
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: company.logoUrl.isNotEmpty
                    ? NetworkImage(company.logoUrl)
                    : null,
                child: company.logoUrl.isEmpty
                    ? const Icon(Icons.storefront)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          //  DIRECCIÓN
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  company.location.address,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // TELÉFONO
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Text(company.phone),
            ],
          ),

          const SizedBox(height: 15),

          // BOTÓN ABRIR EN MAPS
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Con coordenadas abre el punto exacto; si no, busca la dirección
                final query = company.location.hasCoordinates
                    ? "${company.location.lat},${company.location.lng}"
                    : Uri.encodeComponent(company.location.address);
                final url =
                    "https://www.google.com/maps/search/?api=1&query=$query";
                launchUrl(Uri.parse(url));
              },
              icon: const Icon(Icons.map_sharp, color: CustomColorBasic.white1,),
              label: const Text("Ver Ubicacion" , style: TextStyle(color: CustomColorBasic.white1),),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColorBasic.green1,
                
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}