import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// Turns any caught exception into something a person can act on.
///
/// Every controller in the app stores the *raw* exception in its state
/// (see e.g. `AssessmentState.error`, typed `Object?` rather than
/// `String?`) specifically so this is the one place that decides what
/// gets shown — a `DioException`'s own message is implementation detail
/// (English, mentions sockets/hosts/status codes: "SocketException:
/// Failed host lookup"), never something to put in front of someone
/// whose wifi just dropped or whose ngrok tunnel is down. Screens call
/// this at the point of display (`friendlyErrorMessage(l10n,
/// state.error!)`) rather than controllers calling it at the point of
/// catch, so the message is always in whatever language the interface
/// is currently showing — including a language switch that happens
/// after the error was caught.
String friendlyErrorMessage(AppLocalizations l10n, Object error) {
  // A handful of controllers (auth's own validation, mainly) put an
  // already-worded, already-localized message straight into `error`
  // instead of an exception — pass it through unchanged rather than
  // trying to reclassify a string that was never an exception to begin
  // with.
  if (error is String) return error;
  if (error is! DioException) return l10n.commonError;

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return l10n.errorNoConnection;
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return l10n.errorTimeout;
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      if (status >= 500) return l10n.errorServer;
      // Several endpoints answer a 4xx with a short, meaningful plain-text
      // body (e.g. "this person only accepts messages from people they
      // follow") — worth showing over a generic message when it's short
      // enough to actually be that kind of message rather than, say, an
      // HTML error page from a proxy in between.
      final body = error.response?.data;
      if (body is String && body.trim().isNotEmpty && body.length < 200) {
        return body.trim();
      }
      return l10n.commonError;
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      // `unknown` is Dio's bucket for the exception types it doesn't have
      // a name for — in practice this is almost always the platform's own
      // socket/DNS failure (no internet, server unreachable), so it reads
      // the same as a connection error rather than a generic one.
      return l10n.errorNoConnection;
  }
}
