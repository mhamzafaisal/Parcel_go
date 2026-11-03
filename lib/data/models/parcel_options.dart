enum ParcelCategory {
  documents('documents', 'Documents'),
  clothes('clothes', 'Clothes'),
  electronics('electronics', 'Electronics'),
  food('food', 'Food'),
  other('other', 'Other');

  final String value;
  final String label;
  const ParcelCategory(this.value, this.label);
}

enum ParcelSize {
  small('small', 'Small', 'Documents, small box'),
  medium('medium', 'Medium', 'Shoebox or bag'),
  large('large', 'Large', 'Big box');

  final String value;
  final String label;
  final String hint;
  const ParcelSize(this.value, this.label, this.hint);
}