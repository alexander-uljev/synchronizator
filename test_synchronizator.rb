require_relative 'synchronizator'
require 'unit/test'

class TestSynchronizator
  
  SOURCE = 'C:/Users/Alex/source'
  TARGET = 'C:/Users/Alex/target'
  NOT_EXIST = 'nowhere'
  Dir.mkdir SOURCE unless Dir.exist? SOURCE
  5.times |num| do
    name = SOURCE + '\\' + 'file' + num
    File.new name, File::CREAT
  end
  @synch = Synchronizator.new SOURCE, TARGET
  
  def test_source_not_exist
    assert_raise(RuntimeError) { Synchronizator.new NOT_EXIST, TARGET }
  end
  
  def test_target_not_exist
    FileUtils.remove_dir TARGET    
    assert_equal synch.run, '0;Source cloned'
  end
  
  def test_target_not_changed
    assert_equal synch.run, '0;Target up to date'
  end
  
  def test_synch
    3.upto 5 { |num| FileUtils.remove_file TARGET + '\\' + 'file' + num }
    6.upto 8 { |num| File.new TARGET + '\\' + 'file' + num, File::CREAT }
    assert_equal synch.run, '0;Synch done'
    Dir.foreach('C:\\Users\\Alex\\log\\')  { |file| puts file.readlines }
  end
end