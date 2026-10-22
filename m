From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 22 Oct 2026 12:19:08 -0300
Subject: [PATCH v2 10/10] docs: iio: ad9910: document DRCTL pin control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-ad9910-backend-support-v2-10-0ff7f0bff326@analog.com>
References: <20261022-ad9910-backend-support-v2-0-0ff7f0bff326@analog.com>
In-Reply-To: <20261022-ad9910-backend-support-v2-0-0ff7f0bff326@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792682347; l=6219;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=9AdEqIZ+bYqk9Lw6P7OuqM0LPTI0z5xHBJLcZX+ImKY=;
 b=uXb3PIln3CqI5BQMvSFeUzmQlLZ1I31Q5FdLc+gCuiqatzRl2MJl5j89dMPyZZ2mimGOwRjBy
 HED3yDG8d7YByxQfFGWKiPN+Wp+AtN+j4n5YOh7bgHJBjxBBepXlNJT
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the integration_time attribute of the digital ramp generator
(DRG) rising and falling channels, and describe how the DRCTL pin
waveform is generated from those values according to the dwell_en
configuration. Add usage examples for triangular and sawtooth sweeps
driven through the DRCTL pin.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/iio/ad9910.rst | 90 +++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 84 insertions(+), 6 deletions(-)

diff --git a/Documentation/iio/ad9910.rst b/Documentation/iio/ad9910.rst
index aab569f561db..bff55cca8c82 100644
--- a/Documentation/iio/ad9910.rst
+++ b/Documentation/iio/ad9910.rst
@@ -85,13 +85,13 @@ system clock (SYSCLK) which affects all other channels.
      - ``drg_rising_frequency``
      - ``drg_frequency``
      - DRG frequency rising-ramp parameters: limit code, dwell enable,
-       ramp clock, rate of change.
+       ramp clock, rate of change, integration time.
 
    * - ``out_frequency132``
      - ``drg_falling_frequency``
      - ``drg_frequency``
      - DRG frequency falling-ramp parameters: limit code, dwell enable,
-       ramp clock, rate of change.
+       ramp clock, rate of change, integration time.
 
    * - ``out_phase130``
      - ``drg_phase``
@@ -104,13 +104,13 @@ system clock (SYSCLK) which affects all other channels.
      - ``drg_rising_phase``
      - ``drg_phase``
      - DRG phase rising-ramp parameters: limit code, dwell enable, ramp clock,
-       rate of change.
+       rate of change, integration time.
 
    * - ``out_phase132``
      - ``drg_falling_phase``
      - ``drg_phase``
      - DRG phase falling-ramp parameters: limit code, dwell enable, ramp clock,
-       rate of change.
+       rate of change, integration time.
 
    * - ``out_altcurrent130``
      - ``drg_amplitude``
@@ -123,13 +123,13 @@ system clock (SYSCLK) which affects all other channels.
      - ``drg_rising_amplitude``
      - ``drg_amplitude``
      - DRG amplitude rising-ramp parameters: limit code, dwell enable,
-       ramp clock, rate of change.
+       ramp clock, rate of change, integration time.
 
    * - ``out_altcurrent132``
      - ``drg_falling_amplitude``
      - ``drg_amplitude``
      - DRG amplitude falling-ramp parameters: limit code, dwell enable,
-       ramp clock, rate of change.
+       ramp clock, rate of change, integration time.
 
    * - ``out_altcurrent140``
      - ``ram``
@@ -493,6 +493,60 @@ Ramp channel attributes
        from the hardware step size and the current ramp clock. Writing
        requires ``sampling_frequency`` to be configured first.
 
+   * - ``integration_time``
+     - s
+     - Time interval assigned to the ramp direction, which is used to generate
+       the DRCTL pin waveform. See `DRCTL pin control`_. Rising and falling
+       ramp channels of all destinations share the same underlying value for
+       their respective directions. The written value is adjusted to the
+       resolution supported by the PWM provider.
+
+DRCTL pin control
+^^^^^^^^^^^^^^^^^
+
+The DRCTL pin selects the DRG slope direction: a logic high drives the ramp
+towards the upper limit and a logic low drives it towards the lower limit.
+When a PWM is assigned to the DRCTL pin (via the ``pwms`` and ``pwm-names``
+devicetree properties), the driver generates the DRCTL waveform from the
+``integration_time`` of the rising and falling ramp channels, according to the
+``dwell_en`` configuration:
+
+.. flat-table::
+   :header-rows: 1
+
+   * - Rising ``dwell_en``
+     - Falling ``dwell_en``
+     - DRCTL waveform
+
+   * - 1
+     - 1
+     - DRCTL is held high for the rising ``integration_time`` and then held
+       low for the falling ``integration_time``. The PWM period is the sum of
+       both intervals. If a ramp reaches its limit before its interval
+       elapses, the output dwells at that limit.
+
+   * - 0
+     - 1
+     - Sawtooth rising ramp: a new ramp starts at every DRCTL rising edge,
+       which happens periodically at the rising ``integration_time``. The
+       falling ``integration_time`` is not used.
+
+   * - 1
+     - 0
+     - Sawtooth falling ramp: a new ramp starts at every DRCTL falling edge,
+       which happens periodically at the falling ``integration_time``. The
+       rising ``integration_time`` is not used.
+
+   * - 0
+     - 0
+     - Bidirectional continuous ramp. DRCTL is not relevant and it is held
+       low.
+
+The DRCTL output is disabled when the resulting PWM period is zero, e.g., when
+the relevant ``integration_time`` attributes are set to ``0``. Without a PWM
+assigned to the DRCTL pin, writing to ``integration_time`` fails with
+``-EOPNOTSUPP``.
+
 Usage examples
 ^^^^^^^^^^^^^^
 
@@ -525,6 +579,30 @@ Configure a frequency sweep from 40 MHz to 60 MHz with a rate of change of
   # Enable the DRG with frequency as the destination
   echo 1 > /sys/bus/iio/devices/iio\:device0/out_frequency130_en
 
+With the same limits and rate of change, each ramp takes 0.8 ms to complete.
+Configure a PWM-driven triangular sweep that dwells 0.2 ms at each limit:
+
+.. code-block:: bash
+
+  # Enable dwell on both limits, so DRCTL controls the ramp direction
+  echo 1 > /sys/bus/iio/devices/iio\:device0/out_frequency131_dwell_en
+  echo 1 > /sys/bus/iio/devices/iio\:device0/out_frequency132_dwell_en
+
+  # DRCTL high for 1 ms (rising ramp) and low for 1 ms (falling ramp)
+  echo 0.001 > /sys/bus/iio/devices/iio\:device0/out_frequency131_integration_time
+  echo 0.001 > /sys/bus/iio/devices/iio\:device0/out_frequency132_integration_time
+
+Configure a rising sawtooth sweep that restarts every 1 ms:
+
+.. code-block:: bash
+
+  # No dwell at the upper limit: the ramp returns to the lower limit
+  echo 0 > /sys/bus/iio/devices/iio\:device0/out_frequency131_dwell_en
+  echo 1 > /sys/bus/iio/devices/iio\:device0/out_frequency132_dwell_en
+
+  # A new rising ramp starts every 1 ms
+  echo 0.001 > /sys/bus/iio/devices/iio\:device0/out_frequency131_integration_time
+
 RAM mode
 --------
 

-- 
2.43.0

