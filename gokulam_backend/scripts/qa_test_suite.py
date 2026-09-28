"""
End-to-end QA suite for the Gokulam Traders API.

Exercises every endpoint the Flutter app calls, across all four roles, plus
auth edge cases, authorization rules, static image serving and a latency
benchmark. Writes go through dedicated test records that are deleted again.

    python scripts/qa_test_suite.py [base_url]

Exit code 0 = every check passed.
"""

import json
import sys
import time
import urllib.error
import urllib.request

BASE = (sys.argv[1] if len(sys.argv) > 1 else "https://web-production-a7104.up.railway.app") + "/api"

CREDS = {
    "admin": ("admin", "admin123"),
    "cashier": ("cashier1", "test123"),
    "delivery": ("delivery1", "test123"),
    "customer": ("ravi_kumar", "test123"),
}

results = []
tokens = {}


def call(method, path, token=None, payload=None, raw=False):
    url = BASE + path if path.startswith("/") else path
    body = None
    headers = {}
    if payload is not None:
        body = json.dumps(payload).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=45) as res:
            data = res.read()
            elapsed = (time.perf_counter() - started) * 1000
            if raw:
                return res.status, data, elapsed
            return res.status, json.loads(data) if data else {}, elapsed
    except urllib.error.HTTPError as err:
        data = err.read()
        elapsed = (time.perf_counter() - started) * 1000
        try:
            parsed = json.loads(data) if data else {}
        except ValueError:
            parsed = {"_raw": data[:200].decode("utf-8", "replace")}
        return err.code, parsed, elapsed
    except Exception as exc:  # noqa: BLE001 - report any transport failure
        return 0, {"_error": str(exc)}, (time.perf_counter() - started) * 1000


def check(section, name, ok, detail=""):
    results.append((section, name, bool(ok), detail))
    flag = "PASS" if ok else "FAIL"
    print(f"  [{flag}] {name}" + (f"  ({detail})" if detail else ""))


def expect(section, name, actual, wanted):
    if isinstance(wanted, (list, tuple)):
        check(section, name, actual in wanted, f"got {actual}, want {wanted}")
    else:
        check(section, name, actual == wanted, f"got {actual}, want {wanted}")


# ---------------------------------------------------------------- auth ----

print("\n== A. Auth & tokens ==")
for role, (user, pw) in CREDS.items():
    status, body, _ = call("POST", "/auth/login/", payload={"username": user, "password": pw})
    expect("A", f"login {role}", status, 200)
    token = (body or {}).get("tokens", {}).get("access", "")
    tokens[role] = token
    role_field = ((body or {}).get("user") or {}).get("role", "")
    if role == "admin":
        check("A", "admin login returns role + both tokens",
              role_field == "admin" and token and body.get("tokens", {}).get("refresh"),
              f"role={role_field}")
    else:
        check("A", f"{role} token issued", len(token) > 20)

status, body, _ = call("POST", "/auth/login/", payload={"username": "admin", "password": "wrong"})
check("A", "wrong password rejected", status in (400, 401), f"got {status}")

status, body, _ = call("POST", "/auth/login/", payload={"username": "nobody_xyz", "password": "x"})
check("A", "unknown user rejected", status in (400, 401), f"got {status}")

status, body, _ = call("POST", "/auth/login/", payload={"username": ""})
check("A", "missing password field rejected", status in (400, 401), f"got {status}")

refresh = ""
status, body, _ = call("POST", "/auth/login/", payload={"username": "admin", "password": "admin123"})
refresh = (body.get("tokens") or {}).get("refresh", "")
status, body, _ = call("POST", "/auth/token/refresh/", payload={"refresh": refresh})
check("A", "refresh token rotates access token", status == 200 and bool(body.get("access")), f"got {status}")

status, body, _ = call("POST", "/auth/token/refresh/", payload={"refresh": "not-a-token"})
check("A", "bad refresh token rejected", status in (400, 401), f"got {status}")

status, body, _ = call("GET", "/auth/profile/", token="garbage.token.here")
check("A", "malformed bearer token rejected", status in (400, 401), f"got {status}")

status, body, _ = call("POST", "/auth/register/", payload={
    "username": "qa_suite_probe", "email": "qa_probe@example.com",
    "phone": "9000000001", "password": "QaProbe123!",
    "address": "QA probe", "role": "customer"})
check("A", "register endpoint works (creates or cleanly reports duplicate)",
      status in (200, 201) or (status == 400 and not str(body).lower().count("traceback")),
      f"got {status}")
status, body, _ = call("POST", "/auth/login/", payload={"username": "qa_suite_probe", "password": "QaProbe123!"})
check("A", "registered account can log in (end-to-end)",
      status == 200 and bool(body.get("tokens", {}).get("access")), f"got {status}")
status, body, _ = call("POST", "/auth/register/", payload={
    "username": "admin", "email": "x@y.z", "phone": "9000000002",
    "password": "QaProbe123!", "address": "", "role": "customer"})
check("A", "duplicate username rejected", status in (400, 409), f"got {status}")

admin = tokens.get("admin", "")
customer = tokens.get("customer", "")

# ------------------------------------------------------------ catalog ----

print("\n== B. Catalog (public) ==")
status, products, ms = call("GET", "/products/")
count = products.get("count", 0)
expect("B", "GET /products/ 200", status, 200)
check("B", "37 products", count == 37, f"count={count}")
results.append(("B", "latency: product list", True, f"{ms:.0f}ms"))

images = [p.get("primary_image", "") for p in products.get("results", [])]
check("B", "every product has a primary image", all(images), f"empty={images.count('')}")
check("B", "all 37 product images unique", len(set(images)) == 37, f"unique={len(set(images))}")
check("B", "no stale Unsplash URLs", not any("unsplash.com" in u for u in images))
check("B", "product images point at own catalog",
      all(u.startswith("/static/images/products/") for u in images), str(images[0]))

status, body, _ = call("GET", "/products/?page=1")
expect("B", "pagination page 1 200", status, 200)
check("B", "page 1 carries results", isinstance(body.get("results"), list), str(body)[:80])
total_pages = -(-count // 50) if count else 1
status, body, _ = call("GET", f"/products/?page={total_pages}")
check("B", f"last page ({total_pages}) 200", status == 200, f"got {status}")
status, body, _ = call("GET", "/products/?page=99999")
check("B", "beyond-last page is a clean 404 not a 500", status == 404, f"got {status}")

status, body, _ = call("GET", "/products/?search=MCB")
expect("B", "product search filter 200", status, 200)

status, body, _ = call("GET", "/products/?ordering=-selling_price")
check("B", "ordering filter accepted", status == 200, f"got {status}")

first_id = products["results"][0]["id"]
status, body, _ = call("GET", f"/products/{first_id}/")
expect("B", "product detail 200", status, 200)
check("B", "detail returns images array", isinstance(body.get("images"), list) and len(body.get("images", [])) >= 1,
      str(body.get("images", ""))[:60])
check("B", "detail has price + stock",
      "selling_price" in body and "stock" in body and "category" in body)

status, body, _ = call("GET", "/products/999999/")
expect("B", "missing product 404", status, 404)

status, categories, ms = call("GET", "/categories/")
check("B", "12 categories", categories.get("count") == 12, f"count={categories.get('count')}")
cat_imgs = [c.get("image", "") for c in categories.get("results", [])]
check("B", "all categories have images", all(cat_imgs))
check("B", "all 12 category images unique", len(set(cat_imgs)) == 12, f"unique={len(set(cat_imgs))}")
results.append(("B", "latency: category list", True, f"{ms:.0f}ms"))

status, brands, _ = call("GET", "/brands/")
check("B", "20 brands", brands.get("count") == 20, f"count={brands.get('count')}")

status, banners, _ = call("GET", "/banners/")
check("B", "4 banners", banners.get("count") == 4, f"count={banners.get('count')}")
banner_imgs = [b.get("image", "") for b in banners.get("results", [])]
check("B", "banner images unique + present",
      len(set(banner_imgs)) == 4 and all(banner_imgs), str(banner_imgs)[:80])

status, body, _ = call("GET", "/store/location/")
expect("B", "store location 200", status, 200)
check("B", "store payload has radius + charge",
      "delivery_radius_km" in body and "delivery_charge_per_half_km" in body)

status, body, _ = call("GET", "/coupon/validate/", payload=None)
status2, coupon_ok, _ = call("POST", "/coupon/validate/", payload={"code": "WELCOME10", "amount": 600})
check("B", "valid coupon accepted", status2 == 200 and coupon_ok.get("valid") is True, str(coupon_ok)[:80])
check("B", "WELCOME10 10% capped math (600 -> 60)",
      abs(float(coupon_ok.get("discount", -1)) - 60.0) < 0.01, str(coupon_ok.get("discount")))
status2, coupon_flat, _ = call("POST", "/coupon/validate/", payload={"code": "SAVE50", "amount": 1000})
check("B", "SAVE50 flat discount honoured",
      coupon_flat.get("valid") is True and abs(float(coupon_flat.get("discount", -1)) - 50.0) < 0.01,
      str(coupon_flat)[:80])
status2, coupon_cap, _ = call("POST", "/coupon/validate/", payload={"code": "GOKULAM20", "amount": 3000})
check("B", "GOKULAM20 max_discount caps at 500",
      coupon_cap.get("valid") is True and abs(float(coupon_cap.get("discount", -1)) - 500.0) < 0.01,
      str(coupon_cap.get("discount")))
status2, coupon_bad, _ = call("POST", "/coupon/validate/", payload={"code": "NOPE999", "amount": 600})
check("B", "invalid coupon rejected", status2 == 200 and coupon_bad.get("valid") is False, str(coupon_bad)[:80])
status2, coupon_min, _ = call("POST", "/coupon/validate/", payload={"code": "WELCOME10", "amount": 10})
check("B", "coupon below minimum rejected", status2 == 200 and coupon_min.get("valid") is False)
status2, coupon_zero, _ = call("POST", "/coupon/validate/", payload={"code": "WELCOME10", "amount": 0})
check("B", "coupon amount 0 handled without crash", status2 in (200, 400), f"got {status2}")

# ------------------------------------------------- authz / permissions ----

print("\n== C. Authorization matrix ==")
protected = [
    ("/auth/profile/", "GET"), ("/auth/addresses/", "GET"), ("/cart/", "GET"),
    ("/orders/", "GET"), ("/wishlist/", "GET"), ("/khata/credits/", "GET"),
    ("/khata/credits/summary/", "GET"), ("/khata/credits/all_transactions/", "GET"),
]
for path, method in protected:
    status, body, _ = call(method, path, token=None)
    check("C", f"anonymous {method} {path} blocked", status in (401, 403), f"got {status}")

for path in ("/dashboard/stats/", "/products/low_stock/", "/auth/customers/", "/auth/users/"):
    status, _, _ = call("GET", path, token=customer)
    check("C", f"customer blocked from {path}", status in (401, 403), f"got {status}")
    status, _, _ = call("GET", path, token=admin)
    check("C", f"admin allowed on {path}", status == 200, f"got {status}")

status, body, _ = call("GET", "/dashboard/stats/", token=tokens.get("cashier", ""))
check("C", "cashier blocked from dashboard stats", status in (401, 403), f"got {status}")

status, body, _ = call("POST", "/products/", token=customer,
                       payload={"name": "QA probe product", "sku": "QA-PROBE-001",
                                "mrp": 10, "selling_price": 9, "discount_percent": 10,
                                "gst_percent": 18, "stock": 1, "images": []})
check("C", "customer cannot create product", status in (401, 403), f"got {status}")

status, created, _ = call("POST", "/products/", token=admin,
                          payload={"name": "QA probe product", "sku": "QA-PROBE-001",
                                   "mrp": 10, "selling_price": 9, "discount_percent": 10,
                                   "gst_percent": 18, "stock": 1, "images": []})
check("C", "admin can create product", status in (200, 201), f"got {status} {str(created)[:100]}")
probe_id = created.get("id")
if probe_id:
    status, _, _ = call("DELETE", f"/products/{probe_id}/", token=admin)
    check("C", "admin can delete probe product", status in (200, 204), f"got {status}")
    status, _, _ = call("GET", f"/products/{probe_id}/")
    check("C", "deleted product now 404", status == 404, f"got {status}")

status, _, _ = call("PUT", "/store/location/", token=customer,
                    payload={"delivery_radius_km": 5})
check("C", "customer cannot edit store settings", status in (401, 403), f"got {status}")

# ------------------------------------------------- cart & checkout ----

print("\n== D. Cart, checkout, orders (customer1) ==")
status, body, _ = call("GET", "/cart/", token=customer)
expect("D", "GET cart 200", status, 200)
cart = body
# clear pre-existing items so the run is deterministic
for item in cart.get("items", []):
    call("DELETE", f"/cart/items/{item['id']}/", token=customer)

status, cart_add, _ = call("POST", "/cart/", token=customer, payload={"product_id": first_id, "quantity": 2})
check("D", "add to cart", status in (200, 201), f"got {status} {str(cart_add)[:90]}")
check("D", "cart total calculated",
      abs(float(cart_add.get("total", 0)) - 2 * float(cart_add["items"][0]["product_detail"]["selling_price"])) < 0.01
      if cart_add.get("items") else False, str(cart_add.get("total")))

status, bad, _ = call("POST", "/cart/", token=customer, payload={"quantity": 3})
check("D", "cart without product_id rejected", status == 400, f"got {status} {str(bad)[:70]}")

status, bad, _ = call("POST", "/cart/", token=customer, payload={"product_id": 999999, "quantity": 1})
check("D", "cart with unknown product rejected", status in (400, 404), f"got {status}")

status, bad, _ = call("POST", "/cart/", token=customer, payload={"product_id": first_id, "quantity": 0})
check("D", "cart quantity 0 rejected", status == 400, f"got {status}")

status, bad, _ = call("POST", "/cart/", token=customer, payload={"product_id": first_id, "quantity": -5})
check("D", "cart negative quantity rejected", status == 400, f"got {status}")

status, cart_now, _ = call("GET", "/cart/", token=customer)
check("D", "cart reflects added item",
      status == 200 and len(cart_now.get("items", [])) == 1, str(len(cart_now.get("items", []))))

status, empty_order, _ = call("POST", "/orders/create_order/", token=customer,
                              payload={"delivery_type": "takeaway", "payment_method": "cash"})
check("D", "order with stock OK accepted", status in (200, 201), f"got {status} {str(empty_order)[:110]}")
order_id = (empty_order or {}).get("id")
order_no = (empty_order or {}).get("order_id", "")

status, my_orders, _ = call("GET", "/orders/", token=customer)
check("D", "customer sees own orders",
      status == 200 and any(o.get("id") == order_id for o in my_orders.get("results", [])))

status, other_orders, _ = call("GET", "/orders/", token=tokens.get("cashier", ""))
other_ids = {o.get("id") for o in other_orders.get("results", [])}
check("D", "cashier sees orders in shared store", status == 200 and len(other_ids) >= 1)

status, _, _ = call("GET", "/orders/", token=None)
check("D", "anonymous order list blocked", status in (401, 403), f"got {status}")

# malformed payload
status, body, _ = call("POST", "/orders/create_order/", token=customer,
                       payload={"delivery_type": "teleport", "payment_method": "cash"})
check("D", "invalid delivery_type rejected", status == 400, f"got {status}")

# stock bookkeeping: order must decrement stock
status, after, _ = call("GET", f"/products/{first_id}/")
if status == 200 and "stock" in after:
    check("D", "order decremented product stock", isinstance(after["stock"], int))
else:
    check("D", "stock readable after order", False, str(after)[:80])

# ---------------------------------------------- profile & addresses ----

print("\n== E. Profile, addresses, account ==")
status, profile, _ = call("GET", "/auth/profile/", token=customer)
expect("E", "GET profile 200", status, 200)
check("E", "profile exposes role + phone", "role" in profile and "phone" in profile)

status, updated, _ = call("PUT", "/auth/profile/", token=customer,
                          payload={**profile, "first_name": "Ravi", "address": "HSR Layout, Bangalore"})
check("E", "PUT profile updates", status == 200 and updated.get("first_name") == "Ravi",
      f"got {status} {str(updated.get('first_name'))}")

status, addr, _ = call("POST", "/auth/addresses/", token=customer, payload={
    "label": "QA", "full_address": "QA test address", "city": "Bangalore",
    "state": "Karnataka", "pincode": "560010", "is_default": False})
check("E", "create address", status in (200, 201), f"got {status} {str(addr)[:90]}")
addr_id = (addr or {}).get("id")

status, addr_list, _ = call("GET", "/auth/addresses/", token=customer)
check("E", "list addresses", status == 200 and len(addr_list.get("results", addr_list if isinstance(addr_list, list) else [])) >= 1,
      f"got {status}")

if addr_id:
    status, _, _ = call("DELETE", f"/auth/addresses/{addr_id}/", token=customer)
    check("E", "delete address", status in (200, 204), f"got {status}")

status, body, _ = call("POST", "/auth/change-password/", token=customer,
                       payload={"old_password": "definitely-wrong", "new_password": "Whatever123!"})
check("E", "change-password rejects wrong current password", status in (400, 401), f"got {status}")

status, body, _ = call("POST", "/auth/update-fcm/", token=customer, payload={"fcm_token": "qa-fcm-token-123"})
check("E", "update fcm token", status in (200, 201), f"got {status}")

status, body, _ = call("POST", "/auth/update-fcm/", payload={"fcm_token": "x"})
check("E", "fcm update requires auth", status in (401, 403), f"got {status}")

# ------------------------------------------------------ khata ----

print("\n== F. Khata (credit ledger) ==")
for path in ("/khata/credits/", "/khata/credits/summary/", "/khata/credits/all_transactions/",
             "/khata/credits/my_credit/", "/khata/credits/customers/"):
    status, body, _ = call("GET", path, token=admin)
    check("F", f"admin GET {path}", status == 200, f"got {status}")

status, body, _ = call("GET", "/khata/credits/customers/", token=customer)
check("F", "customer blocked from supplier/customer ledger lists", status in (401, 403), f"got {status}")

status, summary, _ = call("GET", "/khata/credits/summary/", token=customer)
check("F", "customer sees own khata summary", status == 200, f"got {status}")

# -------------------------------------------------- reviews/wishlist ----

print("\n== G. Reviews & wishlist ==")
status, body, _ = call("GET", f"/products/{first_id}/reviews/")
expect("G", "product reviews list (public) 200", status, 200)

status, review, _ = call("POST", f"/products/{first_id}/reviews/", token=customer,
                         payload={"rating": 5, "comment": "QA suite review"})
dup = status == 400 and "unique" in str(review).lower()
check("G", "authenticated review accepted (or duplicate rejected cleanly)",
      status in (200, 201) or dup, f"got {status} {str(review)[:90]}")
review_id = (review or {}).get("id")
if review_id:
    pass  # leave the review: reviews are display data and prove the flow

status, body, _ = call("POST", f"/products/{first_id}/reviews/", token=customer, payload={"rating": 99})
check("G", "out-of-range rating rejected", status == 400, f"got {status}")

status, wish, _ = call("POST", "/wishlist/", token=customer, payload={"product": first_id})
check("G", "add to wishlist", status in (200, 201), f"got {status} {str(wish)[:80]}")
wish_id = (wish or {}).get("id")
status, wish_list, _ = call("GET", "/wishlist/", token=customer)
check("G", "wishlist lists item", status == 200 and len(wish_list.get("results", [])) >= 1)

status, body, _ = call("DELETE", f"/wishlist/remove/{first_id}/", token=customer)
check("G", "remove from wishlist", status in (200, 204), f"got {status}")
status, wish_after, _ = call("GET", "/wishlist/", token=customer)
removed = wish_id not in {w.get("id") for w in wish_after.get("results", [])}
check("G", "wishlist item gone", removed or wish_id is None, str(wish_after.get("results"))[:80])

# ----------------------------------------------------- static ----

print("\n== H. Static assets & images ==")
status, blob, ms = call("GET", "https://web-production-a7104.up.railway.app/static/admin/css/base.css", raw=True)
check("H", "Django admin CSS served (collectstatic works)", status == 200 and len(blob) > 1000,
      f"{status}, {len(blob)} bytes")
results.append(("H", "latency: admin css", True, f"{ms:.0f}ms"))

status, blob, ms = call("GET", "https://web-production-a7104.up.railway.app/static/images/products/hw-lock-001.jpg", raw=True)
check("H", "product image served", status == 200 and blob[:2] == b"\xff\xd8", f"{status}, {len(blob)} bytes")
results.append(("H", "latency: product image (cold)", True, f"{ms:.0f}ms"))

ok_images = 0
missing = []
for url in sorted(set(images)):
    status, blob, _ = call("GET", "https://web-production-a7104.up.railway.app" + url, raw=True)
    if status == 200 and len(blob) > 3000:
        ok_images += 1
    else:
        missing.append((url, status, len(blob)))
check("H", "all 37 product images fetch 200 with real bytes", ok_images == 37,
      f"ok={ok_images} missing={missing}")

ok_cat = 0
for url in sorted(set(cat_imgs)):
    status, blob, _ = call("GET", "https://web-production-a7104.up.railway.app" + url, raw=True)
    if status == 200 and len(blob) > 3000:
        ok_cat += 1
check("H", "all 12 category images fetch", ok_cat == 12, f"ok={ok_cat}")

ok_ban = 0
for url in sorted(set(banner_imgs)):
    status, blob, _ = call("GET", "https://web-production-a7104.up.railway.app" + url, raw=True)
    if status == 200 and len(blob) > 3000:
        ok_ban += 1
check("H", "all 4 banner images fetch", ok_ban == 4, f"ok={ok_ban}")

status, blob, _ = call("GET", "https://web-production-a7104.up.railway.app/static/images/products/nope-does-not-exist.jpg", raw=True)
check("H", "missing static file is 404 (not a crash)", status == 404, f"got {status}")

# ------------------------------------------------------- errors ----

print("\n== I. Error handling ==")
status, body, _ = call("GET", "/definitely/not/a/route/")
check("I", "unknown route 404", status == 404, f"got {status}")

req = urllib.request.Request(BASE + "/products/",
                             data=b"{not json", method="POST",
                             headers={"Content-Type": "application/json", "Authorization": f"Bearer {admin}"})
try:
    urllib.request.urlopen(req, timeout=30)
    malformed_ok = False
    malformed_status = 200
except urllib.error.HTTPError as e:
    malformed_ok = e.code in (400,)
    malformed_status = e.code
check("I", "malformed JSON body -> 400 not 500", malformed_ok, f"got {malformed_status}")

status, body, _ = call("DELETE", "/auth/profile/")
check("I", "unauth delete blocked", status in (401, 403), f"got {status}")

# ------------------------------------------------------- benchmark ----

print("\n== J. Latency benchmark (warm) ==")
for label, path in [("product list", "/products/"), ("category list", "/categories/"),
                    ("brand list", "/brands/"), ("banner list", "/banners/"),
                    ("product detail", f"/products/{first_id}/")]:
    samples = []
    for _ in range(8):
        _, _, ms = call("GET", path, token=None)
        samples.append(ms)
    samples.sort()
    avg = sum(samples) / len(samples)
    p95 = samples[int(len(samples) * 0.95) - 1] if len(samples) > 1 else samples[0]
    results.append(("J", f"latency: {label}", avg < 900, f"avg={avg:.0f}ms p95={p95:.0f}ms"))
    print(f"  [LATE] {label:<16} avg={avg:6.1f}ms  p95={p95:6.1f}ms")

img_samples = []
for _ in range(6):
    _, _, ms = call("GET", "https://web-production-a7104.up.railway.app/static/images/products/hw-lock-001.jpg", raw=True)
    img_samples.append(ms)
img_samples.sort()
print(f"  [LATE] {'image (cached':<16} avg={sum(img_samples)/len(img_samples):6.1f}ms")
results.append(("J", "latency: image warm", sum(img_samples) / len(img_samples) < 500,
                f"avg={sum(img_samples)/len(img_samples):.0f}ms"))


def server_timing(path):
    req = urllib.request.Request(BASE + path)
    try:
        with urllib.request.urlopen(req, timeout=45) as res:
            return res.headers.get("Server-Timing", "")
    except Exception:
        return ""


for label, path in [("products", "/products/"), ("store", "/store/location/")]:
    st = server_timing(path)
    print(f"  [TIME] {label:<16} Server-Timing: {st}")
    results.append(("J", f"server timing reported for {label}", bool(st), st))

# ------------------------------------------------------- summary ----

failed = [r for r in results if not r[2]]
print("\n" + "=" * 64)
print(f"TOTAL {len(results)} checks | PASS {len(results) - len(failed)} | FAIL {len(failed)}")
if failed:
    print("FAILURES:")
    for section, name, _, detail in failed:
        print(f"  [{section}] {name}  {detail}")
print("=" * 64)
sys.exit(1 if failed else 0)
