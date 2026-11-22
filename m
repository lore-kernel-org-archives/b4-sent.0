From: EMCP333 <emcp@enser.io>
Subject: [PATCH 0/2] media: venus: Fix end-of-stream and seeks on SDM845
Date: Sun, 22 Nov 2026 05:13:15 +0000
Message-Id: <20261122-b4-venus-eos-seek-v1-0-2e38912c7cf9@enser.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOt5AmsC/yXMzQrCMBAE4Fcpe3bVhKqtryIe8jO1UUhL1gah9
 N1N9PgNM7OSIAUIXZuVEnKQMMUCtWvIjSY+wMEXkz7qs1Jas205Iy7CmIQFeLHHoHvVo+v8icp
 uThjC5/d5u/8ti33CvetRbVgjYJtMdGONKg/5sm85OU3b9gXw/SnqlQAAAA==
X-Change-ID: 20261122-b4-venus-eos-seek-def2919e88d5
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Dikshita Agarwal <dikshita.agarwal@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bod@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Stanimir Varbanov <stanimir.varbanov@linaro.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324396; l=1979;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=iP7FYS+EUWbdvN2tGSghCLya/Epnwo8AlsueNNlxKd8=;
 b=3SJ4nGg5MO7AHbPM4HnJT6atKVij5aE02Xdb7Kp/IFJ/qkQAXViTsx23qxP2PSXXLHUolhcAl
 AUeItdKTwrcAp2HQV90Me3jveKK77HQ/9l00Y2+DYUs+G+hiUZklaH7
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for the Venus decoder and encoder, found on a OnePlus 6T
(SDM845, firmware VIDEO.VE.5.2-00050-PROD-1) while using it from
GStreamer, ffmpeg and mpv.

Patch 1 gives the end-of-stream buffer that the STOP commands queue a
real, mapped address instead of the made-up 0xdeadb000. This firmware
rejects the made-up address, which leaves the encoder unusable until
reboot and decoder clients draining forever.

Patch 2 makes a CAPTURE STREAMON issued while OUTPUT is stopped for a
seek take effect when OUTPUT restarts. That is the order GStreamer uses
for every flushing seek, and without it the seek never completes.

Both were tested on the phone with the postmarketOS sdm845 kernel
(6.18). On v7.4-rc2 the driver builds with W=1 and no warnings.

Both also ran on v7.4-rc3: three encodes drained by V4L2_ENC_CMD_STOP
and decoded back (90 of 90 frames), and three flushing seeks through
GStreamer completed in 0.02 s each, with no venus errors.

One related problem is not addressed here: from 1280x720 up, the encoder
bitstream buffer is an eighth of the size used just below 720p, and
this firmware produces nothing with it. Fixing that properly needs the
firmware's own buffer requirement rather than a bigger guess, so it is
left for a separate change.

---
EMCP333 (2):
      media: venus: Signal end-of-stream with a mapped buffer
      media: venus: vdec: Resume CAPTURE restarted during a seek

 drivers/media/platform/qcom/venus/core.h    |  7 +++++
 drivers/media/platform/qcom/venus/helpers.c | 40 +++++++++++++++++++++++++++++
 drivers/media/platform/qcom/venus/helpers.h |  3 +++
 drivers/media/platform/qcom/venus/vdec.c    | 33 +++++++++++++++++++++---
 drivers/media/platform/qcom/venus/venc.c    |  7 ++++-
 5 files changed, 85 insertions(+), 5 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-venus-eos-seek-def2919e88d5

Best regards,
--  
EMCP333 <emcp@enser.io>

