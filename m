From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 18 Mar 2026 17:56:09 +0000
Subject: [PATCH RFC v2 9/9] docs: iio: add documentation for ad9910 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-ad9910-iio-driver-v2-9-e79f93becf11@analog.com>
References: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
In-Reply-To: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=21400;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=CD1yxulQBdjCdan4eY1kiOcKuvikV8SBaM67bnyl/XA=;
 b=/flYDKSK2fJCsml/JLxLVY/6iVZJv+YXX/UuLX3aeSu8FtXnynxB3CVSqXZ0eSIVJQP4GaJVZ
 ET9auFwWK3fAoXDKNCEyew33ILpdmUq6SdNaBY7BTzvFMrxaUshnIf4
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the AD9910 DDS IIO driver, which describes channels,
DDS modes, attributes and ABI usage examples.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/iio/ad9910.rst | 654 +++++++++++++++++++++++++++++++++++++++++++
 Documentation/iio/index.rst  |   1 +
 MAINTAINERS                  |   1 +
 3 files changed, 656 insertions(+)

diff --git a/Documentation/iio/ad9910.rst b/Documentation/iio/ad9910.rst
new file mode 100644
index 000000000000..116f6af4bc2e
--- /dev/null
+++ b/Documentation/iio/ad9910.rst
@@ -0,0 +1,654 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+=============
+AD9910 driver
+=============
+
+DDS (Direct Digital Synthesizer) driver for the Analog Devices Inc. AD9910.
+The module name is ``ad9910``.
+
+* `AD9910 <https://www.analog.com/en/products/ad9910.html>`_
+
+The AD9910 is a 1 GSPS DDS with a 14-bit DAC, driven over SPI. The driver
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
+unique channel number and a human-readable label:
+
+* ``out_altvoltage100``: ``phy``: Physical output: system clock and profile control
+
+  * ``out_altvoltage110``: ``single_tone``: Single tone mode: per-profile
+    frequency, phase, amplitude
+
+  * ``out_altvoltage120``: ``parallel_port``: Parallel port modulation: enable
+    and offset/scale parameters
+
+  * ``out_altvoltage130``: ``digital_ramp_generator``: DRG control: enable,
+    destination, operating mode
+
+    * ``out_altvoltage131``: ``digital_ramp_up``: DRG ramp-up parameters:
+      limits, step sizes, ramp rate
+    * ``out_altvoltage132``: ``digital_ramp_down``: DRG ramp-down parameters:
+      limits, step sizes, ramp rate
+
+  * ``out_altvoltage140``: ``ram_control``: RAM playback: enable, destination,
+    operating mode, address range
+
+  * ``out_altvoltage150``: ``output_shift_keying``: OSK: enable, amplitude
+    scale, ramp rate, auto/manual control
+
+The ``phy`` channel is the root of the hierarchy. Changing its
+``sampling_frequency`` reconfigures the system clock (SYSCLK) which affects all
+other channels. The ``profile`` attribute on this channel selects the active
+hardware profile (0-7) used by the single tone and RAM channels.
+
+All mode-specific channels (parallel port, DRG, RAM, OSK) have an ``enable``
+attribute. The DRG and RAM channels additionally have ``destination`` and
+``operating_mode`` attributes that configure which DDS core parameter is
+modulated and how.
+
+DDS modes
+=========
+
+The AD9910 supports multiple modes of operation that can be configured
+independently or in combination. Such modes and their corresponding IIO channels
+are described in this section. The following tables are extracted from the
+AD9910 datasheet and summarizes the control parameters for each mode and their
+priority when multiple sources are enabled simultaneously:
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
+     - Parallel data and FTW (frequency_offset)
+     - Parallel data port enabled and data destination is frequency
+
+   * -
+     - FTW (frequency)
+     - RAM enabled and data destination is not frequency
+
+   * -
+     - FTW (frequency) in single tone channel for the active profile
+     - DRG enabled and data destination is not frequency
+
+   * -
+     - FTW (frequency) in single tone channel for the active profile
+     - Parallel data port enabled and data destination is not frequency
+
+   * - Lowest Priority
+     - FTW (frequency) in single tone channel for the active profile
+     - None
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
+     - Parallel data port and POW register LSBs (phase_offset)
+     - Parallel data port enabled and data destination is polar
+
+   * -
+     - POW (phase)
+     - RAM enabled and destination is not phase nor polar
+
+   * -
+     - POW (phase) in single tone channel for the active profile
+     - DRG enabled and data destination is not phase
+
+   * -
+     - POW (phase) in single tone channel for the active profile
+     - Parallel data port enabled and data destination is not phase nor polar
+
+   * - Lowest Priority
+     - POW (phase) in single tone channel for the active profile
+     - None
+
+.. flat-table:: DDS Amplitude Control
+   :header-rows: 1
+
+   * - Priority
+     - Data Source
+     - Conditions
+
+   * - Highest Priority
+     - OSK generator
+     - OSK enabled (auto mode)
+
+   * -
+     - ASF register
+     - OSK enabled (manual mode)
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
+Single tone mode
+----------------
+
+Single tone is the baseline operating mode. The ``single_tone`` channel
+provides per-profile frequency, phase and amplitude control:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``out_altvoltage110_frequency``
+     - Hz
+     - Output frequency. Range [0, SYSCLK/2). Stored in the active profile's
+       frequency tuning word (FTW).
+
+   * - ``out_altvoltage110_phase``
+     - rad
+     - Phase offset. Range [0, 2*pi). Stored in the active profile's phase
+       offset word (POW).
+
+   * - ``out_altvoltage110_scale``
+     - fractional
+     - Amplitude scale factor. Range [0, 1]. Stored in the active profile's
+       amplitude scale factor (ASF).
+
+When RAM mode is enabled, single tone parameters are stored in a shadow
+register and are not written to hardware until RAM mode is disabled.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Set the active profile to 2 and configure a 100 MHz tone:
+
+.. code-block:: bash
+
+	echo 2 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_profile
+	echo 100000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage110_frequency
+	echo 0.5 > /sys/bus/iio/devices/iio:device0/out_altvoltage110_scale
+	echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage110_phase
+
+Read back the current single tone frequency:
+
+.. code-block:: bash
+
+	cat /sys/bus/iio/devices/iio:device0/out_altvoltage110_frequency
+
+Parallel port mode
+------------------
+
+When enabled, the parallel port allows real-time modulation of DDS parameters
+through a 16-bit external data bus.
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``out_altvoltage120_en``
+     - boolean
+     - Enable/disable the parallel data port.
+
+   * - ``out_altvoltage120_frequency_scale``
+     - power-of-2
+     - FM gain multiplier applied to 16-bit parallel input. Range [1, 32768],
+       must be a power of 2.
+
+   * - ``out_altvoltage120_frequency_offset``
+     - Hz
+     - Base FTW to which scaled parallel data is added. Range [0, SYSCLK/2).
+
+   * - ``out_altvoltage120_phase_offset``
+     - rad
+     - Base phase for polar modulation. Lower 8 bits of POW register.
+       Range [0, 2*pi/256).
+
+   * - ``out_altvoltage120_scale_offset``
+     - fractional
+     - Base amplitude for polar modulation. Lower 6 bits of ASF register.
+       Range [0, 1/256).
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Enable parallel port with a frequency scale of 16 and a 50 MHz offset:
+
+.. code-block:: bash
+
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage120_en
+	echo 16 > /sys/bus/iio/devices/iio:device0/out_altvoltage120_frequency_scale
+	echo 50000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage120_frequency_offset
+
+Digital ramp generator (DRG)
+----------------------------
+
+The DRG produces linear frequency, phase or amplitude sweeps using dedicated
+hardware. It is controlled through three channels: a parent control channel
+(``digital_ramp_generator``) and two child ramp channels
+(``digital_ramp_up``, ``digital_ramp_down``).
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
+   * - ``out_altvoltage130_en``
+     - boolean
+     - Enable/disable the DRG.
+
+   * - ``out_altvoltage130_destination``
+     - enum
+     - Which DDS parameter is swept: ``frequency``, ``phase`` or
+       ``amplitude``.
+
+   * - ``out_altvoltage130_destination_available``
+     - string
+     - Lists available destination values.
+
+   * - ``out_altvoltage130_operating_mode``
+     - enum
+     - Ramp behavior (see table below).
+
+   * - ``out_altvoltage130_operating_mode_available``
+     - string
+     - Lists available operating mode values.
+
+DRG operating modes:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Mode
+     - Description
+
+   * - ``bidirectional``
+     - Ramp up then down, dwelling at limits.
+
+   * - ``ramp_down``
+     - No-dwell low; resets to upper limit at lower limit.
+
+   * - ``ramp_up``
+     - No-dwell high; resets to lower limit at upper limit.
+
+   * - ``bidirectional_continuous``
+     - Continuous sweep without dwelling at either limit.
+
+Ramp channel attributes
+^^^^^^^^^^^^^^^^^^^^^^^^
+
+The ``digital_ramp_up`` (channel 131) and ``digital_ramp_down`` (channel 132)
+channels share the same attribute set but configure ascending and descending
+ramp parameters independently:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Attribute
+     - Unit
+     - Description
+
+   * - ``frequency``
+     - Hz
+     - Ramp limit when destination is ``frequency``. Range [0, SYSCLK/2).
+
+   * - ``phase``
+     - rad
+     - Ramp limit when destination is ``phase``. Range [0, 2*pi).
+
+   * - ``scale``
+     - fractional
+     - Ramp limit when destination is ``amplitude``. Range [0, 1).
+
+   * - ``sampling_frequency``
+     - Hz
+     - Ramp clock rate: SYSCLK / (4 * divider).
+
+   * - ``frequency_step``
+     - Hz
+     - Per-tick frequency increment/decrement when destination is
+       ``frequency``.
+
+   * - ``phase_step``
+     - rad
+     - Per-tick phase increment/decrement when destination is ``phase``.
+
+   * - ``scale_step``
+     - fractional
+     - Per-tick amplitude increment/decrement when destination is
+       ``amplitude``. Range [0, 1).
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Configure a frequency sweep from 10 MHz to 100 MHz at a 1 MHz step:
+
+.. code-block:: bash
+
+	# Set DRG destination to frequency
+	echo frequency > /sys/bus/iio/devices/iio:device0/out_altvoltage130_destination
+
+	# Set operating mode
+	echo bidirectional_continuous > /sys/bus/iio/devices/iio:device0/out_altvoltage130_operating_mode
+
+	# Set ramp limits
+	echo 60000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_frequency
+	echo 40000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_frequency
+
+	# Set ramp step size to 1 MHz
+	echo 1000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_frequency_step
+	echo 1000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage132_frequency_step
+
+	# Set ramp clock rate
+	echo 50000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage131_sampling_frequency
+
+	# Enable the DRG
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage130_en
+
+Read the current DRG operating mode:
+
+.. code-block:: bash
+
+	cat /sys/bus/iio/devices/iio:device0/out_altvoltage130_operating_mode
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
+   * - ``out_altvoltage140_en``
+     - boolean
+     - Enable/disable RAM playback. Toggling swaps profile registers between
+       single tone and RAM configurations across all 8 profiles.
+
+   * - ``out_altvoltage140_destination``
+     - enum
+     - RAM data target: ``frequency``, ``phase``, ``amplitude`` or ``polar``.
+       Cannot be changed while RAM mode is enabled.
+
+   * - ``out_altvoltage140_destination_available``
+     - string
+     - Lists available destination values.
+
+   * - ``out_altvoltage140_operating_mode``
+     - enum
+     - Playback behavior (see table below).
+
+   * - ``out_altvoltage140_operating_mode_available``
+     - string
+     - Lists available operating mode values.
+
+   * - ``out_altvoltage140_frequency``
+     - Hz
+     - Frequency tuning word used as the single tone frequency when
+       RAM destination is not ``frequency``. Range [0, SYSCLK/2).
+
+   * - ``out_altvoltage140_phase``
+     - rad
+     - Phase offset word used as the single tone phase when RAM destination
+       is not ``phase``. Range [0, 2*pi).
+
+   * - ``out_altvoltage140_sampling_frequency``
+     - Hz
+     - RAM playback step rate controlling how fast the address counter
+       advances: SYSCLK / (4 * step_rate). Stored per-profile.
+
+   * - ``out_altvoltage140_address_start``
+     - integer
+     - Start address for the active profile. Range [0, 1023]. Cannot be
+       changed while RAM mode is enabled. If set above current end address,
+       end address is automatically adjusted.
+
+   * - ``out_altvoltage140_address_end``
+     - integer
+     - End address for the active profile. Range [address_start, 1023].
+       Cannot be changed while RAM mode is enabled.
+
+RAM operating modes:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Mode
+     - Description
+
+   * - ``direct_switch``
+     - Start address defines a fixed word used by the selected profile.
+
+   * - ``ramp_up``
+     - One-shot ramp through the current profile's address range.
+
+   * - ``bidirectional``
+     - Ramp up then down through profile 0's address range.
+
+   * - ``bidirectional_continuous``
+     - Continuous ramp up/down through current profile's address range.
+
+   * - ``ramp_up_continuous``
+     - Continuous ramp up through current profile's address range.
+
+   * - ``sequenced``
+     - Sequential playback from profile 0 to the active profile.
+       Requires active profile > 0.
+
+   * - ``sequenced_continuous``
+     - Continuous sequential playback. Requires active profile > 0.
+
+Loading RAM data
+^^^^^^^^^^^^^^^^
+
+RAM data is loaded through the firmware upload framework. The driver registers
+a firmware upload device named ``iio_deviceX:ram``. Data must be a multiple of
+4 bytes (32-bit words) and at most 4096 bytes (1024 words).
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Configure RAM mode with frequency destination and load a waveform:
+
+.. code-block:: bash
+
+	# Set RAM address range for profile 0
+	echo 0 > /sys/bus/iio/devices/iio:device0/out_altvoltage140_address_start
+	echo 999 > /sys/bus/iio/devices/iio:device0/out_altvoltage140_address_end
+
+	# Set destination and operating mode
+	echo frequency > /sys/bus/iio/devices/iio:device0/out_altvoltage140_destination
+	echo ramp_up_continuous > /sys/bus/iio/devices/iio:device0/out_altvoltage140_operating_mode
+
+	# Set playback rate
+	echo 250000 > /sys/bus/iio/devices/iio:device0/out_altvoltage140_sampling_frequency
+
+	# Load RAM data via firmware upload
+	echo 1 > /sys/class/firmware/iio\:device0\:ram/loading
+	cat waveform.bin > /sys/class/firmware/iio\:device0\:ram/data
+	echo 0 > /sys/class/firmware/iio\:device0\:ram/loading
+
+	# Enable RAM mode
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage140_en
+
+Read the current RAM operating mode:
+
+.. code-block:: bash
+
+	cat /sys/bus/iio/devices/iio:device0/out_altvoltage140_operating_mode
+
+Output shift keying (OSK)
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
+   * - ``out_altvoltage150_en``
+     - boolean
+     - Enable/disable OSK.
+
+   * - ``out_altvoltage150_scale``
+     - fractional
+     - Target amplitude for the OSK ramp. 14-bit ASF field. Range [0, 1).
+
+   * - ``out_altvoltage150_sampling_frequency``
+     - Hz
+     - OSK ramp rate: SYSCLK / (4 * divider).
+
+   * - ``out_altvoltage150_pinctrl_en``
+     - boolean
+     - Enable manual external pin control. When enabled, the OSK pin directly
+       gates the output on/off instead of using the automatic ramp.
+
+   * - ``out_altvoltage150_scale_step``
+     - fractional
+     - Automatic OSK amplitude step. Writing non-zero enables automatic OSK
+       and sets the per-tick increment. Writing ``0`` disables it. Rounded to
+       nearest hardware step: 0.000061, 0.000122, 0.000244 or 0.000488.
+
+Usage examples
+^^^^^^^^^^^^^^
+
+Enable OSK with automatic ramping:
+
+.. code-block:: bash
+
+	# Set ramp rate
+	echo 1000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_sampling_frequency
+
+	# Enable automatic OSK with step size
+	echo 0.000244 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale_step
+
+	# Enable OSK
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_en
+
+Enable manual pin-controlled OSK:
+
+.. code-block:: bash
+
+	# Set target amplitude to full scale
+	echo 1.0 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_scale
+
+	# Enable manual pin control
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_pinctrl_en
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage150_en
+
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
+   * - ``out_altvoltage100_sampling_frequency``
+     - Hz
+     - System clock (SYSCLK) frequency. With PLL enabled, configures the PLL
+       multiplier (range 420-1000 MHz). Without PLL, ref clock can only be
+       divided by 2.
+
+   * - ``out_altvoltage100_profile``
+     - integer
+     - Active profile index [0, 7]. Selected via GPIO pins. Each profile
+       stores an independent set of single tone and RAM playback parameters.
+
+   * - ``out_altvoltage100_powerdown``
+     - boolean
+     - Software power-down. Writing 1 powers down the digital core, DAC,
+       reference clock input and auxiliary DAC simultaneously.
+
+Usage examples
+--------------
+
+Set the system clock to 1 GHz and select profile 3:
+
+.. code-block:: bash
+
+	echo 1000000000 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_sampling_frequency
+	echo 3 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_profile
+
+Read current system clock frequency:
+
+.. code-block:: bash
+
+	cat /sys/bus/iio/devices/iio:device0/out_altvoltage100_sampling_frequency
+
+Power down the device:
+
+.. code-block:: bash
+
+	echo 1 > /sys/bus/iio/devices/iio:device0/out_altvoltage100_powerdown
diff --git a/Documentation/iio/index.rst b/Documentation/iio/index.rst
index ba3e609c6a13..55cb1ce84ba8 100644
--- a/Documentation/iio/index.rst
+++ b/Documentation/iio/index.rst
@@ -29,6 +29,7 @@ Industrial I/O Kernel Drivers
    ad7606
    ad7625
    ad7944
+   ad9910
    ade9000
    adis16475
    adis16480
diff --git a/MAINTAINERS b/MAINTAINERS
index edd87ee7da5f..14e4272357ce 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1637,6 +1637,7 @@ S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
+F:	Documentation/iio/ad9910.rst
 F:	drivers/iio/frequency/ad9910.c
 
 ANALOG DEVICES INC MAX22007 DRIVER

-- 
2.43.0

