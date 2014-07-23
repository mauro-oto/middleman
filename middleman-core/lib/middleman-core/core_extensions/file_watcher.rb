require 'middleman-core/contracts'
require 'middleman-core/sources'

module Middleman
  module CoreExtensions
    # API for watching file change events
    class FileWatcher < Extension
      # All defined sources.
      Contract None => IsA['Middleman::Sources']
      attr_reader :sources

      # The default list of ignores.
      IGNORES = {
        emacs_files: /(^|\/)\.?#/,
        tilde_files: /~$/,
        ds_store: /\.DS_Store$/,
        git: /(^|\/)\.git(ignore|modules|\/)/
      }

      # Setup the extension.
      def initialize(app, config={}, &block)
        super

        # Setup source collection.
        @sources = ::Middleman::Sources.new(app,
                                            disable_watcher: app.config[:watcher_disable],
                                            force_polling: app.config[:force_polling],
                                            latency: app.config[:watcher_latency])

        # Add default ignores.
        IGNORES.each do |key, value|
          @sources.ignore key, :all, value
        end

        # Watch current source.
        start_watching(app.config[:source])

        # Expose API to app and config.
        app.add_to_instance(:files, &method(:sources))
        app.add_to_config_context(:files, &method(:sources))
      end

      # Before we config, find initial files.
      #
      # @return [void]
      Contract None => Any
      def before_configuration
        @sources.find_new_files!
      end

      # After we config, find new files since config can change paths.
      #
      # @return [void]
      Contract None => Any
      def after_configuration
        if @original_source_dir != app.config[:source]
          @watcher.update_path(app.config[:source])
        end

        @sources.start!
        @sources.find_new_files!
      end

      protected

      # Watch the source directory.
      #
      # @return [void]
      Contract String => Any
      def start_watching(dir)
        @original_source_dir = dir
        @watcher = @sources.watch :source, path: File.join(app.root, dir)
      end
    end
  end
end
