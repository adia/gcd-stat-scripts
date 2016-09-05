# -*- coding: utf-8 -*-

import django
from apps.gcd.models import Issue
from apps.gcd.models.story import STORY_TYPES
from django.db.models import Sum, F
from django.template import Template, Context

def main():
    django.setup()
    t = Template('''<!DOCTYPE HTML>
<html>
<head>
  <title>Issues with more indexed pages than total pages</title>
  <meta charset='utf-8'>
  <link rel='stylesheet' href='style.css' type='text/css'>
</head>
<body>
{% spaceless %}
<h1>Issues with more indexed pages than total pages</h1>
<p>{{ issue_list|length }} issues; updated {% now "r" %}</p>
{% for issue in issue_list %}
    {% ifchanged issue.series.publisher %}
        <h2><img src='http://www.comics.org/static/img/gcd/flags/{{ issue.series.publisher.country.code }}.png' alt='{{ issue.series.publisher.country.name }}'> {{ issue.series.publisher }}</h2>
    {% endifchanged %}
    {% ifchanged issue.series %}
        <h3>{{ issue.series }}</h3>
    {% endifchanged %}
        <p><a href="http://www.comics.org{{ issue.get_absolute_url }}">{{ issue }}</a>
           ({{ issue.indexed_pages|floatformat }} / {{ issue.page_count|floatformat }} pg)</p>
{% endfor %}
</body>
</html>
{% endspaceless %}
''')
    issue_list = Issue.objects.annotate(indexed_pages=Sum('story__page_count')) \
            .exclude(deleted=True) \
            .exclude(story__type=STORY_TYPES['insert']) \
            .exclude(story__deleted=True) \
            .filter(indexed_pages__gt=F('page_count')) \
            .order_by('series__country__name', 'series__publisher__name', 'series__sort_name')
    print(t.render(Context({'issue_list': issue_list})).encode('utf8'))

if __name__ == '__main__':
    main()


