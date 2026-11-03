// C# 12, .NET 10; IBufferWriter<byte> with explicit pooled-buffer ownership.
// Single owner/thread. Borrowed spans expire on the next request/Advance/Dispose.
// Pool must obey ArrayPool's contract. Logical capacity is capped even when a
// pool returns a larger array. No network, packages or finalizer-based cleanup.
using System;
using System.Buffers;
using System.Collections.Generic;
using System.IO;
using System.Linq;

sealed class PooledWriter : IBufferWriter<byte>, IDisposable
{
    readonly ArrayPool<byte> pool;
    readonly int maximum;
    byte[]? buffer;
    int written;
    bool disposed;

    public PooledWriter(ArrayPool<byte> pool, int maximum)
    {
        ArgumentNullException.ThrowIfNull(pool);
        if (maximum < 1 || maximum > 4096) throw new ArgumentOutOfRangeException(nameof(maximum));
        this.pool = pool;
        this.maximum = maximum;
    }
    int Capacity => buffer is null ? 0 : Math.Min(buffer.Length, maximum);
    void Alive() { if (disposed) throw new ObjectDisposedException(nameof(PooledWriter)); }
    public ReadOnlySpan<byte> Written
    {
        get { Alive(); return buffer is null ? ReadOnlySpan<byte>.Empty : buffer.AsSpan(0, written); }
    }
    void Ensure(int hint)
    {
        Alive();
        if (hint < 0) throw new ArgumentOutOfRangeException(nameof(hint));
        int needed = Math.Max(hint, 1); // IBufferWriter requires a nonempty grant for hint zero.
        if (needed > maximum - written) throw new InvalidOperationException("logical limit exceeded");
        if (needed <= Capacity - written) return;
        int target = Math.Min(maximum, Math.Max(written + needed, Math.Max(16, Capacity * 2)));
        // Allocate before changing ownership: a rental failure preserves old data.
        byte[] replacement = pool.Rent(target);
        if (buffer is not null)
        {
            buffer.AsSpan(0, written).CopyTo(replacement);
            pool.Return(buffer, clearArray: true);
        }
        buffer = replacement;
    }
    public Memory<byte> GetMemory(int sizeHint = 0)
    {
        Ensure(sizeHint);
        return buffer!.AsMemory(written, Capacity - written);
    }
    public Span<byte> GetSpan(int sizeHint = 0)
    {
        Ensure(sizeHint);
        return buffer!.AsSpan(written, Capacity - written);
    }
    public void Advance(int count)
    {
        Alive();
        if (count < 0 || count > Capacity - written) throw new ArgumentOutOfRangeException(nameof(count));
        written += count;
    }
    public void Dispose()
    {
        if (disposed) return;
        disposed = true;
        byte[]? owned = buffer;
        buffer = null;
        written = 0;
        if (owned is not null) pool.Return(owned, clearArray: true);
    }
}

sealed class TrackingPool : ArrayPool<byte>
{
    public readonly List<byte[]> Rented = new();
    public readonly List<byte[]> Returned = new();
    public bool FailNext;
    public readonly IOException Failure = new("fixture rental failure");
    public override byte[] Rent(int minimumLength)
    {
        if (FailNext) { FailNext = false; throw Failure; }
        // Pools are allowed to return more space than requested.
        byte[] bytes = Enumerable.Repeat((byte)0xcd, minimumLength + 3).ToArray();
        Rented.Add(bytes);
        return bytes;
    }
    public override void Return(byte[] array, bool clearArray = false)
    {
        Program.Check(Rented.Any(x => ReferenceEquals(x, array)));
        Program.Check(!Returned.Any(x => ReferenceEquals(x, array)));
        Program.Check(clearArray);
        if (clearArray) Array.Clear(array);
        Returned.Add(array);
    }
}

static class Program
{
    public static void Check(bool truth) { if (!truth) throw new Exception("assertion failed"); }
    static T Reject<T>(Action action) where T : Exception
    {
        try { action(); }
        catch (T error) { return error; }
        throw new Exception("expected rejection: " + typeof(T).Name);
    }
    static void Main()
    {
        var pool = new TrackingPool();
        var writer = new PooledWriter(pool, 64);
        Check(writer.Written.IsEmpty && pool.Rented.Count == 0);
        writer.Write("abc"u8); // real IBufferWriter extension, not a private test API
        Check(writer.Written.SequenceEqual("abc"u8));
        Check(pool.Rented.Count == 1);
        pool.FailNext = true;
        IOException error = Reject<IOException>(() => { writer.GetMemory(20); });
        Check(ReferenceEquals(error, pool.Failure));
        Check(writer.Written.SequenceEqual("abc"u8) && pool.Returned.Count == 0);
        Span<byte> grant = writer.GetSpan(20);
        grant[..20].Fill(0x5a);
        writer.Advance(20);
        Check(writer.Written.SequenceEqual(new byte[] { 97, 98, 99 }.Concat(Enumerable.Repeat((byte)0x5a, 20)).ToArray()));
        Check(pool.Rented.Count == 2 && pool.Returned.Count == 1);
        Check(pool.Returned[0].All(x => x == 0));
        int before = writer.Written.Length;
        Reject<ArgumentOutOfRangeException>(() => writer.Advance(-1));
        Reject<ArgumentOutOfRangeException>(() => writer.Advance(65));
        Reject<ArgumentOutOfRangeException>(() => { writer.GetMemory(-1); });
        Reject<InvalidOperationException>(() => { writer.GetMemory(64); });
        Check(writer.Written.Length == before);
        writer.Dispose(); writer.Dispose();
        Check(pool.Returned.Count == 2 && pool.Returned.All(x => x.All(b => b == 0)));
        Reject<ObjectDisposedException>(() => { _ = writer.Written.Length; });
        Reject<ObjectDisposedException>(() => { writer.GetMemory(); });
        Reject<ObjectDisposedException>(() => writer.Advance(0));
        var tinyPool = new TrackingPool();
        using (var tiny = new PooledWriter(tinyPool, 3))
        {
            Memory<byte> memory = tiny.GetMemory(0);
            Check(memory.Length == 3); // pool actually returned six bytes
            new byte[] { 1, 2, 3 }.CopyTo(memory);
            tiny.Advance(3);
            Check(tiny.Written.SequenceEqual(new byte[] { 1, 2, 3 }));
            Reject<InvalidOperationException>(() => { tiny.GetMemory(0); });
            Reject<ArgumentOutOfRangeException>(() => tiny.Advance(1));
            tiny.Advance(0);
        }
        Check(tinyPool.Returned.Count == 1);
        var unusedPool = new TrackingPool();
        using (var unused = new PooledWriter(unusedPool, 1)) unused.Advance(0);
        Check(unusedPool.Rented.Count == 0 && unusedPool.Returned.Count == 0);
        Reject<ArgumentOutOfRangeException>(() => new PooledWriter(pool, 0));
        Reject<ArgumentOutOfRangeException>(() => new PooledWriter(pool, 4097));
        Reject<ArgumentNullException>(() => new PooledWriter(null!, 1));
        // Independent byte sink across small logical capacities. Oversized
        // physical rentals must never change where overflow is reported.
        for (int limit = 1; limit <= 64; limit++)
        {
            var differentialPool = new TrackingPool();
            using (var actual = new PooledWriter(differentialPool, limit))
            using (var reference = new MemoryStream())
            {
                for (int i = 0; i < limit; i++)
                {
                    byte value = (byte)(i * 17 + 3);
                    actual.GetSpan(1)[0] = value;
                    actual.Advance(1);
                    reference.WriteByte(value);
                    Check(actual.Written.SequenceEqual(reference.ToArray()));
                }
                Reject<InvalidOperationException>(() => { actual.GetMemory(1); });
                Check(actual.Written.SequenceEqual(reference.ToArray()));
            }
            Check(differentialPool.Rented.Count == differentialPool.Returned.Count);
            Check(differentialPool.Returned.All(x => x.All(b => b == 0)));
        }
        Console.WriteLine("Pooled writer: ownership, oversized grants, rental failure atomicity, boundaries, clear returns and idempotent disposal passed");
    }
}
