require 'fileutils'
require 'logger'
require 'rubygems/package'
#
class Synchronizator

  PATH = {
    :backup => 'C:\Users\Alex\backup',
    :log => 'C:\Users\Alex\log'
  }
  
  LOGGER_OPTIONS = {    
      :level           => 'INFO',
      :datetime_format => '%d-%m-%Y %H:%M:%S',
      :progname       => 'synchronizer'
    }
  
  #
  def initialize(dirs)
    @logger = Logger.new PATH[:log], 5, LOGGER_OPTIONS
    @source, @target = dirs[:source], dirs[:target] # size > 1?
    unless Dir.exist? @source
      @logger.fatal "Source directory \"#{@source}\" does not exist"
      @logger.close
      exit 2
    end
    @time = Time.now
  end

  # Synchronizes all files in target with files from source
  def run    
    if not Dir.exists? @target
      clone_source      
      '0;Source cloned'  
    elsif target_not_changed?
      @logger.info "\"#{@target}\" is up to date. Exiting"
      '0;Target up to date'
    end
    backup_target
    synchronize_files
    synchronize_content
    @logger.info "Job done. Exiting."
    @logger.close
    '0;Synch done'
  end
  
  private
  
    #
    def clone_source
      Dir.mkdir @target
      FileUtils.copy @source, @target
      @logger.info "Cloned \"#{@source}\" to \"#{@target}\""
    end
    
    #
    def target_not_changed?
      Time.new(File.ctime @target) == Time.new(File.ctime @source)
    end
    
    # Creates backup of files in target before executing synchronization
    def backup_target
      Dir.mkdir BACKUPS unless Dir.exist? BACKUPS
      backup_path = PATH[:backup] + '\\' + File.basename @target + @time.strftime '%d-%m-%Y %H:%M:%S'
      files = Dir.entries @target 
      files.map! { |file| File.absolute_path file, @target }
      tar files, backup_path
      Zlib.gzip backup_path + '.tar'
      FileUtils.copy files, backup_path
      @logger.info "Created backup of \"#{@target}\" to #{backup_path}"
    end

    #
    def synchronize_files
      target = Dir.entries @target
      source = Dir.entries @source
      missing = Array.new
      source.each { |file| missing.push file unless target.include? file }
      missing.map! { |file| File.absolute_path file, @source }
      FileUtils.copy missing, @target
      @logger.info "Copied \"#{missing}\" files to \"#{@target}\"."
      excessive = Array.new
      target.each { |file| excessive.push file unless source.include? file }
      excessive.map! { |file| File.absolute_path file, @target }
      FileUtils.remove excessive      
      @logger.info "Removed \"#{excessive}\" files from \"#{@target}\"."
    end
    
    #
    def synchronize_content      
      Dir.foreach @source |file| do
        target_file_path = @target + file
        source_file = File.open file
        target_file = File.open target_file_path
        FileUtils.copy file, @target unless File.identical? source_file, target_file
        source_file.close
        target_file.close
        @logger.info "Overwritten outdated file \"#{target_file_path}\"."
      end        
    end
    
    #
    def tar(files, backup_path)
      tar = File.open backup_path + '.tar', 'w'
      tar = Gem::Package::TarWriter.new tar
      files.each { |file| tar.add_file file }
      tar.close
    end
end

=begin thinking

  enumerable?

=end