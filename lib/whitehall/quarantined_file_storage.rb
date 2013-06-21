# An alternative CarrierWave storage mechanism for keeping files out of the
# public directory until after they have been virused checked.
#
# This relies on CarrierWave being configured with values for `incoming_root`
# and `clean_root`. `incoming_root` is where new files will be stored for
# virus scanning. `clean_root` is where files will be moved to once they
# have passed virus scan.
#
# The Whitehall app only currently uses this storage mechanism....
#
class Whitehall::QuarantinedFileStorage < CarrierWave::Storage::Abstract
  def store!(file)
    path = ::File.expand_path(uploader.store_path, uploader.incoming_root)
    file.copy_to(path, uploader.permissions)
  end

  # This method *should* return the a `CarrierWave::SanitizedFile` with
  # the full path of the file on the filesystem. But we are doing something
  # slightly different here - it actually returns a path...
  def retrieve!(identifier)
    path = ::File.expand_path(uploader.store_path(identifier), uploader.clean_root)
    CarrierWave::SanitizedFile.new(path)
  end

  CarrierWave::Uploader::Base.add_config :incoming_root
  CarrierWave::Uploader::Base.add_config :clean_root

  CarrierWave.configure do |config|
    config.storage_engines[:quarantined_file] = self.name
  end
end
