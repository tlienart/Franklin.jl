# Rough Notes

This should eventually be compiled into proper documentation.

## Serving with browser-sync

* using `browser-sync` in `JuDoc.serve` to launch a local server and refresh the page upon modification of the source file
* when shutting down `JuDoc.serve` with a `CTRL+C` this propagates to the `browser-sync` process (a `node` process) which gets killed "properly"
* if `JuDoc.serve` gets an error (for example erroneous syntax somewhere), then the `browser-sync` process must be forcibly interrupted as there is no propagated interrupt signal, this is done by
    * writing the PID to a temporary file (`JuDoc.PID_FILE`) when launching the `browser-sync` process
    * upon anormal interruption, kill the process (see `JuDoc.cleanup_process()`)
    * remove the `PID_FILE`

**Note**: this should work fine on Linux/Mac, likely not on windows, but maybe with the emulator.
