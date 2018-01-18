var kkboxPlugin = {
  id: 'plugin.kkbox.search',
  title: 'Search in KKBOX...',
  action: function (keyword) {
    var url = 'https://www.kkbox.com/tw/tc/search.php?word=' + encodeURIComponent(keyword)
    openURL(url)
  }
}

registerPlugin(kkboxPlugin)
