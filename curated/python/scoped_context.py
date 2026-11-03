"""Python 3.11+: task-local context, nested scopes and token restoration.

Run: python scoped_context.py. No network/files or third-party dependencies.
Values are immutable dataclasses: propagating a ContextVar copies bindings, not
arbitrary mutable objects. Child tasks inherit the binding at task creation.
"""
import asyncio
from contextlib import contextmanager
from contextvars import ContextVar, copy_context
from dataclasses import dataclass, replace


@dataclass(frozen=True)
class Request:
    trace: str
    tenant: str


_current: ContextVar[Request | None] = ContextVar("request", default=None)


def current() -> Request:
    value = _current.get()
    if value is None:
        raise LookupError("no request scope")
    return value


@contextmanager
def request_scope(trace: str, tenant: str):
    if not isinstance(trace, str) or not trace or len(trace) > 64:
        raise ValueError("trace must be 1..64 characters")
    if not isinstance(tenant, str) or not tenant or len(tenant) > 32:
        raise ValueError("tenant must be 1..32 characters")
    token = _current.set(Request(trace, tenant))
    try:
        yield current()
    finally:
        # Setting None would incorrectly erase a surrounding scope.
        _current.reset(token)


def absent():
    try:
        current()
    except LookupError:
        return
    raise AssertionError("scope leaked")


async def task_checks():
    entered = asyncio.Event()
    release = asyncio.Event()

    async def child():
        inherited = current()
        entered.set()
        await release.wait()
        assert current() == inherited == Request("parent", "north")
        with request_scope("child", "south"):
            await asyncio.sleep(0)  # an actual scheduling boundary
            assert current() == Request("child", "south")
        assert current() == inherited
        return inherited

    with request_scope("parent", "north"):
        task = asyncio.create_task(child())
        await entered.wait()
        with request_scope("changed-parent", "west"):
            release.set()
            assert await task == Request("parent", "north")
            assert current() == Request("changed-parent", "west")
        assert current() == Request("parent", "north")
    absent()

    # Cancellation must run finally in the cancelled task and leave siblings
    # and the parent binding alone. Synchronize explicitly, not with a delay.
    cancelled_entered = asyncio.Event()
    cleanup = []

    async def cancelled_child():
        try:
            with request_scope("cancelled", "east"):
                cancelled_entered.set()
                await asyncio.Event().wait()
        finally:
            cleanup.append(current())

    with request_scope("survivor", "north"):
        task = asyncio.create_task(cancelled_child())
        await cancelled_entered.wait()
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
        else:
            raise AssertionError("cancellation was swallowed")
        assert cleanup == [Request("survivor", "north")]
        assert current() == Request("survivor", "north")
    absent()


def main():
    absent()
    failure = RuntimeError("fixture")
    with request_scope("outer", "north") as outer:
        try:
            with request_scope("inner", "south"):
                assert current() == Request("inner", "south")
                raise failure
        except RuntimeError as actual:
            assert actual is failure
        assert current() is outer
        copied = copy_context()
        copied.run(_current.set, replace(outer, trace="copied"))
        assert copied.run(current).trace == "copied"
        assert current().trace == "outer"
        for trace, tenant in [("", "x"), ("x" * 65, "y"), (None, "x"),
                              ("x", ""), ("x", "y" * 33), ("x", 1)]:
            try:
                with request_scope(trace, tenant):
                    raise AssertionError("invalid scope accepted")
            except ValueError:
                pass
            assert current() is outer
    absent()
    with request_scope("x" * 64, "y" * 32):
        assert len(current().trace) == 64
    asyncio.run(task_checks())
    absent()
    print("Context scopes: nesting, exceptions, copied bindings, task inheritance and cancellation cleanup passed")


if __name__ == "__main__":
    main()
