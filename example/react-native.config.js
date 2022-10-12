module.exports = {
    dependencies: {
      'react-native-quick-sqlite': {
        platforms: {
          android: {
            sourceDir: "../../android",
            packageImportPath: "import com.reactnativequicksqlite.SequelPackage;",
            packageInstance: "new SequelPackage()"
          },
        },
      },
    },
  };