From: Carlos Baiget Orts <asinfreedom@gmail.com>
Date: Fri, 30 Oct 2026 00:24:33 +0100
Subject: [PATCH] platform/x86/amd/pmc: Add LG Ultra PC 16U70Q to quirks
 list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-lg-16u70q-quirk-v1-1-946f25fea731@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNL3Zx0XUOzUnODQt3C0syibN20xFQLM5OUJBMDUxMloK6CotS0zAq
 widGxtbUAe9FBKGEAAAA=
X-Change-ID: 20261029-lg-16u70q-quirk-fae864db4054
To: Shyam Sundar S K <Shyam-sundar.S-k@amd.com>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Carlos Baiget Orts <asinfreedom@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793316277; l=1794;
 i=asinfreedom@gmail.com; s=20261029; h=from:subject:message-id;
 bh=2scvI5X0yKGdqQL9IjH/N2UwRjmOVAOBN1ZYC7tkAKQ=;
 b=3OXXkpx5QIs0LOCthtkmrsEfTnOQv1xwWaAlTW+w0xglQw1x5LgxRtli1vgJa5FesMFhDd70W
 ngTCrZuBp1ND6QIBtNuqwJhFjT+BOc4so4i7/3eKuDbrGEA1J0nSP4W
X-Developer-Key: i=asinfreedom@gmail.com; a=ed25519;
 pk=aOfyH/lp+7onSrl00TdpSmziKWxCLG6uwG7m69lGXHI=
X-Endpoint-Received: by B4 Relay for asinfreedom@gmail.com/20261029 with auth_id=1359
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LG Ultra PC 16U70Q (Ryzen 7 5825U) spends ~5 seconds in the noirq
resume phase on every s2idle resume. This is the same NVMe SMI handler
issue seen on other Cezanne systems. Skipping it with s2idle_bug_mmio
brings it down to ~32 ms.

As on the other Cezanne systems, the entry must also keep the spurious
IRQ1 (8042) wakeup workaround. Otherwise the system wakes up immediately
from s2idle, so use quirk_s2idle_spurious_8042.

Link: https://gitlab.freedesktop.org/drm/amd/-/issues/6021
Cc: Mario Limonciello <mario.limonciello@amd.com>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Carlos Baiget Orts <asinfreedom@gmail.com>
---
Tested on the 16U70Q (BIOS L2UG0160) with a locally built amd_pmc
carrying this entry: noirq resume drops from ~5.2 s to ~32 ms, and
s2idle no longer wakes up immediately from spurious IRQ1 events.
---
 drivers/platform/x86/amd/pmc/pmc-quirks.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/platform/x86/amd/pmc/pmc-quirks.c b/drivers/platform/x86/amd/pmc/pmc-quirks.c
index fed6c51879..ca188d815c 100644
--- a/drivers/platform/x86/amd/pmc/pmc-quirks.c
+++ b/drivers/platform/x86/amd/pmc/pmc-quirks.c
@@ -386,6 +386,15 @@ static const struct dmi_system_id fwbug_list[] = {
 			DMI_MATCH(DMI_BOARD_NAME, "WUJIE Series-X5SP4NAG"),
 		}
 	},
+	/* https://gitlab.freedesktop.org/drm/amd/-/issues/6021 */
+	{
+		.ident = "LG Ultra PC 16U70Q",
+		.driver_data = &quirk_s2idle_spurious_8042,
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "LG Electronics"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "16U70Q"),
+		}
+	},
 	{}
 };
 

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261029-lg-16u70q-quirk-fae864db4054

Best regards,
-- 
Carlos Baiget Orts <asinfreedom@gmail.com>

