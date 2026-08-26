from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'orders', views.OrderViewSet, basename='order')
router.register(r'wishlist', views.WishlistViewSet, basename='wishlist')

urlpatterns = [
    path('', include(router.urls)),
    path('cart/', views.CartView.as_view(), name='cart'),
    path('cart/items/<int:item_id>/', views.CartItemDetailView.as_view(), name='cart-item-detail'),
    path('orders/create/', views.OrderViewSet.as_view({'post': 'create_order'}), name='order-create'),
]