# -*- coding: utf-8 -*-

import django
import datetime
import json
from django.conf import settings
from django.contrib.auth.models import User
from apps.oi import states
from apps.oi.models import Changeset, ChangesetComment, CTYPES

def main():
    step = 7
    top = 30
    years = range(2010, 2017)
    months = range(1, 13)
    data = [[[[[0 for i in range(top + 1)]
        for auto in range(2)]
        for approved in range(2)]
        for month in months]
        for year in years]
    django.setup()
    anon = User.objects.get(username=settings.ANON_USER_NAME)
    changes = Changeset.objects.exclude(indexer=anon).filter(
            change_type=CTYPES['issue'],
            created__gt=datetime.date(2010, 1, 1),
            state__in=[states.APPROVED,states.DISCARDED])
    for item in changes:
        auto = 0
        if ChangesetComment.objects.filter(changeset=item, text__startswith='This is an automatic').exists():
            auto = 1
        approved = 1 if item.state == states.APPROVED else 0;
        i = (item.modified - item.created).days / step
        if i > top:
            i = top
        data[item.modified.year - 2010][item.modified.month - 1][approved][auto][i] += 1
    print 'var data =', json.dumps(data), ';'

if __name__ == '__main__':
    main()


