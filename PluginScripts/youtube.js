var youtubePlugin = {
  id: 'plugin.youtube.search',
  title: 'Search in Youtube...',
  action: function (keyword) {
    var url = 'https://www.youtube.com/results?search_query=' + encodeURIComponent(keyword)
    openURL(url)
  }
}

registerPlugin(youtubePlugin)
