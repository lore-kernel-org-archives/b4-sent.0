From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/2] net: dwmac_meson8b: Fix incorrect ETH0 register
 assignment
Date: Tue, 13 Jan 2026 23:16:14 +0800
Message-Id: <20260113-aml_eth-v1-0-3dd74db37c4f@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL5hZmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQ0Nj3cTcnPjUkgzdNAPT1DTz5DRzAwMzJaDqgqLUtMwKsEnRSkFuzkq
 xtbUAeZIjgF4AAAA=
To: u-boot-amlogic@groups.io, u-boot@lists.denx.de
Cc: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Jerome Forissier <jerome@forissier.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768317381; l=720;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rY4/JV3DaI9fBaAujMH30v69WA47tqdcDAHu7tVKel8=;
 b=ElkdPBF9JYECe41/gCUZ8cqRaN2eiEfTr+wH2wZXkhsZhsmUcaVXh6Lz5PUb1yLAuU9hczS3V
 gnlw3/81b3VC5ncOJ+MPIOXTRLF5Wo1XGXUfTlgVP0l8almpfh+DAr7
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The currnet logic for setting ETH0 reg seems broken. It does not conform
to the datasheet and the Linux driver code.

Fix two bugs here:
1. replace setbits() with clrsetbits()
2. set tx radio to 2 rather than 4.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      net: dwmac_meson8b: replace setbits() with clrsetbits()
      net: dwmac_meson8b: Fix incorrect clock divider setting

 drivers/net/dwmac_meson8b.c | 48 ++++++++++++++++++++++++++++-----------------
 1 file changed, 30 insertions(+), 18 deletions(-)
---
base-commit: 711150fc6fe7a125cc1133841acc802570478007
change-id: 20260113-aml_eth-f05ef7cf7006

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

