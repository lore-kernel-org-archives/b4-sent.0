From: =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
Date: Thu, 15 Oct 2026 01:15:42 +0300
Subject: [PATCH v2 2/2] platform/x86: hp-wmi: Add Victus 16-e0xxx board
 88EE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261015-hp-wmi-victus-8a26-v2-2-3a9e40e00e64@gmail.com>
References: <20261015-hp-wmi-victus-8a26-v2-0-3a9e40e00e64@gmail.com>
In-Reply-To: <20261015-hp-wmi-victus-8a26-v2-0-3a9e40e00e64@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ege_Kundak=C3=A7=C4=B1o=C4=9Flu?= <egekun67@gmail.com>, 
 =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016155; l=1282;
 i=mrterdo75@gmail.com; s=20261007; h=from:subject:message-id;
 bh=wA6Kph38Xcd3KIjBjUVZwiJvuWP5fYTCJExyTfaY7FU=;
 b=die1BX4zR8qbBqGwrwSobubkhEBoG8QzFwUhgiddPu7M2bH7fUVK637HqkwPddFpM5REmQdi/
 Szt1rEE4ekcALCyY1iJLPN63SwyHvRMGw4OGZHnC70p3y/K/8Zi7hig
X-Developer-Key: i=mrterdo75@gmail.com; a=ed25519;
 pk=bUOfewdT6wnBK6cWdxYDgGaI8ee0+BwtzPbg982vJP8=
X-Endpoint-Received: by B4 Relay for mrterdo75@gmail.com/20261007 with auth_id=1127
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Victus 16-e0xxx (board 88EE) is not in any of the Omen or Victus
board lists, so it falls back to the generic thermal profile handling
and the GPU cTGP offset is never enabled.

Its firmware handles HPWMI_SET_PERFORMANCE_MODE like the 8A26 one: the
mode is stored in the EC register at offset 0x95, which is what the
Victus path reads back, and cTGP is enabled in performance mode. Add
88EE to victus_thermal_profile_boards and update the comment above the
list, which only mentioned the Victus 16-d.

Tested-by: Ege Kundakçıoğlu <egekun67@gmail.com>
Assisted-by: claude-opus-5-5
Signed-off-by: Mert Erdoğan <mrterdo75@gmail.com>
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

-- 
2.56.0

