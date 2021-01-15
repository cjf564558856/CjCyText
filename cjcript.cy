(function(exports) {
	var invalidParamStr = 'Invalid parameter';
	var missingParamStr = 'Missing parameter';

	// app id
	CjAppId = [NSBundle mainBundle].bundleIdentifier;

	// mainBundlePath
	CjAppPath = [NSBundle mainBundle].bundlePath;

	// document path
	CjDocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

	// caches path
	CjCachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]; 

	// 加载系统动态库
	CjLoadFramework = function(name) {
		var head = "/System/Library/";
		var foot = "Frameworks/" + name + ".framework";
		var bundle = [NSBundle bundleWithPath:head + foot] || [NSBundle bundleWithPath:head + "Private" + foot];
  		[bundle load];
  		return bundle;
	};

	// keyWindow
	CjKeyWin = function() {
		return UIApp.keyWindow;
	};

	// 根控制器
	CjRootVc =  function() {
		return UIApp.keyWindow.rootViewController;
	};

	// 找到显示在最前面的控制器
	var _CjFrontVc = function(vc) {
		if (vc.presentedViewController) {
        	return _CjFrontVc(vc.presentedViewController);
	    }else if ([vc isKindOfClass:[UITabBarController class]]) {
	        return _CjFrontVc(vc.selectedViewController);
	    } else if ([vc isKindOfClass:[UINavigationController class]]) {
	        return _CjFrontVc(vc.visibleViewController);
	    } else {
	    	var count = vc.childViewControllers.count;
    		for (var i = count - 1; i >= 0; i--) {
    			var childVc = vc.childViewControllers[i];
    			if (childVc && childVc.view.window) {
    				vc = _CjFrontVc(childVc);
    				break;
    			}
    		}
	        return vc;
    	}
	};

	CjFrontVc = function() {
		return _CjFrontVc(UIApp.keyWindow.rootViewController);
	};

	// 递归打印UIViewController view的层级结构
	CjVcSubviews = function(vc) { 
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return vc.view.recursiveDescription().toString(); 
	};

	// 递归打印最上层UIViewController view的层级结构
	CjFrontVcSubViews = function() {
		return CjVcSubviews(_CjFrontVc(UIApp.keyWindow.rootViewController));
	};

	// 获取按钮绑定的所有TouchUpInside事件的方法名
	CjBtnTouchUpEvent = function(btn) { 
		var events = [];
		var allTargets = btn.allTargets().allObjects()
		var count = allTargets.count;
    	for (var i = count - 1; i >= 0; i--) { 
    		if (btn != allTargets[i]) {
    			var e = [btn actionsForTarget:allTargets[i] forControlEvent:UIControlEventTouchUpInside];
    			events.push(e);
    		}
    	}
	   return events;
	};

	// CG函数
	CjPointMake = function(x, y) { 
		return {0 : x, 1 : y}; 
	};

	CjSizeMake = function(w, h) { 
		return {0 : w, 1 : h}; 
	};

	CjRectMake = function(x, y, w, h) { 
		return {0 : CjPointMake(x, y), 1 : CjSizeMake(w, h)}; 
	};

	// 递归打印controller的层级结构
	CjChildVcs = function(vc) {
		if (![vc isKindOfClass:[UIViewController class]]) throw new Error(invalidParamStr);
		return [vc _printHierarchy].toString();
	};

	


	// 递归打印view的层级结构
	CjSubviews = function(view) { 
		if (![view isKindOfClass:[UIView class]]) throw new Error(invalidParamStr);
		return view.recursiveDescription().toString(); 
	};

	// 判断是否为字符串 "str" @"str"
	CjIsString = function(str) {
		return typeof str == 'string' || str instanceof String;
	};

	// 判断是否为数组 []、@[]
	CjIsArray = function(arr) {
		return arr instanceof Array;
	};

	// 判断是否为数字 666 @666
	CjIsNumber = function(num) {
		return typeof num == 'number' || num instanceof Number;
	};

	var _CjClass = function(className) {
		if (!className) throw new Error(missingParamStr);
		if (CjIsString(className)) {
			return NSClassFromString(className);
		} 
		if (!className) throw new Error(invalidParamStr);
		// 对象或者类
		return className.class();
	};

	// 打印所有的子类
	CjSubclasses = function(className, reg) {
		className = _CjClass(className);

		return [c for each (c in ObjectiveC.classes) 
		if (c != className 
			&& class_getSuperclass(c) 
			&& [c isSubclassOfClass:className] 
			&& (!reg || reg.test(c)))
			];
	};

	// 打印所有的方法
	var _CjGetMethods = function(className, reg, clazz) {
		className = _CjClass(className);

		var count = new new Type('I');
		var classObj = clazz ? className.constructor : className;
		var methodList = class_copyMethodList(classObj, count);
		var methodsArray = [];
		var methodNamesArray = [];
		for(var i = 0; i < *count; i++) {
			var method = methodList[i];
			var selector = method_getName(method);
			var name = sel_getName(selector);
			if (reg && !reg.test(name)) continue;
			methodsArray.push({
				selector : selector, 
				type : method_getTypeEncoding(method)
			});
			methodNamesArray.push(name);
		}
		free(methodList);
		return [methodsArray, methodNamesArray];
	};

	var _CjMethods = function(className, reg, clazz) {
		return _CjGetMethods(className, reg, clazz)[0];
	};

	// 打印所有的方法名字
	var _CjMethodNames = function(className, reg, clazz) {
		return _CjGetMethods(className, reg, clazz)[1];
	};

	// 打印所有的对象方法
	CjInstanceMethods = function(className, reg) {
		return _CjMethods(className, reg);
	};

	// 打印所有的对象方法名字
	CjInstanceMethodNames = function(className, reg) {
		return _CjMethodNames(className, reg);
	};

	// 打印所有的类方法
	CjClassMethods = function(className, reg) {
		return _CjMethods(className, reg, true);
	};

	// 打印所有的类方法名字
	CjClassMethodNames = function(className, reg) {
		return _CjMethodNames(className, reg, true);
	};

	// 打印所有的成员变量
	CjIvars = function(obj, reg){ 
		if (!obj) throw new Error(missingParamStr);
		var x = {}; 
		for(var i in *obj) { 
			try { 
				var value = (*obj)[i];
				if (reg && !reg.test(i) && !reg.test(value)) continue;
				x[i] = value; 
			} catch(e){} 
		} 
		return x; 
	};

	// 打印所有的成员变量名字
	CjIvarNames = function(obj, reg) {
		if (!obj) throw new Error(missingParamStr);
		var array = [];
		for(var name in *obj) { 
			if (reg && !reg.test(name)) continue;
			array.push(name);
		}
		return array;
	};
})(exports);