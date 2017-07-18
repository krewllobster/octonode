const fs = require('fs')

const request = (url) => new Promise((resolve, reject) => {
  //get userID from supplied url string
  const lastSlash = url.lastIndexOf('/')
  const userID = url.substring(lastSlash + 1)
  // Load user json data from a file in the subfolder for mock data
  fs.readFile(`../__mockData__/${userID}.json`, 'utf8', (err, data) => {
    if (err) reject(err)
    resolve(JSON.parse(data))
  })
})

module.exports = request
