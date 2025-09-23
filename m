From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 23 Sep 2025 02:14:50 +0200
Subject: [PATCH] Input: ps2-gpio - fix typo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-ps2-typo-v1-1-03d2468acc32@posteo.net>
X-B4-Tracking: v=1; b=H4sIAHnm0WgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyNj3YJiI92SyoJ8XVMzcxOzZFMzC1ODRCWg8oKi1LTMCrBR0bG1tQC
 l/lTBWgAAAA==
X-Change-ID: 20250923-ps2-typo-56746c56850a
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758586497; l=1181;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=IPy139GDL40Ao6EBEyf0Bsm3lBOPa8B5AbzRx2Cm4mo=;
 b=0utriwySV/XiOEb9kOXBBXidP+4XaLTRlLPAaNEOcq1fRowy6LyK5hrLbVNuQ4g2HcXq8A1/w
 +WW8rCLQcRNBp+XDkZ6eoN9ONeLve3nHjGMRB3uiFLMRv+ePmLzQh/r
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"The data line must be sampled" makes much more sense than what was
previously written, and given that "s" and "d" are neighbors on the
QWERTY keybord, it was probably a typo.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/input/serio/ps2-gpio.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/input/serio/ps2-gpio.c b/drivers/input/serio/ps2-gpio.c
index 93769910ce24ea96265b67e2d04dfd768b9d6c6b..46fb7667b244a37e29c19ac363d17e0c32d7f822 100644
--- a/drivers/input/serio/ps2-gpio.c
+++ b/drivers/input/serio/ps2-gpio.c
@@ -50,7 +50,7 @@
  * interrupt interval should be ~60us. Let's allow +/- 20us for frequency
  * deviations and interrupt latency.
  *
- * The data line must be samples after ~30us to 50us after the falling edge,
+ * The data line must be sampled after ~30us to 50us after the falling edge,
  * since the device updates the data line at the rising edge.
  *
  * ___            ______            ______            ______            ___

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250923-ps2-typo-56746c56850a

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

