class AIOJobManager
  def initialize
    @jobs = []
    @mutex = Mutex.new
  end

  def jobs
    @jobs.dup
  end

  def find(name)
    @jobs.select { |j| j.name == name }
  end

  def add(job, allow_dupe=false)
    @mutex.synchronize do
      if allow_dupe || job.name.nil? || find(job.name).all?(&:cancelled)
        @jobs << job
        job.perform
      end
    end
  end

  def cancel(name)
    @mutex.synchronize do
      if job = @jobs.find { |j| j.name == name }
        job.cancel!
      end
    end
  end

  def cancel_all
    @mutex.synchronize do
      @jobs.each &:cancel!
    end
  end

  def process_jobs
    @mutex.synchronize do
      unless @jobs.empty?
        @jobs.delete_if do |job|
          !job.running && (job.completed || job.cancelled)
        end
        @jobs.each &:perform
      end
    end
  end
end
