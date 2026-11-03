From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Tue, 03 Nov 2026 08:42:48 +0000
Subject: [PATCH] iio: light: al3010: fix out-of-bounds read of the scale
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-al3010-scale-bounds-v1-1-6110c2ffe3b4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAxA0atI1g0kKtb2KsXFzJjWFBnLRKUg3
 r2jXb7F/xuYJBWDe7FBklVNp5jBlwLC4OJLUPtsKKlsmKlCN1bEhBbcKOinJfaGVPv2xiKuvja
 Qy0+Sp37P66P72xb/ljAfK9j3H2ZFq3B3AAAA
X-Change-ID: 20261103-al3010-scale-bounds-04b891eea476
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Dmitry Osipenko <digetx@gmail.com>, 
 David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793695374; l=1752;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=wBZCgtZERGB8XNugFlSt0efy2L/NU1X8KF6SrS/tjqs=;
 b=eOxXoHadO3NIfwDPw73bTr3xABL88fOLiUqxWGYFz/ReqKOrnjHjtblVW6gtg31s2IpM+nwcz
 i1LeJ+W1TRdC9gLAmx0fnlNmQXR3TYwujEkq6dsM0FmaZOsegLX14Mr
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gain field read from the CONFIG register is three bits wide, so it
can hold values from 0 to 7, but al3010_scales[] only has four entries.
If the register holds a gain value of 4 or more, reading the scale
attribute indexes past the end of the table and returns garbage.

Reject such values with -EINVAL instead of indexing past the end of
the table.

Fixes: c36b5195ab70 ("iio: light: add Dyna-Image AL3010 driver")
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Found with LLM-assisted static analysis of drivers/iio, looking for
table lookups indexed by unchecked register fields; the fix was drafted
with the same assistant and reviewed and tested by me.

Tested on arm64 QEMU with i2c-stub and CONFIG_UBSAN_BOUNDS=y. After
writing a gain value of 4 to CONFIG (0x10), reading
in_illuminance_scale:
- before: two array-index-out-of-bounds reports (al3010.c:137 and
  :138), and the attribute reads 0.000000
- after: the read fails with -EINVAL and no report is printed
---
 drivers/iio/light/al3010.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 49f6d8336dbe..481dad5097b9 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -134,6 +134,9 @@ static int al3010_read_raw(struct iio_dev *indio_dev,
 			return ret;
 
 		gain = FIELD_GET(AL3010_GAIN_MASK, gain);
+		if (gain >= ARRAY_SIZE(al3010_scales))
+			return -EINVAL;
+
 		*val = al3010_scales[gain][0];
 		*val2 = al3010_scales[gain][1];
 

---
base-commit: d1425b382b9cc5bd19223fad8ba4a8af3dbe1305
change-id: 20261103-al3010-scale-bounds-04b891eea476

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

