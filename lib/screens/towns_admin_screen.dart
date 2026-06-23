import 'package:flutter/material.dart';
import '../main.dart';

class TownsAdminScreen extends StatefulWidget {
  const TownsAdminScreen({super.key});

  @override
  State<TownsAdminScreen> createState() => _TownsAdminScreenState();
}

class _TownsAdminScreenState extends State<TownsAdminScreen> {
  List<Map<String, dynamic>> _towns = [];
  bool _loading = true;
  bool _showForm = false;

  static const _green = Color(0xFF2D6A4F);
  static const _bg = Color(0xFFF6FBF7);

  @override
  void initState() {
    super.initState();
    _fetchTowns();
  }

  Future<void> _fetchTowns() async {
    setState(() => _loading = true);
    final data = await supabase.from('towns').select().order('id');
    setState(() {
      _towns = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _deleteTown(int id) async {
    final confirm = await _showConfirm('Delete this town?');
    if (!confirm) return;
    await supabase.from('towns').delete().eq('id', id);
    _fetchTowns();
    _showSnack('Town deleted');
  }

  Future<bool> _showConfirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Towns',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_towns.length} towns in Coorg',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add_rounded),
                  label: Text(_showForm ? 'Cancel' : 'Add Town'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showForm ? Colors.grey[200] : _green,
                    foregroundColor: _showForm ? Colors.black87 : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // ── Add form ────────────────────────
                  if (_showForm) ...[
                    _TownForm(
                      onSaved: () {
                        setState(() => _showForm = false);
                        _fetchTowns();
                        _showSnack('Town added successfully');
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Table ───────────────────────────
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _TownsTable(
                          towns: _towns,
                          onDelete: _deleteTown,
                          onRefresh: _fetchTowns,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Towns Table ───────────────────────────────────────────
class _TownsTable extends StatelessWidget {
  final List<Map<String, dynamic>> towns;
  final void Function(int) onDelete;
  final VoidCallback onRefresh;

  const _TownsTable({
    required this.towns,
    required this.onDelete,
    required this.onRefresh,
  });

  static const _green = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    if (towns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('🏘️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'No towns yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Click "Add Town" to create the first one',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(0.8),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[50]),
              children:
                  [
                        'Name',
                        'Aka',
                        'Location',
                        'Weather',
                        'Population',
                        'Actions',
                      ]
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            h,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            // Rows
            ...towns.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              final isEven = i % 2 == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.white
                      : Colors.grey[50]?.withValues(alpha: 0.4),
                ),
                children: [
                  _cell(
                    Row(
                      children: [
                        Text(
                          t['emoji'] ?? '',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _cell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F3DC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t['aka'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                  _cell(
                    Text(
                      t['full_location'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  _cell(
                    Text(
                      t['weather'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  _cell(
                    Text(
                      t['population'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  _cell(
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => onDelete(t['id']),
                      tooltip: 'Delete',
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _cell(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: child,
  );
}

// ── Town Form ─────────────────────────────────────────────
class _TownForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _TownForm({required this.onSaved});

  @override
  State<_TownForm> createState() => _TownFormState();
}

class _TownFormState extends State<_TownForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _name = TextEditingController();
  final _aka = TextEditingController();
  final _desc = TextEditingController();
  final _emoji = TextEditingController();
  final _imagePath = TextEditingController();
  final _fullLocation = TextEditingController();
  final _about = TextEditingController();
  final _weather = TextEditingController();
  final _population = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  // Nearby places
  final List<Map<String, TextEditingController>> _nearbyPlaces = [];

  static const _green = Color(0xFF2D6A4F);

  void _addNearbyPlace() {
    setState(
      () => _nearbyPlaces.add({
        'name': TextEditingController(),
        'dist': TextEditingController(),
      }),
    );
  }

  void _removeNearbyPlace(int i) {
    setState(() {
      _nearbyPlaces[i]['name']!.dispose();
      _nearbyPlaces[i]['dist']!.dispose();
      _nearbyPlaces.removeAt(i);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final nearby = _nearbyPlaces
        .map((p) => {'name': p['name']!.text, 'dist': p['dist']!.text})
        .toList();

    await supabase.from('towns').insert({
      'name': _name.text.trim(),
      'aka': _aka.text.trim(),
      'description': _desc.text.trim(),
      'emoji': _emoji.text.trim(),
      'image_path': _imagePath.text.trim(),
      'full_location': _fullLocation.text.trim(),
      'about': _about.text.trim(),
      'nearby_places': nearby,
      'weather': _weather.text.trim(),
      'population': _population.text.trim(),
      'latitude': double.tryParse(_lat.text) ?? 0.0,
      'longitude': double.tryParse(_lng.text) ?? 0.0,
    });

    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8F3DC), width: 1.5),
        boxShadow: [
          BoxShadow(color: _green.withValues(alpha: 0.06), blurRadius: 16),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Town',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            // Row 1
            _row([
              _field('Town Name', _name, required: true),
              _field('Also Known As (Aka)', _aka, required: true),
              _field('Emoji', _emoji, hint: '🏛️', required: true),
            ]),
            const SizedBox(height: 16),

            // Row 2
            _row([
              _field('Short Description', _desc, required: true),
              _field(
                'Full Location',
                _fullLocation,
                hint: 'Madikeri, Kodagu, Karnataka',
                required: true,
              ),
              _field(
                'Image Path',
                _imagePath,
                hint: 'assets/images/madikeri.jpg',
                required: true,
              ),
            ]),
            const SizedBox(height: 16),

            // About
            _label('About'),
            TextFormField(
              controller: _about,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              decoration: const InputDecoration(
                hintText: 'Detailed description of the town...',
              ),
            ),
            const SizedBox(height: 16),

            // Row 3
            _row([
              _field('Weather', _weather, hint: '18–26°C', required: true),
              _field(
                'Population',
                _population,
                hint: '~33,000',
                required: true,
              ),
              _field('Latitude', _lat, hint: '12.4244', required: true),
              _field('Longitude', _lng, hint: '75.7382', required: true),
            ]),
            const SizedBox(height: 24),

            // Nearby places
            Row(
              children: [
                const Text(
                  'Nearby Places',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _addNearbyPlace,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Place'),
                  style: TextButton.styleFrom(foregroundColor: _green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._nearbyPlaces.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: p['name'],
                        decoration: const InputDecoration(
                          labelText: 'Place Name',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: p['dist'],
                        decoration: const InputDecoration(
                          labelText: 'Distance',
                          isDense: true,
                          hintText: '8 km',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _removeNearbyPlace(i),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 28),

            // Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_saving ? 'Saving...' : 'Save Town'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 16)])
            .toList()
          ..removeLast(),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint, isDense: true),
          validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
        ),
      ],
    );
  }
}
