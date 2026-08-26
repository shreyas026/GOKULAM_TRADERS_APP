from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'credits', views.CustomerCreditViewSet, basename='credit')
router.register(r'payments', views.PaymentViewSet, basename='payment')

urlpatterns = [
    path('', include(router.urls)),
    path('payment/initiate/', views.PaymentInitiateView.as_view(), name='payment-initiate'),
    path('payment/callback/', views.PaymentCallbackView.as_view(), name='payment-callback'),
    path('credits/customers/', views.CustomerCreditViewSet.as_view({'get': 'customers'}), name='credit-customers'),
    path('credits/suppliers/', views.CustomerCreditViewSet.as_view({'get': 'suppliers'}), name='credit-suppliers'),
    path('credits/add_supplier/', views.CustomerCreditViewSet.as_view({'post': 'add_supplier'}), name='add-supplier'),
    path('credits/summary/', views.CustomerCreditViewSet.as_view({'get': 'summary'}), name='credit-summary'),
    path('credits/all_transactions/', views.CustomerCreditViewSet.as_view({'get': 'all_transactions'}), name='all-transactions'),
]
