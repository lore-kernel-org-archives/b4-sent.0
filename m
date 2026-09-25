From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/6] ASoC: codecs: aw88166: fixes and cleanup
Date: Fri, 25 Sep 2026 02:47:28 -0500
Message-Id: <20260925-aw88166-cleanup-v1-0-11f74cb5fe28@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyNT3cRyCwtDMzPd5JzUxLzSAt0U00RDE8OkVDNTw0QloK6CotS0zAq
 widGxtbUAALq53GEAAAA=
X-Change-ID: 20260925-aw88166-cleanup-d5a141be651a
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Weidong Wang <wangweidong.a@awinic.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790322449; l=1072;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=0RxTci400abtv1CmfPdCaZw84TP5Ofx2vovmIeotYPM=;
 b=QVqL9uBRySW7DG2p7F1ZQuAaIqSz46jW3yk6SYfLw4PR2akQAJUMyybk4PfkVBjMAPqXkKdfy
 xc4E0NO5BciCUwOa7lFaUmycDNGv8sJ66KwyXULzv23BGPbIKonSn90
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver was merged in a very downstream-centric manner. This series
copies the changes from Val Packetts series [0] cleaning up the aw88261
driver. This makes the driver notably more usable on the AYN and Retroid
Pocket QCS8550 devices, as well as the AYN Odin 3.

[0] https://lore.kernel.org/linux-sound/20260529200550.529719-1-val@packett.cool/

---
Aaron Kling (6):
      ASoC: codecs: aw88166: support changing sample rate and bit width
      ASoC: codecs: aw88166: add TDM support
      ASoC: codecs: aw88166: reduce log spam
      ASoC: codecs: aw88166: remove fade in/out on start/stop
      ASoC: codecs: aw88166: remove async start
      ASoC: codecs: aw88166: make volume control usable

 sound/soc/codecs/aw88166.c | 590 +++++++++++++++++++++++++--------------------
 sound/soc/codecs/aw88166.h | 180 +++++++++++++-
 2 files changed, 501 insertions(+), 269 deletions(-)
---
base-commit: 4c253ac4b29b8c6cc6fdef8f92d4facde62e63b9
change-id: 20260925-aw88166-cleanup-d5a141be651a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

