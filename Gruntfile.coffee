module.exports = (grunt) ->
  # project configuration  
  grunt.initConfig
    clean: 
      build: [
        "cover.html"
        "lib" 
        "lib-cov"
      ]
    coffee:
      compile:
        files: grunt.file.expandMapping(["src/**/*.coffee"], "lib/", {
          rename: (destBase, destPath) ->
            destBase + destPath.replace(/^src\//, "").replace(/\.coffee$/, ".js")
        })
    jscoverage:
      src: "lib"
      dest: "lib-cov"
    mocha:
      options:
        args: [
          "test/"
        ]
      default:
        reporter: "list"
        console: true
      cover: 
        reporter: "html-cov"
        cover: true
        file: "cover.html"

  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadTasks("tasks")

  grunt.registerTask "run:cover", ["coffee", "jscoverage", "mocha:cover", "open-cover"]
  grunt.registerTask "run:test", ["coffee", "mocha:default"]
  grunt.registerTask "default", ["run:test"]
