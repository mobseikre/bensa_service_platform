import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Location card widget displaying address and navigation options with real-time distance
class LocationCardWidget extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const LocationCardWidget({
    super.key,
    required this.locationData,
  });

  @override
  State<LocationCardWidget> createState() => _LocationCardWidgetState();
}

class _LocationCardWidgetState extends State<LocationCardWidget> {
  Timer? _distanceUpdateTimer;
  double _currentDistance = 0.0;
  bool _isOpeningMaps = false;

  @override
  void initState() {
    super.initState();
    _initializeDistance();
    _startDistanceUpdates();
  }

  @override
  void dispose() {
    _distanceUpdateTimer?.cancel();
    super.dispose();
  }

  /// Safely parse a value to double, handling both String and num types
  double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  void _initializeDistance() {
    // Get customer location with safe parsing
    final customerLat = _parseDouble(
      widget.locationData['latitude'] ??
          widget.locationData['location_lat'] ??
          widget.locationData['lat'],
    );
    final customerLng = _parseDouble(
      widget.locationData['longitude'] ??
          widget.locationData['location_lng'] ??
          widget.locationData['lng'],
    );

    // Get technician location from job data
    final techLocation =
        widget.locationData['technician_location'] as Map<String, dynamic>?;
    if (techLocation != null) {
      final techLat = _parseDouble(techLocation['lat']);
      final techLng = _parseDouble(techLocation['lng']);

      if (customerLat != 0.0 &&
          customerLng != 0.0 &&
          techLat != 0.0 &&
          techLng != 0.0) {
        final distanceInMeters = Geolocator.distanceBetween(
          techLat,
          techLng,
          customerLat,
          customerLng,
        );
        setState(() {
          _currentDistance = distanceInMeters / 1000.0; // Convert to kilometers
        });
      }
    } else if (widget.locationData['distance'] != null) {
      // Fallback to distance from backend if available
      final distance = _parseDouble(widget.locationData['distance']);
      setState(() {
        _currentDistance = distance;
      });
    }
  }

  void _startDistanceUpdates() {
    // Update distance every 10 seconds if we have technician location
    _distanceUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        // Check mounted first before any async operations
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Get current technician position
        try {
          // Check mounted again after async check
          if (!mounted) {
            timer.cancel();
            return;
          }

          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled || !mounted) return;

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever ||
              !mounted) {
            return;
          }

          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              return Position(
                latitude: 0,
                longitude: 0,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            },
          );

          // Final mounted check before setState
          if (position.latitude != 0 && position.longitude != 0 && mounted) {
            _calculateDistance(position);
          }
        } catch (e) {
          debugPrint('Error updating distance: $e');
          // Don't update state if there's an error and widget is disposed
          if (!mounted) {
            timer.cancel();
          }
        }
      },
    );
  }

  void _calculateDistance(Position technicianPosition) {
    // Check mounted before any operations
    if (!mounted) return;

    final customerLat = _parseDouble(
      widget.locationData['latitude'] ??
          widget.locationData['location_lat'] ??
          widget.locationData['lat'],
    );
    final customerLng = _parseDouble(
      widget.locationData['longitude'] ??
          widget.locationData['location_lng'] ??
          widget.locationData['lng'],
    );

    if (customerLat == 0.0 || customerLng == 0.0 || !mounted) return;

    final distanceInMeters = Geolocator.distanceBetween(
      technicianPosition.latitude,
      technicianPosition.longitude,
      customerLat,
      customerLng,
    );

    // Final mounted check before setState
    if (mounted) {
      setState(() {
        _currentDistance = distanceInMeters / 1000.0; // Convert to kilometers
      });
    }
  }

  Future<void> _openMaps() async {
    // Set loading state
    if (mounted) {
      setState(() => _isOpeningMaps = true);
    }

    try {
      final customerLat = _parseDouble(
        widget.locationData['latitude'] ??
            widget.locationData['location_lat'] ??
            widget.locationData['lat'],
      );
      final customerLng = _parseDouble(
        widget.locationData['longitude'] ??
            widget.locationData['location_lng'] ??
            widget.locationData['lng'],
      );

      if (customerLat == 0.0 || customerLng == 0.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('موقع العميل غير متوفر'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get technician's current location with improved accuracy
      Position? techPosition;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            techPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            ).timeout(const Duration(seconds: 10));
          }
        }
      } catch (e) {
        debugPrint('Could not get technician location: $e');
      }

      // Build Google Maps URL
      String googleMapsUrlString;
      if (techPosition != null &&
          techPosition.latitude != 0 &&
          techPosition.longitude != 0) {
        // Calculate and show distance
        final distanceKm = Geolocator.distanceBetween(
              techPosition.latitude,
              techPosition.longitude,
              customerLat,
              customerLng,
            ) /
            1000.0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'فتح الخريطة - المسافة: ${distanceKm.toStringAsFixed(1)} كم'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        googleMapsUrlString =
            'https://www.google.com/maps/dir/?api=1&origin=${techPosition.latitude},${techPosition.longitude}&destination=$customerLat,$customerLng&travelmode=driving&dir_action=navigate';
      } else {
        googleMapsUrlString =
            'https://www.google.com/maps/dir/?api=1&destination=$customerLat,$customerLng&travelmode=driving&dir_action=navigate';
      }

      final googleMapsUrl = Uri.parse(googleMapsUrlString);
      final appleMapsUrl = Uri.parse(
          'https://maps.apple.com/?daddr=$customerLat,$customerLng&dirflg=d');

      try {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          final searchUrl = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$customerLat,$customerLng');
          await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching maps: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في فتح الخريطة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningMaps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'موقع الخدمة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14.sp,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _currentDistance > 0
                          ? '${_currentDistance.toStringAsFixed(1)} كم'
                          : '${widget.locationData['distance'] ?? 0.0} كم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.locationData['address'] as String? ?? 'العنوان غير متوفر',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton.icon(
              onPressed: _isOpeningMaps ? null : _openMaps,
              icon: _isOpeningMaps
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'navigation',
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
              label: Text(
                _isOpeningMaps ? 'جاري الفتح...' : 'التنقل إلى الموقع',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
