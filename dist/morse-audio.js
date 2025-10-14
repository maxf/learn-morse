// Morse code audio module
class MorseAudio {
  constructor() {
    this.audioContext = null;
    this.oscillator = null;
    this.gainNode = null;
    this.isPlaying = false;
    this.queue = [];
    this.dotDuration = 60; // milliseconds
    this.dashDuration = this.dotDuration * 3;
    this.pauseDuration = this.dotDuration;
    this.letterPauseDuration = this.dotDuration * 3;
    this.frequency = 700; // Hz
  }

  init() {
    // Create audio context on first user interaction
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      this.gainNode = this.audioContext.createGain();
      this.gainNode.gain.value = 0;
      this.gainNode.connect(this.audioContext.destination);
    }
  }

  playMorse(morseString) {
    this.init();
    
    if (this.isPlaying) {
      // If already playing, add to queue
      this.queue.push(morseString);
      return;
    }
    
    this.isPlaying = true;
    const sequence = this.parseMorseString(morseString);
    this.playSequence(sequence, 0)
      .then(() => {
        this.isPlaying = false;
        // Notify Elm that playback is complete
        if (this.onComplete) {
          this.onComplete();
        }
        
        // Play next in queue if any
        if (this.queue.length > 0) {
          const next = this.queue.shift();
          this.playMorse(next);
        }
      });
  }

  parseMorseString(morseString) {
    const sequence = [];
    
    for (let i = 0; i < morseString.length; i++) {
      const char = morseString[i];
      
      if (char === '.') {
        sequence.push({ type: 'dot', duration: this.dotDuration });
      } else if (char === '-') {
        sequence.push({ type: 'dash', duration: this.dashDuration });
      } else if (char === ' ') {
        sequence.push({ type: 'letterPause', duration: this.letterPauseDuration });
      }
      
      // Add pause between dots and dashes (but not after spaces)
      if (i < morseString.length - 1 && char !== ' ' && morseString[i+1] !== ' ') {
        sequence.push({ type: 'pause', duration: this.pauseDuration });
      }
    }
    
    return sequence;
  }

  playSequence(sequence, index) {
    return new Promise((resolve) => {
      if (index >= sequence.length) {
        resolve();
        return;
      }
      
      const item = sequence[index];
      
      if (item.type === 'dot' || item.type === 'dash') {
        this.playTone(item.duration)
          .then(() => this.playSequence(sequence, index + 1))
          .then(resolve);
      } else {
        // For pauses
        setTimeout(() => {
          this.playSequence(sequence, index + 1).then(resolve);
        }, item.duration);
      }
    });
  }

  playTone(duration) {
    return new Promise((resolve) => {
      // Create and configure oscillator
      this.oscillator = this.audioContext.createOscillator();
      this.oscillator.type = 'sine';
      this.oscillator.frequency.value = this.frequency;
      this.oscillator.connect(this.gainNode);
      
      // Get current time from audio context for precise scheduling
      const now = this.audioContext.currentTime;
      
      // Smooth transitions to avoid clicks - use more gradual ramping
      this.gainNode.gain.setValueAtTime(0, now);
      this.gainNode.gain.linearRampToValueAtTime(0.5, now + 0.03); // Even longer attack
      
      // Start the tone
      this.oscillator.start(now);
      
      // Schedule the end of the tone with a gradual release
      setTimeout(() => {
        const releaseTime = this.audioContext.currentTime;
        this.gainNode.gain.setValueAtTime(0.5, releaseTime);
        
        // Use exponential ramp for more natural sound decay
        this.gainNode.gain.exponentialRampToValueAtTime(0.001, releaseTime + 0.08);
        this.gainNode.gain.setValueAtTime(0, releaseTime + 0.08);
        
        setTimeout(() => {
          if (this.oscillator) {
            try {
              this.oscillator.stop();
              this.oscillator.disconnect();
            } catch (e) {
              console.log("Oscillator already stopped");
            }
            this.oscillator = null;
          }
          resolve();
        }, 100); // Much longer wait before disconnecting
      }, duration - 120); // Start fade-out earlier
    });
  }

  stop() {
    if (this.oscillator) {
      // Get current gain value
      const currentGain = this.gainNode.gain.value;
      
      // Smooth release to avoid clicks - use exponential ramp for more natural decay
      const now = this.audioContext.currentTime;
      
      // Set the current value explicitly first
      this.gainNode.gain.setValueAtTime(currentGain, now);
      
      // Use a longer fade-out time for smoother release
      // Using exponentialRampToValueAtTime for more natural sound decay
      // We can't ramp to 0 with exponential, so use a very small value
      this.gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
      
      // Then set to 0 after the exponential ramp
      this.gainNode.gain.setValueAtTime(0, now + 0.1);
      
      // Schedule actual stop after the fade-out with a longer delay
      setTimeout(() => {
        if (this.oscillator) {
          try {
            this.oscillator.stop();
            this.oscillator.disconnect();
          } catch (e) {
            // Handle any errors that might occur if the oscillator
            // was already stopped or disconnected
            console.log("Oscillator already stopped");
          }
          this.oscillator = null;
        }
      }, 120); // Wait longer for fade-out to complete
    }
    this.queue = [];
    this.isPlaying = false;
  }

  setOnComplete(callback) {
    this.onComplete = callback;
  }


  startTone() {
    this.init();
    
    // Resume the audio context if it's suspended (needed for first interaction)
    if (this.audioContext.state === 'suspended') {
      this.audioContext.resume().then(() => {
        this.createAndStartOscillator();
      });
    } else {
      this.createAndStartOscillator();
    }
  }
  
  createAndStartOscillator() {
    // Create and configure oscillator
    this.oscillator = this.audioContext.createOscillator();
    this.oscillator.type = 'sine';
    this.oscillator.frequency.value = this.frequency;
    this.oscillator.connect(this.gainNode);

    // Get current time from audio context for precise scheduling
    const now = this.audioContext.currentTime;

    // Smoother attack to avoid clicks
    this.gainNode.gain.setValueAtTime(0, now);
    this.gainNode.gain.linearRampToValueAtTime(0.5, now + 0.08); // Even longer, smoother attack

    // Start the tone
    this.oscillator.start(now);
  }

  
}

export default MorseAudio;
