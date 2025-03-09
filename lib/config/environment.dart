enum Environment {
  development,
  production,
}

class AppConfig {
  // Defina o ambiente atual aqui
  static const Environment currentEnvironment = Environment.production;

  // URLs da API para cada ambiente
  static const Map<Environment, String> _apiBaseUrls = {
    // Use o IP da sua máquina na rede local em vez de localhost
    Environment.development: 'http://192.168.18.10:3000/api',
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
