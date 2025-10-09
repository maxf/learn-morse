class MorseCode {

  constructor() {
    // Define the duration of the dot in milliseconds.
    this._dotDuration = 250;

    // Define the duration of the dash in milliseconds. The
    // dash is supposed to be 3x that of the dot.
    this._dashDuration = (this._dotDuration * 3);

    // Define the pause duration. This is the time between
    // letters and is supposed to be 1x that of the dot.
    this._pauseDuration = (this._dotDuration * 1);

    // Define the pattern map for the morse code patterns
    // as the relate the alpha-numeric characters that they
    // represent.
    this._patternMap = {
        ".-": "A",
        "-...": "B",
        "-.-.": "C",
        "-..": "D",
        ".": "E",
        "..-.": "F",
        "--.": "G",
        "....": "H",
        "..": "I",
        ".---": "J",
        "-.-": "K",
        ".-..": "L",
        "--": "M",
        "-.": "N",
        "---": "O",
        ".--.": "P",
        "--.-": "Q",
        ".-.": "R",
        "...": "S",
        "-": "T",
        "..-": "U",
        "...-": "V",
        ".--": "W",
        "-..-": "X",
        "-.--": "Y",
        "--..": "Z",
        "-----": "0",
        ".----": "1",
        "..---": "2",
        "...--": "3",
        "....-": "4",
        ".....": "5",
        "-....": "6",
        "--...": "7",
        "---..": "8",
        "----.": "9"
    };

    // I am the current, transient sequence being evaluated.
    this._sequence = "";
  }

  // I add the given value to the current sequence.
  //
  // Throws InvalidTone if not a dot or dash.
  addSequence(value) {

    // Check to make sure the value is valid.
    if ((value !== ".") && (value !== "-")) {
        // Invalid value.
        throw( new Error( "InvalidTone" ) );

    }

    // Add the given value to the end of the current
    // sequence value.
    this._sequence += value;

    // Return this object reference.
    return( this );
  }


  // I add a dash to the current sequence.
  dash() {
    // Reroute to the addSequence();
    return( this.addSequence( "-" ) );
  }


  // I add a dot to the current sequence.
  dot() {
    // Reroute to the addSequence();
    return( this.addSequence( "." ) );
  }


  // I get the dash duration.
  getDashDuration() {
    return( this._dashDuration );
  }


  // I get the dot duration.
  getDotDuration() {
    return( this._dotDuration );
  }


  // I get the pause duration.
  getPauseDuration() {
    return( this._pauseDuration );
  }


  // I reset the current sequence.
  resetSequence() {
    // Clear the sequence.
    this._sequence = "";
  }


  // I get the alpha-numeric charater repsented by the
  // current sequence. I also also reset the internal
  // sequence value.
  //
  // Throws InvalidSequence if it cannot be mapped to a
  // valid alpha-numeric character.
  resolveSequence() {

    // Check to see if the current sequence is valid.
    if (!this._patternMap.hasOwnProperty( this._sequence )){
      // The sequence cannot be matched.
      throw( new Error( "InvalidSequence" ) );
    }

    // Get the alpha-numeric mapping.
    var character = this._patternMap[ this._sequence ];

    // Reset the sequence.
    this._sequence = "";

    // Return the mapped character.
    return( character );

  }

}
