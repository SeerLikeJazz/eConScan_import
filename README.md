
# eConScan_import
A plugin for EEGLAB that allows importing data in the BDF format.

## The BDF+ format description
<p>BDF+ is the 24-bits version of EDF+. EDF+ is the popular medical time series storage fileformat.EDF+ stores digital samples (mostly from an analog to digital converter) in two bytes, so the maximumresolution is 16 bit. However, 24-bit ADC's are becoming more and more popular. The data producedby 24-bit ADC's can not be stored in EDF+ without losing information.BDF+ stores the datasamples in three bytes, giving it a resolution of 24 bit.</p>

## Usage
Load one .bdf file:
  
>  filepath = 'C:\eConScan_import1.0\sample_data';
>  EEG = pop_importeConScan( 'data.bdf', filepath );
        
Load more than one.bdf files:
  
> filepath = 'C:\eConScan_import1.0\sample_data';
> EEG = pop_importeConScan( {'data.bdf', 'data2.bdf'}, filepath );