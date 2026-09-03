From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] wcd934x fixes
Date: Thu, 03 Sep 2026 17:21:41 +0200
Message-Id: <20260903-wcd-dma-v3-0-d3920c6563c4@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNyw6CMBQFf4V0bU0fgK0r/8O4gPZWroliWqwo4
 d9tcYGJy0nOzJlIAI8QyL6YiIeIAftbArkpiOma2xko2sREMFEzJSR9GkvttaGtrQUHkFqpHUn
 ruweH41I6nr4cHu0FzJD1vOgwDL1/LVeR591/NXLKqa6gLBvJK2PcAUcctuZNcjOK1dLsxxLJ4
 kob56qaNUKt1jzPH8as9wLkAAAA
X-Change-ID: 20260823-wcd-dma-bd621ee39887
To: Lee Jones <lee@kernel.org>, Thomas Tai <thomas.tai@oracle.com>, 
 Konrad Rzeszutek Wilk <konrad.wilk@oracle.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=840; i=david@ixit.cz;
 h=from:subject:message-id; bh=nRTYXO+CiccuUTUk2c7qbiCnWkPrZRtzyZnhjjtQ0lQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmZCG3KXrAunwVO0uDPNrVIgmhb6EIr46J/1lS
 hhjh/PS4C6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapmQhgAKCRBgAj/E00kg
 cq25EADD6cqCfFx+SY9+V8JFxnvfgpMuKQcpqH0ptsE2wSEqx10jK6ZaFLrJ9JhV0dUG+A5b0lK
 BDKomYmY1qf7TC40wL4Oj0kbPbuRdXuxW+/Ddk+0HEU9e/GTrwxMbk6rk7ji42ZnF7rZoJWhOQH
 QM/tOa1GI75lYWV5Oi60EuGOhztTTtX0AO4FGftwAfAd6kTgUk3mA4gQv/aQdc3GC8y7TiZhfYU
 7cbFOkUD8gBNJeQl8ehg2ycxhvNo7pzLmxfYuSvLcq7Jk71b9qUPJh3RtfoAHpSvjgpSzJH5pA1
 U2R3fd4Hr1Sv06xSZbucCwLMnjuTEIlzB63hlnrE1bl2vfdGY7Q1ImUemXLieygIkiRdsLrCN2r
 oTw8+4pA8mgVdQe7w2bjIb7zA6aE8k9BuNQCLYDUlAnevg79K0AoEE1aUzxPCSSUUhpZG/XFpAd
 0FEMwwUlFnQ9I+r0qethICNWmB9+HGsTzPTmiYpYG7TpQ+rWZtwRIoOxOONcdG6IhVzKhnx4foK
 WLe3GQt6VjBIypOFZZtQog27mhl1VVKKiTg6lP8GpVXsXSCv1SL4kipy3i4AjKqOj8kgFqm03Le
 WgbEXhCJcbeILhgSceELzSM1KilyVPdKRoI+jKhdiw8ZkFSLuIOcVjFYVgzrHqd9wU9hylxF4UC
 e9pgA+WqtUhfMTQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

$subj

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Capitalize commit names. (Sashiko)
- Add commit addressing the NULL deref when of_irq_get fails. (Sashiko)
- Link to v2: https://patch.msgid.link/20260903-wcd-dma-v2-1-189cff560a28@ixit.cz

Changes in v2:
- Use dma_coerce_mask_and_coherent. (Lee)
- Link to v1: https://patch.msgid.link/20260823-wcd-dma-v1-1-95e44a315ccf@ixit.cz

---
David Heidelberg (2):
      mfd: wcd934x: Fix NULL pointer dereference on IRQ probe deferral
      mfd: wcd934x: Set DMA mask on parent to silence "DMA mask not set"

 drivers/mfd/wcd934x.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260823-wcd-dma-bd621ee39887

Best regards,
--  
David Heidelberg <david@ixit.cz>

