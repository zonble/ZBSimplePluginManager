var youtubePlugin = {
  id: 'plugin.google.search',
  title: 'Search in Google...',
  action: function (keyword) {
    var url = 'https://google.com/search?q=' + encodeURIComponent(keyword)
    openURL(url)
  }
}

registerPlugin(youtubePlugin)
