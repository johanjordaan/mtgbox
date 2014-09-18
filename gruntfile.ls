_ = require 'prelude-ls'
module.exports = (grunt) ->
  grunt.initConfig do
    pkg: grunt.file.readJSON 'package.json'

    uglify:
      options:
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      build:
        src: 'src/<%= pkg.name %>.js'
        dest: 'build/<%= pkg.name %>.min.js'

    deadscript:
      build:
        expand: true,
        cwd: './src',
        src: ['**/*.ls'],
        dest: './site',
        ext: '.js'
        extDot : 'last'

    watch:
      changes:
        files:
           'src/*.ls'
           'src/test/*.ls'
           'src/client/*.ls'
           'src/client/*.html'
           'src/client/*.less'
           'src/client/images/*.png'
        tasks: ['deadscript' 'copy:all' 'less:all' 'mochaTest:test']

    concurrent:
      server:
        tasks: ['watch:changes' 'nodemon:server']
        options:
           logConcurrentOutput: true

    nodemon:
      apiServer:
        script: 'site/server.js'
        options:
           pwd: 'site'

    copy:
      all:
        files: [
         * expand: true
           cwd: 'src/client/'
           src: ['*.html']
           dest: 'site/client/'
         * expand: true
           cwd: 'src/client/images'
           src: ['*.png']
           dest: 'site/client/images'
         * expand: true
           cwd: 'src/client/'
           src: ['libs/**']
           dest: 'site/client/'
        ]

    bowercopy:
      options:
        srcPrefix: 'bower_components'
      scripts:
        options:
          destPrefix: 'site/client/libs'
        files:
          'angular/angular.js': 'angular/angular.min.js'
          'angular/angular-route.js': 'angular-route/angular-route.min.js'
          'angular/angular-resource.js': 'angular-resource/angular-resource.min.js'
          'prelude-browser.js': 'prelude-ls/browser/prelude-browser.js'

          'bootstrap/bootstrap.css': 'bootstrap/dist/css/bootstrap.min.css'
          'bootstrap/bootstrap.js': 'bootstrap/dist/js/bootstrap.min.js'
          'jquery.js': 'jquery/dist/jquery.js'

          # This has been added to avoid the browser error
          #
          'angular/angular.min.js.map': 'angular/angular.min.js.map'
          'angular/angular-route.min.js.map': 'angular-route/angular-route.min.js.map'
          'angular/angular-resource.min.js.map': 'angular-resource/angular-resource.min.js.map'
          'jquery.min.map': 'jquery/dist/jquery.min.map'


    mochaTest:
      test:
        options:
          reporter: 'dot'
        src: ['./site/test/**/*.js']

      coverage:
        options:
          reporter: 'dot'
        src: ['./coverage/instrument/site/test/**/*.js']


    instrument:
      files: 'site/**/*.js'
      options:
        lazy: true
        basePath: './coverage/instrument/'
    storeCoverage:
      options:
        dir: './coverage/reports'
    makeReport:
      src: './coverage/reports/**/*.json',
      options:
        type: 'lcov',
        dir: './coverage/reports',
        print: 'detail'

    less:
      all:
        files: [
          expand: true
          cwd:'src/'
          src: ['**/*.less']
          dest: './site/'
          ext:'.css'
        ]

    jsdoc:
      docstrap:
        src: ['./site/utils.js'] #, './README.md']
        options:
          destination : './site/client/doc/'
          template : "node_modules/ink-docstrap/template"
          configure : "node_modules/ink-docstrap/template/jsdoc.conf.json"

  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-nodemon'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-bowercopy'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-deadscript'
  grunt.loadNpmTasks 'grunt-istanbul'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-jsdoc'



  grunt.registerTask 'apimon',  ['default' 'concurrent:api']
  grunt.registerTask 'default', ['deadscript' 'less:all' 'copy:all' 'bowercopy']

  grunt.registerTask 'docs', ['deadscript' 'jsdoc']

  grunt.registerTask 'coverage', ['deadscript','instrument', 'mochaTest:coverage',
    'storeCoverage', 'makeReport']
