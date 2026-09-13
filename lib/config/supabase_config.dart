class SupabaseConfig {
  // Set to true on develop (test branch), false on main (production branch)
  static const bool isTestEnvironment = true;

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jpmodbgmkkrtavuzmpii.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwbW9kYmdta2tydGF2dXptcGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkzMTM5NDgsImV4cCI6MjEwNDg4OTk0OH0.YPh7bLDA9Sx9DkQifJ7p_qSljjiD_YQZyYMu95CeFG4',
  );

  static const reportPhotosBucket = String.fromEnvironment(
    'SUPABASE_REPORT_PHOTOS_BUCKET',
    defaultValue: 'report-photos',
  );
}
