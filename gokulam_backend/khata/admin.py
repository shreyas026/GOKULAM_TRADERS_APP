from django.contrib import admin
from .models import CustomerCredit, CreditTransaction, Payment

admin.site.register(CustomerCredit)
admin.site.register(CreditTransaction)
admin.site.register(Payment)