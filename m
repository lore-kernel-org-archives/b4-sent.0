From: =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
Date: Thu, 15 Oct 2026 01:15:41 +0300
Subject: [PATCH v2 1/2] platform/x86: hp-wmi: Add Victus 16-d1xxx board
 8A26 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261015-hp-wmi-victus-8a26-v2-1-3a9e40e00e64@gmail.com>
References: <20261015-hp-wmi-victus-8a26-v2-0-3a9e40e00e64@gmail.com>
In-Reply-To: <20261015-hp-wmi-victus-8a26-v2-0-3a9e40e00e64@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Mert_Erdo=C4=9Fan?= <mrterdo75@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016155; l=1146;
 i=mrterdo75@gmail.com; s=20261007; h=from:subject:message-id;
 bh=L1CH7dlpQUM4NNhDRcqjtEsJk9TWWjgNN0gDBPxarCY=;
 b=11xG9szFUV7nbSEEVY2pC/SJryjsjF31k0UFfR3IXsMvt6cUqDy5OYltf7IOJ9aJ8p2qinc0c
 GXQYbZrlQaFBv1zjlDK+vlA42PBAtqi7XRSKzJgTg9CcIo4SELJBB6g
X-Developer-Key: i=mrterdo75@gmail.com; a=ed25519;
 pk=bUOfewdT6wnBK6cWdxYDgGaI8ee0+BwtzPbg982vJP8=
X-Endpoint-Received: by B4 Relay for mrterdo75@gmail.com/20261007 with auth_id=1127
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Victus 16-d1xxx ships with at least two DMI board names. 8A25 is
already listed in victus_thermal_profile_boards, but 8A26 is not, so
on those machines the driver falls back to the generic thermal policy.
Selecting a platform profile then never issues the Victus performance
mode WMI call (HPWMI_SET_PERFORMANCE_MODE via HPWMI_GM), and the
firmware keeps the GPU's +15 W configurable TGP offset disabled.

Add 8A26 to the list so these machines use the same Victus thermal
profile path as 8A25.

Assisted-by: claude-opus-5-5
Signed-off-by: Mert Erdoğan <mrterdo75@gmail.com>
---
 drivers/platform/x86/hp/hp-wmi.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 387f60e88..15f1e9f63 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -234,6 +234,7 @@ static const char * const omen_timed_thermal_profile_boards[] = {
 static const char * const victus_thermal_profile_boards[] = {
 	"88F8",
 	"8A25",
+	"8A26",
 };
 
 /* DMI board-specific feature data for Omen and Victus laptops. */

-- 
2.56.0

