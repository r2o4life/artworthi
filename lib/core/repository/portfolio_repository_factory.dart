import 'package:flutter/foundation.dart';
import 'package:portfoliox/core/app_config.dart';
import 'package:portfoliox/core/repository/mock_portfolio_repository.dart';
import 'package:portfoliox/core/repository/portfolio_repository.dart';

class PortfolioRepositoryFactory {
  static PortfolioRepository create() {
    if (!AppConfig.useExternalBackend) return MockPortfolioRepository();
    debugPrint(
      'External backend is enabled but not configured. '
      'Connect Firebase/Supabase via Dreamflow panel then implement an external repository.',
    );
    return MockPortfolioRepository();
  }
}
