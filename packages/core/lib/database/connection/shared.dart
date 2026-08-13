export 'connection_unsupported.dart'
    if (dart.library.ffi) 'connection_io.dart'
    if (dart.library.js_interop) 'connection_web.dart';
