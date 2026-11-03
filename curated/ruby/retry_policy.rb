# Ruby 3: injected sleeper, bounded retry policy, blocks and error identity.
# No real sleeping, network calls or random timing in the fixture checks.
class RetryPolicy
  def initialize(attempts:, initial_delay:, maximum_delay:, sleep:)
    raise ArgumentError unless attempts.is_a?(Integer) && attempts.between?(1, 10)
    raise ArgumentError unless initial_delay.is_a?(Integer) && initial_delay >= 0
    raise ArgumentError unless maximum_delay.is_a?(Integer) && maximum_delay >= initial_delay
    @attempts,@initial,@maximum,@sleep=attempts,initial_delay,maximum_delay,sleep
  end
  def call(retry_if:)
    delay=@initial
    (1..@attempts).each do |attempt|
      begin
        return yield(attempt)
      rescue StandardError => error
        raise unless attempt<@attempts && retry_if.call(error)
        @sleep.call(delay)
        # Saturate before doubling so the bound remains explicit.
        delay=delay>@maximum/2 ? @maximum : delay*2
      end
    end
    raise 'unreachable'
  end
end
class Transient < StandardError; end
def check(value)
  raise 'assertion failed' unless value
end
delays=[];seen=[]
policy=RetryPolicy.new(attempts:5,initial_delay:3,maximum_delay:10,sleep:->(n){delays<<n})
result=policy.call(retry_if:->(e){e.is_a?(Transient)}) do |attempt|
  seen<<attempt
  raise Transient,'again' if attempt<5
  :complete
end
check(result==:complete && seen==[1,2,3,4,5] && delays==[3,6,10,10])
failure=Transient.new('same object');delays.clear;count=0
begin
  policy.call(retry_if:->(_){true}){count+=1;raise failure}
  raise 'missing failure'
rescue Transient => actual
  check(actual.equal?(failure) && count==5 && delays==[3,6,10,10])
end
delays.clear;count=0
begin
  policy.call(retry_if:->(_){false}){count+=1;raise ArgumentError,'permanent'}
  raise 'missing rejection'
rescue ArgumentError
  check(count==1 && delays.empty?)
end
once=RetryPolicy.new(attempts:1,initial_delay:0,maximum_delay:0,sleep:->(_){raise 'must not sleep'})
check(once.call(retry_if:->(_){true}){nil}.nil?)
invalid=false
begin RetryPolicy.new(attempts:0,initial_delay:1,maximum_delay:1,sleep:->(_){});rescue ArgumentError;invalid=true;end
check(invalid)
[[11,0,0],['2',0,0],[1,-1,0],[1,2,1]].each do |attempts,initial,maximum|
  rejected=false
  begin
    RetryPolicy.new(attempts:attempts,initial_delay:initial,maximum_delay:maximum,sleep:->(_) {})
  rescue ArgumentError
    rejected=true
  end
  check(rejected)
end
zeros=[]
zero_policy=RetryPolicy.new(attempts:3,initial_delay:0,maximum_delay:0,sleep:->(n){zeros<<n})
check(zero_policy.call(retry_if:->(_){true}){|n| raise Transient if n<3; :ok}==:ok)
check(zeros==[0,0])
puts 'Retry policy: bounded delays, injected sleeper, predicate and original exception identity passed'
