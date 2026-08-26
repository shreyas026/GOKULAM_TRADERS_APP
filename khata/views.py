import time
from decimal import Decimal
from rest_framework import viewsets, permissions, generics, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import transaction
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
from .models import CustomerCredit, CreditTransaction, Payment
from .serializers import (
    CustomerCreditSerializer, CustomerCreditListSerializer, CreditTransactionSerializer,
    PaymentSerializer, PaymentEntrySerializer, SupplierCreditSerializer,
    AddCreditSerializer, KhataSummarySerializer
)
from accounts.models import User


class CustomerCreditViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CustomerCredit.objects.all()
    serializer_class = CustomerCreditListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = CustomerCredit.objects.select_related('customer').all()
        if user.role in ['admin', 'cashier']:
            pass
        else:
            qs = qs.filter(customer=user)

        search = self.request.query_params.get('search', '')
        if search:
            qs = qs.filter(
                Q(customer__username__icontains=search) |
                Q(customer__phone__icontains=search) |
                Q(supplier_name__icontains=search) |
                Q(supplier_phone__icontains=search)
            )

        party_type = self.request.query_params.get('party_type', '')
        if party_type:
            qs = qs.filter(party_type=party_type)

        return qs.order_by('-updated_at')

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CustomerCreditSerializer
        return CustomerCreditListSerializer

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def summary(self, request):
        user = request.user
        if user.role in ['admin', 'cashier']:
            customer_credits = CustomerCredit.objects.filter(party_type='customer')
            supplier_credits = CustomerCredit.objects.filter(party_type='supplier')
        else:
            customer_credits = CustomerCredit.objects.filter(customer=user, party_type='customer')
            supplier_credits = CustomerCredit.objects.none()

        today = timezone.now().date()
        today_txns = CreditTransaction.objects.filter(created_at__date=today)
        if user.role not in ['admin', 'cashier']:
            today_txns = today_txns.filter(credit__customer=user)

        today_collections = today_txns.filter(
            transaction_type='repayment'
        ).aggregate(total=Sum('amount'))['total'] or 0

        recent = CreditTransaction.objects.all().order_by('-created_at')[:10]
        if user.role not in ['admin', 'cashier']:
            recent = recent.filter(credit__customer=user)

        data = {
            'total_customers': customer_credits.filter(outstanding__gt=0).count(),
            'total_suppliers': supplier_credits.filter(outstanding__gt=0).count(),
            'total_outstanding': float(customer_credits.aggregate(total=Sum('outstanding'))['total'] or 0),
            'total_credit_given': float(customer_credits.aggregate(total=Sum('total_credit_given'))['total'] or 0),
            'total_repaid': float(customer_credits.aggregate(total=Sum('total_repaid'))['total'] or 0),
            'overdue_count': customer_credits.filter(outstanding__gt=0).count(),
            'today_collections': float(today_collections),
            'recent_transactions': CreditTransactionSerializer(recent, many=True).data,
        }
        return Response(data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def customers(self, request):
        credits = self.get_queryset().filter(party_type='customer')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def suppliers(self, request):
        credits = self.get_queryset().filter(party_type='supplier')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def add_supplier(self, request):
        data = request.data.copy()
        data['party_type'] = 'supplier'
        serializer = SupplierCreditSerializer(data=data)
        if serializer.is_valid():
            credit = serializer.save()
            return Response(CustomerCreditSerializer(credit).data, status=201)
        return Response(serializer.errors, status=400)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def add_payment(self, request, pk=None):
        credit = self.get_object()
        serializer = PaymentEntrySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        amount = serializer.validated_data['amount']
        payment_method = serializer.validated_data.get('payment_method', 'cash')
        note = serializer.validated_data.get('note', '')
        with transaction.atomic():
            credit.outstanding -= Decimal(str(amount))
            credit.total_repaid += Decimal(str(amount))
            credit.save()
            CreditTransaction.objects.create(
                credit=credit,
                transaction_type='repayment',
                amount=amount,
                balance_after=credit.outstanding,
                note=f'Payment via {payment_method}' + (f' - {note}' if note else ''),
                created_by=request.user
            )
        return Response(CustomerCreditSerializer(credit).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def add_credit(self, request, pk=None):
        credit = self.get_object()
        serializer = AddCreditSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        amount = serializer.validated_data['amount']
        note = serializer.validated_data.get('note', '')
        with transaction.atomic():
            credit.outstanding += Decimal(str(amount))
            credit.total_credit_given += Decimal(str(amount))
            credit.save()
            CreditTransaction.objects.create(
                credit=credit,
                transaction_type='purchase',
                amount=amount,
                balance_after=credit.outstanding,
                note=note or 'Manual credit entry',
                created_by=request.user
            )
        return Response(CustomerCreditSerializer(credit).data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def outstanding(self, request):
        credits = self.get_queryset().filter(outstanding__gt=0).order_by('-outstanding')
        serializer = self.get_serializer(credits, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def my_credit(self, request):
        credit, _ = CustomerCredit.objects.get_or_create(customer=request.user, party_type='customer')
        return Response(CustomerCreditSerializer(credit).data)

    @action(detail=True, methods=['get'])
    def transactions(self, request, pk=None):
        credit = self.get_object()
        txns = CreditTransaction.objects.filter(credit=credit).order_by('-created_at')

        date_from = request.query_params.get('date_from', '')
        date_to = request.query_params.get('date_to', '')
        txn_type = request.query_params.get('type', '')

        if date_from:
            txns = txns.filter(created_at__date__gte=date_from)
        if date_to:
            txns = txns.filter(created_at__date__lte=date_to)
        if txn_type:
            txns = txns.filter(transaction_type=txn_type)

        page = self.paginate_queryset(txns)
        if page is not None:
            return self.get_paginated_response(CreditTransactionSerializer(page, many=True).data)

        return Response(CreditTransactionSerializer(txns[:100], many=True).data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def all_transactions(self, request):
        txns = CreditTransaction.objects.select_related('credit', 'credit__customer').all().order_by('-created_at')

        date_from = request.query_params.get('date_from', '')
        date_to = request.query_params.get('date_to', '')
        txn_type = request.query_params.get('type', '')
        search = request.query_params.get('search', '')

        if date_from:
            txns = txns.filter(created_at__date__gte=date_from)
        if date_to:
            txns = txns.filter(created_at__date__lte=date_to)
        if txn_type:
            txns = txns.filter(transaction_type=txn_type)
        if search:
            txns = txns.filter(
                Q(credit__customer__username__icontains=search) |
                Q(credit__supplier_name__icontains=search) |
                Q(note__icontains=search)
            )

        return Response(CreditTransactionSerializer(txns[:100], many=True).data)


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
