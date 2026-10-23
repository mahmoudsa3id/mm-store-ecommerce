import 'package:supabase_flutter/supabase_flutter.dart';
class AdminDashboardRepository{AdminDashboardRepository(this.client);final SupabaseClient client;Future<Map<String,dynamic>>get()=>client.rpc('get_admin_dashboard').then((v)=>Map<String,dynamic>.from(v as Map));}
