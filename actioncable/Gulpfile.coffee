gulp      = require('gulp')
del       = require('del')
include   = require('gulp-include')
coffee    = require('gulp-coffee')
uglify    = require('gulp-uglify')
rename    = require('gulp-rename')

gulp.task 'clean', ->
  del(['dist/**/*'])

gulp.task 'coffee', ['clean'], ->
  gulp.src('index.coffee')
    .pipe(include())
    .pipe(coffee(bare: true))
    .pipe(uglify())
    .pipe(rename('actioncable.js'))
    .pipe(gulp.dest('dist'))

gulp.task 'default', [
  'coffee'
]
