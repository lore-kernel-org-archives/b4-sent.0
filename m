From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 19:37:57 +0100
Subject: [PATCH v5 13/13] docs: iio: add documentation for ad9910 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-ad9910-iio-driver-v5-13-31599c88314a@analog.com>
References: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
In-Reply-To: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779043094; l=22157;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Ll4UAPPHH/JlIJ2c6AjBprSAnwegS2CDUDCIoJel7ko=;
 b=E9gHNLsZL99K+5Mwa+/RZTzTpXFMTEwd8XBlkzAS10Upyyxe9leUhnhck6xBKpOYAj+KTPIH3
 1Ym8MzbI70yD/MDGgH1Jai7D3L/Ex5Y3dzeYly4sioz74S4+w8qUoh1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the AD9910 DDS IIO driver, which describes channels,
DDS modes, attributes and ABI usage examples.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/iio/ad9910.rst | 666 +++++++++++++++++++++++++++++++++++++++++++
 Documentation/iio/index.rst  |   1 +
 MAINTAINERS                  |   1 +
 3 files changed, 668 insertions(+)

diff --git a/Documentation/iio/ad9910.rst b/Documentation/iio/ad9910.rst
new file mode 100644
index 000000000000..dbcf8f8a1dda
--- /dev/null
+++ b/Documentation/iio/ad9910.rst
@@ -0,0 +1,666 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+=============
+AD9910 driver
+=============
+
+Direct Digital Synthesizer (DDS) driver for the Analog Devices Inc. AD9910.
+The module name is ``ad9910``.
+
+* `AD9910 <https://www.analog.com/en/products/ad9910.html>`_
+
+The AD9910 is a 1 GSPS DDS with a 14-bit DAC, controlled over SPI. The driver
+exposes the device through the IIO ``altvoltage`` channel type and supports
+five DDS operating modes: single tone, parallel port modulation, digital ramp
+generation (DRG), RAM playback and output shift keying (OSK). The device has
+8 hardware profiles, each capable of storing independent single tone and RAM
+playback parameters.
+
+
+Channel hierarchy
+=================
+
+The driver exposes the following IIO output channels, each identified by a
+unique channel number and a human-readable label. The ``phy`` channel is the
+root of the hierarchy. Changing its ``sampling_frequency`` reconfigures the
+system clock (SYSCLK) which affects all other channels. Most of the
+mode-specific channels have an ``enable`` attribute that turns the mode on/off.
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Channel
+     - Label
+     - Parent
+     - Description
+
+   * - ``out_altvoltage100``
+     - ``phy``
+     -
+     - Physical output: system clock and profile control.
+       See `Physical channel`_.
+
+   * - ``out_altvoltage110`` ... ``out_altvoltage117``
+     - ``profile0`` ... ``profile7``
+     - ``phy``
+     - Single tone control: frequency, phase, amplitude.
+       See `Single Tone mode`_.
+
+   * - ``out_altvoltage120``
+     - ``parallel_port``
+     - ``phy``
+     - Parallel port modulation channel.
+       See `Parallel Port mode`_.
+
+   * - ``out_altvoltage130``
+     - ``digital_ramp_generator``
+     - ``phy``
+     - Digital ramp generator (DRG) control: enable.
+       See `Digital ramp generator (DRG)`_.
+
+   * - ``out_altvoltage131``
+     - ``digital_ramp_up``
+     - ``digital_ramp_generator``
+     - DRG ramp-up parameters: dwell enable, limits, rate of change, ramp rate.
+
+   * - ``out_altvoltage132``
+     - ``digital_ramp_down``
+     - ``digital_ramp_generator``
+     - DRG ramp-down parameters: dwell enable, limits, rate of change, ramp rate.
+
+   * - ``out_altvoltage140``
+     - ``ram_control``
+     - ``phy``
+     - RAM playback: enable, frequency, phase and sampling frequency for active
+       profile. See `RAM mode`_.
+
+   * - ``out_altvoltage150``
+     - ``output_shift_keying``
+     - ``phy``
+     - Output shift keying (OSK): enable, amplitude scale, ramp rate,
+       rate of change control. See `Output Shift Keying (OSK)`_.
+
+DDS modes
+=========
+
+The AD9910 supports multiple modes of operation that can be configured
+independently or in combination. Such modes and their corresponding IIO channels
+are described in this section. Each DDS core parameter (frequency, phase and
+amplitude) value can come from different sources, but only one is active at a
+time. This activation depends on a priority list, which is based on the enable
+and destination configurations for such modes. The following tables are
+extracted from the AD9910 datasheet and summarizes the control parameters for
+each mode and their priority when multiple sources are enabled simultaneously:
+
+.. flat-table:: DDS Frequency Control
+   :header-rows: 1
+
+   * - Priority
+     - Data Source
+     - Conditions
+
+   * - Highest Priority
+     - RAM
+     - RAM enabled and data destination is frequency
+
+   * -
+     - DRG
+     - DRG enabled and data destination is frequency
+
+   * -
+     - Parallel data and Frequency Tuning Word, FTW (frequency_offset)
+     - Parallel data port enabled and data destination is frequency
+
+   * -
+     - FTW register (frequency)
+     - RAM enabled and data destination is not frequency
+
+   * - Lowest Priority
+     - FTW (frequency) in single tone channel for the active profile
+     - All other cases
+
+.. flat-table:: DDS Phase Control
+   :header-rows: 1
+
+   * - Priority
+     - Data Source
+     - Conditions
+
+   * - Highest Priority
+     - RAM
+     - RAM enabled and data destination is phase or polar
+
+   * -
+     - DRG
+     - DRG enabled and data destination is phase
+
+   * -
+     - Parallel data port
+     - Parallel data port enabled and data destination is phase
+
+   * -
+     - Parallel data port and Phase Offset Word, POW register LSBs (phase_offset)
+     - Parallel data port enabled and data destination is polar
+
+   * -
+     - POW register (phase)
+     - RAM enabled and destination is not phase nor polar
+
+   * - Lowest Priority
+     - POW (phase) in single tone channel for the active profile
+     - All other cases
+
+.. flat-table:: DDS Amplitude Control
+   :header-rows: 1
+
+   * - Priority
+     - Data Source
+     - Conditions
+
+   * - Highest Priority
+     - Amplitude Scale Factor, ASF register and OSK generator
+     - OSK enabled
+
+   * -
+     - RAM
+     - RAM enabled and data destination is amplitude or polar
+
+   * -
+     - DRG
+     - DRG enabled and data destination is amplitude
+
+   * -
+     - Parallel data port
+     - Parallel data port enabled and data destination is amplitude
+
+   * -
+     - Parallel data port and ASF register LSBs (scale_offset)
+     - Parallel data port enabled and data destination is polar
+
+   * - Lowest Priority
+     - ASF (scale) in single tone channel for the active profile
+     - (Amplitude scale is already enabled by default)
+
+While debugging or testing, the debug attributes ``frequency_source``,
+``phase_source`` and ``amplitude_source`` can be used to read the label of
+the channel that is actively controlling the correspondent DDS parameter,
+which reflects the priority list described above.
+
+Single Tone mode
+----------------
+
+Single tone is the baseline operating mode. The ``profileY`` channels
+provide enable, frequency, phase and amplitude control:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``en``
+     - boolean (0 or 1)
+     - Enable/disable profile Y. Only one profile can be active at a
+       time. Then enabling a profile disables the current active profile.
+       Disabling an active profile brings the device to a powered down state.
+
+   * - ``frequency``
+     - Hz
+     - Output frequency. Range :math:`[0, f_{SYSCLK}/2)`. Stored in the
+       profile's frequency tuning word (FTW).
+
+   * - ``phase``
+     - rad
+     - Phase offset. Range :math:`[0, 2\pi)`. Stored in the profile's phase
+       offset word (POW).
+
+   * - ``scale``
+     - fractional
+     - Amplitude scale factor. Range :math:`[0, 1]`. Stored in the profile's
+       amplitude scale factor (ASF).
+
+Profile switching is allowed while RAM mode is enabled. In that case single tone
+parameters are stored in a shadow register and are not written to hardware until
+RAM mode is disabled.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Configure a 100 MHz tone in profile to 2 and set it as the active profile:
+
+.. code-block:: bash
+
+  echo 100000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage112_frequency
+  echo 0.5 > /sys/bus/iio/devices/iio:device0/out_altvoltage112_scale
+  echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage112_phase
+
+  # Activate profile 2
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage112_en
+
+Read back the current single tone frequency:
+
+.. code-block:: bash
+
+  cat /sys/bus/iio/devices/iio:device0/out_altvoltage112_frequency
+
+Parallel Port mode
+------------------
+
+The parallel port allows real-time modulation of DDS parameters through a
+16-bit external data bus.
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``frequency_scale``
+     - power-of-2
+     - Frequency modulation (FM) gain multiplier applied to 16-bit parallel
+       input. Range :math:`[1, 32768]`, must be a power of 2.
+
+   * - ``frequency_offset``
+     - Hz
+     - Base FTW to which scaled parallel data is added. Range :math:`[0, f_{SYSCLK}/2)`.
+
+   * - ``phase_offset``
+     - rad
+     - Base phase for polar modulation. Lower 8 bits of POW register.
+       Range :math:`[0, 2\pi/256)`.
+
+   * - ``scale_offset``
+     - fractional
+     - Base amplitude for polar modulation. Lower 6 bits of ASF register.
+       Range :math:`[0, 1/256)`.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Set parallel port frequency modulation with a scale of 16 and a 50 MHz
+offset:
+
+.. code-block:: bash
+
+  echo 16 > /sys/bus/iio/devices/iio:device0/out_altvoltage120_frequency_scale
+  echo 50000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage120_frequency_offset
+
+Digital ramp generator (DRG)
+----------------------------
+
+The DRG produces linear frequency, phase or amplitude sweeps using dedicated
+hardware. It is controlled through three channels: a parent control channel
+(``digital_ramp_generator``) and two child ramp channels
+(``digital_ramp_up``, ``digital_ramp_down``).
+
+The DRG can target only one destination at a time (frequency, phase or
+amplitude). Destination selection follows a "last write wins" policy: writing
+any value (including zero) to a destination-specific attribute (e.g.
+``frequency``, ``frequency_roc``, ``phase``, ``phase_roc``, ``scale`` or
+``scale_roc``) switches the DRG destination accordingly. Reading an attribute
+whose destination is not currently active returns ``-EBUSY``.
+
+Control channel attributes
+^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``en``
+     - boolean
+     - Enable/disable the DRG.
+
+Ramp channel attributes
+^^^^^^^^^^^^^^^^^^^^^^^^
+
+The ``digital_ramp_up`` and ``digital_ramp_down`` channels share the same
+attribute set but configure ascending and descending ramp parameters
+independently:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``dwell_en``
+     - boolean
+     - Enable dwell at the ramp limit. When disabled, the ramp auto-transitions
+       at this limit without waiting for the DRCTL pin. Disabling both creates a
+       bidirectional continuous ramp (Triangular pattern). Other configurations
+       create a single-shot ramp at the transition of the DRCTL pin: ramp-up
+       only, ramp-down only or bidirectional with dwell at the limits.
+
+   * - ``frequency``
+     - Hz
+     - Frequency ramp limit. Range: :math:`[0, f_{SYSCLK}/2)`. Writing a value
+       sets the ramp destination to frequency. Reading back returns the
+       currently active frequency limit or -EBUSY if other destination is
+       active (phase or amplitude).
+
+   * - ``phase``
+     - rad
+     - Phase ramp limit. Range: :math:`[0, 2\pi)`. Writing a value sets the
+       ramp destination to phase. Reading back returns the currently active
+       phase limit or -EBUSY if other destination is active (frequency or
+       amplitude).
+
+   * - ``scale``
+     - fractional
+     - Amplitude scale ramp limit. Range: :math:`[0, 1)`. Writing a value sets
+       the ramp destination to amplitude. Reading back returns the currently
+       active scale limit or -EBUSY if other destination is active (frequency
+       or phase).
+
+   * - ``sampling_frequency``
+     - Hz
+     - Ramp clock rate. It is controlled by an integer divider so the requested
+       value will adjust to nearest supported value.
+
+   * - ``frequency_roc``
+     - Hz/s
+     - Frequency rate of change. Sets the per-tick frequency increment/decrement
+       based on the current ramp clock rate.
+
+   * - ``phase_roc``
+     - rad/s
+     - Phase rate of change. Sets the per-tick phase increment/decrement based
+       on the current ramp clock rate.
+
+   * - ``scale_roc``
+     - 1/s
+     - Amplitude scale rate of change. Sets the per-tick amplitude scale
+       increment/decrement based on the current ramp clock rate.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Configure a frequency sweep from 40 MHz to 60 MHz with a rate of change of
+25 GHz/s:
+
+.. code-block:: bash
+
+  # Disable dwell on both limits for a bidirectional continuous ramp
+  echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_dwell_en
+  echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_dwell_en
+
+  # Set ramp limits
+  echo 60000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_frequency
+  echo 40000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_frequency
+
+  # Set ramp rate
+  echo 25000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_sampling_frequency
+  echo 25000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_sampling_frequency
+
+  # Set frequency rate of change (Hz/s)
+  echo 25000000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_frequency_roc
+  echo 25000000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_frequency_roc
+
+  # Enable the DRG
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage130_en
+
+RAM mode
+--------
+
+The AD9910 contains a 1024 x 32-bit RAM that can be loaded with waveform data
+and played back to modulate frequency, phase, amplitude, or polar (phase +
+amplitude) parameters.
+
+RAM control channel attributes
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``en``
+     - boolean
+     - Enable/disable RAM playback. Toggling swaps profile registers between
+       single tone and RAM configurations across all 8 profiles.
+
+   * - ``frequency``
+     - Hz
+     - Frequency tuning word used as the single tone frequency when
+       RAM destination is not ``frequency``. Range: :math:`[0, f_{SYSCLK}/2)`.
+
+   * - ``phase``
+     - rad
+     - Phase offset word used as the single tone phase when RAM destination
+       is not ``phase``. Range: :math:`[0, 2\pi)`.
+
+   * - ``sampling_frequency``
+     - Hz
+     - RAM playback step rate of the active profile, which controls how fast the
+       address counter advances. It is controlled by an integer divider so the
+       requested value will adjust to nearest supported value.
+
+Loading RAM data
+^^^^^^^^^^^^^^^^
+
+RAM data is loaded through the firmware upload framework. The driver registers
+a firmware upload sysfs entry named ``iio_deviceX:ram``. The firmware data
+follows a binary format (version 1) with an 80-byte header followed by data
+words. All fields are big-endian.
+
+.. flat-table:: RAM firmware header (80 bytes)
+   :header-rows: 1
+
+   * - Offset
+     - Size
+     - Field
+     - Description
+
+   * - 0
+     - 4
+     - ``magic``
+     - Magic number: ``0x00AD9910``
+
+   * - 4
+     - 2
+     - ``version``
+     - Format version: ``0x0001``
+
+   * - 6
+     - 2
+     - ``wcount``
+     - Number of 32-bit RAM data words (0--1024)
+
+   * - 8
+     - 4
+     - ``crc``
+     - CRC32 checksum over ``cfr1``, ``profiles`` and ``words``
+
+   * - 12
+     - 4
+     - ``cfr1``
+     - CFR1 register value. Only RAM-relevant bits are used:
+       bits [30:29] set data destination (00: frequency, 01: phase,
+       10: amplitude, 11: polar); bits [20:17] set internal profile
+       control (see datasheet Table 14)
+
+   * - 16
+     - 64
+     - ``profiles[0..7]``
+     - 8 sets of 8-byte RAM profile configurations (see below)
+
+   * - 80
+     - 4 x wcount
+     - ``words[]``
+     - RAM data words in reverse order
+
+Each 8-byte profile entry contains:
+
+.. flat-table:: RAM profile entry (8 bytes)
+   :header-rows: 1
+
+   * - Bits
+     - Field
+     - Description
+
+   * - [55:40]
+     - Address step rate
+     - Controls playback speed for this profile
+
+   * - [39:30]
+     - End address
+     - Last RAM address for this profile
+
+   * - [23:14]
+     - Start address
+     - First RAM address for this profile
+
+   * - [5]
+     - No-dwell high
+     - No-dwell at high limit (ramp-up mode)
+
+   * - [3]
+     - Zero-crossing
+     - Zero-crossing enable (direct-switch mode)
+
+   * - [2:0]
+     - Operating mode
+     - 000: direct switch, 001: ramp-up, 010: bidirectional,
+       011: bidirectional continuous, 100: ramp-up continuous
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Configure RAM mode with firmware data and enable it:
+
+.. code-block:: bash
+
+  # Load RAM data via firmware upload
+  echo 1 > /sys/class/firmware/iio\:device0\:ram/loading
+  cat ad9910-ram.bin > /sys/class/firmware/iio\:device0\:ram/data
+  echo 0 > /sys/class/firmware/iio\:device0\:ram/loading
+
+  # Enable RAM mode
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage140_en
+
+Output Shift Keying (OSK)
+-------------------------
+
+OSK controls the output amplitude envelope, allowing the output to be ramped
+on/off rather than switched abruptly.
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``en``
+     - boolean (0 or 1)
+     - Enable/disable OSK.
+
+   * - ``scale``
+     - fractional
+     - Target amplitude for the OSK ramp. 14-bit ASF field. Range: :math:`[0, 1)`.
+
+   * - ``scale_roc``
+     - 1/s
+     - Amplitude scale rate of change. Writing a non-zero value enables
+       automatic OSK and selects the closest hardware step size. Writing ``0``
+       disables automatic ramping (manual control of the ASF register using
+       ``scale``). Writing the maximum available value enables pin-controlled
+       immediate transition with no ramping.
+
+   * - ``scale_roc_available``
+     - 1/s
+     - Lists the available ``scale_roc`` values based on the current
+       ``sampling_frequency``. The first value is always ``0`` (disabled) and
+       the last value corresponds to pin-controlled immediate mode.
+
+   * - ``sampling_frequency``
+     - Hz
+     - OSK ramp rate. It is controlled by an integer divider so the requested
+       value will adjust to nearest supported value.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Enable OSK with automatic ramping:
+
+.. code-block:: bash
+
+  # Set ramp rate
+  echo 1000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_sampling_frequency
+
+  # Check available rate of change values
+  cat /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale_roc_available
+
+  # Enable automatic OSK with a rate of change
+  echo 61.035000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale_roc
+
+  # Enable OSK
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_en
+
+Enable pin-controlled immediate OSK:
+
+.. code-block:: bash
+
+  # Read the last (highest) available value for pin-controlled mode
+  cat /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale_roc_available
+
+  # Enable OSK in manual mode (no rate of change)
+  echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale_roc
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_en
+
+  # Set target amplitude to full scale
+  echo 1.0 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale
+
+Physical channel
+================
+
+The ``phy`` channel provides device-level control:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``sampling_frequency``
+     - Hz
+     - System clock (SYSCLK) frequency. When the internal PLL is enabled
+       (via the ``adi,pll-enable`` devicetree property), configures the PLL
+       multiplier (range 420--1000 MHz). Without PLL, the reference clock can
+       only be divided by 2.
+
+   * - ``powerdown``
+     - boolean (0 or 1)
+     - Software power-down. Writing 1 powers down the digital core, DAC,
+       reference clock input and auxiliary DAC simultaneously.
+
+Usage examples
+--------------
+
+Set the system clock to 1 GHz:
+
+.. code-block:: bash
+
+  echo 1000000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_sampling_frequency
+
+Read current system clock frequency:
+
+.. code-block:: bash
+
+  cat /sys/bus/iio/devices/iio:device0/out_altvoltage100_sampling_frequency
+
+Power down the device:
+
+.. code-block:: bash
+
+  echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_powerdown
diff --git a/Documentation/iio/index.rst b/Documentation/iio/index.rst
index 007e0a1fcc5a..1ada7b460066 100644
--- a/Documentation/iio/index.rst
+++ b/Documentation/iio/index.rst
@@ -30,6 +30,7 @@ Industrial I/O Kernel Drivers
    ad7606
    ad7625
    ad7944
+   ad9910
    ade9000
    adis16475
    adis16480
diff --git a/MAINTAINERS b/MAINTAINERS
index c39affe4157a..363b7af827c3 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1645,6 +1645,7 @@ S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
+F:	Documentation/iio/ad9910.rst
 F:	drivers/iio/frequency/ad9910.c
 
 ANALOG DEVICES INC MAX22007 DRIVER

-- 
2.43.0

