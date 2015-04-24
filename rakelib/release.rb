def git_directory
  git_dir = File.expand_path "../../.git", __FILE__
  File.directory?(git_dir) && git_dir
end

def revision_file
  File.expand_path "../../.revision", __FILE__
end

def describe_revision
  @description ||= `git describe --tags --abbrev=40 --long`
end

def release_revision
  if git_directory
    if m = describe_revision.match(/^v(\d+\.\d+(\.\d+)?)-(\d+)-g([0-9a-f]+)/)
      patch = m[3] unless m[3] == "0"
      version = [m[1], patch].compact.join(".c")
      return version, m[4]
    end
  end

  if File.exist? revision_file
    return IO.read(revision_file).split
  end

  ["X.Y.Z", default_release_date, "build"]
end

def release_date
  if git_directory
    m = `git show -s --format="%ci" HEAD`.match(/^(\d+-\d+-\d+)/)
    date = m[1]
  end

  date || default_release_date
end

def default_release_date
  Time.now.strftime "%F"
end

def write_release(path)
  version, revision = release_revision

  File.open path, "wb" do |f|
    f.puts %[#define RBX_RUBY_VERSION     "#{Rubinius::BUILD_CONFIG[:ruby_version]}"]
    f.puts %[#define RBX_ENGINE_VERSION   "#{version.split(".")[0, 3].compact.join(".")}"]
    f.puts %[#define RBX_VERSION          "#{version}"]
    f.puts %[#define RBX_LIB_VERSION      "#{version.split(/\./)[0..1].join}"]
    f.puts %[#define RBX_RELEASE_DATE     "#{release_date}"]
    f.puts %[#define RBX_BUILD_REV        "#{revision}"]
  end
end
