function plv = multitrial_pac(lf_signals, hf_signals, srate, pf, af)
% Inputs: 
% signals = Single_trial- time series
% srate = frequency range
% Pf1,Pf2 = frequency range of the low-frequency
% Af1,Af2 = frequency range of the high-frequency

%Cohen MX."Assessing transient cross-frequency coupling in EEG data"
% Journal of Neuroscience Methods 168 (2008) 494–499

%W.D. Penny et al., "Testing for nested oscillation"
%Journal of Neuroscience Methods 174 (2008) 50–61

%DIMITRIADIS STAVROS 9/2013  & N.Laskaris 14/2/2015
%http://users.auth.gr/~stdimitr/index.html

import dsp2.util.assertions.*;

assert__isa( lf_signals, 'double', 'the low frequency signals' );
assert__isa( hf_signals, 'double', 'the high frequency signals' );
assert__isa( srate, 'double', 'the sampling rate' );
assert__isa( pf, 'double', 'the phase frequencies' );
assert__isa( af, 'double', 'the amplitude frequencies' );

assert( ndims(lf_signals) == ndims(hf_signals) && ...
  all(size(lf_signals) == size(hf_signals)), ['Distributions of low-' ...
  , ' and high-frequency signals must be matrices of equal size.'] );

Pf1 = pf(1);
Pf2 = pf(2);

Af1 = af(1);
Af2 = af(2);

[bb_p,aa_p]=butter(3,[Pf1/(srate/2),Pf2/(srate/2)]);
low_filtered_signals=filtfilt(bb_p,aa_p,lf_signals')';
Phase_signals=angle(hilbert(low_filtered_signals'))'; % this is getting the phase time series
Ntrials=size(lf_signals,1);

%get the phase of high-frequency band

%STEP 1: Filtering the original signal in the range of high-frequency range
                               % just filtering
[bb,aa]=butter(3,[Af1/(srate/2),Af2/(srate/2)]);
high_filtered_signals=filtfilt(bb,aa,hf_signals')';

%STEP 2:Get the analytic signal 
Env_high_filtered_signals=abs(hilbert(high_filtered_signals'))'; % getting the amplitude envelope

%STEP 3: Filtering the obrained envelope of the high-frequency range within the
%frequency range of the low-frequency band
lowfromhigh=filtfilt(bb_p,aa_p,Env_high_filtered_signals')'; 
low_Env_high_filtered_signals=lowfromhigh-repmat(mean(lowfromhigh),Ntrials,1);

%STEP 4:Get the phase
Amp_phase_signals=angle(hilbert(low_Env_high_filtered_signals'))';

Ntime=size(hf_signals,2);

plv=abs(sum(sum(exp(1i*(Phase_signals-Amp_phase_signals)))))/(Ntrials*Ntime);

end