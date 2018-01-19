# ZBSimplePluginManager

A simple plug-in system by using JavaScriptCore.

Copyright (c) 2018 Weizhong Yang a.k.a zonble

## Introduction

A plug-in system helps to make your app more flexible.

Users may not need all of the functions in your app, and you may want to update the implementation of a function anytime. If you make these functions as plug-ins, users can enable or disable them when they need them or not, and you can let users to download new plug-ins if you hope so.

Apple introduced JavaScriptCore framework, a JavaScript interpreter, in iOS 7. It is a great tool and we could leverage it to build a simple plug-in system in your app easily. It is also quite easy to write new plug-ins, since they are just simple JavaScript code.

## Usage

Please create an instance of *ZBSimplePluginManager* by giving the folder where your plug-in files are, and a namespace for storing plug-in settings. A namespace here is a key that is used in NSUserDefaults to manage how a plug-in is enabled or disabled.

Then, ask the manager to load all of the plug-ins in th given folder.

``` swift
let resourceURL = URL(fileURLWithPath: Bundle.main.resourcePath!)
let pluginFolder = resourceURL.appendingPathComponent("PluginScripts")
let pluginManager = ZBSimplePluginManager(pluginFolderURL: pluginFolder, defaultsNameSpace: "plugins")
pluginManager?.loadAllPlugins()
```

Once the plug-ins are loaded, you can obtain a list of plug-ins from the manager.

``` swift
let plugins = pluginManager.plugins
```

A plug-in that we defined in *ZBSimplePluginManager* has an identifier, a name and an action. You can call the action of a plug-in by passing specific parameters.

```
let plugins = pluginManager.plugins
Let plugin = plugins[0]
_ = plugin.call(args: ["Hello World!"])
```

## Plug-in Files

A plug-in may looks like:

``` js
var youtubePlugin = {
  id: 'plugin.google.search',
  title: 'Search in Google...',
  action: function (keyword) {
    var url = 'https://google.com/search?q=' + encodeURIComponent(keyword)
    openURL(url)
  }
}

registerPlugin(youtubePlugin)
```

What the plug-in does is:

* Creating a JavaScript object with attributes including id, title, and action.
* Call `registerPlugin` by passing the object to register it.

If there is already a plug-in registered with the same ID, you cannot register the plug-in.

## JavaScript APIs

*ZBSimplePluginManager* has only a few APIs that you can call from your JavaScript code right now, but it is also easy to extend the APIs.

* `registerPlugin`: Register a new plug-in.
* `log`: Print debug messages.
* `openURL`: Open a given URL.

*ZBSimplePluginManager* also provides a simple shared key/value storage in memory. You can use following functions to access it.

* `set`: Set a value to the shared storage by giving a key.
* `get`: Get a value by giving a key.

You can add your own functions to be called by your JavaScript code by simply calling `addJavaScriptAPI(functionName:, block:)`. For example, if you want to replace the existing `log` function, you can do this in your code:

``` swift
try? self.addJavaScriptAPI(functionName: "log") { log in
  if let log = log as? String {
    print("[My Log]" + log)
  }
  return nil
}
```

The body of your custom function is a Swift closure that has a simple input value and returns a value. Type of both of input and output value is optional any (written in "Any?"). You can cast the value by your self to satisfy your needs. By the way, you cannot replace the 'registerPlugin' function, otherwise we cannot register plug-ins.

Enjoy!
