import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Model/event.dart';
import 'dart:async';
import 'package:flutter/gestures.dart'; // Needed for gestureRecognizers
import 'package:flutter/foundation.dart'; // Needed for Factory

class EventDetailPage extends StatefulWidget {
  final Event event;
  const EventDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final Completer<GoogleMapController> _controller;
  late Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _controller = Completer();
    print("Event coordinates: ${widget.event.latitude}, ${widget.event.longitude}");
    _initializeMarkers();
  }

  void _initializeMarkers() {
    // NOTE: Database currently has no latitude/longitude columns
    // All events will show coordinates 0.0, 0.0 until schema is updated
    // See SCHEMA_MISMATCH_REPORT.md for migration instructions
    _markers = {
      Marker(
        markerId: const MarkerId('event_location'),
        position: LatLng(widget.event.latitude, widget.event.longitude),
        infoWindow: InfoWindow(
          title: widget.event.title,
          snippet: widget.event.organizationName,
        ),
      ),
    };
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    print("Map created successfully");
    _controller.complete(controller);

    // Optional: Animate to the event location
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.event.latitude, widget.event.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image Section
              if (widget.event.bannerUrl != null && widget.event.bannerUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.event.bannerUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (widget.event.bannerUrl != null && widget.event.bannerUrl!.isNotEmpty)
                const SizedBox(height: 24),
              // Details Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.event.description),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(value: widget.event.isRegistered, onChanged: (_) {}),
                            const Text('Registered'),
                          ],
                        ),
                        if (widget.event.isTeamEvent)
                          Row(
                            children: [
                              const Icon(Icons.group, size: 18),
                              const SizedBox(width: 8),
                              Text('Team Size: ${widget.event.minTeamSize ?? '-'} - ${widget.event.maxTeamSize ?? '-'}'),
                            ],
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text(widget.event.isRegistered ? 'Registered' : 'Register'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.event.organizationLogo.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.event.organizationLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text('No Image'));
                        },
                      ),
                    )
                        : const Center(child: Text('No Image')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Map Section
              const Text(
                'Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.event.latitude, widget.event.longitude),
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    mapType: MapType.normal,
                    // Enable gestures
                    scrollGesturesEnabled: true,   // Allows panning
                    zoomGesturesEnabled: true,     // Allows pinch-to-zoom
                    rotateGesturesEnabled: true,   // Allows rotation
                    tiltGesturesEnabled: true,     // Allows tilting
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Location details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Lat: ${widget.event.latitude.toStringAsFixed(6)}'),
                          Text('Lng: ${widget.event.longitude.toStringAsFixed(6)}'),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final GoogleMapController controller = await _controller.future;
                        await controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(widget.event.latitude, widget.event.longitude),
                              zoom: 18,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.center_focus_strong),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Travel Details
              const Text(
                'Travel Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Travel information goes here...'),
              const SizedBox(height: 80), // Space for bottom bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.info_outline),
            Icon(Icons.map_outlined),
            Icon(Icons.add),
            Icon(Icons.calendar_today_outlined),
          ],
        ),
      ),
    );
  }
}