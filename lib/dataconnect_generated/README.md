# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries
This connector does not contain any queries.
## Mutations

### CreatePost
#### Required Arguments
```dart
String imageUrl = ...;
String caption = ...;
ExampleConnector.instance.createPost(
  imageUrl: imageUrl,
  caption: caption,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreatePost, we created `CreatePostBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreatePostVariablesBuilder {
  ...
   CreatePostVariablesBuilder location(String? t) {
   _location.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createPost(
  imageUrl: imageUrl,
  caption: caption,
)
.location(location)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreatePostData, CreatePostVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createPost(
  imageUrl: imageUrl,
  caption: caption,
);
CreatePostData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String imageUrl = ...;
String caption = ...;

final ref = ExampleConnector.instance.createPost(
  imageUrl: imageUrl,
  caption: caption,
).ref();
ref.execute();
```

