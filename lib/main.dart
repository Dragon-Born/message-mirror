import 'package:flutter/material.dart';
import 'package:message_mirror/message_stream.dart';
import 'package:message_mirror/platform_controls.dart';
import 'package:message_mirror/prefs.dart';
import 'package:message_mirror/permissions.dart';
import 'package:message_mirror/logger.dart';
import 'package:flutter/services.dart';
import 'package:message_mirror/app_selector.dart';
import 'package:message_mirror/payload_template_screen.dart';
import 'dart:async';
import 'package:message_mirror/logs_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message Mirror',
      theme: _createTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _createTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B73FF),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      typography: Typography.material2021(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _githubFadeAnimation;
  late Animation<Offset> _githubSlideAnimation;
  late Animation<double> _versionFadeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _progressAnimation;
  String version = '';

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2400), 
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Staggered animations for smooth sequential appearance
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    _logoSlideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _titleSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _subtitleSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _githubFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );
    
    _githubSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _versionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _loadVersionAndNavigate();
  }

  Future<void> _loadVersionAndNavigate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        version = 'v1.0.2+3';
      });
    }

    // Start animations
    _mainController.forward();
    _rotationController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ConfigScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController, 
          _rotationController, 
          _progressController
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.1),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Rotating outer ring
                            RotationTransition(
                              turns: _rotationAnimation,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Main logo container
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.sync_alt_rounded,
                                size: 48,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Animated Title
                    SlideTransition(
                      position: _titleSlideAnimation,
                      child: FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: Text(
                          'Message Mirror',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Animated Subtitle
                    SlideTransition(
                      position: _subtitleSlideAnimation,
                      child: FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: Text(
                          'Seamless Message Forwarding',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 64),
                    
                    // Animated GitHub Link
                    SlideTransition(
                      position: _githubSlideAnimation,
                      child: FadeTransition(
                        opacity: _githubFadeAnimation,
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('https://github.com/Dragon-Born/message-mirror');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.code_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Dragon-Born/message-mirror',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Animated Version
                    FadeTransition(
                      opacity: _versionFadeAnimation,
                      child: version.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                version,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator at bottom
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _progressAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: size.width * 0.6,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: (size.width * 0.6) * _progressAnimation.value,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initializing...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController endpointCtrl = TextEditingController();
  bool smsEnabled = true;
  bool hasNotifAccess = false;
  bool hasPostNotif = false;
  bool hasReadSms = false;
  bool ignoringBattery = false;
  bool serviceRunning = false;
  bool checkingService = true;
  MessageStream? stream;
  String _lastSavedEndpoint = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void reassemble() {
    super.reassemble();
    _recheckService();
  }

  Future<void> _loadPrefs() async {
    final sms = await _getSmsEnabled();
    serviceRunning = await PlatformControls.isServiceRunning();
    await _refreshPerms();
    if (!mounted) return;
    setState(() {
      smsEnabled = sms;
      checkingService = false;
    });
    final ep = await Prefs.getEndpoint();
    if (!mounted) return;
    setState(() {
      endpointCtrl.text = ep;
      _lastSavedEndpoint = ep;
    });
  }

  Future<void> _recheckService() async {
    setState(() { checkingService = true; });
    final running = await PlatformControls.isServiceRunning();
    if (!mounted) return;
    setState(() {
      serviceRunning = running;
      checkingService = false;
    });
  }

  Future<bool> _getSmsEnabled() async {
    MethodChannel ch = const MethodChannel('msg_mirror_prefs');
    final res = await ch.invokeMethod('getSmsEnabled');
    return res == true;
  }

  Future<void> _setSmsEnabled(bool v) async {
    MethodChannel ch = const MethodChannel('msg_mirror_prefs');
    await ch.invokeMethod('setSmsEnabled', v);
    setState(() { smsEnabled = v; });
  }

  Future<void> _refreshPerms() async {
    hasNotifAccess = await PermissionService.hasNotificationAccess();
    hasPostNotif = await PermissionService.hasPostNotifications();
    hasReadSms = await PermissionService.hasReadSms();
    ignoringBattery = await PermissionService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    endpointCtrl.dispose();
    super.dispose();
  }

  bool get _destinationDirty =>
      endpointCtrl.text.trim() != _lastSavedEndpoint.trim();

  void _saveDestination() {
    final endpoint = endpointCtrl.text.trim();
    if (endpoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set Endpoint first')));
      return;
    }
    Prefs.setEndpoint(endpoint);
    final s = MessageStream(reception: '', endpoint: endpoint);
    s.start();
    Logger.d('Destination saved: endpoint=$endpoint');
    setState(() {
      stream = s;
      _lastSavedEndpoint = endpoint;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sync_alt,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Message Mirror',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Queue',
            icon: Icon(Icons.cloud_upload_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())); },
          ),
          IconButton(
            tooltip: 'Logs',
            icon: Icon(Icons.article_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen())); },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    serviceRunning ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: 48,
                    color: serviceRunning ? Colors.green : colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    serviceRunning ? 'Service Active' : 'Service Inactive',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceRunning 
                        ? 'Messages are being monitored and forwarded'
                        : 'Configure settings and start the service',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _ModernCard(
              title: 'Destination Settings',
              icon: Icons.settings_ethernet_rounded,
              child: Column(
                children: [
                  TextField(
                    controller: endpointCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint URL',
                      hintText: 'https://your-api.example.com/webhook',
                      prefixIcon: Icon(Icons.link_rounded),
                      helperText: 'HTTP endpoint to receive message data',
                    ),
                    onChanged: (_) { setState(() {}); },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                      onPressed: (endpointCtrl.text.trim().isEmpty || !_destinationDirty)
                          ? null
                          : _saveDestination,
                    icon: Icon(_destinationDirty ? Icons.save_rounded : Icons.check_rounded),
                    label: Text(_destinationDirty ? 'Save Configuration' : 'Configuration Saved'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const PayloadTemplateScreen())); },
                    icon: const Icon(Icons.data_object_rounded),
                    label: const Text('Edit Payload Template'),
                  ),
                  const SizedBox(height: 8),
                   OutlinedButton.icon(
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSelectorScreen())); },
                    icon: const Icon(Icons.apps_rounded),
                    label: const Text('Select Apps to Monitor'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _ModernCard(
              title: 'Service Control',
              icon: Icons.power_settings_new_rounded,
              child: Column(
                    children: [
                      if (checkingService)
                    Container(
                      padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Checking service status...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                          ),
                        )
                      else if (!serviceRunning)
                    FilledButton.icon(
                            onPressed: (endpointCtrl.text.trim().isEmpty)
                                ? null
                                : () async {
                                    setState(() { checkingService = true; });
                                    await PlatformControls.startService();
                                    await Future.delayed(const Duration(milliseconds: 600));
                                    final running = await PlatformControls.isServiceRunning();
                                    if (!mounted) return;
                                    setState(() {
                                      serviceRunning = running;
                                      checkingService = false;
                                    });
                                  },
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      label: const Text('Start Monitoring Service'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                          ),
                        )
                      else
                    OutlinedButton.icon(
                            onPressed: () async {
                              setState(() { checkingService = true; });
                              await PlatformControls.stopService();
                              bool running = true;
                              for (int i = 0; i < 5; i++) {
                                await Future.delayed(const Duration(milliseconds: 300));
                                running = await PlatformControls.isServiceRunning();
                                if (!running) break;
                              }
                              if (!mounted) return;
                              setState(() {
                                serviceRunning = running;
                                checkingService = false;
                              });
                            },
                      icon: const Icon(Icons.stop_circle_rounded),
                      label: const Text('Stop Service'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sms_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMS Observer',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Monitor SMS messages in addition to notifications',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: smsEnabled,
                          onChanged: (v) async { 
                            await _setSmsEnabled(v); 
                            await Logger.d('SMS enabled set to $v'); 
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _ModernCard(
              title: 'Permissions',
              icon: Icons.security_rounded,
              child: Column(
                children: [
                  _ModernPermissionRow(
                    ok: hasNotifAccess,
                    title: 'Notification Access',
                    subtitle: 'Required to capture notifications',
                    icon: Icons.notifications_rounded,
                    action: () { PermissionService.openNotificationAccess(); },
                  ),
                  const SizedBox(height: 16),
                  _ModernPermissionRow(
                    ok: hasPostNotif,
                    title: 'Post Notifications',
                    subtitle: 'Allow app to show status notifications',
                    icon: Icons.notification_add_rounded,
                    action: () async { 
                      await PermissionService.requestPostNotifications(); 
                      await _refreshPerms(); 
                    },
                  ),
                  const SizedBox(height: 16),
                  _ModernPermissionRow(
                    ok: hasReadSms,
                    title: 'Read SMS',
                    subtitle: 'Optional: Monitor SMS messages',
                    icon: Icons.sms_rounded,
                    isOptional: true,
                    action: () async { 
                      await PermissionService.requestReadSms(); 
                      await _refreshPerms(); 
                    },
                  ),
                  const SizedBox(height: 16),
                  _ModernPermissionRow(
                    ok: ignoringBattery,
                    title: 'Battery Optimization',
                    subtitle: 'Prevent Android from stopping the service',
                    icon: Icons.battery_saver_rounded,
                    action: () { PermissionService.openBatterySettings(); },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: PermissionService.getDataSaverStatus(),
                    builder: (context, snapshot) {
                      final st = snapshot.data ?? 1;
                      final ok = st == 1 || st == 2;
                      return _ModernPermissionRow(
                        ok: ok,
                        title: 'Unrestricted Data',
                        subtitle: 'Allow background network access',
                        icon: Icons.data_usage_rounded,
                        action: () { PermissionService.openDataSaverSettings(); },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                      onPressed: _refreshPerms,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh Permissions'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _GitHubInfoCard(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ModernCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
        ),
    );
  }
}

class _ModernPermissionRow extends StatelessWidget {
  final bool ok;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOptional;
  final VoidCallback action;

  const _ModernPermissionRow({
    required this.ok,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isOptional = false,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (ok) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Granted';
    } else if (isOptional) {
      statusColor = colorScheme.onSurfaceVariant;
      statusIcon = Icons.info_outline_rounded;
      statusText = 'Optional';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
      statusText = 'Required';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok 
            ? Colors.green.withOpacity(0.1)
            : (isOptional 
                ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : Colors.orange.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok 
              ? Colors.green.withOpacity(0.3)
              : (isOptional 
                  ? colorScheme.outline.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
      children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
        TextButton(
          onPressed: action,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  ok ? 'Settings' : 'Grant',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GitHubInfoCard extends StatefulWidget {
  @override
  State<_GitHubInfoCard> createState() => _GitHubInfoCardState();
}

class _GitHubInfoCardState extends State<_GitHubInfoCard> {
  String version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        version = 'v1.0.2+3';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _ModernCard(
      title: 'About',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.primaryContainer.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sync_alt,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message Mirror',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (version.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              version,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Source Project',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse('https://github.com/Dragon-Born/message-mirror');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: Text(
                                'github.com/Dragon-Born/message-mirror',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://github.com/Dragon-Born/message-mirror');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline_rounded,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Star on GitHub',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://github.com/Dragon-Born/message-mirror/issues');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Report Issues',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  _bootstrapBackground();
}

Future<void> _bootstrapBackground() async {
  final reception = await Prefs.getReception();
  final endpoint = await Prefs.getEndpoint();
  await Logger.d('Background(main.dart) bootstrap: reception=${reception.isEmpty ? 'EMPTY' : 'SET'}, endpoint=${endpoint.isEmpty ? 'DEFAULT' : endpoint}');
  final stream = MessageStream(
    reception: reception,
    endpoint: endpoint.isEmpty ? null : endpoint,
  );
  stream.start();
  await Logger.d('Background(main.dart) stream started');
}

 
