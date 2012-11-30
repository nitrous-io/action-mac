require 'SpecHelper'
require 'AIOModel'

class TestModel < AIOModel
  attr_accessor :first_name, :last_name, :age
end

describe AIOModel do
  describe 'constructor' do
    it 'sets properties given in attrs, ignoring properties that do not exist' do
      person = TestModel.new id: 1, first_name: 'leeroy', 'last_name' => 'jenkins', age: 20, job: 'paladin'
      person.id.should.equal 1
      person.first_name.should.equal 'leeroy'
      person.last_name.should.equal 'jenkins'
      person.age.should.equal 20
      person.should.not.respond_to :job
    end
  end

  describe '#update_attributes' do
    it 'mass-sets attributes' do
      person = TestModel.new
      person.update_attributes id: 1, first_name: 'leeroy', 'last_name' => 'jenkins', age: 20, job: 'paladin'
      person.id.should.equal 1
      person.first_name.should.equal 'leeroy'
      person.last_name.should.equal 'jenkins'
      person.age.should.equal 20
      person.should.not.respond_to :job
    end
  end
end
