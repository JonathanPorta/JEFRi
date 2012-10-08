/*global module:false*/
module.exports = function(grunt) {
	'use strict';
	grunt.initConfig({
		pkg: '<json:package.json>',
		meta: {
			banner: '// <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
				'<%= grunt.template.today("yyyy-mm-dd") %>\n' +
				'<%= pkg.homepage ? "// " + pkg.homepage + "\n" : "" %>' +
				'// Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
				' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %>'
		},
		clean: {
			app: {
				src: ["app/dist", "docs", "app/js", 'test/unit/js']
			}
		},
		docco: {
			app: {
				src: ['**/*.ls', '**/*.js']
			}
		},
		qunit: {
			files: ['test/**/*.html']
		},
		livescript: {
			app: {
				files: {
					'app/js/app.js': 'app/ls/app.ls',
					'app/js/filters.js': 'app/ls/filters/*ls',
					'app/js/services.js': 'app/ls/services/*ls',
					'app/js/directives.js': 'app/ls/directives/*ls',
					'app/js/controllers.js': 'app/ls/controllers/*ls'
				},
				options: {
					bare: false
				}
			},
			dist: {
				files: {
					'app/dist/modeler.js': 'app/dist/modeler.ls'
				}
			},
			test: {
				files: {
					'test/unit/js/unit.js': 'test/unit/**/*.ls',

					'test/e2e/js/spec.js': 'test/e2e/ls/*.ls'
				},
				options: {
					bare: true
				}
			}
		},
		concat: {
			app: {
				src: [
					'app/ls/app.ls',
					'app/ls/**/*ls',
				],
				dest: 'app/dist/modeler.ls'
			},
			unit: {
				src: ['test/unit/js/*'],
				dest: 'test/unit.js'
			},
			e2e: {
				src: ['test/e2e/js/*'],
				dest: 'test/e2e.js'	
			}
		},
		min: {
			dist: {
				src: ['<banner:meta.banner>', 'app/dist/modeler.js'],
				dest: 'app/dist/modeler.min.js'
			}
		},
		watch: {
			app: {
				files: ["app/ls/**", "app/partials/**", "app/index.html", "test/**"],
				tasks: ["default"]
			}
		},
		jshint: {
			options: {
				curly: true,
				eqeqeq: true,
				immed: true,
				latedef: true,
				newcap: true,
				noarg: true,
				sub: true,
				undef: true,
				boss: true,
				eqnull: true
			},
			globals: {
				jQuery:false,
				JEFRi:false,
				UUID: false,
				_:false
			}
		},
		uglify: {}
	});

	grunt.loadNpmTasks('grunt-contrib');
	grunt.loadNpmTasks('grunt-docco');

	grunt.registerTask('app', 'livescript:app concat:app livescript:dist min');
	grunt.registerTask('tests', 'livescript:test concat:unit concat:e2e');
	grunt.registerTask('default', 'clean app tests');
};