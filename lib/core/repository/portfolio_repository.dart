import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/portfolio_project.dart';
import 'package:portfoliox/core/models/system_log.dart';

abstract class PortfolioRepository {
  Stream<List<FrameworkMetric>> watchMetrics();
  Stream<List<PortfolioProject>> watchProjects();
  Stream<List<SystemLog>> watchSystemLogs({int limit = 12});
  Future<PortfolioProject?> getProjectById(String id);
  void dispose();
}
