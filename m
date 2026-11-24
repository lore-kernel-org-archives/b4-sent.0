From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:38 +0800
Subject: [PATCH v2 1/9] media: v4l2-ctrls: add DV RX audio sampling rate
 and present controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-1-a154685f6989@ite.com.tw>
References: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
In-Reply-To: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=4280;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=uONLhvOawBsUyg64gstD6rmmzirFK6ytrgkdbVqwlM8=;
 b=t+GfKiFThuL8fWNAo3CF4Yrm8Ek3DT75KcBZ23nXzADx+NpigbJNn9U/HfLF/R+Ap0r7Nw4Rz
 CXPqRhjD+1qBc3NEVOzboThjWh5VSHbIzhCGZF1vFnfMmszkqHlvhuj
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HDMI and DisplayPort receivers can report whether the source sends audio
and at which sampling rate. Drivers expose this today through
driver-specific controls (tc358743 and IT6625 each define their own pair),
so userspace has to know every driver to find it.

Add two standard read-only controls to the DV control class:
V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE, the sampling rate in Hz, 0 when no
audio is received or the rate is not known, and
V4L2_CID_DV_RX_AUDIO_PRESENT, whether audio is received. Drivers set
the range of the sampling rate control.
---
 Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst | 10 ++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c              |  5 +++++
 include/uapi/linux/v4l2-controls.h                     |  2 ++
 3 files changed, 17 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
index 5918dde83efb324cd27cc4c771245cd2c38d0b0e..a9117912e9cb255a2ce452147858d927e9e3c27a 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
@@ -158,3 +158,13 @@ enum v4l2_dv_it_content_type -
     from a computer as opposed to content from a TV broadcast or an
     analog source. See ``V4L2_CID_DV_TX_IT_CONTENT_TYPE`` for the
     available content types.
+
+``V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE (integer)``
+    Reads the sampling rate, in Hz, of the audio that the receiver
+    receives from the source. It is 0 if no audio is received, or if the
+    receiver cannot determine the sampling rate. This read-only control
+    is applicable to HDMI and DisplayPort connectors.
+
+``V4L2_CID_DV_RX_AUDIO_PRESENT (boolean)``
+    Detects whether the receiver receives audio from the source. This
+    read-only control is applicable to HDMI and DisplayPort connectors.
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index e062f2088490470c42d6c579ff7675be454a29b0..579b2d297cc8246dddb4e8d4ab74aed1e6084744 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -1180,6 +1180,8 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_DV_RX_POWER_PRESENT:	return "Power Present";
 	case V4L2_CID_DV_RX_RGB_RANGE:		return "Rx RGB Quantization Range";
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:	return "Rx IT Content Type";
+	case V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE: return "Rx Audio Sampling Rate";
+	case V4L2_CID_DV_RX_AUDIO_PRESENT:	return "Rx Audio Present";
 
 	case V4L2_CID_FM_RX_CLASS:		return "FM Radio Receiver Controls";
 	case V4L2_CID_TUNE_DEEMPHASIS:		return "De-Emphasis";
@@ -1317,6 +1319,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_RDS_RX_TRAFFIC_ANNOUNCEMENT:
 	case V4L2_CID_RDS_RX_TRAFFIC_PROGRAM:
 	case V4L2_CID_RDS_RX_MUSIC_SPEECH:
+	case V4L2_CID_DV_RX_AUDIO_PRESENT:
 		*type = V4L2_CTRL_TYPE_BOOLEAN;
 		*min = 0;
 		*max = *step = 1;
@@ -1682,6 +1685,8 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_DV_TX_EDID_PRESENT:
 	case V4L2_CID_DV_RX_POWER_PRESENT:
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:
+	case V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE:
+	case V4L2_CID_DV_RX_AUDIO_PRESENT:
 	case V4L2_CID_RDS_RX_PTY:
 	case V4L2_CID_RDS_RX_PS_NAME:
 	case V4L2_CID_RDS_RX_RADIO_TEXT:
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index d17e41d51d2ec1ccb9e8ceb3ccc89ebc4381a4cd..52124b7acdeab787978029aa49ea75d0ad4cc534 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1301,6 +1301,8 @@ enum v4l2_dv_it_content_type {
 #define V4L2_CID_DV_RX_POWER_PRESENT		(V4L2_CID_DV_CLASS_BASE + 100)
 #define V4L2_CID_DV_RX_RGB_RANGE		(V4L2_CID_DV_CLASS_BASE + 101)
 #define V4L2_CID_DV_RX_IT_CONTENT_TYPE		(V4L2_CID_DV_CLASS_BASE + 102)
+#define V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE	(V4L2_CID_DV_CLASS_BASE + 103)
+#define V4L2_CID_DV_RX_AUDIO_PRESENT		(V4L2_CID_DV_CLASS_BASE + 104)
 
 #define V4L2_CID_FM_RX_CLASS_BASE		(V4L2_CTRL_CLASS_FM_RX | 0x900)
 #define V4L2_CID_FM_RX_CLASS			(V4L2_CTRL_CLASS_FM_RX | 1)

-- 
2.34.1

