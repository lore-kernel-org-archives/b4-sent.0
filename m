From: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
Subject: [PATCH 0/2] hwmon: ina238: Add samples and update_interval support
Date: Fri, 22 May 2026 09:03:02 +0200
Message-Id: <20260522-hwmon-ina238-add-samples-update-interval-v1-0-e1acfceb447e@advastore.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2N0QrCMAwAf2Xk2UAbWS3+ivgQbOYCW1eabQpj/
 27x8eC4O8CkqhjcuwOq7Gq65Ab+0sFr5PwW1NQYyFFwPTkcP/OSUTPTNSKnhMZzmcRwK4nXpud
 V6s4TUrwFH/oo3g/QcqXKoN//6vE8zx9xfc6regAAAA==
X-Change-ID: 20260520-hwmon-ina238-add-samples-update-interval-28761658e11f
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ferdinand Schwenk <ferdinand.schwenk@advastore.com>, 
 richard.leitner@linux.dev
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779433387; l=1417;
 i=ferdinand.schwenk@advastore.com; h=from:subject:message-id;
 bh=4RLjP9RUqPzryq9T6qgk1AjiOYFgZeMQSUYBnoTaQmI=;
 b=8ppIDYkAzkEQRrctMXXWgnhUkFgtMcd+4xB3OWx1qr+xQv9S7HffJSlRX5WGDozFjtr37golk
 JMg2b32QKnQCYbTjn8Ypm+dTc4+LiKqVNYP91wbj7BjAE47E9VdjViR
X-Developer-Key: i=ferdinand.schwenk@advastore.com; a=ed25519;
 pk=HyA9NdHJ7NystP+1SyuWJeyXNH2EO4A09FXli9mfs9Q=
X-Endpoint-Received: by B4 Relay for ferdinand.schwenk@advastore.com/default with auth_id=788
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series exposes the INA238 ADC_CONFIG register's averaging count
(AVG) and conversion time fields (VBUSCT, VSHCT, VTCT) through the
standard hwmon chip-level attributes chip/samples and
chip/update_interval.

The first patch adds read/write support for both attributes using a
per-chip conversion-time lookup table to correctly handle all
supported variants: INA228, INA237, INA238, INA700, INA780 (sharing
ina238_conv_time[]) and the Silergy SQ52206 (sq52206_conv_time[]).

The second patch uses microseconds as the unit for update_interval
instead of milliseconds.  The INA238 supports conversion times as
short as 50 us; millisecond precision would make the four shortest
steps (50, 84, 150, 280 us) indistinguishable and inaccessible.
Since chip/update_interval is introduced in this same series, no
existing ABI is broken.

Signed-off-by: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
---
Ferdinand Schwenk (2):
      hwmon: ina238: add support for samples and update_interval
      hwmon: ina238: use microseconds for update_interval

 drivers/hwmon/ina238.c | 134 ++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 132 insertions(+), 2 deletions(-)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260520-hwmon-ina238-add-samples-update-interval-28761658e11f

Best regards,
-- 
Ferdinand Schwenk <ferdinand.schwenk@advastore.com>

