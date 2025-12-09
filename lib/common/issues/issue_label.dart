import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class IssueLabel extends StatelessWidget {
  IssueLabel(final Label label, {super.key})
      : name = label.name!,
        color = label.color!;

  IssueLabel.gql(final Glabel label, {super.key})
      : name = label.name,
        color = label.color;
  final String name;
  final String color;

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: context.themeData
                      .extension<BorderRadiusTheme>()
                      ?.smallBorderRadius ??
                  BorderRadius.circular(4),
              color: Color(int.tryParse('0xFF$color') ?? 0xFFFFFFFF)
                  .withOpacity(0.3),
              border: Border.all(
                  color: Color(int.tryParse('0x60$color') ?? 0xFFFFFFFF),
                  width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Center(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        // color: Color(int.tryParse('0xFF$color') ?? 0xFF000000),
                        fontSize: 11,
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      );
}
