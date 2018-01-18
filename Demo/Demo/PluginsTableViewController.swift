import UIKit
import ZBSimplePluginManager

class PluginsTableViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Plug-ins"
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	var pluginManager: ZBSimplePluginManager? {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return nil
		}
		return appDelegate.pluginManager
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return pluginManager?.plugins.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
		guard let plugin = pluginManager?.plugins[indexPath.row] else {
			return cell
		}
		cell.textLabel?.text = plugin.title
		cell.accessoryType = plugin.enabled ? .checkmark : .none
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let plugin = pluginManager?.plugins[indexPath.row] else {
			return
		}
		pluginManager?.toggle(plugin: plugin, enabled: !plugin.enabled)
		self.tableView.reloadData()
		tableView.deselectRow(at: indexPath, animated: true)
	}

}
