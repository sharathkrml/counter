import os
import tempfile

from counter_backend.services.counter import CounterService


def _svc():
    d = tempfile.mkdtemp()
    path = os.path.join(d, "counter.sqlite3")
    svc = CounterService(db_path=path)
    svc._initialize()
    return svc


def test_counter_operations():
    svc = _svc()
    svc.reset()
    assert svc.get_count() == 0
    assert svc.increment() == 1
    assert svc.increment() == 2
    assert svc.decrement() == 1
    assert svc.reset() == 0


def test_initial_counter():
    svc = _svc()
    assert svc.get_count() == 0


def test_multiple_increments():
    svc = _svc()
    for i in range(1, 11):
        assert svc.increment() == i
    assert svc.get_count() == 10


def test_persistence():
    d = tempfile.mkdtemp()
    path = os.path.join(d, "counter.sqlite3")
    svc1 = CounterService(db_path=path)
    svc1._initialize()
    svc1.increment()
    svc1.increment()
    assert svc1.get_count() == 2
    svc2 = CounterService(db_path=path)
    assert svc2.get_count() == 2


def test_concurrent_increments():
    import threading
    d = tempfile.mkdtemp()
    path = os.path.join(d, "counter.sqlite3")
    svc = CounterService(db_path=path)
    svc._initialize()

    def worker():
        for _ in range(50):
            svc.increment()

    threads = [threading.Thread(target=worker) for _ in range(4)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert svc.get_count() == 200
