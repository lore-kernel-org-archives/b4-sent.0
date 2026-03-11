From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] ASoC: codecs: aw88166: Support device specific
 firmware
Date: Tue, 10 Mar 2026 23:43:03 -0500
Message-Id: <20260310-aw88166-fw-v1-0-2777563bb673@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0MD3cRyCwtDMzPdtHJdSwPjpDQz81QDMyNDJaCGgqLUtMwKsGHRsbW
 1AO0TzHxcAAAA
X-Change-ID: 20260310-aw88166-fw-903bf67e0621
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773204187; l=960;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=66W1pmkks2I4ITe9DRIevRnJ2zaQ2m9va/55lmzkK3A=;
 b=Q3RAq01dTOkd5P5WbTiga073JhNgG8Jv/3E4ceB/FwiBZKCMwFDA/qdVqU6+plRirM8MzidU7
 v+p71E+Ajz/AhcJzlHZYMLwyLBRXSayT5JZRhoS8s1ECglFvgIrb2EL
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently loads a hardcoded firmware path. This adds support
for reading a device specific path from the kernel device tree.

Patch 2 was originally part of a larger change [0] by Teguh Sobirin and
was cut down to only the device specific firmware part.

[0] https://github.com/AYNTechnologies/linux/commit/9dbdd074423d970a9dec9a60f8bb99f8cfafd6a1

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (1):
      ASoC: dt-bindings: Document firmware-name for awinic,aw88166

Teguh Sobirin (1):
      ASoC: codecs: aw88166: Support device specific firmware

 .../devicetree/bindings/sound/awinic,aw88395.yaml     |  3 +++
 sound/soc/codecs/aw88166.c                            | 19 +++++++++++++++----
 2 files changed, 18 insertions(+), 4 deletions(-)
---
base-commit: fe9e3edb6a215515d1148d32a5c445c5bdd7916f
change-id: 20260310-aw88166-fw-903bf67e0621

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

