class FlightItinerary {
  final String departDate;
  final String returnDate;
  final String airline;
  final String? airlineReturn;
  final String? departTime;
  final String? arriveTime;
  final String? returnDepartTime;
  final String? returnArriveTime;
  final int price;
  final String currency;
  final String? durationOutbound;
  final int stopsOutbound;
  final String? bookingUrl;

  FlightItinerary({
    required this.departDate,
    required this.returnDate,
    required this.airline,
    this.airlineReturn,
    this.departTime,
    this.arriveTime,
    this.returnDepartTime,
    this.returnArriveTime,
    required this.price,
    required this.currency,
    this.durationOutbound,
    this.stopsOutbound = 0,
    this.bookingUrl,
  });

  factory FlightItinerary.fromJson(Map<String, dynamic> json) {
    return FlightItinerary(
      departDate: json['depart_date'],
      returnDate: json['return_date'],
      airline: json['airline'],
      airlineReturn: json['airline_return'],
      departTime: json['depart_time'],
      arriveTime: json['arrive_time'],
      returnDepartTime: json['return_depart_time'],
      returnArriveTime: json['return_arrive_time'],
      price: json['price'],
      currency: json['currency'],
      durationOutbound: json['duration_outbound'],
      stopsOutbound: json['stops_outbound'] ?? 0,
      bookingUrl: json['booking_url'],
    );
  }
}

class WatchedRoute {
  final int id;
  final int userId;
  final String origin;
  final String destination;
  final String departMonth;
  final double alertThreshold;
  final bool isActive;

  WatchedRoute({
    required this.id,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.departMonth,
    required this.alertThreshold,
    required this.isActive,
  });

  factory WatchedRoute.fromJson(Map<String, dynamic> json) {
    return WatchedRoute(
      id: json['id'],
      userId: json['user_id'],
      origin: json['origin'],
      destination: json['destination'],
      departMonth: json['depart_month'],
      alertThreshold: (json['alert_threshold'] as num).toDouble(),
      isActive: json['is_active'],
    );
  }
}
