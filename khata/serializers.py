from rest_framework import serializers
from .models import CustomerCredit, CreditTransaction, Payment
from accounts.serializers import UserSerializer

class CreditTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = CreditTransaction
        fields = '__all__'


class CustomerCreditSerializer(serializers.ModelSerializer):
    customer_detail = UserSerializer(source='customer', read_only=True)
    transactions = serializers.SerializerMethodField()

    class Meta:
        model = CustomerCredit
        fields = '__all__'
        read_only_fields = ['transactions']

    def get_transactions(self, obj):
        txns = obj.transactions.all().order_by('-created_at')[:30]
        return CreditTransactionSerializer(txns, many=True).data

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if instance.party_type == 'supplier':
            data['display_name'] = instance.supplier_name or 'Supplier'
        else:
            data['display_name'] = instance.customer.username if instance.customer else 'Customer'
        return data


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'
        read_only_fields = ['user']


class PaymentEntrySerializer(serializers.Serializer):
    customer_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    note = serializers.CharField(required=False, allow_blank=True)


class SupplierCreditSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerCredit
        fields = ['id', 'supplier_name', 'supplier_phone', 'credit_limit', 'outstanding', 'is_active', 'note', 'created_at']