From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 23 Sep 2026 10:23:36 +0300
Subject: [PATCH 3/3] cpufreq: dt-platdev: block the driver from probing on
 MediaTek mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-6572-cpufreq-v1-3-41f7af6d6d1a@protonmail.com>
References: <20260923-6572-cpufreq-v1-0-41f7af6d6d1a@protonmail.com>
In-Reply-To: <20260923-6572-cpufreq-v1-0-41f7af6d6d1a@protonmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790148240; l=803;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=pvNavw1TwxmxmNAxfAHmYvDXdUUIz8P51+5XyRZ6nPo=;
 b=YsrJCy5QZyZQ0x8+C3yQqVv16vsP+AsTxbfCOEpZ0WJhlCdxzGXzd1uQ5BVb3/jeTge8q1/k2
 laGs8FQ7FQ8Byo/4hbiF1LPi5WxV62mitZXUae3HxZn9/6QXtWgWCY6
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MediaTek SoCs use mediatek-cpufreq driver instead of generic one. Add
mt6572 to the blocklist.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/cpufreq/cpufreq-dt-platdev.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/cpufreq/cpufreq-dt-platdev.c b/drivers/cpufreq/cpufreq-dt-platdev.c
index ff1204c666b1..ff7fb61eda74 100644
--- a/drivers/cpufreq/cpufreq-dt-platdev.c
+++ b/drivers/cpufreq/cpufreq-dt-platdev.c
@@ -132,6 +132,7 @@ static const struct of_device_id blocklist[] __initconst = {
 
 	{ .compatible = "mediatek,mt2701", },
 	{ .compatible = "mediatek,mt2712", },
+	{ .compatible = "mediatek,mt6572", },
 	{ .compatible = "mediatek,mt7622", },
 	{ .compatible = "mediatek,mt7623", },
 	{ .compatible = "mediatek,mt8167", },

-- 
2.55.0

