library;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_post.dart';

T nativeFromJson<T>(dynamic json) => json as T;
dynamic nativeToJson<T>(T value) => value;

enum OptionalState { set, unset }

class Optional<T> {
  final T Function(dynamic json) deserializer;
  final dynamic Function(T value) serializer;
  OptionalState state = OptionalState.unset;
  T? _value;

  Optional.optional(this.deserializer, this.serializer);

  T? get value => _value;
  set value(T? v) {
    _value = v;
    state = OptionalState.set;
  }

  dynamic toJson() => serializer(_value as T);

  static Optional<T> fromJson<T>(
    dynamic json,
    T Function(dynamic json) deserializer,
    dynamic Function(T value) serializer,
  ) {
    final opt = Optional.optional(deserializer, serializer);
    if (json != null) {
      opt.value = deserializer(json);
    }
    return opt;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Optional<T>) return false;
    return state == other.state && _value == other._value;
  }

  @override
  int get hashCode => Object.hash(state, _value);
}

class ExampleConnector {
  CreatePostVariablesBuilder createPost({
    required String imageUrl,
    required String caption,
  }) {
    return CreatePostVariablesBuilder(
      dataConnect,
      imageUrl: imageUrl,
      caption: caption,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'example',
    'instagramclone',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,
        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
