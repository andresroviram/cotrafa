/// Abstract interface for environment configuration.
/// Implemented by the app-level [Env] class (generated with envied).
/// This allows [core] to depend on env values without depending on the app.
abstract class IEnvConfig {
  String get baseUrl;
  String? get apiKey;
}
