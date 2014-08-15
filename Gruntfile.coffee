module.exports = (grunt)->
    grunt.initConfig
        coffee:
            compile:
                expand: true
                cwd: 'src'
                dest: 'script'
                src: '*.coffee'
                ext: '.js'
        less:
            compile:
                expand: true
                cwd: 'src'
                dest: 'style'
                src: '*.less'
                ext: '.css'
        jade:
            compile:
                expand: true
                cwd: 'src'
                dest: 'template'
                src: '*.jade'
                ext: '.html'
        watch:
            script:
                files: ['src/*.coffee']
                tasks: 'coffee'
            style:
                files: ['src/*.less']
                tasks: 'less'
            html:
                files: ['src/*.jade']
                tasks: 'jade'
    
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.registerTask 'default', ['coffee', 'less', 'jade']