From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:39 +0800
Subject: [PATCH v2 2/9] media: v4l2-ctrls: add the DV RX audio type control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-2-a154685f6989@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=5441;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=RNRg4EXuqjc+rzUxaNXgcFowld6CrgvTSSJCe7lTML4=;
 b=tss+akdrZLs1Y6A2Ba9cLaDhT16sFldCf3WKa+iGPwco/VAETuXAWw0IBD9as/esGPfrPVAyY
 5LsW1bN5/xiAlxvCCJK1l3Ak1Gw8XYiX95MCmrB6FTaWnIPPcsGPIhQ
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An HDMI or DisplayPort receiver can pass on linear PCM, compressed audio
in IEC 61937 format, high bit rate (HBR) compressed audio, or one bit
(DSD) audio. Userspace capturing that audio needs to know which kind it
is, for example to decide whether the samples can be played as PCM or
must be passed through to a decoder.

Add a standard read-only menu control, V4L2_CID_DV_RX_AUDIO_TYPE, to the
DV control class with these four values. It describes how the audio is
carried, not the codec: the codec of compressed audio is identified by
the IEC 61937 data.
---
 .../userspace-api/media/v4l/ext-ctrls-dv.rst       | 25 ++++++++++++++++++++++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          | 12 +++++++++++
 include/uapi/linux/v4l2-controls.h                 |  7 ++++++
 3 files changed, 44 insertions(+)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
index a9117912e9cb255a2ce452147858d927e9e3c27a..feddf5dbe18665855f5ef362260e6439606bfc6b 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-dv.rst
@@ -168,3 +168,28 @@ enum v4l2_dv_it_content_type -
 ``V4L2_CID_DV_RX_AUDIO_PRESENT (boolean)``
     Detects whether the receiver receives audio from the source. This
     read-only control is applicable to HDMI and DisplayPort connectors.
+
+``V4L2_CID_DV_RX_AUDIO_TYPE``
+    (enum)
+
+enum v4l2_dv_rx_audio_type -
+    Reads how the source sends the audio that the receiver receives. It
+    describes the kind of audio stream, not the codec of compressed
+    audio. The value is only meaningful while
+    ``V4L2_CID_DV_RX_AUDIO_PRESENT`` is set. This read-only control is
+    applicable to HDMI and DisplayPort connectors. Possible values are:
+
+.. flat-table::
+    :header-rows:  0
+    :stub-columns: 0
+
+    * - ``V4L2_DV_RX_AUDIO_TYPE_LPCM``
+      - Linear PCM audio.
+    * - ``V4L2_DV_RX_AUDIO_TYPE_IEC61937``
+      - Compressed audio carried as IEC 61937 data, for example AC-3 or
+	DTS. The codec is identified by the IEC 61937 data itself.
+    * - ``V4L2_DV_RX_AUDIO_TYPE_HBR``
+      - High bit rate compressed audio, carried as IEC 61937 data in HDMI
+	High Bit Rate audio packets.
+    * - ``V4L2_DV_RX_AUDIO_TYPE_ONE_BIT``
+      - One bit audio (DSD).
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-defs.c b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
index 579b2d297cc8246dddb4e8d4ab74aed1e6084744..05e8e781d964c488f3f8ce941c10b8474609e86f 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-defs.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-defs.c
@@ -491,6 +491,13 @@ const char * const *v4l2_ctrl_get_menu(u32 id)
 		"No IT Content",
 		NULL,
 	};
+	static const char * const dv_rx_audio_type[] = {
+		"LPCM",
+		"IEC 61937",
+		"High Bit Rate",
+		"One Bit",
+		NULL,
+	};
 	static const char * const detect_md_mode[] = {
 		"Disabled",
 		"Global",
@@ -722,6 +729,8 @@ const char * const *v4l2_ctrl_get_menu(u32 id)
 	case V4L2_CID_DV_TX_IT_CONTENT_TYPE:
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:
 		return dv_it_content_type;
+	case V4L2_CID_DV_RX_AUDIO_TYPE:
+		return dv_rx_audio_type;
 	case V4L2_CID_DETECT_MD_MODE:
 		return detect_md_mode;
 	case V4L2_CID_MPEG_VIDEO_HEVC_PROFILE:
@@ -1182,6 +1191,7 @@ const char *v4l2_ctrl_get_name(u32 id)
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:	return "Rx IT Content Type";
 	case V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE: return "Rx Audio Sampling Rate";
 	case V4L2_CID_DV_RX_AUDIO_PRESENT:	return "Rx Audio Present";
+	case V4L2_CID_DV_RX_AUDIO_TYPE:	return "Rx Audio Type";
 
 	case V4L2_CID_FM_RX_CLASS:		return "FM Radio Receiver Controls";
 	case V4L2_CID_TUNE_DEEMPHASIS:		return "De-Emphasis";
@@ -1407,6 +1417,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_DV_TX_IT_CONTENT_TYPE:
 	case V4L2_CID_DV_RX_RGB_RANGE:
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:
+	case V4L2_CID_DV_RX_AUDIO_TYPE:
 	case V4L2_CID_TEST_PATTERN:
 	case V4L2_CID_DEINTERLACING_MODE:
 	case V4L2_CID_TUNE_DEEMPHASIS:
@@ -1687,6 +1698,7 @@ void v4l2_ctrl_fill(u32 id, const char **name, enum v4l2_ctrl_type *type,
 	case V4L2_CID_DV_RX_IT_CONTENT_TYPE:
 	case V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE:
 	case V4L2_CID_DV_RX_AUDIO_PRESENT:
+	case V4L2_CID_DV_RX_AUDIO_TYPE:
 	case V4L2_CID_RDS_RX_PTY:
 	case V4L2_CID_RDS_RX_PS_NAME:
 	case V4L2_CID_RDS_RX_RADIO_TEXT:
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index 52124b7acdeab787978029aa49ea75d0ad4cc534..942a1df3057e3e49c9111f6a27ec1883d964bf64 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -1303,6 +1303,13 @@ enum v4l2_dv_it_content_type {
 #define V4L2_CID_DV_RX_IT_CONTENT_TYPE		(V4L2_CID_DV_CLASS_BASE + 102)
 #define V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE	(V4L2_CID_DV_CLASS_BASE + 103)
 #define V4L2_CID_DV_RX_AUDIO_PRESENT		(V4L2_CID_DV_CLASS_BASE + 104)
+#define V4L2_CID_DV_RX_AUDIO_TYPE		(V4L2_CID_DV_CLASS_BASE + 105)
+enum v4l2_dv_rx_audio_type {
+	V4L2_DV_RX_AUDIO_TYPE_LPCM	= 0,
+	V4L2_DV_RX_AUDIO_TYPE_IEC61937	= 1,
+	V4L2_DV_RX_AUDIO_TYPE_HBR	= 2,
+	V4L2_DV_RX_AUDIO_TYPE_ONE_BIT	= 3,
+};
 
 #define V4L2_CID_FM_RX_CLASS_BASE		(V4L2_CTRL_CLASS_FM_RX | 0x900)
 #define V4L2_CID_FM_RX_CLASS			(V4L2_CTRL_CLASS_FM_RX | 1)

-- 
2.34.1

