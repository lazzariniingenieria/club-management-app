import 'member.dart';

enum MemberCollectionFilter {
  all('all'),
  overdue('overdue'),
  toCollect('to-collect');

  const MemberCollectionFilter(this.queryValue);

  final String queryValue;

  static MemberCollectionFilter fromQueryValue(String? queryValue) {
    for (final filter in values) {
      if (filter.queryValue == queryValue) return filter;
    }

    return all;
  }

  bool matches(Member member, Set<int> selectedMemberIds) {
    return switch (this) {
      MemberCollectionFilter.all => true,
      MemberCollectionFilter.overdue => member.isOverdue,
      MemberCollectionFilter.toCollect => selectedMemberIds.contains(member.id),
    };
  }
}
