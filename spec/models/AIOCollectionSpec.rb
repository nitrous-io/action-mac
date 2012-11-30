require 'SpecHelper'
require 'AIOCollection'
require 'AIOModel'

class TestModel < AIOModel
  attr_accessor :name, :state, :host, :port
end

class TestCollection < AIOCollection
  model TestModel
  resource_path '/boxes'
  json_root 'boxes'
end

describe AIOCollection do
  before do
    @api = mock 'api'
    @collection = TestCollection.new @api
  end

  describe '.model' do
    it 'sets the class for the model' do
      TestCollection.instance_variable_get(:@model).should.equal TestModel
    end
  end

  describe '.resource_path' do
    it 'sets the path for the resource' do
      TestCollection.instance_variable_get(:@resource_path).should.equal '/boxes'
    end
  end

  describe '.json_root' do
    it 'sets name of the root for resources json"' do
      TestCollection.instance_variable_get(:@json_root).should.equal 'boxes'
    end
  end

  describe 'constructor' do
    it 'sets @api' do
      @collection.api.should.equal @api
    end

    it 'should be an empty array' do
      @collection.should.be.empty
    end
  end

  describe '#find_by_id' do
    before do
      @one = AIOModel.new id: 1
      @two = AIOModel.new id: 2
      @three = AIOModel.new id: 3
      @collection << @one << @two << @three
    end

    it 'returns an item with a given id' do
      @collection.find_by_id(1).should.equal @one
      @collection.find_by_id(3).should.equal @three
      @collection.find_by_id(2).should.equal @two
    end
  end

  describe '#fetch' do
    context 'when request returns nil' do
      before do
        @api.should.receive(:request).with(:get, '/boxes').and_return nil
      end

      it 'does nothing' do
        @collection.fetch.should.be.nil
        @collection.should.be.empty
      end
    end

    context 'when request returns a response' do
      before do
        @petes_box = TestModel.new id: 1, name: 'petes-box', state: 'running', host: 'petes-box.actionbox.io', port: 12345
        @dans_box = TestModel.new id: 4, name: 'dans-box', state: 'running', host: 'dans-box.actionbox.io', port: 13333
        @collection << @petes_box << @dans_box
        hash = {
          'boxes' => [
            { 'id' => 1, 'name' => 'petes-box2', 'state' => 'stopped', 'host' => 'petes-box2.actionbox.io', 'port' => 10000 },
            { 'id' => 3, 'name' => 'aruns-box',  'state' => 'running', 'host' => 'aruns-box.actionbox.io',  'port' => 34567 },
            { 'id' => 2, 'name' => 'ajs-box',    'state' => 'stopped', 'host' => 'ajs-box.actionbox.io',    'port' => 23456 }
          ]
        }
        response = mock 'response', parsed: hash
        @api.should.receive(:request).with(:get, '/boxes').and_return response
      end

      it 'populates the collection with the fetched items, updating values for pre-existing models' do
        @collection.fetch
        @collection.size.should.equal 3

        @collection[0].should.equal @petes_box
        @collection[0].id.should.equal 1
        @collection[0].name.should.equal 'petes-box2'
        @collection[0].state.should.equal 'stopped'
        @collection[0].host.should.equal 'petes-box2.actionbox.io'
        @collection[0].port.should.equal 10000

        @collection[1].should.be.instance_of TestModel
        @collection[1].id.should.equal 2
        @collection[1].name.should.equal 'ajs-box'
        @collection[1].state.should.equal 'stopped'
        @collection[1].host.should.equal 'ajs-box.actionbox.io'
        @collection[1].port.should.equal 23456

        @collection[2].should.be.instance_of TestModel
        @collection[2].id.should.equal 3
        @collection[2].name.should.equal 'aruns-box'
        @collection[2].state.should.equal 'running'
        @collection[2].host.should.equal 'aruns-box.actionbox.io'
        @collection[2].port.should.equal 34567

        @collection.should.not.include @dans_box
      end
    end
  end
end
