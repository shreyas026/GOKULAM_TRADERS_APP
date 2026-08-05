from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, Address

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['username', 'email', 'phone', 'password', 'address', 'role']

    def create(self, validated_data):
        role = validated_data.get('role', User.Role.CUSTOMER)
        is_staff_role = role in [User.Role.CASHIER, User.Role.DELIVERY]
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email') or '',
            phone=validated_data.get('phone') or None,
            password=validated_data['password'],
            address=validated_data.get('address') or '',
            role=role,
            is_approved=not is_staff_role,
            is_active=not is_staff_role,
        )
        return user


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, data):
        user = authenticate(username=data['username'], password=data['password'])
        if not user:
            raise serializers.ValidationError("Invalid credentials")
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'phone', 'role', 'address', 'profile_pic', 'date_joined']


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = '__all__'
        read_only_fields = ['user']


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField()
    new_password = serializers.CharField(min_length=6)