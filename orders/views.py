import random
import string
from rest_framework import serializers, viewsets, permissions, generics, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import transaction
from django.db.models import Sum, F, Q
from django.utils import timezone
from .models import Cart, CartItem, Order, OrderItem, OrderStatusLog, Wishlist
from .serializers import (
    CartSerializer, CartItemSerializer, AddToCartSerializer,
    OrderListSerializer, OrderDetailSerializer, CreateOrderSerializer,
    OrderStatusUpdateSerializer, WishlistSerializer
)
from products.models import Product, Coupon
from khata.models import CustomerCredit, CreditTransaction


def generate_order_id():
    return 'GT' + ''.join(random.choices(string.digits, k=8))


class CartView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        cart, _ = Cart.objects.get_or_create(user=request.user)
        return Response(CartSerializer(cart).data)

    def post(self, request):
        serializer = AddToCartSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        cart, _ = Cart.objects.get_or_create(user=request.user)
        product = Product.objects.get(id=serializer.data['product_id'])
        if not product.is_available or product.stock < 1:
            return Response({'error': 'Product unavailable'}, status=400)
        item, created = CartItem.objects.get_or_create(
            cart=cart, product=product,
            defaults={'quantity': serializer.data['quantity']}
        )
        if not created:
            item.quantity += serializer.data['quantity']
            item.save()
        return Response(CartSerializer(cart).data)

    def delete(self, request):
        CartItem.objects.filter(cart__user=request.user).delete()
        return Response({'message': 'Cart cleared'})


class CartItemDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, item_id):
        try:
            item = CartItem.objects.get(id=item_id, cart__user=request.user)
            item.quantity = max(1, request.data.get('quantity', item.quantity))
            item.save()
            cart = Cart.objects.get(user=request.user)
            return Response(CartSerializer(cart).data)
        except CartItem.DoesNotExist:
            return Response({'error': 'Item not found'}, status=404)

    def delete(self, request, item_id):
        CartItem.objects.filter(id=item_id, cart__user=request.user).delete()
        cart = Cart.objects.get(user=request.user)
        return Response(CartSerializer(cart).data)


class OrderViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Order.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return OrderDetailSerializer
        return OrderListSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in ['admin', 'cashier']:
            return Order.objects.all().order_by('-created_at')
        if user.role == 'delivery':
            return Order.objects.filter(assigned_to=user).order_by('-created_at')
        return Order.objects.filter(user=user).order_by('-created_at')

    @action(detail=False, methods=['post'])
    def create_order(self, request):
        serializer = CreateOrderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        cart = Cart.objects.filter(user=request.user).first()
        if not cart or not cart.items.exists():
            return Response({'error': 'Cart is empty'}, status=400)
        with transaction.atomic():
            items_data = []
            subtotal = 0
            total_gst = 0
            for item in cart.items.all():
                product = item.product
                if product.stock < item.quantity:
                    return Response({'error': f'Insufficient stock for {product.name}'}, status=400)
                item_total = product.selling_price * item.quantity
                gst = item_total * product.gst_percent / 100
                subtotal += item_total
                total_gst += gst
                items_data.append({
                    'product': product,
                    'qty': item.quantity,
                    'price': product.selling_price,
                    'gst': product.gst_percent,
                    'gst_amt': gst,
                    'total': item_total,
                })
            discount = 0
            coupon_code = serializer.data.get('coupon_code', '')
            if coupon_code:
                try:
                    coupon = Coupon.objects.get(code=coupon_code, is_active=True,
                                                 valid_from__lte=timezone.now(), valid_to__gte=timezone.now())
                    if coupon.used_count < coupon.usage_limit and subtotal >= coupon.min_order_amount:
                        discount = coupon.discount_amount if coupon.discount_amount > 0 else (subtotal * coupon.discount_percent / 100)
                        if coupon.max_discount:
                            discount = min(discount, coupon.max_discount)
                        coupon.used_count += 1
                        coupon.save()
                except Coupon.DoesNotExist:
                    pass
            delivery_charge = 0
            address = None
            if serializer.data['delivery_type'] == Order.DeliveryType.HOME_DELIVERY:
                from accounts.models import Address
                address = Address.objects.filter(id=serializer.data.get('address_id'), user=request.user).first()
                if request.user.role == 'customer' and not address:
                    return Response({'error': 'Delivery address required'}, status=400)
                if not address:
                    address = None
                if address and address.latitude and address.longitude:
                    STORE_LAT, STORE_LON = 12.9716, 77.5946
                    from math import radians, sin, cos, sqrt, atan2
                    dlat = radians(address.latitude - STORE_LAT)
                    dlon = radians(address.longitude - STORE_LON)
                    a = sin(dlat/2)**2 + cos(radians(STORE_LAT)) * cos(radians(address.latitude)) * sin(dlon/2)**2
                    dist_km = 6371 * 2 * atan2(sqrt(a), sqrt(1-a))
                    if dist_km > 5:
                        return Response({'error': f'Delivery address is {dist_km:.1f} km away. Maximum 5 km allowed.'}, status=400)
                delivery_charge = 20
            total = subtotal + total_gst + delivery_charge - discount
            order = Order.objects.create(
                order_id=generate_order_id(),
                user=request.user,
                delivery_type=serializer.data['delivery_type'],
                payment_method=serializer.data['payment_method'],
                subtotal=subtotal,
                gst_amount=total_gst,
                discount_amount=discount,
                delivery_charge=delivery_charge,
                total_amount=total,
                delivery_address=address,
                notes=serializer.data.get('notes', ''),
            )
            for item in items_data:
                OrderItem.objects.create(
                    order=order,
                    product=item['product'],
                    product_name=item['product'].name,
                    product_image=item['product'].images[0] if item['product'].images else '',
                    quantity=item['qty'],
                    price=item['price'],
                    gst_percent=item['gst'],
                    gst_amount=item['gst_amt'],
                    total=item['total'],
                )
                item['product'].stock -= item['qty']
                item['product'].total_sold += item['qty']
                item['product'].save()
            OrderStatusLog.objects.create(order=order, status='pending', note='Order placed')
            cart.items.all().delete()
            if serializer.data['payment_method'] == Order.PaymentMethod.CREDIT:
                credit, _ = CustomerCredit.objects.get_or_create(customer=request.user)
                if credit.outstanding + total > credit.credit_limit:
                    raise serializers.ValidationError({'error': 'Credit limit exceeded'})
                credit.outstanding += total
                credit.total_credit_given += total
                credit.save()
                CreditTransaction.objects.create(
                    credit=credit, order=order,
                    transaction_type='purchase', amount=total,
                    balance_after=credit.outstanding,
                )
            return Response(OrderDetailSerializer(order).data, status=201)

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        order = self.get_object()
        user = request.user
        new_status = request.data.get('status', '')
        note = request.data.get('note', '')

        allowed = Order.ROLE_CAN_UPDATE.get(user.role, [])
        if new_status not in allowed:
            return Response({'error': f'Your role ({user.role}) cannot change status to {new_status}'}, status=403)

        flow = Order.TAKEAWAY_FLOW if order.delivery_type == 'takeaway' else Order.HOME_DELIVERY_FLOW
        if order.status not in flow and new_status != 'cancelled':
            return Response({'error': f'Cannot update status from {order.status} for {order.delivery_type} orders'}, status=400)

        if new_status != 'cancelled':
            current_idx = flow.index(order.status) if order.status in flow else -1
            next_idx = flow.index(new_status) if new_status in flow else -1
            if next_idx != current_idx + 1:
                return Response({'error': f'Invalid status transition: {order.status} -> {new_status}. Expected: {flow[current_idx + 1] if current_idx + 1 < len(flow) else "delivered"}'}, status=400)

        order.status = new_status
        if new_status == 'delivered':
            order.payment_status = 'completed'
        order.save()
        OrderStatusLog.objects.create(
            order=order,
            status=new_status,
            note=note,
            created_by=user
        )
        return Response(OrderDetailSerializer(order).data)

    @action(detail=True, methods=['post'])
    def assign_delivery(self, request, pk=None):
        user = request.user
        if user.role not in ['admin', 'cashier']:
            return Response({'error': 'Only admin or cashier can assign delivery'}, status=403)
        order = self.get_object()
        if order.delivery_type != Order.DeliveryType.HOME_DELIVERY:
            return Response({'error': 'Only home delivery orders can be assigned'}, status=400)
        staff_id = request.data.get('staff_id')
        from accounts.models import User
        try:
            staff = User.objects.get(id=staff_id, role='delivery')
            order.assigned_to = staff
            order.status = 'out_for_delivery'
            order.save()
            OrderStatusLog.objects.create(
                order=order, status='out_for_delivery',
                note=f'Assigned to {staff.username}', created_by=user
            )
            return Response({'message': f'Assigned to {staff.username}'})
        except User.DoesNotExist:
            return Response({'error': 'Staff not found'}, status=404)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        orders = self.get_queryset().filter(status='pending')
        serializer = OrderListSerializer(orders, many=True)
        return Response(serializer.data)


class WishlistViewSet(viewsets.ModelViewSet):
    serializer_class = WishlistSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Wishlist.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['delete'], url_path='remove/(?P<product_id>[^/.]+)')
    def remove_product(self, request, product_id=None):
        Wishlist.objects.filter(user=request.user, product_id=product_id).delete()
        return Response({'message': 'Removed from wishlist'})