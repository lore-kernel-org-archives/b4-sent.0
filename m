From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] pmdomain: rockchip: probe error clean-ups
Date: Thu, 26 Nov 2026 10:01:23 +0000
Message-Id: <20261126-pmdomain-rockchip-cleanup-v1-0-a19f5ea7d555@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6DIBBA0auYWXcSYEGDV2m6wHGsUysQUGNiv
 Lu0Xb7F/wcUzsIF2uaAzJsUiaFC3xqg0YcXo/TVYJSxWhuLae7j7CVgjjTRKAnpwz6sCVnZu7f
 OKdcR1D5lHmT/vR/Pv8vavZmW7xDO8wLinfGxfQAAAA==
X-Change-ID: 20261126-pmdomain-rockchip-cleanup-e067a69909bc
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687283; l=1267;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4CReN9sh8A+J7ZqUTq61tIENXfUM+WOrErsgMQCjVk4=;
 b=VuNfgoS6KjJFhSWsGzmWc+jYE1UsOlganyOXj2Zvyj5macFjgOjT1NhI1nYAB35dU+F8HMd7e
 a1oONNyARcTAr9nP0wPNip9X+RImBxt9B0SRVSXtsMKTNjv/dRyn44Q
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keep the error code of a pm_qos syscon lookup, use dev_err_probe() in
the probe path, and report each domain error once.

Build-tested only.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Split out of v3 of "pmdomain: rockchip: fix the probe error and
deferral paths" [1]; its fix goes separately to the fixes branch.

[1] https://lore.kernel.org/r/20261113-pmdomain-rockchip-v3-0-b7039ca30b87@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes since [1]:
- 1/3: the pm_qos part of v3 2/3, without Fixes tags
- 2/3: v3 3/3, also converting rockchip_pm_domain_probe()
- 3/3: the rest of v3 2/3, on top of Yao Zi's patch in next

---
Arun Iyengar (3):
      pmdomain: rockchip: keep the pm_qos regmap error code
      pmdomain: rockchip: use dev_err_probe() in the probe path
      pmdomain: rockchip: report domain errors where they happen

 drivers/pmdomain/rockchip/pm-domains.c | 122 ++++++++++++++-------------------
 1 file changed, 50 insertions(+), 72 deletions(-)
---
base-commit: e9a9fed57b72b811fbaf62673cf56727a3358899
change-id: 20261126-pmdomain-rockchip-cleanup-e067a69909bc

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

