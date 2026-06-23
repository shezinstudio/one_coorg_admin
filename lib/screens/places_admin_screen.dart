import 'package:flutter/material.dart';
import '../main.dart';

class PlacesAdminScreen extends StatefulWidget {
  const PlacesAdminScreen({super.key});

  @override
  State<PlacesAdminScreen> createState() => _PlacesAdminScreenState();
}

class _PlacesAdminScreenState extends State<PlacesAdminScreen> {
  List<Map<String, dynamic>> _places = [];
  bool _loading = true;
  bool _showForm = false;

  static const _green = Color(0xFF2D6A4F);
  static const _bg = Color(0xFFF6FBF7);

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    setState(() => _loading = true);
    final data = await supabase.from('places').select().order('name');
    setState(() {
      _places = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _deletePlace(String id) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm'),
            content: const Text('Delete this place?'),
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
    if (!confirm) return;
    await supabase.from('places').delete().eq('id', id);
    _fetchPlaces();
    _showSnack('Place deleted');
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
                      'Places',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_places.length} places in Coorg',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add_rounded),
                  label: Text(_showForm ? 'Cancel' : 'Add Place'),
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
                    _PlaceForm(
                      onSaved: () {
                        setState(() => _showForm = false);
                        _fetchPlaces();
                        _showSnack('Place added successfully');
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Table ───────────────────────────
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _PlacesTable(places: _places, onDelete: _deletePlace),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Places Table ──────────────────────────────────────────
class _PlacesTable extends StatelessWidget {
  final List<Map<String, dynamic>> places;
  final void Function(String) onDelete;

  const _PlacesTable({required this.places, required this.onDelete});

  Color _categoryColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'waterfall':
        return const Color(0xFF0077B6);
      case 'wildlife':
        return const Color(0xFF2D6A4F);
      case 'temple':
        return const Color(0xFFE07C24);
      case 'viewpoint':
        return const Color(0xFF9B5DE5);
      case 'adventure':
        return const Color(0xFFE63946);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'No places yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Click "Add Place" to create the first one',
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
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(0.8),
            5: FlexColumnWidth(0.6),
            6: FlexColumnWidth(0.6),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[50]),
              children:
                  [
                        'Name',
                        'Category',
                        'Entry Fee',
                        'Location',
                        'Best Time',
                        'Top Rated',
                        'Actions',
                      ]
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
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
            ...places.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final isEven = i % 2 == 0;
              final catColor = _categoryColor(p['category']);
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
                          p['emoji'] ?? '📍',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p['name'] ?? '',
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
                    p['category'] != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p['category'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                  _cell(
                    Text(
                      p['entry_fee'] ?? 'Free',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  _cell(
                    Text(
                      p['location'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  _cell(
                    Text(
                      p['best_time'] ?? '–',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  _cell(
                    p['is_top_rated'] == true
                        ? const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB703),
                            size: 18,
                          )
                        : Icon(
                            Icons.star_outline_rounded,
                            color: Colors.grey[300],
                            size: 18,
                          ),
                  ),
                  _cell(
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => onDelete(p['id']),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: child,
  );
}

// ── Place Form ────────────────────────────────────────────
class _PlaceForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _PlaceForm({required this.onSaved});

  @override
  State<_PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<_PlaceForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _isTopRated = false;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _emoji = TextEditingController();
  final _imageUrl = TextEditingController();
  final _location = TextEditingController();
  final _fullLocation = TextEditingController();
  final _about = TextEditingController();
  final _entryFee = TextEditingController(text: 'Free');
  final _bestTime = TextEditingController();
  final _mapLabel = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _activitiesCtrl = TextEditingController();

  String? _selectedCategory;
  static const _categories = [
    'Waterfall',
    'Wildlife',
    'Temple',
    'Viewpoint',
    'Adventure',
    'Heritage',
    'Nature',
    'Beach',
  ];
  static const _green = Color(0xFF2D6A4F);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final activities = _activitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await supabase.from('places').insert({
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'emoji': _emoji.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'location': _location.text.trim(),
      'full_location': _fullLocation.text.trim(),
      'about': _about.text.trim(),
      'category': _selectedCategory,
      'entry_fee': _entryFee.text.trim(),
      'is_top_rated': _isTopRated,
      'best_time': _bestTime.text.trim(),
      'map_label': _mapLabel.text.trim(),
      'lat': double.tryParse(_lat.text),
      'lng': double.tryParse(_lng.text),
      'activities': activities,
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
              'Add New Place',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            // Row 1
            _row([
              _field('Place Name', _name, required: true),
              _field('Emoji', _emoji, hint: '💧', required: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Category'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    hint: const Text('Select category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            // Row 2
            _row([
              _field('Short Description', _desc),
              _field('Location (short)', _location, hint: 'Near Madikeri'),
              _field(
                'Full Location',
                _fullLocation,
                hint: 'Abbey Falls, Madikeri, Kodagu',
              ),
            ]),
            const SizedBox(height: 16),

            // About
            _label('About'),
            TextFormField(
              controller: _about,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Detailed description of this place...',
              ),
            ),
            const SizedBox(height: 16),

            // Row 3
            _row([
              _field('Image URL', _imageUrl, hint: 'https://...'),
              _field('Entry Fee', _entryFee, hint: 'Free / ₹50'),
              _field('Best Time to Visit', _bestTime, hint: 'Oct to March'),
              _field('Map Label', _mapLabel, hint: 'Abbey Falls'),
            ]),
            const SizedBox(height: 16),

            // Row 4
            _row([
              _field('Latitude', _lat, hint: '12.4244'),
              _field('Longitude', _lng, hint: '75.7382'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Top Rated'),
                  Row(
                    children: [
                      Switch(
                        value: _isTopRated,
                        activeThumbColor: _green,
                        onChanged: (v) => setState(() => _isTopRated = v),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTopRated ? 'Yes ⭐' : 'No',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(),
            ]),
            const SizedBox(height: 16),

            // Activities
            _label('Activities (comma separated)'),
            TextFormField(
              controller: _activitiesCtrl,
              decoration: const InputDecoration(
                hintText: 'Trekking, Photography, Swimming',
                isDense: true,
              ),
            ),
            const SizedBox(height: 28),

            // Save
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
                    label: Text(_saving ? 'Saving...' : 'Save Place'),
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
