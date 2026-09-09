import 'package:app1/Pages/memberInfo.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';

class MemberListerPage extends StatefulWidget {
  final List<Member> members;
  final int sortColumnIndex;
  final bool sortAscending;
  final String groupFilter;

  const MemberListerPage({
    super.key,
    required this.members,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.groupFilter,
  });

  @override
  State<MemberListerPage> createState() => _MemberListerPageState();
}

class _MemberListerPageState extends State<MemberListerPage> {
  List<Member> members = [];
  List<Member> shownMembers = [];

  bool _isLoading = true;
  String? _errorMessage;

  int _sortColumnIndex = 1;
  bool _sortAscending = true;

  late List<DataColumn> _columns;
  late List<DataRow> _rows = [];

  // Filter controllers
  final nameController = TextEditingController();
  final groupController = TextEditingController();
  final numberController = TextEditingController();

  String nameFilter = "";
  String groupFilter = "";
  String numberFilter = "";
  
  // State Filter: null = hepsi kapalı (filtre yok), "in" = İçeride, "out" = Dışarıda
  String? selectedStateFilter;

  @override
  void initState() {
    super.initState();
    _sortColumnIndex = widget.sortColumnIndex;
    _sortAscending = widget.sortAscending;
    groupFilter = widget.groupFilter;
    groupController.text = widget.groupFilter;
    members = widget.members;
    _isLoading = false;

    convertValuesToListItems();
  }

  @override
  void dispose() {
    nameController.dispose();
    groupController.dispose();
    numberController.dispose();
    super.dispose();
  }

  void convertValuesToListItems() {
    applyFilterAndSort(nameFilter, numberFilter, groupFilter, selectedStateFilter);

    _columns = Member.columns(setSortingFields);

    if (_rows.isNotEmpty) {
      _rows.clear();
    }
    AppLogger.instance.log("Shown member number: ${shownMembers.length}");

    for (var member in shownMembers) {
      final state = member.state ?? "Belirlenmemiş";
      final bool isOut = state.toLowerCase() == STATEOUT.toLowerCase();

      _rows.add(
        DataRow(
          color: isOut
              ? WidgetStateProperty.all(Colors.red.withOpacity(0.15))
              : null,
          onSelectChanged: (selected) async {
            if (selected == true) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberInfoPage(
                    pushID: "${member.group}_${member.number}",
                    member: member,
                  ),
                ),
              );
              setState(() {
                convertValuesToListItems();
              });
            }
          },
          cells: [
            DataCell(
              Text(
                member.group,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            DataCell(
              Text(
                member.number.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            DataCell(
              SizedBox(
                width: 150,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    member.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                state.toLowerCase() == STATEIN.toLowerCase()
                    ? "İçeride"
                    : "Dışarıda",
                style: TextStyle(
                  color: isOut ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    _isLoading = false;

    if (mounted) {
      setState(() {});
    }
  }

  void applyFilterAndSort(
      String nameF, String numberF, String groupF, String? stateF) {
    shownMembers = List<Member>.from(members);

    if (nameF.isNotEmpty) {
      shownMembers = shownMembers
          .where((member) => member.name
              .toString()
              .toLowerCase()
              .contains(nameF.toLowerCase()))
          .toList();
    }
    if (groupF.isNotEmpty) {
      shownMembers = shownMembers
          .where((member) => member.group
              .toString()
              .toLowerCase()
              .contains(groupF.toLowerCase()))
          .toList();
    }
    if (numberF.isNotEmpty) {
      shownMembers = shownMembers
          .where((member) =>
              member.number.toString().toLowerCase() == numberF.toLowerCase())
          .toList();
    }
    if (stateF != null && stateF.isNotEmpty) {
      shownMembers = shownMembers
          .where((member) => (member.state ?? '')
              .toLowerCase()
              .contains(stateF.toLowerCase()))
          .toList();
    }

    switch (_sortColumnIndex) {
      case 0:
        shownMembers.sort((a, b) => _sortAscending
            ? a.group.toLowerCase().compareTo(b.group.toLowerCase())
            : b.group.toLowerCase().compareTo(a.group.toLowerCase()));
        break;
      case 1:
        shownMembers.sort((a, b) => _sortAscending
            ? a.number.compareTo(b.number)
            : b.number.compareTo(a.number));
        break;
      case 2:
        shownMembers.sort((a, b) => _sortAscending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 3:
        shownMembers.sort((a, b) => _sortAscending
            ? (a.state ?? '')
                .toLowerCase()
                .compareTo((b.state ?? '').toLowerCase())
            : (b.state ?? '')
                .toLowerCase()
                .compareTo((a.state ?? '').toLowerCase()));
        break;
    }
  }

  void setSortingFields(int sortingColumnIndex, bool sortAscending) {
    setState(() {
      _sortColumnIndex = sortingColumnIndex;
      _sortAscending = sortAscending;
      convertValuesToListItems();
    });
    AppLogger.instance.warn(
        "Tapped! index: $sortingColumnIndex, ascending: $sortAscending");
  }

  Widget drawtable() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: GlassTheme.cyan,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: GlassTheme.textSecondary,
                size: 32,
              ),
              SizedBox(height: 12),
              Text(
                'Gösterilecek üye bulunamadı.',
                style: TextStyle(
                  color: GlassTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          showCheckboxColumn: false,
          headingRowHeight: 42,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 58,
          columnSpacing: 28,
          horizontalMargin: 12,
          dividerThickness: 0.3,
          headingTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          dataTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          headingRowColor: WidgetStateProperty.all(
            Colors.white.withOpacity(0.035),
          ),
          columns: _columns,
          rows: _rows,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
      floatingLabelStyle: const TextStyle(
        color: GlassTheme.cyan,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: Colors.white70,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.11),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
          color: GlassTheme.cyan,
          width: 1.1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
    );
  }

  Widget _buildFilterField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        cursorColor: GlassTheme.cyan,
        decoration: _inputDecoration(
          label,
          icon,
        ),
      ),
    );
  }

  Widget _buildStateFilterButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum Filtresi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildStateOptionButton(
                  label: 'İçeride',
                  value: STATEIN,
                  activeColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStateOptionButton(
                  label: 'Dışarıda',
                  value: STATEOUT,
                  activeColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateOptionButton({
    required String label,
    required String value,
    required Color activeColor,
  }) {
    final bool isSelected = selectedStateFilter?.toLowerCase() == value.toLowerCase();

    return SizedBox(
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.025),
          side: BorderSide(
            color: isSelected
                ? activeColor
                : Colors.white.withOpacity(0.11),
            width: isSelected ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: () {
          setState(() {
            if (isSelected) {
              selectedStateFilter = null; // Tekrar basılırsa kapatır (filtre yok)
            } else {
              selectedStateFilter = value; // Sadece basılan seçili olur
            }
            convertValuesToListItems();
          });
        },
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Filtreler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        _buildFilterField(
          label: 'Numaraya Göre',
          icon: Icons.tag_rounded,
          controller: numberController,
          onChanged: (value) {
            setState(() {
              numberFilter = value;
              convertValuesToListItems();
            });
          },
        ),
        _buildFilterField(
          label: 'Gruba Göre',
          icon: Icons.groups_rounded,
          controller: groupController,
          onChanged: (value) {
            setState(() {
              groupFilter = value;
              convertValuesToListItems();
            });
          },
        ),
        _buildFilterField(
          label: 'İsme Göre',
          icon: Icons.person_rounded,
          controller: nameController,
          onChanged: (value) {
            setState(() {
              nameFilter = value;
              convertValuesToListItems();
            });
          },
        ),
        _buildStateFilterButtons(),
        const SizedBox(height: 8),
        _GlassActionButton(
          icon: Icons.filter_alt_off_rounded,
          label: 'Filtreleri Temizle',
          onPressed: () {
            groupController.clear();
            numberController.clear();
            nameController.clear();
            setState(() {
              groupFilter = "";
              numberFilter = "";
              nameFilter = "";
              selectedStateFilter = null; // Buton seçimleri sıfırlandı
              convertValuesToListItems();
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterSidebar() {
    return GlassPanel(
      title: 'Filtre Paneli',
      icon: Icons.tune_rounded,
      child: _buildFilterPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Üye Listesi',
                            style: TextStyle(
                              color: GlassTheme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kayıtlı üyelerin listesi ve durumları',
                            style: TextStyle(
                              color: GlassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.045),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            size: 15,
                            color: GlassTheme.cyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${shownMembers.length} kayıt',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // CONTENT
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: drawtable(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildFilterSidebar(),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          GlassPanel(
                            title: 'Filtre Paneli',
                            icon: Icons.tune_rounded,
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              collapsedIconColor: Colors.white54,
                              iconColor: GlassTheme.cyan,
                              title: const Text(
                                'Filtreleri Göster',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                _buildFilterPanel(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: drawtable(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: GlassTheme.cyan.withOpacity(0.10),
          foregroundColor: GlassTheme.cyan,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: GlassTheme.cyan.withOpacity(0.20),
            ),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}