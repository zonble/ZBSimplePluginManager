var youtubePlugin = {
  id: 'plugin.bing.search',
  title: 'Search in Bing...',
  action: function (keyword) {
    var url = 'https://bing.com/search?q=' + encodeURIComponent(keyword)
    openURL(url)
  }
}

registerPlugin(youtubePlugin)
