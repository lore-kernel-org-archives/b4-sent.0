From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 20 Feb 2026 16:11:11 -0600
Subject: [PATCH] dt-bindings: vendor-prefixes: Add AYN Technologies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ayn-vendor-v1-1-292cbbb682b3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyMD3cTKPN2y1LyU/CLdRENTY0Mzi2QjyyQjJaCGgqLUtMwKsGHRsbW
 1AHYwlvZcAAAA
X-Change-ID: 20260220-ayn-vendor-a153168c29b2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771625471; l=1366;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=geOwC291n5TffmOu0eiv9p98GOQQrv0IWSadxBAMpUw=;
 b=KuKtqAY6dXw2XeJHA0MtPkTKK6Q7BtFdiSxFULlV5lQQbMxqYfsIyboZ1zyigYoEZ68XwAdKr
 ioSULOPFowkCMHOlLNQ/5msP1eGB0Wj77Qkz7x1ZaZgYeyETG2vCYQ5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xilin Wu <wuxilin123@gmail.com>

Add an entry for AYN Technologies (https://www.ayntec.com/)

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
This was originally submitted as part of the original Odin 2 submission
[0], but that series stalled, so submitting this separately. The prefix
was renamed to ayntec as per the review comment on that patch.

[0] https://lore.kernel.org/linux-arm-msm/20240424-ayn-odin2-initial-v1-8-e0aa05c991fd@gmail.com/
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ee7fd3cfe203936d4aa42d4ce6f2efee951b4023..4d08af7b6ceb98ffb330a6e71a8f908d9cb37c4b 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -221,6 +221,8 @@ patternProperties:
     description: Axiado Corporation
   "^axis,.*":
     description: Axis Communications AB
+  "^ayntec,.*":
+    description: AYN Technologies Co., Ltd.
   "^azoteq,.*":
     description: Azoteq (Pty) Ltd
   "^azw,.*":

---
base-commit: fe9e3edb6a215515d1148d32a5c445c5bdd7916f
change-id: 20260220-ayn-vendor-a153168c29b2

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

