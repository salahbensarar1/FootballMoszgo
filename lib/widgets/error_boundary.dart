import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/logging_service.dart';
import '../services/global_messenger_service.dart';

/// Error boundary widget that catches and handles errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? fallbackMessage;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackMessage,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    
    // Set up global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggingService.error('Flutter Error', details.exception, details.stack);
      
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
      
      widget.onError?.call();
      
      // Show user-friendly message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          GlobalMessengerService.instance.showError(
            'An unexpected error occurred. Please try again.',
          );
        }
      });
    };
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context);
    }

    return widget.child;
  }

  Widget _buildErrorWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.somethingWentWrong ?? 'Something went wrong',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.fallbackMessage ?? 
                  l10n?.tryAgainOrContact ?? 
                  'Please try again or contact support if the problem persists.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Go Back',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        l10n?.retry ?? 'Retry',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF27121),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin to add error handling to stateful widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void handleError(Object error, StackTrace stackTrace, {String? context}) {
    LoggingService.error(
      context ?? 'Widget Error in ${T.toString()}',
      error,
      stackTrace,
    );

    if (mounted) {
      GlobalMessengerService.instance.showError(
        'An error occurred. Please try again.',
      );
    }
  }

  void handleAsyncError(Future<void> future, {String? context}) {
    future.catchError((error, stackTrace) {
      handleError(error, stackTrace, context: context);
    });
  }
}