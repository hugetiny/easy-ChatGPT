import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "dotenv");
  await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!);
  runApp(const MyApp());
}

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
      _pings = List.filled(data.length, null);
      for (var i = 0; i < data.length; ++i) {
        final stopwatch = Stopwatch()..start();

        http.get(Uri.parse('https://' + data[i]['url'])).then((value) {
          setState(() {
            _pings[i] = (value.statusCode == 200)
                ? stopwatch.elapsedMilliseconds.toString() + 'ms'
                : 'failed';
          });
          stopwatch.stop();
        }).onError((error, stackTrace) {
          if (kDebugMode) {
            print(error);
          }
          setState(() {
            _pings[i] = 'failed';
          });
        });

        // final ping = Ping(data[i]['url'],
        //     encoding: const Utf8Codec(allowMalformed: true), count: 2);
        // // print('Running command: ${ping.command}');
        // ping.stream.listen((e) {
        //   setState(() {
        //     _pings[i] = (e.summary?.time?.inMilliseconds == 0)
        //         ? S.of(context).failed
        //         : (e.summary?.time?.inMilliseconds).toString() + 'ms';
        //   });
        // });
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
                DataColumn(
                  label: Text(S.of(context).latency),
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
                      DataCell(_pings.isEmpty || _pings[index] == null
                          ? const LinearProgressIndicator()
                          : _pings[index] == 'failed'
                              ? Text(S.of(context).failed)
                              : Text(_pings[index])),
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
