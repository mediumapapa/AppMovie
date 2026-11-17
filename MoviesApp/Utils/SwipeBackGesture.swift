import UIKit

// Las pantallas de Favoritos, Mis listas y Detalle esconden la flecha de regreso del sistema
// (.navigationBarBackButtonHidden) para usar sus propios botones grandes. Al hacerlo, iOS también
// desactiva el gesto de deslizar desde el borde izquierdo para regresar.
// Esta extensión lo vuelve a activar: el gesto funciona siempre que haya una pantalla a la cual regresar.

// @retroactive solo existe desde Swift 6 (Xcode 16); con Xcode 15 se declara sin él
#if compiler(>=6.0)
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {}
#else
extension UINavigationController: UIGestureRecognizerDelegate {}
#endif

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    @objc public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
