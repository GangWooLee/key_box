enum SecretType {
  apiKey('API Key'),
  token('Token'),
  password('Password'),
  credential('Credential'),
  certificate('Certificate'),
  sshKey('SSH Key'),
  other('Other');

  const SecretType(this.label);
  final String label;
}
