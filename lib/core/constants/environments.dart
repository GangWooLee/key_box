enum Environment {
  development('Development'),
  staging('Staging'),
  production('Production');

  const Environment(this.label);
  final String label;
}
