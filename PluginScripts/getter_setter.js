var kkboxPlugin = {
  id: 'plugin.getter_setter',
  title: 'Getter/Setter',
  action: function (keyword) {
    var key = 'artist'
    set(key, keyword)
    var result = get(key)
    log(result)
  }
}

registerPlugin(kkboxPlugin)
