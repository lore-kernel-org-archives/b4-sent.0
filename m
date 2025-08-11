From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 11 Aug 2025 17:13:33 +0100
Subject: [PATCH] iio: dac: ad5791: drop unused member of struct
 ad5791_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250811-ad5791-drop-unused-v1-1-3412fbf3ba36@analog.com>
X-B4-Tracking: v=1; b=H4sIAKwWmmgC/x3MQQqAIBBA0avIrBtQSayuEi1Mp5qNiWIE0d2Tl
 m/x/wOFMlOBSTyQ6eLCZ2xQnQB/uLgTcmgGLbWRg1LogrGjwpDPhDXWQgGt9/1gVzIkJbQwZdr
 4/qfz8r4f0pcWf2QAAAA=
X-Change-ID: 20250811-ad5791-drop-unused-7cc487be5e00
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754928813; l=1147;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=eEVAzCPM7yfEsfF5RWo92Lj/29oz7CO8jQ0lqSzGt/A=;
 b=h/WxbWTKo0SfKADn1E9AkucLND6zkmB1FG7AWrfXQ5ewRsj3no4KwyQdS0dn+b3Ns3+BDVDhC
 f48vZ4EZwNjAnE5D2yIHMq2glYMG1wGkG4zowjhPMcNhTrb3KwyYxO3
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The regulator pointers reg_vdd and reg_vss are no longer used. So drop
them.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5791.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/iio/dac/ad5791.c b/drivers/iio/dac/ad5791.c
index 41582f2b90fb9d83ff82ccb27a0eea92d9d9b431..ae7297f083983bb606fa3763370c05da7c2fd6f3 100644
--- a/drivers/iio/dac/ad5791.c
+++ b/drivers/iio/dac/ad5791.c
@@ -80,8 +80,6 @@ struct ad5791_chip_info {
 /**
  * struct ad5791_state - driver instance specific data
  * @spi:			spi_device
- * @reg_vdd:		positive supply regulator
- * @reg_vss:		negative supply regulator
  * @gpio_reset:		reset gpio
  * @gpio_clear:		clear gpio
  * @gpio_ldac:		load dac gpio
@@ -100,8 +98,6 @@ struct ad5791_chip_info {
  */
 struct ad5791_state {
 	struct spi_device		*spi;
-	struct regulator		*reg_vdd;
-	struct regulator		*reg_vss;
 	struct gpio_desc		*gpio_reset;
 	struct gpio_desc		*gpio_clear;
 	struct gpio_desc		*gpio_ldac;

---
base-commit: 856d7be7f3c459a6d646b1f8432c6f616ade0d10
change-id: 20250811-ad5791-drop-unused-7cc487be5e00
--

Thanks!
- Nuno Sá

