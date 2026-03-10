// Domain glossary:
//
//   Raw event - single scroll event from the compositor. One physical
//     cog notch produces 3-5 raw events at 6-16ms intervals. Magnitude
//     varies (1.0-10.0 after normalization) based on physical scroll speed.
//
//   Magnitude — raw event intensity after dividing by RAW_DIVISOR.
//     Slow cog click ~1.0. Fast flick ~4.0. Freefall spin ~8-10.
//
//   Accumulator — running sum of magnitudes, drained by exponential
//     decay over time. Represents "how much scroll energy is built up
//     right now." Low when scrolling slowly or pausing, high during
//     sustained fast scrolling. This is what feeds the curve.
//
//   Decay — exponential drain on the accumulator between events.
//     Prevents the accumulator from growing without bound during
//     sustained scrolling. Accumulator reaches equilibrium when
//     decay drains as fast as new events add.
//
//   Curve - maps accumulator -> volume delta per event. Two segments:
//     1. Saturating exponential: ramps from MIN_DELTA toward CRUISE_DELTA.
//        This is the normal scrolling region.
//     2. Linear extension: above CRUISE_AT, adds FREEFALL_RATE per
//        accumulator unit. This is the freefall region where sustained
//        high-speed scrolling breaks past the cruise ceiling.
//     Hard-capped at MAX_DELTA regardless of accumulator value.
//
//   Cruise — the steady-state delta during normal (non-freefall) scrolling.
//     The curve asymptotically approaches CRUISE_DELTA but never exceeds
//     it unless the accumulator passes CRUISE_AT, where the linear
//     freefall extension takes over.
//
//   Freefall — sustained high-speed scrolling (wheel spinning freely).
//     Accumulator builds well past CRUISE_AT, so delta grows linearly
//     beyond cruise. Capped at MAX_DELTA — fast traversal without
//     losing all control.
//
//   Smooth delta — the actual output, filtered version of the curve's
//     raw output. Ramps up instantly (new speed applies immediately)
//     but ramps down slowly (holds speed through brief micro-pauses
//     where the finger hesitates on the wheel). Prevents jerky
//     volume changes during otherwise steady scrolling.
//
//   Mag drop — when magnitude suddenly drops (e.g. freefall at mag 9
//     -> fine-tuning at mag 1.5), the accumulator and smooth delta
//     reset immediately. Without this, freefall momentum leaks into
//     fine adjustments and causes overshoot.
//
// Model tiers:
//   Hardware - describes what the mouse sends. Set per device.
//   Shape - controls curve mechanics (how input maps to output).
//           Set once when the math feels right, then leave alone.
//   Feel - how much volume actually moves. The tuning surface.
//          CRUISE_DELTA = normal scroll speed.
//          FREEFALL_RATE = how fast freefall accelerates past cruise.
//          MAX_DELTA = absolute ceiling on speed (freefall cap).
//   Edge fixes - compensate for specific quirks (micro-pause jitter,
//                freefall-to-fine transitions). Hidden constants unless
//                they keep needing adjustment, in which case the model
//                needs rethinking.

// --- hardware ---
var RAW_DIVISOR = 16;       // normalize hardware deltas to consistent units
var M_SIZE = 2;             // max magnitude of a normal single cog notch

// --- shape ---
var MIN_DELTA = 0.001;      // per-event floor (curve output at zero accumulation)
var K = 0.02;               // curve saturation speed — lower = slower ramp
var CRUISE_AT = 20;         // accumulator value where freefall linear ramp begins
var DECAY = 0.2;            // accumulator drain per 100ms — lower = drains faster

// --- feel ---
var CRUISE_DELTA = 0.004;   // normal scrolling ceiling (delta per event)
var FREEFALL_RATE = 0.0005; // linear growth per accumulator unit above CRUISE_AT
var MAX_DELTA = 0.015;      // absolute ceiling — freefall never exceeds this

// --- edge fixes ---
var RAMP_DOWN = 0.95;       // smooth delta decay per 100ms (holds speed through micro-pauses)
var MAG_DROP_RATIO = 0.5;   // magnitude drop ratio that triggers fine-control reset

// --- state ---
var _accum = 0;
var _lastTime = 0;
var _smoothDelta = 0;
var _prevMag = 0;

function curve(accum) {
    // shift curve so a single cog notch starts at the bottom of the ramp
    var shifted = Math.max(0, accum - M_SIZE);
    // saturating exponential: MIN_DELTA -> CRUISE_DELTA (never quite reaches it)
    var base = MIN_DELTA + (CRUISE_DELTA - MIN_DELTA) * (1 - Math.exp(-K * shifted));
    // linear ramp past cruise ceiling for freefall
    if (shifted > CRUISE_AT) {
        base += FREEFALL_RATE * (shifted - CRUISE_AT);
    }
    return Math.min(base, MAX_DELTA);
}

function processRaw(raw) {
    var magnitude = Math.abs(raw) / RAW_DIVISOR;
    var direction = Math.sign(raw);
    var now = Date.now();
    var elapsed = _lastTime === 0 ? Infinity : now - _lastTime;
    _lastTime = now;

    // mag drop - freefall->fine transition, cut momentum immediately
    if (magnitude < _prevMag * MAG_DROP_RATIO) {
        _accum = magnitude;
        _smoothDelta = 0;
    }
    _prevMag = magnitude;

    // drain accumulator by time elapsed (exponential decay)
    if (isFinite(elapsed)) {
        _accum *= Math.pow(DECAY, elapsed / 100);
    }
    // feed new scroll energy into accumulator
    _accum += magnitude;

    var rawDelta = curve(_accum);

    // hysteresis - ramp up instantly, ramp down slowly
    if (rawDelta >= _smoothDelta) {
        _smoothDelta = rawDelta;
    } else {
        if (isFinite(elapsed)) {
            _smoothDelta *= Math.pow(RAMP_DOWN, elapsed / 100);
        }
        if (_smoothDelta < rawDelta) _smoothDelta = rawDelta;
    }

    return direction * _smoothDelta;
}

function clampVolume(current, delta) {
    return Math.max(0, Math.min(1, current + delta));
}
