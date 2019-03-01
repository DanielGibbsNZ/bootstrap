function isEqualRect(rect1, rect2) {
    return rect1.x === rect2.x && rect1.y === rect2.y && rect1.width === rect2.width && rect1.height === rect2.height;
}

// Full screen.

function fullFrame(screen) {
  return screen.flippedVisibleFrame();
}

function moveToFull(window, screen) {
  var windowFrame = fullFrame(screen);
  window.setFrame(windowFrame);
}

// Halves.

function leftHalfFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width / 2,
    height: screenFrame.height,
  };
}

function moveToLeftHalf(window, screen) {
  var windowFrame = leftHalfFrame(screen);
  window.setFrame(windowFrame);
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

function moveToRightHalf(window, screen) {
  var windowFrame = rightHalfFrame(screen);
  window.setFrame(windowFrame);
}

// Thirds.

function leftThirdFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width / 3,
    height: screenFrame.height,
  };
}

function moveToLeftThird(window, screen) {
  var windowFrame = leftThirdFrame(screen);
  window.setFrame(windowFrame);
}

function leftTwoThirdsFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x,
    y: screenFrame.y,
    width: screenFrame.width - (screenFrame.width / 3),
    height: screenFrame.height,
  };
}

function moveToLeftTwoThirds(window, screen) {
  var windowFrame = leftTwoThirdsFrame(screen);
  window.setFrame(windowFrame);
}

function rightThirdFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + screenFrame.width - (screenFrame.width / 3),
    y: screenFrame.y,
    width: screenFrame.width / 3,
    height: screenFrame.height,
  };
}

function moveToRightThird(window, screen) {
  var windowFrame = rightThirdFrame(screen);
  window.setFrame(windowFrame);
}

function rightTwoThirdsFrame(screen) {
  var screenFrame = screen.flippedVisibleFrame();
  return {
    x: screenFrame.x + (screenFrame.width / 3),
    y: screenFrame.y,
    width: screenFrame.width - (screenFrame.width / 3),
    height: screenFrame.height,
  };
}

function moveToRightTwoThirds(window, screen) {
  var windowFrame = rightTwoThirdsFrame(screen);
  window.setFrame(windowFrame);
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
    moveToFull(window, screen);
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
    var thirdsMode = Storage.get('thirdsMode') || false;
    var screen = window.screen();

    if (thirdsMode) {
      if (isEqualRect(window.frame(), fullFrame(screen))) {
        moveToLeftTwoThirds(window, screen);
      } else if (isEqualRect(window.frame(), leftThirdFrame(screen))) {
        var leftScreen = findLeftScreen(screen);
        if (leftScreen) {
          moveToRightThird(window, leftScreen);
        }
      } else if (isEqualRect(window.frame(), leftTwoThirdsFrame(screen)) || isEqualRect(window.frame(), leftHalfFrame(screen))) {
        moveToLeftThird(window, screen);
      } else if (isEqualRect(window.frame(), rightThirdFrame(screen))) {
        moveToRightTwoThirds(window, screen);
      } else if (isEqualRect(window.frame(), rightTwoThirdsFrame(screen))) {
        moveToFull(window, screen);
      } else {
        moveToLeftTwoThirds(window, screen);
      }
    } else {
      if (isEqualRect(window.frame(), leftHalfFrame(screen))) {
          var leftScreen = findLeftScreen(screen);
          if (leftScreen) {
              moveToRightHalf(window, leftScreen);
          }
      } else {
          moveToLeftHalf(window, screen);
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
      if (isEqualRect(window.frame(), fullFrame(screen))) {
        moveToRightTwoThirds(window, screen);
      } else if (isEqualRect(window.frame(), rightThirdFrame(screen))) {
        var rightScreen = findRightScreen(screen);
        if (rightScreen) {
          moveToLeftThird(window, rightScreen);
        }
      } else if (isEqualRect(window.frame(), rightTwoThirdsFrame(screen)) || isEqualRect(window.frame(), rightHalfFrame(screen))) {
        moveToRightThird(window, screen);
      } else if (isEqualRect(window.frame(), leftThirdFrame(screen))) {
        moveToLeftTwoThirds(window, screen);
      } else if (isEqualRect(window.frame(), leftTwoThirdsFrame(screen))) {
        moveToFull(window, screen);
      } else {
        moveToRightTwoThirds(window, screen);
      }
    } else {
      if (isEqualRect(window.frame(), rightHalfFrame(screen))) {
          var rightScreen = findRightScreen(screen);
          if (rightScreen) {
              moveToLeftHalf(window, rightScreen);
          }
      } else {
          moveToRightHalf(window, screen);
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
