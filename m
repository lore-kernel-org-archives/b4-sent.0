From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 11:23:47 +0100
Subject: [PATCH v2 1/5] dt-bindings: soc: samsung: exynos-sysreg: Add
 compatibles for Exynos5515
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-v2-1-c4ecab4b1c4c@member.fsf.org>
References: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1093;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=4oL1kbyIOn5Laa19Ql6u9Ld59HRQr9TKBpSn19UfVIc=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1e+6I3w1FSVR3pHV96vJjrdf6vqS75do8ONdZ
 /ogMgf4EQmJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatXvuhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+vmmw//UlaEcMchJ3JeAfAC1L2YemzwaOYxTB8
 tKyececJIGWdPq95WRDuXT0EPIZITyoqsZNK8dWIojjImtJd2j/5p3ShmX8KKrcB5fHNnTBg/rE
 TtDYp02luZqSbrYbnY0J7+EYTz2PhRQGFWNXJqMY2Fhyip+47Lr8v5p2+ooPkP4pqQIAQweNkGA
 YhQJFkg+jPc0hyHK3dm3/fKGxb8NBHgQLFWYrPY71OOmONN+HQ7ZmFMHn7hTR5j2xbB9dnMOr8G
 cI1q34kHefLl37k5WFHuOVpiHY4ARlVk14GSwDSx7aOjFE2WL7Sb9fPsIw7ptr1CM0q2TOxBWcE
 pVK6zzD6f8L9YiaNx2qoVfKepaxq9xCipYj2LYcBmfW8NFA5X3l5KCExKlX7r8gnls9Wi+h+9DM
 Midndsh20xRqhecTzmrMH3fbaLBDpzMyXnd9ojF1DRWxqYMbtSBcavh/XjK80N/tSRok4ZnAy4o
 LXcJexI1F3l+73TZj/2bLFmrEgHZD/IMVymlvaq/tIAQ9nAI3MwaJjprrGKHrFHWP5YFW9UMSJW
 AIbckNBSc1QS790HoPKpmszsIGhknaQPWMAMRno+NhWcqZlGWTPavkQT3USXP4zm0/GWsUu0e5M
 6VjDgWY28Gf74Wr6Kkm4ECIWR+h5/VrJDL8rV9u7auGinXL6N3vI=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Exynos5515 compatibles for the following sysreg controllers:
- top
- peri
- fsys

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 .../devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml         | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml b/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
index fcdb9ffd2644..c6731a3ea1c4 100644
--- a/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
+++ b/Documentation/devicetree/bindings/soc/samsung/samsung,exynos-sysreg.yaml
@@ -29,6 +29,9 @@ properties:
               - samsung,exynos3-sysreg
               - samsung,exynos4-sysreg
               - samsung,exynos5-sysreg
+              - samsung,exynos5515-fsys-sysreg
+              - samsung,exynos5515-peri-sysreg
+              - samsung,exynos5515-top-sysreg
               - samsung,exynos7870-cam0-sysreg
               - samsung,exynos7870-disp-sysreg
               - samsung,exynos8895-fsys0-sysreg

-- 
2.54.0

