From: David Heidelberg <david@ixit.cz>
Date: Sat, 19 Apr 2025 21:46:24 +0200
Subject: [PATCH v5 1/2] Input: add ABS_SND_PROFILE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250419-op6-tri-state-v5-1-443127078517@ixit.cz>
References: <20250419-op6-tri-state-v5-0-443127078517@ixit.cz>
In-Reply-To: <20250419-op6-tri-state-v5-0-443127078517@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, Gergo Koteles <soyer@irl.hu>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2583; i=david@ixit.cz;
 h=from:subject:message-id; bh=i5QacdZ/EVh5SDiiH8BXaqoyY6PRnf1bq8efvVTS4uk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoA/2SLFWFP6SwaDTbbhtXi/nY8CtVGPNDNxepf
 +rx00VGsByJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaAP9kgAKCRBgAj/E00kg
 cvU0EACxLXN1Bs8kSN4lpWS/FMjVCiqiOc0elNecLFBakDSaHbUMSAw4z7UFJSg+MfNzbXhnr7S
 AzEsYRhcUfvCmhvMUSOfhi0DGYpG1zdFztM6FmGRTqFNBMo5PunougTmXSZJG5satKEYipfXG1O
 g1pJK4pibcnZN3ijF9X+QUb6rBjeHHOGvOdnIx/WvjruBPJ6iSVF/SVIDP0Bmud49lpGa1GR2aE
 NSObUWdPWVxib0DgR4I8q9Z1D8AK3oSjl63J9OX6pESXO2fCjtOfokp2yU8jrKG/qLB4mdo5hio
 mFJxevAyafkFfWKCDJhrbFyJAzNinOG0u3D9T1XGVpdf9rZKR5/E49hgRe7age9xOVBYDzCDcuo
 Kpo3pe2yv/s4JTwXylRte1F6xfD7OSnuEqNitAYlhCSa0XwqTpZF85sHE/qBRSrhio3zCYyGBG+
 KccPiPxhhrKll8DZgnbvS3/JVF3doqaKDC9zYA2fIcRoLLjc2jQell+nB4tt/ZjnK5csDCRyRP6
 +YD25FOGcLutxzGEpssIVLY5Tex52S8ks4L+3lNt33TfBZkXvSHQALJd+OmCGimtz67/ufuiocI
 aBNgqKHzwNn1nTP/oQY219HhGiLIm1gyjSxvCXXay8l0y2VhljF1U7k4PKQMmM5Hzz5ELmAz9B8
 zELlvHrQ3LoulIg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Gergo Koteles <soyer@irl.hu>

ABS_SND_PROFILE used to describe the state of a multi-value sound profile
switch. This will be used for the alert-slider on OnePlus phones or other
phones.

Profile values added as SND_PROFLE_(SILENT|VIBRATE|RING) identifiers
to input-event-codes.h so they can be used from DTS.

Signed-off-by: Gergo Koteles <soyer@irl.hu>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/input/event-codes.rst    | 6 ++++++
 drivers/hid/hid-debug.c                | 1 +
 include/uapi/linux/input-event-codes.h | 9 +++++++++
 3 files changed, 16 insertions(+)

diff --git a/Documentation/input/event-codes.rst b/Documentation/input/event-codes.rst
index b4557462edd7b3fef9e9cd6c2c3cb2d05bb531ab..d43336e64d6aa4fe8a41b7e9947f4f214df6e1ab 100644
--- a/Documentation/input/event-codes.rst
+++ b/Documentation/input/event-codes.rst
@@ -241,6 +241,12 @@ A few EV_ABS codes have special meanings:
     emitted only when the selected profile changes, indicating the newly
     selected profile value.
 
+* ABS_SND_PROFILE:
+
+  - Used to describe the state of a multi-value sound profile switch.
+    An event is emitted only when the selected profile changes,
+    indicating the newly selected profile value.
+
 * ABS_MT_<name>:
 
   - Used to describe multitouch input events. Please see
diff --git a/drivers/hid/hid-debug.c b/drivers/hid/hid-debug.c
index 8433306148d57887f855578b8386bd0473cad612..2ccbae40c47cbca73df90b69e236830ff0fe4f3e 100644
--- a/drivers/hid/hid-debug.c
+++ b/drivers/hid/hid-debug.c
@@ -3511,6 +3511,7 @@ static const char *absolutes[ABS_CNT] = {
 	[ABS_DISTANCE] = "Distance",	[ABS_TILT_X] = "XTilt",
 	[ABS_TILT_Y] = "YTilt",		[ABS_TOOL_WIDTH] = "ToolWidth",
 	[ABS_VOLUME] = "Volume",	[ABS_PROFILE] = "Profile",
+	[ABS_SND_PROFILE] = "SoundProfile",
 	[ABS_MISC] = "Misc",
 	[ABS_MT_SLOT] = "MTSlot",
 	[ABS_MT_TOUCH_MAJOR] = "MTMajor",
diff --git a/include/uapi/linux/input-event-codes.h b/include/uapi/linux/input-event-codes.h
index 3b2524e4b667d1e7cc02ff5cb674e7c2ac069a66..7b10c97d13fb8d346a836f6c90c5964895856776 100644
--- a/include/uapi/linux/input-event-codes.h
+++ b/include/uapi/linux/input-event-codes.h
@@ -870,6 +870,7 @@
 
 #define ABS_VOLUME		0x20
 #define ABS_PROFILE		0x21
+#define ABS_SND_PROFILE		0x22
 
 #define ABS_MISC		0x28
 
@@ -979,4 +980,12 @@
 #define SND_MAX			0x07
 #define SND_CNT			(SND_MAX+1)
 
+/*
+ * ABS_SND_PROFILE values
+ */
+
+#define SND_PROFILE_SILENT	0x00
+#define SND_PROFILE_VIBRATE	0x01
+#define SND_PROFILE_RING	0x02
+
 #endif

-- 
2.49.0

