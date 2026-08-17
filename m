From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 17 Aug 2026 11:11:46 +0100
Subject: [PATCH 2/2] soc: samsung: exynos-chipid: Add exynos5515 SoC
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-for-next-lucky7-chipid-v1-2-eb2908705c0d@member.fsf.org>
References: <20260817-for-next-lucky7-chipid-v1-0-eb2908705c0d@member.fsf.org>
In-Reply-To: <20260817-for-next-lucky7-chipid-v1-0-eb2908705c0d@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=771;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=4onVHAcKrIX3AThzDNrMPzjm8bkKJ6d7i9OkgFxnui0=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqgt5jjXi6Ca6VVlGxDztOxUyWZvUX3u4J5Ehk6
 PXLoLz195KJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLeYwAKCRBJJwGyxHrX
 6/t1D/9XbqUBfGopw1OhVfelGWacYdVcNcYQn/yhhtEBjjnHZRKHvtbgKHwp7lIyxE2zllPgiTu
 vVbID5c/vaScNWJ3R8Ch+CcOb3Tkl9cFVov747b4IwlhPcnW5T0uBsuGgwGR4fGbn/M1JQI70Ex
 BBFFIGEtKlNj/RTt7EBztztU5U3Rf4K25Ha8DwNQG7j642vi4kYrH9W0VhmB0dI5fVPShv2AmCj
 /k31Fl5UgNOPiwUoEOehtbRo93fSXPsJc92IoVex2Ty9Klrfs77z/QgSao+XOk0opC1DrOHgfv8
 A7cFxmP5XZwVGHKyalpfhA6niO/kZal9mIZl4e9PucH8KPMB0ojXGcqCd28yx/5VN5n0XOtwwXL
 SUXGCuWei4PFiWwrsFi6+yAv3TP0ZaBx05NXq8LwW2DpDSD7JFQdhikarievkdar4X4NOAFKCEc
 DYlVylvT1rZMRkw+t4Y3vgNFoAOUfQZikKQVzPWfODlHx8MrXmvqsIZq9SVw4bEwN05nfReguhT
 pwzZ+ZIlFijHzVxHkSvOg90q4fW0hszIrr8RX/IBFKvP3YSxv6aO2fvZXNQF7KVZQ6zaHjGjSqL
 +/46N/KKXlvcqGa9mQm3JMyCzVMPfAOFyQ2FEQwU65RR2/llZ2+3WAZtCVvgr9CgwOPORswxbVr
 2NRfZIYGHGJku0Q==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add exynos5515 information to the soc_ids table.
The chipid for exynos5515 is "0xE5515000".

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
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

