require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

useSqlCipher = ENV['USE_SQLCIPHER'] ? ENV['USE_SQLCIPHER'] : '0';

Pod::Spec.new do |s|
  s.name         = "react-native-quick-sqlite"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/ospfranco/react-native-quick-sqlite.git", :tag => "#{s.version}" }

  sqliteFlags = ""
  if (useSqlCipher == '1') then
    sqliteFlags = "SQLITE_HAS_CODEC=1 SQLITE_TEMP_STORE=3 SQLCIPHER_CRYPTO_CC SQLITE_SOUNDEX HAVE_USLEEP=1 SQLITE_MAX_VARIABLE_NUMBER=99999 SQLITE_THREADSAFE=1 SQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576 SQLITE_ENABLE_MEMORY_MANAGEMENT=1 SQLITE_ENABLE_LOAD_EXTENSION SQLITE_ENABLE_COLUMN_METADATA SQLITE_ENABLE_UNLOCK_NOTIFY SQLITE_ENABLE_RTREE SQLITE_ENABLE_STAT3 SQLITE_ENABLE_STAT4 SQLITE_ENABLE_JSON1 SQLITE_ENABLE_FTS3_PARENTHESIS SQLITE_ENABLE_FTS4 SQLITE_ENABLE_FTS5 SQLITE_ENABLE_DBSTAT_VTAB NDEBUG=1"
  end

  s.pod_target_xcconfig = {
    :GCC_PREPROCESSOR_DEFINITIONS => ["HAVE_FULLFSYNC=1", "USE_SQLCIPHER=#{useSqlCipher}", "#{sqliteFlags}", "#{ENV['SQLITE_FLAGS']}"],
    :WARNING_CFLAGS => "-Wno-shorten-64-to-32 -Wno-comma -Wno-unreachable-code -Wno-conditional-uninitialized -Wno-deprecated-declarations",
    :USE_HEADERMAP => "No"
  }

  s.source_files = "ios/**/*.{h,hpp,m,mm}", "cpp/**/*.{h,cpp,c}"
  
  s.dependency "React-callinvoker"
  s.dependency "React"
  s.dependency "React-Core"

  if useSqlCipher == '1' then
    s.exclude_files = "cpp/sqlite/*.{h,cpp,c}", "cpp/sqlcipher/android/*.{h,cpp,c}"
    s.frameworks = "Security", "Foundation"
  else
    if ENV['QUICK_SQLITE_USE_PHONE_VERSION'] == '1' then
      s.exclude_files = "cpp/sqlite/*.{h,cpp,c}", "cpp/sqlcipher/**/*.{h,cpp,c}"
      s.library = "sqlite3"
    else
      s.exclude_files = "cpp/sqlcipher/**/*.{h,cpp,c}"
    end
  end
  
end
