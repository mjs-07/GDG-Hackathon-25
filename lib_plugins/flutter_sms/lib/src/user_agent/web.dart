import 'dart:html' as html;

bool isCupertino() {
  final devices = [
    'iPad Simulator',
    'iPhone Simulator',
    'iPod Simulator',
    'iPad',
    'iPhone',
    'iPod',
    'Mac OS X',
  ];
  final String agent = html.window.navigator.userAgent;
  for (final device in devices) {
    if (agent.contains(device)) {
      return true;
    }
  }
  return false;
}
