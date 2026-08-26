import os
import sys
import django

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gokulam_backend.settings')
django.setup()

from datetime import timedelta
from django.utils import timezone
from accounts.models import User, Address
from products.models import Category, Brand, Product, Banner, Coupon
from khata.models import CustomerCredit

print("Seeding database...")

# Create users
admin, created = User.objects.get_or_create(
    username='admin', defaults={'email': 'admin@gokulam.com', 'phone': '9876543200', 'role': 'admin', 'first_name': 'Admin', 'last_name': 'User', 'is_staff': True, 'is_superuser': True, 'address': 'Gokulam Store, Bangalore'}
)
if created:
    admin.set_password('admin123')
    admin.save()

customer1, _ = User.objects.get_or_create(
    username='ravi_kumar', defaults={'email': 'ravi@gmail.com', 'phone': '9876543210', 'role': 'customer', 'first_name': 'Ravi', 'last_name': 'Kumar', 'address': '123 Main Street, Bangalore'}
)
customer2, _ = User.objects.get_or_create(
    username='suresh_babu', defaults={'email': 'suresh@gmail.com', 'phone': '9876543211', 'role': 'customer', 'first_name': 'Suresh', 'last_name': 'Babu', 'address': '456 Lake Road, Bangalore'}
)
customer3, _ = User.objects.get_or_create(
    username='priya_sharma', defaults={'email': 'priya@gmail.com', 'phone': '9876543212', 'role': 'customer', 'first_name': 'Priya', 'last_name': 'Sharma', 'address': '789 Park Avenue, Bangalore'}
)

cashier, _ = User.objects.get_or_create(
    username='cashier1', defaults={'email': 'cashier@gokulam.com', 'phone': '9876543220', 'role': 'cashier', 'first_name': 'Murugan', 'last_name': 'S'}
)
delivery1, _ = User.objects.get_or_create(
    username='delivery1', defaults={'email': 'delivery1@gokulam.com', 'phone': '9876543230', 'role': 'delivery', 'first_name': 'Karthik', 'last_name': 'R'}
)
delivery2, _ = User.objects.get_or_create(
    username='delivery2', defaults={'email': 'delivery2@gokulam.com', 'phone': '9876543231', 'role': 'delivery', 'first_name': 'Vijay', 'last_name': 'M'}
)

# Set passwords
for user in [customer1, customer2, customer3, cashier, delivery1, delivery2]:
    user.set_password('test123')
    user.save()

print("Users created.")

# Create addresses
Address.objects.get_or_create(user=customer1, label='Home', defaults={'full_address': '123 Main Street, Koramangala', 'city': 'Bangalore', 'state': 'Karnataka', 'pincode': '560034', 'is_default': True})
Address.objects.get_or_create(user=customer1, label='Office', defaults={'full_address': '456 MG Road, Indiranagar', 'city': 'Bangalore', 'state': 'Karnataka', 'pincode': '560038', 'is_default': False})
Address.objects.get_or_create(user=customer2, label='Home', defaults={'full_address': '789HSR Layout, Sector 2', 'city': 'Bangalore', 'state': 'Karnataka', 'pincode': '560102', 'is_default': True})
Address.objects.get_or_create(user=customer3, label='Home', defaults={'full_address': '321 JP Nagar, 5th Phase', 'city': 'Bangalore', 'state': 'Karnataka', 'pincode': '560078', 'is_default': True})

print("Addresses created.")

# Create categories
categories_data = {
    'Hardware': 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=200',
    'Electrical': 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=200',
    'Plumbing': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=200',
    'Tools': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=200',
    'Paints': 'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=200',
    'Safety Equipment': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=200',
    'Fasteners': 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=200',
    'Pipes': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=200',
    'Lighting': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'Switches & Sockets': 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=200',
    'Chemicals': 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=200',
    'Bathroom Fittings': 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=200',
}
categories = {}
for name, image_url in categories_data.items():
    cat, created = Category.objects.get_or_create(name=name)
    if created or not cat.image:
        cat.image = image_url
        cat.save()
    categories[name] = cat

print("Categories created.")

# Create brands
brands_data = [
    'Anchor', 'Havells', 'Crompton', 'Polycab', 'Finolex',
    'Astral', 'Supreme', 'Cera', 'Jaquar', 'Hindware',
    'Asian Paints', 'Berger', 'Drillex', 'Bosch', 'Stanley',
    '3M', 'Honeywell', 'Legrand', 'Syska', 'Philips'
]
brands = {}
for name in brands_data:
    brand, _ = Brand.objects.get_or_create(name=name)
    brands[name] = brand

print("Brands created.")

# Create products
products_data = [
    # Hardware
    {'name': 'Steel Door Lock Set', 'category': 'Hardware', 'brand': 'Stanley', 'sku': 'HW-LOCK-001', 'mrp': 1200, 'selling_price': 999, 'discount_percent': 17, 'gst_percent': 18, 'stock': 50, 'description': 'Premium steel door lock set with 3 keys. Suitable for main doors and bedroom doors.', 'material': 'Stainless Steel', 'weight': '800g', 'is_featured': True},
    {'name': 'SS Door Handle - Modern', 'category': 'Hardware', 'brand': 'Stanley', 'sku': 'HW-HNDL-002', 'mrp': 850, 'selling_price': 720, 'discount_percent': 15, 'gst_percent': 18, 'stock': 35, 'description': 'Contemporary stainless steel door handle with satin finish.', 'material': 'SS 304', 'weight': '450g'},
    {'name': 'Heavy Duty Hinge 4 inch', 'category': 'Hardware', 'brand': 'Stanley', 'sku': 'HW-HNGE-003', 'mrp': 120, 'selling_price': 95, 'discount_percent': 21, 'gst_percent': 18, 'stock': 200, 'description': 'Heavy duty door hinge for wooden and metal doors.', 'material': 'Iron', 'weight': '150g'},
    {'name': 'Tower Bolt 8 inch', 'category': 'Hardware', 'brand': 'Stanley', 'sku': 'HW-BOLT-004', 'mrp': 80, 'selling_price': 65, 'discount_percent': 19, 'gst_percent': 18, 'stock': 150, 'description': 'Strong tower bolt for gate and door safety.', 'material': 'Brass', 'weight': '120g'},

    # Electrical
    {'name': 'Havells 1.5mm Wire Bundle (90m)', 'category': 'Electrical', 'brand': 'Havells', 'sku': 'EL-WIRE-001', 'mrp': 3200, 'selling_price': 2850, 'discount_percent': 11, 'gst_percent': 18, 'stock': 40, 'description': 'HRFR (Heat Resistant Flame Retardant) copper wire 1.5 sq mm, 90 meters.', 'material': 'Copper', 'weight': '4.5kg', 'is_featured': True},
    {'name': 'MCB 32A Double Pole', 'category': 'Electrical', 'brand': 'Anchor', 'sku': 'EL-MCB-002', 'mrp': 450, 'selling_price': 380, 'discount_percent': 16, 'gst_percent': 18, 'stock': 75, 'description': 'Miniature circuit breaker 32 Amp, double pole, C-curve.'},
    {'name': 'MCB Distribution Board 8-Way', 'category': 'Electrical', 'brand': 'Anchor', 'sku': 'EL-DB-003', 'mrp': 2800, 'selling_price': 2450, 'discount_percent': 13, 'gst_percent': 18, 'stock': 20, 'description': '8-way modular distribution board with metal door.'},
    {'name': 'Modular Switch 16A - White', 'category': 'Switches & Sockets', 'brand': 'Anchor', 'sku': 'SW-16A-001', 'mrp': 85, 'selling_price': 72, 'discount_percent': 15, 'gst_percent': 18, 'stock': 500, 'description': 'Anchor Roma 16 Amp one-way modular switch.'},
    {'name': '5 Pin Socket 6A', 'category': 'Switches & Sockets', 'brand': 'Anchor', 'sku': 'SW-5P-002', 'mrp': 95, 'selling_price': 82, 'discount_percent': 14, 'gst_percent': 18, 'stock': 400, 'description': 'Anchor Roma 5-pin 6A socket with shutter.'},
    {'name': 'LED Bulb 9W Cool Daylight', 'category': 'Lighting', 'brand': 'Syska', 'sku': 'LT-LED-001', 'mrp': 180, 'selling_price': 145, 'discount_percent': 19, 'gst_percent': 18, 'stock': 300, 'description': 'Syska 9W LED bulb, 6500K cool daylight, B22 base.', 'is_featured': True},
    {'name': 'Tube Light 20W LED Batten', 'category': 'Lighting', 'brand': 'Philips', 'sku': 'LT-BAT-002', 'mrp': 350, 'selling_price': 299, 'discount_percent': 15, 'gst_percent': 18, 'stock': 100, 'description': 'Philips 20W LED batten tube light, 4 feet, slim design.'},
    {'name': 'Panel Light 18W Round', 'category': 'Lighting', 'brand': 'Philips', 'sku': 'LT-PNL-003', 'mrp': 520, 'selling_price': 450, 'discount_percent': 13, 'gst_percent': 18, 'stock': 60, 'description': 'Philips 18W round LED panel light for false ceiling.'},

    # Plumbing
    {'name': 'CPVC Pipe 1/2 inch (3m)', 'category': 'Pipes', 'brand': 'Astral', 'sku': 'PL-CPVC-001', 'mrp': 180, 'selling_price': 155, 'discount_percent': 14, 'gst_percent': 18, 'stock': 200, 'description': 'Astral CPVC-Pro pipe for hot and cold water supply.', 'material': 'CPVC'},
    {'name': 'PVC Pipe 4 inch (3m)', 'category': 'Pipes', 'brand': 'Supreme', 'sku': 'PL-PVC-002', 'mrp': 350, 'selling_price': 310, 'discount_percent': 11, 'gst_percent': 18, 'stock': 100, 'description': 'Supreme SWR pipe for drainage and sewage.', 'material': 'PVC'},
    {'name': 'CPVC Elbow 1/2 inch (Pack of 10)', 'category': 'Plumbing', 'brand': 'Astral', 'sku': 'PL-ELB-003', 'mrp': 120, 'selling_price': 100, 'discount_percent': 17, 'gst_percent': 18, 'stock': 300, 'description': 'CPVC elbow fitting 1/2 inch for plumbing joints.'},
    {'name': 'PPR Pipe 3/4 inch (3m)', 'category': 'Pipes', 'brand': 'Astral', 'sku': 'PL-PPR-004', 'mrp': 220, 'selling_price': 195, 'discount_percent': 11, 'gst_percent': 18, 'stock': 120, 'description': 'Astral PPR pipe for hot water, high temperature resistant.'},

    # Bathroom
    {'name': 'Ceramic Wash Basin - Pedestal', 'category': 'Bathroom Fittings', 'brand': 'Cera', 'sku': 'BT-BAS-001', 'mrp': 5500, 'selling_price': 4800, 'discount_percent': 13, 'gst_percent': 18, 'stock': 10, 'description': 'Cera premium ceramic wash basin with pedestal, white finish.', 'weight': '18kg'},
    {'name': 'Western Commode - EWC', 'category': 'Bathroom Fittings', 'brand': 'Hindware', 'sku': 'BT-CMT-002', 'mrp': 8500, 'selling_price': 7200, 'discount_percent': 15, 'gst_percent': 18, 'stock': 5, 'description': 'Hindware western style EWC with dual flush system.', 'weight': '25kg', 'is_featured': True},
    {'name': 'Faucet Basin Mixer - Chrome', 'category': 'Bathroom Fittings', 'brand': 'Jaquar', 'sku': 'BT-FCT-003', 'mrp': 3200, 'selling_price': 2750, 'discount_percent': 14, 'gst_percent': 18, 'stock': 15, 'description': 'Jaquar single lever basin mixer with chrome finish.', 'material': 'Brass'},
    {'name': 'Shower Head 8 inch Round', 'category': 'Bathroom Fittings', 'brand': 'Jaquar', 'sku': 'BT-SHW-004', 'mrp': 1800, 'selling_price': 1550, 'discount_percent': 14, 'gst_percent': 18, 'stock': 25, 'description': 'Jaquar 8 inch round overhead shower, anti-limescale nozzles.'},

    # Tools
    {'name': 'Bosch Drill Machine 800W', 'category': 'Tools', 'brand': 'Bosch', 'sku': 'TL-DRM-001', 'mrp': 3800, 'selling_price': 3200, 'discount_percent': 16, 'gst_percent': 18, 'stock': 8, 'description': 'Bosch 800W impact drill machine with variable speed.', 'weight': '2.1kg', 'is_featured': True},
    {'name': 'Measuring Tape 5m', 'category': 'Tools', 'brand': 'Stanley', 'sku': 'TL-TPE-002', 'mrp': 250, 'selling_price': 210, 'discount_percent': 16, 'gst_percent': 18, 'stock': 60, 'description': 'Stanley 5 meter measuring tape, auto-lock, metric scale.', 'weight': '150g'},
    {'name': 'Pipe Wrench 14 inch', 'category': 'Tools', 'brand': 'Drillex', 'sku': 'TL-WRN-003', 'mrp': 650, 'selling_price': 550, 'discount_percent': 15, 'gst_percent': 18, 'stock': 20, 'description': 'Heavy duty pipe wrench for plumbing work.', 'weight': '1.2kg'},
    {'name': 'Spirit Level 24 inch', 'category': 'Tools', 'brand': 'Stanley', 'sku': 'TL-LVL-004', 'mrp': 750, 'selling_price': 640, 'discount_percent': 15, 'gst_percent': 18, 'stock': 15, 'description': 'Professional spirit level with 3 vials, aluminium body.', 'weight': '450g'},

    # Paints
    {'name': 'Asian Paints Apex Ultima 20L', 'category': 'Paints', 'brand': 'Asian Paints', 'sku': 'PT-APX-001', 'mrp': 7500, 'selling_price': 6800, 'discount_percent': 9, 'gst_percent': 18, 'stock': 12, 'description': 'Premium exterior emulsion paint, weatherproof, 20 litre.', 'weight': '22kg'},
    {'name': 'Asian Paints Apex 4L White', 'category': 'Paints', 'brand': 'Asian Paints', 'sku': 'PT-APEX-002', 'mrp': 2200, 'selling_price': 1950, 'discount_percent': 11, 'gst_percent': 18, 'stock': 25, 'description': 'Exterior emulsion for walls, 4 litre, white.', 'weight': '5kg'},
    {'name': 'Berger Weathercoat 10L', 'category': 'Paints', 'brand': 'Berger', 'sku': 'PT-WC-003', 'mrp': 4800, 'selling_price': 4200, 'discount_percent': 13, 'gst_percent': 18, 'stock': 15, 'description': 'Weatherproof exterior paint, 10 litre.', 'weight': '12kg'},

    # Safety
    {'name': 'Safety Helmet - Yellow', 'category': 'Safety Equipment', 'brand': '3M', 'sku': 'SF-HLM-001', 'mrp': 450, 'selling_price': 380, 'discount_percent': 16, 'gst_percent': 18, 'stock': 50, 'description': '3M industrial safety helmet, adjustable suspension.', 'weight': '320g'},
    {'name': 'Safety Shoes - Size 8-10', 'category': 'Safety Equipment', 'brand': '3M', 'sku': 'SF-SHO-002', 'mrp': 1800, 'selling_price': 1500, 'discount_percent': 17, 'gst_percent': 18, 'stock': 30, 'description': 'Steel toe cap safety shoes, ISI certified.', 'weight': '900g'},
    {'name': 'Work Gloves - Leather', 'category': 'Safety Equipment', 'brand': '3M', 'sku': 'SF-GLV-003', 'mrp': 350, 'selling_price': 290, 'discount_percent': 17, 'gst_percent': 18, 'stock': 80, 'description': 'Premium leather work gloves, abrasion resistant.'},
    {'name': 'Safety Goggles Clear', 'category': 'Safety Equipment', 'brand': '3M', 'sku': 'SF-GGL-004', 'mrp': 280, 'selling_price': 230, 'discount_percent': 18, 'gst_percent': 18, 'stock': 60, 'description': 'Anti-fog safety goggles for construction and lab use.'},

    # Fasteners
    {'name': 'MS Anchor Bolt 10x100mm (Pack 20)', 'category': 'Fasteners', 'sku': 'FN-ANC-001', 'mrp': 200, 'selling_price': 170, 'discount_percent': 15, 'gst_percent': 18, 'stock': 100, 'description': 'Mild steel anchor bolt for heavy mounting.', 'material': 'MS'},
    {'name': 'Self Drilling Screw 4x25 (Pack 100)', 'category': 'Fasteners', 'sku': 'FN-SCR-002', 'mrp': 180, 'selling_price': 150, 'discount_percent': 17, 'gst_percent': 18, 'stock': 200, 'description': 'Self drilling drywall screws, phosphate coated.'},
    {'name': 'Nut Bolt Set M8 (Pack 50)', 'category': 'Fasteners', 'sku': 'FN-NB-003', 'mrp': 150, 'selling_price': 125, 'discount_percent': 17, 'gst_percent': 18, 'stock': 150, 'description': 'Hex nut and bolt set M8, zinc plated.', 'material': 'MS'},

    # Chemicals
    {'name': 'PVC Solvent Cement 100ml', 'category': 'Chemicals', 'brand': 'Astral', 'sku': 'CH-PVC-001', 'mrp': 120, 'selling_price': 100, 'discount_percent': 17, 'gst_percent': 18, 'stock': 80, 'description': 'PVC solvent cement for pipe joining, quick set.'},
    {'name': 'Teflon Tape Roll (Pack 5)', 'category': 'Chemicals', 'sku': 'CH-TFL-002', 'mrp': 60, 'selling_price': 50, 'discount_percent': 17, 'gst_percent': 18, 'stock': 200, 'description': 'PTFE thread seal tape for plumbing, 5 rolls pack.'},
    {'name': 'Epoxy Adhesive 2 Part 50g', 'category': 'Chemicals', 'sku': 'CH-EPO-003', 'mrp': 180, 'selling_price': 155, 'discount_percent': 14, 'gst_percent': 18, 'stock': 40, 'description': 'Two-part epoxy adhesive for strong bonding.'},
]

for p_data in products_data:
    product, created = Product.objects.get_or_create(
        sku=p_data['sku'],
        defaults={
            'name': p_data['name'],
            'category': categories[p_data['category']],
            'brand': brands.get(p_data.get('brand'), None),
            'mrp': p_data['mrp'],
            'selling_price': p_data['selling_price'],
            'discount_percent': p_data['discount_percent'],
            'gst_percent': p_data['gst_percent'],
            'stock': p_data['stock'],
            'description': p_data.get('description', ''),
            'material': p_data.get('material', ''),
            'weight': p_data.get('weight', ''),
            'is_featured': p_data.get('is_featured', False),
            'images': ['https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=400'],
        }
    )

print(f"Products created: {Product.objects.count()}")

# Create banners
Banner.objects.get_or_create(title='Summer Sale - 20% Off Tools', defaults={'image': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=800', 'is_active': True, 'order': 1})
Banner.objects.get_or_create(title='Electrical Essentials', defaults={'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800', 'is_active': True, 'order': 2})
Banner.objects.get_or_create(title='Bathroom Renovation Deals', defaults={'image': 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800', 'is_active': True, 'order': 3})
Banner.objects.get_or_create(title='Plumbing Solutions - Top Brands', defaults={'image': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800', 'is_active': True, 'order': 4})

print("Banners created.")

# Create coupons
now = timezone.now()
Coupon.objects.get_or_create(code='WELCOME10', defaults={'description': '10% off on first order', 'discount_percent': 10, 'min_order_amount': 500, 'max_discount': 200, 'valid_from': now, 'valid_to': now + timedelta(days=90), 'usage_limit': 500, 'is_active': True})
Coupon.objects.get_or_create(code='SAVE50', defaults={'description': 'Flat Rs.50 off on orders above Rs.1000', 'discount_amount': 50, 'min_order_amount': 1000, 'valid_from': now, 'valid_to': now + timedelta(days=60), 'usage_limit': 200, 'is_active': True})
Coupon.objects.get_or_create(code='GOKULAM20', defaults={'description': '20% off on orders above Rs.2000', 'discount_percent': 20, 'min_order_amount': 2000, 'max_discount': 500, 'valid_from': now, 'valid_to': now + timedelta(days=30), 'usage_limit': 100, 'is_active': True})

print("Coupons created.")

# Create customer credits (Khata)
CustomerCredit.objects.get_or_create(customer=customer1, defaults={'credit_limit': 10000, 'outstanding': 2500, 'total_credit_given': 2500, 'total_repaid': 0})
CustomerCredit.objects.get_or_create(customer=customer2, defaults={'credit_limit': 5000, 'outstanding': 800, 'total_credit_given': 800, 'total_repaid': 0})

print("Customer credits created.")
print("\n=== SEED COMPLETE ===")
print(f"Total Users: {User.objects.count()}")
print(f"Total Categories: {Category.objects.count()}")
print(f"Total Brands: {Brand.objects.count()}")
print(f"Total Products: {Product.objects.count()}")
print(f"Total Banners: {Banner.objects.count()}")
print(f"Total Coupons: {Coupon.objects.count()}")
print(f"\nLogin credentials:")
print(f"  Admin:     admin / admin123")
print(f"  Cashier:   cashier1 / test123")
print(f"  Delivery1: delivery1 / test123")
print(f"  Delivery2: delivery2 / test123")
print(f"  Customer1: ravi_kumar / test123")
print(f"  Customer2: suresh_babu / test123")
print(f"  Customer3: priya_sharma / test123")
