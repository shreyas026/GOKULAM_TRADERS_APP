from rest_framework import serializers
from .models import Cart, CartItem, Order, OrderItem, OrderStatusLog, Wishlist
from products.models import Product
from products.serializers import ProductListSerializer

class CartItemSerializer(serializers.ModelSerializer):
    product_detail = ProductListSerializer(source='product', read_only=True)
    subtotal = serializers.SerializerMethodField()

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_detail', 'quantity', 'subtotal', 'created_at']
        read_only_fields = ['cart']

    def get_subtotal(self, obj):
        return float(obj.product.selling_price * obj.quantity)


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ['id', 'user', 'items', 'total', 'created_at', 'updated_at']

    def get_total(self, obj):
        total = sum(item.product.selling_price * item.quantity for item in obj.items.all())
        return float(total)


class AddToCartSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.IntegerField(default=1, min_value=1)


class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = '__all__'


class OrderListSerializer(serializers.ModelSerializer):
    item_count = serializers.SerializerMethodField()
    first_item_image = serializers.SerializerMethodField()
    delivery_lat = serializers.SerializerMethodField()
    delivery_lng = serializers.SerializerMethodField()
    delivery_address_text = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['id', 'order_id', 'status', 'total_amount', 'payment_status',
                  'delivery_type', 'item_count', 'first_item_image', 'created_at',
                  'delivery_lat', 'delivery_lng', 'delivery_address_text']

    def get_item_count(self, obj):
        return obj.items.count()

    def get_first_item_image(self, obj):
        item = obj.items.first()
        return item.product_image if item else ''

    def get_delivery_lat(self, obj):
        addr = obj.delivery_address
        return float(addr.latitude) if addr and addr.latitude else None

    def get_delivery_lng(self, obj):
        addr = obj.delivery_address
        return float(addr.longitude) if addr and addr.longitude else None

    def get_delivery_address_text(self, obj):
        addr = obj.delivery_address
        if addr:
            return f"{addr.full_address}, {addr.city}"
        return obj.notes


class OrderDetailSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    delivery_address_detail = serializers.SerializerMethodField()
    assigned_to_detail = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = ['user', 'order_id']

    def get_delivery_address_detail(self, obj):
        if obj.delivery_address:
            from accounts.serializers import AddressSerializer
            return AddressSerializer(obj.delivery_address).data
        return None

    def get_assigned_to_detail(self, obj):
        if obj.assigned_to:
            return {
                'id': obj.assigned_to.id,
                'username': obj.assigned_to.username,
                'phone': obj.assigned_to.phone,
            }
        return None


class CreateOrderSerializer(serializers.Serializer):
    delivery_type = serializers.ChoiceField(choices=Order.DeliveryType.choices)
    address_id = serializers.IntegerField(required=False, allow_null=True)
    delivery_address_text = serializers.CharField(required=False, allow_blank=True)
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices)
    notes = serializers.CharField(required=False, allow_blank=True)
    coupon_code = serializers.CharField(required=False, allow_blank=True)


class OrderStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Order.Status.choices)
    note = serializers.CharField(required=False, allow_blank=True)


class WishlistSerializer(serializers.ModelSerializer):
    product_detail = ProductListSerializer(source='product', read_only=True)

    class Meta:
        model = Wishlist
        fields = ['id', 'product', 'product_detail', 'created_at']
        read_only_fields = ['user']