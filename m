From: Dennis Nilsson <kontakt@dennisnilsson.se>
Date: Sat, 17 Oct 2026 10:33:59 +0200
Subject: [PATCH 2/2] platform/x86: acer-wmi: Add support for Acer Nitro
 AN16-41
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-acer-nitro-an16-41-v1-2-c2e7a0ee7303@dennisnilsson.se>
References: <20261017-acer-nitro-an16-41-v1-0-c2e7a0ee7303@dennisnilsson.se>
In-Reply-To: <20261017-acer-nitro-an16-41-v1-0-c2e7a0ee7303@dennisnilsson.se>
To: "Lee, Chun-Yi" <jlee@suse.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dennis Nilsson <kontakt@dennisnilsson.se>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792226037; l=1346;
 i=kontakt@dennisnilsson.se; s=20261017; h=from:subject:message-id;
 bh=QTBqp6Vi/0AxROqLBEXCoQ7Mc+MetYvOr68Lo+Bb148=;
 b=f4gjnUTG8Zq45IQkm8WzVjhyr/j5xFLz28d1tcMpLPw9f2BKuD+B2Dw+5hK9EVccwUG1agqiI
 frEtdknVzTaCSb57rcTJunHN9VjWi2ltoK/b8hbe77aqppAdVMklgCn
X-Developer-Key: i=kontakt@dennisnilsson.se; a=ed25519;
 pk=H+jadpTa8sEscQhkbeWZC2woL8j7NYwN5m1YCjkHJRQ=
X-Endpoint-Received: by B4 Relay for kontakt@dennisnilsson.se/20261017 with auth_id=1223
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Acer Nitro AN16-41 supports the Predator Sense v4 platform profile,
hwmon sensors and fan control, but currently needs the predator_v4
module parameter to expose them. Add a DMI quirk for it, reusing the
Nitro AN515-58 quirk entry since the feature set is the same.

Tested on BIOS V1.03: all five platform profiles are offered by the
firmware and switching them changes the fan curve, both fan speeds and
the temperature sensors read correctly, and pwm1/pwm2 work in custom,
maximum and automatic mode.

Assisted-by: LLM
Signed-off-by: Dennis Nilsson <kontakt@dennisnilsson.se>
---
 drivers/platform/x86/acer-wmi.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/platform/x86/acer-wmi.c b/drivers/platform/x86/acer-wmi.c
index 323179c43..3a018fdf5 100644
--- a/drivers/platform/x86/acer-wmi.c
+++ b/drivers/platform/x86/acer-wmi.c
@@ -681,6 +681,15 @@ static const struct dmi_system_id acer_quirks[] __initconst = {
 		},
 		.driver_data = &quirk_acer_travelmate_2490,
 	},
+	{
+		.callback = dmi_matched,
+		.ident = "Acer Nitro AN16-41",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "Acer"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "Nitro AN16-41"),
+		},
+		.driver_data = &quirk_acer_nitro_an515_58,
+	},
 	{
 		.callback = dmi_matched,
 		.ident = "Acer Nitro AN515-58",

-- 
2.53.0

