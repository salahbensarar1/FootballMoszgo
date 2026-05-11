/// Smart Hungarian character encoding fix - only fix if corruption detected
String cleanHungarianText(String text) {
  String result = text.trim();

  // Check if the text actually needs fixing first
  bool needsFix = result.contains('Ã') ||
                 result.contains('Å') ||
                 result.contains('&') ||
                 result.contains('?');

  if (!needsFix) {
    return result; // Return as-is if it looks fine
  }

  // Only apply fixes if corruption is detected
  result = result
      .replaceAll('Ã¡', 'á') // á - a with acute
      .replaceAll('Ã©', 'é') // é - e with acute
      .replaceAll('Ã­', 'í') // í - i with acute
      .replaceAll('Ã³', 'ó') // ó - o with acute
      .replaceAll('Ã¶', 'ö') // ö - o with diaeresis
      .replaceAll('Ã¼', 'ü') // ü - u with diaeresis
      .replaceAll('Å\u0091', '\u0151') // ő - o with double acute
      .replaceAll('Å±', '\u0171') // ű - u with double acute
      // Upper case versions
      .replaceAll('Ã\u0081', 'Á') // Á
      .replaceAll('Ã‰', 'É') // É
      .replaceAll('Ã\u008D', 'Í') // Í
      .replaceAll('Ã"', 'Ó') // Ó
      .replaceAll('Ã–', 'Ö') // Ö
      .replaceAll('Ã\u009C', 'Ü') // Ü
      .replaceAll('Å\u0090', '\u0150') // Ő
      .replaceAll('Å°', '\u0170') // Ű
      // HTML entities
      .replaceAll('&aacute;', 'á')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  return result;
}

/// Team matching with clean text
bool isTeamMatch(String teamName, String searchTerm) {
  final cleanTeam = cleanHungarianText(teamName).toLowerCase();
  final cleanSearch = searchTerm.toLowerCase();
  return cleanTeam.contains(cleanSearch);
}
