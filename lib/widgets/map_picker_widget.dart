import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../utils/app_theme.dart';

class MapPickerWidget extends StatefulWidget {
  const MapPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
  });

  final void Function(double latitude, double longitude, String neighborhood)
  onLocationSelected;

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  static const LatLng _nairobiCentre = LatLng(-1.2921, 36.8219);

  GoogleMapController? _mapController;

  late LatLng _selectedPosition;
  String _selectedNeighborhood = 'Nairobi';

  bool _isResolvingLocation = false;
  bool _isLocatingUser = false;
  String? _locationError;

  CameraPosition get _initialCameraPosition => CameraPosition(
    target: _selectedPosition,
    zoom: widget.initialLatitude != null && widget.initialLongitude != null
        ? 15
        : 12,
  );

  @override
  void initState() {
    super.initState();

    _selectedPosition =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _nairobiCentre;

    _updateNeighborhood(_selectedPosition);
  }

  Future<void> _updateNeighborhood(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _isResolvingLocation = true;
      _locationError = null;
    });

    try {
      final neighborhood = await LocationService.getNeighborhoodFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedNeighborhood = neighborhood.trim().isEmpty
            ? 'Selected location'
            : neighborhood;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedNeighborhood = 'Selected location';
        _locationError = 'The location name could not be determined.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    await _updateNeighborhood(_selectedPosition);
  }

  Future<void> _centreOnCurrentLocation() async {
    if (_isLocatingUser) return;

    setState(() {
      _isLocatingUser = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      final currentLocation = LatLng(position.latitude, position.longitude);

      _selectedPosition = currentLocation;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation, zoom: 16),
        ),
      );

      await _updateNeighborhood(currentLocation);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationError =
            'Your current location could not be accessed. Check location permissions and try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your current location could not be accessed. Check your device settings and permissions.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingUser = false;
        });
      }
    }
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _selectedPosition.latitude,
      _selectedPosition.longitude,
      _selectedNeighborhood,
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

    return Material(
      color: scheme.surfaceContainerLow,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  padding: const EdgeInsets.only(top: 110, bottom: 90),
                ),
                const Positioned(
                  top: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: _MapInstructionCard(),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 42),
                    child: _MapSelectionMarker(),
                  ),
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: FloatingActionButton.small(
                    heroTag: 'map-picker-current-location',
                    tooltip: 'Use current location',
                    onPressed: _isLocatingUser
                        ? null
                        : _centreOnCurrentLocation,
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.primary,
                    child: _isLocatingUser
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
                if (_isResolvingLocation)
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Finding location name…',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _SelectedLocationPanel(
            neighborhood: _selectedNeighborhood,
            position: _selectedPosition,
            resolving: _isResolvingLocation,
            error: _locationError,
            onConfirm: _isResolvingLocation ? null : _confirmLocation,
          ),
        ],
      ),
    );
  }
}

class _MapInstructionCard extends StatelessWidget {
  const _MapInstructionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.location_searching_rounded),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose the exact location',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Move the map until the pin is positioned correctly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSelectionMarker extends StatelessWidget {
  const _MapSelectionMarker();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(width: 4, color: scheme.surface),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on_rounded,
            color: scheme.onPrimary,
            size: 29,
          ),
        ),
        Container(width: 4, height: 20, color: scheme.primary),
        Container(
          width: 17,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ],
    );
  }
}

class _SelectedLocationPanel extends StatelessWidget {
  const _SelectedLocationPanel({
    required this.neighborhood,
    required this.position,
    required this.resolving,
    required this.error,
    required this.onConfirm,
  });

  final String neighborhood;
  final LatLng position;
  final bool resolving;
  final String? error;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      elevation: 14,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.place_outlined),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECTED LOCATION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          resolving ? 'Finding location…' : neighborhood,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${position.latitude.toStringAsFixed(5)}, '
                          '${position.longitude.toStringAsFixed(5)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: scheme.onErrorContainer,
                        size: 19,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: onConfirm,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirm location'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The selected coordinates will be used for nearby matching and arrival verification.',
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
