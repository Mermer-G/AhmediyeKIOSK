import 'package:app1/Pages/entryInfo.dart';
import 'package:app1/Pages/settings.dart';
import 'package:app1/Pages/memberList.dart';
import 'package:app1/Theme/dashboard_theme.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:app1/utils/debugger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class entryListerPage extends StatefulWidget {
  const entryListerPage({super.key});

  @override
  State<entryListerPage> createState() => _entryListerPageState();
}

class _entryListerPageState extends State<entryListerPage> {
  List<Entry> entries = [];
  List<Entry> shownEntries = [];

  bool _isLoading = false;
  String? _errorMessage;

  int _sortColumnIndex = 2;
  bool _sortAscending = false;

  late List<DataColumn> _columns;
  List<DataRow> _rows = [];

  final TextEditingController groupController =
      TextEditingController();

  final TextEditingController numberController =
      TextEditingController();

  final TextEditingController exitTimeController =
      TextEditingController();

  final TextEditingController loadAmountController =
      TextEditingController();

  String groupFilter = "";
  String numberFilter = "";
  String exitTimeFilter = "";

  int loadAmount = 50;
  int loadedDataAmount = 0;

  @override
  void initState() {
    super.initState();

    loadAmountController.text = loadAmount.toString();

    _fetchDataFromHive();
  }

  @override
  void dispose() {
    groupController.dispose();
    numberController.dispose();
    exitTimeController.dispose();
    loadAmountController.dispose();

    super.dispose();
  }

  Future<void> _fetchDataFromHive() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final box = Hive.box(entryBox);

      final keys = box.keys.toList();

      keys.sort((a, b) {
        final aInt = int.tryParse(a.toString()) ?? 0;
        final bInt = int.tryParse(b.toString()) ?? 0;

        return bInt.compareTo(aInt);
      });

      final selectedKeys =
          keys.take(loadAmount).toList();

      final List<Entry> loadedEntries = [];

      for (final key in selectedKeys) {
        final value = box.get(key);

        if (value != null) {
          loadedEntries.add(
            Entry.fromMap(
              Map<dynamic, dynamic>.from(value),
            ),
          );
        }
      }

      setState(() {
        entries = loadedEntries;
        loadedDataAmount = loadedEntries.length;
        _isLoading = false;
      });

      convertValuesToListItems();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Entry> parseToEntries(List<dynamic> values) {
    final List<Entry> result = [];

    for (final value in values) {
      if (value != null) {
        result.add(
          Entry.fromMap(
            Map<dynamic, dynamic>.from(value),
          ),
        );
      }
    }

    return result;
  }

  void convertValuesToListItems() {
    applyFilterAndSort(
      numberFilter,
      groupFilter,
      exitTimeFilter,
    );

    _columns = Entry.columns(
      setSortingFields,
    );

    _rows = shownEntries.map((entry) {
      Color? rowColor;

      if (entry.entryTime ==
          "Daha giriş yapılmamış") {
        rowColor = Colors.red.withOpacity(1);
      }

      return DataRow(
        color: rowColor == null
            ? null
            : WidgetStateProperty.all(rowColor),
        cells: [
          DataCell(
            Text(
              entry.group.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          DataCell(
            Text(
              entry.number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          DataCell(
            Text(
              formatDateTime(
                DateTime.tryParse(
                      entry.exitTime.toString(),
                    ) ??
                    DateTime.now(),
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
        onSelectChanged: (_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EntryInfoPage(entry: entry),
            ),
          );
        },
      );
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  void setAmountAndReload() {
    final value =
        int.tryParse(loadAmountController.text);

    if (value == null || value <= 0) {
      return;
    }

    loadAmount = value;

    _fetchDataFromHive();
  }

  void applyFilterAndSort(
    String numberF,
    String groupF,
    String exitTimeF,
  ) {
    shownEntries = List<Entry>.from(entries);

    if (groupF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) {
        return entry.group
            .toString()
            .toLowerCase()
            .contains(groupF.toLowerCase());
      }).toList();
    }

    if (numberF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) {
        return entry.number
            .toString()
            .toLowerCase()
            .contains(numberF.toLowerCase());
      }).toList();
    }

    if (exitTimeF.isNotEmpty) {
      shownEntries = shownEntries.where((entry) {
        return entry.exitTime
            .toString()
            .toLowerCase()
            .contains(exitTimeF.toLowerCase());
      }).toList();
    }

    shownEntries.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a.group;
          bValue = b.group;
          break;

        case 1:
          aValue = a.number;
          bValue = b.number;
          break;

        case 2:
          aValue = a.exitTime;
          bValue = b.exitTime;
          break;

        default:
          return 0;
      }

      int result;

      if (aValue is num && bValue is num) {
        result = aValue.compareTo(bValue);
      } else {
        result = aValue
            .toString()
            .compareTo(bValue.toString());
      }

      return _sortAscending ? result : -result;
    });
  }

  void setSortingFields(
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      convertValuesToListItems();
    });
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
                'Gösterilecek kayıt bulunamadı.',
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
          headingRowColor:
              WidgetStateProperty.all(
            Colors.white.withOpacity(0.035),
          ),
          columns: _columns,
          rows: _rows,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
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

  Widget _buildDateFilterField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          surface: Color(0xFF101827),
                          primary: GlassTheme.cyan,
                          onPrimary: Colors.black,
                          onSurface: Colors.white,
                        ),
                        datePickerTheme:
                            DatePickerThemeData(
                          backgroundColor:
                              const Color(0xFF101827),
                          headerBackgroundColor:
                              const Color(0xFF101827),
                          headerForegroundColor:
                              Colors.white,
                          surfaceTintColor:
                              Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.white
                                  .withOpacity(0.10),
                            ),
                          ),
                          dayForegroundColor:
                              WidgetStateProperty.all(
                            Colors.white,
                          ),
                          weekdayStyle:
                              const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          dayStyle:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          todayForegroundColor:
                              WidgetStateProperty.all(
                            GlassTheme.cyan,
                          ),
                          todayBackgroundColor:
                              WidgetStateProperty.all(
                            GlassTheme.cyan
                                .withOpacity(0.10),
                          ),
                          yearStyle:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked == null) return;

                final formatted =
                  '${picked.year}-'
                  '${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}';

                setState(() {
                  exitTimeFilter = formatted;
                  exitTimeController.text = formatted;
                  convertValuesToListItems();
                });
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.025),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.11),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        exitTimeController.text.isEmpty
                            ? 'Çıkış tarihi'
                            : exitTimeController.text,
                        style: TextStyle(
                          color: exitTimeController
                                  .text.isEmpty
                              ? Colors.white70
                              : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (exitTimeController.text.isNotEmpty) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () {
                setState(() {
                  exitTimeController.clear();
                  exitTimeFilter = "";
                  convertValuesToListItems();
                });
              },
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white54,
              ),
            ),
          ],
        ],
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

  Widget _buildFilterPanel() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
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
          label: 'Grouba göre',
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
          label: 'Numaraya göre',
          icon: Icons.tag_rounded,
          controller: numberController,
          onChanged: (value) {
            setState(() {
              numberFilter = value;
              convertValuesToListItems();
            });
          },
        ),

        _buildDateFilterField(),

        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: _buildFilterField(
                label: 'Kayıt miktarı',
                icon: Icons.format_list_numbered_rounded,
                controller: loadAmountController,
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 12),
              child: _GlassActionButton(
                icon: Icons.refresh_rounded,
                label: 'Yükle',
                onPressed: setAmountAndReload,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            const Icon(
              Icons.storage_rounded,
              size: 15,
              color: Colors.white54,
            ),
            const SizedBox(width: 7),
            Text(
              '$loadedDataAmount kayıt yüklendi',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _GlassActionButton(
          icon: Icons.filter_alt_off_rounded,
          label: 'Filtreleri Temizle',
          onPressed: () {
            setState(() {
              groupController.clear();
              numberController.clear();
              exitTimeController.clear();

              groupFilter = "";
              numberFilter = "";
              exitTimeFilter = "";

              convertValuesToListItems();
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterSidebar() {
    return GlassPanel(
      title: 'Filtre ve Veri',
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
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color:
                            GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giriş - Çıkış Listesi',
                            style: TextStyle(
                              color: GlassTheme
                                  .textPrimary,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Geçmiş giriş ve çıkış kayıtları',
                            style: TextStyle(
                              color: GlassTheme
                                  .textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.045),
                        borderRadius:
                            BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white
                              .withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            size: 15,
                            color:
                                GlassTheme.cyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$loadedDataAmount kayıt',
                            style:
                                const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
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
                    builder:
                        (context, constraints) {
                      final wide =
                          constraints.maxWidth >=
                              900;

                      if (wide) {
                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: drawtable(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              flex: 3,
                              child:
                                  _buildFilterSidebar(),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          GlassPanel(
                            title:
                                'Filtre ve Veri',
                            icon:
                                Icons.tune_rounded,
                            child:
                                ExpansionTile(
                              tilePadding:
                                  EdgeInsets.zero,
                              collapsedIconColor:
                                  Colors.white54,
                              iconColor:
                                  GlassTheme.cyan,
                              title:
                                  const Text(
                                'Filtreleri Göster',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              children: [
                                _buildFilterPanel(),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: drawtable(),
                              ),
                            ),
                          )
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

class _GlassActionButton
    extends StatelessWidget {
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
          backgroundColor:
              GlassTheme.cyan.withOpacity(0.10),
          foregroundColor:
              GlassTheme.cyan,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
            side: BorderSide(
              color: GlassTheme.cyan
                  .withOpacity(0.20),
            ),
          ),
        ),
        icon: Icon(
          icon,
          size: 16,
        ),
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