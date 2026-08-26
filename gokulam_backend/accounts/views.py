from rest_framework import status, permissions, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import update_session_auth_hash
from .models import User, Address
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer, AddressSerializer, ChangePasswordSerializer

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if not user.is_approved:
                return Response({
                    'message': 'Registration submitted. Awaiting admin approval.',
                    'pending': True,
                    'user': UserSerializer(user).data,
                }, status=status.HTTP_201_CREATED)
            tokens = get_tokens_for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'tokens': tokens
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data
            if not user.is_active:
                return Response({
                    'error': 'Account pending admin approval. Please wait.'
                }, status=status.HTTP_403_FORBIDDEN)
            tokens = get_tokens_for_user(user)
            return Response({
                'user': UserSerializer(user).data,
                'tokens': tokens
            })
        return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        user = request.user
        for field in ['username', 'email', 'phone', 'address', 'profile_pic']:
            if field in request.data:
                setattr(user, field, request.data[field])
        user.save()
        return Response(UserSerializer(user).data)


class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            if not request.user.check_password(serializer.data['old_password']):
                return Response({'error': 'Wrong password'}, status=status.HTTP_400_BAD_REQUEST)
            request.user.set_password(serializer.data['new_password'])
            request.user.save()
            update_session_auth_hash(request, request.user)
            return Response({'message': 'Password changed'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AddressListCreateView(generics.ListCreateAPIView):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AddressDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user)


class UserListView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


class CustomerListView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(role=User.Role.CUSTOMER)


class UpdateFCMTokenView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        request.user.fcm_token = request.data.get('fcm_token', '')
        request.user.save()
        return Response({'message': 'FCM token updated'})


class PendingApprovalsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        pending = User.objects.filter(is_approved=False, role__in=['cashier', 'delivery'])
        return Response(UserSerializer(pending, many=True).data)


class ApproveUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, user_id):
        try:
            user = User.objects.get(id=user_id, is_approved=False)
            user.is_approved = True
            user.is_active = True
            user.save()
            return Response({'message': f'{user.username} approved', 'user': UserSerializer(user).data})
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

    def delete(self, request, user_id):
        try:
            user = User.objects.get(id=user_id, is_approved=False)
            user.delete()
            return Response({'message': 'User rejected and deleted'})
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)