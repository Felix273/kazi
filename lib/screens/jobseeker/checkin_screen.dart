import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/checkin_service.dart';
import '../../utils/app_theme.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.jobLat,
    required this.jobLng,
  });

  final String jobId;
  final String jobTitle;
  final double jobLat;
  final double jobLng;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;

  bool _loadingLocation = true;
  bool _loadingJob = true;
  bool _submitting = false;
  bool _hasCheckedIn = false;

  String? _locationError;

  static const double _allowedRadiusMeters = 500;

  LatLng get _jobPosition => LatLng(widget.jobLat, widget.jobLng);

  @override
  void initState() {
    super.initState();
    _loadJobState();
    _getCurrentLocation();
  }

  Future<void> _loadJobState() async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (!mounted) return;

      setState(() {
        _hasCheckedIn = document.data()?['workStatus'] == 'in_progress';
        _loadingJob = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loadingJob = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();

      if (!servicesEnabled) {
        throw StateError('Turn on location services to continue.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location access is permanently disabled. Enable it from your device settings.',
        );
      }

      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission is required to verify your arrival.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });

      await _moveCameraToWorker(position);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationError = error is StateError
            ? error.message.toString()
            : 'Your location could not be determined. Check your settings and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _moveCameraToWorker(Position position) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _mapBounds(_jobPosition, LatLng(position.latitude, position.longitude)),
        90,
      ),
    );
  }

  LatLngBounds _mapBounds(LatLng first, LatLng second) {
    return LatLngBounds(
      southwest: LatLng(
        first.latitude < second.latitude ? first.latitude : second.latitude,
        first.longitude < second.longitude ? first.longitude : second.longitude,
      ),
      northeast: LatLng(
        first.latitude > second.latitude ? first.latitude : second.latitude,
        first.longitude > second.longitude ? first.longitude : second.longitude,
      ),
    );
  }

  double? get _distanceMeters {
    final position = _currentPosition;

    if (position == null) return null;

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.jobLat,
      widget.jobLng,
    );
  }

  bool get _isWithinRange {
    final distance = _distanceMeters;

    return distance != null && distance <= _allowedRadiusMeters;
  }

  double get _distanceProgress {
    final distance = _distanceMeters;

    if (distance == null) return 0;

    return (1 - (distance / _allowedRadiusMeters)).clamp(0.0, 1.0);
  }

  Future<void> _performAction() async {
    final position = _currentPosition;

    if (position == null || !_isWithinRange || _submitting) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final location = GeoPoint(position.latitude, position.longitude);

      if (_hasCheckedIn) {
        await CheckinService.checkOut(widget.jobId, location);

        if (!mounted) return;

        await _showCompletionDialog();

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        await CheckinService.checkIn(widget.jobId, location);

        if (!mounted) return;

        setState(() => _hasCheckedIn = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful. Your job has started.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The action could not be completed. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showCompletionDialog() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 34,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.task_alt_rounded, size: 32),
          ),
          title: const Text('Job completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your work has been marked complete successfully.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.secondary,
                      foregroundColor: scheme.onSecondary,
                      child: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Your payment has been transferred to your Kazi Wallet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final position = _currentPosition;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_hasCheckedIn ? 'Finish job' : 'Start job'),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreenDark.withValues(alpha: 0.92),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _loadingLocation ? null : _getCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _jobPosition,
              zoom: 16,
            ),
            padding: const EdgeInsets.only(top: 145, bottom: 290),
            onMapCreated: (controller) async {
              _mapController = controller;

              if (position != null) {
                await _moveCameraToWorker(position);
              }
            },
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationEnabled: position != null,
            myLocationButtonEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('job-location'),
                position: _jobPosition,
                infoWindow: InfoWindow(
                  title: widget.jobTitle,
                  snippet: 'Job location',
                ),
              ),
              if (position != null)
                Marker(
                  markerId: const MarkerId('worker-location'),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: 'Your location'),
                ),
            },
            circles: {
              Circle(
                circleId: const CircleId('check-in-radius'),
                center: _jobPosition,
                radius: _allowedRadiusMeters,
                fillColor: AppTheme.primaryGreen.withValues(alpha: 0.10),
                strokeColor: AppTheme.primaryGreen,
                strokeWidth: 2,
              ),
            },
          ),
          Positioned(
            top:
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _JobMapCard(
              jobTitle: widget.jobTitle,
              hasCheckedIn: _hasCheckedIn,
              loadingJob: _loadingJob,
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 300,
            child: FloatingActionButton.small(
              heroTag: 'recenter-map',
              tooltip: 'Centre map',
              backgroundColor: scheme.surface,
              foregroundColor: scheme.primary,
              onPressed: position == null
                  ? null
                  : () => _moveCameraToWorker(position),
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _CheckInPanel(
              loadingLocation: _loadingLocation,
              locationError: _locationError,
              distanceMeters: _distanceMeters,
              progress: _distanceProgress,
              isWithinRange: _isWithinRange,
              hasCheckedIn: _hasCheckedIn,
              submitting: _submitting,
              onRetryLocation: _getCurrentLocation,
              onAction: _performAction,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobMapCard extends StatelessWidget {
  const _JobMapCard({
    required this.jobTitle,
    required this.hasCheckedIn,
    required this.loadingJob,
  });

  final String jobTitle;
  final bool hasCheckedIn;
  final bool loadingJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: hasCheckedIn
                  ? scheme.secondaryContainer
                  : scheme.primaryContainer,
              foregroundColor: hasCheckedIn
                  ? scheme.onSecondaryContainer
                  : scheme.onPrimaryContainer,
              child: Icon(
                hasCheckedIn
                    ? Icons.work_history_rounded
                    : Icons.location_on_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    loadingJob
                        ? 'Checking job status…'
                        : hasCheckedIn
                        ? 'Work is in progress. Check out when you finish.'
                        : 'Arrive within 500 metres to start.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (loadingJob)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              _WorkStatusBadge(active: hasCheckedIn),
          ],
        ),
      ),
    );
  }
}

class _WorkStatusBadge extends StatelessWidget {
  const _WorkStatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.teal : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        active ? 'Active' : 'Not started',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CheckInPanel extends StatelessWidget {
  const _CheckInPanel({
    required this.loadingLocation,
    required this.locationError,
    required this.distanceMeters,
    required this.progress,
    required this.isWithinRange,
    required this.hasCheckedIn,
    required this.submitting,
    required this.onRetryLocation,
    required this.onAction,
  });

  final bool loadingLocation;
  final String? locationError;
  final double? distanceMeters;
  final double progress;
  final bool isWithinRange;
  final bool hasCheckedIn;
  final bool submitting;
  final VoidCallback onRetryLocation;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      elevation: 16,
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (loadingLocation)
                const _LocatingState()
              else if (locationError != null)
                _LocationErrorState(
                  message: locationError!,
                  onRetry: onRetryLocation,
                )
              else
                _DistanceState(
                  distanceMeters: distanceMeters,
                  progress: progress,
                  isWithinRange: isWithinRange,
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: hasCheckedIn ? scheme.error : scheme.primary,
                  foregroundColor: hasCheckedIn
                      ? scheme.onError
                      : scheme.onPrimary,
                ),
                onPressed:
                    submitting ||
                        loadingLocation ||
                        locationError != null ||
                        !isWithinRange
                    ? null
                    : onAction,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasCheckedIn
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline_rounded,
                      ),
                label: Text(
                  submitting
                      ? hasCheckedIn
                            ? 'Finishing job…'
                            : 'Starting job…'
                      : hasCheckedIn
                      ? 'Finish and check out'
                      : 'Start and check in',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hasCheckedIn
                    ? 'Finishing confirms that the agreed work has been completed.'
                    : 'Your current GPS position is recorded for attendance verification.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocatingState extends StatelessWidget {
  const _LocatingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        const SizedBox.square(
          dimension: 38,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finding your location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'This normally takes a few seconds.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationErrorState extends StatelessWidget {
  const _LocationErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            child: const Icon(Icons.location_off_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location unavailable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Try again',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _DistanceState extends StatelessWidget {
  const _DistanceState({
    required this.distanceMeters,
    required this.progress,
    required this.isWithinRange,
  });

  final double? distanceMeters;
  final double progress;
  final bool isWithinRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final distance = distanceMeters ?? 0;
    final statusColor = isWithinRange ? AppTheme.success : scheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withValues(alpha: 0.12),
              foregroundColor: statusColor,
              child: Icon(
                isWithinRange
                    ? Icons.location_on_rounded
                    : Icons.directions_walk_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWithinRange
                        ? 'You are within range'
                        : 'Move closer to the job',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _distanceMessage(distance),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatDistance(distance),
              style: theme.textTheme.titleLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            color: statusColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              'Your position',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'Required radius: 500 m',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _distanceMessage(double distance) {
  if (distance <= 500) {
    return 'Your location is verified and you can continue.';
  }

  final remaining = distance - 500;

  return 'Move about ${_formatDistance(remaining)} closer to continue.';
}

String _formatDistance(double distance) {
  if (distance >= 1000) {
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  return '${distance.toStringAsFixed(0)} m';
}
