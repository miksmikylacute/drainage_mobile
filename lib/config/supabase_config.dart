class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rttraruhalqrljnkaprj.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0dHJhcnVoYWxxcmxqbmthcHJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2MDIwMTYsImV4cCI6MjA5OTE3ODAxNn0.Khfqx4CO3vFv3SSlSQ0KOk1sCMIvX3gCCjbVKGuyJyw',
  );

  static const reportPhotosBucket = String.fromEnvironment(
    'SUPABASE_REPORT_PHOTOS_BUCKET',
    defaultValue: 'report-photos',
  );
}
