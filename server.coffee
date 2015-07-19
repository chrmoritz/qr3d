express = require 'express'
app     = express()

app.use '/static', express.static __dirname + '/static'
app.use require('connect-assets') paths: ['coffee'], fingerprinting: true
app.set 'views', 'views'
app.set 'view engine', 'jade'

app.get /.+\/.*/, (req, res) -> res.redirect '/'
app.get '*', (req, res) -> res.render 'index', dev: true

app.listen process.env.PORT || 3000
