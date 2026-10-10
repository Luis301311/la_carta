import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';
import 'package:lacarta/core/services/api_client.dart';
import 'package:lacarta/core/widget/responsive.dart';

/// Super admin: escoger qué empresa administrar.
/// (El panel completo del super admin —crear, suspender, etc.— viene después.)
class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final AuthController _auth = AuthController.to;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _auth.listCompanies();
  }

  void _reload() => setState(() => _future = _auth.listCompanies());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColorBasic.white3,
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.logout(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final msg = snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'No se pudieron cargar las empresas';
              return Center(child: Text(msg));
            }
            final companies = snap.data ?? [];
            if (companies.isEmpty) {
              return const Center(child: Text('Aún no hay empresas'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = companies[i];
                final active = c['isActive'] == true;
                final stats = (c['stats'] as Map?) ?? {};
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: active
                          ? CustomColorBasic.yellow2
                          : CustomColorBasic.grey2,
                      child: const Icon(Icons.storefront,
                          color: CustomColorBasic.black1),
                    ),
                    title: Text(
                      c['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '/${c['slug']} · ${stats['products'] ?? 0} productos · '
                      '${stats['orders'] ?? 0} pedidos'
                      '${active ? '' : ' · SUSPENDIDA'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _auth.selectCompany(
                        c['id'] as String, (c['name'] ?? '') as String),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
