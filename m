From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH RESEND 0/4] media: i2c: imx214: Add support for 23.88MHz
 clock
Date: Sat, 08 Mar 2025 22:47:54 +0100
Message-Id: <20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741470489; l=883;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=zUId9PjSmn0obYH/MQAPLhkKVd5X65P4v7UboY1hDOU=;
 b=kuBfcjUn9LmwUeVpxN9JMXjKpC9oj0KgSPIF23LkhTf4kcucoLbcuUuXdPD1nrIiL6oLkcO+J
 2jDHZ+cYj/3BXn2MDnuYRTe9FSn8xeDi56og5e7IYivKLsZXM3Dx3Zz
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 driver currently supports only a 24MHz external clock. But
there are devices, like Qualcomm-MSM8916-based phones, which cannot
provide this frequency. To make the sensor usable by those devices, add
support for 23.88MHz clock.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (4):
      media: i2c: imx214: Calculate link bit rate from clock frequency
      media: i2c: imx214: Prepare for variable clock frequency
      media: i2c: imx214: Read clock frequency from device tree
      media: i2c: imx214: Add support for 23.88MHz clock

 drivers/media/i2c/imx214.c | 188 +++++++++++++++++++++++++++++++++++----------
 1 file changed, 146 insertions(+), 42 deletions(-)
---
base-commit: 942a51cca29ed20f23ba37f34ff52a6af32ab6c4
change-id: 20250205-imx214_clk_freq-3bf6a05de35a

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

