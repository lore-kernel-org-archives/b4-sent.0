From: =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
Date: Sat, 10 Oct 2026 09:38:10 +0300
Subject: [PATCH] platform/x86: hp-wmi: Add Victus 16-e0xxx board 88EE
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261010-hp-wmi-victus-88ee-v1-1-e2200686bc2b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12NzU7DMBAGXyXymUVeJ/6LEOI9UA+2s2kX4bbES
 UCq+u44DSduO9K3MzdRaGIqom9uYqKVC1/OFfCpEekUzkcCHioLJZVBiRJOV/jODCuneSngHBG
 gHZXr3KA624r6eJ1o5J+H9P2wc1niB6V5M/0tJvpaam3eZyJTKeFR65uXPSbt/1hQBlYE3C5tQ
 sLOS/d2zIE/n9Mlv27qGApBhcxz33g3ytYro0k7qTwOmqwJiFFJq3SHY4yYWt+Kw/3+C8AFNnU
 LAQAA
X-Change-ID: 20261010-hp-wmi-victus-88ee-17f2848d2473
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ege_Kundak=C3=A7=C4=B1o=C4=9Flu?= <egekun67@gmail.com>, 
 =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791614297; l=2781;
 i=mrterdo75@gmail.com; s=20261007; h=from:subject:message-id;
 bh=krMjwVPvW4p6J7pzdTxvOgoD3/uAh2OaFLpfxtDbAN0=;
 b=i8Bz2jidRj5j39v1cloaOrkqxqI3DRXdZVN9wBBGCS8B2mmdvWNW3YLlwvYnEdaVHhrp4D2N4
 kOIBIo3qQadC6USbVfi/tcXgvlMKO5QDLMVE7v+7B1KTCan+AKM3iZh
X-Developer-Key: i=mrterdo75@gmail.com; a=ed25519;
 pk=bUOfewdT6wnBK6cWdxYDgGaI8ee0+BwtzPbg982vJP8=
X-Endpoint-Received: by B4 Relay for mrterdo75@gmail.com/20261007 with auth_id=1127
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Victus 16-e0xxx (board 88EE) is not in any of the Omen or Victus
board lists, so it falls back to the generic thermal profile handling
and the GPU cTGP offset is never enabled.

Its DSDT handles the 0x20008 type 0x1A query like the 8A26 one: the
mode is stored in the EC register at offset 0x95, which is what the
Victus path reads back, and cTGP is enabled in performance mode. Add
88EE to victus_thermal_profile_boards and update the comment above the
list, which only mentioned the Victus 16-d.

Ege Kundakçıoğlu tested this on a Victus 16-e0xxx (BIOS F.27, RTX 3060
Laptop GPU). With the unpatched module the GPU power limit stays at
80 W in the balanced, performance and quiet profiles. With this patch
performance gives 95 W, balanced 80 W and quiet 30 W, the EC register
at 0x95 matches the selected profile, and in performance the limit is
back at 95 W after unplugging and replugging AC.

Unlike on 8A26, the 0x1A query only sets cTGP here. Dynamic Boost (the
NPCF DTGP flag) reads back as 0, as the only WMI query that sets it is
0x22, which the Victus path does not send. The GPU still reaches its
95 W maximum, and the tester sees the same maximum on Windows.

This patch was prepared with an AI coding agent (Claude Code, using
Claude Opus 5.5). It checked the DSDT, wrote the change and the test
script. Ege ran the test on the laptop and I checked the results.

Tested-by: Ege Kundakçıoğlu <egekun67@gmail.com>
Assisted-by: claude-opus-5-5
Signed-off-by: Mert Erdoğan <mrterdo75@gmail.com>
---
This applies on top of my pending 8A26 patch for the same board list:
https://lore.kernel.org/r/20261007-hp-wmi-victus-8a26-v1-1-8a256ac14908@gmail.com

Before this patch the owner of the laptop enabled cTGP with an
acpi_call workaround sending the same 0x1A query in performance mode.
---
 drivers/platform/x86/hp/hp-wmi.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 15f1e9f63..1c16a0656 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -230,8 +230,9 @@ static const char * const omen_timed_thermal_profile_boards[] = {
 	"8BAD",
 };
 
-/* DMI Board names of Victus 16-d laptops */
+/* DMI Board names of Victus 16-d and 16-e laptops */
 static const char * const victus_thermal_profile_boards[] = {
+	"88EE",
 	"88F8",
 	"8A25",
 	"8A26",

---
base-commit: 98f039265e580291d5e76a11b2072541fbb1c393
change-id: 20261010-hp-wmi-victus-88ee-17f2848d2473
prerequisite-message-id: <20261007-hp-wmi-victus-8a26-v1-1-8a256ac14908@gmail.com>
prerequisite-patch-id: 3f4190ae015c5cfc0c87dd8b3f7829a95effb9cb

Best regards,
--  
Mert Erdoğan <mrterdo75@gmail.com>

