// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'c62213bddb9aac89c0a19fe034ef243e2a285ba8';

@ProviderFor(aiRemoteDataSource)
final aiRemoteDataSourceProvider = AiRemoteDataSourceProvider._();

final class AiRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AiRemoteDataSource,
          AiRemoteDataSource,
          AiRemoteDataSource
        >
    with $Provider<AiRemoteDataSource> {
  AiRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AiRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiRemoteDataSource create(Ref ref) {
    return aiRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiRemoteDataSource>(value),
    );
  }
}

String _$aiRemoteDataSourceHash() =>
    r'e0de7a9c185ecf53f2bfbbefd569ae7249e69330';

@ProviderFor(aiPlannerRepository)
final aiPlannerRepositoryProvider = AiPlannerRepositoryProvider._();

final class AiPlannerRepositoryProvider
    extends
        $FunctionalProvider<
          IAiPlannerRepository,
          IAiPlannerRepository,
          IAiPlannerRepository
        >
    with $Provider<IAiPlannerRepository> {
  AiPlannerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiPlannerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiPlannerRepositoryHash();

  @$internal
  @override
  $ProviderElement<IAiPlannerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IAiPlannerRepository create(Ref ref) {
    return aiPlannerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAiPlannerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAiPlannerRepository>(value),
    );
  }
}

String _$aiPlannerRepositoryHash() =>
    r'e5d6313a41f741154eae1607a691798e97e7f063';

/// 当前生成的行程状态

@ProviderFor(CurrentItineraryNotifier)
final currentItineraryProvider = CurrentItineraryNotifierProvider._();

/// 当前生成的行程状态
final class CurrentItineraryNotifierProvider
    extends
        $NotifierProvider<CurrentItineraryNotifier, AsyncValue<Itinerary?>> {
  /// 当前生成的行程状态
  CurrentItineraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentItineraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentItineraryNotifierHash();

  @$internal
  @override
  CurrentItineraryNotifier create() => CurrentItineraryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Itinerary?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Itinerary?>>(value),
    );
  }
}

String _$currentItineraryNotifierHash() =>
    r'7e2b1a6b8f1210e354bd2a33f33ebaba041fd508';

/// 当前生成的行程状态

abstract class _$CurrentItineraryNotifier
    extends $Notifier<AsyncValue<Itinerary?>> {
  AsyncValue<Itinerary?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Itinerary?>, AsyncValue<Itinerary?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Itinerary?>, AsyncValue<Itinerary?>>,
              AsyncValue<Itinerary?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
