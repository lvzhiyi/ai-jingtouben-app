import Flutter
import UIKit

/// 从所属引擎的 registrar 获取 presenter，避免跨 scene 选择错误的窗口。
final class ShareHandler: ShareHostApi {
  private let registrar: FlutterPluginRegistrar

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  func shareText(title: String, text: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard Thread.isMainThread,
          let presenter = registrar.viewController,
          presenter.viewIfLoaded?.window != nil,
          presenter.presentedViewController == nil else {
      completion(.failure(PigeonError(code: "share_unavailable", message: "Share sheet unavailable", details: nil)))
      return
    }
    let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    sheet.setValue(title, forKey: "subject")
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.safeAreaInsets.top, width: 1, height: 1)
      popover.permittedArrowDirections = []
    }
    presenter.present(sheet, animated: true) {
      // 仅确认展示；取消或关闭面板均不宣称分享成功。
      completion(.success(()))
    }
  }
}
