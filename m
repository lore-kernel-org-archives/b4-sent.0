From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 18 Mar 2026 17:56:08 +0000
Subject: [PATCH RFC v2 8/9] Documentation: ABI: testing: add docs for
 ad9910 sysfs entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-ad9910-iio-driver-v2-8-e79f93becf11@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=8935;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=grE302iWPE70mi8jjbpmGZcg9LSvpB2JPaUzLTUV+HI=;
 b=4S3+/9p2pi1E/72fi89NhStl1mRsm4xZHHoShdJWnXAIN0qbW1Woqpy9qfQff50dOtrZrJYFl
 su20URI42/VDksqZ62SnIhxlBzzH5j+KXeaemkyIzbAuVZFn9ecel06
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ABI documentation file for the DDS AD9910 with sysfs entries to
control Parallel Port, Digital Ramp Generator, RAM and OSK parameters.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     | 182 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 183 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910 b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
new file mode 100644
index 000000000000..120de494f6b1
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
@@ -0,0 +1,182 @@
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_profile
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the active profile index [0, 7] from/to the physical
+		channel. The AD9910 supports 8 profiles, each storing a complete
+		set of single tone (frequency, phase, amplitude) and RAM playback
+		parameters.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the parallel port frequency offset in Hz. This is the
+		base frequency tuning word (FTW register) to which the scaled
+		parallel port data is added during parallel data port modulation.
+		Valid range is [0, SYSCLK/2).
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_scale
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the parallel port frequency modulation gain. The value
+		must be a power of 2 in the [1, 2^15] range. This value scales the
+		16-bit parallel data port input before adding it to the
+		frequency_offset value.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the parallel port phase offset in radians. Valid range
+		is [0, 2*pi/256). This sets the lower 8 bits of the phase offset
+		word (POW register) used as a base during parallel port polar
+		modulation.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the parallel port amplitude scale offset. Valid range
+		is [0, 1/256). This sets the lower 6 bits of the amplitude scale
+		factor (ASF register) used as a base during parallel port polar
+		modulation.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_destination
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the digital ramp generator (DRG) or the RAM control
+		destination parameter. Determines which DDS core parameter is to
+		be modulated when the child mode channel is enabled.
+
+		Available values can be read from the corresponding
+		out_altvoltageY_destination_available attribute.
+
+		Valid values: "polar" (only for RAM control), "frequency", "phase"
+		and "amplitude"
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_destination_available
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Lists the available destination values for the DRG channel:
+		"frequency phase amplitude"; or for the RAM control channel:
+		"frequency phase amplitude polar".
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_operating_mode
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the DRG or RAM control operating mode. For the DRG
+		channel it controls the no-dwell behavior of the ramp.
+
+		Available values can be read from the corresponding
+		out_altvoltageY_operating_mode_available attribute.
+
+		Valid values for DRG channel:
+
+		  - "bidirectional": Normal ramp generation (ramp up then
+		    down, dwelling at limits).
+		  - "ramp_down": No-dwell low; the ramp resets to upper
+		    limit upon reaching the lower limit.
+		  - "ramp_up": No-dwell high; the ramp resets to lower
+		    limit upon reaching the upper limit.
+		  - "bidirectional_continuous": Both no-dwell high and low;
+		    the ramp continuously sweeps without dwelling.
+
+		Valid values for RAM control channel:
+
+		  - "direct_switch": start address defines fixed word to be used
+		    by the selected profile.
+		  - "ramp_up": One-shot ramp up through current profile's address
+		    range.
+		  - "bidirectional": Ramp up then down through PROFILE0 pin.
+		  - "bidirectional_continuous": Continuous ramp up/down
+		    through current profile's address range.
+		  - "ramp_up_continuous": Continuous ramp up through
+		    current profile's address range.
+		  - "sequenced": Sequenced playback of RAM profiles up to
+		    the active profile. Requires active profile > 0.
+		  - "sequenced_continuous": Continuous sequenced playback
+		    of RAM profiles up to the active profile. Requires
+		    active profile > 0.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_operating_mode_available
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For the DRG channel it lists the available operating mode values:
+		"bidirectional ramp_down ramp_up bidirectional_continuous".
+
+		For the RAM control channel it lists the available operating mode
+		values:
+		"direct_switch ramp_up bidirectional bidirectional_continuous
+		ramp_up_continuous sequenced sequenced_continuous".
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the DRG frequency step size in Hz for ramp up and ramp
+		down DRG channels. This is the increment/decrement step applied to
+		the DRG frequency value, which is input to the DDS core and it is
+		updated at each ramp clock tick when the DRG destination is
+		set to "frequency". Valid range is [0, sysclk/2).
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the DRG phase step size in radians for ramp up and ramp
+		down DRG channels. This is the increment/decrement step applied to
+		the DRG phase value, which is input to the DDS core and it is
+		updated at each ramp clock tick when the DRG destination is
+		set to "phase". Valid range is [0, 2*pi).
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For the DRG ramp up/down channels this is used to read/write the
+		DRG amplitude step size, which is applied as an
+		increment/decrement to the DRG amplitude value, input to the DDS
+		core, updated at each ramp clock tick when the DRG destination is
+		set to "amplitude". Valid range is [0, 1].
+
+		For the OSK channel this is used to read/write the automatic OSK
+		amplitude ramp step size. Writing a	non-zero value enables
+		automatic OSK mode and sets the amplitude step size. Writing "0"
+		disables automatic OSK mode. The value is rounded to the nearest
+		hardware supported step: 0.000061, 0.000122, 0.000244, or
+		0.000488.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_address_start
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the RAM start address for the active profile. Defines
+		the first RAM word address used during playback. Cannot be
+		changed while RAM mode is enabled. Valid range is [0, 1023].
+		If set above the current end address, the end address is
+		automatically adjusted to match.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_address_end
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the RAM end address for the active profile. Defines
+		the last RAM word address used during playback. Cannot be
+		changed while RAM mode is enabled. Valid range is
+		[address_start, 1023].
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_pinctrl_en
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read/write the OSK manual external control enable. Writing '1'
+		enables manual control of the output amplitude envelope via an
+		external pin. Writing '0' disables it. When enabled, the OSK pin
+		directly controls the amplitude on/off state rather than using
+		the automatic OSK ramp.
diff --git a/MAINTAINERS b/MAINTAINERS
index 6403439b530d..edd87ee7da5f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1635,6 +1635,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	drivers/iio/frequency/ad9910.c
 

-- 
2.43.0

