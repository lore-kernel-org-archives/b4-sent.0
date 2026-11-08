From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] ccsify imx355 and imx258
Date: Sun, 08 Nov 2026 12:17:23 +0000
Message-Id: <20261108-imx355-ccsify-v3-0-366ce7ae1bef@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBQFf4V0bU0flhZX/odxAddWrolgWmxAw
 r/b4kJj4nKSM3NmEqxHG8i+mIm3EQP2XQK5KQi0dXexFM+JiWCiZIZXFG+jVIoCBHQTNaoEo5j
 SynGSnLu3Dse1dzy9OTyaq4UhR/KixTD0floPI8+7f+3IKaesKcE6ra3csQOOOGzhSXI5ii9X6
 F9XJFfWlW5AMyO5+rjLsrwABfzFDfYAAAA=
X-Change-ID: 20260819-imx355-ccsify-856c850575f1
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Jai Luthra <jai.luthra@ideasonboard.com>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=929; i=david@ixit.cz;
 h=from:subject:message-id; bh=3EIQBo5WgMeq0yNIV477sq8iF/Ojcq5glNWFNlrvfBc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GhXQO/ENKAmC7Mj6xu2FtnT/QvxKcTMCO95y
 nISJhq3ZhiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBoVwAKCRBgAj/E00kg
 cq/RD/49h7eaqSt6NRvq+NBoOHKq1M5PSMm9TyMi71VS1WgMyouBJxPuYJANVjqKBoK8spfQyh9
 qayGQ84Tn0fQJqxqaQWZF2cYaFCo/ReF+BQ1D8EI8ZzZr/NSpU/YoWoXGQFOoVwsaJpcDBDkSKk
 fhp04t+iAAkwfkm8UbVIZGEfhH4p1Hzo3t6Hn/jmm2yQZHGQsw+VlAWBDRqQFqcgbHLq5w/4a+J
 hFPA6NVeIWWU92J2DV0p1N24Y1SC8U3MHUJ68eMAdr6BPG8yEEmMy4X83SF5UG8L2a2pQPf8Cqa
 xNxJvD8Ru4U7WyLBu2GbG9r1khF3dPUFtyTmr94cdQsS920hFbK7qVlj8GHZard+Q4LIUxBlqIW
 GTbDiFhzxqUP8pADXrdMQ4w6Y1gCMi3Wpk1LdeQ9RTQymNUfFvIUds1LpAPwz+GRNMWMkuBVNW6
 lMEFT2GarpbSfEFh4m4KDnhKce052JGxE9tYV3LKKfX0C2qHYq+lXltyZGFhNacY4ulTiglY0oH
 bPm7oPej0lyIhdBy3/NdkIv1lVuT/gV5kuis66iwNU8SCvlgfloEIds15A/Q2RluzpTnf0dvGO2
 tEIOFQLd6SATFPgYHpVjjZaXIwWkv9szw7Xpj+RxlHi902ID6BsqnW+lUHVQVgV2R0RmLzNSXuw
 Uvgsglq9J4g1TEQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Makes grepping easy. Makes stuff more unified and deduplicated.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Use the ccs regs on imx258 too.
- Rebase on top of next-20261105.
- Link to v2: https://patch.msgid.link/20260827-imx355-ccsify-v2-1-3a97bc708315@ixit.cz

Changes in v2:
- Replaced all occurences with CCS ones.
- Link to v1: https://patch.msgid.link/20260819-imx355-ccsify-v1-1-0b6cef77e340@ixit.cz

---
David Heidelberg (2):
      media: imx355: Reuse existing CCS defines
      media: imx258: Reuse existing CCS defines

 drivers/media/i2c/imx258.c | 218 +++++++++++++++++++--------------------------
 drivers/media/i2c/imx355.c |  84 ++++++-----------
 2 files changed, 115 insertions(+), 187 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20260819-imx355-ccsify-856c850575f1

Best regards,
--  
David Heidelberg <david@ixit.cz>

