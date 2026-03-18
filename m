From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH RFC v2 0/9] AD9910 Direct Digital Synthesizer
Date: Wed, 18 Mar 2026 17:56:00 +0000
Message-Id: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADDnumkC/22NwQrCMBBEf6Xs2Uh2G0vrSRD8AK/Sw7ZJ2wVtJ
 JGglP67oV49vhnmzQLRBXERjsUCwSWJ4ucMtCugn3genRKbGUhTpQlrxbZpUCsRr2yQ5IJqutI
 Smp4OOEDePYMb5L05b3C9nKHN4STx5cNn+0m4VT8l6T/KhEqrsqPKMJuaUZ945rsf971/QLuu6
 xcCgM4guAAAAA==
X-Change-ID: 20260218-ad9910-iio-driver-9b3d214c251f
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=8760;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Uvo457Wh7y4+UHfmA1m+9aW9HdSvK6o1Rnp5RB93Ae8=;
 b=SR/nFpnm9hGI+jcZfDTxLu2NZd/po8+ZMuiaaF9nhKfGlUgb6/q7MD+GfocPrYrVUKSe1Ki9w
 RDaCqtkcuCSAKtk0MKyTX+jvsIQwBfXvRiDd9iIVlyC2Fj6mcqQGb8l
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Analog Devices AD9910 DDS.
This is a RFC so that we can agree/discuss on the design that follows:

This is a follow-up of the V1 discussion. We are reaching into this
channel composition agreement where physical channels may have
sub-channels. That adds the flexibility necessary for this design.
Nothing has been changed to iio-core yet, so I've just addressed
comments, aiming to keep the discussion going forward.

The AD9910 DDS core can be driven through several independent mechanisms:
single tone profiles, a digital ramp generator, an internal RAM playback
engine, a parallel data port, and output shift keying. Each of these
represents a distinct signal path into the DDS accumulator, so the driver
models them as separate IIO output channels (all IIO_ALTVOLTAGE type).
This per-channel separation allows userspace to configure each mode
independently through its own set of sysfs attributes, and to
enable/disable modes individually via IIO_CHAN_INFO_ENABLE, relying on
the hardware's own mode selection architecture.

The AD9910 register map is not suited for the regmap framework: register
widths vary across the map (16, 32, and 64 bits). The driver instead
implements direct SPI access helpers with a software register cache, using
type-specific read/write/update functions (ad9910_reg{16,32,64}_{read,
write,update}) that handle endianness conversion and cache coherency.

Registers are cached for several reasons. The control/function registers
(CFR1, CFR2) are frequently queried to determine the current operating
mode (e.g., checking RAM_ENABLE before every profile register access),
and caching avoids repeated SPI read transactions for what are
essentially state checks. The cache also enables efficient
read-modify-write updates on multi-byte registers: the update functions
merge new field values with the cached register content without issuing
a SPI read, and skip the write entirely when the value is unchanged.
Finally, the profile registers serve dual purposes depending on whether
RAM mode is active -- they hold single tone parameters (FTW, POW, ASF)
in normal operation but are repurposed for RAM playback configuration
(start/end address, step rate, operating mode) when RAM is enabled. A
shadow register array (reg_profile[]) preserves the inactive mode's
settings across transitions, so no state is lost when switching between
single tone and RAM operation.

RAM data is loaded through firmware upload infrastructure. Userspace
writes the waveform data as a raw binary buffer (up to 4096 bytes for
the full 1024x32-bit RAM), and the driver reverses the byte array and
transfers it to the device in a single SPI transaction. Per-profile
start/end addresses and playback parameters (operating mode, step rate,
no-dwell control) are configured through the RAM channel's ext_info
attributes.

Streaming data to the DDS core through the parallel data port at the
PD_CLK rate is not covered by this series. That functionality would
be added in a separate patch series, building on top of the IIO backend
infrastructure to provide a proper buffered data path.

As I am pushing implementation, as lot has been done already without much
supervision or agreement, still I would be interested on hearing about
the design choices discussed above. Here is the output for the iio_info
at this point:

iio:device3: ad9910
  8 channels found:
      altvoltage120:  (output)
      7 channel-specific attributes found:
          attr  0: en value: 0
          attr  1: frequency_offset value: 0.000000
          attr  2: frequency_scale value: 1
          attr  3: label value: parallel_port
          attr  4: phase_offset value: 0.000000
          attr  5: sampling_frequency value: 250000000.000000
          attr  6: scale_offset value: 0.000000
      altvoltage140:  (output)
      11 channel-specific attributes found:
          attr  0: address_end value: 1023
          attr  1: address_start value: 0
          attr  2: destination value: frequency
          attr  3: destination_available value: frequency phase amplitude polar
          attr  4: en value: 0
          attr  5: frequency value: 0.000000
          attr  6: label value: ram_control
          attr  7: operating_mode value: direct_switch
          attr  8: operating_mode_available value: direct_switch ramp_up
		           bidirectional bidirectional_continuous ramp_up_continuous
				   sequenced sequenced_continuous
          attr  9: phase value: 0.000000
          attr 10: sampling_frequency value: 250000000.000000
      altvoltage130:  (output)
      11 channel-specific attributes found:
          attr  0: destination value: frequency
          attr  1: destination_available value: frequency phase amplitude
          attr  2: en value: 0
          attr  3: label value: digital_ramp_generator
          attr  4: operating_mode value: bidirectional_continuous
          attr  5: operating_mode_available value: bidirectional ramp_down
		           ramp_up bidirectional_continuous
      altvoltage110:  (output)
      4 channel-specific attributes found:
          attr  0: frequency value: 0.000000
          attr  1: label value: single_tone
          attr  2: phase value: 0.000000
          attr  3: scale value: 0.000000
      altvoltage132:  (output)
      8 channel-specific attributes found:
          attr  0: frequency value: 0.000000
          attr  1: frequency_step value: 0.000000
          attr  2: label value: digital_ramp_down
          attr  3: phase value: 0.000000000
          attr  4: phase_step value: 0.000000000
          attr  5: sampling_frequency value: 250000000.000000
          attr  6: scale value: 0.000000000
          attr  7: scale_step value: 0.000000000
      altvoltage131:  (output)
      8 channel-specific attributes found:
          attr  0: frequency value: 0.000000
          attr  1: frequency_step value: 0.000000
          attr  2: label value: digital_ramp_up
          attr  3: phase value: 0.000000000
          attr  4: phase_step value: 0.000000000
          attr  5: sampling_frequency value: 250000000.000000
          attr  6: scale value: 0.000000000
          attr  7: scale_step value: 0.000000000
      altvoltage100:  (output)
      4 channel-specific attributes found:
          attr  0: label value: phy
          attr  1: powerdown value: 0
          attr  2: profile value: 0
          attr  3: sampling_frequency value: 1000000000
      altvoltage150:  (output)
      6 channel-specific attributes found:
          attr  0: en value: 0
          attr  1: label value: output_shift_keying
          attr  2: pinctrl_en value: 0
          attr  3: sampling_frequency value: 250000000.000000
          attr  4: scale value: 0.000000
          attr  5: scale_step value: 0.000000
  4 debug attributes found:
          debug attr  1: ram_data ERROR: Input/output error (5)
          debug attr  2: ram_loading value: 0
          debug attr  3: direct_reg_access value: 0x2

Kind regards,

Rodrigo Alencar

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v2:
- Device-tree bindings changes.
- RAM loading to use firmware update interface.
- Rearrange of channels into a hierarchy.
- Link to v1: https://lore.kernel.org/r/20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com

---
Rodrigo Alencar (9):
      dt-bindings: iio: frequency: add ad9910
      iio: frequency: ad9910: initial driver implementation
      iio: frequency: ad9910: add simple parallel port mode support
      iio: frequency: ad9910: add digital ramp generator support
      iio: frequency: ad9910: add RAM mode support
      iio: frequency: ad9910: add output shift keying support
      iio: frequency: ad9910: add channel labels
      Documentation: ABI: testing: add docs for ad9910 sysfs entries
      docs: iio: add documentation for ad9910 driver

 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     |  182 ++
 .../bindings/iio/frequency/adi,ad9910.yaml         |  189 ++
 Documentation/iio/ad9910.rst                       |  654 ++++++
 Documentation/iio/index.rst                        |    1 +
 MAINTAINERS                                        |   10 +
 drivers/iio/frequency/Kconfig                      |   20 +
 drivers/iio/frequency/Makefile                     |    1 +
 drivers/iio/frequency/ad9910.c                     | 2261 ++++++++++++++++++++
 8 files changed, 3318 insertions(+)
---
base-commit: ff0843ceb1fb11a6b73e0e77b932ef7967aecd4b
change-id: 20260218-ad9910-iio-driver-9b3d214c251f

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

