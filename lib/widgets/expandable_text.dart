import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText({
    required this.text,
    this.maxLines = 3,
    Key? key,
  }) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: context.size!.width);

    setState(() {
      _isOverflowing = textPainter.didExceedMaxLines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        if (_isOverflowing)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Text(
              _isExpanded ? 'Show less' : 'Read more',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
