String formatWeight(num kg) {
  if (kg < 1) {
    return '${(kg * 1000).round()} g';
  }
  // Remove trailing zeros if whole or clean
  if (kg % 1 == 0) {
    return '${kg.toInt()} kg';
  }
  return '${kg.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '')} kg';
}
