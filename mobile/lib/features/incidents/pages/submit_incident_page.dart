import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../features/auth/cubit/auth_cubit.dart';
import '../cubit/incident_cubit.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class SubmitIncidentPage extends StatefulWidget {
  const SubmitIncidentPage({super.key});
  @override
  State<SubmitIncidentPage> createState() => _SubmitIncidentPageState();
}

class _SubmitIncidentPageState extends State<SubmitIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _type = 'fire';
  List<Uint8List> _photoBytesList = [];
  Position? _gpsPosition;
  LatLng _editablePosition = const LatLng(14.5995, 120.9842);
  bool _isAnonymous = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  String _buildingType = '';
  bool _accidentInjuries = false;
  int _accidentVehicles = 1;
  String _crimeType = '';
  String _crimeSuspect = '';
  int _medicalPatients = 1;
  String _medicalCondition = '';
  String _disasterType = '';
  String _infraType = '';
  String _damageSeverity = '';

  static final _types = [
    ('fire', Icons.local_fire_department, 'Fire', IrmsStatusColors.fire.light),
    ('accident', Icons.car_crash, 'Accident', IrmsStatusColors.pending.light),
    ('crime', Icons.local_police, 'Crime', IrmsColors.primary),
    ('medical', Icons.medical_services, 'Medical', IrmsStatusColors.medical.light),
    ('natural_disaster', Icons.storm, 'Disaster', IrmsColors.info),
    ('infrastructure', Icons.construction, 'Infra', IrmsColors.mutedText),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _phoneCtrl.text = authState.user['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _descCtrl.clear();
    _phoneCtrl.clear();
    setState(() {
      _photoBytesList.clear();
      _editablePosition = null;
      _gpsPosition = null;
    });
    context.read<IncidentCubit>().reset();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS Location services on your phone')),
          );
        }
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        if (mounted) {
          setState(() {
            _gpsPosition = pos;
            _editablePosition = LatLng(pos.latitude, pos.longitude);
          });
        }
      }
    } catch (e) {
      print('[location] position error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuth = authNotifier.value;
    return BlocListener<IncidentCubit, IncidentState>(
      listener: (context, state) {
        if (state is IncidentSubmitted) {
          final trackingCode = state.incident['tracking_code'] ?? state.incident['id'];
          if (trackingCode != null) {
            _showTrackingCode(context, trackingCode.toString());
          }
        }
      },
      child: BlocBuilder<IncidentCubit, IncidentState>(
        builder: (ctx, state) {
        return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  theme,
                  icon: Icons.category_outlined,
                  title: 'What type?',
                  subtitle: 'Select the incident category',
                ),
                const SizedBox(height: 12),
                _buildTypeGrid(theme),
                const SizedBox(height: 16),
                _buildAnonymousModeCard(theme),
                const SizedBox(height: 16),
                _buildTypeSpecificFields(theme),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  theme,
                  icon: Icons.description_outlined,
                  title: 'Details',
                  subtitle: 'Describe what happened',
                ),
                const SizedBox(height: 12),
                _buildCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDescField(theme)),
                          IconButton(
                            onPressed: () => _startListening(theme),
                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                            color: _isListening ? theme.colorScheme.primary : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationSection(theme),
                      if (isAuth == false && !_isAnonymous) ...[
                        const SizedBox(height: 12),
                        _buildPhoneField(theme),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  theme,
                  icon: Icons.camera_alt_outlined,
                  title: 'Photo',
                  subtitle: 'Optional visual evidence',
                ),
                const SizedBox(height: 12),
                _buildPhotoSection(theme),
                if (state is IncidentSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildSubmitButton(ctx, state),
                const SizedBox(height: 16),
                Text(
                  'Your report is confidential until verified by a dispatcher.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, {required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({Key? key, required Widget child}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  Widget _buildAnonymousModeCard(ThemeData theme) {
    final activeColor = _isAnonymous ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAnonymous 
          ? theme.colorScheme.secondary.withValues(alpha: 0.08) 
          : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isAnonymous 
            ? theme.colorScheme.secondary.withValues(alpha: 0.3) 
            : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _isAnonymous ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAnonymous ? Icons.security : Icons.person_outline,
                  color: activeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isAnonymous ? 'Anonymous Reporting Active' : 'Public / Named Report',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_isAnonymous) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PROTECTED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isAnonymous
                          ? 'Your identity & contact info will be masked from public view.'
                          : 'Standard report submission with your verified contact info.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAnonymous,
                activeColor: theme.colorScheme.secondary,
                onChanged: (val) {
                  setState(() => _isAnonymous = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final t = _types[index];
        final selected = _type == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _type = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.$2, color: selected ? Colors.white : theme.colorScheme.primary, size: 26),
                const SizedBox(height: 4),
                Text(
                  t.$3,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSpecificFields(ThemeData theme) {
    return _buildCard(
      child: Column(
        children: [
          switch (_type) {
            'fire' => _buildFireFields(theme),
            'accident' => _buildAccidentFields(theme),
            'crime' => _buildCrimeFields(theme),
            'medical' => _buildMedicalFields(theme),
            'natural_disaster' => _buildDisasterFields(theme),
            'infrastructure' => _buildInfraFields(theme),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }

  Widget _buildFireFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _buildingType.isEmpty ? null : _buildingType,
          decoration: const InputDecoration(labelText: 'Building / Structure Type'),
          items: const [
            DropdownMenuItem(value: 'residential', child: Text('Residential')),
            DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
            DropdownMenuItem(value: 'industrial', child: Text('Industrial')),
            DropdownMenuItem(value: 'mixed_use', child: Text('Mixed Use')),
            DropdownMenuItem(value: 'vehicle', child: Text('Vehicle')),
          ],
          onChanged: (v) => setState(() => _buildingType = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildAccidentFields(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _accidentVehicles,
                decoration: const InputDecoration(labelText: 'Vehicles Involved'),
                items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                onChanged: (v) => setState(() => _accidentVehicles = v ?? 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _accidentInjuries = !_accidentInjuries),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: _accidentInjuries ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accidentInjuries ? theme.colorScheme.error : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _accidentInjuries ? Icons.warning : Icons.check_circle_outline,
                        color: _accidentInjuries ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Injuries reported',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _accidentInjuries ? theme.colorScheme.onError : theme.colorScheme.onSurface,
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
    );
  }

  Widget _buildCrimeFields(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _crimeType.isEmpty ? null : _crimeType,
          decoration: const InputDecoration(labelText: 'Crime Type'),
          items: const [
            DropdownMenuItem(value: 'theft', child: Text('Theft')),
            DropdownMenuItem(value: 'robbery', child: Text('Robbery')),
            DropdownMenuItem(value: 'assault', child: Text('Assault')),
            DropdownMenuItem(value: 'vandalism', child: Text('Vandalism')),
            DropdownMenuItem(value: 'breakin', child: Text('Break-in')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _crimeType = v ?? ''),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(labelText: 'Suspect Description (optional)'),
          onChanged: (v) => _crimeSuspect = v,
        ),
      ],
    );
  }

  Widget _buildMedicalFields(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _medicalPatients,
                decoration: const InputDecoration(labelText: 'Number of Patients'),
                items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                onChanged: (v) => setState(() => _medicalPatients = v ?? 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _medicalCondition.isEmpty ? null : _medicalCondition,
                decoration: const InputDecoration(labelText: 'Primary Condition'),
                items: const [
                  DropdownMenuItem(value: 'cardiac', child: Text('Cardiac')),
                  DropdownMenuItem(value: 'respiratory', child: Text('Respiratory')),
                  DropdownMenuItem(value: 'trauma', child: Text('Trauma')),
                  DropdownMenuItem(value: 'unconscious', child: Text('Unconscious')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _medicalCondition = v ?? ''),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisasterFields(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _disasterType.isEmpty ? null : _disasterType,
          decoration: const InputDecoration(labelText: 'Disaster Type'),
          items: const [
            DropdownMenuItem(value: 'flood', child: Text('Flood')),
            DropdownMenuItem(value: 'landslide', child: Text('Landslide')),
            DropdownMenuItem(value: 'earthquake', child: Text('Earthquake')),
            DropdownMenuItem(value: 'typhoon', child: Text('Typhoon')),
            DropdownMenuItem(value: 'fire_structural', child: Text('Structural Fire')),
          ],
          onChanged: (v) => setState(() => _disasterType = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildInfraFields(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _infraType.isEmpty ? null : _infraType,
          decoration: const InputDecoration(labelText: 'Infrastructure Type'),
          items: const [
            DropdownMenuItem(value: 'road', child: Text('Road')),
            DropdownMenuItem(value: 'bridge', child: Text('Bridge')),
            DropdownMenuItem(value: 'power_line', child: Text('Power Line')),
            DropdownMenuItem(value: 'water_system', child: Text('Water System')),
            DropdownMenuItem(value: 'telecom', child: Text('Telecom')),
          ],
          onChanged: (v) => setState(() => _infraType = v ?? ''),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _damageSeverity.isEmpty ? null : _damageSeverity,
          decoration: const InputDecoration(labelText: 'Damage Severity'),
          items: const [
            DropdownMenuItem(value: 'minor', child: Text('Minor')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'severe', child: Text('Severe')),
            DropdownMenuItem(value: 'total', child: Text('Total Loss')),
          ],
          onChanged: (v) => setState(() => _damageSeverity = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildDescField(ThemeData theme) {
    return TextField(
      controller: _descCtrl,
      maxLines: 4,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Describe the incident',
        hintText: 'What happened? Where exactly? Any injuries?',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    return TextField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        hintText: 'Enter your phone number',
        prefixIcon: Icon(Icons.phone),
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              'Location',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_gpsPosition != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gps_fixed, color: theme.colorScheme.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  'GPS: ±${(_gpsPosition!.accuracy).toStringAsFixed(0)}m · ${_gpsPosition!.latitude.toStringAsFixed(5)}, ${_gpsPosition!.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _editablePosition,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapEvent: (event) {
                    if (event is MapEventTap) {
                      setState(() => _editablePosition = event.tapPosition);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.irms_mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _editablePosition,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_location, color: theme.colorScheme.primary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_editablePosition.latitude.toStringAsFixed(5)}, ${_editablePosition.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _determinePosition(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Locate',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap map to adjust location manually',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Column(
      children: [
        if (_photoBytesList.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoBytesList.length,
              itemBuilder: (ctx, idx) {
                final bytes = _photoBytesList[idx];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 14,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoBytesList.removeAt(idx)),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(_photoBytesList.isEmpty ? 'Take Photo' : 'Add Another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext ctx, IncidentState state) {
    final typeLabel = _types.firstWhere((t) => t.$1 == _type, orElse: () => _types.first).$3;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _submit(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.send),
          label: Text('Submit $typeLabel Report'),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final typeLabel = _types.firstWhere((t) => t.$1 == _type, orElse: () => _types.first).$3;
    final bool hasLocation = _editablePosition != null;
    if (!hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for GPS location or tap the map to set it.')),
      );
      return;
    }
    context.read<IncidentCubit>().submitIncident(
      type: _type,
      title: '$typeLabel Emergency',
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      latitude: _editablePosition?.latitude,
      longitude: _editablePosition?.longitude,
      reporterPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      photoBytesList: _photoBytesList,
    );
  }

  void _showTrackingCode(BuildContext ctx, String code) {
    Clipboard.setData(ClipboardData(text: code));
    final theme = Theme.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: IrmsColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: IrmsColors.success, size: 36),
        ),
        title: const Text('Report Submitted!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your tracking code:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                code,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code to track your incident status.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              messenger.showSnackBar(const SnackBar(content: Text('Tracking code copied!')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _resetForm();
            },
            icon: const Icon(Icons.add),
            label: const Text('New Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final XFile? picked;
      if (src == ImageSource.camera) {
        picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1280);
      } else {
        picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1280);
      }
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytesList.add(bytes));
    } catch (_) {}
  }

  Future<void> _startListening(ThemeData theme) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    bool available = await _speech.initialize(
      onStatus: (s) {},
      onError: (error) => setState(() => _isListening = false),
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available on this device')),
        );
      }
      return;
    }
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _descCtrl.text = result.recognizedWords;
        });
      },
      partialResults: true,
      localeId: 'en-US',
    );
  }
}