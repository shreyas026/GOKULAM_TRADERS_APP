from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from .models import StoreConfig

User = get_user_model()
URL = '/api/store/location/'


class StoreLocationViewTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='loc_admin', password='pw', role='admin', is_staff=True, is_superuser=True)
        self.customer = User.objects.create_user(
            username='loc_customer', password='pw', role='customer')

    def login(self, user):
        self.client.force_authenticate(user=user)

    def test_anonymous_can_read_location(self):
        res = self.client.get(URL)
        self.assertEqual(res.status_code, 200)
        body = res.json()
        for key in ('name', 'address', 'latitude', 'longitude',
                    'delivery_radius_km', 'delivery_charge_per_half_km'):
            self.assertIn(key, body)
        self.assertIsInstance(body['latitude'], (int, float))
        self.assertIsInstance(body['delivery_charge_per_half_km'], (int, float))

    def test_anonymous_cannot_write(self):
        res = self.client.put(URL, {'latitude': 1.0}, format='json')
        self.assertIn(res.status_code, (401, 403))

    def test_customer_cannot_write(self):
        self.login(self.customer)
        res = self.client.put(URL, {'delivery_radius_km': 9}, format='json')
        self.assertEqual(res.status_code, 403)

    def test_admin_can_change_location(self):
        self.login(self.admin)
        res = self.client.put(URL, {
            'name': 'Gokulam Traders',
            'address': '42 Market Road, Bangalore',
            'latitude': 13.0827,
            'longitude': 80.2707,
            'delivery_radius_km': 7.5,
            'delivery_charge_per_half_km': 4,
        }, format='json')
        self.assertEqual(res.status_code, 200)
        body = res.json()
        self.assertEqual(body['latitude'], 13.0827)
        self.assertEqual(body['longitude'], 80.2707)
        self.assertEqual(body['delivery_radius_km'], 7.5)
        self.assertEqual(body['delivery_charge_per_half_km'], 4)

        saved = StoreConfig.get()
        self.assertEqual(saved.latitude, 13.0827)
        self.assertEqual(saved.address, '42 Market Road, Bangalore')

    def test_partial_update_keeps_other_fields(self):
        StoreConfig.get()
        self.login(self.admin)
        res = self.client.patch(URL, {'latitude': 12.3456}, format='json')
        self.assertEqual(res.status_code, 200)
        saved = StoreConfig.get()
        self.assertEqual(saved.latitude, 12.3456)
        self.assertEqual(saved.name, 'Gokulam Traders')

    def test_latitude_out_of_range_is_rejected(self):
        before = StoreConfig.get().latitude
        self.login(self.admin)
        res = self.client.put(URL, {'latitude': 999}, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertIn('latitude', res.json())
        self.assertEqual(StoreConfig.get().latitude, before)

    def test_latitude_not_a_number_is_rejected_not_500(self):
        self.login(self.admin)
        res = self.client.put(URL, {'latitude': 'not-a-number'}, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertIn('latitude', res.json())

    def test_longitude_out_of_range_is_rejected(self):
        self.login(self.admin)
        res = self.client.put(URL, {'longitude': 200}, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertIn('longitude', res.json())

    def test_non_positive_radius_is_rejected(self):
        self.login(self.admin)
        for bad in (0, -1):
            res = self.client.put(URL, {'delivery_radius_km': bad}, format='json')
            self.assertEqual(res.status_code, 400)
            self.assertIn('delivery_radius_km', res.json())

    def test_negative_charge_is_rejected(self):
        self.login(self.admin)
        res = self.client.put(URL, {'delivery_charge_per_half_km': -2}, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertIn('delivery_charge_per_half_km', res.json())
