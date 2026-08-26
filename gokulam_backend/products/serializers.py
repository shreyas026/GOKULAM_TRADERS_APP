from rest_framework import serializers
from .models import Category, Brand, Product, Review, Banner, Coupon

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