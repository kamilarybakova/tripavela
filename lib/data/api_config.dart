final tripavelaApiBase = Uri.parse(
  const String.fromEnvironment(
    'TRIPAVELA_API_BASE_URL',
    defaultValue: 'https://api.tripavela.dev/api/v1/',
  ),
);

Uri tripavelaMediaUri(String assetPath) => tripavelaApiBase.resolveUri(
  Uri(pathSegments: ['', 'media', ...assetPath.split('/')]),
);

bool isNetworkPhoto(Uri? uri) {
  if (uri == null || uri.host.isEmpty) return false;
  return uri.scheme == 'https' ||
      (uri.scheme == 'http' && uri.origin == tripavelaApiBase.origin);
}
