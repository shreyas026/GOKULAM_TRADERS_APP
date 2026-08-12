from rest_framework import viewsets, permissions, filters, generics, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q, Count, F
from django.utils import timezone
from .models import Category, Brand, Product, Review, Banner, Coupon
from .serializers import (
    CategorySerializer, BrandSerializer, ProductListSerializer,
    ProductDetailSerializer, ProductCreateUpdateSerializer, ReviewSerializer, BannerSerializer, CouponSerializer
)


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    search_fields = ['name']

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]


class BrandViewSet(viewsets.ModelViewSet):
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    search_fields = ['name']

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.select_related('category', 'brand').all()
    filterset_fields = ['category', 'brand', 'is_available', 'is_featured']
    search_fields = ['name', 'sku', 'barcode', 'brand__name']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        if self.action in ['create', 'update', 'partial_update']:
            return ProductCreateUpdateSerializer
        return ProductListSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        if not self.request.user.is_staff:
            qs = qs.filter(is_available=True)
        return qs

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    @action(detail=False, methods=['get'])
    def search(self, request):
        query = request.query_params.get('q', '')
        if not query:
            return Response([])
        products = self.get_queryset().filter(
            Q(name__icontains=query) | Q(sku__icontains=query) |
            Q(barcode__icontains=query) | Q(brand__name__icontains=query)
        )[:20]
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_barcode(self, request):
        barcode = request.query_params.get('code', '')
        if not barcode:
            return Response({'error': 'Barcode required'}, status=400)
        product = self.get_queryset().filter(barcode=barcode).first()
        if not product:
            return Response({'error': 'Not found'}, status=404)
        return Response(ProductDetailSerializer(product).data)

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        products = self.get_queryset().filter(stock__lte=F('low_stock_threshold'))
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)


class ReviewViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Review.objects.filter(product_id=self.kwargs.get('product_pk'))

    def perform_create(self, serializer):
        serializer.save(user=self.request.user, product_id=self.kwargs.get('product_pk'))


class BannerViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Banner.objects.filter(is_active=True).order_by('order')
    serializer_class = BannerSerializer


class CouponValidateView(APIView):
    def post(self, request):
        code = request.data.get('code', '')
        amount = float(request.data.get('amount', 0))
        try:
            coupon = Coupon.objects.get(code=code, is_active=True,
                                         valid_from__lte=timezone.now(), valid_to__gte=timezone.now())
            if coupon.used_count >= coupon.usage_limit:
                return Response({'valid': False, 'error': 'Coupon usage limit reached'})
            if amount < coupon.min_order_amount:
                return Response({'valid': False, 'error': f'Minimum order: {coupon.min_order_amount}'})
            discount = coupon.discount_amount if coupon.discount_amount > 0 else (amount * coupon.discount_percent / 100)
            if coupon.max_discount:
                discount = min(discount, coupon.max_discount)
            return Response({'valid': True, 'discount': float(discount), 'code': code})
        except Coupon.DoesNotExist:
            return Response({'valid': False, 'error': 'Invalid or expired coupon'})


class DashboardStatsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        from django.db.models import Sum
        from orders.models import Order

        total_orders = Order.objects.count()
        pending_orders = Order.objects.filter(status='pending').count()
        total_revenue = Order.objects.filter(status='delivered').aggregate(Sum('total_amount'))['total_amount__sum'] or 0
        total_products = Product.objects.count()
        low_stock = Product.objects.filter(stock__lte=F('low_stock_threshold')).count()

        return Response({
            'total_orders': total_orders,
            'pending_orders': pending_orders,
            'total_revenue': total_revenue,
            'total_products': total_products,
            'low_stock': low_stock,
        })


class StoreLocationView(APIView):
    def get(self, request):
        return Response({
            'name': 'Gokulam Traders',
            'address': '123 Main Road, Bangalore - 560001',
            'latitude': 12.9716,
            'longitude': 77.5946,
            'delivery_radius_km': 5,
        })


class ProductImageUploadView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        image = request.FILES.get('image')
        if not image:
            return Response({'error': 'image file required'}, status=400)
        if image.size > 5 * 1024 * 1024:
            return Response({'error': 'Image must be under 5 MB'}, status=400)
        import os
        from django.conf import settings
        from django.utils.crypto import get_random_string
        ext = os.path.splitext(image.name)[1].lower()
        if ext not in ['.jpg', '.jpeg', '.png', '.webp', '.gif']:
            ext = '.jpg'
        filename = f'product_{get_random_string(10)}{ext}'
        subdir = os.path.join(settings.MEDIA_ROOT, 'product_images')
        os.makedirs(subdir, exist_ok=True)
        path = os.path.join(subdir, filename)
        with open(path, 'wb') as f:
            for chunk in image.chunks():
                f.write(chunk)
        url = settings.MEDIA_URL + 'product_images/' + filename
        absolute = request.build_absolute_uri(url)
        return Response({'url': absolute}, status=201)