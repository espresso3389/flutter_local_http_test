import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mime/mime.dart';

final localhostServer = new MyHttpServer();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  localhostServer.start();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  final browser = MyChromeSafariBrowser(MyInAppBrowser());

  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HTTP Test'),
      ),
      body: Center(child: TextButton(onPressed: testHttp, child: Text('Start Browser')))
    );
  }

  void testHttp() async {
    await widget.browser.open(
      url: 'http://192.168.1.2:5500/sample_web/index.html',
      options: ChromeSafariBrowserClassOptions(
          android: AndroidChromeCustomTabsOptions(addDefaultShareMenuItem: false),
          ios: IOSSafariOptions(barCollapsingEnabled: true)));
  }
}

class MyInAppBrowser extends InAppBrowser {
  @override
  Future onLoadStart(String url) async {
    print("\n\nStarted $url\n\n");
  }

  @override
  Future onLoadStop(String url) async {
    print("\n\nStopped $url\n\n");
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  void onExit() {
    print("\n\nBrowser closed!\n\n");
  }
}

class MyChromeSafariBrowser extends ChromeSafariBrowser {

  MyChromeSafariBrowser(browserFallback) : super(bFallback: browserFallback);

  @override
  void onOpened() {
    print("ChromeSafari browser opened");
  }

  @override
  void onCompletedInitialLoad() {
    print("ChromeSafari browser initial load completed");
  }

  @override
  void onClosed() {
    print("ChromeSafari browser closed");
  }
}

///This class allows you to create a simple server on `http://localhost:[port]/` in order to be able to load your assets file on a server. The default [port] value is `8080`.
class MyHttpServer {
  HttpServer _server;
  int _port = 8080;

  MyHttpServer({int port = 8080}) {
    this._port = port;
  }

  Future<void> start() async {
    if (this._server != null) {
      throw Exception('Server already started on http://localhost:$_port');
    }

    var completer = Completer();

    runZoned(() {
      HttpServer.bind('127.0.0.1', _port).then((server) {
        print('Server running on http://localhost:' + _port.toString());

        this._server = server;

        server.listen((HttpRequest request) async {
          var path = request.requestedUri.path;
          print('New req: ${request.requestedUri}');
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';

          if (path == 'testdata') {
            request.response.headers.contentType = ContentType('text', 'javascript', charset: 'utf-8');
            request.response.add(utf8.encode('document.test_name = "Local Http Server";'));
            request.response.close();
          } else {
            print('Not supported: $path');
            request.response.addError('Not supported: $path');
            request.response.close();
            return;
          }
        });

        completer.complete();
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }

  ///Closes the server.
  Future<void> close() async {
    if (this._server != null) {
      await this._server.close(force: true);
      print('Server running on http://localhost:$_port closed');
      this._server = null;
    }
  }
}
