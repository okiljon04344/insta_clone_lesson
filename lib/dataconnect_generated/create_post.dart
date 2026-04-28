part of 'generated.dart';

class CreatePostVariablesBuilder {
  String imageUrl;
  String caption;
  final Optional<String> _location = Optional.optional(
    (dynamic json) => nativeFromJson<String>(json),
    (String value) => nativeToJson<String>(value),
  );

  final FirebaseDataConnect _dataConnect;
  CreatePostVariablesBuilder location(String? t) {
    _location.value = t;
    return this;
  }

  CreatePostVariablesBuilder(
    this._dataConnect, {
    required this.imageUrl,
    required this.caption,
  });
  Deserializer<CreatePostData> dataDeserializer =
      (dynamic json) => CreatePostData.fromJson(jsonDecode(json));
  Serializer<CreatePostVariables> varsSerializer =
      (CreatePostVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreatePostData, CreatePostVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreatePostData, CreatePostVariables> ref() {
    CreatePostVariables vars = CreatePostVariables(
      imageUrl: imageUrl,
      caption: caption,
      location: _location,
    );
    return _dataConnect.mutation(
      "CreatePost",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreatePostPostInsert {
  final String id;
  CreatePostPostInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostPostInsert otherTyped = other as CreatePostPostInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  const CreatePostPostInsert({required this.id});
}

@immutable
class CreatePostData {
  final CreatePostPostInsert postInsert;
  CreatePostData.fromJson(dynamic json)
    : postInsert = CreatePostPostInsert.fromJson(json['post_insert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostData otherTyped = other as CreatePostData;
    return postInsert == otherTyped.postInsert;
  }

  @override
  int get hashCode => postInsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['post_insert'] = postInsert.toJson();
    return json;
  }

  const CreatePostData({required this.postInsert});
}

@immutable
class CreatePostVariables {
  final String imageUrl;
  final String caption;
  final Optional<String> location;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreatePostVariables.fromJson(Map<String, dynamic> json)
    : imageUrl = nativeFromJson<String>(json['imageUrl']),
      caption = nativeFromJson<String>(json['caption']),
      location = Optional.fromJson(
        json['location'],
        (dynamic json) => nativeFromJson<String>(json),
        (String value) => nativeToJson<String>(value),
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreatePostVariables otherTyped = other as CreatePostVariables;
    return imageUrl == otherTyped.imageUrl &&
        caption == otherTyped.caption &&
        location == otherTyped.location;
  }

  @override
  int get hashCode =>
      Object.hashAll([imageUrl.hashCode, caption.hashCode, location.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['imageUrl'] = nativeToJson<String>(imageUrl);
    json['caption'] = nativeToJson<String>(caption);
    if (location.state == OptionalState.set) {
      json['location'] = location.toJson();
    }
    return json;
  }

  const CreatePostVariables({
    required this.imageUrl,
    required this.caption,
    required this.location,
  });
}
