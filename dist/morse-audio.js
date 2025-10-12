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
      this.gainNode.gain.linearRampToValueAtTime(0.5, now + 0.015); // Longer attack
      
      // Start the tone
      this.oscillator.start(now);
      
      // Schedule the end of the tone with a gradual release
      setTimeout(() => {
        const releaseTime = this.audioContext.currentTime;
        this.gainNode.gain.setValueAtTime(0.5, releaseTime);
        this.gainNode.gain.linearRampToValueAtTime(0, releaseTime + 0.015); // Longer release
        
        setTimeout(() => {
          this.oscillator.stop();
          this.oscillator.disconnect();
          this.oscillator = null;
          resolve();
        }, 20); // Slightly longer wait before disconnecting
      }, duration - 30); // Start fade-out a bit earlier
    });
  }

  stop() {
    if (this.oscillator) {
      // Smooth release to avoid clicks
      const now = this.audioContext.currentTime;
      this.gainNode.gain.setValueAtTime(this.gainNode.gain.value, now);
      this.gainNode.gain.linearRampToValueAtTime(0, now + 0.05); // Longer, smoother release
      
      // Schedule actual stop after the fade-out
      setTimeout(() => {
        this.oscillator.stop();
        this.oscillator.disconnect();
        this.oscillator = null;
      }, 60); // Wait for fade-out to complete
    }
    this.queue = [];
    this.isPlaying = false;
  }

  setOnComplete(callback) {
    this.onComplete = callback;
  }


  startTone() {
    this.init();

    // Create and configure oscillator
    this.oscillator = this.audioContext.createOscillator();
    this.oscillator.type = 'sine';
    this.oscillator.frequency.value = this.frequency;
    this.oscillator.connect(this.gainNode);

    // Get current time from audio context for precise scheduling
    const now = this.audioContext.currentTime;

    // Smoother attack to avoid clicks
    this.gainNode.gain.setValueAtTime(0, now);
    this.gainNode.gain.linearRampToValueAtTime(0.5, now + 0.05); // Longer, smoother attack

    // Start the tone
    this.oscillator.start(now);
  }

  
}

export default MorseAudio;
