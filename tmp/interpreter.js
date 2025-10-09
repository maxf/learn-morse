const $ = jQuery;
const morseCode = new MorseCode();
const container = document.querySelector("div.output");

// Get the dom elements in this module.
const characters = container.querySelector("span.characters");

// Get the dot and dash durations (in milliseconds).
const dotDuration = 250;
const dashDuration = dotDuration * 3;
const pauseDuration = dotDuration;

// Store the date/time for the keydown.
let keyDownDate = null;

// Keep a timer for post-key resolution for characters.
let resolveTimer = null;

// Keep a timer for adding a new space to the message.
let spaceTimer = null;


document.onkeydown = function(event) {
  event.preventDefault();

  // Check to see if there is a key-down date. If
  // so, then exit - we only want the first press
  // event to be registered.
  if (keyDownDate){
    // Don't process this event.
    return;
  }

  // Clear the resolution timer.
  clearTimeout( resolveTimer );

  // Clear the space timer.
  clearTimeout( spaceTimer );

  // Store the date for this key-down.
  keyDownDate = new Date();
};


document.onkeyup = function( event ) {
  event.preventDefault();

  // Determine the keypress duration.
  var keyPressDuration = ((new Date())- keyDownDate);

  // Clear the key down date so subsequent key
  // press events can be processed.
  keyDownDate = null;

  // Check to see if the duration indicates a dot
  // or a dash.
  if (keyPressDuration <= dotDuration){
    // Push a dot.
    morseCode.dot();
  } else {
    // Push a dash.
    morseCode.dash();
  }

  // Now that the key has been pressed, we need to
  // wait a bit to see if we need to resolve the
  // current sequence (if the user doesn't interact
  // with the interpreter, we'll resolve).
  resolveTimer = setTimeout(
    function(){
      // Try to resolve the sequence.
      try {

        // Get the character respresented by
        // the current sequence.
        var character = morseCode.resolveSequence();

        // Add it to the output.
        characters.innerText = characters.innerText + character;

      } catch (e) {
        // Reset the sequence - something
        // went wrong with the user's input.
        morseCode.resetSequence();
      }

      // Set a timer to add a new space to the
      // message.
      spaceTimer = setTimeout(
        function(){
          // Add a "space".
          characters.innerText = characters.innerText + "__";
        },
        3500
      );
    },
    (pauseDuration * 3)
  );
}
