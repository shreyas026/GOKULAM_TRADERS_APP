from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'categories', views.CategoryViewSet)
router.register(r'brands', views.BrandViewSet)
router.register(r'products', views.ProductViewSet)
router.register(r'banners', views.BannerViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('products/<int:product_pk>/reviews/', views.ReviewViewSet.as_view({'get': 'list', 'post': 'create'})),
    path('coupon/validate/', views.CouponValidateView.as_view(), name='coupon-validate'),
    path('dashboard/stats/', views.DashboardStatsView.as_view(), name='dashboard-stats'),
    path('store/location/', views.StoreLocationView.as_view(), name='store-location'),
]