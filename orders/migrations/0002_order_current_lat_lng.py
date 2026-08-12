from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('orders', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='order',
            name='current_lat',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='order',
            name='current_lng',
            field=models.FloatField(blank=True, null=True),
        ),
    ]