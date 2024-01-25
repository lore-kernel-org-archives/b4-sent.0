From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Thu, 25 Jan 2024 00:07:33 +0000
Subject: [PATCH BlueZ v3 8/8] android: export only (android) entrypoint
 from the modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240125-rm-ext-plugins-v3-8-d141f7870bb6@gmail.com>
References: <20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com>
In-Reply-To: <20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706141247; l=3016;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=A9wt+5pbCxd+p0NIbARFNH3H5ujiQXTs0z8giNMkb3Y=;
 b=/aEvjGs3MbYixjLOan9wWHGqwyPZWWCZK59mBHKklNkQ5PYGLAlkoCB4NKv7P+fayVcjuXLYp
 PAWOS9I/kbvBH54JomfS9UfDqU1y7LBVAgRtWiLL4eDfiWL/x3R/AXH
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

The android specific modules, have a designated HMI entrypoint. Hide
everything else with -fvisibility=hidden.
---
 android/Makefile.am     | 3 +++
 android/hal-audio.c     | 1 +
 android/hal-bluetooth.c | 1 +
 android/hal-sco.c       | 1 +
 4 files changed, 6 insertions(+)

diff --git a/android/Makefile.am b/android/Makefile.am
index 309910147..e3756e89c 100644
--- a/android/Makefile.am
+++ b/android/Makefile.am
@@ -96,6 +96,7 @@ android_bluetooth_default_la_SOURCES = android/hal.h android/hal-bluetooth.c \
 					android/hal-log.h \
 					android/hal-ipc.h android/hal-ipc.c \
 					android/hal-utils.h android/hal-utils.c
+android_bluetooth_default_la_CFLAGS = $(AM_CFLAGS) -fvisibility=hidden
 android_bluetooth_default_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/android
 android_bluetooth_default_la_LDFLAGS = $(AM_LDFLAGS) -module -avoid-version \
 					-no-undefined
@@ -195,6 +196,7 @@ android_audio_a2dp_default_la_SOURCES = android/audio-msg.h \
 					android/hardware/audio_effect.h \
 					android/hardware/hardware.h \
 					android/system/audio.h
+android_audio_a2dp_default_la_CFLAGS = $(AM_CFLAGS) -fvisibility=hidden
 android_audio_a2dp_default_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/android \
 					$(SBC_CFLAGS)
 android_audio_a2dp_default_la_LIBADD = $(SBC_LIBS) -lrt
@@ -212,6 +214,7 @@ android_audio_sco_default_la_SOURCES = android/hal-log.h \
 					android/audio_utils/resampler.c \
 					android/audio_utils/resampler.h \
 					android/system/audio.h
+android_audio_sco_default_la_CFLAGS = $(AM_CFLAGS) -fvisibility=hidden
 android_audio_sco_default_la_CPPFLAGS = $(AM_CPPFLAGS) -I$(srcdir)/android
 android_audio_sco_default_la_LIBADD = $(SPEEXDSP_LIBS) -lrt
 android_audio_sco_default_la_LDFLAGS = $(AM_LDFLAGS) -module -avoid-version \
diff --git a/android/hal-audio.c b/android/hal-audio.c
index d37d6098c..f3d9b40a6 100644
--- a/android/hal-audio.c
+++ b/android/hal-audio.c
@@ -1618,6 +1618,7 @@ static struct hw_module_methods_t hal_module_methods = {
 	.open = audio_open,
 };
 
+__attribute__ ((visibility("default")))
 struct audio_module HAL_MODULE_INFO_SYM = {
 	.common = {
 		.tag = HARDWARE_MODULE_TAG,
diff --git a/android/hal-bluetooth.c b/android/hal-bluetooth.c
index d4442e620..7d1e5ac63 100644
--- a/android/hal-bluetooth.c
+++ b/android/hal-bluetooth.c
@@ -1117,6 +1117,7 @@ static struct hw_module_methods_t bluetooth_module_methods = {
 	.open = open_bluetooth,
 };
 
+__attribute__ ((visibility("default")))
 struct hw_module_t HAL_MODULE_INFO_SYM = {
 	.tag = HARDWARE_MODULE_TAG,
 	.version_major = 1,
diff --git a/android/hal-sco.c b/android/hal-sco.c
index d7c08a68b..3d66ad357 100644
--- a/android/hal-sco.c
+++ b/android/hal-sco.c
@@ -1507,6 +1507,7 @@ static struct hw_module_methods_t hal_module_methods = {
 	.open = sco_open,
 };
 
+__attribute__ ((visibility("default")))
 struct audio_module HAL_MODULE_INFO_SYM = {
 	.common = {
 		.tag = HARDWARE_MODULE_TAG,

-- 
2.43.0

