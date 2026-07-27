import time
from rest_framework import viewsets, permissions, generics, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import transaction
from django.utils import timezone
from .models import CustomerCredit, CreditTransaction, Payment
from .serializers import (
    CustomerCreditSerializer, CreditTransactionSerializer,
    PaymentSerializer, PaymentEntrySerializer, SupplierCreditSerializer
)
from accounts.models import User


class CustomerCreditViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CustomerCredit.objects.all()
    serializer_class = CustomerCreditSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=False, methods=['get'])
    def customers(self, request):
        credits = self.get_queryset().filter(party_type='customer')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def suppliers(self, request):
        credits = self.get_queryset().filter(party_type='supplier')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def add_supplier(self, request):
        data = request.data.copy()
        data['party_type'] = 'supplier'
        serializer = SupplierCreditSerializer(data=data)
        if serializer.is_valid():
            credit = serializer.save()
            return Response(CustomerCreditSerializer(credit).data, status=201)
        return Response(serializer.errors, status=400)

    @action(detail=True, methods=['post'])
    def add_payment(self, request, pk=None):
        credit = self.get_object()
        serializer = PaymentEntrySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        amount = serializer.data['amount']
        with transaction.atomic():
            credit.outstanding -= amount
            credit.total_repaid += amount
            credit.save()
            txn = CreditTransaction.objects.create(
                credit=credit,
                transaction_type='repayment',
                amount=amount,
                balance_after=credit.outstanding,
                note=serializer.data.get('note', ''),
                created_by=request.user
            )
        return Response(CustomerCreditSerializer(credit).data)

    @action(detail=False, methods=['get'])
    def outstanding(self, request):
        credits = self.get_queryset().filter(outstanding__gt=0).order_by('-outstanding')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def my_credit(self, request):
        credit, _ = CustomerCredit.objects.get_or_create(customer=request.user)
        return Response(CustomerCreditSerializer(credit).data)


class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Payment.objects.all()

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Payment.objects.all()
        return Payment.objects.filter(user=user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PaymentInitiateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get('order_id')
        amount = request.data.get('amount')
        payment_method = request.data.get('payment_method', 'upi')
        from orders.models import Order
        try:
            order = Order.objects.get(id=order_id, user=request.user)
            payment = Payment.objects.create(
                order=order, user=request.user,
                amount=amount, payment_method=payment_method,
                transaction_id='TXN_' + str(int(timezone.now().timestamp())),
                status='pending'
            )
            return Response(PaymentSerializer(payment).data)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=404)


class PaymentCallbackView(APIView):
    def post(self, request):
        payment_id = request.data.get('payment_id')
        razorpay_payment_id = request.data.get('razorpay_payment_id')
        try:
            payment = Payment.objects.get(id=payment_id)
            payment.razorpay_payment_id = razorpay_payment_id
            payment.status = 'completed'
            payment.save()
            payment.order.payment_status = 'completed'
            payment.order.save()
            return Response({'message': 'Payment updated'})
        except Payment.DoesNotExist:
            return Response({'error': 'Not found'}, status=404)