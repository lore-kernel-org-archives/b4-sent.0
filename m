From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Thu, 01 Jan 2026 21:47:39 +0530
Subject: [PATCH v4 2/4] iio: proximity: rfd77402: Add OF device ID for
 enumeration via DT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-b4-rfd77402_irq-v4-2-42cd54359e9f@gmail.com>
References: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
In-Reply-To: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: raskar.shree97@gmail.com, skhan@linuxfoundation.org, 
 david.hunter.linux@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767284290; l=1125;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=vqy/DEvaK2P0nm0mNsxwW8n+PXruCd9gkMKLRnARTow=;
 b=frtbWm1r4IhTdmJDt/qUUyVWIuZQ4oI98i6dPTEhD5SabnuSda4wo8Tm3aqoUnIOG4QeaWneq
 m1futJKEcg1Dm+HlKaO297UHXcqZgg9sUnfevh8uxHaZdFE+HwdyZXk
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an OF device ID table so the driver can bind automatically when
the RFD77402 sensor is described in Device Tree. This enables proper
enumeration via its compatible string and allows instantiation on
DT-based platforms.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index aff60a3c1a6f..3262af6f6882 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -313,10 +313,17 @@ static const struct i2c_device_id rfd77402_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, rfd77402_id);
 
+static const struct of_device_id rfd77402_of_match[] = {
+	{ .compatible = "rfdigital,rfd77402" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, rfd77402_of_match);
+
 static struct i2c_driver rfd77402_driver = {
 	.driver = {
 		.name   = RFD77402_DRV_NAME,
 		.pm     = pm_sleep_ptr(&rfd77402_pm_ops),
+		.of_match_table = rfd77402_of_match,
 	},
 	.probe = rfd77402_probe,
 	.id_table = rfd77402_id,

-- 
2.43.0

