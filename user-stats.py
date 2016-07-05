# -*- coding: utf-8 -*-

import datetime
from django.db.models import Count
from django.template import Template, Context
from django.contrib.auth.models import User, Group
from apps.oi.models import Changeset
from apps.oi.states import APPROVED
from apps.mycomics.models import CollectionItem
from django.conf import settings

def main():
    t = Template('''<p>Counts calculated on: {% now "r" %}</p>
  <ul>
     <li><b>Total users: </b> {{ total_users }}</li>
     <li><b>Logged-in during last 3 months: </b> {{ total_active }} ({{ pc_active|floatformat }}%)</li>
     <li><b>Members: </b> {{ total_members }} ({{ pc_members|floatformat }}%)</li>
     <li><b>Members logged-in during last 3 months: </b> {{ total_active_members }} ({{ pc_active_members|floatformat }}%)</li>
     <li><b>Have submitted changes: </b> {{ total_submitters }} ({{ pc_submitters|floatformat }}%)</li>
     <li><b>Had changes approved: </b> {{ total_successful }} ({{ pc_successful|floatformat }}%)</li>
     <li><b>Had changes approved during last 3 months: </b> {{ total_active_successful }} ({{ pc_active_successful|floatformat }}%)</li>
     <li><b>Have used my.comics.org: </b> {{ total_mycomics }} ({{ pc_mycomics|floatformat }}%)</li>
  </ul>
''')

    three_months_ago = datetime.datetime.now() - datetime.timedelta(days=90)
    member_group_id = Group.objects.get(name='member').id
    total_users = User.objects.filter(is_active=True).count()
    total_members = User.objects.filter(groups=member_group_id).count()
    total_submitters = Changeset.objects.values('indexer_id').distinct().count()
    total_successful = Changeset.objects.filter(state=APPROVED).values('indexer_id').distinct().count()
    total_active_successful = Changeset.objects.filter(state=APPROVED, modified__gt=three_months_ago).values('indexer_id').distinct().count()
    total_mycomics = CollectionItem.objects.values('collections__collector_id').distinct().count()
    total_active = User.objects.filter(is_active=True, last_login__gt=three_months_ago).count()
    total_active_members = User.objects.filter(groups=member_group_id, last_login__gt=three_months_ago).count()

    context = Context({ 'total_users': total_users,
                        'total_active': total_active,
                        'total_members': total_members,
                        'total_submitters': total_submitters,
                        'total_successful': total_successful,
                        'total_active_successful': total_active_successful,
                        'total_active_members': total_active_members,
                        'total_mycomics': total_mycomics,
                        'pc_active': 100.0 * total_active / total_users,
                        'pc_members': 100.0 * total_members / total_users,
                        'pc_submitters': 100.0 * total_submitters / total_users,
                        'pc_successful': 100.0 * total_successful / total_users,
                        'pc_active_successful': 100.0 * total_active_successful / total_users,
                        'pc_active_members': 100.0 * total_active_members / total_users,
                        'pc_mycomics': 100.0 * total_mycomics / total_users, });
    print t.render(context).encode('utf8')

if __name__ == '__main__':
    main()


