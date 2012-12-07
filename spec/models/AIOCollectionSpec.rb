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

  def models
    @content ||= []
  end
end

describe AIOCollection do
  before do
    @api = mock 'api'
    @collection = TestCollection.new
    @collection.stub(:api).and_return @api
  end

  describe '.model' do
    it 'sets the class for the model' do
      TestCollection.class_variable_get(:@@model).should.equal TestModel
    end
  end

  describe '.resource_path' do
    it 'sets the path for the resource' do
      TestCollection.class_variable_get(:@@resource_path).should.equal '/boxes'
    end
  end

  describe '.json_root' do
    it 'sets name of the root for resources json"' do
      TestCollection.class_variable_get(:@@json_root).should.equal 'boxes'
    end
  end

  describe '#api' do
    context 'when not overridden' do
      before do
        @collection = AIOCollection.new
      end

      it 'raises NotImplementedError' do
        -> { @collection.api }.should.raise NotImplementedError
      end
    end
  end

  describe '#models' do
    context 'when not overridden' do
      before do
        @collection = AIOCollection.new
      end

      it 'raises NotImplementedError' do
        -> { @collection.models }.should.raise NotImplementedError
      end
    end
  end

  describe '#add_object' do
    before do
      @model = AIOModel.new id: 1
      @collection.add_object @model
    end

    it 'adds a given object to models' do
      @collection.models.should.equal [@model]
    end
  end

  describe '#add_objects' do
    before do
      @one = AIOModel.new id: 1
      @two = AIOModel.new id: 2
      @collection.add_objects [@one, @two]
    end

    it 'adds given objects to models' do
      @collection.models.should.equal [@one, @two]
    end
  end

  describe '#remove_object' do
    before do
      @one = AIOModel.new id: 1
      @two = AIOModel.new id: 2
      @collection.models.concat [@one, @two]
      @collection.remove_object @one
    end

    it 'removes a given object from models' do
      @collection.models.should.equal [@two]
    end
  end

  describe '#remove_objects' do
    before do
      @one = AIOModel.new id: 1
      @two = AIOModel.new id: 2
      @three = AIOModel.new id: 3
      @collection.models.concat [@one, @two, @three]
      @collection.remove_objects [@one, @three]
    end

    it 'removes given objects from models' do
      @collection.models.should.equal [@two]
    end
  end

  describe '#find_by_id' do
    before do
      @one = AIOModel.new id: 1
      @two = AIOModel.new id: 2
      @three = AIOModel.new id: 3
      @collection.models.concat [@one, @two, @three]
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
        @collection.models.should.be.empty
      end
    end

    context 'when request returns a response' do
      before do
        @petes_box = TestModel.new id: 1, name: 'petes-box', state: 'running', host: 'petes-box.actionbox.io', port: 12345
        @dans_box = TestModel.new id: 4, name: 'dans-box', state: 'running', host: 'dans-box.actionbox.io', port: 13333
        @collection.add_objects [@petes_box, @dans_box]
        hash = {
          'boxes' => [
            { 'id' => 1, 'name' => 'petes-box2', 'state' => 'stopped', 'host' => 'petes-box2.actionbox.io', 'port' => 10000 },
            { 'id' => 2, 'name' => 'ajs-box',    'state' => 'stopped', 'host' => 'ajs-box.actionbox.io',    'port' => 23456 },
            { 'id' => 3, 'name' => 'aruns-box',  'state' => 'running', 'host' => 'aruns-box.actionbox.io',  'port' => 34567 }
          ]
        }
        response = mock 'response', parsed: hash
        @api.should.receive(:request).with(:get, '/boxes').and_return response
      end

      it 'populates the collection with the fetched items, updating values for pre-existing models' do
        @collection.fetch
        content = @collection.models
        content.size.should.equal 3

        content[0].should.equal @petes_box
        content[0].id.should.equal 1
        content[0].name.should.equal 'petes-box2'
        content[0].state.should.equal 'stopped'
        content[0].host.should.equal 'petes-box2.actionbox.io'
        content[0].port.should.equal 10000

        content[1].should.be.instance_of TestModel
        content[1].id.should.equal 2
        content[1].name.should.equal 'ajs-box'
        content[1].state.should.equal 'stopped'
        content[1].host.should.equal 'ajs-box.actionbox.io'
        content[1].port.should.equal 23456

        content[2].should.be.instance_of TestModel
        content[2].id.should.equal 3
        content[2].name.should.equal 'aruns-box'
        content[2].state.should.equal 'running'
        content[2].host.should.equal 'aruns-box.actionbox.io'
        content[2].port.should.equal 34567

        content.should.not.include @dans_box
      end
    end
  end
end

