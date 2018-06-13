function isEqualRect(rect1, rect2) {
    return rect1.x === rect2.x && rect1.y === rect2.y && rect1.width === rect2.width && rect1.height === rect2.height;
}

function leftHalfFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width / 2,
    height: screenFrame.height,
  };
}

function rightHalfFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + (screenFrame.width / 2),
    y: screenFrame.y,
    width: screenFrame.width / 2,
    height: screenFrame.height,
  };
}

function moveToLeft(window, screen) {
  var windowFrame = leftHalfFrame(screen);
  window.setFrame(windowFrame);
}

function moveToRight(window, screen) {
  var windowFrame = rightHalfFrame(screen);
  window.setFrame(windowFrame);
}

function findLeftScreen(screen) {
    var leftScreen = null;
    Screen.all().forEach(function(aScreen) {
        if (aScreen.frame().y === screen.frame().y || aScreen.frame().y + aScreen.frame().height === screen.frame().y + screen.frame().height) {
            if (aScreen.frame().x + aScreen.frame().width === screen.frame().x) {
                leftScreen = aScreen;
            }
        }
    });
    return leftScreen;
}

function findrightScreen(screen) {
    var rightScreen = null;
    Screen.all().forEach(function(aScreen) {
        if (aScreen.frame().y === screen.frame().y || aScreen.frame().y + aScreen.frame().height === screen.frame().y + screen.frame().height) {
            if (aScreen.frame().x === screen.frame().x + screen.frame().width) {
                rightScreen = aScreen;
            }
        }
    });
    return rightScreen;
}

Key.on('up', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();
    window.setFrame(screen.flippedVisibleFrame());
  }
});

Key.on('down', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();
    var screenFrame = screen.flippedVisibleFrame();
    var windowFrame = {
      x: screenFrame.x + screenFrame.width / 4,
      y: screenFrame.y + screenFrame.height / 4,
      width: screenFrame.width / 2,
      height: screenFrame.height / 2,
    };
    window.setFrame(windowFrame);
  }
});

Key.on('left', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();

    if (isEqualRect(window.frame(), leftHalfFrame(screen))) {
        var leftScreen = findLeftScreen(screen);
        if (leftScreen) {
            moveToRight(window, leftScreen);
        }
    } else {
        moveToLeft(window, screen);
    }
  }
});

Key.on('right', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();

    if (isEqualRect(window.frame(), rightHalfFrame(screen))) {
        var rightScreen = findRightScreen(screen);
        if (rightScreen) {
            moveToRight(window, rightScreen);
        }
    } else {
        moveToRight(window, screen);
    }
  }
});
