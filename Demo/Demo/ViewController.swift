import UIKit
import ZBSimplePluginManager

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Demo"
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	@IBAction func promptMenu() {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		guard let manager = appDelegate.pluginManager else {
			return
		}

		if manager.enabledPlugins.count == 0 {
			return
		}

		let contoller = UIAlertController(title: "You choice", message: "Select one from the items below.", preferredStyle: UIAlertControllerStyle.actionSheet)

		for plugin in manager.enabledPlugins {
			let action = UIAlertAction(title: plugin.title, style: .default) { action in
				_ = plugin.call(args: ["Nirvana"])
			}
			contoller.addAction(action)
		}
		contoller.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
		})
		self.present(contoller, animated: true, completion: nil)
	}

	@IBAction func managePlugins() {
		self.navigationController?.pushViewController(PluginsTableViewController(), animated: true)
	}

}

