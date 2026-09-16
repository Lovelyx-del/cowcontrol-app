import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente unico de Supabase. Todos los demas servicios pasan por este getter
/// en vez de llamar a Supabase.instance.client directamente en cada archivo.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
}
