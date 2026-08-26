from django.contrib import admin
from .models import Category, Brand, Product, Review, Banner, Coupon, StoreConfig

admin.site.register(Category)
admin.site.register(Brand)
admin.site.register(Product)
admin.site.register(Review)
admin.site.register(Banner)
admin.site.register(Coupon)
admin.site.register(StoreConfig)