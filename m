From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v4 0/2] iio: light: add support for ams OSRAM TCS3430
Date: Sat, 28 Nov 2026 21:40:46 +0100
Message-Id: <20261128-iio-tcs3430-v4-0-14d03e411f8e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NTQ6CMBCG4auQrq1pp+WnrryHcVHLAGOUGopEQ
 7i7BTdgXH7JPO+MLGBHGNghGVmHAwXybRx6lzDX2LZGTmXcDARkUoLmRJ73LiitBIcqVUVuUsi
 xZFE8OqzotdRO5+8Oz8sVXT8n5ouGQu+79/JukPPd//IgueCiAqsKm1nt5LG+W7rtnb+zuTzA2
 mZbC9FmLlVgShBGml+r1jbfWhUtSiOtFlZb3Nhpmj5RBgJLMAEAAA==
X-Change-ID: 20261124-iio-tcs3430-2f53879527ed
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Matti Vaittinen <mazziesaccount@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898449; l=3510;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=dbEtNhwThduph7BKFv4b4mNalrw5/lYEJz/CPCZk6iA=;
 b=QegDiMvLVSseiiqyIiREHmy5bp+a/h1Xpl5IFHPHXdCyYxEyJDWmTVT2TAoDmXt5DfdWiuA1I
 HMuBTRHF2IJBRsNfFjoIrrJW3cD4D+ppVSzMQfHu++O5dbzo2qnln9k
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree binding documentation and an IIO driver for the ams OSRAM
TCS3430 ambient light and CIE 1931 XYZ tristimulus color sensor.

Tested on Microsoft Surface Pro X SQ2 (SC8180X), where the sensor is
connected on I2C at 0x39 and used for ambient light sensing.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v4:
- Expose IIO_CHAN_INFO_SCALE via info_mask_shared_by_all across both the
  illuminance and intensity (X, Y, Z, IR1) channels since hardware gain
  and integration time scale all channels together (Jonathan Cameron).
- Replace <linux/device.h> with <linux/dev_printk.h> and
  <linux/device/devres.h>, and add blank lines before final return
  statements (Jonathan Cameron).
- Move devm_regulator_get_enable(dev, "vdd") after devm_iio_device_alloc()
  in tcs3430_probe() so hardware power is not touched on allocation failure
  (Andy Shevchenko).
- Pick up Andy Shevchenko's Reviewed-by on patch 2/2.
- Link to v3: https://patch.msgid.link/20261127-iio-tcs3430-v3-0-e191a40a4ae9@gmail.com

Changes in v3:
- Import the IIO_GTS_HELPER module namespace via MODULE_IMPORT_NS("IIO_GTS_HELPER")
  so modular builds (CONFIG_TCS3430=m) pass modpost.
- Enable REGCACHE_MAPLE with a volatile register table (0x92..0x9b) and
  regcache_cache_only()/regcache_mark_dirty()/regcache_sync() across
  suspend/resume (Andy Shevchenko).
- Align Kconfig tristate prompt, top driver comment, and MODULE_DESCRIPTION(),
  and keep driver-separation rationale in the commit message rather than
  Kconfig help (Andy Shevchenko).
- Simplify tcs3430_set_scale() to drop the keep_time boolean, rename
  in_range to gain_in_range in tcs3430_set_itime(), use local regmap
  variables for readability, add blank lines after guard(mutex)(), and
  keep dev_dbg()/DEFINE_SIMPLE_DEV_PM_OPS() on single lines (Andy Shevchenko).
- Link to v2: https://lore.kernel.org/r/20261126-iio-tcs3430-v2-0-6c5329d20919@gmail.com

Changes in v2:
- Replace hardwaregain control with standard IIO _scale and configurable
  integration time using the IIO GTS helper (Jonathan Cameron).
- Hold data->lock across the entire IIO_CHAN_INFO_SCALE path in
  tcs3430_read_raw() (Jonathan Cameron).
- Convert register I/O to regmap_i2c (Joshua Crofts).
- Wrap guard(mutex) declarations in tcs3430_read_raw() switch cases in
  enclosing blocks to fix Clang -Wjump-misses-init / cleanup scoping
  (kernel test robot, Joshua Crofts).
- Use switch(mask) in tcs3430_read_avail() and tcs3430_write_raw(), and
  drop unused linux/mod_devicetable.h include (Joshua Crofts).
- Drop redundant L: mailing-list line from MAINTAINERS (Joshua Crofts).
- Pick up Krzysztof Kozlowski's Reviewed-by on dt-bindings.
- Link to v1: https://patch.msgid.link/20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com

---
Robert Ijtsma (2):
      dt-bindings: iio: light: add ams OSRAM TCS3430
      iio: light: add ams OSRAM TCS3430 XYZ and ambient light sensor driver

 .../devicetree/bindings/iio/light/ams,tcs3430.yaml |  52 ++
 MAINTAINERS                                        |   6 +
 drivers/iio/light/Kconfig                          |  12 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/tcs3430.c                        | 529 +++++++++++++++++++++
 5 files changed, 600 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-iio-tcs3430-2f53879527ed

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

