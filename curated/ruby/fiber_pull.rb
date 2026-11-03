# Ruby 3+: thread-bound cooperative pull producer with explicit cleanup.
# ruby fiber_pull.rb; core runtime only. Owner must close an unfinished task.
# Producer emits only through the supplied callback, acquires resources inside
# its block, never yields during ensure, and does not intercept private Cancel.
# This is cooperative cancellation, not a way to kill arbitrary Ruby code.
class PullTask
  class ClosedError < StandardError; end
  class Cancel < Exception; end # generic rescue StandardError must not swallow it
  private_constant :Cancel
  attr_reader :state

  def initialize(&producer)
    raise ArgumentError, 'producer block required' unless producer
    @owner = Thread.current
    @state = :new
    @busy = false
    @result = @failure = nil
    @fiber = Fiber.new do
      begin
        result = producer.call(->(item) { Fiber.yield([:item, item]) })
        [:done, result]
      rescue Cancel
        [:closed, nil]
      end
    end
  end
  def step
    access!
    return [:done, @result] if @state == :done
    raise ClosedError, 'task closed' if @state == :closed
    raise @failure if @state == :failed
    message = invoke { @fiber.resume }
    case message[0]
    when :item
      @state = :waiting
      message
    when :done
      @state = :done
      @result = message[1]
      @fiber = nil
      [:done, @result]
    else
      raise FiberError, 'producer violated emission protocol'
    end
  end
  def close
    access!
    return nil if [:done, :closed, :failed].include?(@state)
    if @state == :new
      @state = :closed
      @fiber = nil # unstarted producer has acquired nothing
      return nil
    end
    message = invoke { @fiber.raise(Cancel.new) }
    raise FiberError, 'producer intercepted cancellation' unless message == [:closed, nil] && !@fiber.alive?
    @fiber = nil
    @state = :closed
    nil
  end
  private
  def access!
    raise ThreadError, 'owner thread required' unless Thread.current.equal?(@owner)
    raise FiberError, 'recursive task operation' if @busy
  end
  def invoke
    @busy = true
    begin
      yield
    rescue Exception => error # preserve all producer failures, then re-raise
      @state = :failed
      @failure = error
      @fiber = nil
      raise
    ensure
      @busy = false
    end
  end
end
def check(truth)
  raise 'assertion failed' unless truth
end
def rejection(type)
  begin
    yield
  rescue type => error
    return error
  end
  raise "expected #{type}"
end

rejection(ArgumentError) { PullTask.new }
events = []
unstarted = PullTask.new { events << :must_not_run }
unstarted.close; unstarted.close
check(unstarted.state == :closed && events.empty?)
rejection(PullTask::ClosedError) { unstarted.step }
empty = PullTask.new { nil }
check(empty.step == [:done, nil] && empty.step == [:done, nil])
empty.close
check(empty.state == :done)

payload = [:done, 'this is item data']
task = PullTask.new do |emit|
  events << :open
  begin
    emit.call(nil)
    emit.call(false)
    emit.call(payload)
    42
  ensure
    events << :closed
  end
end
check(events.empty? && task.state == :new)
check(task.step == [:item, nil])
check(task.step == [:item, false])
check(task.step[1].equal?(payload))
check(events == [:open] && task.state == :waiting)
check(task.step == [:done, 42] && task.step == [:done, 42])
task.close
check(events == [:open, :closed])

events.clear
rescued = []
early = PullTask.new do |emit|
  events << :open
  begin
    emit.call(:first)
    raise 'must not resume normally after close'
  rescue StandardError => error
    rescued << error
  ensure
    events << :closed
  end
end
check(early.step == [:item, :first])
early.close; early.close
check(events == [:open, :closed] && rescued.empty?)
rejection(PullTask::ClosedError) { early.step }

events.clear
boom = RuntimeError.new('fixture producer error')
failed = PullTask.new do |emit|
  begin
    emit.call(1)
    raise boom
  ensure
    events << :closed
  end
end
check(failed.step == [:item, 1])
check(rejection(RuntimeError) { failed.step }.equal?(boom))
check(rejection(RuntimeError) { failed.step }.equal?(boom))
failed.close
check(failed.state == :failed && events == [:closed])

events.clear
cleanup_error = IOError.new('fixture cleanup error')
bad_cleanup = PullTask.new do |emit|
  begin
    emit.call(1)
  ensure
    events << :closed
    raise cleanup_error
  end
end
bad_cleanup.step
check(rejection(IOError) { bad_cleanup.close }.equal?(cleanup_error))
bad_cleanup.close
check(rejection(IOError) { bad_cleanup.step }.equal?(cleanup_error))
check(events == [:closed])

events.clear
recursive = nil
recursive = PullTask.new do |_emit|
  begin
    recursive.step
  ensure
    events << :closed
  end
end
error = rejection(FiberError) { recursive.step }
check(error.message == 'recursive task operation' && recursive.state == :failed)
check(rejection(FiberError) { recursive.step }.equal?(error) && events == [:closed])

owned = PullTask.new { |emit| emit.call(:owner); :complete }
foreign_error = Thread.new { rejection(ThreadError) { owned.step } }.value
check(foreign_error.message == 'owner thread required' && owned.state == :new)
check(owned.step == [:item, :owner] && owned.step == [:done, :complete])
puts 'Fiber pull: lazy acquisition, tagged data/end, cooperative close, cleanup failures, reentrancy and owner-thread checks passed'
