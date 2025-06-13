import 'dart:async';
import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';
import '../../../core/widgets/league_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with TickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<LeaderboardEntry> _allEntries = [];
  List<LeaderboardEntry> _filteredEntries = [];
  bool _isLoading = true;
  String? _error;
  League? _selectedLeague;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  late TabController _tabController;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initAuthAndLoadLeaderboard();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAuthAndLoadLeaderboard() async {
    final token = await _authService.getAccessToken();
    setState(() {
      _accessToken = token;
    });
    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      setState(() {
        _error = 'Требуется заголовок c access token';
        _isLoading = false;
      });
      return;
    }
    try {
      final leaderboard = await _leaderboardService.getLeaderboard(_accessToken);
      leaderboard.sort((a, b) => b.xpPoints.compareTo(a.xpPoints));
      setState(() {
        _allEntries = leaderboard;
        _filteredEntries = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _applyFilters();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    if (_accessToken == null || _accessToken!.isEmpty) {
      setState(() {
        _error = 'Требуется заголовок c access token';
      });
      return;
    }
    try {
      final results = await _leaderboardService.searchPlayers(query, _accessToken);
      results.sort((a, b) => b.xpPoints.compareTo(a.xpPoints));
      if (mounted) {
        setState(() {
          _filteredEntries = _selectedLeague != null 
              ? _leaderboardService.filterByLeague(results, _selectedLeague)
              : results;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      final filtered = _selectedLeague != null 
          ? _leaderboardService.filterByLeague(_allEntries, _selectedLeague)
          : _allEntries;
      filtered.sort((a, b) => b.xpPoints.compareTo(a.xpPoints));
      _filteredEntries = filtered;
    });
  }

  void _onLeagueSelected(League? league) {
    setState(() {
      _selectedLeague = league;
      if (_isSearching) {
        _performSearch(_searchController.text);
      } else {
        _applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        
        final routes = {
          0: '/main',
          1: '/leaderboard',
          2: '/practice',
          3: '/profile',
        };
        
        if (routes.containsKey(index)) {
          Navigator.pushReplacementNamed(context, routes[index]!);
        }
      },
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildLeagueTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: const Color(0xFFFFC800),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Таблица лидеров',
                          style: TextStyle(
                            color: const Color(0xFF2D3748),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Соревнуйтесь за первое место',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6B73FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showLeagueStats,
                icon: Icon(
                  Icons.analytics,
                  color: const Color(0xFF6B73FF),
                  size: 24,
                ),
                tooltip: 'Статистика лиг',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeagueStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        
        final headerHeight = 30.0; 
        final headerSpacing = 16.0; 
        final leagueCardHeight = 82.0; 
        final leagueSpacing = 12.0; 
        final containerPadding = 32.0; 
        final handleHeight = 28.0; 
        
        final totalLeagues = League.values.length;
        final estimatedContentHeight = handleHeight + 
                                     containerPadding + 
                                     headerHeight + 
                                     headerSpacing + 
                                     (totalLeagues * leagueCardHeight) + 
                                     ((totalLeagues - 1) * leagueSpacing);
        
        final maxHeight = screenHeight > 800 ? screenHeight * 0.6 : screenHeight * 0.5;
        
        final modalHeight = estimatedContentHeight.clamp(200.0, maxHeight);
        
        return Container(
          height: modalHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Статистика лиг',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildLeagueStatsCards(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Поиск игроков...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B73FF)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useIcons = constraints.maxWidth < 400;
          
          return TabBar(
            controller: _tabController,
            onTap: (index) {
              final leagues = [null, League.gold, League.silver, League.bronze, League.none];
              _onLeagueSelected(leagues[index]);
            },
            tabs: [
              Tab(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: FittedBox(
                      key: ValueKey('all_$useIcons'),
                      fit: BoxFit.scaleDown,
                      child: Text(useIcons ? 'All' : 'Все', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: useIcons 
                      ? Icon(Icons.emoji_events, key: ValueKey('gold_icon'), size: 20, color: const Color(0xFFFFC800))
                      : FittedBox(
                          key: ValueKey('gold_text'),
                          fit: BoxFit.scaleDown,
                          child: Text('Золото', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: useIcons 
                      ? Icon(Icons.military_tech, key: ValueKey('silver_icon'), size: 20, color: const Color(0xFFC0C0C0))
                      : FittedBox(
                          key: ValueKey('silver_text'),
                          fit: BoxFit.scaleDown,
                          child: Text('Серебро', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: useIcons 
                      ? Icon(Icons.workspace_premium, key: ValueKey('bronze_icon'), size: 20, color: const Color(0xFFCD7F32))
                      : FittedBox(
                          key: ValueKey('bronze_text'),
                          fit: BoxFit.scaleDown,
                          child: Text('Бронза', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: useIcons 
                      ? Icon(Icons.person_outline, key: ValueKey('newbie_icon'), size: 20, color: Colors.grey[600])
                      : FittedBox(
                          key: ValueKey('newbie_text'),
                          fit: BoxFit.scaleDown,
                          child: Text('Новички', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                  ),
                ),
              ),
            ],
            labelColor: const Color(0xFF6B73FF),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF6B73FF),
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Игроки не найдены' : 'Нет игроков в этой лиге',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: ListView.builder(
        key: ValueKey('${_selectedLeague?.toString() ?? 'all'}_${_filteredEntries.length}'),
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16),
        itemCount: _filteredEntries.length,
        cacheExtent: 1000,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final entry = _filteredEntries[index];
          final position = index + 1;
          return RepaintBoundary(
            child: _LeaderboardItem(
              key: ValueKey(entry.userId),
              entry: entry, 
              index: index,
              position: position,
              selectedLeague: _selectedLeague,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildLeagueStatsCards() {
    final totalPlayers = _allEntries.length;
    
    return League.values.map((league) {
      final count = _allEntries.where((entry) => entry.league == league).length;
      final percentage = totalPlayers > 0 ? (count / totalPlayers * 100) : 0;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: league.color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: league.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: league.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: league.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  league.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count игроков (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: league.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _LeaderboardItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index;
  final int position;
  final League? selectedLeague;

  const _LeaderboardItem({
    super.key,
    required this.entry, 
    required this.index,
    required this.position,
    required this.selectedLeague,
  });

  static const _usernameStyle = TextStyle(
    color: Color(0xFF2D3748),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const _positionStyle = TextStyle(
    color: Color(0xFF718096),
    fontSize: 14,
  );

  static const _xpStyle = TextStyle(
    color: Color(0xFF6B73FF),
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static const _modalUsernameStyle = TextStyle(
    color: Color(0xFF2D3748),
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const _modalPositionStyle = TextStyle(
    fontSize: 16,
  );

  static const _modalRankStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const _listRankStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  static const _modalXpStyle = TextStyle(
    color: Color(0xFF6B73FF),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  Color _getRankColor(int position) {
    if (selectedLeague == null) {
      return const Color(0xFF6B73FF);
    }
    return entry.league.color;
  }

  IconData _getRankIcon(int position) {
    if (position == 1) {
      return entry.league.icon;
    }
    return Icons.person;
  }

  bool _shouldShowIcon(int position) {
    return position == 1;
  }

  void _showPlayerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        
        final handleHeight = 28.0; 
        final containerPadding = 32.0; 
        final playerCardHeight = 140.0; 
        final spacingBetween = 16.0; 
        final leagueProgressHeight = 80.0; 
        
        final estimatedContentHeight = handleHeight + 
                                     containerPadding + 
                                     playerCardHeight + 
                                     spacingBetween + 
                                     leagueProgressHeight;
        
        final maxHeight = screenHeight > 800 ? screenHeight * 0.6 : screenHeight * 0.5;
        
        final modalHeight = estimatedContentHeight.clamp(200.0, maxHeight);
        
        return Container(
          height: modalHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(entry.image, 60, _getRankColor(position), username: entry.username),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.username,
                                    style: _modalUsernameStyle,
                                  ),
                                  Text(
                                    'Позиция $position',
                                    style: _modalPositionStyle.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: entry.league.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      entry.league.icon,
                                      size: 16,
                                      color: entry.league.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B73FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${entry.xpPoints} XP',
                                style: _modalXpStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LeagueProgressWidget(entry: entry),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPlayerDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: position == 1 
              ? Border.all(
                  color: _getRankColor(position).withOpacity(0.3),
                  width: 2,
                )
              : Border.all(
                  color: entry.league.color.withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Row(
          children: [
            _buildAvatar(entry.image, 50, _getRankColor(position), username: entry.username),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: _usernameStyle,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Позиция $position',
                          style: _positionStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B73FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${entry.xpPoints} XP',
                style: _xpStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String imageUrl, double size, Color fallbackColor, {String? username}) {
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(size, fallbackColor, username),
        ),
      );
    } else {
      return _buildFallbackAvatar(size, fallbackColor, username);
    }
  }

  Widget _buildFallbackAvatar(double size, Color color, String? username) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: username != null && username.isNotEmpty
            ? Text(
                username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              )
            : Icon(Icons.person, color: Colors.white, size: size * 0.6),
      ),
    );
  }
} 