import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CityLocation {
  final String name;
  final double latitude;
  final double longitude;

  const CityLocation(this.name, this.latitude, this.longitude);

  static const List<CityLocation> majorCities = [
    CityLocation('인천', 37.4563, 126.7052),
    CityLocation('서울', 37.5665, 126.9780),
    CityLocation('수원/경기남부', 37.2636, 127.0286),
    CityLocation('고양/경기북부', 37.6584, 126.8320),
    CityLocation('성남/분당', 37.4200, 127.1265),
    CityLocation('춘천/영서', 37.8813, 127.7298),
    CityLocation('강릉/영동', 37.7519, 128.8760),
    CityLocation('대전/세종', 36.3504, 127.3845),
    CityLocation('청주/충북', 36.6424, 127.4890),
    CityLocation('천안/충남', 36.8151, 127.1139),
    CityLocation('전주/전북', 35.8242, 127.1480),
    CityLocation('광주/전남', 35.1595, 126.8526),
    CityLocation('여수/순천', 34.7604, 127.6622),
    CityLocation('대구/경북', 35.8714, 128.6014),
    CityLocation('포항', 36.0190, 129.3435),
    CityLocation('부산/경남', 35.1796, 129.0756),
    CityLocation('울산', 35.5384, 129.3114),
    CityLocation('창원', 35.2280, 128.6811),
    CityLocation('제주', 33.4996, 126.5312),
  ];
}

/// 기상청(KMA) Lambert Conformal Conic 좌표 변환기 (위경도 -> 기상청 격자 nx, ny)
class KmaGridConverter {
  static const double _re = 6371.00877; // 지구 반경(km)
  static const double _grid = 5.0; // 격자 간격(km)
  static const double _slat1 = 30.0; // 투영 위도1(degree)
  static const double _slat2 = 60.0; // 투영 위도2(degree)
  static const double _olon = 126.0; // 기준점 경도(degree)
  static const double _olat = 38.0; // 기준점 위도(degree)
  static const double _xo = 43.0; // 기준점 X좌표(GRID)
  static const double _yo = 136.0; // 기준점 Y좌표(GRID)

  static ({int nx, int ny}) toGrid(double lat, double lon) {
    const deg2rad = math.pi / 180.0;

    const re = _re / _grid;
    const slat1 = _slat1 * deg2rad;
    const slat2 = _slat2 * deg2rad;
    const olon = _olon * deg2rad;
    const olat = _olat * deg2rad;

    var sn = math.tan(math.pi * 0.25 + slat2 * 0.5) / math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);
    var sf = math.tan(math.pi * 0.25 + slat1 * 0.5);
    sf = math.pow(sf, sn) * math.cos(slat1) / sn;
    var ro = math.tan(math.pi * 0.25 + olat * 0.5);
    ro = re * sf / math.pow(ro, sn);

    var ra = math.tan(math.pi * 0.25 + lat * deg2rad * 0.5);
    ra = re * sf / math.pow(ra, sn);
    var theta = lon * deg2rad - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    final x = (ra * math.sin(theta) + _xo + 0.5).floor();
    final y = (ro - ra * math.cos(theta) + _yo + 0.5).floor();

    return (nx: x, ny: y);
  }
}

class YesterdayWeather {
  final double tempAtSameHour;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;
  final String description;
  final IconData icon;

  const YesterdayWeather({
    required this.tempAtSameHour,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
    required this.description,
    required this.icon,
  });

  static YesterdayWeather defaultYesterday() {
    return const YesterdayWeather(
      tempAtSameHour: 20.0,
      minTemp: 15.0,
      maxTemp: 23.0,
      weatherCode: 0,
      description: '맑음',
      icon: Icons.wb_sunny_outlined,
    );
  }

  Map<String, dynamic> toJson() => {
    'tempAtSameHour': tempAtSameHour,
    'minTemp': minTemp,
    'maxTemp': maxTemp,
    'weatherCode': weatherCode,
    'description': description,
  };

  factory YesterdayWeather.fromJson(Map<String, dynamic> json) {
    final code = (json['weatherCode'] as num?)?.toInt() ?? 0;
    final info = WeatherData.interpretCode(code, true);
    return YesterdayWeather(
      tempAtSameHour: (json['tempAtSameHour'] as num?)?.toDouble() ?? 20.0,
      minTemp: (json['minTemp'] as num?)?.toDouble() ?? 15.0,
      maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 23.0,
      weatherCode: code,
      description: (json['description'] as String?) ?? info.description,
      icon: info.icon,
    );
  }
}

class WeatherData {
  final double currentTemp;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final String description;
  final IconData icon;
  final bool isDay;
  final String locationName;
  final int? timestamp;
  final YesterdayWeather? yesterday;

  const WeatherData({
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.description,
    required this.icon,
    required this.isDay,
    this.locationName = '인천',
    this.timestamp,
    this.yesterday,
  });

  /// 어제 동일 시각 대비 기온 차이 (°C)
  double? get tempDiffFromYesterday {
    if (yesterday == null) return null;
    return currentTemp - yesterday!.tempAtSameHour;
  }

  /// 어제 대비 기온 비교 설명 문구 (예: "어제보다 +2.5° 높음", "어제와 비슷", "어제보다 1.2° 낮음")
  String get tempDiffDescription {
    final diff = tempDiffFromYesterday;
    if (diff == null) return '';
    final rounded = (diff * 10).round() / 10;
    if (rounded.abs() < 0.3) {
      return '어제와 비슷';
    } else if (rounded > 0) {
      return '어제보다 +${rounded.toStringAsFixed(1)}°';
    } else {
      return '어제보다 ${rounded.toStringAsFixed(1)}°';
    }
  }

  /// 콤팩트 배지용 텍스트 (예: "(▲2.5°)", "(▼1.2°)", "(=)")
  String get compactTempDiffBadge {
    final diff = tempDiffFromYesterday;
    if (diff == null) return '';
    final rounded = (diff * 10).round() / 10;
    if (rounded.abs() < 0.3) {
      return '(=)';
    } else if (rounded > 0) {
      return '(▲${rounded.toStringAsFixed(1)}°)';
    } else {
      return '(▼${rounded.abs().toStringAsFixed(1)}°)';
    }
  }

  static WeatherData defaultWeather({String city = '인천'}) {
    return WeatherData(
      currentTemp: 22.0,
      maxTemp: 25.0,
      minTemp: 18.0,
      weatherCode: 0,
      description: '맑음',
      icon: Icons.wb_sunny_outlined,
      isDay: true,
      locationName: city,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      yesterday: YesterdayWeather.defaultYesterday(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentTemp': currentTemp,
    'maxTemp': maxTemp,
    'minTemp': minTemp,
    'weatherCode': weatherCode,
    'description': description,
    'isDay': isDay,
    'locationName': locationName,
    'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    if (yesterday != null) 'yesterday': yesterday!.toJson(),
  };

  factory WeatherData.fromCacheJson(Map<String, dynamic> json) {
    final currentCode = (json['weatherCode'] as num?)?.toInt() ?? 0;
    final isDay = json['isDay'] as bool? ?? true;
    final info = interpretCode(currentCode, isDay);

    YesterdayWeather? yesterday;
    if (json['yesterday'] != null && json['yesterday'] is Map<String, dynamic>) {
      yesterday = YesterdayWeather.fromJson(json['yesterday'] as Map<String, dynamic>);
    } else {
      yesterday = YesterdayWeather.defaultYesterday();
    }

    return WeatherData(
      currentTemp: (json['currentTemp'] as num?)?.toDouble() ?? 22.0,
      maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 25.0,
      minTemp: (json['minTemp'] as num?)?.toDouble() ?? 18.0,
      weatherCode: currentCode,
      description: (json['description'] as String?) ?? info.description,
      icon: info.icon,
      isDay: isDay,
      locationName: (json['locationName'] as String?) ?? '인천',
      timestamp: (json['timestamp'] as num?)?.toInt(),
      yesterday: yesterday,
    );
  }

  factory WeatherData.fromKma({
    required String cityName,
    required double currentTemp,
    required double minTemp,
    required double maxTemp,
    required int sky,
    required int pty,
    required bool isDay,
    YesterdayWeather? yesterday,
  }) {
    // weatherCode: PTY가 있으면 1000 + PTY, 없으면 SKY 코드 사용 (1: 맑음, 3: 구름많음, 4: 흐림)
    final weatherCode = pty > 0 ? 1000 + pty : sky;
    final info = interpretCode(weatherCode, isDay);

    return WeatherData(
      currentTemp: currentTemp,
      maxTemp: maxTemp,
      minTemp: minTemp,
      weatherCode: weatherCode,
      description: info.description,
      icon: info.icon,
      isDay: isDay,
      locationName: cityName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      yesterday: yesterday ?? YesterdayWeather.defaultYesterday(),
    );
  }

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json, String cityName) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};

    final currentTemp = (current['temperature_2m'] as num?)?.toDouble() ?? 22.0;
    final currentCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;

    final maxList = daily['temperature_2m_max'] as List<dynamic>? ?? [];
    final minList = daily['temperature_2m_min'] as List<dynamic>? ?? [];
    final dailyCodes = daily['weather_code'] as List<dynamic>? ?? [];
    final dailyTimes = daily['time'] as List<dynamic>? ?? [];

    // past_days=1 인 경우 daily 리스트의 0번 인덱스는 어제, 1번 인덱스는 오늘
    final hasYesterdayInDaily = dailyTimes.length >= 2;
    final todayIndex = hasYesterdayInDaily ? 1 : 0;
    final yesterdayIndex = hasYesterdayInDaily ? 0 : -1;

    final maxTemp = maxList.length > todayIndex ? (maxList[todayIndex] as num).toDouble() : currentTemp + 2.0;
    final minTemp = minList.length > todayIndex ? (minList[todayIndex] as num).toDouble() : currentTemp - 3.0;
    final dailyCode = dailyCodes.length > todayIndex ? (dailyCodes[todayIndex] as num).toInt() : currentCode;

    int effectiveCode = currentCode;
    if (currentCode <= 3) {
      if (dailyCode >= 80 && dailyCode <= 82) {
        effectiveCode = dailyCode;
      } else if (dailyCode >= 95) {
        effectiveCode = dailyCode;
      } else if (dailyCode >= 61 && dailyCode <= 65) {
        effectiveCode = dailyCode;
      } else if (dailyCode >= 71 && dailyCode <= 77) {
        effectiveCode = dailyCode;
      }
    }

    final info = interpretCode(effectiveCode, isDay);

    // 어제 날씨 구성
    YesterdayWeather? yesterday;
    if (yesterdayIndex >= 0) {
      final yMax = (maxList[yesterdayIndex] as num?)?.toDouble() ?? (currentTemp + 1.0);
      final yMin = (minList[yesterdayIndex] as num?)?.toDouble() ?? (currentTemp - 4.0);
      final yCode = (dailyCodes[yesterdayIndex] as num?)?.toInt() ?? 0;

      final nowHour = DateTime.now().hour.clamp(0, 23);
      final hourlyTemps = hourly['temperature_2m'] as List<dynamic>? ?? [];
      final hourlyCodes = hourly['weather_code'] as List<dynamic>? ?? [];

      double yHourTemp = (yMax + yMin) / 2.0;
      if (hourlyTemps.length > nowHour) {
        yHourTemp = (hourlyTemps[nowHour] as num).toDouble();
      }

      int yEffectiveCode = yCode;
      if (hourlyCodes.length > nowHour) {
        final hCode = (hourlyCodes[nowHour] as num).toInt();
        if (hCode > 0) yEffectiveCode = hCode;
      }

      final yInfo = interpretCode(yEffectiveCode, true);
      yesterday = YesterdayWeather(
        tempAtSameHour: yHourTemp,
        minTemp: yMin,
        maxTemp: yMax,
        weatherCode: yEffectiveCode,
        description: yInfo.description,
        icon: yInfo.icon,
      );
    } else {
      yesterday = YesterdayWeather.defaultYesterday();
    }

    return WeatherData(
      currentTemp: currentTemp,
      maxTemp: maxTemp,
      minTemp: minTemp,
      weatherCode: effectiveCode,
      description: info.description,
      icon: info.icon,
      isDay: isDay,
      locationName: cityName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      yesterday: yesterday,
    );
  }

  static ({String description, IconData icon}) interpretCode(int code, bool isDay) {
    // 기상청 PTY (1000 + PTY)
    if (code >= 1000) {
      final pty = code - 1000;
      switch (pty) {
        case 1:
          return (description: '비', icon: Icons.water_drop_outlined);
        case 2:
          return (description: '비/눈', icon: Icons.grain_outlined);
        case 3:
          return (description: '눈', icon: Icons.ac_unit_outlined);
        case 5:
          return (description: '빗방울', icon: Icons.water_drop_outlined);
        case 6:
          return (description: '진눈깨비', icon: Icons.grain_outlined);
        case 7:
          return (description: '눈날림', icon: Icons.ac_unit_outlined);
      }
    }

    // 기상청 SKY (1: 맑음, 3: 구름많음, 4: 흐림) 및 WMO 코드 통합
    switch (code) {
      case 0:
      case 1:
        return (
          description: '맑음',
          icon: isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
        );
      case 2:
        return (
          description: '구름 조금',
          icon: isDay ? Icons.cloud_queue_outlined : Icons.nightlight_outlined,
        );
      case 3:
        return (
          description: '구름많음',
          icon: isDay ? Icons.cloud_outlined : Icons.nightlight_outlined,
        );
      case 4:
        return (description: '흐림', icon: Icons.cloud_outlined);
      case 45:
      case 48:
        return (description: '안개', icon: Icons.waves_outlined);
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return (description: '이슬비', icon: Icons.grain_outlined);
      case 61:
      case 63:
      case 65:
        return (description: '비', icon: Icons.water_drop_outlined);
      case 66:
      case 67:
        return (description: '진눈깨비', icon: Icons.grain_outlined);
      case 71:
      case 73:
      case 75:
      case 77:
        return (description: '눈', icon: Icons.ac_unit_outlined);
      case 80:
      case 81:
      case 82:
        return (description: '소나기', icon: Icons.shower_outlined);
      case 85:
      case 86:
        return (description: '눈 소나기', icon: Icons.ac_unit_outlined);
      case 95:
      case 96:
      case 99:
        return (description: '뇌우', icon: Icons.thunderstorm_outlined);
      default:
        return (
          description: '맑음',
          icon: isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
        );
    }
  }
}

class WeatherService {
  static WeatherData? _cached;
  static DateTime? _lastFetchedAt;
  static const String _storageKey = 'audistine_cached_weather';
  static const String _cityKey = 'audistine_weather_city';
  static bool _isFetching = false;

  /// 기상청 공공데이터포털 일반 인증키 (Decoding)
  static const String kmaApiKey = '9i0aDoLX6WDwuFiv2eJf1AVdBrmLC1et5sktDrL3yAJl416NBcZTt54qXR0wqWVDAUeLRtkKvbTlPaXRzfpvSQ==';

  /// 현재 저장된 도시명 불러오기 (기본값: 인천)
  static Future<CityLocation> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityName = prefs.getString(_cityKey) ?? '인천';
      return CityLocation.majorCities.firstWhere(
        (c) => c.name == cityName,
        orElse: () => CityLocation.majorCities[0],
      );
    } catch (_) {
      return CityLocation.majorCities[0];
    }
  }

  /// 도시 변경 및 즉시 캐시 초기화
  static Future<void> setSelectedCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityKey, cityName);
      _cached = null;
      _lastFetchedAt = null;
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// 캐시된 최근 날씨를 즉시(0초) 반환 (도시 일치 확인)
  static Future<WeatherData> getFastWeather() async {
    final city = await getSelectedCity();

    if (_cached != null && _cached!.locationName == city.name) {
      return _cached!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        final data = WeatherData.fromCacheJson(json.decode(saved) as Map<String, dynamic>);
        if (data.locationName == city.name) {
          _cached = data;
          return data;
        }
      }
    } catch (_) {}

    return WeatherData.defaultWeather(city: city.name);
  }

  /// 특정 도시의 실시간 날씨 조회
  static Future<WeatherData> fetchFreshWeatherForCity(CityLocation city) async {
    // 웹(Chrome) 환경은 브라우저 CORS 정책으로 인해 공공데이터포털 직접 호출이 차단되므로 Open-Meteo를 즉시 사용합니다.
    // 모바일(Android/iOS) 네이티브 환경에서는 기상청(KMA) 공식 API를 최우선 연동합니다.
    if (!kIsWeb && kmaApiKey.isNotEmpty) {
      final kmaWeather = await _fetchFromKma(city);
      if (kmaWeather != null) {
        return kmaWeather;
      }
    }

    final fallbackWeather = await _fetchFromOpenMeteo(city);
    if (fallbackWeather != null) {
      return fallbackWeather;
    }

    return WeatherData.defaultWeather(city: city.name);
  }

  /// 기상청(KMA) 실시간 날씨 조회 (15분 경과 시 자동 네트워크 갱신)
  static Future<WeatherData> fetchFreshWeather({bool force = false}) async {
    final city = await getSelectedCity();

    final isCacheValid = _cached != null &&
        _cached!.locationName == city.name &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!).inMinutes < 15;

    if (isCacheValid && !force) {
      return _cached!;
    }

    if (_isFetching && !force) {
      return _cached ?? await getFastWeather();
    }
    _isFetching = true;

    try {
      final fresh = await fetchFreshWeatherForCity(city);
      _cached = fresh;
      _lastFetchedAt = DateTime.now();
      _saveToCache(fresh);
      return fresh;
    } catch (e) {
      debugPrint('날씨 정보 수신 실패: $e');
    } finally {
      _isFetching = false;
    }

    return _cached ?? await getFastWeather();
  }

  static Future<void> _saveToCache(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(data.toJson()));
    } catch (_) {}
  }

  /// 기상청 API 연동 (초단기실황 + 초단기예보 + 단기예보)
  static Future<WeatherData?> _fetchFromKma(CityLocation city) async {
    try {
      final now = DateTime.now();
      final grid = KmaGridConverter.toGrid(city.latitude, city.longitude);
      final nx = grid.nx;
      final ny = grid.ny;

      // 1) 초단기실황 (현재 기온 T1H, 현재 강수형태 PTY)
      // 기상청 실황은 매시 45분 이후에 직전 정시가 안정적으로 제공됨
      DateTime ncstTime = now;
      if (ncstTime.minute < 45) {
        ncstTime = ncstTime.subtract(const Duration(hours: 1));
      }

      double? currentTemp;
      int currentPty = 0;

      // 1차 시도 (최신 시각), 실패 시 직전 1시간 추가 시도
      for (int attempt = 0; attempt < 2; attempt++) {
        final checkTime = attempt == 0 ? ncstTime : ncstTime.subtract(const Duration(hours: 1));
        final ncstDate = '${checkTime.year}${checkTime.month.toString().padLeft(2, '0')}${checkTime.day.toString().padLeft(2, '0')}';
        final ncstHour = '${checkTime.hour.toString().padLeft(2, '0')}00';

        final ncstUri = Uri.parse(
          'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst?serviceKey=${Uri.encodeQueryComponent(kmaApiKey)}&pageNo=1&numOfRows=100&dataType=JSON&base_date=$ncstDate&base_time=$ncstHour&nx=$nx&ny=$ny',
        );

        final ncstRes = await http.get(ncstUri).timeout(const Duration(seconds: 4));
        if (ncstRes.statusCode == 200) {
          final jsonMap = json.decode(ncstRes.body) as Map<String, dynamic>;
          final items = jsonMap['response']?['body']?['items']?['item'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            for (final item in items) {
              final cat = item['category'];
              final val = item['obsrValue'];
              if (cat == 'T1H') currentTemp = double.tryParse(val.toString());
              if (cat == 'PTY') currentPty = int.tryParse(val.toString()) ?? 0;
            }
            if (currentTemp != null) break;
          }
        }
      }

      // 2) 초단기예보 (하늘상태 SKY: 1 맑음, 3 구름많음, 4 흐림)
      DateTime fcstTime = now;
      if (fcstTime.minute < 45) {
        fcstTime = fcstTime.subtract(const Duration(hours: 1));
      }
      final fcstDate = '${fcstTime.year}${fcstTime.month.toString().padLeft(2, '0')}${fcstTime.day.toString().padLeft(2, '0')}';
      final fcstHour = '${fcstTime.hour.toString().padLeft(2, '0')}30';

      final fcstUri = Uri.parse(
        'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst?serviceKey=${Uri.encodeQueryComponent(kmaApiKey)}&pageNo=1&numOfRows=60&dataType=JSON&base_date=$fcstDate&base_time=$fcstHour&nx=$nx&ny=$ny',
      );

      int sky = 1;
      int fcstPty = currentPty;

      final fcstRes = await http.get(fcstUri).timeout(const Duration(seconds: 4));
      if (fcstRes.statusCode == 200) {
        final jsonMap = json.decode(fcstRes.body) as Map<String, dynamic>;
        final items = jsonMap['response']?['body']?['items']?['item'] as List<dynamic>? ?? [];
        for (final item in items) {
          final cat = item['category'];
          final val = item['fcstValue'];
          if (cat == 'SKY' && sky == 1) {
            sky = int.tryParse(val.toString()) ?? 1;
          }
          if (cat == 'PTY' && currentPty == 0) {
            final p = int.tryParse(val.toString()) ?? 0;
            if (p > 0) fcstPty = p;
          }
        }
      }

      // 3) 단기예보 (당일 최고/최저기온 TMN/TMX 또는 TMP)
      final vilageBase = _getVilageBaseDateTime(now);
      final vilageUri = Uri.parse(
        'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?serviceKey=${Uri.encodeQueryComponent(kmaApiKey)}&pageNo=1&numOfRows=250&dataType=JSON&base_date=${vilageBase.baseDate}&base_time=${vilageBase.baseTime}&nx=$nx&ny=$ny',
      );

      double? minTemp;
      double? maxTemp;
      final List<double> todayTmps = [];
      final todayStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final vilageRes = await http.get(vilageUri).timeout(const Duration(seconds: 4));
      if (vilageRes.statusCode == 200) {
        final jsonMap = json.decode(vilageRes.body) as Map<String, dynamic>;
        final items = jsonMap['response']?['body']?['items']?['item'] as List<dynamic>? ?? [];
        for (final item in items) {
          final fDate = item['fcstDate']?.toString();
          final cat = item['category']?.toString();
          final val = item['fcstValue'];

          if (fDate == todayStr) {
            if (cat == 'TMN') minTemp = double.tryParse(val.toString());
            if (cat == 'TMX') maxTemp = double.tryParse(val.toString());
            if (cat == 'TMP') {
              final tmp = double.tryParse(val.toString());
              if (tmp != null) todayTmps.add(tmp);
            }
          }
        }
      }

      if (currentTemp != null) {
        todayTmps.add(currentTemp);
      }
      if (todayTmps.isNotEmpty) {
        todayTmps.sort();
        minTemp ??= todayTmps.first;
        maxTemp ??= todayTmps.last;
      }
      minTemp ??= (currentTemp != null ? currentTemp - 3.0 : 18.0);
      maxTemp ??= (currentTemp != null ? currentTemp + 4.0 : 25.0);
      currentTemp ??= (minTemp + maxTemp) / 2.0;

      final isDay = now.hour >= 6 && now.hour < 19;
      final effectivePty = currentPty > 0 ? currentPty : fcstPty;

      final yesterday = await fetchYesterdayWeather(city);

      return WeatherData.fromKma(
        cityName: city.name,
        currentTemp: currentTemp,
        minTemp: minTemp,
        maxTemp: maxTemp,
        sky: sky,
        pty: effectivePty,
        isDay: isDay,
        yesterday: yesterday ?? YesterdayWeather.defaultYesterday(),
      );
    } catch (e) {
      debugPrint('기상청 API 연동 오류: $e');
      return null;
    }
  }

  /// 어제 날씨 단독 조회 (Open-Meteo 과거 1일 데이터 활용)
  static Future<YesterdayWeather?> fetchYesterdayWeather(CityLocation city) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${city.latitude}&longitude=${city.longitude}&past_days=1&forecast_days=1&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Asia%2FSeoul',
      );
      final response = await http.get(uri).timeout(const Duration(milliseconds: 5000));
      if (response.statusCode == 200) {
        final jsonMap = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final daily = jsonMap['daily'] as Map<String, dynamic>? ?? {};
        final hourly = jsonMap['hourly'] as Map<String, dynamic>? ?? {};

        final maxList = daily['temperature_2m_max'] as List<dynamic>? ?? [];
        final minList = daily['temperature_2m_min'] as List<dynamic>? ?? [];
        final dailyCodes = daily['weather_code'] as List<dynamic>? ?? [];

        final yMax = maxList.isNotEmpty ? (maxList[0] as num).toDouble() : 23.0;
        final yMin = minList.isNotEmpty ? (minList[0] as num).toDouble() : 15.0;
        final yCode = dailyCodes.isNotEmpty ? (dailyCodes[0] as num).toInt() : 0;

        final nowHour = DateTime.now().hour.clamp(0, 23);
        final hourlyTemps = hourly['temperature_2m'] as List<dynamic>? ?? [];
        final hourlyCodes = hourly['weather_code'] as List<dynamic>? ?? [];

        double yHourTemp = (yMax + yMin) / 2.0;
        if (hourlyTemps.length > nowHour) {
          yHourTemp = (hourlyTemps[nowHour] as num).toDouble();
        }

        int yEffectiveCode = yCode;
        if (hourlyCodes.length > nowHour) {
          final hCode = (hourlyCodes[nowHour] as num).toInt();
          if (hCode > 0) yEffectiveCode = hCode;
        }

        final info = WeatherData.interpretCode(yEffectiveCode, true);
        return YesterdayWeather(
          tempAtSameHour: yHourTemp,
          minTemp: yMin,
          maxTemp: yMax,
          weatherCode: yEffectiveCode,
          description: info.description,
          icon: info.icon,
        );
      }
    } catch (e) {
      debugPrint('어제 날씨 조회 오류: $e');
    }
    return null;
  }

  static ({String baseDate, String baseTime}) _getVilageBaseDateTime(DateTime now) {
    final times = [2, 5, 8, 11, 14, 17, 20, 23];
    if (now.hour < 2 || (now.hour == 2 && now.minute < 10)) {
      final target = now.subtract(const Duration(days: 1));
      return (
        baseDate: '${target.year}${target.month.toString().padLeft(2, '0')}${target.day.toString().padLeft(2, '0')}',
        baseTime: '2300',
      );
    }

    int selectedHour = 2;
    for (final t in times) {
      if (now.hour > t || (now.hour == t && now.minute >= 10)) {
        selectedHour = t;
      }
    }

    return (
      baseDate: '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
      baseTime: '${selectedHour.toString().padLeft(2, '0')}00',
    );
  }

  /// Open-Meteo 백업 API (과거 1일 데이터 포함)
  static Future<WeatherData?> _fetchFromOpenMeteo(CityLocation city) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${city.latitude}&longitude=${city.longitude}&past_days=1&forecast_days=1&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Asia%2FSeoul',
      );

      final response = await http.get(uri).timeout(const Duration(milliseconds: 6000));
      if (response.statusCode == 200) {
        final jsonMap = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return WeatherData.fromOpenMeteo(jsonMap, city.name);
      }
    } catch (_) {}
    return null;
  }
}
