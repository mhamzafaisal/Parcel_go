/// 0300..., 300..., +92300... sab ko +92300xxxxxxx bana deta hai.
/// Number theek na ho to null.
String? normalizePkPhone(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('92')) d = d.substring(2);
  if (d.startsWith('0')) d = d.substring(1);
  if (d.length == 10 && d.startsWith('3')) return '+92$d';
  return null;
}