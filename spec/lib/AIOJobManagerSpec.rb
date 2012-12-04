require 'SpecHelper'
require 'AIOJobManager'
require 'AIOJob'

describe AIOJobManager do
  before do
    @manager = AIOJobManager.new
  end

  it 'does not have any job by default' do
    @manager.jobs.should.be.empty
  end

  describe '#jobs' do
    it 'returns a shallow copy of the underlying @jobs array' do
      @manager.instance_variable_set :@jobs, [:foo, :bar]
      jobs = @manager.jobs
      jobs.should.equal [:foo, :bar]
      jobs << :baz
      @manager.jobs.should.equal [:foo, :bar]
    end
  end

  describe '#find' do
    before do
      @job1 = AIOJob.new('test-job') { 1 }
      @manager.instance_variable_set :@jobs, [@job1]
    end

    context 'when a job with a given name exists' do
      it 'returns the job' do
        @manager.find('test-job').should.equal @job1
      end
    end

    context 'when a job with a given name does not exist' do
      it 'returns nil' do
        @manager.find('some-job').should.be.nil
      end
    end
  end

  describe '#add' do
    context 'when job name is given' do
      before do
        @job1 = AIOJob.new('test-job') { 1 }
        @job2 = AIOJob.new('test-job') { 2 }
        @job3 = AIOJob.new('test-job3') { 3 }
        @job4 = AIOJob.new { 4 }
        @job5 = AIOJob.new { 5 }
        @manager.instance_variable_set :@jobs, [@job1]
      end

      context 'when a job with a same name exists' do
        it 'does not add the job' do
          @manager.add @job2
          @manager.jobs.size.should.equal 1
          @manager.jobs.should.include @job1
        end
      end

      context 'when a job with a same name does not exist' do
        it 'adds and performs the job' do
          @job3.should.receive :perform
          @manager.add @job3
          @job4.should.receive :perform
          @manager.add @job4
          @job5.should.receive :perform
          @manager.add @job5
          @manager.jobs.size.should.equal 4
          @manager.jobs.should.include @job1
          @manager.jobs.should.include @job3
          @manager.jobs.should.include @job4
          @manager.jobs.should.include @job5
        end
      end
    end
  end

  describe '#process_jobs' do
    before do
      jobs = []

      jobs << @non_running_job1 = AIOJob.new { sleep 10 }
      jobs << @non_running_job2 = AIOJob.new { sleep 10 }

      jobs << @running_job1 = mass_set(AIOJob.new {}, running: true)
      jobs << @running_job2 = mass_set(AIOJob.new {}, running: true)

      jobs << @non_running_cancelled_job1 = mass_set(AIOJob.new {}, cancelled: true)
      jobs << @non_running_cancelled_job2 = mass_set(AIOJob.new {}, cancelled: true)
      jobs << @running_cancelled_job = mass_set(AIOJob.new {}, cancelled: true, running: true)

      jobs << @non_running_completed_job1 = mass_set(AIOJob.new { sleep 5 }, completed: true)
      jobs << @non_running_completed_job2 = mass_set(AIOJob.new { sleep 5 }, completed: true)
      jobs << @running_completed_job = mass_set(AIOJob.new {}, completed: true, running: true)

      jobs << @non_running_failed_job2 = mass_set(AIOJob.new { sleep 5 }, failed: true, last_error: StandardError.new)
      jobs << @non_running_failed_job1 = mass_set(AIOJob.new { sleep 5 }, failed: true, last_error: StandardError.new)
      jobs << @running_failed_job = mass_set(AIOJob.new {}, failed: true, last_error: StandardError.new, running: true)

      jobs.each { |job| job.stub :perform }
      @manager.instance_variable_set :@jobs, jobs
    end

    it 'removes non-running cancelled jobs' do
      @manager.process_jobs
      @manager.jobs.should.not.include @non_running_cancelled_job1
      @manager.jobs.should.not.include @non_running_cancelled_job2
      @manager.jobs.should.include @running_cancelled_job
    end

    it 'removes non-running completed jobs' do
      @manager.process_jobs
      @manager.jobs.should.not.include @non_running_completed_job1
      @manager.jobs.should.not.include @non_running_completed_job2
      @manager.jobs.should.include @running_completed_job
    end

    it 'calls perform on the rest' do
      @non_running_job1.should.receive :perform
      @non_running_job2.should.receive :perform
      @running_job1.should.receive :perform
      @running_job2.should.receive :perform
      @running_cancelled_job.should.receive :perform
      @running_completed_job.should.receive :perform
      @non_running_failed_job1.should.receive :perform
      @non_running_failed_job2.should.receive :perform
      @running_failed_job.should.receive :perform

      @manager.process_jobs
    end
  end
end
