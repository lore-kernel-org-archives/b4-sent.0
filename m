From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 09 Apr 2026 18:28:27 +0300
Subject: [PATCH v7 6/6] docs: iio: adc: ad4691: add driver documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260409-ad4692-multichannel-sar-adc-driver-v7-6-be375d4df2c5@analog.com>
References: <20260409-ad4692-multichannel-sar-adc-driver-v7-0-be375d4df2c5@analog.com>
In-Reply-To: <20260409-ad4692-multichannel-sar-adc-driver-v7-0-be375d4df2c5@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-doc@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775748505; l=13101;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=IptN2OXLuNKyo/j556/GPrsAWPRNvypfZxc/oV4K/08=;
 b=yxWNyMKAMFayikY2a8aPmPC4cimWIh1kYwt4nLnqEZ9DNF8VoWaaJarr5ZW6UCY0He4TzRChQ
 WrEhManA9QIBRGiv61DldWe7xEDDPeSa9eLlyz8yQ+vSnm6CaUtcPGM
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RST documentation for the AD4691 family ADC driver covering
supported devices, IIO channels, operating modes, oversampling,
reference voltage, LDO supply, reset, GP pins, SPI offload support,
and buffer data format.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 Documentation/iio/ad4691.rst | 283 +++++++++++++++++++++++++++++++++++++++++++
 Documentation/iio/index.rst  |   1 +
 MAINTAINERS                  |   1 +
 3 files changed, 285 insertions(+)

diff --git a/Documentation/iio/ad4691.rst b/Documentation/iio/ad4691.rst
new file mode 100644
index 000000000000..a1012c8b78a3
--- /dev/null
+++ b/Documentation/iio/ad4691.rst
@@ -0,0 +1,283 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+=============
+AD4691 driver
+=============
+
+ADC driver for Analog Devices Inc. AD4691 family of multichannel SAR ADCs.
+The module name is ``ad4691``.
+
+
+Supported devices
+=================
+
+The following chips are supported by this driver:
+
+* `AD4691 <https://www.analog.com/en/products/ad4691.html>`_ — 16-channel, 500 kSPS
+* `AD4692 <https://www.analog.com/en/products/ad4692.html>`_ — 16-channel, 1 MSPS
+* `AD4693 <https://www.analog.com/en/products/ad4693.html>`_ — 8-channel, 500 kSPS
+* `AD4694 <https://www.analog.com/en/products/ad4694.html>`_ — 8-channel, 1 MSPS
+
+
+IIO channels
+============
+
+Each physical ADC input maps to one IIO voltage channel. The AD4691 and AD4692
+expose 16 channels (``voltage0`` through ``voltage15``); the AD4693 and AD4694
+expose 8 channels (``voltage0`` through ``voltage7``).
+
+All channels share a common scale (``in_voltage_scale``), derived from the
+reference voltage. Each channel independently exposes:
+
+* ``in_voltageN_raw`` — single-shot ADC result
+* ``in_voltageN_sampling_frequency`` — per-channel effective conversion rate.
+  In CNV Burst Mode this equals the internal oscillator frequency divided by
+  the channel's oversampling ratio. In Manual Mode (where oversampling is not
+  supported) it equals the oscillator frequency directly.
+* ``in_voltageN_sampling_frequency_available`` — list of valid oscillator
+  frequencies
+
+The following attributes are only available in CNV Burst Mode:
+
+* ``in_voltageN_oversampling_ratio`` — per-channel hardware accumulation depth
+* ``in_voltageN_oversampling_ratio_available`` — list of valid ratios: 1, 2, 4,
+  8, 16, 32
+
+
+Operating modes
+===============
+
+The driver supports two operating modes, auto-detected from the device tree at
+probe time. Both modes transition to and from an internal Autonomous Mode idle
+state when the IIO buffer is enabled and disabled.
+
+Manual Mode
+-----------
+
+Selected when no ``pwms`` property is present in the device tree. The CNV pin
+is tied to the SPI chip-select: every CS assertion both triggers a new
+conversion and returns the result of the previous one (pipelined N+1 scheme).
+
+To read N channels the driver issues N+1 SPI transfers in a single optimised
+message:
+
+* Transfers 0 to N-1 each carry ``AD4691_ADC_CHAN(n)`` in the TX byte to
+  select the next channel; the RX byte of transfer ``k+1`` contains the result
+  of the channel selected in transfer ``k``.
+* Transfer N is a NOOP (0x00) to flush the last conversion result out of the
+  pipeline.
+
+A user-defined IIO trigger (e.g. hrtimer trigger) drives the trigger handler,
+which executes the pre-built SPI message and pushes the scan to the buffer.
+
+Oversampling is not supported in Manual Mode.
+
+CNV Burst Mode
+--------------
+
+Selected when a ``pwms`` property is present in the device tree. The PWM drives
+the CNV pin independently of SPI at the configured conversion rate, and a GP
+pin (identified by ``interrupt-names``) asserts DATA_READY at end-of-burst to
+signal that the AVG_IN result registers are ready to be read.
+
+The IRQ handler fires the IIO trigger without stopping the PWM, then disables
+itself to prevent a second DATA_READY assertion while the trigger handler is
+running. The trigger handler reads all active ``AVG_IN(n)`` registers in a
+single optimised SPI message, pushes the scan to the buffer, and re-enables
+the IRQ.
+
+The buffer sampling frequency (i.e. the PWM rate) is controlled by the
+``sampling_frequency`` attribute on the IIO buffer. Valid values span from the
+chip's minimum oscillator rate up to its maximum conversion rate (500 kSPS for
+AD4691/AD4693, 1 MSPS for AD4692/AD4694). In practice, without SPI offload,
+the SPI read overhead between DATA_READY and the start of the next PWM period
+limits the achievable rate; the PWM frequency should be set low enough to
+accommodate the SPI transfer time.
+
+Autonomous Mode (idle / single-shot)
+-------------------------------------
+
+The chip idles in Autonomous Mode whenever the IIO buffer is disabled. In this
+state, ``read_raw`` requests (``in_voltageN_raw``) use the internal oscillator
+to perform a single conversion on the requested channel and read back the
+result from the ``AVG_IN(N)`` register. The oscillator is started and stopped
+for each read to save power.
+
+
+Oversampling
+============
+
+In CNV Burst Mode each channel has an independent hardware accumulator
+(ACC_DEPTH_IN) that averages a configurable number of successive conversions
+before DATA_READY asserts. The result is always returned as a 16-bit mean from
+the ``AVG_IN`` register, so the IIO ``realbits`` and ``storagebits`` are
+unaffected by the oversampling ratio.
+
+Valid ratios are 1, 2, 4, 8, 16 and 32. The default is 1 (no averaging).
+Oversampling is not supported in Manual Mode.
+
+.. code-block:: bash
+
+    # Set oversampling ratio to 16 on channel 0
+    echo 16 > /sys/bus/iio/devices/iio:device0/in_voltage0_oversampling_ratio
+
+When OSR > 1 the effective conversion rate reported by
+``in_voltageN_sampling_frequency`` and used for ``read_raw`` is reduced
+accordingly, since each output sample requires OSR successive conversions.
+
+
+Reference voltage
+=================
+
+The driver supports two reference configurations, mutually exclusive:
+
+* **External reference** (``ref-supply``): a voltage between 2.4 V and 5.25 V
+  supplied externally. The internal reference buffer is disabled.
+* **Buffered internal reference** (``refin-supply``): An internal reference
+  buffer is used. The driver enables ``REFBUF_EN`` in the REF_CTRL register
+  when this supply is used.
+
+Exactly one of ``ref-supply`` or ``refin-supply`` must be present in the
+device tree.
+
+The reference voltage determines the full-scale range:
+
+.. code-block::
+
+    full-scale = Vref / 2^16  (per LSB)
+
+
+LDO supply
+==========
+
+The chip contains an internal LDO that powers part of the analog front-end.
+The LDO input can be driven externally via the ``ldo-in-supply`` regulator. If
+that supply is absent, the driver enables the internal LDO path (``LDO_EN``
+bit in DEVICE_SETUP).
+
+
+Reset
+=====
+
+The driver supports two reset mechanisms:
+
+* **Hardware reset** (``reset-gpios`` in device tree): the GPIO is already
+  asserted at driver probe by the reset controller framework. The driver waits
+  for the required 300 µs reset pulse width and then deasserts.
+* **Software reset** (fallback when ``reset-gpios`` is absent): the driver
+  writes the software-reset pattern to the SPI_CONFIG_A register.
+
+
+GP pins and interrupts
+======================
+
+The chip exposes up to four general-purpose (GP) pins that can be configured as
+interrupt or trigger-source outputs. In CNV Burst Mode (non-offload), one GP
+pin must be wired to an interrupt-capable SoC input and declared in the device
+tree using the ``interrupts`` and ``interrupt-names`` properties.
+
+The ``interrupt-names`` value identifies which GP pin is used (``"gp0"``
+through ``"gp3"``). The driver configures that pin as a DATA_READY output in
+the GPIO_MODE register.
+
+Example device tree fragment::
+
+    adc@0 {
+        compatible = "adi,ad4692";
+        ...
+        interrupts = <17 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-parent = <&gpio0>;
+        interrupt-names = "gp0";
+    };
+
+
+SPI offload support
+===================
+
+When a SPI offload engine (e.g. the AXI SPI Engine) is present, the driver
+uses DMA-backed transfers for CPU-independent, high-throughput data capture.
+SPI offload is detected automatically at probe via ``devm_spi_offload_get()``;
+if no offload hardware is available the driver falls back to the software
+triggered-buffer path.
+
+Two SPI offload sub-modes exist, corresponding to the two operating modes:
+
+CNV Burst offload
+-----------------
+
+Used when a ``pwms`` property is present and SPI offload is available.
+
+The PWM drives CNV at the configured rate. On DATA_READY the SPI offload
+engine automatically executes a pre-built message that reads all active
+``AVG_IN`` registers and streams the data directly to an IIO DMA buffer with
+no CPU involvement. A final state-reset transfer re-arms DATA_READY for the
+next burst.
+
+The GP pin used as DATA_READY trigger is supplied by the trigger-source
+consumer (via ``#trigger-source-cells``) at buffer enable time; no
+``interrupt-names`` entry is required in this path.
+
+The buffer sampling frequency is controlled by the ``sampling_frequency``
+attribute on the IIO buffer (same as the non-offload CNV Burst path).
+
+Manual offload
+--------------
+
+Used when no ``pwms`` property is present and SPI offload is available.
+
+A periodic SPI offload trigger controls the conversion rate. On each trigger
+period, the SPI engine executes an N+1 transfer message (same pipelined scheme
+as software Manual Mode) and streams the 16-bit ADC results directly to the
+IIO DMA buffer. Each transfer sends a 16-bit TX word (channel command byte in
+the upper byte, zero in the lower byte); the chip returns the 16-bit ADC
+result on MISO. The first transfer's RX is discarded (pipeline flush); results
+from transfers 1 through N are streamed to the DMA buffer.
+
+The ``sampling_frequency`` attribute on the IIO buffer controls the trigger
+rate (in Hz). The initial rate is 100 kHz — a conservative default chosen
+because the N+1 SPI transfer overhead in this mode limits the achievable rate
+relative to the chip's maximum conversion rate.
+
+Oversampling is not supported in Manual Mode.
+
+
+Buffer data format
+==================
+
+The IIO buffer data format (``in_voltageN_type``) is the same across all
+paths: 16-bit unsigned big-endian samples with no shift.
+
++-------------------------+-------------+----------+-------+
+| Path                    | storagebits | realbits | shift |
++=========================+=============+==========+=======+
+| Triggered buffer        | 16          | 16       | 0     |
++-------------------------+-------------+----------+-------+
+| CNV Burst offload (DMA) | 16          | 16       | 0     |
++-------------------------+-------------+----------+-------+
+| Manual offload (DMA)    | 16          | 16       | 0     |
++-------------------------+-------------+----------+-------+
+
+In the triggered-buffer path the SPI rx_buf for each transfer points directly
+into the scan buffer, so the 16-bit big-endian result is written in place with
+no additional copying.
+
+In the DMA offload paths the SPI offload engine streams 16-bit words (one per
+active channel) directly into the IIO DMA buffer:
+
+* **CNV Burst offload**: each channel read uses a 16-bit address phase followed
+  by a 16-bit data phase; only the data phase is flagged for DMA streaming, so
+  the 16-bit result lands directly in the buffer.
+* **Manual offload**: each 16-bit SPI transfer carries the channel command on
+  TX and receives the 16-bit ADC result on RX; results are streamed to the
+  DMA buffer one 16-bit word per channel.
+
+The ``in_voltageN_type`` sysfs attribute reflects the active scan type.
+
+
+Unimplemented features
+======================
+
+* GPIO controller functionality of the GP pins
+* Clamp status and overrange events
+* Raw accumulator (ACC_IN) and accumulator status registers
+* ADC_BUSY and overrun status interrupts
diff --git a/Documentation/iio/index.rst b/Documentation/iio/index.rst
index ba3e609c6a13..007e0a1fcc5a 100644
--- a/Documentation/iio/index.rst
+++ b/Documentation/iio/index.rst
@@ -23,6 +23,7 @@ Industrial I/O Kernel Drivers
    ad4000
    ad4030
    ad4062
+   ad4691
    ad4695
    ad7191
    ad7380
diff --git a/MAINTAINERS b/MAINTAINERS
index 24e4502b8292..819d8b6eb6bb 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1491,6 +1491,7 @@ S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
 F:	drivers/iio/adc/ad4691.c
+F:	drivers/iio/adc/ad4691.rst
 
 ANALOG DEVICES INC AD4695 DRIVER
 M:	Michael Hennerich <michael.hennerich@analog.com>

-- 
2.43.0

