# Cart & Wishlist Debug Guide

## Current Status

The application is running with enhanced debug logging. Based on the console output:
- **Cart API is being called** but returning **0 items**
- This could mean:
  1. User is not logged in (guest cart not implemented)
  2. Cart is actually empty on the backend
  3. API response format is different than expected

## Debug Steps to Follow

### Step 1: Check Browser Console
1. Open the app in Chrome: `http://localhost:XXXX` (check the Flutter output for the port)
2. Open Chrome DevTools (F12)
3. Go to the **Console** tab
4. Look for debug messages starting with:
   - `[CartAPI]` - Shows cart API responses
   - `[CartStore]` - Shows cart parsing
   - `[WishlistAPI]` - Shows wishlist API responses
   - `[WishlistStore]` - Shows wishlist parsing

### Step 2: Check Network Tab
1. In Chrome DevTools, go to the **Network** tab
2. Filter by "Fetch/XHR"
3. Look for these API calls:
   - `GET /api/cart`
   - `POST /api/cart/add-product`
   - `POST /api/cart/add-package`
   - `GET /api/wishlist`
   - `POST /api/wishlist/add-product`
   - `POST /api/wishlist/add-package`

### Step 3: Test Adding to Cart
1. Navigate to a product page
2. Click "Add to Cart"
3. **Watch the Console** for these messages:
   ```
   [CartAPI] 🔍 FETCH CART - Response type: ...
   [CartAPI] 📦 Full response: ...
   [CartStore] 🛒 Loading cart from API...
   [CartStore] 📦 Raw cart data length: ...
   ```
4. **Watch the Network tab** for:
   - `POST /api/cart/add-product` - Should return 200 OK
   - `GET /api/cart` - Should be called after adding
5. Navigate to `/cart` page
6. Check if items appear

### Step 4: Check API Response Format

In the Network tab, click on the `GET /api/cart` request and check the **Response** tab.

#### Expected Format Option 1 (Direct List):
```json
[
  {
    "id": "1",
    "product_id": "123",
    "quantity": 2,
    "product": {
      "id": "123",
      "name": "Product Name",
      "price": 10.50,
      "image_url": "..."
    }
  }
]
```

#### Expected Format Option 2 (Wrapped in data):
```json
{
  "data": [
    {
      "id": "1",
      "product_id": "123",
      ...
    }
  ]
}
```

#### Expected Format Option 3 (Separate products/packages):
```json
{
  "products": [
    {
      "id": "1",
      "product_id": "123",
      ...
    }
  ],
  "packages": [
    {
      "id": "2",
      "package_id": "456",
      ...
    }
  ]
}
```

### Step 5: Common Issues & Solutions

#### Issue 1: "Received 0 raw items from API"
**Cause**: API returning empty array or unexpected format
**Solution**: 
1. Check if user is logged in
2. Add items via backend/database directly to test
3. Check API response in Network tab

#### Issue 2: "Product data missing for product_id: XXX"
**Cause**: API returning IDs but not nested product/package objects
**Solution**: Backend needs to include product/package data in response

#### Issue 3: Items added but not showing
**Cause**: State not updating or UI not rebuilding
**Solution**: Check console for parsing errors

## What to Report Back

Please provide:

1. **Console Output**: Copy all `[CartAPI]` and `[CartStore]` messages
2. **Network Response**: Copy the JSON response from `GET /api/cart`
3. **What you see**: Screenshot of cart page after adding items
4. **Any errors**: Red error messages in console

## Quick Test Commands

### Test 1: Add Product to Cart
```
1. Go to any product page
2. Click "Add to Cart"
3. Check console for: "[CartAPI] 🔍 FETCH CART"
4. Go to /cart page
5. Report what you see
```

### Test 2: Add to Wishlist
```
1. Click heart icon on any product
2. Check console for: "[WishlistAPI] 🔍 FETCH WISHLIST"
3. Go to /wishlist page
4. Report what you see
```

### Test 3: Check if User is Logged In
```
1. Open console
2. Type: localStorage.getItem('auth_token')
3. If null, you need to log in first
```

## Expected Debug Output (When Working)

When you add a product to cart, you should see:
```
═══════════════════════════════════════════
[CartAPI] 🔍 FETCH CART - Response type: List<dynamic>
[CartAPI] 📦 Full response: [{id: 1, product_id: 123, ...}]
[CartAPI] ✅ Response is List with 1 items
[CartAPI] 📋 First item: {id: 1, product_id: 123, ...}
═══════════════════════════════════════════
[CartStore] 🛒 Loading cart from API...
[CartStore] 📦 Raw cart data length: 1
[CartStore] 📋 First raw item: {id: 1, product_id: 123, ...}
[CartStore] 🔍 Processing item with keys: [id, product_id, quantity, product]
[CartStore] 🆔 Item ID: 1
[CartStore] 📦 Direct productId: 123, packageId: null
[CartStore] 🔢 Quantity: 1
[CartStore] 🏷️ Parsing product data...
[CartStore] ✅ Added cart item: 1 (product: Product Name, package: null)
[CartStore] ✅ Successfully parsed 1 cart items
[CartStore] 🛒 Cart state: 1 items, loading: false
═══════════════════════════════════════════
```

## Next Steps

After you complete the tests above and report back the results, I can:
1. Fix any API parsing issues
2. Adjust the state management
3. Fix UI refresh problems
4. Handle authentication issues

