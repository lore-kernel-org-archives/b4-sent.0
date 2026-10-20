From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 20 Oct 2026 01:02:34 +0100
Subject: [PATCH v2 1/3] dt-bindings: pinctrl: samsung: Add compatible for
 Exynos5515
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-for-next-lucky7-pinctrl-v2-1-b6b0e6065452@member.fsf.org>
References: <20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org>
In-Reply-To: <20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Tomasz Figa <tomasz.figa@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=844;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=wcMJv5MC9TAqtq4PfS0HwwKmDAbPXKFvyCt4uDAd3gs=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1q+a/w4FRcf5pIs6c0cfBlyB/dkjDSTQKmwiM
 TH8zZvr+s+JAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatavmhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+vJGw//b0cu6ODcpEuJLNZgfef0aE1babIjbA2
 PLLn5RMb0w8dtLuW/BXzn1eLl8yfNCVvGuXkl9O56eRxLEt7+2hiLHMkOmUBLWRbxeYesE687MS
 PerJIGgpMQcnfjLrTxH1ik2BHicO2QryifsnkWGRWT/a4SA2R8oE4Z/eGh1GQ9AJOnhh/HxvAOv
 LpH0KvpWWeIxNghc88VzyKrLFwVRzivd3GJJM/2946pP7tmKB3stxI7eD0B9Kp6wfL5yTuexGin
 JmOChISUzhDx85MA7e+QOSTygsi7grPY2Cpmngw1w4Xw846PDl4HVVjizOvVzgXacN3Zd2Sa1pv
 iWcas2zRh/+JUYttInvWY9SUCwiW9ewShYRz0zd/uTfbt2Jd7G4/kyWPZxCDyD7KDSTYjPJKQ8L
 PqkC/XwIu89vOGzkWKFCKxsNCyMABxFdjXH2zuyEfoSxx1tHPn9oAilLhpes16PDYPoXYSg/2n6
 6eNNSdgMzkmd79lmOVL8+X4bGQE35lLi+n9pITRP0JCdypGpOBoa74Tb+6SGsdqohnvn1rkWLvL
 IvoUdukep641ZypoYYnhg2s2ebYreGn4Ebec8kXxbPSenulFZ4lmDGL7Jo/2P+v1WAsXxqJxNjM
 uRW6gzWNoBkc00wm7+f1UM0UWDiwDegecHimvHpTGggqN1u57CPQ=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Exynos5515 pinctrl compatible string.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
index 1feb6a6fc690..7e49ca7b560a 100644
--- a/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/samsung,pinctrl.yaml
@@ -49,6 +49,7 @@ properties:
       - samsung,exynos5410-pinctrl
       - samsung,exynos5420-pinctrl
       - samsung,exynos5433-pinctrl
+      - samsung,exynos5515-pinctrl
       - samsung,exynos7-pinctrl
       - samsung,exynos7870-pinctrl
       - samsung,exynos7885-pinctrl

-- 
2.54.0

