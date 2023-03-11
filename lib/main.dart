import 'dart:convert';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0');
  runApp(const MyApp());
}

// void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // static const String _title = 'Easy-ChatGPT';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy-ChatGPT',
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  // static const int numItems = 10;
  // List<bool> selected = List<bool>.generate(numItems, (int index) => false);
  List _pings = [];
  final _selectAll = Supabase.instance.client
      .from('chatgpt')
      .select<List<Map<String, dynamic>>>(
          // const FetchOptions(
          //   count: CountOption.exact,
          // ),
          );

  @override
  initState() {
    super.initState();
    _selectAll.then((data) {
      _pings = List.filled(data.length, '...');
      for (var i = 0; i < data.length; ++i) {
        final ping = Ping(data[i]['url'],
            encoding: const Utf8Codec(allowMalformed: true), count: 2);
        print('Running command: ${ping.command}');
        ping.stream.listen((e) {
          setState(() {
            _pings[i] = (e.summary?.time?.inMilliseconds == 0)
                ? S.of(context).failed
                : (e.summary?.time?.inMilliseconds).toString() + 'ms';
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _selectAll,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final chatgpt = snapshot.data!;

        return SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: <DataColumn>[
                DataColumn(label: Text(S.of(context).url)),
                DataColumn(
                  label: Text(S.of(context).chatGPTVer),
                ),
                // DataColumn(
                //   label: Text(S.of(context).estimatedDataDate),
                // ),
                const DataColumn(
                  label: Text('ping'),
                ),
                const DataColumn(
                  label: Text(''),
                ),
              ],
              rows: List<DataRow>.generate(
                chatgpt.length,
                (int index) {
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text(chatgpt[index]['url']), onTap: () {
                        launchUrl(Uri.parse("https://" + chatgpt[index]['url']),
                            mode: LaunchMode.inAppWebView);
                      }),
                      DataCell(Text(chatgpt[index]['chatGPTVer'])),
                      // DataCell(Text(DateFormat.yM().format(DateTime(
                      //   int.parse(
                      //       chatgpt[index]['estimatedDataDate'].split('-')[0]),
                      //   int.parse(
                      //       chatgpt[index]['estimatedDataDate'].split('-')[1]),
                      // )))),
                      DataCell(Text(_pings[index])),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () {},
                            ),
                            Text(chatgpt[index]['like'].toString()),
                            IconButton(
                              icon: const Icon(Icons.thumb_down_alt_outlined),
                              onPressed: () {},
                            ),
                            Text(chatgpt[index]['dislike'].toString()),
                          ],
                        ),
                      ),
                    ],
                    // selected: selected[index],
                    // onSelectChanged: (bool? value) {
                    //   setState(() {
                    //     selected[index] = value!;
                    //   });
                    // },
                  );
                },
              ),
            ));
      },
    ));
  }
}
