module DataHygiene
  class AttachmentExtensionFixer
    attr_reader :attachment_data, :logger

    def self.fix_attachment_data(attachment_data, logger=Logger.new($stderr))
      logger.info("Attempting to fix #{attachment_data.count} attachment(s)")
      attachment_data.each do |ad|
        self.new(ad, logger).fix!
      end
    end

    def initialize(attachment_data, logger)
      @logger = logger
      @attachment_data = attachment_data
    end

    def fix!
      return if attachment_file_missing?

      if attachment_needs_fixing?
        logger.info("AttachmentData (#{attachment_data.id}) replaced #{filename} with #{corrected_filename}")
        AttachmentData.create!(file: corrected_tmp_file, to_replace_id: attachment_data)
        cleanup
      end
    end

    def attachment_needs_fixing?
      if attachment_data.replaced_by
        logger.info("AttachmentData (#{attachment_data.id}) already has a replacement")
        false
      elsif filename == corrected_filename
        logger.info("AttachmentData (#{attachment_data.id}) does not need fixing")
        false
      else
        true
      end
    end

    def attachment_file_missing?
      unless File.exists?(attachment_data.file.path)
        logger.warn("WARNING: File for AttachmentData (#{attachment_data.id}) not found (#{attachment_data.file.path})")
        true
      end
    end

    def corrected_filename
      filename.gsub(/(\.#{extension}\.#{extension})$/, ".#{extension}")
    end

    def corrected_tmp_file
      @corrected_tmp_file ||= clone_and_rename_file
    end

    def clone_and_rename_file
      tmp_filepath = Rails.root.join('tmp', corrected_filename)
      FileUtils.copy(path, tmp_filepath)
      File.open(tmp_filepath)
    end

    def cleanup
      File.delete(corrected_tmp_file.path)
    end

    def extension
      attachment_data.file.path.split('.').last
    end

    def filename
      attachment_data.filename
    end

    def path
      attachment_data.file.path
    end
  end
end
