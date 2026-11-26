MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-yoc1s-ffmpeg-v1-4-f01fec79468b@certik.com>
References: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
In-Reply-To: <20261127-yoc1s-ffmpeg-v1-0-f01fec79468b@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 23:02:05 +0000
Subject: [scarthgap][PATCH 4/7] ffmpeg: fix CVE-2026-135725
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769565; l=2686;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=HWcqlx1vXCOUWCWD91ivCLqslU3Hsq846IOO0wpUCrQ=;
 b=p9N6cfuwBdtPbkcGn1wOmEyHBxJZDQtjNC+urkPaqzrXOYaKUfMzGX15+wa59sDg81QrLEya+
 rO7mtg8dIXQCUSAcCxO/dOjxrFQftLk8gVnNchFhChBdbhxOWe1DjxW
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTMP packet header buffer was too small for the generated header,
allowing a stack out-of-bounds write. Backport the upstream fix.

https://github.com/FFmpeg/FFmpeg/commit/041098a1a3be

AI-Generated: OpenAI Codex, gpt-6.2-sol
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../ffmpeg/ffmpeg/CVE-2026-135725.patch       | 34 +++++++++++++++++++
 .../recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb |  1 +
 2 files changed, 35 insertions(+)
 create mode 100644 meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135725.patch

diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135725.patch b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135725.patch
new file mode 100644
index 00000000..9f481c75
--- /dev/null
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg/CVE-2026-135725.patch
@@ -0,0 +1,34 @@
+From 041098a1a3bee481a1c8e905257ba04dad0c60a1 Mon Sep 17 00:00:00 2001
+From: Michael Niedermayer <michael@niedermayer.cc>
+Date: Tue, 6 Oct 2026 06:53:14 +0200
+Subject: [PATCH] avformat/rtmppkt: Make the packet header buffer large enough
+
+The fix is the one recommended in the report.
+
+Fixes: out of array write
+Fixes: BvkwW4Yd19HN
+Fixes: AISLE-2026-0111-00462
+Stack out of array write Replicated through UnModified FFmpeg with ASAN
+Found-by: Joshua Rogers <joshua.rogers@aisle.com>
+
+CVE: CVE-2026-135725
+Upstream-Status: Backport [https://github.com/FFmpeg/FFmpeg/commit/041098a1a3bee481a1c8e905257ba04dad0c60a1]
+
+Signed-off-by: Dickson Wu <dickson.wu@certik.com>
+---
+ libavformat/rtmppkt.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/libavformat/rtmppkt.c b/libavformat/rtmppkt.c
+index e52307c5d63c5..ee687d4791568 100644
+--- a/libavformat/rtmppkt.c
++++ b/libavformat/rtmppkt.c
+@@ -314,7 +314,7 @@ int ff_rtmp_packet_write(URLContext *h, RTMPPacket *pkt,
+                          int chunk_size, RTMPPacket **prev_pkt_ptr,
+                          int *nb_prev_pkt)
+ {
+-    uint8_t pkt_hdr[16], *p = pkt_hdr;
++    uint8_t pkt_hdr[18], *p = pkt_hdr;
+     int mode = RTMP_PS_TWELVEBYTES;
+     int off = 0;
+     int written = 0;
diff --git a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
index a9b42303..789beed0 100644
--- a/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
+++ b/meta/recipes-multimedia/ffmpeg/ffmpeg_6.1.4.bb
@@ -35,6 +35,7 @@ SRC_URI = " \
     file://CVE-2026-135736.patch \
     file://CVE-2026-135743.patch \
     file://CVE-2026-135722.patch \
+    file://CVE-2026-135725.patch \
 "
 
 SRC_URI[sha256sum] = "a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18"
-- 
2.43.0

