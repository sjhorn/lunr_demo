import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lunr/lunr.dart' as lunr;
import 'package:lunr_demo/corpus.dart';

dynamic corpus = json.decode(corpusJson);
Map<String, dynamic> store = {};
lunr.Index index = lunr.lunr(
  (l) {
    l.ref = 'id';
    l.field('name');
    l.field('body');
    l.metadataWhitelist.add('position');
    for (var doc in corpus) {
      l.add(doc);
      store[doc['id']] = doc;
    }
  },
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        return SearchPage(
          showResults: (query) => index.search(query),
        );
      }),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<lunr.DocMatch> Function(String query) showResults;
  final _textController = TextEditingController();

  SearchPage({super.key, required this.showResults});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<lunr.DocMatch>? results;
  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        iconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
        toolbarTextStyle: theme.textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: theme.inputDecorationTheme.hintStyle,
        border: InputBorder.none,
      ),
    );
  }

  List<TextSpan> highlightRanges(List ranges, String txt) {
    List<TextSpan> chunks = [];
    int lastIndex = 0;
    for (var range in ranges) {
      //print(range);
      if (lastIndex < range[0]) {
        chunks.add(TextSpan(text: txt.substring(lastIndex, range[0])));
      }
      int end = range[0] + range[1];
      chunks.add(TextSpan(
        text: txt.substring(range[0], end),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));
      lastIndex = end;
    }
    if (lastIndex < txt.length) {
      chunks.add(TextSpan(text: txt.substring(lastIndex, txt.length)));
    }

    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = appBarTheme(context);
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => setState(() {
              results = widget.showResults(widget._textController.text);
              focusNode.requestFocus();
            }),
            icon: const Icon(Icons.search),
          ),
          title: TextField(
            focusNode: focusNode,
            controller: widget._textController,
            style: theme.textTheme.titleLarge,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            onSubmitted: (String _) => setState(() {
              results = widget.showResults(widget._textController.text);
              focusNode.requestFocus();
            }),
            decoration: const InputDecoration(hintText: 'Search'),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget._textController.clear();
                  setState(() {
                    results = null;
                    focusNode.requestFocus();
                  });
                })
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: results != null ? results!.length : corpus.length,
          itemBuilder: (context, index) {
            var item =
                results != null ? store[results![index].ref] : corpus[index];
            var titleRanges = [];
            var bodyRanges = [];
            if (results != null) {
              for (var e in results![index].matchData.metadata.entries) {
                if (e.value.containsKey('name')) {
                  titleRanges = e.value['name']!['position']!;
                }
                if (e.value.containsKey('body')) {
                  bodyRanges = e.value['body']!['position']!;
                }
              }
            }

            return Card(
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text.rich(TextSpan(
                      text: '${index + 1}. ',
                      children: highlightRanges(titleRanges, '${item["name"]}'),
                      style: Theme.of(context).textTheme.titleLarge)),
                ),
                subtitle: Text.rich(TextSpan(
                  children: highlightRanges(bodyRanges, '${item["body"]}'),
                )),
              ),
            );
          },
        ),
      ),
    );
  }
}
