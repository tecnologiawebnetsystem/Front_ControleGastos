enum Environment {
  development,
  production,
}

class AppConfig {
  // Defina o ambiente atual aqui
  static const Environment currentEnvironment = Environment.development;

  // URLs da API para cada ambiente
  static const Map<Environment, String> _apiBaseUrls = {
    Environment.development: 'http://localhost:3000/api',
    Environment.production: 'https://controle-gastos-api.onrender.com/api',
  };

  // Método para obter a URL base da API com base no ambiente atual
  static String get apiBaseUrl => _apiBaseUrls[currentEnvironment]!;

  // Método para verificar se estamos em ambiente de desenvolvimento
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;

  // Método para verificar se estamos em ambiente de produção
  static bool get isProduction => currentEnvironment == Environment.production;
}
