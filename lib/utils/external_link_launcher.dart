import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';

/// Deep link that opens a Facebook HTTPS URL inside the Facebook app.
Uri facebookAppUri(String httpsPageUrl) {
  return Uri.parse(
    'fb://facewebmodal/f?href=${Uri.encodeComponent(httpsPageUrl.trim())}',
  );
}

/// Android intent targeting the Facebook app (`com.facebook.katana`).
Uri? androidFacebookIntentUri(Uri httpsUri) {
  if (!Platform.isAndroid) return null;
  final path = '${httpsUri.host}${httpsUri.path}';
  final query = httpsUri.hasQuery ? '?${httpsUri.query}' : '';
  return Uri.parse(
    'intent://$path$query#Intent;package=com.facebook.katana;scheme=https;end',
  );
}

/// Deep link that opens a YouTube HTTPS URL inside the YouTube app.
Uri youtubeAppUri(String httpsUrl) {
  final uri = Uri.parse(httpsUrl.trim());
  final path = '${uri.host}${uri.path}';
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return Uri.parse('vnd.youtube://$path$query');
}

/// Android intent targeting the YouTube app (`com.google.android.youtube`).
Uri? androidYouTubeIntentUri(Uri httpsUri) {
  if (!Platform.isAndroid) return null;
  final path = '${httpsUri.host}${httpsUri.path}';
  final query = httpsUri.hasQuery ? '?${httpsUri.query}' : '';
  return Uri.parse(
    'intent://$path$query#Intent;package=com.google.android.youtube;scheme=https;end',
  );
}

Future<bool> _launchWithCandidates(
  BuildContext context,
  Uri httpsUri,
  List<Uri> candidates, {
  required String failureMessage,
}) async {
  for (final uri in candidates) {
    try {
      final canOpen = await canLaunchUrl(uri);
      if (!canOpen) continue;
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {
      continue;
    }
  }

  try {
    final ok = await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showFailure(context, failureMessage);
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      _showFailure(context, failureMessage);
    }
    return false;
  }
}

Future<bool> launchFacebookUrl(
  BuildContext context,
  String url, {
  String? failureMessage,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    _showFailure(context, failureMessage ?? 'Link is not available');
    return false;
  }

  final httpsUri = Uri.tryParse(trimmed);
  if (httpsUri == null || !httpsUri.hasScheme) {
    _showFailure(context, failureMessage ?? 'Invalid link');
    return false;
  }

  final candidates = <Uri>[
    facebookAppUri(trimmed),
    if (androidFacebookIntentUri(httpsUri) case final intent?) intent,
    httpsUri,
  ];

  return _launchWithCandidates(
    context,
    httpsUri,
    candidates,
    failureMessage: failureMessage ?? 'Could not open Facebook',
  );
}

Future<bool> launchYouTubeUrl(
  BuildContext context,
  String url, {
  String? failureMessage,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    _showFailure(context, failureMessage ?? 'Link is not available');
    return false;
  }

  final httpsUri = Uri.tryParse(trimmed);
  if (httpsUri == null || !httpsUri.hasScheme) {
    _showFailure(context, failureMessage ?? 'Invalid link');
    return false;
  }

  final candidates = <Uri>[
    youtubeAppUri(trimmed),
    if (androidYouTubeIntentUri(httpsUri) case final intent?) intent,
    httpsUri,
  ];

  return _launchWithCandidates(
    context,
    httpsUri,
    candidates,
    failureMessage: failureMessage ?? 'Could not open YouTube',
  );
}

Future<bool> launchExternalUrl(
  BuildContext context,
  String url, {
  String? failureMessage,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    _showFailure(context, failureMessage ?? 'Link is not available');
    return false;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    _showFailure(context, failureMessage ?? 'Invalid link');
    return false;
  }

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showFailure(context, failureMessage ?? 'Could not open link');
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      _showFailure(context, failureMessage ?? 'Could not open link');
    }
    return false;
  }
}

void _showFailure(BuildContext context, String message) {
  final c = Theme.of(context).extension<AppThemeColors>();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: AppTheme.lato(color: c?.textPrimary ?? Colors.white),
      ),
      backgroundColor: c?.backgroundElevated ?? Colors.grey.shade900,
    ),
  );
}
