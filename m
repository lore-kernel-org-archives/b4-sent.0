From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/2] Input: sx8654 - fix SX8650 reset and status handling
Date: Mon, 23 Nov 2026 21:41:44 +0300
Message-Id: <20261123-b4-sx8650-fixes-v1-0-b82a881b971d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3SQT3eIKCzNTA920zIrUYt0UE0tL06SktJQUc0sloK6ColSwBFB
 TdCyEX1yalJWaXAIyRqm2FgALnWJKcwAAAA==
X-Change-ID: 20261123-b4-sx8650-fixes-d4995bbfdd79
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459304; l=1195;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=fOKx4+gCcDyeBd94X9G1hP6GxrLI5moZQp1CGVh7qmk=;
 b=Qa1kbX5hZO3j4z/+XWtTl3fu6WLuAZ5EjS8JDJb5FKFxyObXFt5ngtF44SLSfh1wexQIV6XHm
 ROzscsE+D9YAQn8pi25u2QP4VvPR+3P3b20x7bf91QW77o3Eiu+orwQ
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix two independent issues introduced with SX8650 support. Its soft-reset
register is 0x1f, unlike the other supported variants. Also retain the
signed SMBus status return so an I2C error cannot be interpreted as a
conversion interrupt.

On Almond+, writing the old reset address acknowledged but left CTRL2
unchanged; using 0x1f restored the documented reset value. An isolated
harness using the actual driver helpers exercised 39167 cases under
ASan/UBSan, including negative status reads and both reset paths. ARM
built-in and module compilation passed on Linux v7.4-rc4.

These fixes are independent of the Cortina platform series. Local
OpenWrt conversion-rate and recovery policy changes are not included.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Fil Dunsky (2):
      Input: sx8654 - use the SX8650 soft-reset register
      Input: sx8654 - check SX8650 status read errors

 drivers/input/touchscreen/sx8654.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-sx8650-fixes-d4995bbfdd79

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

