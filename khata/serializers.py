from rest_framework import serializers
from .models import CustomerCredit, CreditTransaction, Payment
from accounts.serializers import UserSerializer


class CreditTransactionSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()

    class Meta:
        model = CreditTransaction
        fields = '__all__'

    def get_customer_name(self, obj):
        if obj.credit and obj.credit.customer:
            return obj.credit.customer.username
        if obj.credit and obj.credit.party_type == 'supplier':
            return obj.credit.supplier_name
        return ''


class CustomerCreditSerializer(serializers.ModelSerializer):
    customer_detail = UserSerializer(source='customer', read_only=True)
    transactions = serializers.SerializerMethodField()
    display_name = serializers.SerializerMethodField()
    available_credit = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()

    class Meta:
        model = CustomerCredit
        fields = '__all__'
        read_only_fields = ['transactions']

    def get_transactions(self, obj):
        txns = obj.transactions.all().order_by('-created_at')[:50]
        return CreditTransactionSerializer(txns, many=True).data

    def get_display_name(self, obj):
        if obj.party_type == 'supplier':
            return obj.supplier_name or 'Supplier'
        return obj.customer.username if obj.customer else 'Customer'

    def get_available_credit(self, obj):
        return float(obj.credit_limit) - float(obj.outstanding)

    def get_customer_phone(self, obj):
        if obj.customer:
            return obj.customer.phone or ''
        return obj.supplier_phone or ''


class CustomerCreditListSerializer(serializers.ModelSerializer):
    display_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    available_credit = serializers.SerializerMethodField()
    transaction_count = serializers.SerializerMethodField()

    class Meta:
        model = CustomerCredit
        fields = ['id', 'party_type', 'customer', 'supplier_name', 'supplier_phone',
                  'credit_limit', 'outstanding', 'total_credit_given', 'total_repaid',
                  'is_active', 'display_name', 'customer_phone', 'available_credit',
                  'transaction_count', 'created_at', 'updated_at']

    def get_display_name(self, obj):
        if obj.party_type == 'supplier':
            return obj.supplier_name or 'Supplier'
        return obj.customer.username if obj.customer else 'Customer'

    def get_customer_phone(self, obj):
        if obj.customer:
            return obj.customer.phone or ''
        return obj.supplier_phone or ''

    def get_available_credit(self, obj):
        return float(obj.credit_limit) - float(obj.outstanding)

    def get_transaction_count(self, obj):
        return obj.transactions.count()


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'
        read_only_fields = ['user']


class PaymentEntrySerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.01)
    payment_method = serializers.ChoiceField(
        choices=['cash', 'upi', 'bank_transfer', 'card', 'other'],
        default='cash'
    )
    note = serializers.CharField(required=False, allow_blank=True)


class AddCreditSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.01)
    note = serializers.CharField(required=False, allow_blank=True)


class SupplierCreditSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerCredit
        fields = ['id', 'supplier_name', 'supplier_phone', 'credit_limit', 'is_active', 'created_at']


class KhataSummarySerializer(serializers.Serializer):
    total_customers = serializers.IntegerField()
    total_suppliers = serializers.IntegerField()
    total_outstanding = serializers.FloatField()
    total_credit_given = serializers.FloatField()
    total_repaid = serializers.FloatField()
    overdue_count = serializers.IntegerField()
    today_collections = serializers.FloatField()
    recent_transactions = CreditTransactionSerializer(many=True)
