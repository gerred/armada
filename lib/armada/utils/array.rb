class Array
  def each_in_parallel(&block)
    threads = map do |s|
      Thread.new { block.call(s) }
    end

    threads.each { |t| t.join }
  end
end
