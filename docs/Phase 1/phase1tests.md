On real hardware, nothing is truly bug-free until it touches silicon. Expect two quick 2-minute sanity checks the first time you run install-bridge.sh on your RPi 5:

Verify AMMB's exact config.ini section names against the freshly cloned /opt/ordnance-bridge/examples/config.ini.example, and paste the working commit SHA from git -C /opt/ordnance-bridge rev-parse HEAD back into install-bridge.sh.

Confirm the exact health endpoint path (curl -s [http://127.0.0.1:8080/openapi.json](http://127.0.0.1:8080/openapi.json)) so ordnance-watchdog.sh and check-radios.sh hit the exact 200 OK route in your pinned AMMB version.

Once your two benchtop radios pass the 10-message bidirectional test, 3× reboot test, and USB hot-pull test, Phase 1 is officially signed off.