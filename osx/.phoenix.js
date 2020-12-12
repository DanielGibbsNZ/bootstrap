function isEqualish(a, b) {
    // A leniency of 1px is fine for most apps, but Terminal doesn't extend to the bottom of the screen so 10px is needed.
    return Math.abs(a - b) <= 10;
}

function isEqualRect(rect1, rect2) {
  return isEqualish(rect1.x, rect2.x) && isEqualish(rect1.y, rect2.y) && isEqualish(rect1.width, rect2.width) && isEqualish(rect1.height, rect2.height);
}

function stringFromRect(rect) {
  return `${rect.x},${rect.y},${rect.width},${rect.height}`
}

// Frames.

var FULL_SCREEN = function(screen) {
  return screen.flippedVisibleFrame();
};

var CENTRE_SCREEN = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + screenFrame.width / 4,
    y: screenFrame.y + screenFrame.height / 4,
    width: screenFrame.width / 2,
    height: screenFrame.height / 2,
  };
};

var LEFT_HALF = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width / 2,
    height: screenFrame.height,
  };
};

var RIGHT_HALF = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + (screenFrame.width / 2),
    y: screenFrame.y,
    width: screenFrame.width / 2,
    height: screenFrame.height,
  };
};

var LEFT_THIRD = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width / 3,
    height: screenFrame.height,
  };
};

var LEFT_TWO_THIRDS = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width - (screenFrame.width / 3),
    height: screenFrame.height,
  };
};

var RIGHT_THIRD = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + screenFrame.width - (screenFrame.width / 3),
    y: screenFrame.y,
    width: screenFrame.width / 3,
    height: screenFrame.height,
  };
};

var RIGHT_TWO_THIRDS = function(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + (screenFrame.width / 3),
    y: screenFrame.y,
    width: screenFrame.width - (screenFrame.width / 3),
    height: screenFrame.height,
  };
};

// Window checking and moving.

function windowIs(window, frameFunc) {
  var screen = window.screen();
  var frame = frameFunc(screen);
  return isEqualRect(window.frame(), frame);
}

function moveWindow(window, screen, frameFunc) {
  var frame = frameFunc(screen);
  window.setFrame(frame);
}

// Screen locating.

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

function findRightScreen(screen) {
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

// Modals.

function showModal(text) {
  var window = Window.focused();
  if (window) {
    var screen = window.screen();
    var screenFrame = screen.frame();
    var modal = Modal.build({
      origin: function(frame) {
        return {
          x: screenFrame.x + (screenFrame.width / 2) - (frame.width / 2),
          y: screenFrame.y + (screenFrame.height / 2) - (frame.height / 2)
        };
      },
      duration: 0.5,
      text: text,
      appearance: 'dark'
    });
    modal.show();
  }
}

// Key listeners.

Key.on('up', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();
    moveWindow(window, screen, FULL_SCREEN);
  }
});

Key.on('down', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var screen = window.screen();
    moveWindow(window, screen, CENTRE_SCREEN);
  }
});

Key.on('left', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var thirdsMode = Storage.get('thirdsMode') || false;
    var screen = window.screen();

    if (thirdsMode) {
      if (windowIs(window, FULL_SCREEN)) {
        moveWindow(window, screen, LEFT_TWO_THIRDS);
      } else if (windowIs(window, LEFT_THIRD)) {
        var leftScreen = findLeftScreen(screen);
        if (leftScreen) {
          moveWindow(window, leftScreen, RIGHT_THIRD);
        }
      } else if (windowIs(window, LEFT_TWO_THIRDS) || windowIs(window, LEFT_HALF)) {
        moveWindow(window, screen, LEFT_THIRD);
      } else if (windowIs(window, RIGHT_THIRD)) {
        moveWindow(window, screen, RIGHT_TWO_THIRDS);
      } else if (windowIs(window, RIGHT_TWO_THIRDS)) {
        moveWindow(window, screen, FULL_SCREEN);
      } else {
        moveWindow(window, screen, LEFT_TWO_THIRDS);
      }
    } else {
      if (windowIs(window, LEFT_HALF)) {
        var leftScreen = findLeftScreen(screen);
        if (leftScreen) {
          moveWindow(window, leftScreen, RIGHT_HALF);
        }
      } else {
        moveWindow(window, screen, LEFT_HALF);
      }
    }
  }
});

Key.on('right', [ 'ctrl', 'alt' ], function () {
  var window = Window.focused();

  if (window) {
    var thirdsMode = Storage.get('thirdsMode') || false;
    var screen = window.screen();

    if (thirdsMode) {
      if (windowIs(window, FULL_SCREEN)) {
        moveWindow(window, screen, RIGHT_TWO_THIRDS);
      } else if (windowIs(window, RIGHT_THIRD)) {
        var rightScreen = findRightScreen(screen);
        if (rightScreen) {
          moveWindow(window, rightScreen, LEFT_THIRD);
        }
      } else if (windowIs(window, RIGHT_TWO_THIRDS) || windowIs(window, RIGHT_HALF)) {
        moveWindow(window, screen, RIGHT_THIRD);
      } else if (windowIs(window, LEFT_THIRD)) {
        moveWindow(window, screen, LEFT_TWO_THIRDS);
      } else if (windowIs(window, LEFT_TWO_THIRDS)) {
        moveWindow(window, screen, FULL_SCREEN);
      } else {
        moveWindow(window, screen, RIGHT_TWO_THIRDS);
      }
    } else {
      if (windowIs(window, RIGHT_HALF)) {
        var rightScreen = findRightScreen(screen);
        if (rightScreen) {
          moveWindow(window, rightScreen, LEFT_HALF);
        }
      } else {
        moveWindow(window, screen, RIGHT_HALF);
      }
    }
  }
});

Key.on('/', [ 'ctrl', 'alt' ], function () {
  var thirdsMode = Storage.get('thirdsMode') || false;
  thirdsMode = !thirdsMode;
  Storage.set('thirdsMode', thirdsMode);
  showModal(thirdsMode ? 'Thirds' : 'Halves');
});
