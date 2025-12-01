class SelectedService {
  final String id;
  final String name;
  final int price;
  final int duration;
  double qty;

  SelectedService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    this.qty = 1,
  });
}
