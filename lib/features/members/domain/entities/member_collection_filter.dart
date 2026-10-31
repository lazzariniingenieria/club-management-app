import 'member.dart';

enum MemberCollectionFilter {
  all('all'),
  overdue('overdue'),
  inactive('inactive');

  const MemberCollectionFilter(this.queryValue);

  final String queryValue;

  static MemberCollectionFilter fromQueryValue(String? queryValue) {
    for (final filter in values) {
      if (filter.queryValue == queryValue) return filter;
    }

    return all;
  }

  bool matches(Member member) {
    return switch (this) {
      MemberCollectionFilter.all => member.isActive,
      MemberCollectionFilter.overdue => member.isActive && member.isOverdue,
      MemberCollectionFilter.inactive => !member.isActive,
    };
  }
}
