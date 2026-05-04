// faust2lv2 tracingexciter.dsp  &&  sed -i -e 's/out0/OutI/g' -e 's/out1/OutQ/g' tracingexciter.lv2/tracingexciter.ttl  &&  cp -R ./tracingexciter.lv2/ /usr/local/lib/lv2/

declare name "TracingExciter"; // No spaces for better JACK port names.
declare version "2026";
declare author "jpka";
declare license "MIT";
declare description "Voice exciter using LP needle tracing error behaviour";

import("stdfaust.lib");

on      =  button("[0] ON");
needleR = hslider("[1] Needle R", 1.5, -5.0, 5.0, 0.1);
dly     = hslider("[2] Symmetry", 0.0,    0, 1.0, 0.01);

// 1st derivative scaled to some point, stable across variation of sample rates.
deri(a, x) = (x - x@(1)) * ma.SR / 1000.0;

// Optional delay in samples must be non-negative integer.
// As it impossible to be freq-independent, we use 440 Hz as reference point, at which we provide 360 degree of phase rotation. Other freqs will differ.
delay = abs(round(dly * ma.SR / 440));

// Tracing error 1st order approximation. Note rectifier as 'abs'.
tracingError = abs(fi.spectral_tilt(2, 20, 10000, -1.0) : deri(-1) * abs(needleR)) @ delay;
tracingErrorSign = -1, 1 :> select2(needleR > 0);

process =
_ <: _,
  (
    // Original voice
    _
    // Added distortion
    + tracingError * tracingErrorSign
    // Centered at zero volts
    : fi.dcblocker
  )
:> select2(on)
;
