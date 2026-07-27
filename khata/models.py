from django.db import models
from django.conf import settings

class CustomerCredit(models.Model):
    class PartyType(models.TextChoices):
        CUSTOMER = 'customer', 'Customer'
        SUPPLIER = 'supplier', 'Supplier'

    party_type = models.CharField(max_length=20, choices=PartyType.choices, default=PartyType.CUSTOMER)
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='credits', null=True, blank=True)
    supplier_name = models.CharField(max_length=200, blank=True)
    supplier_phone = models.CharField(max_length=15, blank=True)
    credit_limit = models.DecimalField(max_digits=12, decimal_places=2, default=5000)
    outstanding = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_credit_given = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_repaid = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        if self.party_type == 'supplier':
            return f"Supplier: {self.supplier_name} - Outstanding: {self.outstanding}"
        return f"{self.customer.username if self.customer else '?'} - Outstanding: {self.outstanding}"


class CreditTransaction(models.Model):
    class TransactionType(models.TextChoices):
        PURCHASE = 'purchase', 'Purchase'
        REPAYMENT = 'repayment', 'Repayment'
        ADJUSTMENT = 'adjustment', 'Adjustment'

    credit = models.ForeignKey(CustomerCredit, on_delete=models.CASCADE, related_name='transactions')
    order = models.ForeignKey('orders.Order', on_delete=models.SET_NULL, null=True, blank=True)
    transaction_type = models.CharField(max_length=20, choices=TransactionType.choices)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    balance_after = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.TextField(blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_transaction_type_display()} - {self.amount} ({self.credit.customer.username})"


class Payment(models.Model):
    class PaymentStatus(models.TextChoices):
        PENDING = 'pending', 'Pending'
        COMPLETED = 'completed', 'Completed'
        FAILED = 'failed', 'Failed'
        REFUNDED = 'refunded', 'Refunded'

    order = models.ForeignKey('orders.Order', on_delete=models.CASCADE, related_name='payments')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20)
    transaction_id = models.CharField(max_length=100, blank=True)
    razorpay_order_id = models.CharField(max_length=100, blank=True)
    razorpay_payment_id = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment {self.transaction_id} - {self.amount}"