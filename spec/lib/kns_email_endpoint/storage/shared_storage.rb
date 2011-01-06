shared_examples_for "a storage engine" do |storage|

  test_unique_id = "a1235456789"

  describe "CRUD" do
    
    it 'should delete a record' do
      storage.find(test_unique_id)
      if storage.unique_id
        storage.delete.should eql true
      end
    end

    it 'should create a new file' do
      storage.create({
        :unique_id => test_unique_id,
        :message_id => "abcd"
      })

      storage.unique_id.should eql test_unique_id
    end

    it "should find a unique_id" do
      s = storage.find(test_unique_id)
      s.unique_id.should eql test_unique_id
    end

   
    it "should return a valid message_id" do
      storage.message_id.should eql 'abcd'
    end

    it "should increment the retry count" do
      storage.retry_count = 1
      storage.retry_count.should eql 1
    end

    it "should be able to set the state" do
      storage.state = :finished
      storage.state.should eql :finished
    end

    it "should use find_or_create method to create a row" do
      alt_unique_id = 'b123456789'
      s = storage.find_or_create({:unique_id => alt_unique_id, :message_id => 'abcd'})
      s.unique_id.should eql alt_unique_id
    end

    it "should raise an error if unique_id is not provided" do
      lambda {storage.find_or_create({:message_id => ""})}.
        should raise_error
    end

    it "should raise an error if message_id is not provided" do
      lambda {storage.find_or_create({:unique_id => "abc"})}.
        should raise_error
    end

    it "should return nil if not found" do
      s = storage.find('mombojombo')
      s.should be_nil
    end

  end
end
