From: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Date: Mon, 10 Nov 2025 16:52:16 +0800
Subject: [PATCH RESEND] Input: atkbd - skip deactivate for HONOR FMB-P's
 internal keyboard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-honor-v1-1-c6fa244d2a8b@linux.dev>
X-B4-Tracking: v=1; b=H4sIAL+nEWkC/12MsQrCMBRFf6W82UhfUNo4OdjVQUfp0DQv5kFJJ
 NFQKf13Q0fHc+/hLJAoMiU4VQtEypw4+AK4q2B0g3+SYFMYZC2PWEspXPAhilaPSpNtSQ8NFPc
 VyfK8dR5w6+7d9QJ92R2nd4jfLZ9xe/9KGQUKa1t1ICMbHNR5Yv+Z94Yy9Ou6/gDVxd9WogAAA
 A==
X-Change-ID: 20251022-honor-8bc9bef8eba7
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Hans de Goede <hansg@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@kernel.org, zhanjun@uniontech.com, niecheng1@uniontech.com, 
 cryolitia@uniontech.com, Mingcong Bai <jeffbai@aosc.io>, 
 Kexy Biscuit <kexybiscuit@aosc.io>, Hans de Goede <hansg@kernel.org>, 
 Mikura Kyouka <mikurakyouka@aosc.io>, 
 "foad.elkhattabi" <foad.elkhattabi@gmail.com>, 
 Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762764740; l=1781;
 i=cryolitia.pukngae@linux.dev; s=20250730; h=from:subject:message-id;
 bh=dDOq3UaFkFzKOUAwy6Vt2xf7bR4f29gMNu4AHKX58gI=;
 b=/NMHIn/AzlcBr/Uqra5zyQEmXRzq9r45qdvhasb8cZwMBmkJnWR+wg9Wrt8/JaB3yMr0rW1LZ
 PJaxqqNRoCdCtrdpXCQw5OXAKKgF83tOtVSwRPCCFFQrGeV+Wt3nqAA
X-Developer-Key: i=cryolitia.pukngae@linux.dev; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia.pukngae@linux.dev/20250730 with auth_id=540
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After commit 9cf6e24c9fbf17e52de9fff07f12be7565ea6d61 ("Input: atkbd -
do not skip atkbd_deactivate() when skipping ATKBD_CMD_GETID"), HONOR
FMB-P, aka HONOR MagicBook Pro 14 2025's internal keyboard stops
working. Adding the atkbd_deactivate_fixup quirk fixes it.

DMI: HONOR FMB-P/FMB-P-PCB, BIOS 1.13 05/08/2025

Fixes: 9cf6e24c9fbf17e52de9fff07f12be7565ea6d61 ("Input: atkbd - do not skip atkbd_deactivate() when skipping ATKBD_CMD_GETID")
Reported-by: Mikura Kyouka <mikurakyouka@aosc.io>
Link: https://www.xiaohongshu.com/explore/68738d0a0000000012015a79
Link: https://club.honor.com/cn/thread-29463529-1-1.html
Link: https://club.honor.com/cn/thread-29490444-1-1.html
Reported-by: foad.elkhattabi <foad.elkhattabi@gmail.com>
Link: https://bugzilla.kernel.org/show_bug.cgi?id=220384
Signed-off-by: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Reviewed-by: Hans de Goede <hansg@kernel.org>
---
Previous: https://lore.kernel.org/all/20251022-honor-v1-1-ff894ed271a9@linux.dev/
---
 drivers/input/keyboard/atkbd.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/input/keyboard/atkbd.c b/drivers/input/keyboard/atkbd.c
index 6c999d89ee4b..422e28ad1e8e 100644
--- a/drivers/input/keyboard/atkbd.c
+++ b/drivers/input/keyboard/atkbd.c
@@ -1937,6 +1937,13 @@ static const struct dmi_system_id atkbd_dmi_quirk_table[] __initconst = {
 		},
 		.callback = atkbd_deactivate_fixup,
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HONOR"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "FMB-P"),
+		},
+		.callback = atkbd_deactivate_fixup,
+	},
 	{ }
 };
 

---
base-commit: 552c50713f273b494ac6c77052032a49bc9255e2
change-id: 20251022-honor-8bc9bef8eba7

Best regards,
-- 
Cryolitia PukNgae <cryolitia.pukngae@linux.dev>

