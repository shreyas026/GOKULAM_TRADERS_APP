# Generated migration for unique_together on (customer, party_type)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('khata', '0002_alter_customercredit_unique_together_and_more'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='customercredit',
            unique_together={('customer', 'party_type')},
        ),
    ]
