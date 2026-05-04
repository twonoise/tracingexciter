# tracingexciter
Voice exciter with LP needle tracing error using JACK, LV2, and Faust

DESCRIPTION
-----------

One may note that sometimes old LPs, most notably very old mono records, are have warm and rich voice reproduction, may be even more sweet than original master tape of it. I think that it is due to these records are not yet have intentional pre-emphasis distortion step [1:Fig.7], so at play time these LPs are have noticeable _tracing error_, which, looks like, not (only) bad, but also can be so good so intentional addition of it to modern (non-mechanical or non-LP) voice signals may be useful.

This tracing error is shown at [1:Fig.5] with red line.

Sadly, correct implementation of it, is almost impossible with modern DSP, as, which can be seen at [1:Fig.4], it requires to alter samples not only by its amplitude (value), but also by its **time** - which is rarely can be done using FAUST, and more like, way too complex C code is need here. _(TODO: Resamplers are solves exactly this task, are they useful here?)_
But, instead of exact result, if we allow more or less close approximation of it, then one may note that this tracing error line, as first order of approximation, looks as rectified 1st derivative of signal.

The 1st derivative, at first look, is as simple as current sample to previous one difference (scaled to sample rate, if exactly precise). The problem that this approach is linearly frequency-dependent, but we do not want that out derivative amplitude changes four orders at audible band; rather, we prefer it more or less constant. Note that former one is closer to physically limited RIAA-corrected real LP predistorted freq response, and you may like it; while here i will prefer latter one as more predictable effect on voice, as the voice is target for this work.

So, we'll need some frequency correction. Here are good and not-so-good news. Good are FAUST provide `spectral_tilt()` which, used with `Alpha = -1.0` tilt, effectively makes our derivative signal frequency-independent.

But not-so-good news are
>A filter that changes the frequency response also changes the time response. This is unavoidable,

as per [2]. I discover that `spectral_tilt()` have non-constant delay. Rather, its delay is frequency dependent, i.e., it will give frequency dispersion. Within tested ~40...4k Hz band, it is `Pi/2` (90 degrees, or 1/4 of period) * Alpha.  So, for `Alpha = -0.5`, it will be 1/40/4*0.5 ~= 3 ms for 40 Hz, or ~= 30 us for 4k Hz.
Sadly, `Alpha = -1.0`, which gives most better frequency response, also gives most bad shift for our derivative, `Pi/2`.

I am spent months trying to compensate for this (remember, it not just an delay, it is frequency dependent!).

Most close approach i found so far is **Hilbert Filter**. It is seldom thing that gives 90 degree phase shift at _any_ frequency. The first problem is "any" means not really any, but some wide but well limited band: classic Hilberts (made from very good LPF turned to be BPF, like `fi.pospass()`) gives useful selectivity starting from ~1k Hz and up, which is rarely useful for human voice. There is even more special Hilbert filter, known as "Olli Niemitalo" or "0.6923878" filter [3]. I combine Olli Niemitalo's coefs with this FAUST code of some filter:

    // FAUST filter version by https://dazdsp.org/tech/faust/index.html, License: Unknown.
    // Coefs are by Olli Niemitalo (these are older than 2006). License: Unknown. See more at its .dsp file. (TODO)
    ia = allpass1mdaz(0.6923878):allpass1mdaz(0.9360654322959):allpass1mdaz(0.9882295226860):allpass1mdaz(0.9987488452737):mem;
    qa = allpass1mdaz(0.4021921162426):allpass1mdaz(0.8561710882420):allpass1mdaz(0.9722909545651):allpass1mdaz(0.9952884791278);
    allpass1mdaz(a,x) = (_:mem,x,a:+,_:*:_,x:_,mem:_,mem:-) ~ _ ;

To understand how it work, one should have some skills at _negative frequencies_ approach. One may recall that any real mono signal, like voice or sine tone, appears like two components, 1/2 amplitude each, on its _full_ spectrum, one of which is below zero. Check the blue line on picture below, it is just mono sine tone. There is not enough information in mono signal to make it not to be exactly mirrored at zero point; there is some information should be added. Simplest example if we _phase shifted_ it (not delayed! as delay will work for one tone only) by 90 degree, and use this new signal as complementary or _**Q**uadrature_ one. They both, together with original _**I**n-phase_ one, form a _complex_ signal, and it is enough to have negative and positive frequencies in it completely independent: in this case with phase shift, there will be only one (positive or negative) tone of full amplitude remains on spectrum (which one, is phase shift sign depend).

The magic here is that back annotation is also true. If we can filter out all half of band (say negative part) but keep all other part (positive), we will solve the question and got two signals with 90 degree phase shift at "any" frequency, which is exactly we need. This is exactly what Hilbert filters are for. Check the yellow line: it is filter above at work. Note that, unlike ordinary LPF, Hilbert filters are can't be ideal: they are approximations, with tradeoffs for selectivity, bandwidth, stop band attenuation, delay, CPU cost, etc. Most hard is near-zero filtration, and Olli Niemitalo's filters are exceptionally good at that.
The bad news is Hilbert filter is not just phase-shifts the incoming signal. Rather, it produce two outputs with 90 degree phase shift, _but_, phase relation to incoming signal is not defined. So it can't be used for my task. (TODO: Still try this approach, i.e. input signal also to be passed thru Hilbert filter, is it good for voice?). P.S. Btw, the pulse-measured delay of Olli Niemitalo's filter is pretty good, less than two samples.

So even after months, i am still not solved it.

The only hope is, musicians are says that the phase relation between fundamental tone of signal and its obertones, is not relevant to human ear: the way different waveforms on oscilloscope, when same on spectrum analyzer, sounds same. So at the moment, i'll try to use this statement, which means just not worry about phase angle of derivative i produce. I've added static phase shift (delay) knob for vary the phase relation, to see if this statement is correct, and maybe it can make some voices a bit richer.

One may also note that result is somewhat similar to add 1st obertone (2x of fundamental tone) to signal; and, as it is even, it should form the consonance (unlike of regular/symmetrical non-linearity like limiters/compressors, which add 2nd (3x) obertone, which is odd, so it's dissonant).


LICENSE
-------

This research text description, together with its inlined pictures, are licensed under Creative Commons Attribution 4.0. You are welcome to contribute to the description in order to improve it so long as your contributions are made available under this same license.

Included software is licensed as per LICENSE file.


[1] https://www.tonmeister.ca/wordpress/2023/11/01/dynamic-styli-correlator-ii/

[2] https://www.tonmeister.ca/wordpress/2022/07/09/filters-and-ringing-part-9/

[3] https://dsp.stackexchange.com/a/59157

[4] https://dazdsp.org/tech/faust/index.html
