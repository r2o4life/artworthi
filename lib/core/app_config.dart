/// Central configuration flags for backend readiness.
///
/// This project ships with a deterministic mock repository by default.
/// When you later connect Firebase or Supabase via Dreamflow panels,
/// you can switch this to true and implement the external repository.
class AppConfig {
  static const bool useExternalBackend = false;
}
