from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    path('addresses/', views.AddressListCreateView.as_view(), name='address-list'),
    path('addresses/<int:pk>/', views.AddressDetailView.as_view(), name='address-detail'),
    path('users/', views.UserListView.as_view(), name='user-list'),
    path('customers/', views.CustomerListView.as_view(), name='customer-list'),
    path('update-fcm/', views.UpdateFCMTokenView.as_view(), name='update-fcm'),
    path('approvals/pending/', views.PendingApprovalsView.as_view(), name='pending-approvals'),
    path('approvals/<int:user_id>/', views.ApproveUserView.as_view(), name='approve-user'),
]