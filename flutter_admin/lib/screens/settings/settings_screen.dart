// ============================================================================
//  screens/settings/settings_screen.dart
//  FIX: replaced file_picker (FilePicker.platform error) with image_picker
//       image_picker is already in your project and works on web + emulator
// ============================================================================
 
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';   // ← already in your project
import '../../models/settings_model.dart';
import '../../services/settings_service.dart';
 
// ── Palette ───────────────────────────────────────────────────────────────────
const _bg         = Color(0xFFF5F0EA);
const _border     = Color(0xFFE8E0D8);
const _muted      = Color(0xFF6B6560);
const _dark       = Color(0xFF1A1A1A);
const _inputBg    = Color(0xFFFDFCFA);
const _saveBtnClr = Color(0xFF2D2B27);
const _roFieldBg  = Color(0xFFF5F0EA);
const _editBadge  = Color(0xFFF5EAE5);
 
// ── SettingsScreen ────────────────────────────────────────────────────────────
 
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
 
class _SettingsScreenState extends State<SettingsScreen> {
  final _svc     = SettingsService();
  final _picker  = ImagePicker();           // ← image_picker instance
  SettingsModel _s = SettingsModel.empty();
  bool _loading  = true;
  String? _error;
 
  // Which section is in edit mode — only one at a time
  String? _editing;  // 'appInfo' | 'contact' | 'social' | 'footer' | 'contactUs' | null
 
  final Map<String, bool> _saving = {
    'appInfo': false, 'contact': false, 'social': false,
    'footer': false,  'contactUs': false,
  };
 
  // ── Controllers ──────────────────────────────────────────────────────────
  final _appName   = TextEditingController();
  final _suppEmail = TextEditingController();
  final _suppPhone = TextEditingController();
  final _whatsapp  = TextEditingController();
  final _website   = TextEditingController();
  final _facebook  = TextEditingController();
  final _instagram = TextEditingController();
  final _twitter   = TextEditingController();
  final _youtube   = TextEditingController();
  final _linkedin  = TextEditingController();
  final _company   = TextEditingController();
  final _copyright = TextEditingController();
  final _privacy   = TextEditingController();
  final _terms     = TextEditingController();
  final _address   = TextEditingController();
  final _conEmail  = TextEditingController();
  final _conPhone  = TextEditingController();
  final _hours     = TextEditingController();
 
  // ── Image bytes — XFile.readAsBytes() works on web + emulator ────────────
  Uint8List? _logoBytes;    String? _logoName;
  Uint8List? _faviconBytes; String? _faviconName;
 
  @override
  void initState() { super.initState(); _load(); }
 
  @override
  void dispose() {
    for (final c in [
      _appName, _suppEmail, _suppPhone, _whatsapp, _website,
      _facebook, _instagram, _twitter, _youtube, _linkedin,
      _company, _copyright, _privacy, _terms,
      _address, _conEmail, _conPhone, _hours,
    ]) { c.dispose(); }
    super.dispose();
  }
 
  // ── Load settings ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _svc.getSettings();
      if (mounted) setState(() { _s = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }
 
  // ── Fill controllers ──────────────────────────────────────────────────────
  void _fill(SettingsModel s) {
    _appName.text   = s.appName;
    _suppEmail.text = s.supportEmail      ?? '';
    _suppPhone.text = s.supportPhone      ?? '';
    _whatsapp.text  = s.whatsappNumber    ?? '';
    _website.text   = s.websiteUrl        ?? '';
    _facebook.text  = s.facebookUrl       ?? '';
    _instagram.text = s.instagramUrl      ?? '';
    _twitter.text   = s.twitterUrl        ?? '';
    _youtube.text   = s.youtubeUrl        ?? '';
    _linkedin.text  = s.linkedinUrl       ?? '';
    _company.text   = s.companyName       ?? '';
    _copyright.text = s.copyrightText     ?? '';
    _privacy.text   = s.privacyPolicyLink ?? '';
    _terms.text     = s.termsLink         ?? '';
    _address.text   = s.officeAddress     ?? '';
    _conEmail.text  = s.contactEmail      ?? '';
    _conPhone.text  = s.contactPhone      ?? '';
    _hours.text     = s.workingHours      ?? '';
  }
 
  // ── Edit / Cancel ─────────────────────────────────────────────────────────
  void _startEdit(String section) {
    _fill(_s);
    setState(() {
      _editing      = section;
      _logoBytes    = null; _logoName    = null;
      _faviconBytes = null; _faviconName = null;
    });
  }
 
  void _cancelEdit() =>
      setState(() { _editing = null; _logoBytes = null; _faviconBytes = null; });
 
  // ── Image pickers — image_picker works on web + emulator ─────────────────
  Future<void> _pickLogo() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();   // no dart:io needed
    setState(() { _logoBytes = bytes; _logoName = xfile.name; });
  }
 
  Future<void> _pickFavicon() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _faviconBytes = bytes; _faviconName = xfile.name; });
  }
 
  // ── Save handlers ─────────────────────────────────────────────────────────
 
  Future<void> _saveAppInfo() async {
    setState(() => _saving['appInfo'] = true);
    try {
      var updated = _s.copyWith(appName: _appName.text.trim());
      if (_logoBytes    != null && _logoName    != null) {
        final url = await _svc.uploadLogo(_logoBytes!, _logoName!);
        updated = updated.copyWith(appLogo: url);
      }
      if (_faviconBytes != null && _faviconName != null) {
        final url = await _svc.uploadFavicon(_faviconBytes!, _faviconName!);
        updated = updated.copyWith(faviconUrl: url);
      }
      final saved = await _svc.updateAppInfo(updated);
      setState(() { _s = saved; _editing = null; _logoBytes = null; _faviconBytes = null; });
      _snack('Application info saved');
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving['appInfo'] = false);
    }
  }
 
  Future<void> _saveContact() async {
    setState(() => _saving['contact'] = true);
    try {
      final saved = await _svc.updateContact(_s.copyWith(
        supportEmail: _suppEmail.text.trim(), supportPhone: _suppPhone.text.trim(),
        whatsappNumber: _whatsapp.text.trim(), websiteUrl: _website.text.trim(),
      ));
      setState(() { _s = saved; _editing = null; });
      _snack('Contact info saved');
    } catch (e) { _snack(e.toString(), error: true);
    } finally { if (mounted) setState(() => _saving['contact'] = false); }
  }
 
  Future<void> _saveSocial() async {
    setState(() => _saving['social'] = true);
    try {
      final saved = await _svc.updateSocial(_s.copyWith(
        facebookUrl: _facebook.text.trim(), instagramUrl: _instagram.text.trim(),
        twitterUrl: _twitter.text.trim(), youtubeUrl: _youtube.text.trim(),
        linkedinUrl: _linkedin.text.trim(),
      ));
      setState(() { _s = saved; _editing = null; });
      _snack('Social links saved');
    } catch (e) { _snack(e.toString(), error: true);
    } finally { if (mounted) setState(() => _saving['social'] = false); }
  }
 
  Future<void> _saveFooter() async {
    setState(() => _saving['footer'] = true);
    try {
      final saved = await _svc.updateFooter(_s.copyWith(
        companyName: _company.text.trim(), copyrightText: _copyright.text.trim(),
        privacyPolicyLink: _privacy.text.trim(), termsLink: _terms.text.trim(),
      ));
      setState(() { _s = saved; _editing = null; });
      _snack('Footer info saved');
    } catch (e) { _snack(e.toString(), error: true);
    } finally { if (mounted) setState(() => _saving['footer'] = false); }
  }
 
  Future<void> _saveContactUs() async {
    setState(() => _saving['contactUs'] = true);
    try {
      final saved = await _svc.updateContactUs(_s.copyWith(
        officeAddress: _address.text.trim(), contactEmail: _conEmail.text.trim(),
        contactPhone: _conPhone.text.trim(), workingHours: _hours.text.trim(),
      ));
      setState(() { _s = saved; _editing = null; });
      _snack('Contact Us details saved');
    } catch (e) { _snack(e.toString(), error: true);
    } finally { if (mounted) setState(() => _saving['contactUs'] = false); }
  }
 
  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : _saveBtnClr,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
 
  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _saveBtnClr, strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: _saveBtnClr),
            child: const Text('Retry'),
          ),
        ])),
      );
    }
 
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('General settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _dark)),
            const SizedBox(height: 20),
            _buildAppInfoCard(),
            const SizedBox(height: 14),
            _buildContactCard(),
            const SizedBox(height: 14),
            _buildSocialCard(),
            const SizedBox(height: 14),
            _buildFooterCard(),
            const SizedBox(height: 14),
            _buildContactUsCard(),
          ],
        ),
      ),
    );
  }
 
  // ── Section 1.1 ───────────────────────────────────────────────────────────
  Widget _buildAppInfoCard() {
    final isEdit = _editing == 'appInfo';
    return _SectionCard(
      icon: Icons.phone_android, iconBg: const Color(0xFFE8E0D8), iconColor: const Color(0xFF444441),
      title: 'Application information',
      isEditing: isEdit, isSaving: _saving['appInfo']!,
      onEdit: () => _startEdit('appInfo'), onCancel: _cancelEdit, onSave: _saveAppInfo,
      viewContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _viewRow('Application name', _s.appName),
        _viewImageRow('Logo',    _s.appLogo),
        _viewImageRow('Favicon', _s.faviconUrl),
        _viewRow('Version', _s.appVersion),
      ]),
      editContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field('Application name', _appName),
        const SizedBox(height: 12),
        _twoCol(
          _imgUpload('Application logo', 'PNG or SVG · 200×60px',
              _logoBytes, _logoName, _s.appLogo, _pickLogo),
          _imgUpload('Favicon (website icon)', 'ICO or PNG · 32×32px',
              _faviconBytes, _faviconName, _s.faviconUrl, _pickFavicon),
        ),
        const SizedBox(height: 12),
        _readOnlyField('Application version', _s.appVersion),
      ]),
    );
  }
 
  // ── Section 1.2 ───────────────────────────────────────────────────────────
  Widget _buildContactCard() {
    final isEdit = _editing == 'contact';
    return _SectionCard(
      icon: Icons.phone, iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF0C447C),
      title: 'Contact information',
      isEditing: isEdit, isSaving: _saving['contact']!,
      onEdit: () => _startEdit('contact'), onCancel: _cancelEdit, onSave: _saveContact,
      viewContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _twoCol(_viewRow('Support email', _s.supportEmail), _viewRow('Support phone', _s.supportPhone)),
        const SizedBox(height: 8),
        _twoCol(_viewRow('WhatsApp', _s.whatsappNumber), _viewRow('Website URL', _s.websiteUrl)),
      ]),
      editContent: Column(children: [
        _twoCol(
          _field('Support email',  _suppEmail, type: TextInputType.emailAddress),
          _field('Support phone',  _suppPhone, type: TextInputType.phone),
        ),
        const SizedBox(height: 12),
        _twoCol(
          _field('WhatsApp number', _whatsapp, type: TextInputType.phone),
          _field('Website URL',     _website,  type: TextInputType.url),
        ),
      ]),
    );
  }
 
  // ── Section 1.3 ───────────────────────────────────────────────────────────
  Widget _buildSocialCard() {
    final isEdit = _editing == 'social';
    return _SectionCard(
      icon: Icons.share, iconBg: const Color(0xFFEEEDFE), iconColor: const Color(0xFF3C3489),
      title: 'Social media links', badge: 'Optional',
      isEditing: isEdit, isSaving: _saving['social']!,
      onEdit: () => _startEdit('social'), onCancel: _cancelEdit, onSave: _saveSocial,
      viewContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _viewRow('Facebook',    _s.facebookUrl),
        _viewRow('Instagram',   _s.instagramUrl),
        _viewRow('X (Twitter)', _s.twitterUrl),
        _viewRow('YouTube',     _s.youtubeUrl),
        _viewRow('LinkedIn',    _s.linkedinUrl),
      ]),
      editContent: Column(children: [
        _socialRow(Icons.facebook,        const Color(0xFFE6F1FB), const Color(0xFF0C447C), _facebook,  'https://facebook.com/thiraa'),
        _socialRow(Icons.camera_alt,      const Color(0xFFFBEAF0), const Color(0xFF72243E), _instagram, 'https://instagram.com/thiraa'),
        _socialRow(Icons.close,           const Color(0xFFF1EFE8), const Color(0xFF444441), _twitter,   'https://x.com/thiraa'),
        _socialRow(Icons.play_arrow,      const Color(0xFFFCEBEB), const Color(0xFFA32D2D), _youtube,   'https://youtube.com/@thiraa'),
        _socialRow(Icons.business_center, const Color(0xFFE6F1FB), const Color(0xFF0C447C), _linkedin,  'https://linkedin.com/company/thiraa'),
      ]),
    );
  }
 
  // ── Section 1.4 ───────────────────────────────────────────────────────────
  Widget _buildFooterCard() {
    final isEdit = _editing == 'footer';
    return _SectionCard(
      icon: Icons.view_agenda_outlined, iconBg: const Color(0xFFEAF3DE), iconColor: const Color(0xFF27500A),
      title: 'Footer information',
      isEditing: isEdit, isSaving: _saving['footer']!,
      onEdit: () => _startEdit('footer'), onCancel: _cancelEdit, onSave: _saveFooter,
      viewContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _twoCol(_viewRow('Company name', _s.companyName), _viewRow('Copyright text', _s.copyrightText)),
        const SizedBox(height: 8),
        _twoCol(_viewRow('Privacy policy', _s.privacyPolicyLink), _viewRow('Terms link', _s.termsLink)),
        const SizedBox(height: 12),
        _footerPreview(_s.copyrightText),
      ]),
      editContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _twoCol(_field('Company name', _company), _field('Copyright text', _copyright)),
        const SizedBox(height: 12),
        _twoCol(
          _field('Privacy policy link',       _privacy, type: TextInputType.url),
          _field('Terms and conditions link', _terms,   type: TextInputType.url),
        ),
        const SizedBox(height: 14),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 12),
        const Text('FOOTER PREVIEW',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _muted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _copyright,
          builder: (_, __) => _footerPreview(_copyright.text.isNotEmpty ? _copyright.text : null),
        ),
      ]),
    );
  }
 
  // ── Section 1.5 ───────────────────────────────────────────────────────────
  Widget _buildContactUsCard() {
    final isEdit = _editing == 'contactUs';
    return _SectionCard(
      icon: Icons.location_on_outlined, iconBg: const Color(0xFFFAEEDA), iconColor: const Color(0xFF633806),
      title: 'Contact us details',
      isEditing: isEdit, isSaving: _saving['contactUs']!,
      onEdit: () => _startEdit('contactUs'), onCancel: _cancelEdit, onSave: _saveContactUs,
      viewContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _viewRow('Office address', _s.officeAddress),
        const SizedBox(height: 8),
        _twoCol(_viewRow('Email', _s.contactEmail), _viewRow('Phone number', _s.contactPhone)),
        _viewRow('Working hours', _s.workingHours),
      ]),
      editContent: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field('Office address', _address),
        const SizedBox(height: 12),
        _twoCol(
          _field('Email',        _conEmail, type: TextInputType.emailAddress),
          _field('Phone number', _conPhone, type: TextInputType.phone),
        ),
        const SizedBox(height: 12),
        _field('Working hours', _hours),
      ]),
    );
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  //  SHARED SMALL WIDGETS
  // ─────────────────────────────────────────────────────────────────────────
 
  Widget _viewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(builder: (_, c) {
        if (c.maxWidth < 400) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
            const SizedBox(height: 2),
            Text(value?.isNotEmpty == true ? value! : '—',
                style: const TextStyle(fontSize: 13, color: _dark)),
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 150,
              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted))),
          Expanded(
              child: Text(value?.isNotEmpty == true ? value! : '—',
                  style: const TextStyle(fontSize: 12, color: _dark))),
        ]);
      }),
    );
  }
 
  Widget _viewImageRow(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 150,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted))),
        if (url != null && url.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(url, width: 36, height: 36, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.broken_image, size: 14, color: _muted),
              )),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(url.split('/').last,
              style: const TextStyle(fontSize: 11, color: _muted), overflow: TextOverflow.ellipsis)),
        ] else
          const Text('Not uploaded', style: TextStyle(fontSize: 12, color: _muted)),
      ]),
    );
  }
 
  Widget _twoCol(Widget left, Widget right) {
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth < 560) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 12), right]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: left), const SizedBox(width: 14), Expanded(child: right),
      ]);
    });
  }
 
  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl, keyboardType: type,
        style: const TextStyle(fontSize: 12, color: _dark),
        decoration: InputDecoration(
          isDense: true, filled: true, fillColor: _inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _border, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _border, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _dark, width: 1)),
        ),
      ),
    ]);
  }
 
  Widget _readOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: _editBadge, borderRadius: BorderRadius.circular(10)),
          child: const Text('Read only',
              style: TextStyle(fontSize: 9, color: Color(0xFF7A3D2A), fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 5),
      Container(
        height: 36, alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: _roFieldBg, border: Border.all(color: _border, width: 0.5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(value, style: const TextStyle(fontSize: 12, color: _muted)),
      ),
    ]);
  }
 
  Widget _imgUpload(String label, String hint,
      Uint8List? localBytes, String? localName, String? networkUrl, VoidCallback onTap) {
    final hasLocal   = localBytes != null && localName != null;
    final hasNetwork = networkUrl != null && networkUrl.isNotEmpty;
    final name = hasLocal ? localName! : (hasNetwork ? networkUrl.split('/').last : 'No file uploaded');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
      const SizedBox(height: 5),
      InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 58, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAF8),
            border: Border.all(color: const Color(0xFFC8BFB5), width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(6)),
              clipBehavior: Clip.hardEdge,
              child: hasLocal
                  ? Image.memory(localBytes, fit: BoxFit.cover)
                  : (hasNetwork
                      ? Image.network(networkUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 16, color: _muted))
                      : const Icon(Icons.image_outlined, size: 18, color: _muted)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, color: _dark), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(hint, style: const TextStyle(fontSize: 10, color: _muted)),
              ],
            )),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.upload, size: 13, color: _muted),
              label: const Text('Replace', style: TextStyle(fontSize: 11, color: _muted)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border, width: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
 
  Widget _socialRow(IconData icon, Color bg, Color fg,
      TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 15, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
            isDense: true, hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: _muted),
            filled: true, fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _border, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: _dark, width: 1)),
          ),
        )),
      ]),
    );
  }
 
  Widget _footerPreview(String? copyright) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bg, border: Border.all(color: _border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: copyright?.isNotEmpty == true ? copyright! : '© 2026 Company. All Rights Reserved.',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _dark),
        ),
        const TextSpan(
          text: '   ·   Privacy policy   ·   Terms and conditions',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
      ])),
    );
  }
}
 
// ============================================================================
//  _SectionCard — Edit button in header, view/edit body, Save/Cancel footer
// ============================================================================
 
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.isEditing, required this.isSaving,
    required this.onEdit, required this.onCancel, required this.onSave,
    required this.viewContent, required this.editContent, this.badge,
  });
 
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   title;
  final String?  badge;
  final bool     isEditing, isSaving;
  final VoidCallback onEdit, onCancel;
  final Future<void> Function() onSave;
  final Widget   viewContent, editContent;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border, width: 0.5))),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Row(children: [
              Flexible(child: Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _dark),
                  overflow: TextOverflow.ellipsis)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(badge!, style: const TextStyle(fontSize: 10, color: _muted)),
                ),
              ],
            ])),
            // Edit button — only in view mode
            if (!isEditing)
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border, width: 0.5),
                  foregroundColor: _muted,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
              ),
          ]),
        ),
 
        // Body
        Padding(
          padding: const EdgeInsets.all(18),
          child: isEditing ? editContent : viewContent,
        ),
 
        // Footer — Cancel + Save (edit mode only)
        if (isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border, width: 0.5))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _border, width: 0.5),
                  foregroundColor: _muted,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saveBtnClr, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
      ]),
    );
  }
}