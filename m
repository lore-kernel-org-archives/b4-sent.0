From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:25:01 +0300
Subject: [PATCH 09/13] mfd: mt6397-core: add support for mt6323 thermal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-9-799b58b355ff@protonmail.com>
References: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
In-Reply-To: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=903;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=1GBl1TpFBcVXYGizGdKi1F7hlRKLPxUy3Qzy4DpQjMM=;
 b=8nyO1z82QxMlj6H0WEVe86aCBbZcH4auRH3dTb7ryxt+R5BbJ1NJpZ0rlhv416KiWWfCYbyhM
 VaAhTEw+tP3ChoTAZAIFSwzFtWpJxazwDOCBgmDQ680MNhJw61JUEO0
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mt6323 PMIC temperature can be measured using AUXADC channel.
Register the thermal in the mt6323 devices array to allow the
corresponding driver to probe using compatible string.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/mfd/mt6397-core.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/mfd/mt6397-core.c b/drivers/mfd/mt6397-core.c
index 2d9419b80a5c..061ac242f1f8 100644
--- a/drivers/mfd/mt6397-core.c
+++ b/drivers/mfd/mt6397-core.c
@@ -151,6 +151,9 @@ static const struct mfd_cell mt6323_devs[] = {
 		.num_resources = ARRAY_SIZE(mt6323_pwrc_resources),
 		.resources = mt6323_pwrc_resources,
 		.of_compatible = "mediatek,mt6323-pwrc"
+	}, {
+		.name = "mt6323-thermal",
+		.of_compatible = "mediatek,mt6323-thermal",
 	},
 };
 

-- 
2.53.0

