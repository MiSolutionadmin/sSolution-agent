import 'package:encrypt/encrypt.dart'as en;


/// 1이면 암호화, 아니면 복호화
String textEncryption(String text, int enOrDe) {
  dynamic publicKey = en.RSAKeyParser().parse('-----BEGIN PUBLIC KEY-----\n'
      'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCzoN1rGpG4oIam1m2fup1ruY5e\n'
      'nRGxF9KJtnhc2XZZoTn2mRz+oqFJEvgN0DsfNrjpAJRModM9qHFx4u2wEZgSjHvI\n'
      '2IgVp0t5R2Ji/v3bwwcYKy9MUhL6Qp24EYyi6awh8uK8BovNCM7IzWFOgBxTtOJ8\n'
      'oBUkko01QfIIG+uoAQIDAQAB\n'
      '-----END PUBLIC KEY-----');
  dynamic privKey = en.RSAKeyParser().parse('-----BEGIN RSA PRIVATE KEY-----\n'
      'MIICWwIBAAKBgQCzoN1rGpG4oIam1m2fup1ruY5enRGxF9KJtnhc2XZZoTn2mRz+\n'
      'oqFJEvgN0DsfNrjpAJRModM9qHFx4u2wEZgSjHvI2IgVp0t5R2Ji/v3bwwcYKy9M\n'
      'UhL6Qp24EYyi6awh8uK8BovNCM7IzWFOgBxTtOJ8oBUkko01QfIIG+uoAQIDAQAB\n'
      'An8l48jQzsnuJ+4/QvvctYB/OKTPUFJrCJtgcRzyeOx9+4Q+gA2dqLBcuaOZRlMy\n'
      'Qli+zWB6yafFWcKUQ0nf2dY5t86wubsSAaHrSMDCASjLIJJeVDEqPe+Gj+w3RAXw\n'
      'vb8MW4l7I9T3sSRukn0CnIhGU0KT8+znTHQrAvxNFFbZAkEA+yyTC2FSEGrGqKEx\n'
      'Vao0ZBegnyoWIN26Xyh+i0c1mZKYHNw363NbMIo3VLQRrnQ08OzXNXE4pxKH+ACN\n'
      's1wAjwJBALcUYq619D42YmwpSoPLIUWAFHZmbQYQbO+N+wBlopP0nE6CimC5HsTI\n'
      'uMAqefnAXRIEU9CM5h3u+6zFVCyi9m8CQQD4JXqEtLppw8POl6nw8z3dYUZr2R2R\n'
      'jN1y48PZgBmhRqYHZT3N3OLLmtG9WkVZsC8ZkzOu9dO9o943EvzrpUpbAkEAliv9\n'
      'iiusDX/Umb4A5jwvrW+S2U/I6+l7QcBne/riMZS6xddkJFSUvXubt9zfspIshYPR\n'
      'MEby1ujZve0az4ZYtwJAa00wn3MncsMiYkwmPIqIruAT5AMkTHLGhddaEFmuQ/kP\n'
      'xrVrCDQlcV53PNeRoldVb2YSXu58gMeI/SOQIgKMzw==\n'
      '-----END RSA PRIVATE KEY-----');
  final encrypter = en.Encrypter(en.RSA(publicKey: publicKey, privateKey: privKey));
  if (enOrDe == 1) {
    final encrypted = encrypter.encrypt(text);
    return encrypted.base64.toString();
  } else {
    try {
      return encrypter.decrypt64(text).toString();
    } catch (Exception) {
      return text.toString();
    }
  }
}