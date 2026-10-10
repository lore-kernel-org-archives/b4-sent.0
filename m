From: benthecarman <benthecarman1@gmail.com>
Subject: [PATCH 0/2] wifi: iwlwifi: fix legacy-rate injection outside 2.4
 GHz
Date: Fri, 09 Oct 2026 21:42:21 -0500
Message-Id: <20261009-next-v1-0-b370f5302d27@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwNL3bzUihLdlEQLCxMDE4tUMzNzJaDSgqLUtMwKsDHRsbW1ABJ2MpB
 WAAAA
X-Change-ID: 20261009-next-da884048e667
To: Miri Korenblit <miriam.rachel.korenblit@intel.com>
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 benthecarman <benthecarman@live.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791600143; l=1858;
 i=benthecarman1@gmail.com; s=20261009; h=from:subject:message-id;
 bh=S57sgVcE/7Jei4pRIK3BUSdo5UYSccERXm9nve4j2CM=;
 b=ZmdkOA3SQ9vUOhlhIRrMIcoHuMpaIiWEpQGlAg0RzOVPuAb6Z1mmBQDSttQxOt890+47RbEYD
 At09DbQ9hVKBXj9B1MBRpWDhyRarTOKX2dOFnDuTtLsywC/E2f5y2J6
X-Developer-Key: i=benthecarman1@gmail.com; a=ed25519;
 pk=8RDA9X90+5wKUu3kkgPYpamlxYvX93l7iXqMWrkhvOY=
X-Endpoint-Received: by B4 Relay for benthecarman1@gmail.com/20261009 with auth_id=1149
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both op modes pass mac80211's legacy rate index for an injected frame
to the driver's rate conversion unchanged. Outside 2.4 GHz that index
points into a bitrate table starting at 6 Mbps, so every injected
legacy rate is shifted down by the four CCK rates: 12 Mbps on 5 GHz
goes out as 5.5 Mbps CCK, which nothing on that band can receive.

I found this bringing up userspace AWDL (OWL) on an AX211: the peer
heard none of our data frames until the rate was remapped. Patch 1
(mvm) was tested on that hardware; patch 2 (mld) is the same fix and
build-tested only, as I have no iwlmld device.

Testing: patch 1 was tested on an Intel AX211 (iwlmvm, firmware
89.123cf747.0) with the same change applied to Ubuntu's 7.0.0-38
kernel, injecting AWDL frames at a radiotap rate of 12 Mbps on channel
44 (5220 MHz). Before, the TX response showed status 0x83 (long retry
limit) and rate_n_flags 0x8002; after, status 0x1, no retries,
rate_n_flags 0x8102, and the peer ACKed every frame. Against
iwlwifi-next both mvm/tx.c and mld/tx.c build without warnings at W=1,
but I could not boot an iwlwifi-next kernel, and patch 2 is untested
at runtime.

The bug was found, and the patches written, with help from an AI
assistant (Claude) during that debugging session; I reviewed and
tested them as described above.

Signed-off-by: benthecarman <benthecarman@live.com>
---
benthecarman (2):
      wifi: iwlwifi: mvm: Fix injected 5 GHz legacy rate
      wifi: iwlwifi: mld: Fix injected 5 GHz legacy rate

 drivers/net/wireless/intel/iwlwifi/mld/tx.c | 11 ++++++++++-
 drivers/net/wireless/intel/iwlwifi/mvm/tx.c |  8 ++++++++
 2 files changed, 18 insertions(+), 1 deletion(-)
---
base-commit: 5d017b30f502e20bfb96ba534b1c36f060a06e98
change-id: 20261009-next-da884048e667

Best regards,
-- 
benthecarman <benthecarman1@gmail.com>

