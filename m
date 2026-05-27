From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH v5 0/2] iio: adc: ad_sigma_delta: fix CS assertion and
 registerless device handling
Date: Wed, 27 May 2026 12:38:37 +0300
Message-Id: <20260527-ad_sigma_delta-fix-v5-0-446fd2bc7330@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJ27FmoC/33O0YrCMBAF0F+RPG8kmWmydZ/2PxaRmWRSA9ouj
 RQX6b9v9EXF4uO9MOfORRUZsxT1tbqoUaZc8tDX4D5WKuyp70TnWLMCA9400GqKu5K7I+2iHE6
 kUz5rZu+i8yEwG1UPf0ep9Q392da8z+U0jH+3jcle27fcZLXVrWDagBNpI3xTT4ehW4fhqK7eB
 HfDmc9FA6ohofXCpvHI8cXAB8Mu/4HaaALaAJuAPuGL0TwYYBeNphqcGGNCQR/pyZjn+R/ZeKS
 ugQEAAA==
X-Change-ID: 20260428-ad_sigma_delta-fix-bb65d56ccbb0
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779874718; l=4905;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=4rbJIQTpv3EO6ILZHoULoet7hB2qjSej26iz17w1p1Y=;
 b=HUKisZG2REIE2JysdAOqgnS/fZWSFeCbsojNnGB0dy5U4ECQgqDXdT93yppYhFKRnAR0Qi+0P
 7dMA0NkQnumAVlboYkKSs9Q5VdIod7PLmN7FfpeTdUE7JzNJpYy46BL
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes two independent bugs in the ad_sigma_delta framework.

Patch 1 fixes CS being left permanently asserted after single conversion
and in the error path of ad_sd_buffer_postenable(). In
ad_sigma_delta_single_conversion(), set_mode(AD_SD_MODE_IDLE) and
disable_one() were executing while keep_cs_asserted was still true,
causing any SPI transfer they issued to carry cs_change=1. The
postenable() error path also failed to call set_mode(AD_SD_MODE_IDLE),
leaving the device in continuous conversion mode with bus_locked
incorrectly set, opening a window for concurrent SPI access.

Patch 2 fixes ad_sigma_delta_clear_pending_event() for devices with                                     
has_registers = false and no rdy_gpiod (currently AD7191, AD7780, and
MAX11205). These devices fall through to the status register read path,                                 
but since has_registers is false, ad_sd_read_reg() transmits no address                               
byte and blindly clocks raw MISO bytes — indistinguishable from reading
conversion data, partially consuming any pending result and corrupting the
stream. With num_resetclks = 0 on these devices a further hazard exists:
if pending_event is set, the drain path attempts memset of SIZE_MAX bytes,
corrupting the heap. The fix returns 0 immediately for registerless
devices. This is safe for all current instances: AD7191 and AD7780 (with
powerdown GPIO) are reset between conversions by CS deassertion; AD7780
(without powerdown GPIO) and MAX11205 are continuously-converting and
cycle ~DRDY regardless, so the next falling edge fires naturally. A future
registerless device that holds ~DRDY asserted until data is read would
need num_resetclks set or a rdy-gpio instead. The same heap corruption can
be triggered on any device with rdy_gpiod set but num_resetclks = 0, so
an explicit data_read_len == 0 guard is added independently.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
Changes in v5:
- Removed the IRQ_DISABLE_UNLAZY paragraph entirely from the commit
  message — it was backwards and based on an implementation-defined assumption
- Added concrete per-device reasoning (CS=PDOWN reset for ad7191/ad7780,
  continuous-converting for ad7780/max11205)
- Added the pitfall paragraph for future registerless devices
- Last paragraph: removed "let the latched IRQ edge fire" — replaced with the
  correct explanation that the stale result is consumed by ad_sigma_delta_single_conversion()
- Link to v4: https://lore.kernel.org/r/20260521-ad_sigma_delta-fix-v4-0-bfb3df3e36da@analog.com

Changes in v4:
- set_mode(AD_SD_MODE_IDLE) was accidentally placed in patch 2
  in v3; moved to the correct commit via rebase.
- add data_read_len == 0 guard to cover the heap corruption path
  reachable via rdy_gpiod on devices with num_resetclks = 0;
  set_mode(AD_SD_MODE_IDLE) moved to patch 1.
- Link to v3: https://lore.kernel.org/r/20260518-ad_sigma_delta-fix-v3-0-a2a92b0c36f3@analog.com

Changes in v3:
- add ad_sigma_delta_set_mode(AD_SD_MODE_IDLE) to the err_unlock
  path in ad_sd_buffer_postenable() to revert the device
  from continuous mode and deassert CS; previously only the flag resets
  were added. Update commit message to remove the inaccurate "in all
  cases" claim and note that CS-less devices such as MAX11205 are
  unaffected since no physical line is toggled.
- Patch 2: new patch fixing ad_sigma_delta_clear_pending_event() for
  devices with has_registers = false and no rdy_gpiod, where the
  existing status register read path blindly clocks raw MISO bytes,
  partially consuming pending conversion data and potentially
  corrupting the heap via a SIZE_MAX memset.
- Link to v2: https://lore.kernel.org/r/20260507-ad_sigma_delta-fix-v2-1-ec86eb0463bd@analog.com

Changes in v2:
- Move set_mode(AD_SD_MODE_IDLE) into out_unlock: as well, not only
  disable_one(); v1 left set_mode() above the label where
  keep_cs_asserted is still true, so devices without the optional
  disable_one callback still had CS stuck after that transfer.
- Fix pre-existing state leak in ad_sd_buffer_postenable() err_unlock:
  reset bus_locked and keep_cs_asserted before spi_bus_unlock() to
  prevent spi_sync_locked() being called on an unlocked controller.
- Link to v1: https://lore.kernel.org/r/20260428-ad_sigma_delta-fix-v1-1-8e3f925ee8d2@analog.com

---
Radu Sabau (2):
      iio: adc: ad_sigma_delta: fix CS held asserted and state leaks
      iio: adc: ad_sigma_delta: fix clear_pending_event for registerless devices

 drivers/iio/adc/ad_sigma_delta.c | 39 ++++++++++++++++++++++++++++++++++-----
 1 file changed, 34 insertions(+), 5 deletions(-)
---
base-commit: 3b3bea6d4b9c162f9e555905d96b8c1da67ecd5b
change-id: 20260428-ad_sigma_delta-fix-bb65d56ccbb0

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

