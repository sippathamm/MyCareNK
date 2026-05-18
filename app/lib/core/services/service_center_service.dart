import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_center_model.dart';

class ServiceCenterService {
  static Future<List<ServiceCenterModel>> fetchActive() async {
    final data = await Supabase.instance.client.rpc('get_service_centers');
    return (data as List<dynamic>)
        .map((e) => ServiceCenterModel.fromMap(e as Map<String, dynamic>))
        .where((c) => c.isActive)
        .toList();
  }
}
