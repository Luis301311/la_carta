import 'package:flutter/material.dart';
import 'package:lacarta/core/widget/responsive.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/company_controller.dart';
import 'package:lacarta/core/widget/mobile/panel_information.dart';

/// Encabezado del menú: estado (abierto/cerrado), logo, nombre e información.
///
/// Antes todo se calculaba con el ancho de la PANTALLA (alto = ancho * 0.9,
/// letra = ancho * 0.04...). En un PC de 1920 px eso daba un encabezado de
/// más de 1700 px de alto. Ahora usa el ancho disponible con límites.
class HeaderMobile extends StatelessWidget {
  const HeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final RestaurantController companyController =
        Get.find<RestaurantController>();

    return Builder(
      builder: (context) {
        final w = Responsive.contentWidth(context);
        final logoSize = (w * 0.4).clamp(110.0, 180.0);
        final nameSize = (w * 0.055).clamp(18.0, 26.0);

        return Container(
          width: double.infinity,
          color: CustomColorBasic.white1,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ESTADO
              Align(
                alignment: Alignment.centerLeft,
                child: _OpenStatus(controller: companyController),
              ),

              const SizedBox(height: 8),

              // LOGO
              Container(
                height: logoSize,
                width: logoSize,
                decoration: const BoxDecoration(
                  color: CustomColorBasic.white1,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Obx(() {
                    final logo = companyController.company.value?.logoUrl ?? "";
                    if (logo.isEmpty) {
                      return Icon(Icons.storefront,
                          size: logoSize * 0.5, color: Colors.grey);
                    }
                    return Image.network(
                      logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.storefront,
                          size: logoSize * 0.5, color: Colors.grey),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // NOMBRE
              Obx(() {
                return Text(
                  companyController.company.value?.name ?? "MI EMPRESA",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: nameSize),
                );
              }),

              const SizedBox(height: 12),

              // INFORMACION
              GestureDetector(
                onTap: () => _showInformation(context, companyController),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
                  decoration: BoxDecoration(
                    color: CustomColorBasic.white2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomColorBasic.grey1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Text("Información"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInformation(
      BuildContext context, RestaurantController companyController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // En PC la hoja no se estira a todo el ancho
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Obx(() {
            final company = companyController.company.value;
            if (company == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return PanelInformation(company: company);
          }),
        );
      },
    );
  }
}

/// Píldora "Abierto / Cerrado". Se ajusta al texto en lugar de tener
/// un ancho fijo (antes se cortaba en celulares pequeños).
class _OpenStatus extends StatelessWidget {
  final RestaurantController controller;
  const _OpenStatus({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final open = controller.isOpen.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CustomColorBasic.white2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CustomColorBasic.grey2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: open ? CustomColorBasic.green1 : CustomColorBasic.grey1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              open ? "Abierto" : "Cerrado",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    });
  }
}
