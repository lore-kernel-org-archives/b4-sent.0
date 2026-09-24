From: Shuming Fan <shumingf@realtek.com>
Subject: [PATCH v2 0/3] Add ASoC machine driver support for the RT766 and
 RT767 codecs.
Date: Thu, 24 Sep 2026 13:53:01 +0800
Message-Id: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL26tGoC/22Nyw7CIBBFf6VhLQamiOLK/zAuRjq1+GgNINE0/
 XehrjQuT3LPuSML5B0Ftq1G5im54IY+AywqZjvsT8Rdk5mBAC0MKO7jWmtOIGwtpMFGtCxv755
 a95w7+8OHw+N4JhuLXBadC3Hwr/koybL7bSbJBdeEqAgt1qR2nvAa6bK0w42VaoK/HmRPmlWjD
 Fiym/rbm6bpDe5blIXmAAAA
X-Change-ID: 20260924-rt766-e20c3019ad0f
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: Shuming Fan <shumingf@realtek.com>, derek.fang@realtek.com, 
 lars@metafoo.de, oder_chiou@realtek.com, linux-sound@vger.kernel.org, 
 flove@realtek.com, jack.yu@realtek.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229204; l=1472;
 i=shumingf@realtek.com; s=20260924; h=from:subject:message-id;
 bh=hzpGQhYnTyhqcrL9brsm+8ctP1I5x4qm4pICrcrYBpo=;
 b=qGtCHiqMzztIZwbgF1psKT5t9TwmuH2cRQQHnIqNLEQxiNHEFrCcTGlcRnGRjd5PJ0BIHq7bD
 00fDv7Dc83qC38ANfEfhMNmPsdJuTNkj7+LZ8zw0tulIKg37MvBAFG9
X-Developer-Key: i=shumingf@realtek.com; a=ed25519;
 pk=ZM8Pg7tEJ0SDXQeBw6SfvcYyqXU9nF88DuTyxzf9utE=
X-Endpoint-Received: by B4 Relay for shumingf@realtek.com/20260924 with auth_id=1053
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the required codec information and codec-specific DAPM routes,
enables wake capability on Intel platforms, and avoids re-initializing blind writes.

The series includes:

Add RT766 and RT767 to the SoundWire wake-capable codec list.
Add RT766 and RT767 codec information to sdw_utils.
Add support for codec versions 3 and 4.
Add the RT766 speaker and headset DAPM routes.
Avoid re-initializing blind writes.

With these changes, the generic SoundWire machine driver can recognize the RT766/RT767
codecs and set up the corresponding ASoC DAI links and codec routes.

Signed-off-by: Shuming Fan <shumingf@realtek.com>
---
Changes in v2:
- use b4 command to send this series and add a cover letter

---
Shuming Fan (3):
      soundwire: intel_auxdevice: add rt766/rt767 codec to wake_capable_list
      ASoC: sdw_utils: Add rt766/rt767 support
      ASoC: rt766: avoid re-initialize the blind write

 drivers/soundwire/intel_auxdevice.c               |   2 +
 sound/soc/codecs/rt766-sdca.c                     |   2 +-
 sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c          |   6 +
 sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c |   8 +
 sound/soc/sdw_utils/soc_sdw_utils.c               | 172 ++++++++++++++++++++++
 5 files changed, 189 insertions(+), 1 deletion(-)
---
base-commit: 782424a17d77ae6de07b490618b523066c528f59
change-id: 20260924-rt766-e20c3019ad0f

Best regards,
--  
Shuming Fan <shumingf@realtek.com>

