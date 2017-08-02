/**
 * Created by max.rozdobudko@gmail.com on 7/22/17.
 */
package feathersx.mvvc {
import feathers.controls.AutoSizeMode;
import feathers.controls.LayoutGroup;
import feathers.controls.StackScreenNavigator;
import feathers.events.FeathersEventType;
import feathers.layout.AnchorLayout;
import feathers.layout.AnchorLayoutData;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import feathers.motion.Fade;

import feathersx.motion.Slide;

import starling.animation.Transitions;

import starling.display.DisplayObject;
import starling.display.Quad;
import starling.events.Event;

public class NavigationController extends ViewController {

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function NavigationController(rootViewController:ViewController) {
        super();
        setViewControllers(new <ViewController>[rootViewController], false);
    }

    //--------------------------------------------------------------------------
    //
    //  View
    //
    //--------------------------------------------------------------------------

    override public function get isViewLoaded(): Boolean {
        return _navigator != null; // TODO(dev) if (isViewLoaded) { after loadView signature is changed
    }

    //--------------------------------------------------------------------------
    //
    //  Transition
    //
    //--------------------------------------------------------------------------

    protected function getPushTransition(animated:Boolean):Function {
        var onProgress:Function = function (progress:Number) {
            trace("onProgress: " + progress);
        };
        var onComplete:Function = function () {
            trace("onComplete");
        };

        return Slide.createSlideLeftTransition(0.5, Transitions.EASE_OUT, null, onProgress, onComplete);
    }

    protected function getPopTransition(animated:Boolean):Function {
        var onProgress:Function = function (progress:Number) {
            trace("onProgress: " + progress);
        };
        var onComplete:Function = function () {
            trace("onComplete");
        };

        return Slide.createSlideRightTransition(0.5, Transitions.EASE_OUT, null, onProgress, onComplete);
    }

    private function getReplaceTransition(animated: Boolean): Function {
        return Fade.createFadeInTransition();
    }

    //--------------------------------------------------------------------------
    //
    //  Push & Pop stack items
    //
    //--------------------------------------------------------------------------

    override public function show(vc: ViewController, sender: Object = null): void {
        pushViewController(vc, true);
    }

    public function pushViewController(vc:ViewController, animated:Boolean):void {
        navigatorAddScreenWithViewController(vc);

        navigator.pushScreen(vc.identifier, null, getPushTransition(animated));

        _navigationBar.pushItem(vc.navigationItem, animated);

        _viewControllers.push(vc);
    }

    public function popViewController(animated:Boolean):ViewController {
        var navigator:StackScreenNavigator = this._navigator as StackScreenNavigator;
        var transition:Function = getPopTransition(animated);
        var view:DisplayObject = navigator.popScreen(transition);

        _navigationBar.popItem(animated);

        return _viewControllers.pop();
    }

    public function popToRootViewController(animated:Boolean):Vector.<ViewController> {
        return null;
    }

    public function popToViewController(viewController:ViewController, animated:Boolean):Vector.<ViewController> {
        return null;
    }

    override public function replaceWithViewController(vc: ViewController, animated: Boolean, completion: Function = null): void {
        navigatorAddScreenWithViewController(vc);
        navigator.replaceScreen(vc.identifier, getReplaceTransition(animated));
        navigator.addEventListener(FeathersEventType.TRANSITION_COMPLETE, function (event:Event):void {
            navigator.removeEventListener(FeathersEventType.TRANSITION_COMPLETE, arguments.callee);
            if (completion != null) {
                completion();
            }
        });
    }

    //--------------------------------------------------------------------------
    //
    //  Navigation Stack
    //
    //--------------------------------------------------------------------------

    private var _viewControllers: Vector.<ViewController> = new <ViewController>[];

    public function get topViewController(): ViewController {
        if (_viewControllers.length > 0) {
            return _viewControllers[_viewControllers.length - 1];
        }
        return null;
    }

    public function get viewControllers(): Vector.<ViewController> {
        return _viewControllers;
    }

    public function setViewControllers(viewControllers: Vector.<ViewController>, animated: Boolean): void {
        if (isViewLoaded) {

            if (viewControllers.length > 0 && navigator.activeScreenID != null) {
                var newTopViewController: ViewController = viewControllers[viewControllers.length - 1];
                replaceWithViewController(newTopViewController, animated, function () {
                    setViewControllersInternal(viewControllers);
                });
            } else {
                setViewControllersInternal(viewControllers);
            }

            _navigationBar.setItems(navigationItemsFromViewControllers(_viewControllers), animated);

        } else {
            _viewControllers = viewControllers;
        }
    }

    private function setViewControllersInternal(viewControllers: Vector.<ViewController>): void {
        for each (var oldViewController:ViewController in _viewControllers) {
            if (viewControllers.indexOf(oldViewController) != -1) {
                continue;
            }
            navigatorRemoveScreenWithViewController(oldViewController);
        }
        for each (var newViewController:ViewController in viewControllers) {
            if (navigator.hasScreen(newViewController.identifier)) {
                continue;
            }
            navigatorAddScreenWithViewController(newViewController);
        }

        _viewControllers = viewControllers;

        if (viewControllers.length > 0) {
            var newRootViewController: ViewController = viewControllers[0];
            navigator.rootScreenID = newRootViewController.identifier;
        }
    }

    private function navigatorAddScreenWithViewController(vc: ViewController): void {
        if (navigator.hasScreen(vc.identifier)) {
            navigator.removeScreen(vc.identifier);
        }
        navigator.addScreen(vc.identifier, new ViewControllerNavigatorItem(vc));
        vc.setNavigationController(this);
    }

    private function navigatorRemoveScreenWithViewController(vc: ViewController): void {
        if (navigator.hasScreen(vc.identifier)) {
            navigator.removeScreen(vc.identifier);
        }
        vc.setNavigationController(null);
    }

    //--------------------------------------------------------------------------
    //
    //  Stack Navigator
    //
    //--------------------------------------------------------------------------

    override protected function loadView(): DisplayObject {
        var view:LayoutGroup = new LayoutGroup();
        view.autoSizeMode = AutoSizeMode.STAGE;
        view.layout = new AnchorLayout();

        _navigator = new StackScreenNavigator();
        _navigator.layoutData = new AnchorLayoutData(0, 0, 0, 0);
        view.addChild(_navigator);

        _navigationBar = new NavigationBar();
        _navigationBar.layoutData = new AnchorLayoutData(0, 0, NaN, 0);
        _navigationBar.onBack = navigationBarOnBack;
        _navigationBar.height = 60;
        view.addChild(_navigationBar);

        _toolbar = new Toolbar();
        _toolbar.layoutData = new AnchorLayoutData(NaN, 0, 0, 0);
        _toolbar.height = 40;
        view.addChild(_toolbar);

        setViewControllers(_viewControllers, false);

        return view;
    }

    private var _navigator:StackScreenNavigator;
    public function get navigator(): StackScreenNavigator {
        // TODO(dev) each nc has its own navigator
        if (presentingViewController is NavigationController) {
            return NavigationController(presentingViewController).navigator;
        } else {
            return _navigator;
        }
    }

    //--------------------------------------------------------------------------
    //
    //  NavigatorBar
    //
    //--------------------------------------------------------------------------

    private var _navigationBar:NavigationBar;
    public function get navigationBar(): NavigationBar {
        if (presentingViewController is NavigationController) {
            return NavigationController(presentingViewController).navigationBar;
        } else {
            return _navigationBar;
        }
    }

    private var _toolbar:Toolbar;
    public function get toolbar(): Toolbar {
        if (presentingViewController is NavigationController) {
            return NavigationController(presentingViewController).toolbar;
        } else {
            return _toolbar;
        }
    }

    private function navigationBarOnBack(): void {
        popViewController(true);
    }

    private function navigationItemsFromViewControllers(veiwControllers: Vector.<ViewController>): Vector.<NavigationItem> {
        var items: Vector.<NavigationItem> = new <NavigationItem>[];
        veiwControllers.forEach(function (vc: ViewController, index: int, vector:*):void {
            items[items.length] = vc.navigationItem;
        });
        return items;
    }

    //--------------------------------------------------------------------------
    //
    //  Toolbar
    //
    //--------------------------------------------------------------------------

    public function set toolbar(value: Toolbar): void {
        _toolbar = value;
    }

    //--------------------------------------------------------------------------
    //
    //  Root
    //
    //--------------------------------------------------------------------------

    override protected function setupRootView(): void {
        if (_root == null) {
            throw new Error("[mvvc] root must be set.");
        }
        _root.addChild(this.view);
    }
}
}

//--------------------------------------------------------------------------
//
//  ViewControllerNavigatorItem
//
//--------------------------------------------------------------------------

import feathers.controls.StackScreenNavigatorItem;

import feathersx.mvvc.ViewController;

import starling.display.DisplayObject;

class ViewControllerNavigatorItem extends StackScreenNavigatorItem {
    public function ViewControllerNavigatorItem(vc: ViewController): void {
        super();
        _viewController = vc;
    }

    private var _viewController: ViewController;

    override public function get canDispose(): Boolean {
        return false;
    }

    override public function getScreen(): DisplayObject {
        return _viewController.view;
    }
}