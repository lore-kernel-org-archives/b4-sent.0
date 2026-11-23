From: =?utf-8?q?Fr=C3=A9d=C3=A9ric_Aime?= <frederic.aime@gmail.com>
Date: Mon, 23 Nov 2026 22:57:10 +0100
Subject: [PATCH] platform/asus: asus-wmi: Detect Vivobook thermal policy
 without presence bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261123-proart-thermal-policy-v1-1-396374f9e1d8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtgRiLSq5Qu0jjqiDVhEkuLe
 HfTdvkW/++QWIUTXKsdlF+SJKwF5lKBn9w6MkpfDFRTaww1GDU4zZgn1qdbMIZF/Aeps7b1bBs
 aCEoblQd5/763+99pe8zs83cGx3ECY0vy6nkAAAA=
X-Change-ID: 20261123-proart-thermal-policy-28556ce532f2
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>
Cc: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Fr=C3=A9d=C3=A9ric_Aime?= <frederic.aime@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795471029; l=3936;
 i=frederic.aime@gmail.com; s=20261123; h=from:subject:message-id;
 bh=Wf3A0r7uX2ZUoDRLKINwzfnBD6nYGfliM3J1iNQZ+80=;
 b=je2sq2pyurw1z4J9SAwuhxejIsQmEHl9jcHi5ltd6GWMmYXi7s+v2fPBnsmB/20hDtkxB4jYT
 KhXsoEpQDGJCE1BDcBkGvkaQrWUBgHnOlGUKaXX/gQ3rvJk0Rprh9Go
X-Developer-Key: i=frederic.aime@gmail.com; a=ed25519;
 pk=xkFcmpr+qwkxDu8LFMuiki1YjzZT/JWGb/oXAMSMFOE=
X-Endpoint-Received: by B4 Relay for frederic.aime@gmail.com/20261123 with auth_id=1624
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ProArt Studiobook 16 (H7604JV, BIOS H7604JV.305) implements the
Vivobook-style thermal policy device 0x00110019: its WMNB DEVS handler
calls ATKD.FANL(), which switches the EC fan curve, updates the DPTF OEM
variable ODV0 (notifying IETM with 0x88) and selects the matching NVIDIA
power table. This is what MyASUS uses on Windows to switch between
Standard (0), Whisper (1), Performance (2) and Full Speed (3).

However, its DSTS reply for this device does not set
ASUS_WMI_DSTS_PRESENCE_BIT. It returns the current mode with the USER and
BIOS bits set instead, e.g. 0x02060002 in Performance mode. As
asus_wmi_dev_is_present() requires the presence bit, the device is never
detected and no platform_profile is registered. power-profiles-daemon
then falls back to its placeholder driver, the machine stays in
Standard mode, and Intel DPTF (thermald --adaptive) keeps applying the
Standard policy, which caps the CPU at PL1 30 W / PL2 55 W as soon as
one of the board sensors reaches 65 °C.

Device IDs this BIOS does not implement still fail with -ENODEV, so a
successful DSTS reply with both the USER and BIOS bits set reliably
indicates that the device exists. Accept that pattern for the Vivobook
thermal policy device in addition to the presence bit.

The existing Vivobook mapping matches this firmware: quiet -> 1
(Whisper), balanced -> 0 (Standard), performance -> 2 (Performance).
Tested on the H7604JV: power-profiles-daemon now uses the
platform_profile driver, each profile switches the firmware mode (DSTS
0x02060001 / 0x02060000 / 0x02060002) and ODV0 accordingly, and
thermald --adaptive applies the matching OEM policy (e.g. PL1 130 W /
PL2 157 W in performance instead of 30 W / 55 W).

Signed-off-by: Frédéric Aime <frederic.aime@gmail.com>
---
 drivers/platform/asus/asus-wmi.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/asus/asus-wmi.c b/drivers/platform/asus/asus-wmi.c
index b33ebdb21..66a68944d 100644
--- a/drivers/platform/asus/asus-wmi.c
+++ b/drivers/platform/asus/asus-wmi.c
@@ -660,6 +660,24 @@ static bool asus_wmi_dev_is_present(struct asus_wmi *asus, u32 dev_id)
 	return status == 0 && (retval & ASUS_WMI_DSTS_PRESENCE_BIT);
 }
 
+/*
+ * Some BIOSes implement the Vivobook-style thermal policy device but leave
+ * ASUS_WMI_DSTS_PRESENCE_BIT clear in its DSTS reply. The ProArt Studiobook 16
+ * (H7604JV) for instance returns the current mode with the USER and BIOS bits
+ * set (e.g. 0x02060002), while unsupported device IDs still fail with -ENODEV.
+ * Accept that pattern as well so platform_profile works on these machines.
+ */
+static bool asus_wmi_throttle_thermal_policy_vivo_is_present(struct asus_wmi *asus)
+{
+	const u32 mask = ASUS_WMI_DSTS_USER_BIT | ASUS_WMI_DSTS_BIOS_BIT;
+	u32 retval;
+
+	if (asus_wmi_get_devstate(asus, ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY_VIVO, &retval))
+		return false;
+
+	return (retval & ASUS_WMI_DSTS_PRESENCE_BIT) || (retval & mask) == mask;
+}
+
 /* Keystone *******************************************************************/
 
 static int keystone_check_present(struct asus_wmi *asus)
@@ -5222,7 +5240,7 @@ static int asus_wmi_add(struct platform_device *pdev)
 
 	if (asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY))
 		asus->throttle_thermal_policy_dev = ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY;
-	else if (asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY_VIVO))
+	else if (asus_wmi_throttle_thermal_policy_vivo_is_present(asus))
 		asus->throttle_thermal_policy_dev = ASUS_WMI_DEVID_THROTTLE_THERMAL_POLICY_VIVO;
 
 	if (asus_wmi_dev_is_present(asus, ASUS_WMI_DEVID_TUF_RGB_MODE))

---
base-commit: 2268d837dea13a78639fa3dad60472bb67478709
change-id: 20261123-proart-thermal-policy-28556ce532f2

Best regards,
--  
Frédéric Aime <frederic.aime@gmail.com>

