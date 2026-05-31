From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v15 00/12] ADF41513/ADF41510 PLL frequency synthesizers
Date: Sun, 31 May 2026 09:30:43 +0100
Message-Id: <20260531-adf41513-iio-driver-v15-0-da09adf1c0dd@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALPxG2oC/33STY7UMBAF4KuMsibIVeVfVtwDsbBd5RlL0EFpF
 IFGfXecllCCHLO0FX9OPb/36S5rlfv06eV9WmWr97rc2gLMh5cpv8Xbq8yV28aECg0AqDly0WC
 A5lqXmde6yTrHmKOPrnjlZWonf6xS6q8n++VrW7/V+89l/f28ZYN99//eBrOakYtPogpnK5/jL
 X5bXj/m5fu0gxseCEK4RrAhSTBET2xcoA6hv4hVoPw1QvufEAM5iFK07xB9QsBeI7ohnJJj6zw
 iuA4xJwTpGjHPTLJ4wIjMsUPsCaFBsLYhuWiLFNp3KXeIOxAcjeP2YJUweReTMaFD/IGQGozjG
 +KZUYPLWVvTIeGE4GCc0BAgLIqVs+R0h4A6lHZ80Da1v0+xoLRlo03/PgAHY9QgFni2NjkJIRf
 xBXsGT8yw+3tvSceCwuhcKD1DZ8YNmL25KVmBZpFVF8ypugb1gNm7q6xHzSGDKf9G/Hg8/gBPs
 OsIQwQAAA==
X-Change-ID: 20251110-adf41513-iio-driver-aaca8a7f808e
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, Petr Mladek <pmladek@suse.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780216295; l=7207;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=BwrCMJSqDqw93Kci2D9Mvk3scFE9sWiCX07UitM6pyY=;
 b=zKYqjB9Jzts8SWcgiAa5z0EAH1ZbDQMJQw9lnbL9Y4PC7PGqkC+WQalew2NgCh3jCEy34vomY
 5CpM2GNMWG4DEIOJ8cCg7WvBTwn/YjOjydds/NgFjpt11Y0SFRiytfA
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Analog Devices ADF41513 and ADF41510
ultralow noise PLL frequency synthesizers. These devices are designed for
implementing local oscillators (LOs) in high-frequency applications.
The ADF41513 covers frequencies from 1 GHz to 26.5 GHz, while the ADF41510
operates from 1 GHz to 10 GHz.

Key features supported by this driver:
- Integer-N and fractional-N operation modes
- High maximum PFD frequency (250 MHz integer-N, 125 MHz fractional-N)
- 25-bit fixed modulus or 49-bit variable modulus fractional modes
- Digital lock detect functionality
- Phase resync capability for consistent output phase
- Load Enable vs Reference signal syncronization

The series includes:
1. PLL driver implementation
2. Device tree bindings documentation
3. IIO ABI documentation
4. Parsing utils for 64-bit decimal values

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v15:
- Set bleed value when chaging mode.
- Link to v14: https://lore.kernel.org/r/20260524-adf41513-iio-driver-v14-0-06824d9c15f4@analog.com

Changes in v14:
- Review include headers.
- Use named fields in spi device table.
- Address relevant sashiko's feedback.
- Minor tweaks to iio core changes.
- Link to v13: https://lore.kernel.org/r/20260517-adf41513-iio-driver-v13-0-bb6e134a360f@analog.com

Changes in v13:
- Introduce _parse_integer_limit_init()
- Better support for 0 and larger scales in kstrtodec64()
- Increase test scope for kstrtodec64()
- Fix LSB_P1 check at startup when going for fixed modulus mode.
- Clear phase adjust when setting phase (It turns out sashiko was correct).
- Make sure Load Enable is not selected when powering up.
- Address some minor comments.
- Link to v12: https://lore.kernel.org/r/20260510-adf41513-iio-driver-v12-0-34af2ed2779f@analog.com

Changes in v12:
- Contraint charge pump current.
- Fix division-by-zero issues.
- Address PM and sysfs powerdown conflicts.
- Program proper phase resync value in clk divider mode.
- Link to v11: https://lore.kernel.org/r/20260506-adf41513-iio-driver-v11-0-2b7e99cfe8f2@analog.com

Changes in v11:
- Cleanup ext info attribute read/write callbacks.
- Adjust attribute names in the documentation.
- Turn s64 compose macros into static inline functions.
- Link to v10: https://lore.kernel.org/r/20260415-adf41513-iio-driver-v10-0-df61046d5457@analog.com

Changes in v10:
- Drop simple_strntoull() changes
- Create kstrtodec64() and kstrtoudec64() helpers. 
- Add IIO value format for 64-bit decimal values.
- PLL driver code implements new decimal format for frequency attr. 
- Link to v9: https://lore.kernel.org/r/20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com

Changes in v9:
- Expose simple_strntoull() in a safer prototype instead of new kstrntoull()
- Link to v8: https://lore.kernel.org/r/20260303-adf41513-iio-driver-v8-0-8dd2417cc465@analog.com

Changes in v8:
- Add new function kstrntoull() to lib/kstrtox.c and tests to lib/test-kstrtox.c.
- Drop custom iio u64 parser, replacing it for kstrntoull().
- Dedicated MAINTAINERS entry for drivers/iio/test/iio-test-fixpoint-parse.c.
- Link to v7: https://lore.kernel.org/r/20260216-adf41513-iio-driver-v7-0-b0ed387ab559@analog.com

Changes in v7:
- Addressed minor suggestions.
- frequency_resolution ABI for AD4350 removed in favor of generic one.
- Link to v6: https://lore.kernel.org/r/20260130-adf41513-iio-driver-v6-0-cf46239026bc@analog.com

Changes in v6:
- Drop usage of simple_strtoull().
- Implement better overflow checks with iio_safe_strntou64().
- Link to v5: https://lore.kernel.org/r/20260123-adf41513-iio-driver-v5-0-2dce812a2dda@analog.com

Changes in v5:
- Drop local parsing of 64-bit plus fractional parts
- Add iio_str_to_fixpoint64() to iio core with parsing tests
- Add DT property dependency for adi,charge-pump-resistor-ohms
- Add local definition for ADF41513_HZ_PER_GHZ and drop units.h patch
- Link to v4: https://lore.kernel.org/r/20260116-adf41513-iio-driver-v4-0-dbb7d6782217@analog.com

Changes in v4:
- Proper usage of units.h macros
- Simplifications to DT property parsing
- Adjustments to return value handling
- Drop of simple DT property node example
- Link to v3: https://lore.kernel.org/r/20260108-adf41513-iio-driver-v3-0-23d1371aef48@analog.com

Changes in v3:
- Use FIELD_MODIFY macro in driver implementation
- Drop refin_frequency iio attribute
- Drop muxout-select property from dt-bindings (and rename logic-level property)
- Use -mhz suffix in power-up frequency property
- Address documentation issues
- Link to v2: https://lore.kernel.org/r/20251219-adf41513-iio-driver-v2-0-be29a83d5793@analog.com

Changes in v2:
- separate driver implementation from extra features and improve commit messages
- use macros from units.h
- explanation of custom parse function: adf41513_parse_uhz
- reorganize driver data structures
- drop clock framework support for now
- reorganize documentation
- Link to v1: https://lore.kernel.org/r/20251110-adf41513-iio-driver-v1-0-2df8be0fdc6e@analog.com

---
Rodrigo Alencar (12):
      dt-bindings: iio: frequency: add adf41513
      lib: kstrtox: add local _parse_integer_limit_init() helper
      lib: kstrtox: add kstrtoudec64() and kstrtodec64()
      lib: test-kstrtox: tests for kstrtodec64() and kstrtoudec64()
      lib: math: div64: add div64_s64_rem()
      iio: core: add decimal value formatting into 64-bit value
      iio: test: iio-test-format: add test case for decimal format
      iio: frequency: adf41513: driver implementation
      iio: frequency: adf41513: handle LE synchronization feature
      iio: frequency: adf41513: features on frequency change
      docs: iio: add documentation for adf41513 driver
      Documentation: ABI: testing: add common ABI file for iio/frequency

 Documentation/ABI/testing/sysfs-bus-iio-frequency  |   11 +
 .../ABI/testing/sysfs-bus-iio-frequency-adf4350    |   10 -
 .../bindings/iio/frequency/adi,adf41513.yaml       |  227 ++++
 Documentation/iio/adf41513.rst                     |  199 ++++
 Documentation/iio/index.rst                        |    1 +
 MAINTAINERS                                        |    9 +
 drivers/iio/frequency/Kconfig                      |   10 +
 drivers/iio/frequency/Makefile                     |    1 +
 drivers/iio/frequency/adf41513.c                   | 1246 ++++++++++++++++++++
 drivers/iio/industrialio-core.c                    |   47 +-
 drivers/iio/test/iio-test-format.c                 |   97 +-
 include/linux/iio/types.h                          |   30 +
 include/linux/kstrtox.h                            |    3 +
 include/linux/math64.h                             |   18 +
 lib/kstrtox.c                                      |  141 ++-
 lib/math/div64.c                                   |   15 +
 lib/test-kstrtox.c                                 |  182 +++
 17 files changed, 2193 insertions(+), 54 deletions(-)
---
base-commit: 1548c54e9adc32a719499216f63fba14b2fc07c3
change-id: 20251110-adf41513-iio-driver-aaca8a7f808e

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

