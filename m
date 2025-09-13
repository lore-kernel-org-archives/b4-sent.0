From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/3] Add driver for Novatek NT35596S panel
Date: Sat, 13 Sep 2025 21:19:46 +0200
Message-Id: <20250913-nt35596s-v6-0-b5deb05e04af@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANLDxWgC/zXMQQrCMBBA0auUrE2YpE1jXHkPcTFNpzbQJjKpI
 pTe3SC4fPD5uyjEkYq4NLtgescSc6roT40IM6YHyThWCwPGgoezTFtrre+L1KaDYELoaAii5k+
 mKX5+q9u9euK8ym1mwv+gBae9tgbAKe2d0yC1RE74GtVEzMixXENeFhwyowp5FcfxBeW5UK+iA
 AAA
X-Change-ID: 20250908-nt35596s-1240c2cc4ebc
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Molly Sophia <mollysophia379@gmail.com>, 
 Arnaud Ferraris <arnaud.ferraris@collabora.com>, 
 David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1524; i=david@ixit.cz;
 h=from:subject:message-id; bh=M7v6OeJEljlT0UA3gOL67Bm7olaXUkgjIMpsWGYViy4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoxcPVzPqYJE2zvubwyWrWbxGFWkJJJnw9pEBh6
 zUmq7391TaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaMXD1QAKCRBgAj/E00kg
 cq+uEACO/XDIWx71H/vjlgkY2mtJsvok9sR7Ryj2TdWcz5BqDG9wp5KGMbTPsCpTA6PjzfEGFb5
 vWS3xogs28si0vz4UokymdiPTSAYZEeah4VQpS8aAW3PcNrk7uziPjjefftgJy3QFf8NKQNS8va
 V4FxdMiGrP0a4akrAWTztqjoMHYg8Lwvj4u6AcZXvo8fvbHp6JITendF0J1ZKKMlaMC5JIwIfm7
 G4leI1a90rNE6L/9+c65ozNZTpwX0pFGlrv+nQdZzYmY957BR9u8+/7OhdpFNZqpcXO8Ow+2+Km
 xs1mB+LZ/Id8JxI1ORSPqbfzPuw/wwKtizWXam81Td6YsssJqBPn6InFATHywOYla1kbRn0lZ5A
 2S2FWtqIjp7KomPG+zlYC/Q6fSjDPFwWsB+XX81LfUSFtvXdS1Qe0UgNiVz3Xa/jDhMfEbK/QTq
 t/tQrcjym9B7z4Ohu/bOvjzZMdvc3EXg1aH9BULnEu5EWzg6vFXUuDBh5ecnCuDM+mk+49O7++f
 8j4i12EbbRJuFlyKbMgIVY45UDP3Bp2EoxtcJxB5SW8h77mm0Zn19F+gcmTayN3VdmpJcei0bIv
 ua2gylOpFNtypSyskCqTFcbgH7C7+lO52XR961QU8x3sl0ek5SvlHIL4qV1juekEJAGGgswqOc3
 QX0KckcPmfUgrCw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches add support for Novatek NT35596S based JDI FHD panels.
This panel is already used by mainlined Xiaomi Mi Mix 2S mobile phone.

Notes:
- I'm taking over this series as the original submitter is no longer
  able to work on/test those patches.

Changes in v5:
- Split changes affecting original paths to the separate patch
  "drm: panel: nt36672a: Make some command sequences optional"
  for easier review.
- Small wording corrections.

Changes in v5:
- Move changelogs out of commit messages.
- Wrap comment/text lines around 80 chars.

Changes in v4:
- Correct numeric order of the items in binding.

Changes in v3:
- Embed the support into existing driver (panel-novatek-nt36672a), as
  these two IC are similar with different initialization commands.

Changes in v2:
- Correct items order in Makefile and improve failure handling.

---
Molly Sophia (3):
      drm: panel: nt36672a: Make some command sequences optional
      drm: panel: nt36672a: Add support for novatek nt35596s panel
      dt-bindings: display: panel: Add Novatek NT35596S panel bindings

 .../bindings/display/panel/novatek,nt36672a.yaml   |  21 +-
 drivers/gpu/drm/panel/Kconfig                      |   7 +-
 drivers/gpu/drm/panel/panel-novatek-nt36672a.c     | 252 +++++++++++++++++++--
 3 files changed, 251 insertions(+), 29 deletions(-)
---
base-commit: 590b221ed4256fd6c34d3dea77aa5bd6e741bbc1
change-id: 20250908-nt35596s-1240c2cc4ebc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

