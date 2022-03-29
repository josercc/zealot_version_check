library zealot_version_check;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_update_dialog/flutter_update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

class ZealotVersionCheck extends StatefulWidget {
  /// Zealot的地址
  final String zealotHost;

  /// Zealot 用户 Token
  final String token;

  /// Channel Key
  final String channelKey;

  /// 内容组件
  final Widget child;

  /// 初始化
  const ZealotVersionCheck({
    Key? key,
    required this.zealotHost,
    required this.token,
    required this.channelKey,
    required this.child,
  }) : super(key: key);

  @override
  State<ZealotVersionCheck> createState() => _ZealotVersionCheckState();
}

class _ZealotVersionCheckState extends State<ZealotVersionCheck> {
  @override
  void initState() {
    super.initState();
    _loadLastVersion();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// 获取最新的版本
  Future<void> _loadLastVersion() async {
    final dio = Dio();
    Response<Map<String, dynamic>> response = await dio.get(
      "${widget.zealotHost}/api/apps/versions?token=${widget.token}&channel_key=${widget.channelKey}&page=1&per_page=1",
    );
    List<dynamic>? releases = response.data?["releases"] as List<dynamic>?;
    if (releases == null) return;
    Map<String, dynamic>? lastVersion = releases.first as Map<String, dynamic>?;
    if (lastVersion == null) return;
    String? releaseVersion = lastVersion["release_version"] as String?;
    String? buildVersion = lastVersion["build_version"] as String?;
    String? installUrl = lastVersion["install_url"] as String?;
    List<dynamic> changelog = lastVersion["changelog"] as List<dynamic>? ?? [];
    PackageInfo info = await PackageInfo.fromPlatform();
    String appVersion = info.version;
    String appBuildNumber = info.buildNumber;
    if (Version.parse(releaseVersion) < Version.parse(appVersion)) return;
    if (Version.parse(buildVersion) <= Version.parse(appBuildNumber)) return;
    if (releaseVersion == null || buildVersion == null || installUrl == null) {
      return;
    }
    UpdateDialog.showUpdate(
      context,
      title: "有最新测试版本:$releaseVersion($buildVersion)发布,是否需要升级?",
      updateContent: "更新内容:\n${changelog.join("\n")}",
      onUpdate: () {
        launch(installUrl);
      },
    );
  }
}
