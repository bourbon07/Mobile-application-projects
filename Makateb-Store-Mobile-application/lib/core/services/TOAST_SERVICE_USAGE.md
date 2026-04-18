# Toast Service Usage Guide

## Overview

The `ToastService` is a Flutter service/helper equivalent to Vue's `useToast` composable. It provides a simple API for showing toast notifications using the notification store.

## Usage

### In ConsumerWidget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/toast_service.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ToastService(ref);
    
    return ElevatedButton(
      onPressed: () {
        toast.toast.success('Operation completed!');
      },
      child: Text('Show Success'),
    );
  }
}
```

### In ConsumerStatefulWidget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/toast_service.dart';

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  late final ToastService _toast;
  
  @override
  void initState() {
    super.initState();
    _toast = ToastService(ref);
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _toast.toast.error('An error occurred');
      },
      child: Text('Show Error'),
    );
  }
}
```

### Using Static Helper

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/toast_service.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ToastServiceHelper.success(ref, 'Operation completed!');
      },
      child: Text('Show Success'),
    );
  }
}
```

## Methods

### Success Toast

```dart
final toast = ToastService(ref);
toast.toast.success('Operation completed successfully!');
// or
ToastServiceHelper.success(ref, 'Operation completed successfully!');
```

### Error Toast

```dart
final toast = ToastService(ref);
toast.toast.error('An error occurred');
// or
ToastServiceHelper.error(ref, 'An error occurred');
```

### Warning Toast

```dart
final toast = ToastService(ref);
toast.toast.warning('Please check your input');
// or
ToastServiceHelper.warning(ref, 'Please check your input');
```

### Info Toast

```dart
final toast = ToastService(ref);
toast.toast.info('New update available');
// or
ToastServiceHelper.info(ref, 'New update available');
```

## With Options (Future Enhancement)

The `ToastOptions` parameter is included to match Vue's API but is currently unused:

```dart
final toast = ToastService(ref);
toast.toast.success(
  'Operation completed!',
  ToastOptions(duration: 5000),
);
```

## Example: After Action

```dart
class AddToCartButton extends ConsumerWidget {
  final Product product;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ToastService(ref);
    
    return ElevatedButton(
      onPressed: () async {
        try {
          await addToCart(product);
          toast.toast.success('Product added to cart');
        } catch (e) {
          toast.toast.error('Failed to add product to cart');
        }
      },
      child: Text('Add to Cart'),
    );
  }
}
```

## Migration from Vue

| Vue | Flutter |
|-----|---------|
| `const { toast } = useToast()` | `final toast = ToastService(ref).toast` |
| `toast.success(message)` | `toast.success(message)` |
| `toast.error(message)` | `toast.error(message)` |
| `toast.warning(message)` | `toast.warning(message)` |
| `toast.info(message)` | `toast.info(message)` |

## Notes

- **Requires WidgetRef**: The service requires a `WidgetRef` from Riverpod to access the notification store
- **Auto-dismiss**: All toasts auto-dismiss after 6 seconds (configurable in notification store)
- **Returns ID**: Methods return notification ID for manual dismissal if needed
- **No UI**: This is a service only - the UI is handled by the `NotificationToast` widget

