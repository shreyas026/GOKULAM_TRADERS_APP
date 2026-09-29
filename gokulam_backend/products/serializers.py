from decimal import Decimal

from rest_framework import serializers
from .models import Category, Brand, Product, Review, Banner, Coupon, StoreConfig

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = '__all__'


class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    brand_name = serializers.CharField(source='brand.name', read_only=True, default='')
    primary_image = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id', 'name', 'category', 'category_name', 'brand', 'brand_name', 'sku',
                  'selling_price', 'mrp', 'discount_percent', 'gst_percent', 'stock',
                  'primary_image', 'is_available', 'is_featured', 'rating', 'total_sold']

    def get_primary_image(self, obj):
        if obj.images:
            return obj.images[0] if isinstance(obj.images, list) else ''
        return ''


class ProductDetailSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    brand_name = serializers.CharField(source='brand.name', read_only=True, default='')

    class Meta:
        model = Product
        fields = '__all__'


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    brand_name = serializers.CharField(source='brand.name', read_only=True, default='')

    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['rating', 'total_sold', 'created_at', 'updated_at']


class ReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Review
        fields = ['id', 'product', 'user', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['user']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class BannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = '__all__'


class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = '__all__'


class StoreConfigSerializer(serializers.ModelSerializer):
    name = serializers.CharField(max_length=200, allow_blank=True)
    address = serializers.CharField(max_length=500, allow_blank=True)
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)
    delivery_radius_km = serializers.FloatField(min_value=0.1, max_value=100)
    delivery_charge_per_half_km = serializers.DecimalField(
        max_digits=6, decimal_places=2, min_value=Decimal('0'), max_value=Decimal('9999.99'),
        coerce_to_string=False,
    )

    class Meta:
        model = StoreConfig
        fields = ['name', 'address', 'latitude', 'longitude', 'delivery_radius_km', 'delivery_charge_per_half_km']