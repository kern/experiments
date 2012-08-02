require "fileutils"
require "transmission-simple"

class TransmissionExtractor
  FIELDS = ["name", "uploadRatio", "downloadDir", "trackers", "files", "torrentFile", "sizeWhenDone"]
  TRACKERS = [/what\.cd/, /bitme\.org/, /brokenstones\.me/]

  attr_reader :size

  def initialize(options)
    endpoint = options.fetch(:endpoint)
    @api = TransmissionSimple::Api.new(endpoint)
    @torrents_directory = options.fetch(:torrents_directory)
    @files_directory = options.fetch(:files_directory)
    @minimum_ratio = options.fetch(:minimum_ratio)
    @size = nil
  end

  def run
    create_directories!
    retrieve_torrents!
    filter_torrents!
    calculate_size!
    extract_torrents!
    extract_files!
  end

  private

  def create_directories!
    [@torrents_directory, @files_directory].each do |directory|
      FileUtils.mkdir_p(directory)
    end
  end

  def retrieve_torrents!
    @torrents = @api.torrent_get(fields: FIELDS)
  end

  def filter_torrents!
    @torrents.delete_if { |torrent| torrent.upload_ratio < @minimum_ratio }
    @torrents.delete_if do |torrent|
      torrent.trackers.all? do |tracker|
        TRACKERS.none? do |allowed_tracker|
          allowed_tracker =~ tracker.announce
        end
      end
    end
  end

  def calculate_size!
    @size = @torrents.inject(0) { |sum, torrent| sum + torrent.size_when_done }
  end

  def extract_torrents!
    @torrents.each do |torrent|
      puts "Moving torrent #{torrent.name}."
      FileUtils.cp(torrent.torrent_file, @torrents_directory)
    end
  end

  def extract_files!
    @torrents.each do |torrent|
      torrent.files.each do |file|
        name = file.name
        directory = File.dirname(name)
        FileUtils.mkdir_p(File.join(@files_directory, directory))

        old_path = File.join(torrent.download_dir, name)
        new_path = File.join(@files_directory, name)

        puts "Moving file #{name}."
        FileUtils.cp(old_path, new_path)
      end
    end
  end
end

extractor = TransmissionExtractor.new(
  endpoint: "http://localhost:9091/transmission/rpc",
  torrents_directory: "/Users/alex/Desktop/torrents",
  files_directory: "/Users/alex/Desktop/files",
  minimum_ratio: 1
)

extractor.run
