import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme.dart';
import '../../../core/services/api_client.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _category = 'manual';
  String _durationUnit = 'hours';
  bool _isNegotiable = false;
  bool _isLoading = false;

  final _categories = [
    ('manual', 'Manual Labour', Icons.construction_rounded, Color(0xFFE8763A)),
    ('professional', 'Professional', Icons.build_circle_outlined, Color(0xFF2D6A6A)),
    ('errands', 'Errands', Icons.delivery_dining_rounded, Color(0xFF7C5CBF)),
    ('digital', 'Digital', Icons.computer_rounded, Color(0xFF2196F3)),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _budgetCtrl.dispose();
    _locationCtrl.dispose(); _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final api = context.read<ApiClient>();
      await api.createJob({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category,
        'budget': double.parse(_budgetCtrl.text.trim()),
        'is_negotiable': _isNegotiable,
        'duration_value': int.parse(_durationCtrl.text.trim()),
        'duration_unit': _durationUnit,
        'latitude': -1.2921,
        'longitude': 36.8219,
        'location_address': _locationCtrl.text.trim(),
        'search_radius_km': 10,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: KaziTheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e'), backgroundColor: KaziTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(KaziSpacing.md),
          children: [
            // Category
            Text('Category', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: KaziSpacing.sm,
              mainAxisSpacing: KaziSpacing.sm,
              childAspectRatio: 3,
              children: _categories.map((cat) {
                final (id, label, icon, color) = cat;
                final isSelected = _category == id;
                return GestureDetector(
                  onTap: () => setState(() => _category = id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.1) : KaziTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : KaziTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: isSelected ? color : KaziTheme.textHint),
                        const SizedBox(width: 8),
                        Expanded(child: Text(label, style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isSelected ? color : KaziTheme.textSecondary,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: KaziSpacing.lg),
            Text('Job Title', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'e.g. Clean 3-bedroom house in Kilimani'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a job title' : null,
            ),

            const SizedBox(height: KaziSpacing.lg),
            Text('Description', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Describe what needs to be done, requirements, tools provided...',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().length < 20 ? 'Add more detail (min 20 characters)' : null,
            ),

            const SizedBox(height: KaziSpacing.lg),
            Text('Location', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Westlands, Nairobi',
                prefixIcon: Icon(Icons.place_outlined, color: KaziTheme.textHint),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter job location' : null,
            ),

            const SizedBox(height: KaziSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget (KES)', style: KaziText.label),
                      const SizedBox(height: KaziSpacing.sm),
                      TextFormField(
                        controller: _budgetCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: '0', prefixText: 'KES '),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter budget';
                          if (int.tryParse(v) == null || int.parse(v) < 100) return 'Min KES 100';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KaziSpacing.md),
                Column(
                  children: [
                    Text(' ', style: KaziText.label),
                    const SizedBox(height: KaziSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isNegotiable,
                            onChanged: (v) => setState(() => _isNegotiable = v ?? false),
                            activeColor: KaziTheme.primary,
                          ),
                          Text('Negotiable', style: KaziText.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: KaziSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration', style: KaziText.label),
                      const SizedBox(height: KaziSpacing.sm),
                      TextFormField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(hintText: '1'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KaziSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit', style: KaziText.label),
                      const SizedBox(height: KaziSpacing.sm),
                      DropdownButtonFormField<String>(
                        value: _durationUnit,
                        style: GoogleFonts.dmSans(fontSize: 14, color: KaziTheme.textPrimary),
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(value: 'hours', child: Text('Hours')),
                          DropdownMenuItem(value: 'days', child: Text('Days')),
                        ],
                        onChanged: (v) => setState(() => _durationUnit = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: KaziSpacing.xxl),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post Job'),
            ),
            const SizedBox(height: KaziSpacing.lg),
          ],
        ),
      ),
    );
  }
}
