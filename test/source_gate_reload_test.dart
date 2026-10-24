import 'package:duanju_app/app_build.dart';
import 'package:duanju_app/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStore> create([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(Map.of(initial));
    final store = testStore(await SharedPreferences.getInstance());
    addTearDown(store.dispose);
    return store;
  }

  int get unlockedCount => allSourcesEnabled ? 11 : 1;
  int get lockedCount => allSourcesEnabled ? 4 : 1;

  test('background reload keeps the unlocked sources visible', () async {
    final store = await create(await gatePreferences());
    await unlockGate(store);
    expect(store.sources.length, unlockedCount);
    final unlocked = store.sources.map((site) => site.id).toList();

    // 自动导出定时器每 8 秒调用一次 reload()，不能抹掉本次运行的解锁状态。
    await store.reload();

    expect(store.sourcesUnlocked, isTrue);
    expect(store.sources.map((site) => site.id).toList(), unlocked);
    expect(store.allowsSource('huangdou'), unlockedCount > lockedCount);
  });

  test('reload keeps sources the user explicitly locked', () async {
    final store = await create(await gatePreferences());
    await unlockGate(store);
    store.lockSources();
    expect(store.sources.length, lockedCount);

    await store.reload();

    expect(store.sourcesUnlocked, isFalse);
    expect(store.sources.length, lockedCount);
  });

  test('a fresh store after restart is locked again', () async {
    final store = await create(await gatePreferences());
    await unlockGate(store);
    final restarted = testStore(store.preferences);
    addTearDown(restarted.dispose);

    expect(restarted.sourcesUnlocked, isFalse);
    expect(restarted.sources.length, lockedCount);
  });
}
