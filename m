From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 16:05:43 +0100
Subject: [PATCH v2 2/2] soc: samsung: exynos-chipid: Add Exynos5515 SoC
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-chipid-v2-2-28ae49f5c349@member.fsf.org>
References: <20260818-for-next-lucky7-chipid-v2-0-28ae49f5c349@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-chipid-v2-0-28ae49f5c349@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=767;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=KrAvbTcjPgbEqmHaN4JftTy05Ws77uQwQ2XXbRU1taw=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhHUYhckpPyuaAWT392LX/C6uN5uPLPi5/tBVa
 ktbbqmfOgaJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoR1GAAKCRBJJwGyxHrX
 668zD/0RgG3Qiu7GFJKFaVrk7O9inGucMKIg0JATcjQFzegBFbclxxmBKUxIpPIcHKPvSIcDv97
 9llDqe9WcvUC9HDMvY5tV9yzqW9ZLesUS718CGo7ltIoJnao54yDxAR+NKfAX4DsDAJ2ZuXzJj/
 /Fg7sFZNwkPpRdIMGwFThauaXQ1hEB2gEX683A7S3padQcEa5YNEJVSXoDqPUMRpqQ1eCatgvU7
 27DRSqo5LeaPS8I53bazB6uKGotJV34+3TkGVpBNUHhsEZKiSYPLFmm7PRXImt3jhJ/ksuF+dpv
 ANBaXwBWG5jSHqbvQqQ//EZyCYN1D8wbKcRuJDxQPQYiyH/iyXSlhG499ltMdFCT7CWDkJHrggS
 PK55zp5r9XeVLONpiuvikwk/L5edX7DyqE7am4/QMLWkAVvUnVq9AkUw+q5hJzf2aAHY/KMMWC6
 jkGDoxqyZMLvhfjytmWaFptJ8tq4BByEPTGryb1dHARJiup+IU1aYRBVwKZrvoofZf2sDSPIBIp
 T0fhN9pt8ZGgBcWxECthLhiUGdqIkI6FWjbdGy77RNLcfUoYwDLwcmflDbEnfHPsI8PL+DfLIjA
 w6MqXTBxJmFx2C1ODz63a7E6vKT8J/CVL1tGx+S0+XLiK5FhsGfo/v85m95oD8+EuLrVYS43Mt8
 bE/zwlwr9lSMjlQ==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Exynos5515 information to the soc_ids table.
The ChipID for Exynos5515 is "0xE5515000".

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/soc/samsung/exynos-chipid.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/samsung/exynos-chipid.c b/drivers/soc/samsung/exynos-chipid.c
index 6ef9751e2509..506a0bcdfe30 100644
--- a/drivers/soc/samsung/exynos-chipid.c
+++ b/drivers/soc/samsung/exynos-chipid.c
@@ -64,6 +64,7 @@ static const struct exynos_soc_id {
 	{ "EXYNOS8890", 0xE8890000 },
 	/* Compatible with: samsung,exynos850-chipid */
 	{ "EXYNOS2200", 0xE9925000 },
+	{ "EXYNOS5515", 0xE5515000 },
 	{ "EXYNOS7885", 0xE7885000 },
 	{ "EXYNOS850", 0xE3830000 },
 	{ "EXYNOS8895", 0xE8895000 },

-- 
2.54.0

