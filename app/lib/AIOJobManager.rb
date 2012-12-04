class AIOJobManager
  def initialize
    @jobs = []
    @mutex = Mutex.new
  end

  def jobs
    @jobs.dup
  end

  def find(name)
    @jobs.find { |j| j.name == name }
  end

  def add(job)
    @mutex.synchronize do
      if job.name.nil? || find(job.name).nil?
        @jobs << job
        job.perform
      end
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
