class FluQ::DSL::Base

  protected

    def constantize(*path)
      require([:fluq, *path].join('/'))
      names = path.map {|p| p.to_s.split('_').map(&:capitalize).join }
      names.inject(FluQ) {|klass, name| klass.const_get(name) }
    end

end
