From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 00/23] iio: make masklength __private (final round)
Date: Fri, 26 Jul 2024 10:22:52 +0200
Message-Id: <20240726-dev-iio-masklength-private3-v1-0-82913fc0fb87@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANxco2YC/x3MQQqAIBAAwK/EnlsoC6y+Eh0W3WqpLFQkiP6ed
 JzLPBDYCwcYigc8Jwlyuoy6LMCs5BZGsdmgKtVWWrVoOaHIiQeFbWe3xBUvL4kiN6hJ2a7uyRh
 tIQ+X51nufx+n9/0AyfqI/20AAAA=
To: linux-iio@vger.kernel.org, linux-staging@lists.linux.dev
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Ramona Gradinariu <ramona.gradinariu@analog.com>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Marcus Folkesson <marcus.folkesson@gmail.com>, 
 Kent Gustavsson <kent@minoris.se>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Francesco Dolcini <francesco@dolcini.it>, 
 =?utf-8?q?Jo=C3=A3o_Paulo_Gon=C3=A7alves?= <jpaulo.silvagoncalves@gmail.com>, 
 Haibo Chen <haibo.chen@nxp.com>, Michal Simek <michal.simek@amd.com>, 
 Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982177; l=5077;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=WyJI+2lqRWn23JQimnxJt9rUlG59V5Wo8/tdFWvIKuM=;
 b=7dO/QcsN3vOJ1/SAxpLpEUUZ6emm5sf6znQMt4MjPY491Ya7+QQCYQyS2Trge9M/pmTFfHFvQ
 wMwUCwQTGOADl6sX+5VHG8yr8TfJMKhSHGZyMYxeSbSkPLz+lSqrjIJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes the final conversion round.  On the testing branch a git
grep:

git grep "\->masklength"

Gives no more users so hopefully I did it right :).

Not entirely related with this but I'll mention it anyways :). Looking
at the other [INTERN] fields, I see:

* active_scan_mask: which seems to be pretty similar to masklength;
* scan_timestamp: Has some apparently valid  users;
* scan_bytes: Also has a few users;
* trig: may need a bit more inspection.

The first 3 look like valid RO fields that drivers are allowed to
access. I mean, for scan_bytes I guess drivers could calculate that
based on the active_scan_mask but I think that's just not worth it given
the core already did it for us.
 
So I wonder if a similar work would be valuable? scan_timestamp and
scan_bytes would be pretty trivial but for active_scan_mask we do have
lots of users (but also trivial I think).

For Trig, most of the writes are drivers doing

indio_dev->trig = iio_trigger_get(data->trig);

So we either assume it's public or remove that line from drivers. Though
that could break userland apps relying on some trigger to be
automatically set after device probe. We can anyways have another helper
to do that for drivers (not sure this field is accessed in some
fastpath).

Also need to better check if there are any readers for it.

Anyways, it would be nice to get your inputs on the last [INTERNAL] fields
in struct iio_dev

Also want to mention that I deliberately removed some mailing lists
given by get_maintainers as this is fairly simple and so I don't think
the "spam" is worth it :). 

---
Nuno Sa (23):
      iio: accel: adxl380: make use of iio_get_masklength()
      iio: adc: max1118: make use of iio_for_each_active_channel()
      iio: adc: max1118: make use of iio_for_each_active_channel()
      iio: adc: mcp3911: make use of iio_for_each_active_channel()
      iio: adc: mt6360-adc: make use of iio_for_each_active_channel()
      iio: adc: rockchip_saradc: make use of iio_for_each_active_channel()
      iio: adc: rtq6056: make use of iio_for_each_active_channel()
      iio: adc: stm32-adc: make use of iio_get_masklength()
      iio: adc: stm32-dfsdm-adc: make use of iio_get_masklength()
      iio: adc: ti-adc0832: make use of iio_for_each_active_channel()
      iio: adc: ti-adc084s021: make use of iio_for_each_active_channel()
      iio: adc: ti-ads1015: make use of iio_get_masklength()
      iio: adc: ti-ads1119: make use of iio_get_masklength()
      iio: adc: ti-ads1298: make use of iio_for_each_active_channel()
      iio: adc: ti-adc12138: make use of iio_for_each_active_channel()
      iio: adc: ti-ads124s08: make use of iio_for_each_active_channel()
      iio: adc: ti-ads131e08: make use of iio_for_each_active_channel()
      iio: adc: ti-ads8688: make use of iio_for_each_active_channel()
      iio: adc: vf610_adc: make use of iio_get_masklength()
      iio: adc: xilinx-xadc-core: use new '.masklength' accessors
      iio: common: cros_ec_sensors_core: use new '.masklength' accessors
      staging: iio: impedance-analyzer: ad5933: make use of iio_get_masklength()
      iio: core: annotate masklength as __private

 drivers/iio/accel/adxl380.c                               | 2 +-
 drivers/iio/adc/ina2xx-adc.c                              | 3 +--
 drivers/iio/adc/max1118.c                                 | 3 +--
 drivers/iio/adc/mcp3911.c                                 | 2 +-
 drivers/iio/adc/mt6360-adc.c                              | 2 +-
 drivers/iio/adc/rockchip_saradc.c                         | 2 +-
 drivers/iio/adc/rtq6056.c                                 | 2 +-
 drivers/iio/adc/stm32-adc.c                               | 4 ++--
 drivers/iio/adc/stm32-dfsdm-adc.c                         | 2 +-
 drivers/iio/adc/ti-adc0832.c                              | 3 +--
 drivers/iio/adc/ti-adc084s021.c                           | 3 +--
 drivers/iio/adc/ti-adc12138.c                             | 3 +--
 drivers/iio/adc/ti-ads1015.c                              | 2 +-
 drivers/iio/adc/ti-ads1119.c                              | 4 ++--
 drivers/iio/adc/ti-ads124s08.c                            | 3 +--
 drivers/iio/adc/ti-ads1298.c                              | 3 +--
 drivers/iio/adc/ti-ads131e08.c                            | 2 +-
 drivers/iio/adc/ti-ads8688.c                              | 4 +---
 drivers/iio/adc/vf610_adc.c                               | 2 +-
 drivers/iio/adc/xilinx-xadc-core.c                        | 5 ++---
 drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c | 8 +++-----
 drivers/iio/industrialio-buffer.c                         | 2 +-
 drivers/staging/iio/impedance-analyzer/ad5933.c           | 5 +++--
 include/linux/iio/iio.h                                   | 4 ++--
 24 files changed, 32 insertions(+), 43 deletions(-)
---
base-commit: 472438c7e0e2261c6737a8321f46ef176eef1c8f
change-id: 20240724-dev-iio-masklength-private3-7a2d819acc7d
--

Thanks!
- Nuno Sá

