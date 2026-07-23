class SelectedService {
  final String id;
  final String serviceId;
  final String name;
  final int price;
  final int duration;
  final List<String> processTypes;
  final String itemStatus;
  double qty;

  SelectedService({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.price,
    required this.duration,
    this.processTypes = const [],
    this.itemStatus = 'pending',
    this.qty = 1,
  });
}
