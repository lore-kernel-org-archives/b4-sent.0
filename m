From: Samuel Wheeler <swheel33@gmail.com>
Date: Wed, 11 Nov 2026 21:54:26 -0500
Subject: [PATCH 1/2] platform/x86: hp-wmi: Only use the low byte of the
 thermal profile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-omnibook-8eb4-v1-1-3127f45cc338@gmail.com>
References: <20261111-omnibook-8eb4-v1-0-3127f45cc338@gmail.com>
In-Reply-To: <20261111-omnibook-8eb4-v1-0-3127f45cc338@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shang En Sim <sim@shangen.org>, Samuel Wheeler <swheel33@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794452066; l=2515;
 i=swheel33@gmail.com; s=20261112; h=from:subject:message-id;
 bh=Lv1LLK3vrHWNEFO3BC4NJWJr1q0dg08n6iLOShJ9Tic=;
 b=Qka/uR5xcS7FHPblj1ely7UHVrDuBfHLQLgouil2nzkRL45SdmkZ2PNxVkQsYOq5kcEJsgPfq
 Cge6AMnKuZxB3lk16dHAYamO1iNcDh9SMfvRi66zr4UdjxUJ2QImhd9
X-Developer-Key: i=swheel33@gmail.com; a=ed25519;
 pk=cokeT6B31W84o+Gc4wuP2okLF8wShbbGQ7pb5h5JPXg=
X-Endpoint-Received: by B4 Relay for swheel33@gmail.com/20261112 with auth_id=1494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the HP OmniBook Ultra Laptop 14-kd0xxx (board 8EB4, BIOS F.06), the
HPWMI_THERMAL_PROFILE_QUERY read returns the active profile in byte 0,
followed by status flags and a constant. With the "default" profile
active the four bytes are 01 11 04 00. thermal_profile_get() returns the
whole 32-bit value (0x041101), which matches none of the
HP_THERMAL_PROFILE_* values, so reading the platform profile always
fails with -EINVAL:

  platform_profile: Failed to get profile for handler hp-wmi

and /sys/firmware/acpi/platform_profile returns "Invalid argument".

The firmware's GTPS method (in the SSDT that defines \_SB.WMID) fills
byte 0 from the EC field GFCM (0-5), byte 1 with status flags (ONTB,
INBG, DPIN, PWDN, IBGE, MSFG) and byte 2 with 0x04. Setting a profile
already works: GFCM becomes 0, 1, 2 and 3 for performance, default, cool
and quiet.

Mask the value to its low byte. This also stops
thermal_profile_setup() from writing the status bytes back through
thermal_profile_set(tp) at probe time. That write was harmless on this
firmware, whose STPS method only reads byte 0, but it was not intended.
On firmware that already returns a zero-extended value the mask changes
nothing.

Tested on the OmniBook Ultra 14-kd0xxx: platform_profile reads
"balanced" instead of failing, and each profile reads back after being
set.

This patch was prepared with an AI coding assistant (Claude, by
Anthropic). It decompiled the ACPI tables, traced the WMI query, wrote
the change and this description, and ran the tests on my laptop under
my direction. I reviewed the change and the test results.

Signed-off-by: Samuel Wheeler <swheel33@gmail.com>
---
 drivers/platform/x86/hp/hp-wmi.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 0069af86800e..46c9a5a532ba 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -2117,7 +2117,16 @@ static int platform_profile_omen_set(struct device *dev,
 
 static int thermal_profile_get(void)
 {
-	return hp_wmi_read_int(HPWMI_THERMAL_PROFILE_QUERY);
+	int tp = hp_wmi_read_int(HPWMI_THERMAL_PROFILE_QUERY);
+
+	if (tp < 0)
+		return tp;
+
+	/*
+	 * The profile is in the low byte. Some firmware (e.g. board 8EB4)
+	 * returns status flags and a constant in the upper bytes.
+	 */
+	return tp & 0xff;
 }
 
 static int thermal_profile_set(int thermal_profile)

-- 
2.56.0

