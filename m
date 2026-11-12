From: Yusuke Hayashi <yusuke8h@gmail.com>
Date: Thu, 12 Nov 2026 04:29:55 +0000
Subject: [PATCH] staging: bcm2835-audio: remove unused
 bcm2835_audio_retrieve_buffers() declaration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-bcm2835-audio-unused-decl-v1-1-3b63a24b033b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMJA9WoC/x2MQQqAIBAAvxJ7biHXiugr0cF0q4WyUIwg+nvSc
 WBmHogchCP0xQOBL4ly+AyqLMCuxi+M4jIDVdQqpQgnu1OnGzTJyYHJp8gOHdsNa2pNNvSkuYP
 cn4Fnuf/3ML7vB0o0Dc1rAAAA
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Ray Jui <rjui@broadcom.com>, Scott Branden <sbranden@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: linux-staging@lists.linux.dev, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yusuke Hayashi <yusuke8h@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794457795; l=1434;
 i=yusuke8h@gmail.com; s=20261112; h=from:subject:message-id;
 bh=a+TgyUI6wkUkFO2I4cpqAGWsRWGHAWy+RkqW/CQr8tE=;
 b=bFuG0CHsUqIN8TsqRDo45PNlrMwwZoe6/DklH1Tqgyl9UR6UthH5+qMZ4VkD64Y1ybu8lGEc6
 BozwNImwss8CQG4yK414WsNFnI5f7Fz6qGtJvrZ1v3leU9tHGXi/E20
X-Developer-Key: i=yusuke8h@gmail.com; a=ed25519;
 pk=7SzYbbTWl4u1a0gmKeMxAqo7g7F1K7tnWWGWQ+LnNNs=
X-Endpoint-Received: by B4 Relay for yusuke8h@gmail.com/20261112 with auth_id=1495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bcm2835_audio_retrieve_buffers() is declared in bcm2835.h, but its
definition and sole caller were removed in commit d7ca3a71545b
("staging: bcm2835-audio: Operate non-atomic PCM ops").

Remove the orphaned function declaration.

Signed-off-by: Yusuke Hayashi <yusuke8h@gmail.com>
---
Found while scanning staging headers for declarations without definitions
with an AI coding assistant, verified against commit d7ca3a71545b, and
compile-tested with Clang 18 (LLVM=1 W=1 C=2) and GCC 13 (W=1 C=2) with
CONFIG_SND_BCM2835=m.
---
 drivers/staging/vc04_services/bcm2835-audio/bcm2835.h | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/staging/vc04_services/bcm2835-audio/bcm2835.h b/drivers/staging/vc04_services/bcm2835-audio/bcm2835.h
index 5a1348747ff4..54ad749129fc 100644
--- a/drivers/staging/vc04_services/bcm2835-audio/bcm2835.h
+++ b/drivers/staging/vc04_services/bcm2835-audio/bcm2835.h
@@ -107,6 +107,5 @@ int bcm2835_audio_write(struct bcm2835_alsa_stream *alsa_stream,
 			void *src);
 void bcm2835_playback_fifo(struct bcm2835_alsa_stream *alsa_stream,
 			   unsigned int size);
-unsigned int bcm2835_audio_retrieve_buffers(struct bcm2835_alsa_stream *alsa_stream);
 
 #endif /* __SOUND_ARM_BCM2835_H */

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-bcm2835-audio-unused-decl-426a1123b3e8

Best regards,
-- 
Yusuke Hayashi <yusuke8h@gmail.com>

