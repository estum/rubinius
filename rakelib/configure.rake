#
# configure.rake - handles all configuration and generate needed build files
#

file 'lib/rbconfig.rb' => :config_env do
  write_rbconfig
end

%w[shotgun/config.mk shotgun/config.h].each do |f|
  file f => :config_env do
    write_config
  end
end

task :configure => %w[shotgun/config.mk lib/rbconfig.rb shotgun/config.h]

task :config_env => %W[rakelib/configure.rake] do
  libtool = system("which glibtool &> /dev/null") ? "glibtool" : "libtool"

  DTRACE              = ENV['DTRACE']
  ENGINE              = "rbx"
  PREFIX              = ENV['PREFIX'] || "/usr/local"
  RBX_RUBY_VERSION    = "1.8.6"
  RBX_RUBY_PATCHLEVEL = "111"
  LIBVER              = "0.8"
  RBX_VERSION         = "#{LIBVER}.0"
  HOST                = `./shotgun/config.guess`.chomp
  BUILDREV            = `git rev-list --all | head -n1`.chomp
  CC                  = ENV['CC'] || 'gcc'
  LIBTOOL             = libtool
  BINPATH             = "#{PREFIX}/bin"
  LIBPATH             = "#{PREFIX}/lib"
  CODEPATH            = "#{PREFIX}/lib/rubinius/#{LIBVER}"
  RBAPATH             = "#{PREFIX}/lib/rubinius/#{LIBVER}/runtime"
  EXTPATH             = "#{PREFIX}/lib/rubinius/#{LIBVER}/#{HOST}"

  case HOST
  when /darwin9/ then
    DARWIN         = 1
    DISABLE_KQUEUE = 1
  when /darwin/ then
    DARWIN         = 1
    DISABLE_KQUEUE = 1
  else
    DARWIN         = 0
    DISABLE_KQUEUE = (HOST =~ /freebsd/ ? 1 : 0)
  end
end

def write_config
  Dir.chdir(File.join(RUBINIUS_BASE, 'shotgun')) do
    File.open("config.mk", "w") do |f|
      f.puts "BUILDREV        = #{BUILDREV}"
      f.puts "ENGINE          = #{ENGINE}"
      f.puts "PREFIX          = #{PREFIX}"
      f.puts "RUBY_VERSION    = #{RBX_RUBY_VERSION}"
      f.puts "RUBY_PATCHLEVEL = #{RBX_RUBY_PATCHLEVEL}"
      f.puts "LIBVER          = #{LIBVER}"
      f.puts "VERSION         = #{RBX_VERSION}"
      f.puts "HOST            = #{HOST}"
      f.puts "LIBTOOL         = #{LIBTOOL}"
      f.puts "DARWIN          = #{DARWIN}"
      f.puts "DISABLE_KQUEUE  = #{DISABLE_KQUEUE}"
      f.puts "BINPATH         = #{BINPATH}"
      f.puts "LIBPATH         = #{LIBPATH}"
      f.puts "CODEPATH        = #{CODEPATH}"
      f.puts "RBAPATH         = #{RBAPATH}"
      f.puts "EXTPATH         = #{EXTPATH}"
      f.puts "BUILDREV        = #{BUILDREV}"
      f.puts "DTRACE          = #{DTRACE}"

      case HOST
      when /darwin9/ then
        f.puts "MACOSX_DEPLOYMENT_TARGET=10.5"
      when /darwin/ then
        f.puts "MACOSX_DEPLOYMENT_TARGET=10.4"
      end
    end

    unix_date = Time.now.strftime("%m/%d/%Y")

    File.open("config.h", "w") do |f|
      f.puts "#define CONFIG_DARWIN           #{DARWIN.to_s.inspect}"
      f.puts "#define CONFIG_DISABLE_KQUEUE   #{DISABLE_KQUEUE}"
      f.puts "#define CONFIG_HOST             #{HOST.inspect}"
      f.puts "#define CONFIG_PREFIX           #{PREFIX.inspect}"
      f.puts "#define CONFIG_VERSION          #{RBX_VERSION.inspect}"
      f.puts "#define CONFIG_RUBY_VERSION     #{RBX_RUBY_VERSION.inspect}"
      f.puts "#define CONFIG_RELDATE          #{unix_date.inspect}"
      f.puts "#define CONFIG_RUBY_PATCHLEVEL  #{RBX_RUBY_PATCHLEVEL.inspect}"
      f.puts "#define CONFIG_CODEPATH         #{CODEPATH.inspect}"
      f.puts "#define CONFIG_RBAPATH          #{RBAPATH.inspect}"
      f.puts "#define CONFIG_EXTPATH          #{EXTPATH.inspect}"
      f.puts "#define CONFIG_BUILDREV         #{BUILDREV.inspect}"
      f.puts "#define CONFIG_ENGINE           #{ENGINE.inspect}"
      f.puts "#define CONFIG_CC               #{CC.inspect}"

      if DTRACE then
        f.puts "#define CONFIG_ENABLE_DTRACE 1"
      end

      if system "config/run is64bit &> /dev/null" then
        f.puts "#define CONFIG_WORDSIZE 64"
        f.puts "#define CONFIG_ENABLE_DT 0"
      else
        f.puts "#define CONFIG_WORDSIZE 32"
        f.puts "#define CONFIG_ENABLE_DT 1"
      end

      if system "config/run isbigendian &> /dev/null" then
        f.puts "#define CONFIG_BIG_ENDIAN 1"
      else
        f.puts "#define CONFIG_BIG_ENDIAN 0"
      end
    end
  end
end

def write_rbconfig
  File.open 'lib/rbconfig.rb', 'w' do |f|
    f.puts "#--"
    f.puts "# This file was generated by the rubinius' rakelib/configure.rake."
    f.puts "#++"
    f.puts
    f.puts "module Config"
    f.puts "  prefix = File.dirname(File.dirname(__FILE__))"
    f.puts
    f.puts "  CONFIG = {}"
    f.puts
    f.puts "  CONFIG['PREFIX']            = prefix"
    f.puts "  CONFIG['DLEXT']             = Rubinius::LIBSUFFIX.dup"
    f.puts "  CONFIG['EXEEXT']            = ''"
    f.puts "  CONFIG['RUBY_SO_NAME']      = \"rubinius-#\{Rubinius::RBX_VERSION}\""
    f.puts "  CONFIG['arch']              = RUBY_PLATFORM.dup"
    f.puts "  CONFIG['bindir']            = File.join(prefix, 'bin')"
    f.puts "  CONFIG['datadir']           = File.join(prefix, 'share')"
    f.puts "  CONFIG['libdir']            = File.join(prefix, 'lib')"
    f.puts "  CONFIG['ruby_install_name'] = '#{ENGINE}'"
    f.puts "  CONFIG['ruby_version']      = '#{RBX_RUBY_VERSION}'"
    f.puts "  CONFIG['sitedir']           = '#{File.join LIBPATH, 'rubinius'}'"
    f.puts "  CONFIG['sitelibdir']        = '#{CODEPATH}'"
    f.puts "  CONFIG['wordsize']          = Rubinius::WORDSIZE"

    f.puts "  CONFIG['rubyhdrdir']        = File.join(prefix,'shotgun/lib/subtend')"

    f.puts "end"
    f.puts
    f.puts "RbConfig = Config"
  end
end
