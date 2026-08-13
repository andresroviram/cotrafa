import 'package:injectable/injectable.dart';

/// Marca este package como [MicroPackage].
/// [injectable_config_builder] generará un [MicroPackageModule] que el app raíz
/// incluye automáticamente en su método `init()` sin llamadas manuales.
@InjectableInit.microPackage()
void initMicroPackage() {} // stub requerido por el generador, nunca se llama
